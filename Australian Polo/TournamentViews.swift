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
                // Tournaments fetched successfully
                await MainActor.run {
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

    private func deleteTournaments(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let tournament = tournaments.filter { $0.isActive }[index]
                tournament.isActive = false

                // Call API to delete tournament
                Task {
                    do {
                        // TODO: Implement proper UUID to backend ID mapping
                        let tournamentId = abs(tournament.id.hashValue)
                        try await ApiService.shared.deleteTournament(id: tournamentId)
                    } catch {
                        print("Failed to delete tournament from API: \(error.localizedDescription)")
                    }
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
        }
    }
}

// MARK: - Add Tournament View

struct AddTournamentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var location = ""
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
                    TextField("Location", text: $location)

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
                        .disabled(name.isEmpty || location.isEmpty)
                    }
                }
            }
        }
    }

    private func addTournament() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                // Use MySQL-compatible date format (YYYY-MM-DD)
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                dateFormatter.timeZone = TimeZone(identifier: "UTC")
                let startDateString = dateFormatter.string(from: startDate)
                let endDateString = dateFormatter.string(from: endDate)

                // Call API to create tournament
                let tournamentDTO = try await ApiService.shared.createTournament(
                    name: name,
                    location: location,
                    startDate: startDateString,
                    endDate: endDateString
                )

                // Also save locally to SwiftData
                await MainActor.run {
                    let newTournament = Tournament(name: name, grade: selectedGrade, startDate: startDate, endDate: endDate, location: location)
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
    
    var body: some View {
        Form {
            Section(header: Text("Tournament Information")) {
                TextField("Name", text: $tournament.name)
                TextField("Location", text: $tournament.location)
                
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
                Picker("Club", selection: Binding<Club?>(
                    get: { tournament.club },
                    set: { tournament.club = $0 }
                )) {
                    Text("No Club").tag(Club?.none)
                    ForEach(allClubs.filter { $0.isActive }, id: \.id) { club in
                        Text(club.name).tag(Club?.some(club))
                    }
                }
                
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
    }
}
