import SwiftUI

// MARK: - Sign In View

struct SignInView: View {
    @EnvironmentObject private var authManager: AuthManager

    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false

    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()

            VStack(spacing: DesignSystem.Spacing.xl) {
                Spacer()

                // MARK: - Logo Area
                VStack(spacing: DesignSystem.Spacing.m) {
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

                    Text("GigaRizz")
                        .font(DesignSystem.Typography.scoreLarge)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text("Your AI dating photographer.")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                Spacer()

                // MARK: - Form
                VStack(spacing: DesignSystem.Spacing.m) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.plain)
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .padding(DesignSystem.Spacing.m)
                        .background(DesignSystem.Colors.surfaceSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)

                    SecureField("Password", text: $password)
                        .textFieldStyle(.plain)
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                        .padding(DesignSystem.Spacing.m)
                        .background(DesignSystem.Colors.surfaceSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
                        .textContentType(.password)

                    if let error = authManager.errorMessage {
                        Text(error)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.error)
                    }

                    GRButton(
                        title: isSignUp ? "Create Account" : "Sign In",
                        icon: isSignUp ? "person.badge.plus" : "arrow.right",
                        isLoading: authManager.isLoading,
                        isDisabled: email.isEmpty || password.isEmpty
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
                .padding(.horizontal, DesignSystem.Spacing.m)

                // MARK: - Toggle
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
                .padding(.bottom, DesignSystem.Spacing.xl)
            }
        }
    }
}

#Preview {
    SignInView()
        .environmentObject(AuthManager())
        .preferredColorScheme(.dark)
}
