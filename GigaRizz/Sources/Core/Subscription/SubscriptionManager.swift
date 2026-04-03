import Combine
import Foundation
import RevenueCat

// MARK: - Subscription Tier

enum SubscriptionTier: String, CaseIterable {
    case free
    case plus
    case gold

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .plus: return "Plus"
        case .gold: return "Gold"
        }
    }

    var dailyPhotoLimit: Int {
        switch self {
        case .free: return 3
        case .plus: return 30
        case .gold: return Int.max
        }
    }

    var availableStyles: Int {
        switch self {
        case .free: return 1
        case .plus: return 10
        case .gold: return Int.max
        }
    }

    var canDownloadHD: Bool {
        self != .free
    }

    var canRemoveWatermark: Bool {
        self != .free
    }

    var hasPriorityQueue: Bool {
        self == .gold
    }
}

// MARK: - Banner State

enum BannerState: Equatable {
    case freePhotosLeft(count: Int)
    case freeNoPhotosLeft
    case plusActive(renewsAt: Date)
    case plusExpiringSoon(days: Int)
    case goldActive
    case gracePeriod
}

// MARK: - Subscription Manager

@MainActor
final class SubscriptionManager: NSObject, ObservableObject {
    // MARK: - Published Properties

    @Published var currentTier: SubscriptionTier = .free
    @Published var bannerState: BannerState = .freePhotosLeft(count: 3)
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var dailyPhotosUsed = 0

    // MARK: - Purchases

    private var purchases: Purchases { Purchases.shared }

    // MARK: - Override

    var canGeneratePhoto: Bool {
        dailyPhotosUsed < currentTier.dailyPhotoLimit
    }

    var photosRemainingToday: Int {
        max(0, currentTier.dailyPhotoLimit - dailyPhotosUsed)
    }

    var availableStyles: [String] {
        let allStyles = ["Confident", "Adventurous", "Mysterious", "Sporty", "CasualChic",
                         "Professional", "GoldenHour", "UrbanMoody", "CleanMinimal", "TravelAdventure"]
        return Array(allStyles.prefix(currentTier.availableStyles))
    }

    // MARK: - Init

    override init() {
        super.init()
        // Guard against unconfigured RevenueCat (e.g. during unit tests)
        guard Purchases.isConfigured else { return }
        purchases.delegate = self
        fetchEntitlements()
    }

    // MARK: - Fetch Entitlements

    func fetchEntitlements() {
        isLoading = true
        errorMessage = nil

        purchases.getCustomerInfo { [weak self] customerInfo, error in
            Task { @MainActor in
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }

                self?.updateTierFromEntitlements(customerInfo?.entitlements.all)
                self?.updateBannerState()
            }
        }
    }

    // MARK: - Purchase

    func purchase(package: Package) async throws {
        isLoading = true
        errorMessage = nil

        let result = try await purchases.purchase(package: package)

        Task { @MainActor in
            self.isLoading = false
            if result.userCancelled {
                self.errorMessage = "Purchase cancelled"
                DesignSystem.Haptics.error()
            } else {
                self.updateTierFromEntitlements(result.customerInfo.entitlements.all)
                self.updateBannerState()
                DesignSystem.Haptics.success()
            }
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        isLoading = true
        errorMessage = nil

        do {
            let customerInfo = try await purchases.restorePurchases()
            updateTierFromEntitlements(customerInfo.entitlements.all)
            updateBannerState()
            DesignSystem.Haptics.success()
        } catch {
            errorMessage = error.localizedDescription
            DesignSystem.Haptics.error()
        }

        isLoading = false
    }

    // MARK: - Private

    private func updateTierFromEntitlements(_ entitlements: [String: RevenueCat.EntitlementInfo]?) {
        guard let entitlements = entitlements else {
            currentTier = .free
            return
        }

        if entitlements["gold"]?.isActive == true {
            currentTier = .gold
        } else if entitlements["plus"]?.isActive == true {
            currentTier = .plus
        } else {
            currentTier = .free
        }
    }

    private func updateBannerState() {
        switch currentTier {
        case .free:
            if photosRemainingToday > 0 {
                bannerState = .freePhotosLeft(count: photosRemainingToday)
            } else {
                bannerState = .freeNoPhotosLeft
            }
        case .plus:
            bannerState = .plusActive(renewsAt: Date().addingTimeInterval(30 * 24 * 60 * 60))
        case .gold:
            bannerState = .goldActive
        }
    }

    // MARK: - Increment Usage

    func incrementPhotoUsage() {
        dailyPhotosUsed += 1
        updateBannerState()
    }

    func resetDailyUsage() {
        dailyPhotosUsed = 0
        updateBannerState()
    }
}

// MARK: - PurchasesDelegate

extension SubscriptionManager: @preconcurrency PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.updateTierFromEntitlements(customerInfo.entitlements.all)
            self.updateBannerState()
        }
    }
}
