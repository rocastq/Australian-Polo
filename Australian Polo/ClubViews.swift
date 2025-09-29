//
//  ClubViews.swift
//  Australian Polo
//
//  Created by Rodrigo Castillo on 9/29/25.
//

import SwiftUI
import SwiftData

// MARK: - Club List View

struct ClubListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var clubs: [Club]
    @State private var showingAddClub = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(clubs.filter { $0.isActive }) { club in
                    NavigationLink(destination: ClubDetailView(club: club)) {
                        ClubRowView(club: club)
                    }
                }
                .onDelete(perform: deleteClubs)
            }
            .navigationTitle("Clubs")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddClub = true }) {
                        Label("Add Club", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddClub) {
                AddClubView()
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