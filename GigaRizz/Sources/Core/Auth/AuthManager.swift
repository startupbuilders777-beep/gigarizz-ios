import AuthenticationServices
import Combine
import CryptoKit
import FirebaseAuth
import FirebaseCore
import Foundation

/// Manages Firebase Authentication state and user identity.
/// Supports Apple Sign-In, Email/Password, and Firebase Auth state management.
@MainActor
final class AuthManager: ObservableObject {
    // MARK: - Singleton

    static let shared = AuthManager()

    // MARK: - Published Properties

    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showAppleSignIn = false

    // MARK: - Computed Properties

    var currentUserId: String? {
        currentUser?.uid
    }

    // MARK: - Private Properties

    private nonisolated(unsafe) var authStateListener: AuthStateDidChangeListenerHandle?
    var currentNonce: String?

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
                if user != nil {
                    PostHogManager.shared.trackAppleSignInCompleted()
                }
            }
        }
    }

    func stopAuthStateListener() {
        if let handle = authStateListener {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Apple Sign-In

    /// Starts the Apple Sign-In flow.
    /// Generates a nonce for security and tracks analytics.
    func startAppleSignIn() {
        currentNonce = randomNonceString()
        isLoading = true
        errorMessage = nil
        PostHogManager.shared.trackAppleSignInStarted()
        DesignSystem.Haptics.medium()
    }

    /// Handles Apple Sign-In completion with Firebase credential.
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        guard let nonce = currentNonce else {
            throw AuthError.invalidNonce
        }
        
        guard let appleIDTokenData = credential.identityToken else {
            throw AuthError.invalidToken
        }
        
        guard let idTokenString = String(data: appleIDTokenData, encoding: .utf8) else {
            throw AuthError.invalidToken
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        let appleCredential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: credential.fullName
        )
        
        try await Auth.auth().signIn(with: appleCredential)
        DesignSystem.Haptics.success()
        PostHogManager.shared.trackAppleSignInCompleted()
    }
    
    /// Returns the current nonce for Apple Sign-In request.
    func getCurrentNonce() -> String? {
        currentNonce
    }
    
    /// Clears the nonce after use.
    func clearNonce() {
        currentNonce = nil
    }

    // MARK: - Sign In (Email/Password)

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
        currentUserId
    }

    var userEmail: String? {
        currentUser?.email
    }

    // MARK: - Helpers

    /// Generates a random nonce string for Apple Sign-In security.
    func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let resultCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if resultCode != errSecSuccess {
            fatalError("Unable to generate nonce: SecRandomCopyBytes failed with OSStatus \(resultCode)")
        }
        
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }

    deinit {
        if let handle = authStateListener {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case invalidNonce
    case invalidToken
    case invalidCredential
    
    var errorDescription: String? {
        switch self {
        case .invalidNonce:
            return "Sign-in request was invalid. Please try again."
        case .invalidToken:
            return "Could not verify your Apple account. Please try again."
        case .invalidCredential:
            return "Sign-in credential was invalid. Please try again."
        }
    }
}

// MARK: - Apple Sign-In Coordinator

/// Coordinates Apple Sign-In requests with Firebase Auth.
@MainActor
final class AppleSignInCoordinator: NSObject {
    weak var authManager: AuthManager?
    var onCompletion: ((Result<Void, Error>) -> Void)?
    
    init(authManager: AuthManager) {
        self.authManager = authManager
    }
    
    func startSignInFlow() {
        guard let nonce = authManager?.randomNonceString(length: 32) else { return }
        authManager?.currentNonce = nonce
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.performRequests()
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleSignInCoordinator: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            Task { @MainActor in
                onCompletion?(.failure(AuthError.invalidCredential))
            }
            return
        }
        
        Task { @MainActor in
            do {
                try await authManager?.signInWithApple(credential: appleIDCredential)
                onCompletion?(.success(()))
            } catch {
                authManager?.errorMessage = error.localizedDescription
                onCompletion?(.failure(error))
            }
        }
    }
    
    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Task { @MainActor in
            authManager?.errorMessage = error.localizedDescription
            onCompletion?(.failure(error))
        }
    }
}
