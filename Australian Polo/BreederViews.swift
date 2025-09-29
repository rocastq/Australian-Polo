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
        }
    }
    
    private func deleteBreeders(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let breeder = breeders.filter { $0.isActive }[index]
                breeder.isActive = false
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
            }
            .navigationTitle("Add Breeder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        addBreeder()
                    }
                    .disabled(name.isEmpty || location.isEmpty)
                }
            }
        }
    }
    
    private func addBreeder() {
        let newBreeder = Breeder(name: name, location: location, establishedDate: establishedDate)
        newBreeder.user = selectedUser
        selectedUser?.breederProfile = newBreeder
        modelContext.insert(newBreeder)
        dismiss()
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