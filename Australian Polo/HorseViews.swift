//
//  HorseViews.swift
//  Australian Polo
//
//  Created by Rodrigo Castillo on 9/29/25.
//

import SwiftUI
import SwiftData

// MARK: - Horse List View

struct HorseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var horses: [Horse]
    @State private var showingAddHorse = false
    @State private var isLoadingHorses = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            List {
                ForEach(horses.filter { $0.isActive }) { horse in
                    NavigationLink(destination: HorseDetailView(horse: horse)) {
                        HorseRowView(horse: horse)
                    }
                }
                .onDelete(perform: deleteHorses)
            }
            .navigationTitle("Horses")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddHorse = true }) {
                        Label("Add Horse", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddHorse) {
                AddHorseView()
            }
            .onAppear {
                fetchHorses()
            }
        }
    }

    private func fetchHorses() {
        isLoadingHorses = true
        Task {
            do {
                let horseDTOs = try await ApiService.shared.getAllHorses()
                await MainActor.run {
                    isLoadingHorses = false
                }
            } catch {
                await MainActor.run {
                    isLoadingHorses = false
                    errorMessage = "Failed to fetch horses: \(error.localizedDescription)"
                }
            }
        }
    }

    private func deleteHorses(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let horse = horses.filter { $0.isActive }[index]
                horse.isActive = false

                Task {
                    do {
                        if let horseId = horse.id.hashValue as? Int {
                            try await ApiService.shared.deleteHorse(id: horseId)
                        }
                    } catch {
                        print("Failed to delete horse from API: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}

struct HorseRowView: View {
    let horse: Horse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(horse.name)
                    .font(.headline)
                Spacer()
                Text("\(horse.age) years")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.brown)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            HStack {
                Text(horse.gender.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("•")
                    .foregroundColor(.secondary)
                Text(horse.color.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Games: \(horse.gamesPlayed)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("Tournaments Won: \(horse.tournamentsWon)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                if let owner = horse.owner {
                    Text("Owner: \(owner.name)")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            
            if !horse.awards.isEmpty {
                Text("Awards: \(horse.awards.joined(separator: ", "))")
                    .font(.caption2)
                    .foregroundColor(.green)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Add Horse View

struct AddHorseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var birthDate = Date()
    @State private var selectedGender: HorseGender = .gelding
    @State private var selectedColor: HorseColor = .bay
    @State private var pedigree = ""
    @Query private var breeders: [Breeder]
    @Query private var players: [Player]
    @State private var selectedBreeder: Breeder?
    @State private var selectedOwner: Player?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Horse Information")) {
                    TextField("Name", text: $name)
                    DatePicker("Birth Date", selection: $birthDate, displayedComponents: .date)

                    Picker("Gender", selection: $selectedGender) {
                        ForEach(HorseGender.allCases, id: \.self) { gender in
                            Text(gender.rawValue).tag(gender)
                        }
                    }

                    Picker("Color", selection: $selectedColor) {
                        ForEach(HorseColor.allCases, id: \.self) { color in
                            Text(color.rawValue).tag(color)
                        }
                    }

                    TextField("Pedigree", text: $pedigree, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section(header: Text("Associations")) {
                    Picker("Breeder", selection: $selectedBreeder) {
                        Text("No Breeder").tag(Breeder?.none)
                        ForEach(breeders.filter { $0.isActive }, id: \.id) { breeder in
                            Text(breeder.name).tag(Breeder?.some(breeder))
                        }
                    }

                    Picker("Owner", selection: $selectedOwner) {
                        Text("No Owner").tag(Player?.none)
                        ForEach(players.filter { $0.isActive }, id: \.id) { player in
                            Text(player.name).tag(Player?.some(player))
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
            .navigationTitle("Add Horse")
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
                            addHorse()
                        }
                        .disabled(name.isEmpty)
                    }
                }
            }
        }
    }

    private func addHorse() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                // Build pedigree dictionary (simplified for now)
                let pedigreeDict: [String: String]? = pedigree.isEmpty ? nil : ["info": pedigree]

                // Call API to create horse
                let horseDTO = try await ApiService.shared.createHorse(
                    name: name,
                    pedigree: pedigreeDict,
                    breederId: selectedBreeder?.id.hashValue
                )

                await MainActor.run {
                    let newHorse = Horse(name: name, birthDate: birthDate, gender: selectedGender, color: selectedColor, pedigree: pedigree)
                    newHorse.breeder = selectedBreeder
                    newHorse.owner = selectedOwner
                    modelContext.insert(newHorse)
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to create horse: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Horse Detail View

struct HorseDetailView: View {
    @Bindable var horse: Horse
    @Query private var allBreeders: [Breeder]
    @Query private var allPlayers: [Player]
    @Environment(\.modelContext) private var modelContext
    @State private var newAward = ""
    @State private var showingAddAward = false
    
    var body: some View {
        Form {
            Section(header: Text("Horse Information")) {
                TextField("Name", text: $horse.name)
                DatePicker("Birth Date", selection: $horse.birthDate, displayedComponents: .date)
                
                Picker("Gender", selection: $horse.gender) {
                    ForEach(HorseGender.allCases, id: \.self) { gender in
                        Text(gender.rawValue).tag(gender)
                    }
                }
                
                Picker("Color", selection: $horse.color) {
                    ForEach(HorseColor.allCases, id: \.self) { color in
                        Text(color.rawValue).tag(color)
                    }
                }
                
                TextField("Pedigree", text: $horse.pedigree, axis: .vertical)
                    .lineLimit(3...6)
                
                Toggle("Active Horse", isOn: $horse.isActive)
            }
            
            Section(header: Text("Details")) {
                HStack {
                    Text("Age")
                    Spacer()
                    Text("\(horse.age) years")
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Associations")) {
                Picker("Breeder", selection: Binding<Breeder?>(
                    get: { horse.breeder },
                    set: { horse.breeder = $0 }
                )) {
                    Text("No Breeder").tag(Breeder?.none)
                    ForEach(allBreeders.filter { $0.isActive }, id: \.id) { breeder in
                        Text(breeder.name).tag(Breeder?.some(breeder))
                    }
                }
                
                Picker("Owner", selection: Binding<Player?>(
                    get: { horse.owner },
                    set: { horse.owner = $0 }
                )) {
                    Text("No Owner").tag(Player?.none)
                    ForEach(allPlayers.filter { $0.isActive }, id: \.id) { player in
                        Text(player.name).tag(Player?.some(player))
                    }
                }
            }
            
            Section(header: Text("Statistics")) {
                HStack {
                    Text("Games Played")
                    Spacer()
                    Text("\(horse.gamesPlayed)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Tournaments Won")
                    Spacer()
                    Text("\(horse.tournamentsWon)")
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: HStack {
                Text("Awards (\(horse.awards.count))")
                Spacer()
                Button("Add Award") {
                    showingAddAward = true
                }
                .font(.caption)
            }) {
                ForEach(horse.awards, id: \.self) { award in
                    HStack {
                        Text(award)
                        Spacer()
                        Button("Remove") {
                            horse.awards.removeAll { $0 == award }
                        }
                        .foregroundColor(.red)
                        .font(.caption)
                    }
                }
                
                if horse.awards.isEmpty {
                    Text("No awards yet")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            
            if let breeder = horse.breeder {
                Section(header: Text("Breeder Details")) {
                    NavigationLink(destination: BreederDetailView(breeder: breeder)) {
                        BreederRowView(breeder: breeder)
                    }
                }
            }
            
            if let owner = horse.owner {
                Section(header: Text("Owner Details")) {
                    NavigationLink(destination: PlayerDetailView(player: owner)) {
                        PlayerRowView(player: owner)
                    }
                }
            }
        }
        .navigationTitle(horse.name)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Add Award", isPresented: $showingAddAward) {
            TextField("Award Name", text: $newAward)
            Button("Add") {
                if !newAward.isEmpty {
                    horse.awards.append(newAward)
                    newAward = ""
                }
            }
            Button("Cancel", role: .cancel) {
                newAward = ""
            }
        } message: {
            Text("Enter the name of the award or achievement.")
        }
    }
}