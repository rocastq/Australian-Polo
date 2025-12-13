//
//  TournamentViews.swift
//  Australian Polo
//
//  Created by Rodrigo Castillo on 9/29/25.
//

import SwiftUI
import SwiftData

enum TournamentViewMode: String, CaseIterable {
    case tournaments = "Tournaments"
    case matches = "Matches"
}

// MARK: - Tournament List View

struct TournamentListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tournaments: [Tournament]
    @Query(sort: \Match.date, order: .reverse) private var matches: [Match]
    @State private var showingAddTournament = false
    @State private var showingAddMatch = false
    @State private var selectedMode: TournamentViewMode = .tournaments
    @State private var selectedMatchResult: MatchResult?
    @State private var isLoadingTournaments = false
    @State private var errorMessage: String?

    private var filteredMatches: [Match] {
        if let selectedResult = selectedMatchResult {
            return matches.filter { $0.result == selectedResult }
        }
        return matches
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Mode picker
                Picker("View Mode", selection: $selectedMode) {
                    ForEach(TournamentViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                // Content based on mode
                switch selectedMode {
                case .tournaments:
                    List {
                        ForEach(tournaments.filter { $0.isActive }) { tournament in
                            NavigationLink(destination: TournamentDetailView(tournament: tournament)) {
                                TournamentRowView(tournament: tournament)
                            }
                        }
                        .onDelete(perform: deleteTournaments)
                    }
                    .refreshable {
                        await refreshTournaments()
                    }

                case .matches:
                    List {
                        Picker("Filter by Result", selection: $selectedMatchResult) {
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
                }
            }
            .navigationTitle(selectedMode.rawValue)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if selectedMode == .tournaments {
                            showingAddTournament = true
                        } else {
                            showingAddMatch = true
                        }
                    }) {
                        Label("Add \(selectedMode.rawValue.dropLast())", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTournament) {
                AddTournamentView()
            }
            .sheet(isPresented: $showingAddMatch) {
                AddMatchView()
            }
            .onAppear {
                fetchTournaments()
            }
        }
    }

    private func fetchTournaments() {
        isLoadingTournaments = true
        Task {
            do {
                let tournamentDTOs = try await ApiService.shared.getAllTournaments()

                // Save fetched tournaments to SwiftData
                await MainActor.run {
                    for dto in tournamentDTOs {
                        // Check if tournament already exists by backendId
                        let existingTournament = tournaments.first { $0.backendId == dto.id }

                        if existingTournament == nil {
                            // Parse dates from backend format (YYYY-MM-DD)
                            let startDate = dto.startDate.flatMap { Date.apiDate(from: $0) } ?? Date()
                            let endDate = dto.endDate.flatMap { Date.apiDate(from: $0) } ?? Date()
                            let location = dto.location ?? "Unknown"

                            // Create new tournament with backend ID
                            let newTournament = Tournament(
                                name: dto.name,
                                grade: .medium, // Default grade since backend doesn't provide it
                                startDate: startDate,
                                endDate: endDate,
                                location: location,
                                backendId: dto.id
                            )
                            modelContext.insert(newTournament)
                        }
                    }

                    isLoadingTournaments = false
                }
            } catch {
                await MainActor.run {
                    isLoadingTournaments = false
                    errorMessage = "Failed to fetch tournaments: \(error.localizedDescription)"
                }
            }
        }
    }

    private func refreshTournaments() async {
        do {
            let tournamentDTOs = try await ApiService.shared.getAllTournaments()

            await MainActor.run {
                for dto in tournamentDTOs {
                    if let existing = tournaments.first(where: { $0.backendId == dto.id }) {
                        // Update existing tournament
                        existing.name = dto.name
                        existing.location = dto.location ?? existing.location
                        if let startStr = dto.startDate, let start = Date.apiDate(from: startStr) {
                            existing.startDate = start
                        }
                        if let endStr = dto.endDate, let end = Date.apiDate(from: endStr) {
                            existing.endDate = end
                        }
                    } else {
                        // Insert new tournament
                        let startDate = dto.startDate.flatMap { Date.apiDate(from: $0) } ?? Date()
                        let endDate = dto.endDate.flatMap { Date.apiDate(from: $0) } ?? Date()
                        let newTournament = Tournament(
                            name: dto.name,
                            grade: .medium,
                            startDate: startDate,
                            endDate: endDate,
                            location: dto.location ?? "Unknown",
                            backendId: dto.id
                        )
                        modelContext.insert(newTournament)
                    }
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to refresh tournaments: \(error.localizedDescription)"
            }
        }
    }

    private func refreshMatches() async {
        // Fetch matches for all tournaments that have backend IDs
        let tournamentsWithBackendIds = tournaments.filter { $0.backendId != nil }

        for tournament in tournamentsWithBackendIds {
            guard let backendId = tournament.backendId else { continue }

            do {
                let matchDTOs = try await ApiService.shared.getMatchesByTournament(tournamentId: backendId)

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
                        // Note: New match insertion would require more complex logic
                        // to link teams, so we only update existing matches here
                    }
                }
            } catch {
                // Continue with other tournaments if one fails
                continue
            }
        }
    }

    private func deleteTournaments(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let tournament = tournaments.filter { $0.isActive }[index]

                // Call API to delete tournament if it has a backend ID
                if let backendId = tournament.backendId {
                    Task {
                        do {
                            try await ApiService.shared.deleteTournament(id: backendId)
                            // Delete from SwiftData on successful backend deletion
                            await MainActor.run {
                                modelContext.delete(tournament)
                            }
                        } catch {
                            await MainActor.run {
                                errorMessage = "Failed to delete tournament: \(error.localizedDescription)"
                            }
                        }
                    }
                } else {
                    // If no backend ID, just delete locally
                    modelContext.delete(tournament)
                }
            }
        }
    }

    private func deleteMatches(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredMatches[index])
            }
        }
    }
}

struct TournamentRowView: View {
    let tournament: Tournament
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(tournament.name)
                    .font(.headline)
                Spacer()
                Text(tournament.grade.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(gradeColor(for: tournament.grade))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Text(tournament.location)
                .foregroundColor(.secondary)
                .font(.caption)
            
            HStack {
                Text("Start: \(tournament.startDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("End: \(tournament.endDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
    
    private func gradeColor(for grade: TournamentGrade) -> Color {
        switch grade {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        case .zero: return .blue
        case .subzero: return .purple
        }
    }
}

// MARK: - Add Tournament View

struct AddTournamentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var clubs: [Club]
    @State private var name = ""
    @State private var selectedClub: Club?
    @State private var selectedGrade: TournamentGrade = .medium
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(7 * 24 * 60 * 60) // 7 days later
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Tournament Information")) {
                    TextField("Name", text: $name)

                    Picker("Club/Location", selection: $selectedClub) {
                        Text("Select Club").tag(nil as Club?)
                        ForEach(clubs.filter { $0.isActive }) { club in
                            Text("\(club.name) - \(club.location)").tag(club as Club?)
                        }
                    }

                    Picker("Grade", selection: $selectedGrade) {
                        ForEach(TournamentGrade.allCases, id: \.self) { grade in
                            Text(grade.rawValue).tag(grade)
                        }
                    }
                }

                Section(header: Text("Schedule")) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }

                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add Tournament")
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
                            addTournament()
                        }
                        .disabled(name.isEmpty || selectedClub == nil)
                    }
                }
            }
        }
    }

    private func addTournament() {
        guard let club = selectedClub else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let startDateString = startDate.apiISODateString()
                let endDateString = endDate.apiISODateString()

                // Call API to create tournament
                let tournamentDTO = try await ApiService.shared.createTournament(
                    name: name,
                    location: club.name,
                    startDate: startDateString,
                    endDate: endDateString
                )

                // Save locally to SwiftData with backend ID
                await MainActor.run {
                    let newTournament = Tournament(
                        name: name,
                        grade: selectedGrade,
                        startDate: startDate,
                        endDate: endDate,
                        location: club.name,
                        backendId: tournamentDTO.id
                    )
                    newTournament.club = club
                    modelContext.insert(newTournament)
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to create tournament: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Tournament Detail View

struct TournamentDetailView: View {
    @Bindable var tournament: Tournament
    @Query private var allClubs: [Club]
    @Query private var allFields: [Field]
    @Environment(\.modelContext) private var modelContext
    @State private var saveState: SaveState = .idle
    @State private var saveMessage: String = ""
    @State private var showingSaveAlert = false

    var body: some View {
        Form {
            Section(header: Text("Tournament Information")) {
                TextField("Name", text: $tournament.name)

                Picker("Club/Location", selection: Binding<Club?>(
                    get: { tournament.club },
                    set: { newClub in
                        tournament.club = newClub
                        if let club = newClub {
                            tournament.location = club.name
                        }
                    }
                )) {
                    Text("No Club").tag(Club?.none)
                    ForEach(allClubs.filter { $0.isActive }, id: \.id) { club in
                        Text("\(club.name) - \(club.location)").tag(Club?.some(club))
                    }
                }

                TextField("Location", text: $tournament.location)
                    .foregroundColor(.secondary)
                    .disabled(true)

                Picker("Grade", selection: $tournament.grade) {
                    ForEach(TournamentGrade.allCases, id: \.self) { grade in
                        Text(grade.rawValue).tag(grade)
                    }
                }
            }

            Section(header: Text("Schedule")) {
                DatePicker("Start Date", selection: $tournament.startDate, displayedComponents: .date)
                DatePicker("End Date", selection: $tournament.endDate, displayedComponents: .date)

                Toggle("Active Tournament", isOn: $tournament.isActive)
            }

            Section(header: Text("Associations")) {

                Picker("Field", selection: Binding<Field?>(
                    get: { tournament.field },
                    set: { tournament.field = $0 }
                )) {
                    Text("No Field").tag(Field?.none)
                    ForEach(allFields.filter { $0.isActive }, id: \.id) { field in
                        Text(field.name).tag(Field?.some(field))
                    }
                }
            }

            Section(header: Text("Statistics")) {
                HStack {
                    Text("Total Matches")
                    Spacer()
                    Text("\(tournament.matches.count)")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Teams Participating")
                    Spacer()
                    Text("\(tournament.teams.count)")
                        .foregroundColor(.secondary)
                }
            }

            if !tournament.matches.isEmpty {
                Section(header: Text("Matches")) {
                    ForEach(tournament.matches, id: \.id) { match in
                        NavigationLink(destination: MatchDetailView(match: match)) {
                            MatchRowView(match: match)
                        }
                    }
                }
            }
        }
        .navigationTitle(tournament.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if tournament.backendId != nil {
                    Button(action: saveToBackend) {
                        switch saveState {
                        case .idle:
                            Label("Save", systemImage: "square.and.arrow.up")
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
        guard let backendId = tournament.backendId else { return }

        saveState = .saving
        Task {
            do {
                let startDateString = tournament.startDate.apiISODateString()
                let endDateString = tournament.endDate.apiISODateString()

                _ = try await ApiService.shared.updateTournament(
                    id: backendId,
                    name: tournament.name,
                    location: tournament.location,
                    startDate: startDateString,
                    endDate: endDateString
                )

                await MainActor.run {
                    saveState = .success
                    saveMessage = "Tournament saved successfully"
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
}
