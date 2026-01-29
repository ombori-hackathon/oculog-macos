import SwiftUI

@MainActor
class AuthState: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = true
    @Published var error: String?
    @Published var currentUser: AuthUser?

    private let baseURL = "http://localhost:8000"

    func checkAuth() async {
        isLoading = true
        error = nil

        guard let accessToken = KeychainManager.get(forKey: .accessToken) else {
            isAuthenticated = false
            isLoading = false
            return
        }

        // Validate token with /auth/me
        do {
            let user = try await fetchCurrentUser(accessToken: accessToken)
            currentUser = user
            isAuthenticated = true
        } catch AuthError.unauthorized {
            // Try refresh
            if await refreshToken() {
                await checkAuth()
                return
            }
            logout()
        } catch {
            self.error = error.localizedDescription
            isAuthenticated = false
        }

        isLoading = false
    }

    func login(email: String, password: String) async {
        isLoading = true
        error = nil

        do {
            let tokens = try await performLogin(email: email, password: password)
            saveTokens(tokens)
            await checkAuth()
        } catch AuthError.invalidCredentials {
            error = "Invalid email or password"
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }

    func signup(email: String, password: String) async {
        isLoading = true
        error = nil

        do {
            let tokens = try await performSignup(email: email, password: password)
            saveTokens(tokens)
            await checkAuth()
        } catch AuthError.emailAlreadyExists {
            error = "Email already registered"
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }

    func logout() {
        KeychainManager.clearAll()
        currentUser = nil
        isAuthenticated = false
        error = nil
    }

    func refreshToken() async -> Bool {
        guard let refreshToken = KeychainManager.get(forKey: .refreshToken) else {
            return false
        }

        do {
            let tokens = try await performRefresh(refreshToken: refreshToken)
            saveTokens(tokens)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Private API Methods

    private func performLogin(email: String, password: String) async throws -> TokenResponse {
        var request = URLRequest(url: URL(string: "\(baseURL)/auth/login")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["email": email, "password": password]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkError
        }

        if httpResponse.statusCode >= 400 {
            throw parseAuthError(data: data, statusCode: httpResponse.statusCode)
        }

        return try JSONDecoder().decode(TokenResponse.self, from: data)
    }

    private func performSignup(email: String, password: String) async throws -> TokenResponse {
        var request = URLRequest(url: URL(string: "\(baseURL)/auth/signup")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["email": email, "password": password]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkError
        }

        if httpResponse.statusCode >= 400 {
            throw parseAuthError(data: data, statusCode: httpResponse.statusCode)
        }

        return try JSONDecoder().decode(TokenResponse.self, from: data)
    }

    private func performRefresh(refreshToken: String) async throws -> TokenResponse {
        var request = URLRequest(url: URL(string: "\(baseURL)/auth/refresh")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["refresh_token": refreshToken]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkError
        }

        if httpResponse.statusCode >= 400 {
            throw parseAuthError(data: data, statusCode: httpResponse.statusCode)
        }

        return try JSONDecoder().decode(TokenResponse.self, from: data)
    }

    private func fetchCurrentUser(accessToken: String) async throws -> AuthUser {
        var request = URLRequest(url: URL(string: "\(baseURL)/auth/me")!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkError
        }

        if httpResponse.statusCode >= 400 {
            throw parseAuthError(data: data, statusCode: httpResponse.statusCode)
        }

        return try JSONDecoder().decode(AuthUser.self, from: data)
    }

    private func saveTokens(_ tokens: TokenResponse) {
        KeychainManager.save(token: tokens.accessToken, forKey: .accessToken)
        KeychainManager.save(token: tokens.refreshToken, forKey: .refreshToken)
    }

    // MARK: - Unified Error Parsing

    private func parseAuthError(data: Data, statusCode: Int) -> AuthError {
        if let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
            let errorType = APIErrorType(rawValue: errorResponse.type) ?? .unknown
            switch errorType {
            case .invalidCredentials:
                return .invalidCredentials
            case .emailAlreadyExists:
                return .emailAlreadyExists
            case .unauthorized:
                return .unauthorized
            default:
                return .serverError(statusCode)
            }
        }
        // Fallback based on status code
        switch statusCode {
        case 401:
            return .unauthorized
        case 400:
            return .emailAlreadyExists
        default:
            return .serverError(statusCode)
        }
    }
}

enum AuthError: Error {
    case invalidCredentials
    case emailAlreadyExists
    case unauthorized
    case networkError
    case serverError(Int)
}
