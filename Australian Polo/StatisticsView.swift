//
//  StatisticsView.swift
//  Australian Polo
//
//  Created by Rodrigo Castillo on 9/29/25.
//

import SwiftUI
import SwiftData

// MARK: - Statistics View

struct StatisticsView: View {
    @Query private var matches: [Match]
    @Query private var players: [Player]
    @Query private var teams: [Team]
    @Query private var horses: [Horse]
    @Query private var tournaments: [Tournament]
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // Match Statistics
                MatchStatisticsView(matches: matches)
                    .tabItem {
                        Label("Matches", systemImage: "gamecontroller")
                    }
                    .tag(0)
                
                // Player Statistics
                PlayerStatisticsView(players: players)
                    .tabItem {
                        Label("Players", systemImage: "person.circle")
                    }
                    .tag(1)
                
                // Team Statistics
                TeamStatisticsView(teams: teams)
                    .tabItem {
                        Label("Teams", systemImage: "person.3.sequence")
                    }
                    .tag(2)
                
                // Horse Statistics
                HorseStatisticsView(horses: horses)
                    .tabItem {
                        Label("Horses", systemImage: "pawprint")
                    }
                    .tag(3)
                
                // Tournament Statistics
                TournamentStatisticsView(tournaments: tournaments)
                    .tabItem {
                        Label("Tournaments", systemImage: "trophy")
                    }
                    .tag(4)
            }
            .navigationTitle("Statistics")
        }
    }
}

// MARK: - Match Statistics

struct MatchStatisticsView: View {
    let matches: [Match]
    
    var completedMatches: [Match] {
        matches.filter { $0.result != .pending }
    }
    
    var body: some View {
        List {
            Section(header: Text("Overall Match Statistics")) {
                StatisticRowView(title: "Total Matches", value: "\(matches.count)")
                StatisticRowView(title: "Completed Matches", value: "\(completedMatches.count)")
                StatisticRowView(title: "Pending Matches", value: "\(matches.count - completedMatches.count)")
            }
            
            Section(header: Text("Match Results")) {
                StatisticRowView(title: "Wins", value: "\(matches.filter { $0.result == .win }.count)")
                StatisticRowView(title: "Losses", value: "\(matches.filter { $0.result == .loss }.count)")
                StatisticRowView(title: "Draws", value: "\(matches.filter { $0.result == .draw }.count)")
            }
            
            if !completedMatches.isEmpty {
                Section(header: Text("Scoring Statistics")) {
                    let totalGoals = completedMatches.reduce(0) { $0 + $1.homeScore + $1.awayScore }
                    let averageGoals = Double(totalGoals) / Double(completedMatches.count)
                    
                    StatisticRowView(title: "Total Goals Scored", value: "\(totalGoals)")
                    StatisticRowView(title: "Average Goals per Match", value: String(format: "%.1f", averageGoals))
                    
                    let highestScoringMatch = completedMatches.max { ($0.homeScore + $0.awayScore) < ($1.homeScore + $1.awayScore) }
                    if let highestMatch = highestScoringMatch {
                        StatisticRowView(title: "Highest Scoring Match", value: "\(highestMatch.homeScore + highestMatch.awayScore) goals")
                    }
                }
            }
            
            Section(header: Text("Recent Matches")) {
                ForEach(matches.sorted { $0.date > $1.date }.prefix(5), id: \.id) { match in
                    MatchRowView(match: match)
                }
            }
        }
    }
}

// MARK: - Player Statistics

struct PlayerStatisticsView: View {
    let players: [Player]
    
    var activePlayers: [Player] {
        players.filter { $0.isActive }
    }
    
    var topScorers: [Player] {
        activePlayers.sorted { $0.goalsScored > $1.goalsScored }.prefix(10).map { $0 }
    }
    
    var body: some View {
        List {
            Section(header: Text("Player Overview")) {
                StatisticRowView(title: "Total Players", value: "\(players.count)")
                StatisticRowView(title: "Active Players", value: "\(activePlayers.count)")
                StatisticRowView(title: "Total Games Played", value: "\(activePlayers.reduce(0) { $0 + $1.gamesPlayed })")
                StatisticRowView(title: "Total Goals Scored", value: "\(activePlayers.reduce(0) { $0 + $1.goalsScored })")
            }
            
            if !activePlayers.isEmpty {
                Section(header: Text("Average Statistics")) {
                    let avgGames = Double(activePlayers.reduce(0) { $0 + $1.gamesPlayed }) / Double(activePlayers.count)
                    let avgGoals = Double(activePlayers.reduce(0) { $0 + $1.goalsScored }) / Double(activePlayers.count)
                    let avgHandicap = activePlayers.reduce(0.0) { $0 + $1.handicap } / Double(activePlayers.count)
                    
                    StatisticRowView(title: "Games per Player", value: String(format: "%.1f", avgGames))
                    StatisticRowView(title: "Goals per Player", value: String(format: "%.1f", avgGoals))
                    StatisticRowView(title: "Average Handicap", value: String(format: "%.1f", avgHandicap))
                }
            }
            
            Section(header: Text("Top Scorers")) {
                ForEach(topScorers, id: \.id) { player in
                    HStack {
                        Text(player.name)
                            .font(.headline)
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("\(player.goalsScored) goals")
                                .font(.caption)
                                .fontWeight(.semibold)
                            if player.gamesPlayed > 0 {
                                Text("\(Double(player.goalsScored) / Double(player.gamesPlayed), specifier: "%.2f") per game")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            
            Section(header: Text("Handicap Distribution")) {
                let handicapRanges = [
                    ("Low Goal (0-4)", players.filter { $0.handicap >= 0 && $0.handicap <= 4 }.count),
                    ("Medium Goal (5-6)", players.filter { $0.handicap >= 5 && $0.handicap <= 6 }.count),
                    ("High Goal (7+)", players.filter { $0.handicap >= 7 }.count)
                ]
                
                ForEach(handicapRanges, id: \.0) { range in
                    StatisticRowView(title: range.0, value: "\(range.1)")
                }
            }
        }
    }
}

// MARK: - Team Statistics

struct TeamStatisticsView: View {
    let teams: [Team]
    
    var teamsWithGames: [Team] {
        teams.filter { $0.gamesPlayed > 0 }
    }
    
    var topTeams: [Team] {
        teamsWithGames.sorted { $0.winPercentage > $1.winPercentage }.prefix(10).map { $0 }
    }
    
    var body: some View {
        List {
            Section(header: Text("Team Overview")) {
                StatisticRowView(title: "Total Teams", value: "\(teams.count)")
                StatisticRowView(title: "Teams with Games", value: "\(teamsWithGames.count)")
                StatisticRowView(title: "Total Games", value: "\(teamsWithGames.reduce(0) { $0 + $1.gamesPlayed })")
                StatisticRowView(title: "Total Goals", value: "\(teamsWithGames.reduce(0) { $0 + $1.goalsFor })")
            }
            
            Section(header: Text("Top Teams (by Win %)")) {
                ForEach(topTeams, id: \.id) { team in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(team.name)
                                .font(.headline)
                            Text("\(team.wins)W \(team.losses)L \(team.draws)D")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("\(team.winPercentage, specifier: "%.1f")%")
                                .font(.headline)
                                .foregroundColor(.green)
                            Text("\(team.goalDifference > 0 ? "+" : "")\(team.goalDifference)")
                                .font(.caption)
                                .foregroundColor(team.goalDifference >= 0 ? .green : .red)
                        }
                    }
                }
            }
            
            Section(header: Text("Grade Distribution")) {
                let gradeDistribution = Dictionary(grouping: teams, by: \.grade)
                ForEach(TournamentGrade.allCases, id: \.self) { grade in
                    let count = gradeDistribution[grade]?.count ?? 0
                    StatisticRowView(title: "\(grade.rawValue) Grade", value: "\(count)")
                }
            }
        }
    }
}

extension Team {
    var winPercentage: Double {
        guard gamesPlayed > 0 else { return 0.0 }
        return Double(wins) / Double(gamesPlayed) * 100
    }
}

// MARK: - Horse Statistics

struct HorseStatisticsView: View {
    let horses: [Horse]
    
    var activeHorses: [Horse] {
        horses.filter { $0.isActive }
    }
    
    var topHorses: [Horse] {
        activeHorses.sorted { $0.gamesPlayed > $1.gamesPlayed }.prefix(10).map { $0 }
    }
    
    var body: some View {
        List {
            Section(header: Text("Horse Overview")) {
                StatisticRowView(title: "Total Horses", value: "\(horses.count)")
                StatisticRowView(title: "Active Horses", value: "\(activeHorses.count)")
                StatisticRowView(title: "Total Games", value: "\(activeHorses.reduce(0) { $0 + $1.gamesPlayed })")
                StatisticRowView(title: "Total Tournament Wins", value: "\(activeHorses.reduce(0) { $0 + $1.tournamentsWon })")
            }
            
            if !activeHorses.isEmpty {
                Section(header: Text("Age Distribution")) {
                    let ageRanges = [
                        ("Young (2-5 years)", activeHorses.filter { $0.age >= 2 && $0.age <= 5 }.count),
                        ("Prime (6-12 years)", activeHorses.filter { $0.age >= 6 && $0.age <= 12 }.count),
                        ("Senior (13+ years)", activeHorses.filter { $0.age >= 13 }.count)
                    ]
                    
                    ForEach(ageRanges, id: \.0) { range in
                        StatisticRowView(title: range.0, value: "\(range.1)")
                    }
                }
                
                Section(header: Text("Gender Distribution")) {
                    ForEach(HorseGender.allCases, id: \.self) { gender in
                        let count = activeHorses.filter { $0.gender == gender }.count
                        StatisticRowView(title: gender.rawValue, value: "\(count)")
                    }
                }
                
                Section(header: Text("Most Active Horses")) {
                    ForEach(topHorses, id: \.id) { horse in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(horse.name)
                                    .font(.headline)
                                Text("\(horse.age) year old \(horse.gender.rawValue)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("\(horse.gamesPlayed) games")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                Text("\(horse.tournamentsWon) tournaments")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Tournament Statistics

struct TournamentStatisticsView: View {
    let tournaments: [Tournament]
    
    var activeTournaments: [Tournament] {
        tournaments.filter { $0.isActive }
    }
    
    var completedTournaments: [Tournament] {
        tournaments.filter { $0.endDate < Date() }
    }
    
    var body: some View {
        List {
            Section(header: Text("Tournament Overview")) {
                StatisticRowView(title: "Total Tournaments", value: "\(tournaments.count)")
                StatisticRowView(title: "Active Tournaments", value: "\(activeTournaments.count)")
                StatisticRowView(title: "Completed Tournaments", value: "\(completedTournaments.count)")
                StatisticRowView(title: "Upcoming Tournaments", value: "\(tournaments.filter { $0.startDate > Date() }.count)")
            }
            
            Section(header: Text("Grade Distribution")) {
                ForEach(TournamentGrade.allCases, id: \.self) { grade in
                    let count = tournaments.filter { $0.grade == grade }.count
                    StatisticRowView(title: "\(grade.rawValue) Grade", value: "\(count)")
                }
            }
            
            Section(header: Text("Recent Tournaments")) {
                ForEach(tournaments.sorted { $0.startDate > $1.startDate }.prefix(5), id: \.id) { tournament in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tournament.name)
                            .font(.headline)
                        HStack {
                            Text(tournament.grade.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.blue)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                            Text(tournament.location)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(tournament.startDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Text("\(tournament.matches.count) matches, \(tournament.teams.count) teams")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
}

// MARK: - Helper Views

struct StatisticRowView: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
                .fontWeight(.semibold)
        }
    }
}