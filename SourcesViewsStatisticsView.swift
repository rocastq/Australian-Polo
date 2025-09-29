import SwiftUI
import SwiftData

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tournaments: [Tournament]
    @Query private var matches: [Match]
    @Query private var players: [Player]
    @Query private var horses: [Horse]
    @Query private var awards: [Award]
    
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            VStack {
                // Tab Selection
                Picker("Statistics Type", selection: $selectedTab) {
                    Text("Overview").tag(0)
                    Text("Players").tag(1)
                    Text("Horses").tag(2)
                    Text("Awards").tag(3)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                ScrollView {
                    Group {
                        switch selectedTab {
                        case 0:
                            OverallStatisticsView(
                                tournaments: tournaments,
                                matches: matches,
                                players: players,
                                horses: horses
                            )
                        case 1:
                            PlayerStatisticsView(players: players)
                        case 2:
                            HorseStatisticsView(horses: horses)
                        case 3:
                            AwardsStatisticsView(awards: awards)
                        default:
                            OverallStatisticsView(
                                tournaments: tournaments,
                                matches: matches,
                                players: players,
                                horses: horses
                            )
                        }
                    }
                }
            }
            .navigationTitle("Statistics")
        }
    }
}

struct OverallStatisticsView: View {
    let tournaments: [Tournament]
    let matches: [Match]
    let players: [Player]
    let horses: [Horse]
    
    var activeTournaments: [Tournament] {
        tournaments.filter { $0.isActive }
    }
    
    var completedMatches: [Match] {
        matches.filter { $0.status == .completed }
    }
    
    var totalGoals: Int {
        completedMatches.reduce(0) { total, match in
            total + match.teamAScore + match.teamBScore
        }
    }
    
    var averageGoalsPerMatch: Double {
        guard !completedMatches.isEmpty else { return 0 }
        return Double(totalGoals) / Double(completedMatches.count)
    }
    
    var body: some View {
        LazyVStack(spacing: 20) {
            // Main Statistics Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatCard(title: "Total Tournaments", value: "\(tournaments.count)", systemImage: "trophy.fill", color: .orange)
                StatCard(title: "Active Tournaments", value: "\(activeTournaments.count)", systemImage: "trophy.circle.fill", color: .blue)
                StatCard(title: "Total Matches", value: "\(matches.count)", systemImage: "sportscourt.fill", color: .green)
                StatCard(title: "Completed Matches", value: "\(completedMatches.count)", systemImage: "checkmark.circle.fill", color: .purple)
                StatCard(title: "Total Players", value: "\(players.count)", systemImage: "person.fill", color: .red)
                StatCard(title: "Active Players", value: "\(players.filter { $0.isActive }.count)", systemImage: "person.circle.fill", color: .pink)
                StatCard(title: "Total Horses", value: "\(horses.count)", systemImage: "pawprint.fill", color: .brown)
                StatCard(title: "Active Horses", value: "\(horses.filter { $0.isActive }.count)", systemImage: "pawprint.circle.fill", color: .mint)
            }
            .padding(.horizontal)
            
            // Goal Statistics
            VStack(alignment: .leading, spacing: 12) {
                Text("Scoring Statistics")
                    .font(.headline)
                    .padding(.horizontal)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    StatCard(title: "Total Goals", value: "\(totalGoals)", systemImage: "target", color: .orange)
                    StatCard(title: "Goals per Match", value: String(format: "%.1f", averageGoalsPerMatch), systemImage: "chart.line.uptrend.xyaxis", color: .blue)
                }
                .padding(.horizontal)
            }
            
            // Recent Activity
            if !matches.isEmpty {
                RecentActivityView(matches: matches)
            }
            
            // Top Performers Preview
            TopPerformersPreview(players: players, horses: horses)
        }
        .padding(.vertical)
    }
}

struct RecentActivityView: View {
    let matches: [Match]
    
    var recentMatches: [Match] {
        matches.sorted { $0.date > $1.date }.prefix(5).map { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVStack(spacing: 8) {
                ForEach(recentMatches, id: \.id) { match in
                    RecentMatchCard(match: match)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct RecentMatchCard: View {
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
            
            VStack(alignment: .trailing, spacing: 4) {
                if match.status == .completed {
                    Text("\(match.teamAScore) - \(match.teamBScore)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                } else {
                    Text(match.status.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(statusColor(for: match.status))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
                
                if let tournament = match.tournament {
                    Text(tournament.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
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

struct TopPerformersPreview: View {
    let players: [Player]
    let horses: [Horse]
    
    var topScorers: [Player] {
        players.filter { $0.totalGoals > 0 }
            .sorted { $0.totalGoals > $1.totalGoals }
            .prefix(3)
            .map { $0 }
    }
    
    var mostActiveHorses: [Horse] {
        horses.filter { $0.totalGames > 0 }
            .sorted { $0.totalGames > $1.totalGames }
            .prefix(3)
            .map { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !topScorers.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Top Goal Scorers")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    LazyVStack(spacing: 8) {
                        ForEach(Array(topScorers.enumerated()), id: \.element.id) { index, player in
                            TopScorerRow(player: player, rank: index + 1)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            if !mostActiveHorses.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Most Active Horses")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    LazyVStack(spacing: 8) {
                        ForEach(Array(mostActiveHorses.enumerated()), id: \.element.id) { index, horse in
                            TopHorseRow(horse: horse, rank: index + 1)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct TopScorerRow: View {
    let player: Player
    let rank: Int
    
    var body: some View {
        HStack {
            Text("\(rank)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(rankColor(for: rank))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(player.fullName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let club = player.club {
                    Text(club.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(player.totalGoals)")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text("goals")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func rankColor(for rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .blue
        }
    }
}

struct TopHorseRow: View {
    let horse: Horse
    let rank: Int
    
    var body: some View {
        HStack {
            Text("\(rank)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(rankColor(for: rank))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(horse.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(horse.color.rawValue) \(horse.gender.rawValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(horse.totalGames)")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text("games")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func rankColor(for rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .blue
        }
    }
}

struct PlayerStatisticsView: View {
    let players: [Player]
    
    var sortedPlayers: [Player] {
        players.filter { $0.totalGoals > 0 }
            .sorted { $0.totalGoals > $1.totalGoals }
    }
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            Text("Player Performance Rankings")
                .font(.headline)
                .padding(.horizontal)
            
            if sortedPlayers.isEmpty {
                Text("No player statistics available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(Array(sortedPlayers.enumerated()), id: \.element.id) { index, player in
                        DetailedPlayerRow(player: player, rank: index + 1)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
}

struct DetailedPlayerRow: View {
    let player: Player
    let rank: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(rank)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
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
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(player.totalGoals)")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("goals")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Text("\(player.totalMatches) matches")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(player.averageGoalsPerMatch, specifier: "%.1f") goals/match")
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

struct HorseStatisticsView: View {
    let horses: [Horse]
    
    var sortedHorses: [Horse] {
        horses.filter { $0.totalGames > 0 }
            .sorted { $0.totalGames > $1.totalGames }
    }
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            Text("Horse Activity Rankings")
                .font(.headline)
                .padding(.horizontal)
            
            if sortedHorses.isEmpty {
                Text("No horse statistics available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(Array(sortedHorses.enumerated()), id: \.element.id) { index, horse in
                        DetailedHorseRow(horse: horse, rank: index + 1)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
}

struct DetailedHorseRow: View {
    let horse: Horse
    let rank: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(rank)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.brown)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(horse.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("\(horse.color.rawValue) \(horse.gender.rawValue), \(horse.age) years")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(horse.totalGames)")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("games")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                if let breeder = horse.breeder {
                    Text("Bred by \(breeder.fullName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(horse.totalTournaments) tournaments")
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

struct AwardsStatisticsView: View {
    let awards: [Award]
    
    var awardsByType: [AwardType: [Award]] {
        Dictionary(grouping: awards) { $0.awardType }
    }
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            Text("Awards Distribution")
                .font(.headline)
                .padding(.horizontal)
            
            if awards.isEmpty {
                Text("No awards recorded")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(Array(awardsByType.keys).sorted { $0.rawValue < $1.rawValue }, id: \.self) { awardType in
                        if let typeAwards = awardsByType[awardType] {
                            AwardTypeRow(awardType: awardType, awards: typeAwards)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
}

struct AwardTypeRow: View {
    let awardType: AwardType
    let awards: [Award]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
                
                Text(awardType.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(awards.count)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            if awards.count <= 3 {
                // Show all awards if 3 or fewer
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(awards.sorted { $0.dateAwarded > $1.dateAwarded }, id: \.id) { award in
                        AwardDetailRow(award: award)
                    }
                }
            } else {
                // Show recent awards
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(awards.sorted { $0.dateAwarded > $1.dateAwarded }.prefix(2), id: \.id) { award in
                        AwardDetailRow(award: award)
                    }
                }
                
                Text("and \(awards.count - 2) more...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 16)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct AwardDetailRow: View {
    let award: Award
    
    var body: some View {
        HStack {
            Text("•")
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 2) {
                if let player = award.player {
                    Text(player.fullName)
                        .font(.caption)
                        .fontWeight(.medium)
                } else if let team = award.team {
                    Text(team.name)
                        .font(.caption)
                        .fontWeight(.medium)
                } else if let horse = award.horse {
                    Text(horse.name)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                if let tournament = award.tournament {
                    Text(tournament.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(award.dateAwarded, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    StatisticsView()
        .modelContainer(for: [Tournament.self, Match.self, Player.self, Horse.self, Award.self])
}