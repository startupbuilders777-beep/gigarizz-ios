import AuthenticationServices
import CryptoKit
import SwiftUI

// MARK: - Sign In View

struct SignInView: View {
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.deepNight
                .ignoresSafeArea()
            
            VStack(spacing: DesignSystem.Spacing.xl) {
                Spacer()
                
                // MARK: - Logo Area
                VStack(spacing: DesignSystem.Spacing.medium) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 64, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    DesignSystem.Colors.flameOrange,
                                    DesignSystem.Colors.goldAccent
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .accessibilityHidden(true)
                    
                    Text("GigaRizz")
                        .font(DesignSystem.Typography.scoreLarge)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    
                    Text("Your AI dating photographer.")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("GigaRizz. Your AI dating photographer.")
                
                Spacer()
                
                // MARK: - Apple Sign-In (Primary)
                appleSignInButton
                    .padding(.horizontal, DesignSystem.Spacing.medium)
                
                // MARK: - Divider
                HStack(spacing: DesignSystem.Spacing.small) {
                    Rectangle()
                        .fill(DesignSystem.Colors.divider)
                        .frame(height: 1)
                    
                    Text("or")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                    
                    Rectangle()
                        .fill(DesignSystem.Colors.divider)
                        .frame(height: 1)
                }
                .padding(.horizontal, DesignSystem.Spacing.medium)
                .accessibilityHidden(true)
                
                // MARK: - Email/Password Form
                VStack(spacing: DesignSystem.Spacing.medium) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.plain)
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .padding(DesignSystem.Spacing.medium)
                        .background(DesignSystem.Colors.surfaceSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .accessibilityLabel("Email address")
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(.plain)
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .padding(DesignSystem.Spacing.medium)
                        .background(DesignSystem.Colors.surfaceSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
                        .textContentType(.password)
                        .accessibilityLabel("Password")
                    
                    if let error = authManager.errorMessage {
                        Text(error)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.error)
                            .accessibilityLabel("Error: \(error)")
                    }
                    
                    GRButton(
                        title: isSignUp ? "Create Account" : "Sign In",
                        icon: isSignUp ? "person.badge.plus" : "arrow.right",
                        isLoading: authManager.isLoading,
                        isDisabled: email.isEmpty || password.isEmpty,
                        accessibilityHint: isSignUp ? "Creates a new account with email and password" : "Signs in with email and password"
                    ) {
                        Task {
                            do {
                                if isSignUp {
                                    try await authManager.signUp(email: email, password: password)
                                } else {
                                    try await authManager.signIn(email: email, password: password)
                                }
                            } catch {
                                authManager.errorMessage = error.localizedDescription
                            }
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.medium)
                
                // MARK: - Toggle Sign Up/Sign In
                Button {
                    withAnimation(DesignSystem.Animation.quickSpring) {
                        isSignUp.toggle()
                    }
                    DesignSystem.Haptics.light()
                } label: {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .font(DesignSystem.Typography.smallButton)
                        .foregroundStyle(DesignSystem.Colors.flameOrange)
                }
                .accessibilityHint(isSignUp ? "Switches to sign in mode" : "Switches to sign up mode")
                .padding(.top, DesignSystem.Spacing.medium)
                
                Spacer()
                
                // MARK: - Footer (Privacy & Terms)
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Text("By continuing, you agree to our")
                        .font(DesignSystem.Typography.footnote)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                    
                    HStack(spacing: DesignSystem.Spacing.small) {
                        Button {
                            // Open privacy policy
                            PostHogManager.shared.trackEvent("privacy_policy_viewed")
                        } label: {
                            Text("Privacy Policy")
                                .font(DesignSystem.Typography.footnote)
                                .foregroundStyle(DesignSystem.Colors.flameOrange)
                        }
                        
                        Text("and")
                            .font(DesignSystem.Typography.footnote)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                        
                        Button {
                            // Open terms of service
                            PostHogManager.shared.trackEvent("terms_of_service_viewed")
                        } label: {
                            Text("Terms of Service")
                                .font(DesignSystem.Typography.footnote)
                                .foregroundStyle(DesignSystem.Colors.flameOrange)
                        }
                    }
                }
                .padding(.bottom, DesignSystem.Spacing.large)
            }
        }
    }
    
    // MARK: - Apple Sign-In Button
    
    @ViewBuilder
    private var appleSignInButton: some View {
        SignInWithAppleButton(
            .signIn,
            onRequest: { request in
                authManager.startAppleSignIn()
                request.requestedScopes = [.fullName, .email]
                if let nonce = authManager.getCurrentNonce() {
                    request.nonce = sha256(nonce)
                }
            },
            onCompletion: { result in
                switch result {
                case .success(let authorization):
                    guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                        authManager.errorMessage = "Invalid Apple credential"
                        return
                    }
                    
                    Task {
                        do {
                            try await authManager.signInWithApple(credential: credential)
                        } catch {
                            authManager.errorMessage = error.localizedDescription
                        }
                    }
                    
                case .failure(let error):
                    authManager.errorMessage = error.localizedDescription
                    authManager.isLoading = false
                }
            }
        )
        .signInWithAppleButtonStyle(.white)
        .frame(height: 52)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button))
        .accessibilityLabel("Sign in with Apple")
        .accessibilityHint("Uses your Apple ID for fast, secure sign in")
    }
    
    // MARK: - SHA256 Helper
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        return hashString
    }
}

// MARK: - Preview

#Preview {
    SignInView()
        .environmentObject(AuthManager())
        .preferredColorScheme(.dark)
}