import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tournaments: [Tournament]
    @Query private var matches: [Match]
    @Query private var players: [Player]
    @Query private var horses: [Horse]
    
    var activeTournaments: [Tournament] {
        tournaments.filter { $0.isActive }
    }
    
    var todaysMatches: [Match] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        return matches.filter { match in
            match.date >= today && match.date < tomorrow
        }
    }
    
    var liveMatches: [Match] {
        matches.filter { $0.status == .inProgress }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Live Matches
                    if !liveMatches.isEmpty {
                        DashboardSection(title: "Live Matches", systemImage: "dot.radiowaves.left.and.right") {
                            ForEach(liveMatches, id: \.id) { match in
                                LiveMatchCard(match: match)
                            }
                        }
                    }
                    
                    // Today's Matches
                    if !todaysMatches.isEmpty {
                        DashboardSection(title: "Today's Matches", systemImage: "calendar") {
                            ForEach(todaysMatches, id: \.id) { match in
                                TodayMatchCard(match: match)
                            }
                        }
                    }
                    
                    // Statistics Overview
                    DashboardSection(title: "Overview", systemImage: "chart.bar") {
                        StatisticsGrid(
                            activeTournaments: activeTournaments.count,
                            totalPlayers: players.count,
                            totalHorses: horses.count,
                            totalMatches: matches.count
                        )
                    }
                    
                    // Active Tournaments
                    if !activeTournaments.isEmpty {
                        DashboardSection(title: "Active Tournaments", systemImage: "trophy") {
                            ForEach(activeTournaments, id: \.id) { tournament in
                                TournamentCard(tournament: tournament)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Polo Manager")
            .refreshable {
                // Refresh data
            }
        }
    }
}

struct DashboardSection<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
                Spacer()
            }
            
            content
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct LiveMatchCard: View {
    let match: Match
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("LIVE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .cornerRadius(4)
                
                Spacer()
                
                Text("Chukker \(match.currentChukker)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text(match.teamA?.name ?? "Team A")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(match.teamB?.name ?? "Team B")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack {
                    Text("\(match.teamAScore)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("\(match.teamBScore)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 2)
    }
}

struct TodayMatchCard: View {
    let match: Match
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(match.startTime, style: .time)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(match.field?.name ?? "Field TBA")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack {
                Text("\(match.teamA?.name ?? "TBA") vs \(match.teamB?.name ?? "TBA")")
                    .font(.subheadline)
                Text(match.tournament?.name ?? "Tournament")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(match.status.rawValue)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(colorForStatus(match.status))
                .foregroundColor(.white)
                .cornerRadius(4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 1)
    }
    
    private func colorForStatus(_ status: MatchStatus) -> Color {
        switch status {
        case .scheduled: return .blue
        case .inProgress: return .green
        case .completed: return .gray
        case .cancelled: return .red
        case .postponed: return .orange
        }
    }
}

struct StatisticsGrid: View {
    let activeTournaments: Int
    let totalPlayers: Int
    let totalHorses: Int
    let totalMatches: Int
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            StatCard(title: "Active Tournaments", value: "\(activeTournaments)", systemImage: "trophy.fill", color: .orange)
            StatCard(title: "Players", value: "\(totalPlayers)", systemImage: "person.fill", color: .blue)
            StatCard(title: "Horses", value: "\(totalHorses)", systemImage: "pawprint.fill", color: .green)
            StatCard(title: "Matches", value: "\(totalMatches)", systemImage: "sportscourt.fill", color: .purple)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let systemImage: String
    let color: Color
    
    var body: some View {
        VStack {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 1)
    }
}

struct TournamentCard: View {
    let tournament: Tournament
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(tournament.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(tournament.grade.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(tournament.startDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 1)
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Tournament.self, Match.self, Player.self, Horse.self])
}