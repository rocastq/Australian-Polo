//
//  HomeView.swift
//  Australian Polo
//
//  Created by Rodrigo Castillo on 9/29/25.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query private var tournaments: [Tournament]
    @Query private var matches: [Match]
    @Query private var players: [Player]
    @Query private var teams: [Team]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    headerSection
                    
                    // Recent Tournaments Summary
                    recentTournamentsSection
                    
                    // Quick Stats
                    quickStatsSection
                    
                    // Feature Selection
                    featureSelectionSection
                    
                    Spacer(minLength: 32)
                }
                .padding()
            }
            .navigationTitle("Australian Polo")
            .navigationBarTitleDisplayMode(.large)
            .background(backgroundColor)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "sportscourt.fill")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Welcome to Australian Polo")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Manage tournaments, teams, and players")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Recent Tournaments Section
    private var recentTournamentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.orange)
                Text("Recent Tournaments")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if recentTournaments.isEmpty {
                Text("No recent tournaments")
                    .foregroundColor(.secondary)
                    .italic()
                    .padding(.vertical, 8)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(recentTournaments.prefix(3), id: \.id) { tournament in
                        TournamentSummaryCard(tournament: tournament)
                    }
                }
            }
        }
        .padding()
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Quick Stats Section
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.green)
                Text("Quick Stats")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            HStack(spacing: 16) {
                StatCard(title: "Active Tournaments", value: "\(activeTournaments.count)", color: .blue)
                StatCard(title: "Total Players", value: "\(players.count)", color: .purple)
                StatCard(title: "Active Teams", value: "\(activeTeams.count)", color: .orange)
            }
        }
        .padding()
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Feature Selection Section
    private var featureSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "square.grid.2x2.fill")
                    .foregroundColor(.indigo)
                Text("Features")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                FeatureCard(
                    title: "Tournaments",
                    icon: "trophy.fill",
                    color: .orange,
                    destination: AnyView(TournamentListView())
                )
                
                FeatureCard(
                    title: "Players",
                    icon: "person.circle.fill",
                    color: .blue,
                    destination: AnyView(PlayerListView())
                )
                
                FeatureCard(
                    title: "Teams",
                    icon: "person.3.sequence.fill",
                    color: .green,
                    destination: AnyView(TeamListView())
                )
                
                FeatureCard(
                    title: "Matches",
                    icon: "gamecontroller.fill",
                    color: .purple,
                    destination: AnyView(MatchListView())
                )
                
                FeatureCard(
                    title: "Statistics",
                    icon: "chart.bar.xaxis",
                    color: .red,
                    destination: AnyView(StatisticsView())
                )
                
                FeatureCard(
                    title: "Clubs",
                    icon: "building.2.fill",
                    color: .cyan,
                    destination: AnyView(ClubListView())
                )
            }
        }
        .padding()
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Computed Properties
    private var recentTournaments: [Tournament] {
        tournaments
            .filter { $0.isActive }
            .sorted { $0.startDate > $1.startDate }
    }
    
    private var activeTournaments: [Tournament] {
        tournaments.filter { $0.isActive }
    }
    
    private var activeTeams: [Team] {
        teams.filter { team in
            // Assuming teams are active if they have recent matches or are in active tournaments
            return true // You can add more sophisticated logic here
        }
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color(.systemGroupedBackground)
    }
    
    private var cardBackground: Color {
        colorScheme == .dark ? Color(.systemGray6) : Color.white
    }
}

// MARK: - Supporting Views

struct TournamentSummaryCard: View {
    let tournament: Tournament
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(tournament.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(tournament.location)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text("\(tournament.startDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(gradeColor.opacity(0.2))
                    .foregroundColor(gradeColor)
                    .clipShape(Capsule())
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var gradeColor: Color {
        switch tournament.grade {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct FeatureCard: View {
    let title: String
    let icon: String
    let color: Color
    let destination: AnyView
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
            .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .foregroundColor(.primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview("Light Mode") {
    HomeView()
        .modelContainer(for: [
            Tournament.self,
            Match.self,
            Player.self,
            Team.self
        ], inMemory: true)
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    HomeView()
        .modelContainer(for: [
            Tournament.self,
            Match.self,
            Player.self,
            Team.self
        ], inMemory: true)
        .preferredColorScheme(.dark)
}