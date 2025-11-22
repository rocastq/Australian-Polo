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

                case .players:
                    List {
                        ForEach(players.filter { $0.isActive }) { player in
                            NavigationLink(destination: PlayerDetailView(player: player)) {
                                PlayerRowView(player: player)
                            }
                        }
                        .onDelete(perform: deletePlayers)
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

                case .fields:
                    List {
                        ForEach(fields.filter { $0.isActive }) { field in
                            NavigationLink(destination: FieldDetailView(field: field)) {
                                FieldRowView(field: field)
                            }
                        }
                        .onDelete(perform: deleteFields)
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
                modelContext.delete(teams[index])
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