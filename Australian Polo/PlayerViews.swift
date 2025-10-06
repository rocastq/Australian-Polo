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
}

struct PlayerRowView: View {
    let player: Player
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(player.name)
                    .font(.headline)
                Spacer()
                Text("Handicap: \(player.handicap, specifier: "%.1f")")
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
    @State private var name = ""
    @State private var handicap: Double = 0
    @Query private var clubs: [Club]
    @Query private var users: [User]
    @State private var selectedClub: Club?
    @State private var selectedUser: User?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Player Information")) {
                    TextField("Name", text: $name)
                    
                    VStack(alignment: .leading) {
                        Text("Handicap: \(handicap, specifier: "%.1f")")
                        Slider(value: $handicap, in: -2...10, step: 1) {
                            Text("Handicap")
                        }
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
                    Button("Save") {
                        addPlayer()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func addPlayer() {
        let newPlayer = Player(name: name, handicap: handicap)
        newPlayer.club = selectedClub
        newPlayer.user = selectedUser
        selectedUser?.playerProfile = newPlayer
        modelContext.insert(newPlayer)
        dismiss()
    }
}

// MARK: - Player Detail View

struct PlayerDetailView: View {
    @Bindable var player: Player
    @Query private var allClubs: [Club]
    @Query private var allUsers: [User]
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        Form {
            Section(header: Text("Player Information")) {
                TextField("Name", text: $player.name)
                
                VStack(alignment: .leading) {
                    Text("Handicap: \(player.handicap, specifier: "%.1f")")
                    Slider(value: $player.handicap, in: -2...10, step: 1) {
                        Text("Handicap")
                    }
                }
                
                DatePicker("Join Date", selection: $player.joinDate, displayedComponents: .date)
                
                Toggle("Active Player", isOn: $player.isActive)
            }
            
            Section(header: Text("Associations")) {
                Picker("User Account", selection: Binding<User?>(
                    get: { player.user },
                    set: { 
                        player.user?.playerProfile = nil
                        player.user = $0
                        $0?.playerProfile = player
                    }
                )) {
                    Text("No User Account").tag(User?.none)
                    ForEach(allUsers.filter { $0.isActive && $0.role == .player && ($0.playerProfile == nil || $0.playerProfile?.id == player.id) }, id: \.id) { user in
                        Text(user.name).tag(User?.some(user))
                    }
                }
                
                Picker("Club", selection: Binding<Club?>(
                    get: { player.club },
                    set: { player.club = $0 }
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
        .navigationTitle(player.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}


#Preview {
    ContentView()
        .modelContainer(for: [
            Player.self,
        ], inMemory: true)
}
