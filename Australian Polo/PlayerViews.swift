//
//  PlayerViews.swift
//  Australian Polo
//
//  Created by Rodrigo Castillo on 9/29/25.
//

import SwiftUI
import SwiftData

// MARK: - Player List View

struct PlayerListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var players: [Player]
    @State private var showingAddPlayer = false
    @State private var isLoadingPlayers = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
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
            .navigationTitle("Players")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddPlayer = true }) {
                        Label("Add Player", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddPlayer) {
                AddPlayerView()
            }
            .onAppear {
                fetchPlayers()
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

    private func fetchPlayers() {
        isLoadingPlayers = true
        Task {
            do {
                print("🔄 Fetching players from API...")
                let playerDTOs = try await ApiService.shared.getAllPlayers()
                print("✅ Received \(playerDTOs.count) players from API")

                // Save fetched players to SwiftData
                await MainActor.run {
                    for dto in playerDTOs {
                        print("📝 Processing player: \(dto.firstName) \(dto.surname) (ID: \(dto.id))")
                        // Check if player already exists by backendId
                        let existingPlayer = players.first { $0.backendId == dto.id }

                        if existingPlayer == nil {
                            // Create new player with backend ID
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
                            print("➕ Created new player: \(newPlayer.displayName)")
                        } else {
                            print("⏭️ Player already exists, skipping")
                        }
                    }

                    print("✅ Finished processing. Total players in DB: \(players.count)")

                    // Explicitly save the context
                    do {
                        try modelContext.save()
                        print("💾 [PlayerViews] Context saved successfully")
                    } catch {
                        print("❌ [PlayerViews] Failed to save context: \(error)")
                    }

                    isLoadingPlayers = false
                }
            } catch {
                print("❌ Error fetching players: \(error)")
                await MainActor.run {
                    isLoadingPlayers = false
                    errorMessage = "Failed to fetch players: \(error.localizedDescription)"
                }
            }
        }
    }

    private func deletePlayers(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let player = players.filter { $0.isActive }[index]

                // Call API to delete player if it has a backend ID
                if let backendId = player.backendId {
                    Task {
                        do {
                            try await ApiService.shared.deletePlayer(id: backendId)
                            // Mark as inactive on successful backend deletion
                            await MainActor.run {
                                player.isActive = false
                            }
                        } catch {
                            print("Failed to delete player from backend: \(error.localizedDescription)")
                        }
                    }
                } else {
                    // If no backend ID, just mark as inactive locally
                    player.isActive = false
                }
            }
        }
    }

    private func refreshPlayers() async {
        do {
            let playerDTOs = try await ApiService.shared.getAllPlayers()

            await MainActor.run {
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
                    }
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to refresh players: \(error.localizedDescription)"
            }
        }
    }
}

struct PlayerRowView: View {
    let player: Player

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(player.displayName)
                    .font(.headline)
                if let state = player.state {
                    Text(state.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.gray.opacity(0.2))
                        .cornerRadius(4)
                }
                Spacer()
                Text("Handicap: \(player.currentHandicap, specifier: "%.1f")")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            HStack {
                Text("Games: \(player.gamesPlayed)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Goals: \(player.goalsScored)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if player.gamesPlayed > 0 {
                    Text("Win Rate: \(player.winPercentage, specifier: "%.1f")%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if let club = player.club {
                Text("Club: \(club.name)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Add Player View

struct AddPlayerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var firstName = ""
    @State private var surname = ""
    @State private var selectedState: AustralianState?
    @State private var handicapJun2025: Double = 0
    @State private var womensHandicapJun2025: Double = 0
    @State private var handicapDec2026: Double = 0
    @State private var womensHandicapDec2026: Double = 0
    @State private var position = ""
    @Query private var clubs: [Club]
    @Query private var users: [User]
    @State private var selectedClub: Club?
    @State private var selectedUser: User?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Player Information")) {
                    TextField("First Name", text: $firstName)
                    TextField("Surname", text: $surname)

                    Picker("State", selection: $selectedState) {
                        Text("Select State").tag(AustralianState?.none)
                        ForEach(AustralianState.allCases, id: \.self) { state in
                            Text(state.rawValue).tag(AustralianState?.some(state))
                        }
                    }

                    TextField("Position", text: $position)
                }

                Section(header: Text("Handicaps - June 2025")) {
                    VStack(alignment: .leading) {
                        Text("Open Handicap: \(handicapJun2025, specifier: "%.1f")")
                        Slider(value: $handicapJun2025, in: -2...10, step: 0.5)
                    }

                    VStack(alignment: .leading) {
                        Text("Women's Handicap: \(womensHandicapJun2025, specifier: "%.1f")")
                        Slider(value: $womensHandicapJun2025, in: -2...10, step: 0.5)
                    }
                }

                Section(header: Text("Handicaps - December 2026")) {
                    VStack(alignment: .leading) {
                        Text("Open Handicap: \(handicapDec2026, specifier: "%.1f")")
                        Slider(value: $handicapDec2026, in: -2...10, step: 0.5)
                    }

                    VStack(alignment: .leading) {
                        Text("Women's Handicap: \(womensHandicapDec2026, specifier: "%.1f")")
                        Slider(value: $womensHandicapDec2026, in: -2...10, step: 0.5)
                    }
                }

                Section(header: Text("Associations")) {
                    Picker("User Account", selection: $selectedUser) {
                        Text("No User Account").tag(User?.none)
                        ForEach(users.filter { $0.isActive && $0.role == .player && $0.playerProfile == nil }, id: \.id) { user in
                            Text(user.name).tag(User?.some(user))
                        }
                    }

                    Picker("Club", selection: $selectedClub) {
                        Text("No Club").tag(Club?.none)
                        ForEach(clubs.filter { $0.isActive }, id: \.id) { club in
                            Text(club.name).tag(Club?.some(club))
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
            .navigationTitle("Add Player")
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
                            addPlayer()
                        }
                        .disabled(firstName.isEmpty || surname.isEmpty)
                    }
                }
            }
        }
    }

    private func addPlayer() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                // Call API to create player
                let playerDTO = try await ApiService.shared.createPlayer(
                    firstName: firstName,
                    surname: surname,
                    state: selectedState?.rawValue,
                    handicapJun2025: handicapJun2025,
                    womensHandicapJun2025: womensHandicapJun2025,
                    handicapDec2026: handicapDec2026,
                    womensHandicapDec2026: womensHandicapDec2026,
                    teamId: nil,
                    position: position.isEmpty ? nil : position,
                    clubId: selectedClub?.backendId
                )

                // Save locally to SwiftData with backend ID
                await MainActor.run {
                    let newPlayer = Player(
                        firstName: firstName,
                        surname: surname,
                        state: selectedState,
                        handicapJun2025: handicapJun2025,
                        backendId: playerDTO.id
                    )
                    newPlayer.womensHandicapJun2025 = womensHandicapJun2025
                    newPlayer.handicapDec2026 = handicapDec2026
                    newPlayer.womensHandicapDec2026 = womensHandicapDec2026
                    newPlayer.position = position.isEmpty ? nil : position
                    newPlayer.club = selectedClub
                    newPlayer.user = selectedUser
                    selectedUser?.playerProfile = newPlayer
                    modelContext.insert(newPlayer)
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to create player: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Player Detail View

struct PlayerDetailView: View {
    @Bindable var player: Player
    @Query private var allClubs: [Club]
    @Query private var allUsers: [User]
    @Environment(\.modelContext) private var modelContext
    @State private var saveState: SaveState = .idle
    @State private var saveMessage: String = ""
    @State private var showingSaveAlert = false
    @State private var positionText: String = ""

    // Helper bindings to avoid type-checker complexity
    private var handicapJun2025Binding: Binding<Double> {
        Binding(
            get: { player.handicapJun2025 ?? 0 },
            set: { player.handicapJun2025 = $0 }
        )
    }

    private var womensHandicapJun2025Binding: Binding<Double> {
        Binding(
            get: { player.womensHandicapJun2025 ?? 0 },
            set: { player.womensHandicapJun2025 = $0 }
        )
    }

    private var handicapDec2026Binding: Binding<Double> {
        Binding(
            get: { player.handicapDec2026 ?? 0 },
            set: { player.handicapDec2026 = $0 }
        )
    }

    private var womensHandicapDec2026Binding: Binding<Double> {
        Binding(
            get: { player.womensHandicapDec2026 ?? 0 },
            set: { player.womensHandicapDec2026 = $0 }
        )
    }

    private var stateBinding: Binding<AustralianState?> {
        Binding(
            get: { player.state },
            set: { player.state = $0 }
        )
    }

    private var userBinding: Binding<User?> {
        Binding(
            get: { player.user },
            set: {
                player.user?.playerProfile = nil
                player.user = $0
                $0?.playerProfile = player
            }
        )
    }

    private var clubBinding: Binding<Club?> {
        Binding(
            get: { player.club },
            set: { player.club = $0 }
        )
    }

    var body: some View {
        Form {
            Section(header: Text("Player Information")) {
                TextField("First Name", text: $player.firstName)
                TextField("Surname", text: $player.surname)

                Picker("State", selection: stateBinding) {
                    Text("Select State").tag(AustralianState?.none)
                    ForEach(AustralianState.allCases, id: \.self) { state in
                        Text(state.rawValue).tag(AustralianState?.some(state))
                    }
                }

                TextField("Position", text: $positionText)
                    .onAppear { positionText = player.position ?? "" }
                    .onChange(of: positionText) { _, newValue in
                        player.position = newValue.isEmpty ? nil : newValue
                    }

                DatePicker("Join Date", selection: $player.joinDate, displayedComponents: .date)
                Toggle("Active Player", isOn: $player.isActive)
            }

            Section(header: Text("Handicaps - June 2025")) {
                VStack(alignment: .leading) {
                    Text("Open Handicap: \(player.handicapJun2025 ?? 0, specifier: "%.1f")")
                    Slider(value: handicapJun2025Binding, in: -2...10, step: 0.5)
                }

                VStack(alignment: .leading) {
                    Text("Women's Handicap: \(player.womensHandicapJun2025 ?? 0, specifier: "%.1f")")
                    Slider(value: womensHandicapJun2025Binding, in: -2...10, step: 0.5)
                }
            }

            Section(header: Text("Handicaps - December 2026")) {
                VStack(alignment: .leading) {
                    Text("Open Handicap: \(player.handicapDec2026 ?? 0, specifier: "%.1f")")
                    Slider(value: handicapDec2026Binding, in: -2...10, step: 0.5)
                }

                VStack(alignment: .leading) {
                    Text("Women's Handicap: \(player.womensHandicapDec2026 ?? 0, specifier: "%.1f")")
                    Slider(value: womensHandicapDec2026Binding, in: -2...10, step: 0.5)
                }
            }

            Section(header: Text("Associations")) {
                Picker("User Account", selection: userBinding) {
                    Text("No User Account").tag(User?.none)
                    ForEach(allUsers.filter { $0.isActive && $0.role == .player && ($0.playerProfile == nil || $0.playerProfile?.id == player.id) }, id: \.id) { user in
                        Text(user.name).tag(User?.some(user))
                    }
                }

                Picker("Club", selection: clubBinding) {
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
                    Text("\(player.gamesPlayed)")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Goals Scored")
                    Spacer()
                    Text("\(player.goalsScored)")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Wins")
                    Spacer()
                    Text("\(player.wins)")
                        .foregroundColor(.green)
                }

                HStack {
                    Text("Losses")
                    Spacer()
                    Text("\(player.losses)")
                        .foregroundColor(.red)
                }

                HStack {
                    Text("Draws")
                    Spacer()
                    Text("\(player.draws)")
                        .foregroundColor(.orange)
                }

                if player.gamesPlayed > 0 {
                    HStack {
                        Text("Win Percentage")
                        Spacer()
                        Text("\(player.winPercentage, specifier: "%.1f")%")
                            .foregroundColor(.secondary)
                    }
                }
            }

            if !player.teams.isEmpty {
                Section(header: Text("Teams")) {
                    ForEach(player.teams, id: \.id) { team in
                        NavigationLink(destination: TeamDetailView(team: team)) {
                            TeamRowView(team: team)
                        }
                    }
                }
            }

            if !player.horses.isEmpty {
                Section(header: Text("Horses")) {
                    ForEach(player.horses.filter { $0.isActive }, id: \.id) { horse in
                        NavigationLink(destination: HorseDetailView(horse: horse)) {
                            HorseRowView(horse: horse)
                        }
                    }
                }
            }

            if !player.duties.isEmpty {
                Section(header: Text("Recent Duties")) {
                    ForEach(player.duties.sorted { $0.date > $1.date }.prefix(5), id: \.id) { duty in
                        NavigationLink(destination: DutyDetailView(duty: duty)) {
                            DutyRowView(duty: duty)
                        }
                    }
                }
            }
        }
        .navigationTitle(player.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if player.backendId != nil {
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
        guard let backendId = player.backendId else { return }

        saveState = .saving
        Task {
            do {
                _ = try await ApiService.shared.updatePlayer(
                    id: backendId,
                    firstName: player.firstName,
                    surname: player.surname,
                    state: player.state?.rawValue,
                    handicapJun2025: player.handicapJun2025,
                    womensHandicapJun2025: player.womensHandicapJun2025,
                    handicapDec2026: player.handicapDec2026,
                    womensHandicapDec2026: player.womensHandicapDec2026,
                    teamId: nil,
                    position: player.position,
                    clubId: player.club?.backendId
                )

                await MainActor.run {
                    saveState = .success
                    saveMessage = "Player saved successfully"
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


#Preview {
    ContentView()
        .modelContainer(for: [
            Player.self,
        ], inMemory: true)
}
