//
//  ClubViews.swift
//  Australian Polo
//
//  Created by Rodrigo Castillo on 9/29/25.
//

import SwiftUI
import SwiftData

enum ClubViewMode: String, CaseIterable {
    case clubs = "Clubs"
    case players = "Players"
    case teams = "Teams"
    case fields = "Fields"
    case horses = "Horses"
}

// MARK: - Club List View

struct ClubListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var clubs: [Club]
    @Query private var players: [Player]
    @Query private var teams: [Team]
    @Query private var fields: [Field]
    @Query private var horses: [Horse]
    @State private var showingAddClub = false
    @State private var showingAddPlayer = false
    @State private var showingAddTeam = false
    @State private var showingAddField = false
    @State private var showingAddHorse = false
    @State private var selectedMode: ClubViewMode = .clubs
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Mode picker
                Picker("View Mode", selection: $selectedMode) {
                    ForEach(ClubViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                // Content based on mode
                switch selectedMode {
                case .clubs:
                    List {
                        ForEach(clubs.filter { $0.isActive }) { club in
                            NavigationLink(destination: ClubDetailView(club: club)) {
                                ClubRowView(club: club)
                            }
                        }
                        .onDelete(perform: deleteClubs)
                    }
                    .refreshable {
                        await refreshClubs()
                    }

                case .players:
                    List {
                        ForEach(players.filter { $0.isActive }) { player in
                            NavigationLink(destination: PlayerDetailView(player: player)) {
                                PlayerRowView(player: player)
                            }
                        }
                        .onDelete(perform: deletePlayers)
                    }
                    .refreshable {
                        await refreshPlayers()
                    }

                case .teams:
                    List {
                        ForEach(teams) { team in
                            NavigationLink(destination: TeamDetailView(team: team)) {
                                TeamRowView(team: team)
                            }
                        }
                        .onDelete(perform: deleteTeams)
                    }
                    .refreshable {
                        await refreshTeams()
                    }

                case .fields:
                    List {
                        ForEach(fields.filter { $0.isActive }) { field in
                            NavigationLink(destination: FieldDetailView(field: field)) {
                                FieldRowView(field: field)
                            }
                        }
                        .onDelete(perform: deleteFields)
                    }
                    .refreshable {
                        await refreshFields()
                    }

                case .horses:
                    List {
                        ForEach(horses.filter { $0.isActive }) { horse in
                            NavigationLink(destination: HorseDetailView(horse: horse)) {
                                HorseRowView(horse: horse)
                            }
                        }
                        .onDelete(perform: deleteHorses)
                    }
                    .refreshable {
                        await refreshHorses()
                    }
                }
            }
            .navigationTitle(selectedMode.rawValue)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        switch selectedMode {
                        case .clubs: showingAddClub = true
                        case .players: showingAddPlayer = true
                        case .teams: showingAddTeam = true
                        case .fields: showingAddField = true
                        case .horses: showingAddHorse = true
                        }
                    }) {
                        Label("Add \(selectedMode.rawValue.dropLast())", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddClub) {
                AddClubView()
            }
            .sheet(isPresented: $showingAddPlayer) {
                AddPlayerView()
            }
            .sheet(isPresented: $showingAddTeam) {
                AddTeamView()
            }
            .sheet(isPresented: $showingAddField) {
                AddFieldView()
            }
            .sheet(isPresented: $showingAddHorse) {
                AddHorseView()
            }
            .onAppear {
                // Fetch data when view appears (only if not already loaded)
                if players.isEmpty || teams.isEmpty || horses.isEmpty {
                    isLoading = true
                    Task {
                        print("🔄 ClubListView appeared, fetching data for all tabs...")
                        await refreshClubs()
                        await refreshPlayers()
                        await refreshTeams()
                        await refreshFields()
                        await refreshHorses()
                        await MainActor.run {
                            isLoading = false
                        }
                        print("✅ ClubListView finished initial data fetch")
                    }
                }
            }
            .overlay {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.3)
                        VStack {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Loading data...")
                                .foregroundColor(.white)
                                .padding()
                        }
                    }
                    .ignoresSafeArea()
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }

    private func deleteClubs(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let club = clubs.filter { $0.isActive }[index]
                club.isActive = false
            }
        }
    }

    private func deletePlayers(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let player = players.filter { $0.isActive }[index]
                player.isActive = false
            }
        }
    }

    private func deleteTeams(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let team = teams[index]

                // Call API to delete team if it has a backend ID
                if let backendId = team.backendId {
                    Task {
                        do {
                            try await ApiService.shared.deleteTeam(id: backendId)
                            // Delete from SwiftData on successful backend deletion
                            await MainActor.run {
                                modelContext.delete(team)
                            }
                        } catch {
                            print("Failed to delete team from backend: \(error.localizedDescription)")
                        }
                    }
                } else {
                    // If no backend ID, just delete locally
                    modelContext.delete(team)
                }
            }
        }
    }

    private func deleteFields(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let field = fields.filter { $0.isActive }[index]
                field.isActive = false
            }
        }
    }

    private func deleteHorses(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let horse = horses.filter { $0.isActive }[index]
                horse.isActive = false
            }
        }
    }

    // MARK: - Refresh Functions

    private func refreshClubs() async {
        do {
            let clubDTOs = try await ApiService.shared.getAllClubs()

            await MainActor.run {
                for dto in clubDTOs {
                    if let existing = clubs.first(where: { $0.backendId == dto.id }) {
                        // Update existing club
                        existing.name = dto.name
                        existing.location = dto.location ?? existing.location
                        if let foundedDateStr = dto.foundedDate, let foundedDate = Date.apiDate(from: foundedDateStr) {
                            existing.foundedDate = foundedDate
                        }
                    } else {
                        // Insert new club
                        var foundedDate = Date()
                        if let foundedDateStr = dto.foundedDate, let parsed = Date.apiDate(from: foundedDateStr) {
                            foundedDate = parsed
                        }
                        let newClub = Club(
                            name: dto.name,
                            location: dto.location ?? "",
                            foundedDate: foundedDate,
                            backendId: dto.id
                        )
                        modelContext.insert(newClub)
                    }
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to refresh clubs: \(error.localizedDescription)"
            }
        }
    }

    private func refreshPlayers() async {
        do {
            print("🔄 [ClubViews] Fetching players from API...")
            let playerDTOs = try await ApiService.shared.getAllPlayers()
            print("✅ [ClubViews] Received \(playerDTOs.count) players from API")

            await MainActor.run {
                var newCount = 0
                var updateCount = 0

                for dto in playerDTOs {
                    if let existing = players.first(where: { $0.backendId == dto.id }) {
                        // Update existing player with all backend fields
                        existing.firstName = dto.firstName
                        existing.surname = dto.surname
                        existing.state = dto.state.flatMap { AustralianState(rawValue: $0) }
                        existing.handicapJun2025 = dto.handicapJun2025
                        existing.womensHandicapJun2025 = dto.womensHandicapJun2025
                        existing.handicapDec2026 = dto.handicapDec2026
                        existing.womensHandicapDec2026 = dto.womensHandicapDec2026
                        existing.position = dto.position
                        updateCount += 1
                    } else {
                        // Insert new player
                        let newPlayer = Player(
                            firstName: dto.firstName,
                            surname: dto.surname,
                            state: dto.state.flatMap { AustralianState(rawValue: $0) },
                            handicapJun2025: dto.handicapJun2025,
                            backendId: dto.id
                        )
                        newPlayer.womensHandicapJun2025 = dto.womensHandicapJun2025
                        newPlayer.handicapDec2026 = dto.handicapDec2026
                        newPlayer.womensHandicapDec2026 = dto.womensHandicapDec2026
                        newPlayer.position = dto.position
                        modelContext.insert(newPlayer)
                        newCount += 1
                    }
                }

                print("✅ [ClubViews] Players: \(newCount) created, \(updateCount) updated. Total in DB: \(players.count)")
                print("📊 [ClubViews] Active players: \(players.filter { $0.isActive }.count)")

                // Explicitly save the context
                do {
                    try modelContext.save()
                    print("💾 [ClubViews] Context saved successfully")
                } catch {
                    print("❌ [ClubViews] Failed to save context: \(error)")
                }
            }
        } catch {
            print("❌ [ClubViews] Error refreshing players: \(error)")
            await MainActor.run {
                errorMessage = "Failed to refresh players: \(error.localizedDescription)"
            }
        }
    }

    private func refreshTeams() async {
        do {
            let teamDTOs = try await ApiService.shared.getAllTeams()

            await MainActor.run {
                for dto in teamDTOs {
                    if let existing = teams.first(where: { $0.backendId == dto.id }) {
                        // Update existing team
                        existing.name = dto.name
                    } else {
                        // Insert new team
                        let newTeam = Team(
                            name: dto.name,
                            grade: .medium,
                            backendId: dto.id
                        )
                        modelContext.insert(newTeam)
                    }
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to refresh teams: \(error.localizedDescription)"
            }
        }
    }

    private func refreshFields() async {
        do {
            let fieldDTOs = try await ApiService.shared.getAllFields()

            await MainActor.run {
                for dto in fieldDTOs {
                    if let existing = fields.first(where: { $0.backendId == dto.id }) {
                        // Update existing field
                        existing.name = dto.name
                        existing.location = dto.location ?? existing.location
                        if let gradeStr = dto.grade, let grade = TournamentGrade(rawValue: gradeStr) {
                            existing.grade = grade
                        }
                    } else {
                        // Insert new field
                        let grade: TournamentGrade
                        if let gradeStr = dto.grade, let parsed = TournamentGrade(rawValue: gradeStr) {
                            grade = parsed
                        } else {
                            grade = .medium
                        }
                        let newField = Field(
                            name: dto.name,
                            location: dto.location ?? "",
                            grade: grade,
                            backendId: dto.id
                        )
                        modelContext.insert(newField)
                    }
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to refresh fields: \(error.localizedDescription)"
            }
        }
    }

    private func refreshHorses() async {
        do {
            let horseDTOs = try await ApiService.shared.getAllHorses()

            await MainActor.run {
                for dto in horseDTOs {
                    if let existing = horses.first(where: { $0.backendId == dto.id }) {
                        // Update existing horse
                        existing.name = dto.name
                    } else {
                        // Insert new horse
                        let newHorse = Horse(
                            name: dto.name,
                            birthDate: Date(),
                            gender: .gelding,
                            color: .bay,
                            pedigree: dto.pedigree?["info"] ?? "",
                            backendId: dto.id
                        )
                        modelContext.insert(newHorse)
                    }
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to refresh horses: \(error.localizedDescription)"
            }
        }
    }
}

struct ClubRowView: View {
    let club: Club
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(club.name)
                .font(.headline)
            
            HStack {
                Image(systemName: "location")
                    .foregroundColor(.secondary)
                    .font(.caption)
                Text(club.location)
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            
            HStack {
                Text("Founded: \(club.foundedDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(club.players.count) players")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("\(club.teams.count) teams")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Add Club View

struct AddClubView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var location = ""
    @State private var foundedDate = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Club Information")) {
                    TextField("Name", text: $name)
                    TextField("Location", text: $location)
                    DatePicker("Founded Date", selection: $foundedDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Add Club")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        addClub()
                    }
                    .disabled(name.isEmpty || location.isEmpty)
                }
            }
        }
    }
    
    private func addClub() {
        let newClub = Club(name: name, location: location, foundedDate: foundedDate)
        modelContext.insert(newClub)
        dismiss()
    }
}

// MARK: - Club Detail View

struct ClubDetailView: View {
    @Bindable var club: Club
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        Form {
            Section(header: Text("Club Information")) {
                TextField("Name", text: $club.name)
                TextField("Location", text: $club.location)
                DatePicker("Founded Date", selection: $club.foundedDate, displayedComponents: .date)
                
                Toggle("Active Club", isOn: $club.isActive)
            }
            
            Section(header: Text("Statistics")) {
                HStack {
                    Text("Total Players")
                    Spacer()
                    Text("\(club.players.count)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Total Teams")
                    Spacer()
                    Text("\(club.teams.count)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Total Tournaments")
                    Spacer()
                    Text("\(club.tournaments.count)")
                        .foregroundColor(.secondary)
                }
            }
            
            if !club.teams.isEmpty {
                Section(header: Text("Teams")) {
                    ForEach(club.teams, id: \.id) { team in
                        NavigationLink(destination: TeamDetailView(team: team)) {
                            TeamRowView(team: team)
                        }
                    }
                }
            }
            
            if !club.players.isEmpty {
                Section(header: Text("Players")) {
                    ForEach(club.players.filter { $0.isActive }, id: \.id) { player in
                        NavigationLink(destination: PlayerDetailView(player: player)) {
                            PlayerRowView(player: player)
                        }
                    }
                }
            }
            
            if !club.tournaments.isEmpty {
                Section(header: Text("Recent Tournaments")) {
                    ForEach(club.tournaments.sorted { $0.startDate > $1.startDate }.prefix(5), id: \.id) { tournament in
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
        .navigationTitle(club.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
