import SwiftUI

struct SignupView: View {
    @ObservedObject var authState: AuthState
    @Binding var isPresented: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var validationError: String?

    private let backgroundColor = Color(red: 0.1, green: 0.1, blue: 0.15)

    private var passwordsMatch: Bool {
        password == confirmPassword
    }

    private var isValid: Bool {
        !email.isEmpty && password.count >= 8 && passwordsMatch
    }

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            VStack(spacing: 24) {
                // Title
                VStack(spacing: 8) {
                    Text("Create Account")
                        .font(.title.bold())
                        .foregroundStyle(.white)

                    Text("Join Oculog to track your eye health")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 20)

                // Form
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .autocorrectionDisabled()

                    SecureField("Password (min 8 characters)", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.newPassword)

                    SecureField("Confirm Password", text: $confirmPassword)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.newPassword)

                    if !confirmPassword.isEmpty && !passwordsMatch {
                        Text("Passwords don't match")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }

                    if let error = validationError ?? authState.error {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Button(action: {
                        validationError = nil
                        if password.count < 8 {
                            validationError = "Password must be at least 8 characters"
                            return
                        }
                        Task {
                            await authState.signup(email: email, password: password)
                            if authState.isAuthenticated {
                                isPresented = false
                            }
                        }
                    }) {
                        if authState.isLoading {
                            ProgressView()
                                .controlSize(.small)
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Create Account")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isValid || authState.isLoading)
                }
                .frame(maxWidth: 300)

                // Back to login
                HStack {
                    Text("Already have an account?")
                        .foregroundStyle(.secondary)
                    Button("Log in") {
                        isPresented = false
                    }
                    .buttonStyle(.link)
                }
            }
            .padding(40)
        }
        .frame(minWidth: 400, minHeight: 450)
    }
}
