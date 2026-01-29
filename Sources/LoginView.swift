import SwiftUI

struct LoginView: View {
    @ObservedObject var authState: AuthState
    @State private var email = ""
    @State private var password = ""
    @State private var showSignup = false

    private let backgroundColor = Color(red: 0.1, green: 0.1, blue: 0.15)

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            VStack(spacing: 24) {
                // Logo/Title
                VStack(spacing: 8) {
                    Image(systemName: "eye.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.blue)

                    Text("Oculog")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)

                    Text("Track your eye health")
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

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.password)

                    if let error = authState.error {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Button(action: {
                        Task {
                            await authState.login(email: email, password: password)
                        }
                    }) {
                        if authState.isLoading {
                            ProgressView()
                                .controlSize(.small)
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Log In")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(email.isEmpty || password.isEmpty || authState.isLoading)
                }
                .frame(maxWidth: 300)

                // Sign up link
                HStack {
                    Text("Don't have an account?")
                        .foregroundStyle(.secondary)
                    Button("Create one") {
                        showSignup = true
                    }
                    .buttonStyle(.link)
                }
            }
            .padding(40)
        }
        .sheet(isPresented: $showSignup) {
            SignupView(authState: authState, isPresented: $showSignup)
        }
    }
}
