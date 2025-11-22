//
//  ContentView.swift
//  Australian Polo
//
//  Created by Rodrigo Castillo on 9/29/25.
//

import SwiftUI
import SwiftData

// MARK: - Tabs

private enum AppTab: Hashable {
    case home
    case tournaments
    case matches
    case players
    case teams
    case more
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: AppTab = .home
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home / Dashboard
            NavigationStack {
                HomeDashboardView(selectedTab: $selectedTab)
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(AppTab.home)
            
            // Key sections as primary tabs
            TournamentListView()
                .tabItem {
                    Label("Tournaments", systemImage: "trophy")
                }
                .tag(AppTab.tournaments)
            
            MatchListView()
                .tabItem {
                    Label("Matches", systemImage: "sportscourt")
                }
                .tag(AppTab.matches)
            
            PlayerListView()
                .tabItem {
                    Label("Players", systemImage: "person.2.fill")
                }
                .tag(AppTab.players)
            
            TeamListView()
                .tabItem {
                    Label("Teams", systemImage: "person.3.sequence")
                }
                .tag(AppTab.teams)
            
            // "More" tab holds the remaining features
            MoreView()
                .tabItem {
                    Label("More", systemImage: "ellipsis.circle")
                }
                .tag(AppTab.more)
        }
    }
}

// MARK: - Legacy enum retained for destinations in “More”

enum NavigationSection: CaseIterable, Hashable {
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
        case .matches: return "sportscourt"
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

// MARK: - Home Dashboard

private struct HomeDashboardView: View {
    @Binding var selectedTab: AppTab
    
    // Fetch data and derive the subsets we want to show
    @Query private var tournaments: [Tournament]
    @Query(sort: \Match.date, order: .reverse) private var matches: [Match]
    @Query private var players: [Player]
    
    private var upcomingTournaments: [Tournament] {
        let now = Date()
        return Array(tournaments
            .filter { $0.isActive && $0.startDate >= now }
            .sorted { $0.startDate < $1.startDate }
            .prefix(3))
    }
    
    private var recentMatches: [Match] {
        Array(matches.prefix(5))
    }
    
    private var topPlayers: [Player] {
        Array(players
            .filter { $0.isActive }
            .sorted { $0.goalsScored > $1.goalsScored }
            .prefix(5))
    }
    
    private var activeCounts: (tournaments: Int, pendingMatches: Int, activePlayers: Int) {
        let t = tournaments.filter { $0.isActive }.count
        let pending = matches.filter { $0.result == .pending }.count
        let p = players.filter { $0.isActive }.count
        return (t, pending, p)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Welcome
                HStack(spacing: 12) {
                    Image(systemName: "sportscourt")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Australian Polo")
                            .font(.title2).bold()
                        Text("Dashboard")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
              
                // Summary tiles
                HStack(spacing: 12) {
                    SummaryTile(title: "Active Tournaments", value: "\(activeCounts.tournaments)", color: .orange, icon: "trophy")
                        .onTapGesture { selectedTab = .tournaments }
                    SummaryTile(title: "Pending Matches", value: "\(activeCounts.pendingMatches)", color: .blue, icon: "sportscourt")
                        .onTapGesture { selectedTab = .matches }
                    SummaryTile(title: "Active Players", value: "\(activeCounts.activePlayers)", color: .green, icon: "person.2.fill")
                        .onTapGesture { selectedTab = .players }
                }
                .padding(.horizontal)
                
                // Upcoming Tournaments
                SectionCard(title: "Upcoming Tournaments",
                            icon: "calendar",
                            accent: .orange,
                            seeAllTitle: "See All",
                            onSeeAll: { selectedTab = .tournaments }) {
                    if upcomingTournaments.isEmpty {
                        EmptyHint(text: "No upcoming tournaments.")
                    } else {
                        VStack(spacing: 8) {
                            ForEach(upcomingTournaments, id: \.id) { t in
                                NavigationLink {
                                    TournamentDetailView(tournament: t)
                                } label: {
                                    TournamentRowView(tournament: t)
                                }
                                .buttonStyle(.plain)
                                if t.id != upcomingTournaments.last?.id {
                                    Divider().opacity(0.2)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Recent Matches
                SectionCard(title: "Recent Matches",
                            icon: "clock.fill",
                            accent: .blue,
                            seeAllTitle: "See All",
                            onSeeAll: { selectedTab = .matches }) {
                    if recentMatches.isEmpty {
                        EmptyHint(text: "No matches yet.")
                    } else {
                        VStack(spacing: 8) {
                            ForEach(recentMatches, id: \.id) { m in
                                NavigationLink {
                                    MatchDetailView(match: m)
                                } label: {
                                    MatchRowView(match: m)
                                }
                                .buttonStyle(.plain)
                                if m.id != recentMatches.last?.id {
                                    Divider().opacity(0.2)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Top Players
                SectionCard(title: "Top Players",
                            icon: "star.fill",
                            accent: .green,
                            seeAllTitle: "See All",
                            onSeeAll: { selectedTab = .players }) {
                    if topPlayers.isEmpty {
                        EmptyHint(text: "No players yet.")
                    } else {
                        VStack(spacing: 8) {
                            ForEach(topPlayers, id: \.id) { p in
                                NavigationLink {
                                    PlayerDetailView(player: p)
                                } label: {
                                    PlayerRowView(player: p)
                                }
                                .buttonStyle(.plain)
                                if p.id != topPlayers.last?.id {
                                    Divider().opacity(0.2)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer(minLength: 12)
            }
            .padding(.bottom, 12)
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - More tab

struct MoreView: View {
    // Exclude the sections that already have their own tab
    private let moreSections: [NavigationSection] = [
        .users, .fields, .clubs, .duties, .breeders, .horses, .statistics
    ]
    
    var body: some View {
        List {
            Section {
                ForEach(moreSections, id: \.self) { section in
                    NavigationLink {
                        section.destination
                            .navigationTitle(section.title)
                    } label: {
                        Label(section.title, systemImage: section.icon)
                    }
                }
            } header: {
                Text("Browse")
            }
        }
        .navigationTitle("More")
    }
}

// MARK: - UI helpers

private struct SectionCard<Content: View>: View {
    let title: String
    let icon: String
    let accent: Color
    var seeAllTitle: String? = nil
    var onSeeAll: (() -> Void)? = nil
    @ViewBuilder var content: Content
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.headline)
                    .foregroundStyle(accent)
                Spacer()
                if let seeAllTitle, let onSeeAll {
                    Button(seeAllTitle, action: onSeeAll)
                        .font(.subheadline.weight(.semibold))
                }
            }
            .padding([.top, .horizontal])
            .padding(.bottom, 8)
            
            VStack(alignment: .leading, spacing: 0) {
                content
                    .padding(.horizontal)
                    .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

private struct SummaryTile: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
            }
            Text(value)
                .font(.title2).bold()
                .foregroundColor(.white)
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(colors: [color.opacity(0.9), color.opacity(0.6)],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct QuickLink: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(color.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                Text(title)
                    .font(.subheadline).bold()
                    .foregroundColor(.primary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct EmptyHint: View {
    let text: String
    var body: some View {
        HStack {
            Image(systemName: "info.circle")
                .foregroundColor(.secondary)
            Text(text)
                .foregroundColor(.secondary)
                .font(.subheadline)
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

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
