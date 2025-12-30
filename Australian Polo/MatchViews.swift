//
//  MatchViews.swift
//  Australian Polo
//
//  Created by Rodrigo Castillo on 9/29/25.
//

import SwiftUI
import SwiftData
import UserNotifications

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
    @State private var previousDate: Date?
    @State private var showingConcludeConfirmation = false

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

            HStack {
                Text("Result")
                Spacer()
                Text(match.result.rawValue)
                    .foregroundColor(resultColor(for: match.result))
            }
        }
    }

    private var matchStatusSection: some View {
        Section(header: Text("Match Status")) {
            if match.result == .pending {
                VStack(alignment: .leading, spacing: 8) {
                    if let startTime = match.matchStartTime {
                        HStack {
                            Text("Match Started:")
                            Spacer()
                            Text(startTime.formatted(date: .omitted, time: .shortened))
                                .foregroundColor(.secondary)
                        }

                        if match.shouldAutoConclude {
                            Text("Match will auto-conclude (2 hours elapsed)")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    } else {
                        Text("Match not started yet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Button(action: {
                        showingConcludeConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Conclude Match")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                    Text("Match Concluded")
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func resultColor(for result: MatchResult) -> Color {
        switch result {
        case .win: return .green
        case .loss: return .red
        case .draw: return .orange
        case .pending: return .blue
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
            matchStatusSection
            associationsSection
            dutiesSection
            participationsSection
        }
        .navigationTitle("Match Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            previousDate = match.date
        }
        .onChange(of: match.date) { oldValue, newValue in
            checkDateChange(oldDate: oldValue, newDate: newValue)
        }
        .confirmationDialog("Conclude Match", isPresented: $showingConcludeConfirmation) {
            Button("Conclude as \(predictedResult())", role: .destructive) {
                concludeMatch()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will finalize the match result based on the current score: \(match.homeTeam?.name ?? "Home") \(match.homeScore) - \(match.awayScore) \(match.awayTeam?.name ?? "Away")")
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    NavigationLink(destination: MatchControlView(match: match)) {
                        Label("Match Control", systemImage: "sportscourt.fill")
                    }

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

    private func predictedResult() -> String {
        if match.homeScore > match.awayScore {
            return "Win"
        } else if match.awayScore > match.homeScore {
            return "Loss"
        } else {
            return "Draw"
        }
    }

    private func concludeMatch() {
        if match.homeScore > match.awayScore {
            match.result = .win
        } else if match.awayScore > match.homeScore {
            match.result = .loss
        } else {
            match.result = .draw
        }
    }

    private func checkDateChange(oldDate: Date, newDate: Date) {
        // Check if the date actually changed (more than 1 minute difference)
        let timeDifference = abs(newDate.timeIntervalSince(oldDate))
        if timeDifference > 60 { // More than 1 minute difference
            sendMatchTimeChangeNotification(oldDate: oldDate, newDate: newDate)
            match.originalDate = oldDate // Update original date for reference
        }
    }

    private func sendMatchTimeChangeNotification(oldDate: Date, newDate: Date) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }

            let content = UNMutableNotificationContent()
            content.title = "Match Time Changed"
            content.body = """
            \(match.homeTeam?.name ?? "Home") vs \(match.awayTeam?.name ?? "Away")
            From: \(oldDate.formatted(date: .abbreviated, time: .shortened))
            To: \(newDate.formatted(date: .abbreviated, time: .shortened))
            """
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request)
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
    @State private var selectedPlayerIDs: Set<UUID> = []
    @State private var selectedTeam: Team?
    @State private var selectedHorse: Horse?
    @State private var goalsScored: Int = 0
    @State private var fouls: Int = 0

    var availableTeams: [Team] {
        [match.homeTeam, match.awayTeam].compactMap { $0 }
    }

    var filteredPlayers: [Player] {
        // Filter out players already added to the match
        let existingPlayerIDs = Set(match.participations.compactMap { $0.player?.id })

        if searchText.isEmpty {
            return allPlayers.filter { $0.isActive && !existingPlayerIDs.contains($0.id) }
        } else {
            return allPlayers.filter { player in
                player.isActive &&
                !existingPlayerIDs.contains(player.id) &&
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

                // Selection summary
                if !selectedPlayerIDs.isEmpty {
                    HStack {
                        Text("\(selectedPlayerIDs.count) player\(selectedPlayerIDs.count == 1 ? "" : "s") selected")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        Spacer()
                        Button("Clear") {
                            selectedPlayerIDs.removeAll()
                        }
                        .font(.caption)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                }

                // Player list with scroll
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredPlayers) { player in
                            Button(action: {
                                togglePlayerSelection(player)
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
                                    if selectedPlayerIDs.contains(player.id) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.gray.opacity(0.3))
                                    }
                                }
                                .padding()
                                .background(selectedPlayerIDs.contains(player.id) ? Color.blue.opacity(0.1) : Color.clear)
                            }
                            Divider()
                        }
                    }
                }

                // Stats section
                if !selectedPlayerIDs.isEmpty {
                    Form {
                        Section(header: Text("Participation Details (applies to all selected players)")) {
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

                            Picker("Horse (Optional)", selection: $selectedHorse) {
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
            .navigationTitle("Add Players")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(selectedPlayerIDs.isEmpty ? "Add" : "Add (\(selectedPlayerIDs.count))") {
                        addParticipations()
                    }
                    .disabled(selectedPlayerIDs.isEmpty || selectedTeam == nil)
                }
            }
        }
    }

    private func togglePlayerSelection(_ player: Player) {
        if selectedPlayerIDs.contains(player.id) {
            selectedPlayerIDs.remove(player.id)
        } else {
            selectedPlayerIDs.insert(player.id)
        }
    }

    private func addParticipations() {
        guard let team = selectedTeam else { return }

        // Create participation for each selected player
        for playerID in selectedPlayerIDs {
            if let player = allPlayers.first(where: { $0.id == playerID }) {
                let participation = MatchParticipation(
                    player: player,
                    horse: selectedHorse,
                    team: team
                )
                participation.goalsScored = goalsScored
                participation.fouls = fouls
                participation.match = match

                modelContext.insert(participation)
            }
        }

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

// MARK: - Match Control View

struct Goal: Identifiable, Codable {
    let id: UUID
    let playerId: UUID
    let playerName: String
    let teamId: UUID
    let teamName: String
    let timestamp: Date
    let isHomeTeam: Bool
    let chukka: Int

    init(player: Player, team: Team, isHomeTeam: Bool, chukka: Int) {
        self.id = UUID()
        self.playerId = player.id
        self.playerName = player.displayName
        self.teamId = team.id
        self.teamName = team.name
        self.timestamp = Date()
        self.isHomeTeam = isHomeTeam
        self.chukka = chukka
    }
}

struct MatchControlView: View {
    @Bindable var match: Match
    @Environment(\.modelContext) private var modelContext
    @State private var showingPlayerPicker = false
    @State private var selectedTeamIsHome: Bool = true
    @State private var goals: [Goal] = []

    // Chukka tracking
    @State private var chukkaTimeRemaining: TimeInterval = 420 // 7 minutes in seconds
    @State private var isTimerRunning: Bool = false
    @State private var timer: Timer?

    // Use match.currentChukka directly instead of separate state
    private var currentChukka: Int {
        get { match.currentChukka }
        nonmutating set { match.currentChukka = newValue }
    }

    var homeParticipations: [MatchParticipation] {
        match.participations.filter { $0.team?.id == match.homeTeam?.id }
    }

    var awayParticipations: [MatchParticipation] {
        match.participations.filter { $0.team?.id == match.awayTeam?.id }
    }

    var timeString: String {
        let minutes = Int(chukkaTimeRemaining) / 60
        let seconds = Int(chukkaTimeRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Scoreboard
            scoreboardView
                .padding()
                .background(Color(.systemGroupedBackground))

            // Chukka Control
            chukkaControlView
                .padding()
                .background(Color(.systemBackground))

            Divider()

            // Goal Buttons
            goalButtonsView
                .padding()

            Divider()

            // Goal History
            goalHistoryView
        }
        .navigationTitle("Match Control")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingPlayerPicker) {
            PlayerGoalPickerView(
                participations: selectedTeamIsHome ? homeParticipations : awayParticipations,
                teamName: selectedTeamIsHome ? (match.homeTeam?.name ?? "Home") : (match.awayTeam?.name ?? "Away"),
                isHomeTeam: selectedTeamIsHome,
                onPlayerSelected: { participation in
                    addGoal(for: participation, isHomeTeam: selectedTeamIsHome)
                }
            )
        }
        .onDisappear {
            stopTimer()
        }
    }

    private var scoreboardView: some View {
        VStack(spacing: 16) {
            // Match info
            VStack(spacing: 4) {
                if let tournament = match.tournament {
                    Text(tournament.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(match.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // Score display
            HStack(spacing: 20) {
                // Home Team
                VStack(spacing: 8) {
                    Text(match.homeTeam?.name ?? "Home")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    Text("\(match.homeScore)")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity)

                Text(":")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.secondary)

                // Away Team
                VStack(spacing: 8) {
                    Text(match.awayTeam?.name ?? "Away")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    Text("\(match.awayScore)")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.orange)
                }
                .frame(maxWidth: .infinity)
            }

            // Result badge
            Text(match.result.rawValue)
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(resultColor(for: match.result))
                .foregroundColor(.white)
                .cornerRadius(12)
        }
    }

    private var chukkaControlView: some View {
        VStack(spacing: 12) {
            // Chukka selector
            HStack {
                Text("Chukka")
                    .font(.headline)

                Spacer()

                // Chukka stepper
                HStack(spacing: 12) {
                    Button(action: {
                        if currentChukka > 1 {
                            currentChukka -= 1
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundColor(currentChukka > 1 ? .blue : .gray)
                    }
                    .disabled(currentChukka <= 1)

                    Text("\(currentChukka)")
                        .font(.title)
                        .fontWeight(.bold)
                        .frame(minWidth: 40)

                    Button(action: {
                        if currentChukka < 8 {
                            currentChukka += 1
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(currentChukka < 8 ? .blue : .gray)
                    }
                    .disabled(currentChukka >= 8)
                }
            }

            // Timer display
            VStack(spacing: 8) {
                Text(timeString)
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(chukkaTimeRemaining <= 60 ? .red : .primary)

                // Timer controls
                HStack(spacing: 16) {
                    // Start/Pause button
                    Button(action: {
                        if isTimerRunning {
                            pauseTimer()
                        } else {
                            startTimer()
                        }
                    }) {
                        HStack {
                            Image(systemName: isTimerRunning ? "pause.circle.fill" : "play.circle.fill")
                                .font(.title2)
                            Text(isTimerRunning ? "Pause" : "Start")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isTimerRunning ? Color.orange : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }

                    // Reset button
                    Button(action: {
                        resetTimer()
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .font(.title2)
                            Text("Reset")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
            }
        }
    }

    private var goalButtonsView: some View {
        HStack(spacing: 16) {
            // Home team goal button
            Button(action: {
                if !homeParticipations.isEmpty {
                    selectedTeamIsHome = true
                    showingPlayerPicker = true
                }
            }) {
                VStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 32))
                    Text("Add Goal")
                        .font(.caption)
                    Text(match.homeTeam?.name ?? "Home")
                        .font(.caption2)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(homeParticipations.isEmpty ? Color.gray.opacity(0.3) : Color.blue.opacity(0.2))
                .foregroundColor(homeParticipations.isEmpty ? .gray : .blue)
                .cornerRadius(12)
            }
            .disabled(homeParticipations.isEmpty)

            // Away team goal button
            Button(action: {
                if !awayParticipations.isEmpty {
                    selectedTeamIsHome = false
                    showingPlayerPicker = true
                }
            }) {
                VStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 32))
                    Text("Add Goal")
                        .font(.caption)
                    Text(match.awayTeam?.name ?? "Away")
                        .font(.caption2)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(awayParticipations.isEmpty ? Color.gray.opacity(0.3) : Color.orange.opacity(0.2))
                .foregroundColor(awayParticipations.isEmpty ? .gray : .orange)
                .cornerRadius(12)
            }
            .disabled(awayParticipations.isEmpty)
        }
    }

    private var goalHistoryView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Goal History")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 8)

            if goals.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "sportscourt")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No goals recorded yet")
                        .foregroundColor(.secondary)
                    Text("Add players to the match and start recording goals")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                List {
                    ForEach(goals.reversed()) { goal in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(goal.playerName)
                                    .font(.headline)
                                HStack(spacing: 8) {
                                    Text(goal.teamName)
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(goal.isHomeTeam ? Color.blue.opacity(0.2) : Color.orange.opacity(0.2))
                                        .foregroundColor(goal.isHomeTeam ? .blue : .orange)
                                        .cornerRadius(4)
                                    Text("Chukka \(goal.chukka)")
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.gray.opacity(0.2))
                                        .foregroundColor(.secondary)
                                        .cornerRadius(4)
                                }
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Image(systemName: "soccerball")
                                    .foregroundColor(goal.isHomeTeam ? .blue : .orange)
                                Text(goal.timestamp.formatted(date: .omitted, time: .shortened))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                removeGoal(goal)
                            } label: {
                                Label("Undo", systemImage: "arrow.uturn.backward")
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private func resultColor(for result: MatchResult) -> Color {
        switch result {
        case .win: return .green
        case .loss: return .red
        case .draw: return .orange
        case .pending: return .blue
        }
    }

    private func addGoal(for participation: MatchParticipation, isHomeTeam: Bool) {
        // Update match score
        if isHomeTeam {
            match.homeScore += 1
        } else {
            match.awayScore += 1
        }

        // Update player's goals in participation
        participation.goalsScored += 1

        // Update match result
        updateMatchResult()

        // Add to goal history
        if let player = participation.player, let team = participation.team {
            let goal = Goal(player: player, team: team, isHomeTeam: isHomeTeam, chukka: currentChukka)
            goals.append(goal)
        }
    }

    private func updateMatchResult() {
        if match.homeScore > match.awayScore {
            match.result = .win
        } else if match.awayScore > match.homeScore {
            match.result = .loss
        } else if match.homeScore == match.awayScore && (match.homeScore > 0 || match.awayScore > 0) {
            match.result = .draw
        } else {
            match.result = .pending
        }
    }

    private func removeGoal(_ goal: Goal) {
        // Remove from history
        goals.removeAll { $0.id == goal.id }

        // Update match score
        if goal.isHomeTeam {
            match.homeScore = max(0, match.homeScore - 1)
        } else {
            match.awayScore = max(0, match.awayScore - 1)
        }

        // Update player's goals in participation
        if let participation = match.participations.first(where: { $0.player?.id == goal.playerId }) {
            participation.goalsScored = max(0, participation.goalsScored - 1)
        }

        // Update match result
        updateMatchResult()
    }

    // MARK: - Timer Functions

    private func startTimer() {
        isTimerRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if chukkaTimeRemaining > 0 {
                chukkaTimeRemaining -= 1
            } else {
                // Timer reached zero
                pauseTimer()
            }
        }
    }

    private func pauseTimer() {
        isTimerRunning = false
        timer?.invalidate()
        timer = nil
    }

    private func resetTimer() {
        pauseTimer()
        chukkaTimeRemaining = 420 // Reset to 7 minutes
    }

    private func stopTimer() {
        pauseTimer()
        chukkaTimeRemaining = 420
    }
}

// MARK: - Player Goal Picker View

struct PlayerGoalPickerView: View {
    let participations: [MatchParticipation]
    let teamName: String
    let isHomeTeam: Bool
    let onPlayerSelected: (MatchParticipation) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                if participations.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No players added to this team yet")
                            .foregroundColor(.secondary)
                        Text("Add players to the match first in the Match Details view")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    Section(header: Text("Select Player Who Scored")) {
                        ForEach(participations, id: \.id) { participation in
                            Button(action: {
                                onPlayerSelected(participation)
                                dismiss()
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(participation.player?.displayName ?? "Unknown")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        HStack(spacing: 8) {
                                            Text("Goals: \(participation.goalsScored)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            if let horse = participation.horse {
                                                Text("• \(horse.name)")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.green)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Goal - \(teamName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
