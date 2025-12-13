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
    @Query private var tournaments: [Tournament]
    @Query private var teams: [Team]
    @State private var showingAddMatch = false
    @State private var selectedResult: MatchResult?
    @State private var isLoadingMatches = false
    @State private var errorMessage: String?

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
            .refreshable {
                await refreshMatches()
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
            .onAppear {
                fetchMatches()
            }
        }
    }

    private var filteredMatches: [Match] {
        if let selectedResult = selectedResult {
            return matches.filter { $0.result == selectedResult }
        }
        return matches
    }

    private func fetchMatches() {
        isLoadingMatches = true
        Task {
            do {
                // Fetch matches for all tournaments with backend IDs
                let tournamentsWithBackendIds = tournaments.filter { $0.backendId != nil }

                for tournament in tournamentsWithBackendIds {
                    guard let tournamentBackendId = tournament.backendId else { continue }

                    let matchDTOs = try await ApiService.shared.getMatchesByTournament(tournamentId: tournamentBackendId)

                    await MainActor.run {
                        for dto in matchDTOs {
                            // Check if match already exists by backendId
                            let existingMatch = matches.first { $0.backendId == dto.id }

                            if existingMatch == nil {
                                // Find teams by backend ID
                                let team1 = teams.first { $0.backendId == dto.team1Id }
                                let team2 = teams.first { $0.backendId == dto.team2Id }

                                if let team1 = team1, let team2 = team2 {
                                // Parse scheduled time
                                let date = dto.scheduledTime.flatMap { Date.apiDate(from: $0) } ?? Date()

                                    // Create new match with backend ID
                                    let newMatch = Match(
                                        date: date,
                                        homeTeam: team1,
                                        awayTeam: team2,
                                        backendId: dto.id
                                    )
                                    newMatch.tournament = tournament

                                    // Parse result if available
                                    if let resultString = dto.result {
                                        newMatch.result = MatchResult(rawValue: resultString) ?? .pending
                                    }

                                    modelContext.insert(newMatch)
                                }
                            }
                        }
                    }
                }

                await MainActor.run {
                    isLoadingMatches = false
                }
            } catch {
                await MainActor.run {
                    isLoadingMatches = false
                    errorMessage = "Failed to fetch matches: \(error.localizedDescription)"
                }
            }
        }
    }

    private func deleteMatches(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let match = filteredMatches[index]

                // Call API to delete match if it has a backend ID
                if let backendId = match.backendId {
                    Task {
                        do {
                            try await ApiService.shared.deleteMatch(id: backendId)
                            // Delete from SwiftData on successful backend deletion
                            await MainActor.run {
                                modelContext.delete(match)
                            }
                        } catch {
                            await MainActor.run {
                                errorMessage = "Failed to delete match: \(error.localizedDescription)"
                            }
                        }
                    }
                } else {
                    // If no backend ID, just delete locally
                    modelContext.delete(match)
                }
            }
        }
    }

    private func refreshMatches() async {
        // Fetch matches for all tournaments with backend IDs
        let tournamentsWithBackendIds = tournaments.filter { $0.backendId != nil }

        for tournament in tournamentsWithBackendIds {
            guard let tournamentBackendId = tournament.backendId else { continue }

            do {
                let matchDTOs = try await ApiService.shared.getMatchesByTournament(tournamentId: tournamentBackendId)

                await MainActor.run {
                    for dto in matchDTOs {
                        if let existing = matches.first(where: { $0.backendId == dto.id }) {
                            // Update existing match
                            if let timeStr = dto.scheduledTime, let date = Date.apiDate(from: timeStr) {
                                existing.date = date
                            }
                            if let resultStr = dto.result, let result = MatchResult(rawValue: resultStr) {
                                existing.result = result
                            }
                            // Note: Backend doesn't provide scores, keeping local values
                        }
                        // Note: New match insertion requires complex team linking
                    }
                }
            } catch {
                // Continue with other tournaments if one fails
                continue
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
    @State private var isLoading = false
    @State private var errorMessage: String?

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

                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
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
                    .disabled(isLoading)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button("Save") {
                            addMatch()
                        }
                        .disabled(selectedHomeTeam == nil || selectedAwayTeam == nil || selectedTournament == nil)
                    }
                }
            }
        }
    }

    private func addMatch() {
        guard let homeTeam = selectedHomeTeam,
              let awayTeam = selectedAwayTeam,
              let tournament = selectedTournament,
              let tournamentBackendId = tournament.backendId,
              let homeTeamBackendId = homeTeam.backendId,
              let awayTeamBackendId = awayTeam.backendId else {
            errorMessage = "Selected tournament or teams are not synced with backend"
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let scheduledTime = date.apiISODateTimeString()

                // Call API to create match using proper backend IDs
                let matchDTO = try await ApiService.shared.createMatch(
                    tournamentId: tournamentBackendId,
                    team1Id: homeTeamBackendId,
                    team2Id: awayTeamBackendId,
                    scheduledTime: scheduledTime
                )

                // Save locally to SwiftData with backend ID
                await MainActor.run {
                    let newMatch = Match(
                        date: date,
                        homeTeam: homeTeam,
                        awayTeam: awayTeam,
                        backendId: matchDTO.id
                    )
                    newMatch.tournament = selectedTournament
                    newMatch.field = selectedField
                    modelContext.insert(newMatch)
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to create match: \(error.localizedDescription)"
                }
            }
        }
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
    @State private var showingAddParticipation = false
    @State private var saveState: SaveState = .idle
    @State private var saveMessage: String = ""
    @State private var showingSaveAlert = false

    // Helper bindings to avoid type-checker complexity
    private var homeTeamBinding: Binding<Team?> {
        Binding(
            get: { match.homeTeam },
            set: { match.homeTeam = $0 }
        )
    }

    private var awayTeamBinding: Binding<Team?> {
        Binding(
            get: { match.awayTeam },
            set: { match.awayTeam = $0 }
        )
    }

    private var tournamentBinding: Binding<Tournament?> {
        Binding(
            get: { match.tournament },
            set: { match.tournament = $0 }
        )
    }

    private var fieldBinding: Binding<Field?> {
        Binding(
            get: { match.field },
            set: { match.field = $0 }
        )
    }

    // Break up sections to help type-checker
    private var matchInformationSection: some View {
        Section(header: Text("Match Information")) {
            DatePicker("Date & Time", selection: $match.date)

            Picker("Home Team", selection: homeTeamBinding) {
                Text("Select Home Team").tag(Team?.none)
                ForEach(allTeams, id: \.id) { team in
                    Text(team.name).tag(Team?.some(team))
                }
            }

            Picker("Away Team", selection: awayTeamBinding) {
                Text("Select Away Team").tag(Team?.none)
                ForEach(allTeams.filter { $0.id != match.homeTeam?.id }, id: \.id) { team in
                    Text(team.name).tag(Team?.some(team))
                }
            }

            TextField("Notes", text: $match.notes, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    private var scoreSection: some View {
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
    }

    private var associationsSection: some View {
        Section(header: Text("Associations")) {
            Picker("Tournament", selection: tournamentBinding) {
                Text("No Tournament").tag(Tournament?.none)
                ForEach(allTournaments.filter { $0.isActive }, id: \.id) { tournament in
                    Text(tournament.name).tag(Tournament?.some(tournament))
                }
            }

            Picker("Field", selection: fieldBinding) {
                Text("No Field").tag(Field?.none)
                ForEach(allFields.filter { $0.isActive }, id: \.id) { field in
                    Text(field.name).tag(Field?.some(field))
                }
            }
        }
    }

    @ViewBuilder
    private var dutiesSection: some View {
        if !match.duties.isEmpty {
            Section(header: Text("Match Officials")) {
                ForEach(match.duties, id: \.id) { duty in
                    NavigationLink(destination: DutyDetailView(duty: duty)) {
                        DutyRowView(duty: duty)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var participationsSection: some View {
        Section(header: HStack {
            Text("Player Participations")
            Spacer()
            Button(action: { showingAddParticipation = true }) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue)
            }
        }) {
            if match.participations.isEmpty {
                Text("No players added yet")
                    .foregroundColor(.secondary)
                    .font(.caption)
            } else {
                ForEach(match.participations, id: \.id) { participation in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(participation.player?.displayName ?? "Unknown Player")
                                .font(.headline)
                            HStack(spacing: 8) {
                                if let team = participation.team {
                                    Text(team.name)
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(team.id == match.homeTeam?.id ? Color.blue.opacity(0.2) : Color.orange.opacity(0.2))
                                        .foregroundColor(team.id == match.homeTeam?.id ? .blue : .orange)
                                        .cornerRadius(4)
                                }
                                if let horse = participation.horse {
                                    Text("🐴 \(horse.name)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Goals: \(participation.goalsScored)")
                                .font(.caption)
                            Text("Fouls: \(participation.fouls)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onDelete(perform: deleteParticipations)
            }
        }
    }

    var body: some View {
        Form {
            matchInformationSection
            scoreSection
            associationsSection
            dutiesSection
            participationsSection
        }
        .navigationTitle("Match Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button("Edit Score") {
                        showingScoreEntry = true
                    }
                    if match.backendId != nil {
                        Button(action: saveToBackend) {
                            switch saveState {
                            case .idle:
                                Image(systemName: "square.and.arrow.up")
                            case .saving:
                                ProgressView()
                            case .success:
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            case .error:
                                Image(systemName: "exclamation.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                        .disabled(saveState == .saving)
                    }
                }
            }
        }
        .sheet(isPresented: $showingScoreEntry) {
            ScoreEntryView(match: match)
        }
        .sheet(isPresented: $showingAddParticipation) {
            AddPlayerParticipationView(match: match)
        }
        .alert("Save Status", isPresented: $showingSaveAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveMessage)
        }
        .onChange(of: saveState) { oldValue, newValue in
            if case .success = newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    if case .success = saveState {
                        saveState = .idle
                    }
                }
            }
        }
    }

    private func saveToBackend() {
        guard let backendId = match.backendId,
              let tournamentBackendId = match.tournament?.backendId,
              let homeTeamBackendId = match.homeTeam?.backendId,
              let awayTeamBackendId = match.awayTeam?.backendId else {
            saveMessage = "Cannot save: Match, tournament, or teams not linked to backend"
            showingSaveAlert = true
            return
        }

        saveState = .saving
        Task {
            do {
                let scheduledTime = match.date.apiISODateTimeString()

                _ = try await ApiService.shared.updateMatch(
                    id: backendId,
                    tournamentId: tournamentBackendId,
                    team1Id: homeTeamBackendId,
                    team2Id: awayTeamBackendId,
                    scheduledTime: scheduledTime,
                    result: match.result.rawValue
                )

                await MainActor.run {
                    saveState = .success
                    saveMessage = "Match saved successfully"
                    showingSaveAlert = true
                }
            } catch {
                await MainActor.run {
                    saveState = .error(error.localizedDescription)
                    saveMessage = "Save failed: \(error.localizedDescription)"
                    showingSaveAlert = true
                }
            }
        }
    }

    private func deleteParticipations(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let participation = match.participations[index]
                modelContext.delete(participation)
            }
        }
    }
}

// MARK: - Add Player Participation View

struct AddPlayerParticipationView: View {
    @Bindable var match: Match
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allPlayers: [Player]
    @Query private var allHorses: [Horse]
    @State private var searchText = ""
    @State private var selectedPlayer: Player?
    @State private var selectedTeam: Team?
    @State private var selectedHorse: Horse?
    @State private var goalsScored: Int = 0
    @State private var fouls: Int = 0

    var availableTeams: [Team] {
        [match.homeTeam, match.awayTeam].compactMap { $0 }
    }

    var filteredPlayers: [Player] {
        if searchText.isEmpty {
            return allPlayers.filter { $0.isActive }
        } else {
            return allPlayers.filter { player in
                player.isActive &&
                player.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search players...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                .background(Color(.systemGroupedBackground))

                // Player list with scroll
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredPlayers) { player in
                            Button(action: {
                                selectedPlayer = player
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(player.displayName)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        HStack {
                                            if let state = player.state {
                                                Text(state.rawValue)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            Text("Handicap: \(String(format: "%.1f", player.currentHandicap))")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
                                    if selectedPlayer?.id == player.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding()
                                .background(selectedPlayer?.id == player.id ? Color.blue.opacity(0.1) : Color.clear)
                            }
                            Divider()
                        }
                    }
                }

                // Stats section
                if selectedPlayer != nil {
                    Form {
                        Section(header: Text("Participation Details")) {
                            Picker("Team", selection: $selectedTeam) {
                                Text("Select Team").tag(Team?.none)
                                ForEach(availableTeams) { team in
                                    HStack {
                                        Text(team.name)
                                        Spacer()
                                        if team.id == match.homeTeam?.id {
                                            Text("Home")
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                        } else if team.id == match.awayTeam?.id {
                                            Text("Away")
                                                .font(.caption)
                                                .foregroundColor(.orange)
                                        }
                                    }
                                    .tag(Team?.some(team))
                                }
                            }

                            Picker("Horse", selection: $selectedHorse) {
                                Text("No Horse").tag(Horse?.none)
                                ForEach(allHorses.filter { $0.isActive }) { horse in
                                    Text(horse.name).tag(Horse?.some(horse))
                                }
                            }

                            Stepper("Goals Scored: \(goalsScored)", value: $goalsScored, in: 0...20)

                            Stepper("Fouls: \(fouls)", value: $fouls, in: 0...10)
                        }
                    }
                    .frame(height: 280)
                }
            }
            .navigationTitle("Add Player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addParticipation()
                    }
                    .disabled(selectedPlayer == nil || selectedTeam == nil)
                }
            }
        }
    }

    private func addParticipation() {
        guard let player = selectedPlayer,
              let team = selectedTeam else { return }

        let participation = MatchParticipation(
            player: player,
            horse: selectedHorse,
            team: team
        )
        participation.goalsScored = goalsScored
        participation.fouls = fouls
        participation.match = match

        modelContext.insert(participation)
        dismiss()
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
