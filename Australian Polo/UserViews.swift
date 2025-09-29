//
//  UserViews.swift
//  Australian Polo
//
//  Created by Rodrigo Castillo on 9/29/25.
//

import SwiftUI
import SwiftData

// MARK: - User List View

struct UserListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @State private var showingAddUser = false
    @State private var selectedRole: UserRole = .user
    
    var body: some View {
        NavigationView {
            List {
                Picker("Filter by Role", selection: $selectedRole) {
                    Text("All Users").tag(UserRole.user)
                    ForEach(UserRole.allCases, id: \.self) { role in
                        Text(role.rawValue).tag(role)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.vertical, 8)
                
                ForEach(filteredUsers) { user in
                    NavigationLink(destination: UserDetailView(user: user)) {
                        UserRowView(user: user)
                    }
                }
                .onDelete(perform: deleteUsers)
            }
            .navigationTitle("Users")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddUser = true }) {
                        Label("Add User", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddUser) {
                AddUserView()
            }
        }
    }
    
    private var filteredUsers: [User] {
        if selectedRole == .user {
            return users.filter { $0.isActive }
        }
        return users.filter { $0.role == selectedRole && $0.isActive }
    }
    
    private func deleteUsers(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let user = filteredUsers[index]
                user.isActive = false
            }
        }
    }
}

struct UserRowView: View {
    let user: User
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(user.name)
                .font(.headline)
            HStack {
                Text(user.email)
                    .foregroundColor(.secondary)
                    .font(.caption)
                Spacer()
                Text(user.role.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(roleColor(for: user.role))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 2)
    }
    
    private func roleColor(for role: UserRole) -> Color {
        switch role {
        case .administrator: return .red
        case .clubOperator: return .orange
        case .player: return .blue
        case .breeder: return .green
        case .user: return .gray
        }
    }
}

// MARK: - Add User View

struct AddUserView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var selectedRole: UserRole = .user
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("User Information")) {
                    TextField("Name", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }
                
                Section(header: Text("Role")) {
                    Picker("Role", selection: $selectedRole) {
                        ForEach(UserRole.allCases, id: \.self) { role in
                            Text(role.rawValue).tag(role)
                        }
                    }
                }
            }
            .navigationTitle("Add User")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        addUser()
                    }
                    .disabled(name.isEmpty || email.isEmpty)
                }
            }
        }
    }
    
    private func addUser() {
        let newUser = User(name: name, email: email, role: selectedRole)
        modelContext.insert(newUser)
        dismiss()
    }
}

// MARK: - User Detail View

struct UserDetailView: View {
    @Bindable var user: User
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        Form {
            Section(header: Text("User Information")) {
                TextField("Name", text: $user.name)
                TextField("Email", text: $user.email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                
                Picker("Role", selection: $user.role) {
                    ForEach(UserRole.allCases, id: \.self) { role in
                        Text(role.rawValue).tag(role)
                    }
                }
            }
            
            Section(header: Text("Account Details")) {
                HStack {
                    Text("Created")
                    Spacer()
                    Text(user.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .foregroundColor(.secondary)
                }
                
                Toggle("Active Account", isOn: $user.isActive)
            }
            
            if let playerProfile = user.playerProfile {
                Section(header: Text("Player Profile")) {
                    NavigationLink("View Player Details") {
                        PlayerDetailView(player: playerProfile)
                    }
                }
            }
            
            if let breederProfile = user.breederProfile {
                Section(header: Text("Breeder Profile")) {
                    NavigationLink("View Breeder Details") {
                        BreederDetailView(breeder: breederProfile)
                    }
                }
            }
        }
        .navigationTitle(user.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}