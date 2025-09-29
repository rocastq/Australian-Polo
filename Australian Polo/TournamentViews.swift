//
//  TournamentViews.swift
//  Australian Polo
//
//  Created by Rodrigo Castillo on 9/29/25.
//

import SwiftUI
import SwiftData

// MARK: - Tournament List View

struct TournamentListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tournaments: [Tournament]
    @State private var showingAddTournament = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(tournaments.filter { $0.isActive }) { tournament in
                    NavigationLink(destination: TournamentDetailView(tournament: tournament)) {
                        TournamentRowView(tournament: tournament)
                    }
                }
                .onDelete(perform: deleteTournaments)
            }
            .navigationTitle("Tournaments")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTournament = true }) {
                        Label("Add Tournament", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTournament) {
                AddTournamentView()
            }
        }
    }
    
    private func deleteTournaments(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let tournament = tournaments.filter { $0.isActive }[index]
                tournament.isActive = false
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
            }
            .navigationTitle("Add Tournament")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        addTournament()
                    }
                    .disabled(name.isEmpty || location.isEmpty)
                }
            }
        }
    }
    
    private func addTournament() {
        let newTournament = Tournament(name: name, grade: selectedGrade, startDate: startDate, endDate: endDate, location: location)
        modelContext.insert(newTournament)
        dismiss()
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