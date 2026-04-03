import Combine
import FirebaseAuth
import FirebaseCore
import Foundation

/// Manages Firebase Authentication state and user identity.
@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    // MARK: - Published Properties

    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private nonisolated(unsafe) var authStateListener: AuthStateDidChangeListenerHandle?

    // MARK: - Init

    init() {
        // Guard against unconfigured Firebase (e.g. during unit test bootstrap).
        guard FirebaseApp.app() != nil else { return }
    }

    // MARK: - Auth State

    func startAuthStateListener() {
        guard FirebaseApp.app() != nil else { return }
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                self?.isAuthenticated = user != nil
            }
        }
    }

    func stopAuthStateListener() {
        if let handle = authStateListener {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        try await Auth.auth().signIn(withEmail: email, password: password)
        DesignSystem.Haptics.success()
    }

    // MARK: - Sign Up

    func signUp(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        try await Auth.auth().createUser(withEmail: email, password: password)
        DesignSystem.Haptics.success()
    }

    // MARK: - Sign Out

    func signOut() throws {
        try Auth.auth().signOut()
        isAuthenticated = false
        currentUser = nil
        DesignSystem.Haptics.medium()
    }

    // MARK: - Delete Account

    func deleteAccount() async throws {
        guard let user = currentUser else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        nonisolated(unsafe) let userToDelete = user
        try await userToDelete.delete()
        isAuthenticated = false
        currentUser = nil
        DesignSystem.Haptics.heavy()
    }

    // MARK: - Helpers

    var userId: String? {
        currentUser?.uid
    }

    var currentUserId: String? {
        currentUser?.uid
    }

    var userEmail: String? {
        currentUser?.email
    }

    deinit {
        if let handle = authStateListener {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}
