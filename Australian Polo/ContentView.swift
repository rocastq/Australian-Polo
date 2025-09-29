//
//  ContentView.swift
//  Australian Polo
//
//  Created by Rodrigo Castillo on 9/29/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedSection: NavigationSection?
    
    var body: some View {
        NavigationSplitView {
            List(NavigationSection.allCases, id: \.self, selection: $selectedSection) { section in
                NavigationLink(value: section) {
                    Label(section.title, systemImage: section.icon)
                }
            }
            .navigationTitle("Australian Polo")
        } detail: {
            if let selectedSection = selectedSection {
                selectedSection.destination
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "sportscourt")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    Text("Welcome to Australian Polo")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Select a section from the sidebar to get started")
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
    }
}

enum NavigationSection: CaseIterable {
    case users
    case tournaments
    case fields
    case clubs
    case teams
    case duties
    case players
    case breeders
    case horses
    case matches
    case statistics
    
    var title: String {
        switch self {
        case .users: return "Users"
        case .tournaments: return "Tournaments"
        case .fields: return "Fields"
        case .clubs: return "Clubs"
        case .teams: return "Teams"
        case .duties: return "Duties"
        case .players: return "Players"
        case .breeders: return "Breeders"
        case .horses: return "Horses"
        case .matches: return "Matches"
        case .statistics: return "Statistics"
        }
    }
    
    var icon: String {
        switch self {
        case .users: return "person.3"
        case .tournaments: return "trophy"
        case .fields: return "map"
        case .clubs: return "building.2"
        case .teams: return "person.3.sequence"
        case .duties: return "person.badge.shield.checkmark"
        case .players: return "person.circle"
        case .breeders: return "figure.equestrian.sports"
        case .horses: return "pawprint"
        case .matches: return "gamecontroller"
        case .statistics: return "chart.bar.xaxis"
        }
    }
    
    @ViewBuilder
    var destination: some View {
        switch self {
        case .users: UserListView()
        case .tournaments: TournamentListView()
        case .fields: FieldListView()
        case .clubs: ClubListView()
        case .teams: TeamListView()
        case .duties: DutyListView()
        case .players: PlayerListView()
        case .breeders: BreederListView()
        case .horses: HorseListView()
        case .matches: MatchListView()
        case .statistics: StatisticsView()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            User.self,
            Tournament.self,
            Field.self,
            Club.self,
            Team.self,
            Duty.self,
            Player.self,
            Breeder.self,
            Horse.self,
            Match.self,
            MatchParticipation.self,
            Item.self
        ], inMemory: true)
}
