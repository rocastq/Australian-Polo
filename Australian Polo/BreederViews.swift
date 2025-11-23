//
//  BreederViews.swift
//  Australian Polo
//
//  Created by Rodrigo Castillo on 9/29/25.
//

import SwiftUI
import SwiftData

// MARK: - Breeder List View

struct BreederListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var breeders: [Breeder]
    @State private var showingAddBreeder = false
    @State private var isLoadingBreeders = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            List {
                ForEach(breeders.filter { $0.isActive }) { breeder in
                    NavigationLink(destination: BreederDetailView(breeder: breeder)) {
                        BreederRowView(breeder: breeder)
                    }
                }
                .onDelete(perform: deleteBreeders)
            }
            .navigationTitle("Breeders")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddBreeder = true }) {
                        Label("Add Breeder", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddBreeder) {
                AddBreederView()
            }
            .onAppear {
                fetchBreeders()
            }
        }
    }

    private func fetchBreeders() {
        isLoadingBreeders = true
        Task {
            do {
                let breederDTOs = try await ApiService.shared.getAllBreeders()
                await MainActor.run {
                    isLoadingBreeders = false
                }
            } catch {
                await MainActor.run {
                    isLoadingBreeders = false
                    errorMessage = "Failed to fetch breeders: \(error.localizedDescription)"
                }
            }
        }
    }

    private func deleteBreeders(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let breeder = breeders.filter { $0.isActive }[index]
                breeder.isActive = false

                Task {
                    do {
                        // TODO: Implement proper UUID to backend ID mapping
                        let breederId = abs(breeder.id.hashValue)
                        try await ApiService.shared.deleteBreeder(id: breederId)
                    } catch {
                        print("Failed to delete breeder from API: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}

struct BreederRowView: View {
    let breeder: Breeder
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(breeder.name)
                .font(.headline)
            
            HStack {
                Image(systemName: "location")
                    .foregroundColor(.secondary)
                    .font(.caption)
                Text(breeder.location)
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            
            HStack {
                Text("Established: \(breeder.establishedDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(breeder.horses.count) horses")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Add Breeder View

struct AddBreederView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var location = ""
    @State private var establishedDate = Date()
    @Query private var users: [User]
    @State private var selectedUser: User?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Breeder Information")) {
                    TextField("Name", text: $name)
                    TextField("Location", text: $location)
                    DatePicker("Established Date", selection: $establishedDate, displayedComponents: .date)
                }

                Section(header: Text("User Account")) {
                    Picker("User Account", selection: $selectedUser) {
                        Text("No User Account").tag(User?.none)
                        ForEach(users.filter { $0.isActive && $0.role == .breeder && $0.breederProfile == nil }, id: \.id) { user in
                            Text(user.name).tag(User?.some(user))
                        }
                    }
                }

                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add Breeder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button("Save") {
                            addBreeder()
                        }
                        .disabled(name.isEmpty || location.isEmpty)
                    }
                }
            }
        }
    }

    private func addBreeder() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                // Call API to create breeder
                let breederDTO = try await ApiService.shared.createBreeder(
                    name: name,
                    contactInfo: location
                )

                await MainActor.run {
                    let newBreeder = Breeder(name: name, location: location, establishedDate: establishedDate)
                    newBreeder.user = selectedUser
                    selectedUser?.breederProfile = newBreeder
                    modelContext.insert(newBreeder)
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to create breeder: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Breeder Detail View

struct BreederDetailView: View {
    @Bindable var breeder: Breeder
    @Query private var allUsers: [User]
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        Form {
            Section(header: Text("Breeder Information")) {
                TextField("Name", text: $breeder.name)
                TextField("Location", text: $breeder.location)
                DatePicker("Established Date", selection: $breeder.establishedDate, displayedComponents: .date)
                
                Toggle("Active Breeder", isOn: $breeder.isActive)
            }
            
            Section(header: Text("User Account")) {
                Picker("User Account", selection: Binding<User?>(
                    get: { breeder.user },
                    set: { 
                        breeder.user?.breederProfile = nil
                        breeder.user = $0
                        $0?.breederProfile = breeder
                    }
                )) {
                    Text("No User Account").tag(User?.none)
                    ForEach(allUsers.filter { $0.isActive && $0.role == .breeder && ($0.breederProfile == nil || $0.breederProfile?.id == breeder.id) }, id: \.id) { user in
                        Text(user.name).tag(User?.some(user))
                    }
                }
            }
            
            Section(header: Text("Statistics")) {
                HStack {
                    Text("Total Horses")
                    Spacer()
                    Text("\(breeder.horses.count)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Active Horses")
                    Spacer()
                    Text("\(breeder.horses.filter { $0.isActive }.count)")
                        .foregroundColor(.secondary)
                }
            }
            
            if !breeder.horses.isEmpty {
                Section(header: Text("Horses")) {
                    ForEach(breeder.horses.filter { $0.isActive }, id: \.id) { horse in
                        NavigationLink(destination: HorseDetailView(horse: horse)) {
                            HorseRowView(horse: horse)
                        }
                    }
                }
            }
        }
        .navigationTitle(breeder.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}