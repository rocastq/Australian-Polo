import SwiftUI
import SwiftData

struct HorseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var horses: [Horse]
    @State private var showingAddHorse = false
    @State private var searchText = ""
    @State private var selectedGenderFilter: HorseGender?
    @State private var selectedColorFilter: HorseColor?
    
    var filteredHorses: [Horse] {
        var filtered = horses
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.breeder?.fullName.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        // Apply gender filter
        if let gender = selectedGenderFilter {
            filtered = filtered.filter { $0.gender == gender }
        }
        
        // Apply color filter
        if let color = selectedColorFilter {
            filtered = filtered.filter { $0.color == color }
        }
        
        return filtered.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        Menu("Gender") {
                            Button("All Genders") {
                                selectedGenderFilter = nil
                            }
                            ForEach(HorseGender.allCases, id: \.self) { gender in
                                Button(gender.rawValue) {
                                    selectedGenderFilter = gender
                                }
                            }
                        }
                        .buttonStyle(FilterMenuButtonStyle(isSelected: selectedGenderFilter != nil))
                        
                        Menu("Color") {
                            Button("All Colors") {
                                selectedColorFilter = nil
                            }
                            ForEach(HorseColor.allCases, id: \.self) { color in
                                Button(color.rawValue) {
                                    selectedColorFilter = color
                                }
                            }
                        }
                        .buttonStyle(FilterMenuButtonStyle(isSelected: selectedColorFilter != nil))
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                List {
                    ForEach(filteredHorses, id: \.id) { horse in
                        NavigationLink(destination: HorseDetailView(horse: horse)) {
                            HorseRow(horse: horse)
                        }
                    }
                    .onDelete(perform: deleteHorses)
                }
            }
            .searchable(text: $searchText, prompt: "Search horses...")
            .navigationTitle("Horses")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddHorse = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddHorse) {
                AddHorseView()
            }
        }
    }
    
    private func deleteHorses(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredHorses[index])
            }
        }
    }
}

struct FilterMenuButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                isSelected ? Color.blue : Color(.systemGray5)
            )
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct HorseRow: View {
    let horse: Horse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(horse.name)
                    .font(.headline)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(horse.gender.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                    
                    Text("\(horse.age) years")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Text(horse.color.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let breeder = horse.breeder {
                    Text("• Bred by \(breeder.fullName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            if let registrationNumber = horse.registrationNumber {
                Text("Reg: \(registrationNumber)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                if horse.totalGames > 0 {
                    Text("\(horse.totalGames) games")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if horse.totalTournaments > 0 {
                    Text("• \(horse.totalTournaments) tournaments")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !horse.awards.isEmpty {
                    Text("\(horse.awards.count) awards")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            // Pedigree info if available
            if horse.sire != nil || horse.dam != nil {
                HStack {
                    if let sire = horse.sire {
                        Text("Sire: \(sire)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let dam = horse.dam {
                        Text("Dam: \(dam)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddHorseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var breeders: [User]
    
    @State private var name = ""
    @State private var birthDate = Date()
    @State private var selectedGender = HorseGender.gelding
    @State private var selectedColor = HorseColor.bay
    @State private var selectedBreeder: User?
    @State private var sire = ""
    @State private var dam = ""
    @State private var registrationNumber = ""
    @State private var notes = ""
    
    var availableBreeders: [User] {
        breeders.filter { $0.profileType == .breeder }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Horse Details") {
                    TextField("Horse Name", text: $name)
                    
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
                }
                
                Section("Pedigree") {
                    TextField("Sire (Optional)", text: $sire)
                    TextField("Dam (Optional)", text: $dam)
                    
                    Picker("Breeder", selection: $selectedBreeder) {
                        Text("Unknown Breeder").tag(nil as User?)
                        ForEach(availableBreeders, id: \.id) { breeder in
                            Text(breeder.fullName).tag(breeder as User?)
                        }
                    }
                }
                
                Section("Registration & Notes") {
                    TextField("Registration Number (Optional)", text: $registrationNumber)
                    TextField("Notes (Optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New Horse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveHorse()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveHorse() {
        let horse = Horse(
            name: name,
            birthDate: birthDate,
            gender: selectedGender,
            color: selectedColor,
            breeder: selectedBreeder,
            sire: sire.isEmpty ? nil : sire,
            dam: dam.isEmpty ? nil : dam,
            registrationNumber: registrationNumber.isEmpty ? nil : registrationNumber,
            notes: notes.isEmpty ? nil : notes
        )
        
        modelContext.insert(horse)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving horse: \(error)")
        }
    }
}

#Preview {
    HorseListView()
        .modelContainer(for: [Horse.self, User.self])
}