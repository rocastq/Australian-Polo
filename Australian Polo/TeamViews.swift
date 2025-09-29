//
//  TeamViews.swift
//  Australian Polo
//
//  Created by Rodrigo Castillo on 9/29/25.
//

import SwiftUI
import SwiftData

// MARK: - Team List View

struct TeamListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var teams: [Team]
    @State private var showingAddTeam = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(teams) { team in
                    NavigationLink(destination: TeamDetailView(team: team)) {
                        TeamRowView(team: team)
                    }
                }
                .onDelete(perform: deleteTeams)
            }
            .navigationTitle("Teams")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTeam = true }) {
                        Label("Add Team", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTeam) {
                AddTeamView()
            }
        }
    }
    
    private func deleteTeams(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(teams[index])
            }
        }
    }
}

struct TeamRowView: View {
    let team: Team
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(team.name)
                    .font(.headline)
                Spacer()
                Text(team.grade.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(gradeColor(for: team.grade))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            HStack {
                Text("\(team.players.count) players")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("W: \(team.wins) L: \(team.losses) D: \(team.draws)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if team.gamesPlayed > 0 {
                HStack {
                    Text("Goals: \(team.goalsFor)/\(team.goalsAgainst)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Diff: \(team.goalDifference > 0 ? "+" : "")\(team.goalDifference)")
                        .font(.caption2)
                        .foregroundColor(team.goalDifference >= 0 ? .green : .red)
                }
            }
        }
        .padding(.vertical, 2)
    }
    
    private func gradeColor(for grade: TournamentGrade) -> Color {
        switch grade {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }
}

// MARK: - Add Team View

struct AddTeamView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedGrade: TournamentGrade = .medium
    @Query private var clubs: [Club]
    @State private var selectedClub: Club?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Team Information")) {
                    TextField("Name", text: $name)
                    
                    Picker("Grade", selection: $selectedGrade) {
                        ForEach(TournamentGrade.allCases, id: \.self) { grade in
                            Text(grade.rawValue).tag(grade)
                        }
                    }
                    
                    Picker("Club", selection: $selectedClub) {
                        Text("No Club").tag(Club?.none)
                        ForEach(clubs.filter { $0.isActive }, id: \.id) { club in
                            Text(club.name).tag(Club?.some(club))
                        }
                    }
                }
            }
            .navigationTitle("Add Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        addTeam()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func addTeam() {
        let newTeam = Team(name: name, grade: selectedGrade)
        newTeam.club = selectedClub
        modelContext.insert(newTeam)
        dismiss()
    }
}

// MARK: - Team Detail View

struct TeamDetailView: View {
    @Bindable var team: Team
    @Query private var allPlayers: [Player]
    @Query private var allClubs: [Club]
    @Environment(\.modelContext) private var modelContext
    @State private var showingPlayerSelection = false
    
    var body: some View {
        Form {
            Section(header: Text("Team Information")) {
                TextField("Name", text: $team.name)
                
                Picker("Grade", selection: $team.grade) {
                    ForEach(TournamentGrade.allCases, id: \.self) { grade in
                        Text(grade.rawValue).tag(grade)
                    }
                }
                
                Picker("Club", selection: Binding<Club?>(
                    get: { team.club },
                    set: { team.club = $0 }
                )) {
                    Text("No Club").tag(Club?.none)
                    ForEach(allClubs.filter { $0.isActive }, id: \.id) { club in
                        Text(club.name).tag(Club?.some(club))
                    }
                }
            }
            
            Section(header: Text("Statistics")) {
                HStack {
                    Text("Games Played")
                    Spacer()
                    Text("\(team.gamesPlayed)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Wins")
                    Spacer()
                    Text("\(team.wins)")
                        .foregroundColor(.green)
                }
                
                HStack {
                    Text("Losses")
                    Spacer()
                    Text("\(team.losses)")
                        .foregroundColor(.red)
                }
                
                HStack {
                    Text("Draws")
                    Spacer()
                    Text("\(team.draws)")
                        .foregroundColor(.orange)
                }
                
                HStack {
                    Text("Goals For/Against")
                    Spacer()
                    Text("\(team.goalsFor)/\(team.goalsAgainst)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Goal Difference")
                    Spacer()
                    Text("\(team.goalDifference > 0 ? "+" : "")\(team.goalDifference)")
                        .foregroundColor(team.goalDifference >= 0 ? .green : .red)
                }
            }
            
            Section(header: HStack {
                Text("Players (\(team.players.count))")
                Spacer()
                Button("Add Player") {
                    showingPlayerSelection = true
                }
                .font(.caption)
            }) {
                ForEach(team.players, id: \.id) { player in
                    NavigationLink(destination: PlayerDetailView(player: player)) {
                        PlayerRowView(player: player)
                    }
                }
                .onDelete(perform: removePlayers)
            }
            
            if !team.tournaments.isEmpty {
                Section(header: Text("Tournaments")) {
                    ForEach(team.tournaments, id: \.id) { tournament in
                        NavigationLink(destination: TournamentDetailView(tournament: tournament)) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(tournament.name)
                                    .font(.headline)
                                Text(tournament.startDate.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(team.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingPlayerSelection) {
            PlayerSelectionView(team: team)
        }
    }
    
    private func removePlayers(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let player = team.players[index]
                team.players.removeAll { $0.id == player.id }
                player.teams.removeAll { $0.id == team.id }
            }
        }
    }
}

// MARK: - Player Selection View

struct PlayerSelectionView: View {
    @Bindable var team: Team
    @Query private var allPlayers: [Player]
    @Environment(\.dismiss) private var dismiss
    
    var availablePlayers: [Player] {
        allPlayers.filter { player in
            player.isActive && !team.players.contains { $0.id == player.id }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(availablePlayers, id: \.id) { player in
                    Button(action: {
                        addPlayerToTeam(player)
                    }) {
                        PlayerRowView(player: player)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Add Players")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func addPlayerToTeam(_ player: Player) {
        withAnimation {
            team.players.append(player)
            player.teams.append(team)
        }
    }
}