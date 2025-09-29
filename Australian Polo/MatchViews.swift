//
//  MatchViews.swift
//  Australian Polo
//
//  Created by Rodrigo Castillo on 9/29/25.
//

import SwiftUI
import SwiftData

// MARK: - Match List View

struct MatchListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Match.date, order: .reverse) private var matches: [Match]
    @State private var showingAddMatch = false
    @State private var selectedResult: MatchResult?
    
    var body: some View {
        NavigationView {
            List {
                Picker("Filter by Result", selection: $selectedResult) {
                    Text("All Matches").tag(MatchResult?.none)
                    ForEach(MatchResult.allCases, id: \.self) { result in
                        Text(result.rawValue).tag(MatchResult?.some(result))
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.vertical, 8)
                
                ForEach(filteredMatches) { match in
                    NavigationLink(destination: MatchDetailView(match: match)) {
                        MatchRowView(match: match)
                    }
                }
                .onDelete(perform: deleteMatches)
            }
            .navigationTitle("Matches")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddMatch = true }) {
                        Label("Add Match", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddMatch) {
                AddMatchView()
            }
        }
    }
    
    private var filteredMatches: [Match] {
        if let selectedResult = selectedResult {
            return matches.filter { $0.result == selectedResult }
        }
        return matches
    }
    
    private func deleteMatches(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredMatches[index])
            }
        }
    }
}

struct MatchRowView: View {
    let match: Match
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading) {
                    Text("\(match.homeTeam?.name ?? "TBD") vs \(match.awayTeam?.name ?? "TBD")")
                        .font(.headline)
                    Text(match.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                VStack(alignment: .trailing) {
                    if match.result != .pending {
                        Text("\(match.homeScore) - \(match.awayScore)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    Text(match.result.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(resultColor(for: match.result))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            
            if let tournament = match.tournament {
                Text("Tournament: \(tournament.name)")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
            
            if let field = match.field {
                Text("Field: \(field.name)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !match.notes.isEmpty {
                Text(match.notes)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 2)
    }
    
    private func resultColor(for result: MatchResult) -> Color {
        switch result {
        case .win: return .green
        case .loss: return .red
        case .draw: return .orange
        case .pending: return .blue
        }
    }
}

// MARK: - Add Match View

struct AddMatchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var date = Date()
    @Query private var teams: [Team]
    @Query private var tournaments: [Tournament]
    @Query private var fields: [Field]
    @State private var selectedHomeTeam: Team?
    @State private var selectedAwayTeam: Team?
    @State private var selectedTournament: Tournament?
    @State private var selectedField: Field?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Match Information")) {
                    DatePicker("Date & Time", selection: $date)
                    
                    Picker("Home Team", selection: $selectedHomeTeam) {
                        Text("Select Home Team").tag(Team?.none)
                        ForEach(teams, id: \.id) { team in
                            Text(team.name).tag(Team?.some(team))
                        }
                    }
                    
                    Picker("Away Team", selection: $selectedAwayTeam) {
                        Text("Select Away Team").tag(Team?.none)
                        ForEach(teams.filter { $0.id != selectedHomeTeam?.id }, id: \.id) { team in
                            Text(team.name).tag(Team?.some(team))
                        }
                    }
                }
                
                Section(header: Text("Associations")) {
                    Picker("Tournament", selection: $selectedTournament) {
                        Text("No Tournament").tag(Tournament?.none)
                        ForEach(tournaments.filter { $0.isActive }, id: \.id) { tournament in
                            Text(tournament.name).tag(Tournament?.some(tournament))
                        }
                    }
                    
                    Picker("Field", selection: $selectedField) {
                        Text("No Field").tag(Field?.none)
                        ForEach(fields.filter { $0.isActive }, id: \.id) { field in
                            Text(field.name).tag(Field?.some(field))
                        }
                    }
                }
            }
            .navigationTitle("Add Match")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        addMatch()
                    }
                    .disabled(selectedHomeTeam == nil || selectedAwayTeam == nil)
                }
            }
        }
    }
    
    private func addMatch() {
        guard let homeTeam = selectedHomeTeam,
              let awayTeam = selectedAwayTeam else { return }
        
        let newMatch = Match(date: date, homeTeam: homeTeam, awayTeam: awayTeam)
        newMatch.tournament = selectedTournament
        newMatch.field = selectedField
        modelContext.insert(newMatch)
        dismiss()
    }
}

// MARK: - Match Detail View

struct MatchDetailView: View {
    @Bindable var match: Match
    @Query private var allTeams: [Team]
    @Query private var allTournaments: [Tournament]
    @Query private var allFields: [Field]
    @Environment(\.modelContext) private var modelContext
    @State private var showingScoreEntry = false
    
    var body: some View {
        Form {
            Section(header: Text("Match Information")) {
                DatePicker("Date & Time", selection: $match.date)
                
                Picker("Home Team", selection: Binding<Team?>(
                    get: { match.homeTeam },
                    set: { match.homeTeam = $0 }
                )) {
                    Text("Select Home Team").tag(Team?.none)
                    ForEach(allTeams, id: \.id) { team in
                        Text(team.name).tag(Team?.some(team))
                    }
                }
                
                Picker("Away Team", selection: Binding<Team?>(
                    get: { match.awayTeam },
                    set: { match.awayTeam = $0 }
                )) {
                    Text("Select Away Team").tag(Team?.none)
                    ForEach(allTeams.filter { $0.id != match.homeTeam?.id }, id: \.id) { team in
                        Text(team.name).tag(Team?.some(team))
                    }
                }
                
                TextField("Notes", text: $match.notes, axis: .vertical)
                    .lineLimit(3...6)
            }
            
            Section(header: Text("Score & Result")) {
                HStack {
                    Text("Home Score")
                    Spacer()
                    Button("\(match.homeScore)") {
                        showingScoreEntry = true
                    }
                    .foregroundColor(.blue)
                }
                
                HStack {
                    Text("Away Score")
                    Spacer()
                    Button("\(match.awayScore)") {
                        showingScoreEntry = true
                    }
                    .foregroundColor(.blue)
                }
                
                Picker("Result", selection: $match.result) {
                    ForEach(MatchResult.allCases, id: \.self) { result in
                        Text(result.rawValue).tag(result)
                    }
                }
            }
            
            Section(header: Text("Associations")) {
                Picker("Tournament", selection: Binding<Tournament?>(
                    get: { match.tournament },
                    set: { match.tournament = $0 }
                )) {
                    Text("No Tournament").tag(Tournament?.none)
                    ForEach(allTournaments.filter { $0.isActive }, id: \.id) { tournament in
                        Text(tournament.name).tag(Tournament?.some(tournament))
                    }
                }
                
                Picker("Field", selection: Binding<Field?>(
                    get: { match.field },
                    set: { match.field = $0 }
                )) {
                    Text("No Field").tag(Field?.none)
                    ForEach(allFields.filter { $0.isActive }, id: \.id) { field in
                        Text(field.name).tag(Field?.some(field))
                    }
                }
            }
            
            if !match.duties.isEmpty {
                Section(header: Text("Match Officials")) {
                    ForEach(match.duties, id: \.id) { duty in
                        NavigationLink(destination: DutyDetailView(duty: duty)) {
                            DutyRowView(duty: duty)
                        }
                    }
                }
            }
            
            if !match.participations.isEmpty {
                Section(header: Text("Player Participations")) {
                    ForEach(match.participations, id: \.id) { participation in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(participation.player?.name ?? "Unknown Player")
                                    .font(.headline)
                                if let horse = participation.horse {
                                    Text("Horse: \(horse.name)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("Goals: \(participation.goalsScored)")
                                    .font(.caption)
                                Text("Fouls: \(participation.fouls)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Match Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit Score") {
                    showingScoreEntry = true
                }
            }
        }
        .sheet(isPresented: $showingScoreEntry) {
            ScoreEntryView(match: match)
        }
    }
}

// MARK: - Score Entry View

struct ScoreEntryView: View {
    @Bindable var match: Match
    @Environment(\.dismiss) private var dismiss
    @State private var homeScore: Int
    @State private var awayScore: Int
    
    init(match: Match) {
        self.match = match
        self._homeScore = State(initialValue: match.homeScore)
        self._awayScore = State(initialValue: match.awayScore)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Match Score")) {
                    HStack {
                        Text(match.homeTeam?.name ?? "Home Team")
                            .fontWeight(.semibold)
                        Spacer()
                        Stepper("\(homeScore)", value: $homeScore, in: 0...50)
                    }
                    
                    HStack {
                        Text(match.awayTeam?.name ?? "Away Team")
                            .fontWeight(.semibold)
                        Spacer()
                        Stepper("\(awayScore)", value: $awayScore, in: 0...50)
                    }
                }
                
                Section(header: Text("Result")) {
                    HStack {
                        Text("Winner")
                        Spacer()
                        if homeScore > awayScore {
                            Text(match.homeTeam?.name ?? "Home")
                                .foregroundColor(.green)
                        } else if awayScore > homeScore {
                            Text(match.awayTeam?.name ?? "Away")
                                .foregroundColor(.green)
                        } else {
                            Text("Draw")
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .navigationTitle("Enter Score")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveScore()
                    }
                }
            }
        }
    }
    
    private func saveScore() {
        match.homeScore = homeScore
        match.awayScore = awayScore
        
        // Update result based on score
        if homeScore > awayScore {
            match.result = .win
        } else if awayScore > homeScore {
            match.result = .loss
        } else {
            match.result = .draw
        }
        
        // Update team statistics
        updateTeamStats()
        
        dismiss()
    }
    
    private func updateTeamStats() {
        guard let homeTeam = match.homeTeam,
              let awayTeam = match.awayTeam else { return }
        
        homeTeam.goalsFor += homeScore
        homeTeam.goalsAgainst += awayScore
        awayTeam.goalsFor += awayScore
        awayTeam.goalsAgainst += homeScore
        
        if homeScore > awayScore {
            homeTeam.wins += 1
            awayTeam.losses += 1
        } else if awayScore > homeScore {
            awayTeam.wins += 1
            homeTeam.losses += 1
        } else {
            homeTeam.draws += 1
            awayTeam.draws += 1
        }
    }
}