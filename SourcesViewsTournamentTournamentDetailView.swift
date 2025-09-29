import SwiftUI
import SwiftData

struct TournamentDetailView: View {
    let tournament: Tournament
    @Environment(\.modelContext) private var modelContext
    @State private var showingEditTournament = false
    @State private var selectedTab = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Tournament Header
                TournamentHeaderView(tournament: tournament)
                
                // Tab Selection
                Picker("View", selection: $selectedTab) {
                    Text("Overview").tag(0)
                    Text("Matches").tag(1)
                    Text("Statistics").tag(2)
                    Text("Awards").tag(3)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Tab Content
                Group {
                    switch selectedTab {
                    case 0:
                        TournamentOverviewView(tournament: tournament)
                    case 1:
                        TournamentMatchesView(tournament: tournament)
                    case 2:
                        TournamentStatisticsView(tournament: tournament)
                    case 3:
                        TournamentAwardsView(tournament: tournament)
                    default:
                        TournamentOverviewView(tournament: tournament)
                    }
                }
            }
        }
        .navigationTitle(tournament.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingEditTournament = true
                    } label: {
                        Label("Edit Tournament", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        deleteTournament()
                    } label: {
                        Label("Delete Tournament", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditTournament) {
            EditTournamentView(tournament: tournament)
        }
    }
    
    private func deleteTournament() {
        modelContext.delete(tournament)
        try? modelContext.save()
    }
}

struct TournamentHeaderView: View {
    let tournament: Tournament
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tournament.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(tournament.grade.rawValue)
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if tournament.isActive {
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
            
            HStack(spacing: 20) {
                Label(tournament.startDate, style: .date, systemImage: "calendar")
                    .font(.subheadline)
                
                if let location = tournament.location {
                    Label(location, systemImage: "location")
                        .font(.subheadline)
                }
            }
            .foregroundColor(.secondary)
            
            Text("Duration: \(tournament.duration) days")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct TournamentOverviewView: View {
    let tournament: Tournament
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Quick Stats
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatCard(title: "Matches", value: "\(tournament.matches.count)", systemImage: "sportscourt.fill", color: .blue)
                StatCard(title: "Teams", value: "\(uniqueTeams.count)", systemImage: "person.3.fill", color: .green)
                StatCard(title: "Fields", value: "\(tournament.fields.count)", systemImage: "map.fill", color: .orange)
                StatCard(title: "Awards", value: "\(tournament.awards.count)", systemImage: "trophy.fill", color: .purple)
            }
            
            // Recent Activity
            if !tournament.matches.isEmpty {
                Text("Recent Matches")
                    .font(.headline)
                    .padding(.horizontal)
                
                LazyVStack {
                    ForEach(tournament.matches.sorted { $0.date > $1.date }.prefix(3), id: \.id) { match in
                        RecentMatchRow(match: match)
                    }
                }
            }
        }
        .padding()
    }
    
    private var uniqueTeams: Set<Team> {
        var teams = Set<Team>()
        for match in tournament.matches {
            if let teamA = match.teamA { teams.insert(teamA) }
            if let teamB = match.teamB { teams.insert(teamB) }
        }
        return teams
    }
}

struct TournamentMatchesView: View {
    let tournament: Tournament
    @State private var showingAddMatch = false
    
    var sortedMatches: [Match] {
        tournament.matches.sorted { $0.date < $1.date }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Matches")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    showingAddMatch = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }
            .padding(.horizontal)
            
            if sortedMatches.isEmpty {
                Text("No matches scheduled")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVStack {
                    ForEach(sortedMatches, id: \.id) { match in
                        MatchRow(match: match)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddMatch) {
            // AddMatchView would go here
            Text("Add Match View")
        }
    }
}

struct TournamentStatisticsView: View {
    let tournament: Tournament
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tournament Statistics")
                .font(.headline)
                .padding(.horizontal)
            
            // Add tournament statistics here
            Text("Statistics coming soon...")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        }
    }
}

struct TournamentAwardsView: View {
    let tournament: Tournament
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Awards")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    // Add award action
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }
            .padding(.horizontal)
            
            if tournament.awards.isEmpty {
                Text("No awards yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVStack {
                    ForEach(tournament.awards, id: \.id) { award in
                        AwardRow(award: award)
                    }
                }
            }
        }
    }
}

struct RecentMatchRow: View {
    let match: Match
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(match.teamA?.name ?? "TBA") vs \(match.teamB?.name ?? "TBA")")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(match.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if match.status == .completed {
                Text("\(match.teamAScore) - \(match.teamBScore)")
                    .font(.subheadline)
                    .fontWeight(.medium)
            } else {
                Text(match.status.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct MatchRow: View {
    let match: Match
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(match.teamA?.name ?? "TBA") vs \(match.teamB?.name ?? "TBA")")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Text(match.date, style: .date)
                        Text(match.startTime, style: .time)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if match.status == .completed {
                        Text("\(match.teamAScore) - \(match.teamBScore)")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    
                    Text(match.status.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(statusColor(for: match.status))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
            }
            
            if let field = match.field {
                Text("Field: \(field.name)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 1)
        .padding(.horizontal)
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

struct AwardRow: View {
    let award: Award
    
    var body: some View {
        HStack {
            Image(systemName: "trophy.fill")
                .foregroundColor(.yellow)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(award.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(award.awardType.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let player = award.player {
                    Text("Player: \(player.fullName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if let team = award.team {
                    Text("Team: \(team.name)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if let horse = award.horse {
                    Text("Horse: \(horse.name)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(award.dateAwarded, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

struct EditTournamentView: View {
    let tournament: Tournament
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var selectedGrade: Grade
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var location: String
    @State private var isActive: Bool
    
    init(tournament: Tournament) {
        self.tournament = tournament
        self._name = State(initialValue: tournament.name)
        self._selectedGrade = State(initialValue: tournament.grade)
        self._startDate = State(initialValue: tournament.startDate)
        self._endDate = State(initialValue: tournament.endDate)
        self._location = State(initialValue: tournament.location ?? "")
        self._isActive = State(initialValue: tournament.isActive)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Tournament Details") {
                    TextField("Tournament Name", text: $name)
                    
                    Picker("Grade", selection: $selectedGrade) {
                        ForEach(Grade.allCases, id: \.self) { grade in
                            Text(grade.rawValue).tag(grade)
                        }
                    }
                    
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    
                    TextField("Location", text: $location)
                }
                
                Section {
                    Toggle("Active Tournament", isOn: $isActive)
                }
            }
            .navigationTitle("Edit Tournament")
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
        tournament.name = name
        tournament.grade = selectedGrade
        tournament.startDate = startDate
        tournament.endDate = endDate
        tournament.location = location.isEmpty ? nil : location
        tournament.isActive = isActive
        
        dismiss()
    }
}

#Preview {
    let tournament = Tournament(
        name: "Spring Championship",
        grade: .high,
        startDate: Date(),
        endDate: Date().addingTimeInterval(7 * 24 * 60 * 60)
    )
    
    return TournamentDetailView(tournament: tournament)
        .modelContainer(for: Tournament.self)
}