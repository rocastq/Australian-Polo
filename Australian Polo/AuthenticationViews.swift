//
//  AuthenticationViews.swift
//  Australian Polo
//
//  Created by Claude on 11/23/25.
//

import SwiftUI
import Foundation

// MARK: - Authentication Flow Root

struct AuthenticationFlow: View {
    @State private var showingRegister = false

    var body: some View {
        if showingRegister {
            RegistrationView(showingRegister: $showingRegister)
        } else {
            LoginView(showingRegister: $showingRegister)
        }
    }
}

// MARK: - Login View

struct LoginView: View {
    @Binding var showingRegister: Bool
    @EnvironmentObject private var authManager: AuthenticationManager

    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 30) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "trophy.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.accentColor)

                            Text("Australian Polo")
                                .font(.largeTitle)
                                .fontWeight(.bold)

                            Text("Welcome back")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 40)

                        // Login Form
                        VStack(spacing: 20) {
                            // Email Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.headline)

                                TextField("Enter your email", text: $email)
                                    .textFieldStyle(.roundedBorder)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                                    .disabled(authManager.isLoading)
                            }

                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.headline)

                                HStack {
                                    if showPassword {
                                        TextField("Enter your password", text: $password)
                                    } else {
                                        SecureField("Enter your password", text: $password)
                                    }

                                    Button(action: { showPassword.toggle() }) {
                                        Image(systemName: showPassword ? "eye.slash" : "eye")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .textFieldStyle(.roundedBorder)
                                .disabled(authManager.isLoading)
                            }

                            // Error Message
                            if let errorMessage = authManager.errorMessage {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                            }

                            // Login Button
                            Button(action: handleLogin) {
                                HStack {
                                    if authManager.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Text("Sign In")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(isFormValid ? Color.accentColor : Color.gray)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .disabled(!isFormValid || authManager.isLoading)

                            // Forgot Password
                            Button("Forgot Password?") {
                                // Handle forgot password
                            }
                            .font(.subheadline)
                            .foregroundColor(.accentColor)
                        }
                        .padding(.horizontal, 32)

                        Spacer()

                        // Register Link
                        VStack(spacing: 16) {
                            HStack {
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(.gray.opacity(0.3))

                                Text("OR")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(.gray.opacity(0.3))
                            }
                            .padding(.horizontal, 32)

                            Button(action: { showingRegister = true }) {
                                HStack {
                                    Text("Don't have an account?")
                                        .foregroundColor(.secondary)
                                    Text("Sign Up")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    .frame(minHeight: geometry.size.height)
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var isFormValid: Bool {
        !email.isEmpty && email.contains("@") && password.count >= 6
    }

    private func handleLogin() {
        Task {
            await authManager.login(email: email, password: password)
        }
    }
}

// MARK: - Registration View

struct RegistrationView: View {
    @Binding var showingRegister: Bool
    @EnvironmentObject private var authManager: AuthenticationManager

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var selectedRole: UserRole = .user
    @State private var phoneNumber = ""
    @State private var dateOfBirth = Date()
    @State private var nationality = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var agreedToTerms = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.fill.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.accentColor)

                        Text("Create Account")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Join the Australian Polo community")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)

                    // Registration Form
                    VStack(spacing: 16) {
                        // Name Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Full Name")
                                .font(.headline)

                            TextField("Enter your full name", text: $name)
                                .textFieldStyle(.roundedBorder)
                                .disabled(authManager.isLoading)
                        }

                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.headline)

                            TextField("Enter your email", text: $email)
                                .textFieldStyle(.roundedBorder)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .disabled(authManager.isLoading)
                        }

                        // Role Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Role")
                                .font(.headline)

                            Picker("Select your role", selection: $selectedRole) {
                                ForEach(UserRole.allCases, id: \.self) { role in
                                    Text(role.rawValue).tag(role)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .disabled(authManager.isLoading)
                        }

                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.headline)

                            HStack {
                                if showPassword {
                                    TextField("Create a password", text: $password)
                                } else {
                                    SecureField("Create a password", text: $password)
                                }

                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .textFieldStyle(.roundedBorder)
                            .disabled(authManager.isLoading)

                            Text("Password must be at least 6 characters")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        // Confirm Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.headline)

                            HStack {
                                if showConfirmPassword {
                                    TextField("Confirm your password", text: $confirmPassword)
                                } else {
                                    SecureField("Confirm your password", text: $confirmPassword)
                                }

                                Button(action: { showConfirmPassword.toggle() }) {
                                    Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .textFieldStyle(.roundedBorder)
                            .disabled(authManager.isLoading)

                            if !confirmPassword.isEmpty && password != confirmPassword {
                                Text("Passwords do not match")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }

                        // Optional Fields
                        DisclosureGroup("Optional Information") {
                            VStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Phone Number")
                                        .font(.headline)

                                    TextField("Enter your phone number", text: $phoneNumber)
                                        .textFieldStyle(.roundedBorder)
                                        .keyboardType(.phonePad)
                                        .disabled(authManager.isLoading)
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Date of Birth")
                                        .font(.headline)

                                    DatePicker("", selection: $dateOfBirth, displayedComponents: .date)
                                        .datePickerStyle(.compact)
                                        .disabled(authManager.isLoading)
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Nationality")
                                        .font(.headline)

                                    TextField("Enter your nationality", text: $nationality)
                                        .textFieldStyle(.roundedBorder)
                                        .disabled(authManager.isLoading)
                                }
                            }
                            .padding(.top, 8)
                        }

                        // Terms and Conditions
                        HStack(alignment: .top, spacing: 12) {
                            Button(action: { agreedToTerms.toggle() }) {
                                Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                                    .foregroundColor(agreedToTerms ? .accentColor : .gray)
                                    .font(.title2)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("I agree to the Terms of Service and Privacy Policy")
                                    .font(.subheadline)

                                HStack {
                                    Button("Terms of Service") {
                                        // Handle terms
                                    }
                                    .font(.caption)
                                    .foregroundColor(.accentColor)

                                    Text("and")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    Button("Privacy Policy") {
                                        // Handle privacy policy
                                    }
                                    .font(.caption)
                                    .foregroundColor(.accentColor)
                                }
                            }

                            Spacer()
                        }

                        // Error Message
                        if let errorMessage = authManager.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }

                        // Register Button
                        Button(action: handleRegister) {
                            HStack {
                                if authManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Create Account")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(isFormValid ? Color.accentColor : Color.gray)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .disabled(!isFormValid || authManager.isLoading)

                        // Back to Login
                        Button(action: { showingRegister = false }) {
                            HStack {
                                Text("Already have an account?")
                                    .foregroundColor(.secondary)
                                Text("Sign In")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 32)
                }
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
        }
    }

    private var isFormValid: Bool {
        !name.isEmpty &&
        !email.isEmpty &&
        email.contains("@") &&
        password.count >= 6 &&
        password == confirmPassword &&
        agreedToTerms
    }

    private func handleRegister() {
        let registerRequest = RegisterRequest(
            name: name,
            email: email,
            password: password,
            role: selectedRole,
            phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
            dateOfBirth: dateOfBirth,
            nationality: nationality.isEmpty ? nil : nationality
        )

        Task {
            await authManager.register(registerRequest)
        }
    }
}

// MARK: - Preview

#Preview {
    AuthenticationFlow()
        .environmentObject(AuthenticationManager())
}
