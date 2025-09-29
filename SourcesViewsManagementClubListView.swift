import SwiftUI
import SwiftData

struct ClubListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var clubs: [Club]
    @State private var showingAddClub = false
    @State private var searchText = ""
    
    var filteredClubs: [Club] {
        if searchText.isEmpty {
            return clubs.sorted { $0.name < $1.name }
        } else {
            return clubs.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.location.localizedCaseInsensitiveContains(searchText)
            }.sorted { $0.name < $1.name }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredClubs, id: \.id) { club in
                    NavigationLink(destination: ClubDetailView(club: club)) {
                        ClubRow(club: club)
                    }
                }
                .onDelete(perform: deleteClubs)
            }
            .searchable(text: $searchText, prompt: "Search clubs...")
            .navigationTitle("Clubs")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddClub = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddClub) {
                AddClubView()
            }
        }
    }
    
    private func deleteClubs(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredClubs[index])
            }
        }
    }
}

struct ClubRow: View {
    let club: Club
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(club.name)
                    .font(.headline)
                
                Spacer()
                
                if !club.isActive {
                    Text("Inactive")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            Text(club.location)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                if let email = club.contactEmail {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let phone = club.contactPhone {
                    Text("• \(phone)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Text("\(club.teams.count) teams")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text("• \(club.players.count) players")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                if club.tournaments.count > 0 {
                    Text("• \(club.tournaments.count) tournaments")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct ClubDetailView: View {
    let club: Club
    @Environment(\.modelContext) private var modelContext
    @State private var showingEditClub = false
    @State private var selectedTab = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Club Header
                ClubHeaderView(club: club)
                
                // Tab Selection
                Picker("View", selection: $selectedTab) {
                    Text("Teams").tag(0)
                    Text("Players").tag(1)
                    Text("Tournaments").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Tab Content
                Group {
                    switch selectedTab {
                    case 0:
                        ClubTeamsView(club: club)
                    case 1:
                        ClubPlayersView(club: club)
                    case 2:
                        ClubTournamentsView(club: club)
                    default:
                        ClubTeamsView(club: club)
                    }
                }
            }
        }
        .navigationTitle(club.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingEditClub = true
                    } label: {
                        Label("Edit Club", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        deleteClub()
                    } label: {
                        Label("Delete Club", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditClub) {
            EditClubView(club: club)
        }
    }
    
    private func deleteClub() {
        modelContext.delete(club)
        try? modelContext.save()
    }
}

struct ClubHeaderView: View {
    let club: Club
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(club.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(club.location)
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if club.isActive {
                        Text("Active")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            
            // Contact Information
            VStack(alignment: .leading, spacing: 8) {
                if let email = club.contactEmail {
                    Label(email, systemImage: "envelope")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let phone = club.contactPhone {
                    Label(phone, systemImage: "phone")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let website = club.website {
                    Label(website, systemImage: "globe")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            
            // Club Statistics
            HStack(spacing: 30) {
                VStack {
                    Text("\(club.teams.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Teams")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(club.players.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Players")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(club.tournaments.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Tournaments")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct ClubTeamsView: View {
    let club: Club
    
    var sortedTeams: [Team] {
        club.teams.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Teams (\(club.teams.count))")
                .font(.headline)
                .padding(.horizontal)
            
            if sortedTeams.isEmpty {
                Text("No teams registered with this club")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(sortedTeams, id: \.id) { team in
                        ClubTeamRow(team: team)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct ClubTeamRow: View {
    let team: Team
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(team.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Text(team.grade.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                    
                    Text("\(team.players.count) players")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Record: \(team.wins)W - \(team.losses)L")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Handicap: \(team.totalHandicap, specifier: "%.1f")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 1)
    }
}

struct ClubPlayersView: View {
    let club: Club
    
    var sortedPlayers: [Player] {
        club.players.sorted { $0.fullName < $1.fullName }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Players (\(club.players.count))")
                .font(.headline)
                .padding(.horizontal)
            
            if sortedPlayers.isEmpty {
                Text("No players registered with this club")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(sortedPlayers, id: \.id) { player in
                        ClubPlayerRow(player: player)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct ClubPlayerRow: View {
    let player: Player
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(player.fullName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Text("Handicap: \(player.handicap, specifier: "%.1f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let nationality = player.nationality {
                        Text("• \(nationality)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(player.totalGoals) goals")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(player.totalMatches) matches")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 1)
    }
}

struct ClubTournamentsView: View {
    let club: Club
    
    var sortedTournaments: [Tournament] {
        club.tournaments.sorted { $0.startDate > $1.startDate }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tournaments (\(club.tournaments.count))")
                .font(.headline)
                .padding(.horizontal)
            
            if sortedTournaments.isEmpty {
                Text("No tournaments associated with this club")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(sortedTournaments, id: \.id) { tournament in
                        ClubTournamentRow(tournament: tournament)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct ClubTournamentRow: View {
    let tournament: Tournament
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(tournament.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Text(tournament.grade.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(4)
                    
                    Text(tournament.startDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if tournament.isActive {
                    Text("Active")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                
                Text("\(tournament.matches.count) matches")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 1)
    }
}

struct AddClubView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var location = ""
    @State private var contactEmail = ""
    @State private var contactPhone = ""
    @State private var website = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Club Details") {
                    TextField("Club Name", text: $name)
                    TextField("Location", text: $location)
                }
                
                Section("Contact Information") {
                    TextField("Email (Optional)", text: $contactEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    TextField("Phone (Optional)", text: $contactPhone)
                        .keyboardType(.phonePad)
                    
                    TextField("Website (Optional)", text: $website)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("New Club")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveClub()
                    }
                    .disabled(name.isEmpty || location.isEmpty)
                }
            }
        }
    }
    
    private func saveClub() {
        let club = Club(
            name: name,
            location: location,
            contactEmail: contactEmail.isEmpty ? nil : contactEmail,
            contactPhone: contactPhone.isEmpty ? nil : contactPhone,
            website: website.isEmpty ? nil : website
        )
        
        modelContext.insert(club)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving club: \(error)")
        }
    }
}

struct EditClubView: View {
    let club: Club
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name: String
    @State private var location: String
    @State private var contactEmail: String
    @State private var contactPhone: String
    @State private var website: String
    @State private var isActive: Bool
    
    init(club: Club) {
        self.club = club
        self._name = State(initialValue: club.name)
        self._location = State(initialValue: club.location)
        self._contactEmail = State(initialValue: club.contactEmail ?? "")
        self._contactPhone = State(initialValue: club.contactPhone ?? "")
        self._website = State(initialValue: club.website ?? "")
        self._isActive = State(initialValue: club.isActive)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Club Details") {
                    TextField("Club Name", text: $name)
                    TextField("Location", text: $location)
                }
                
                Section("Contact Information") {
                    TextField("Email", text: $contactEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    TextField("Phone", text: $contactPhone)
                        .keyboardType(.phonePad)
                    
                    TextField("Website", text: $website)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
                
                Section {
                    Toggle("Active Club", isOn: $isActive)
                }
            }
            .navigationTitle("Edit Club")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(name.isEmpty || location.isEmpty)
                }
            }
        }
    }
    
    private func saveChanges() {
        club.name = name
        club.location = location
        club.contactEmail = contactEmail.isEmpty ? nil : contactEmail
        club.contactPhone = contactPhone.isEmpty ? nil : contactPhone
        club.website = website.isEmpty ? nil : website
        club.isActive = isActive
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving club changes: \(error)")
        }
    }
}

#Preview {
    ClubListView()
        .modelContainer(for: [Club.self, Team.self, Player.self, Tournament.self])
}