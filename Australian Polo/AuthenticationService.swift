//
//  AuthenticationService.swift
//  Australian Polo
//
//  Created by Claude on 11/23/25.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Authentication Models

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let name: String
    let email: String
    let password: String
    let role: UserRole
    let phoneNumber: String?
    let dateOfBirth: Date?
    let nationality: String?
}

struct AuthResponse: Codable {
    let token: String
    let user: UserProfile
    let refreshToken: String?
    let expiresIn: TimeInterval
}

struct UserProfile: Codable, Identifiable {
    let id: UUID
    let name: String
    let email: String
    let role: UserRole
    let createdAt: Date
    let lastLoginAt: Date?
    let isActive: Bool
    let isEmailVerified: Bool
    let phoneNumber: String?
    let dateOfBirth: Date?
    let nationality: String?
}

struct ErrorResponse: Codable {
    let message: String
    let code: String?
}

// MARK: - Authentication State

class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: UserProfile?
    @Published var authToken: String?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let baseURL = "https://your-backend-url.com/api" // Replace with your backend URL
    private let keychain = KeychainManager()

    init() {
        loadStoredAuthentication()
    }

    // MARK: - Authentication Methods

    @MainActor
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let request = LoginRequest(email: email, password: password)
            let response: AuthResponse = try await performRequest(
                endpoint: "/auth/login",
                method: "POST",
                body: request
            )

            await handleAuthenticationSuccess(response)
        } catch {
            errorMessage = handleError(error)
        }

        isLoading = false
    }

    @MainActor
    func register(_ request: RegisterRequest) async {
        isLoading = true
        errorMessage = nil

        do {
            let response: AuthResponse = try await performRequest(
                endpoint: "/auth/register",
                method: "POST",
                body: request
            )

            await handleAuthenticationSuccess(response)
        } catch {
            errorMessage = handleError(error)
        }

        isLoading = false
    }

    @MainActor
    func logout() {
        isAuthenticated = false
        currentUser = nil
        authToken = nil
        keychain.deleteToken()
        keychain.deleteUserProfile()
    }

    @MainActor
    func refreshToken() async {
        guard let refreshToken = keychain.getRefreshToken() else { return }

        do {
            let response: AuthResponse = try await performRequest(
                endpoint: "/auth/refresh",
                method: "POST",
                body: ["refreshToken": refreshToken]
            )

            await handleAuthenticationSuccess(response)
        } catch {
            await logout() // If refresh fails, logout user
        }
    }

    // MARK: - Private Methods

    private func loadStoredAuthentication() {
        if let token = keychain.getToken(),
           let userData = keychain.getUserProfile(),
           let user = try? JSONDecoder().decode(UserProfile.self, from: userData) {

            Task { @MainActor in
                self.authToken = token
                self.currentUser = user
                self.isAuthenticated = true
            }
        }
    }

    private func handleAuthenticationSuccess(_ response: AuthResponse) async {
        authToken = response.token
        currentUser = response.user
        isAuthenticated = true

        // Store in keychain
        keychain.storeToken(response.token)
        if let refreshToken = response.refreshToken {
            keychain.storeRefreshToken(refreshToken)
        }

        if let userData = try? JSONEncoder().encode(response.user) {
            keychain.storeUserProfile(userData)
        }
    }

    private func handleError(_ error: Error) -> String {
        if let apiError = error as? APIError {
            return apiError.message
        }
        return "An unexpected error occurred. Please try again."
    }

    private func performRequest<T: Codable, U: Codable>(
        endpoint: String,
        method: String,
        body: T? = nil
    ) async throws -> U {

        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let authToken = authToken {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        if let body = body {
            request.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode >= 400 {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            if let errorData = try? decoder.decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorData.message)
            } else {
                throw APIError.serverError("Server error: \(httpResponse.statusCode)")
            }
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(U.self, from: data)
    }
}

// MARK: - API Error

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .serverError(let message):
            return message
        }
    }

    var message: String {
        errorDescription ?? "Unknown error"
    }
}

// MARK: - Keychain Manager

class KeychainManager {
    private let service = "com.australianpolo.app"
    private let tokenKey = "auth_token"
    private let refreshTokenKey = "refresh_token"
    private let userProfileKey = "user_profile"

    func storeToken(_ token: String) {
        store(key: tokenKey, data: token.data(using: .utf8)!)
    }

    func getToken() -> String? {
        guard let data = retrieve(key: tokenKey) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func deleteToken() {
        delete(key: tokenKey)
    }

    func storeRefreshToken(_ token: String) {
        store(key: refreshTokenKey, data: token.data(using: .utf8)!)
    }

    func getRefreshToken() -> String? {
        guard let data = retrieve(key: refreshTokenKey) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func storeUserProfile(_ data: Data) {
        store(key: userProfileKey, data: data)
    }

    func getUserProfile() -> Data? {
        return retrieve(key: userProfileKey)
    }

    func deleteUserProfile() {
        delete(key: userProfileKey)
    }

    private func store(key: String, data: Data) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func retrieve(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        return result as? Data
    }

    private func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}