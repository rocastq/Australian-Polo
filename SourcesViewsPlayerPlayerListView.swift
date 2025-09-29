import SwiftUI
import SwiftData

struct PlayerListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var players: [Player]
    @State private var showingAddPlayer = false
    @State private var searchText = ""
    @State private var selectedHandicapFilter: HandicapFilter = .all
    
    var filteredPlayers: [Player] {
        var filtered = players
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.fullName.localizedCaseInsensitiveContains(searchText) ||
                $0.club?.name.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        // Apply handicap filter
        switch selectedHandicapFilter {
        case .all:
            break
        case .low:
            filtered = filtered.filter { $0.handicap <= 2 }
        case .medium:
            filtered = filtered.filter { $0.handicap > 2 && $0.handicap <= 6 }
        case .high:
            filtered = filtered.filter { $0.handicap > 6 }
        }
        
        return filtered.sorted { $0.fullName < $1.fullName }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Handicap Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(HandicapFilter.allCases, id: \.self) { filter in
                            Button(filter.displayName) {
                                selectedHandicapFilter = filter
                            }
                            .buttonStyle(FilterButtonStyle(isSelected: selectedHandicapFilter == filter))
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                List {
                    ForEach(filteredPlayers, id: \.id) { player in
                        NavigationLink(destination: PlayerDetailView(player: player)) {
                            PlayerRow(player: player)
                        }
                    }
                    .onDelete(perform: deletePlayers)
                }
            }
            .searchable(text: $searchText, prompt: "Search players...")
            .navigationTitle("Players")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddPlayer = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddPlayer) {
                AddPlayerView()
            }
        }
    }
    
    private func deletePlayers(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredPlayers[index])
            }
        }
    }
}

enum HandicapFilter: String, CaseIterable {
    case all = "All"
    case low = "Low (0-2)"
    case medium = "Medium (3-6)"
    case high = "High (7-10)"
    
    var displayName: String {
        return rawValue
    }
}

struct PlayerRow: View {
    let player: Player
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(player.fullName)
                    .font(.headline)
                
                Spacer()
                
                Text("\(player.handicap, specifier: "%.1f")")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            HStack {
                if let club = player.club {
                    Text(club.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let nationality = player.nationality {
                    Text("• \(nationality)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if player.totalMatches > 0 {
                    Text("\(player.totalMatches) matches")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                if player.totalGoals > 0 {
                    Text("\(player.totalGoals) goals")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("(\(player.averageGoalsPerMatch, specifier: "%.1f") avg)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let age = player.age {
                    Text("Age \(age)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if !player.teams.isEmpty {
                Text("Teams: \(player.teams.map { $0.name }.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddPlayerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var clubs: [Club]
    @Query private var users: [User]
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var handicap = 0.0
    @State private var selectedClub: Club?
    @State private var selectedUser: User?
    @State private var birthDate = Date()
    @State private var nationality = ""
    @State private var showingBirthDate = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Player Details") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Handicap")
                            Spacer()
                            Text("\(handicap, specifier: "%.1f")")
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                        }
                        Slider(value: $handicap, in: -2...10, step: 0.5)
                    }
                    
                    Picker("Club", selection: $selectedClub) {
                        Text("No Club").tag(nil as Club?)
                        ForEach(clubs, id: \.id) { club in
                            Text(club.name).tag(club as Club?)
                        }
                    }
                }
                
                Section("Additional Information") {
                    Toggle("Set Birth Date", isOn: $showingBirthDate)
                    
                    if showingBirthDate {
                        DatePicker("Birth Date", selection: $birthDate, displayedComponents: .date)
                    }
                    
                    TextField("Nationality (Optional)", text: $nationality)
                    
                    Picker("Link to User Account", selection: $selectedUser) {
                        Text("No User Account").tag(nil as User?)
                        ForEach(users.filter { $0.profileType == .player || $0.profileType == .user }, id: \.id) { user in
                            Text(user.fullName).tag(user as User?)
                        }
                    }
                }
            }
            .navigationTitle("New Player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        savePlayer()
                    }
                    .disabled(firstName.isEmpty || lastName.isEmpty)
                }
            }
        }
    }
    
    private func savePlayer() {
        let player = Player(
            firstName: firstName,
            lastName: lastName,
            handicap: handicap,
            user: selectedUser,
            club: selectedClub,
            birthDate: showingBirthDate ? birthDate : nil,
            nationality: nationality.isEmpty ? nil : nationality
        )
        
        modelContext.insert(player)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving player: \(error)")
        }
    }
}

#Preview {
    PlayerListView()
        .modelContainer(for: [Player.self, Club.self, User.self])
}