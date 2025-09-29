import SwiftUI
import SwiftData

struct TeamDetailView: View {
    let team: Team
    @Environment(\.modelContext) private var modelContext
    @State private var showingEditTeam = false
    @State private var showingAddPlayer = false
    @State private var selectedTab = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Team Header
                TeamHeaderView(team: team)
                
                // Tab Selection
                Picker("View", selection: $selectedTab) {
                    Text("Players").tag(0)
                    Text("Statistics").tag(1)
                    Text("Matches").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Tab Content
                Group {
                    switch selectedTab {
                    case 0:
                        TeamPlayersView(team: team, showingAddPlayer: $showingAddPlayer)
                    case 1:
                        TeamStatisticsView(team: team)
                    case 2:
                        TeamMatchesView(team: team)
                    default:
                        TeamPlayersView(team: team, showingAddPlayer: $showingAddPlayer)
                    }
                }
            }
        }
        .navigationTitle(team.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingEditTeam = true
                    } label: {
                        Label("Edit Team", systemImage: "pencil")
                    }
                    
                    Button {
                        showingAddPlayer = true
                    } label: {
                        Label("Add Player", systemImage: "person.badge.plus")
                    }
                    
                    Button(role: .destructive) {
                        deleteTeam()
                    } label: {
                        Label("Delete Team", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditTeam) {
            EditTeamView(team: team)
        }
        .sheet(isPresented: $showingAddPlayer) {
            AddPlayerToTeamView(team: team)
        }
    }
    
    private func deleteTeam() {
        modelContext.delete(team)
        try? modelContext.save()
    }
}

struct TeamHeaderView: View {
    let team: Team
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Team color indicator
                if let colorName = team.teamColor {
                    Circle()
                        .fill(colorFromString(colorName))
                        .frame(width: 24, height: 24)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(team.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(team.grade.rawValue)
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if team.isActive {
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
            
            if let club = team.club {
                Label(club.name, systemImage: "building.2")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Team Statistics
            HStack(spacing: 30) {
                VStack {
                    Text("\(team.players.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Players")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(team.totalHandicap, specifier: "%.1f")")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Total Handicap")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(team.wins)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Wins")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(team.losses)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Losses")
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
    
    private func colorFromString(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "yellow": return .yellow
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "black": return .black
        case "white": return .white
        case "gray": return .gray
        default: return .blue
        }
    }
}

struct TeamPlayersView: View {
    let team: Team
    @Binding var showingAddPlayer: Bool
    
    var sortedPlayers: [Player] {
        team.players.sorted { $0.handicap > $1.handicap }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Players (\(team.players.count))")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    showingAddPlayer = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }
            .padding(.horizontal)
            
            if sortedPlayers.isEmpty {
                Text("No players assigned to this team")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(sortedPlayers, id: \.id) { player in
                        PlayerInTeamRow(player: player, team: team)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct PlayerInTeamRow: View {
    let player: Player
    let team: Team
    @Environment(\.modelContext) private var modelContext
    
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
                    
                    if let club = player.club {
                        Text("• \(club.name)")
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
                
                if player.totalMatches > 0 {
                    Text("\(player.averageGoalsPerMatch, specifier: "%.1f") avg")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Button {
                removePlayerFromTeam()
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 1)
    }
    
    private func removePlayerFromTeam() {
        if let index = team.players.firstIndex(of: player) {
            team.players.remove(at: index)
            try? modelContext.save()
        }
    }
}

struct TeamStatisticsView: View {
    let team: Team
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Team Statistics")
                .font(.headline)
                .padding(.horizontal)
            
            // Performance Statistics
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatCard(title: "Win Rate", value: "\(team.winPercentage, specifier: "%.1f")%", systemImage: "percent", color: .green)
                StatCard(title: "Total Matches", value: "\(team.allMatches.count)", systemImage: "sportscourt.fill", color: .blue)
                StatCard(title: "Goals For", value: "\(totalGoalsFor)", systemImage: "target", color: .orange)
                StatCard(title: "Goals Against", value: "\(totalGoalsAgainst)", systemImage: "shield.fill", color: .red)
            }
            .padding(.horizontal)
            
            // Recent Form
            if !team.allMatches.isEmpty {
                Text("Recent Matches")
                    .font(.headline)
                    .padding(.horizontal)
                
                LazyVStack(spacing: 8) {
                    ForEach(team.allMatches.sorted { $0.date > $1.date }.prefix(5), id: \.id) { match in
                        TeamMatchResultRow(match: match, team: team)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var totalGoalsFor: Int {
        team.allMatches.reduce(0) { total, match in
            if match.teamA == team {
                return total + match.teamAScore
            } else {
                return total + match.teamBScore
            }
        }
    }
    
    private var totalGoalsAgainst: Int {
        team.allMatches.reduce(0) { total, match in
            if match.teamA == team {
                return total + match.teamBScore
            } else {
                return total + match.teamAScore
            }
        }
    }
}

struct TeamMatchesView: View {
    let team: Team
    
    var sortedMatches: [Match] {
        team.allMatches.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Match History")
                .font(.headline)
                .padding(.horizontal)
            
            if sortedMatches.isEmpty {
                Text("No matches played yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(sortedMatches, id: \.id) { match in
                        TeamMatchHistoryRow(match: match, team: team)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct TeamMatchResultRow: View {
    let match: Match
    let team: Team
    
    var isWin: Bool {
        match.winner == team
    }
    
    var opponent: Team? {
        if match.teamA == team {
            return match.teamB
        } else {
            return match.teamA
        }
    }
    
    var teamScore: Int {
        if match.teamA == team {
            return match.teamAScore
        } else {
            return match.teamBScore
        }
    }
    
    var opponentScore: Int {
        if match.teamA == team {
            return match.teamBScore
        } else {
            return match.teamAScore
        }
    }
    
    var body: some View {
        HStack {
            // Result indicator
            Text(isWin ? "W" : (teamScore == opponentScore ? "D" : "L"))
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(isWin ? Color.green : (teamScore == opponentScore ? Color.gray : Color.red))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("vs \(opponent?.name ?? "TBA")")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(match.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(teamScore) - \(opponentScore)")
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color(.systemGray6))
        .cornerRadius(6)
    }
}

struct TeamMatchHistoryRow: View {
    let match: Match
    let team: Team
    
    var opponent: Team? {
        if match.teamA == team {
            return match.teamB
        } else {
            return match.teamA
        }
    }
    
    var teamScore: Int {
        if match.teamA == team {
            return match.teamAScore
        } else {
            return match.teamBScore
        }
    }
    
    var opponentScore: Int {
        if match.teamA == team {
            return match.teamBScore
        } else {
            return match.teamAScore
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("vs \(opponent?.name ?? "TBA")")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                if match.status == .completed {
                    Text("\(teamScore) - \(opponentScore)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(teamScore > opponentScore ? .green : (teamScore == opponentScore ? .gray : .red))
                }
            }
            
            HStack {
                Text(match.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let tournament = match.tournament {
                    Text("• \(tournament.name)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(match.status.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(statusColor(for: match.status))
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 1)
    }
    
    private func statusColor(for status: MatchStatus) -> Color {
        switch status {
        case .scheduled: return .blue
        case .inProgress: return .green
        case .completed: return .gray
        case .cancelled: return .red
        case .postponed: return .orange
        }
    }
}

struct AddPlayerToTeamView: View {
    let team: Team
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allPlayers: [Player]
    @State private var selectedPlayers: Set<Player> = []
    
    var availablePlayers: [Player] {
        allPlayers.filter { player in
            !team.players.contains(player) && player.isActive
        }.sorted { $0.fullName < $1.fullName }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(availablePlayers, id: \.id) { player in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(player.fullName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            HStack {
                                Text("Handicap: \(player.handicap, specifier: "%.1f")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if let club = player.club {
                                    Text("• \(club.name)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        if selectedPlayers.contains(player) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(.gray)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        togglePlayerSelection(player)
                    }
                }
            }
            .navigationTitle("Add Players")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        addSelectedPlayers()
                    }
                    .disabled(selectedPlayers.isEmpty)
                }
            }
        }
    }
    
    private func togglePlayerSelection(_ player: Player) {
        if selectedPlayers.contains(player) {
            selectedPlayers.remove(player)
        } else {
            selectedPlayers.insert(player)
        }
    }
    
    private func addSelectedPlayers() {
        for player in selectedPlayers {
            team.players.append(player)
        }
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error adding players to team: \(error)")
        }
    }
}

struct EditTeamView: View {
    let team: Team
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var clubs: [Club]
    
    @State private var name: String
    @State private var selectedGrade: Grade
    @State private var selectedClub: Club?
    @State private var teamColor: String
    @State private var isActive: Bool
    
    init(team: Team) {
        self.team = team
        self._name = State(initialValue: team.name)
        self._selectedGrade = State(initialValue: team.grade)
        self._selectedClub = State(initialValue: team.club)
        self._teamColor = State(initialValue: team.teamColor ?? "")
        self._isActive = State(initialValue: team.isActive)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Team Details") {
                    TextField("Team Name", text: $name)
                    
                    Picker("Grade", selection: $selectedGrade) {
                        ForEach(Grade.allCases, id: \.self) { grade in
                            Text(grade.rawValue).tag(grade)
                        }
                    }
                    
                    Picker("Club", selection: $selectedClub) {
                        Text("No Club").tag(nil as Club?)
                        ForEach(clubs, id: \.id) { club in
                            Text(club.name).tag(club as Club?)
                        }
                    }
                    
                    TextField("Team Color", text: $teamColor)
                }
                
                Section {
                    Toggle("Active Team", isOn: $isActive)
                }
            }
            .navigationTitle("Edit Team")
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
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveChanges() {
        team.name = name
        team.grade = selectedGrade
        team.club = selectedClub
        team.teamColor = teamColor.isEmpty ? nil : teamColor
        team.isActive = isActive
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving team changes: \(error)")
        }
    }
}

#Preview {
    let team = Team(
        name: "Los Alamos",
        grade: .high,
        teamColor: "Blue"
    )
    
    return TeamDetailView(team: team)
        .modelContainer(for: [Team.self, Player.self, Club.self])
}