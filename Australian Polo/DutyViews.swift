//
//  DutyViews.swift
//  Australian Polo
//
//  Created by Rodrigo Castillo on 9/29/25.
//

import SwiftUI
import SwiftData

// MARK: - Duty List View

struct DutyListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Duty.date, order: .reverse) private var duties: [Duty]
    @State private var showingAddDuty = false
    @State private var selectedDutyType: DutyType?
    
    var body: some View {
        NavigationView {
            List {
                Picker("Filter by Type", selection: $selectedDutyType) {
                    Text("All Duties").tag(DutyType?.none)
                    ForEach(DutyType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(DutyType?.some(type))
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.vertical, 8)
                
                ForEach(filteredDuties) { duty in
                    NavigationLink(destination: DutyDetailView(duty: duty)) {
                        DutyRowView(duty: duty)
                    }
                }
                .onDelete(perform: deleteDuties)
            }
            .navigationTitle("Duties")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddDuty = true }) {
                        Label("Add Duty", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddDuty) {
                AddDutyView()
            }
        }
    }
    
    private var filteredDuties: [Duty] {
        if let selectedType = selectedDutyType {
            return duties.filter { $0.type == selectedType }
        }
        return duties
    }
    
    private func deleteDuties(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredDuties[index])
            }
        }
    }
}

struct DutyRowView: View {
    let duty: Duty
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(duty.type.rawValue)
                    .font(.headline)
                Spacer()
                Text(duty.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(dutyColor(for: duty.type))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            if let player = duty.player {
                Text("Assigned to: \(player.displayName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("No player assigned")
                    .font(.subheadline)
                    .foregroundColor(.orange)
            }
            
            if !duty.notes.isEmpty {
                Text(duty.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            if let match = duty.match {
                Text("Match: \(match.homeTeam?.name ?? "TBD") vs \(match.awayTeam?.name ?? "TBD")")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 2)
    }
    
    private func dutyColor(for type: DutyType) -> Color {
        switch type {
        case .umpire: return .blue
        case .centreTable: return .green
        case .goalUmpire: return .orange
        }
    }
}

// MARK: - Add Duty View

struct AddDutyView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var selectedType: DutyType = .umpire
    @State private var date = Date()
    @State private var notes = ""
    @Query private var players: [Player]
    @Query private var matches: [Match]
    @State private var selectedPlayer: Player?
    @State private var selectedMatch: Match?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Duty Information")) {
                    Picker("Type", selection: $selectedType) {
                        ForEach(DutyType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(header: Text("Assignments")) {
                    Picker("Player", selection: $selectedPlayer) {
                        Text("No Player Assigned").tag(Player?.none)
                        ForEach(players.filter { $0.isActive }, id: \.id) { player in
                            Text(player.displayName).tag(Player?.some(player))
                        }
                    }
                    
                    Picker("Match", selection: $selectedMatch) {
                        Text("No Specific Match").tag(Match?.none)
                        ForEach(matches.filter { $0.result == .pending }, id: \.id) { match in
                            Text("\(match.homeTeam?.name ?? "TBD") vs \(match.awayTeam?.name ?? "TBD")").tag(Match?.some(match))
                        }
                    }
                }
            }
            .navigationTitle("Add Duty")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        addDuty()
                    }
                }
            }
        }
    }
    
    private func addDuty() {
        let newDuty = Duty(type: selectedType, date: date, notes: notes)
        newDuty.player = selectedPlayer
        newDuty.match = selectedMatch
        modelContext.insert(newDuty)
        dismiss()
    }
}

// MARK: - Duty Detail View

struct DutyDetailView: View {
    @Bindable var duty: Duty
    @Query private var allPlayers: [Player]
    @Query private var allMatches: [Match]
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        Form {
            Section(header: Text("Duty Information")) {
                Picker("Type", selection: $duty.type) {
                    ForEach(DutyType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                
                DatePicker("Date", selection: $duty.date, displayedComponents: [.date, .hourAndMinute])
                
                TextField("Notes", text: $duty.notes, axis: .vertical)
                    .lineLimit(3...6)
            }
            
            Section(header: Text("Assignments")) {
                Picker("Player", selection: Binding<Player?>(
                    get: { duty.player },
                    set: { duty.player = $0 }
                )) {
                    Text("No Player Assigned").tag(Player?.none)
                    ForEach(allPlayers.filter { $0.isActive }, id: \.id) { player in
                        Text(player.displayName).tag(Player?.some(player))
                    }
                }
                
                Picker("Match", selection: Binding<Match?>(
                    get: { duty.match },
                    set: { duty.match = $0 }
                )) {
                    Text("No Specific Match").tag(Match?.none)
                    ForEach(allMatches, id: \.id) { match in
                        Text("\(match.homeTeam?.name ?? "TBD") vs \(match.awayTeam?.name ?? "TBD")").tag(Match?.some(match))
                    }
                }
            }
            
            if let player = duty.player {
                Section(header: Text("Player Details")) {
                    NavigationLink(destination: PlayerDetailView(player: player)) {
                        PlayerRowView(player: player)
                    }
                }
            }
            
            if let match = duty.match {
                Section(header: Text("Match Details")) {
                    NavigationLink(destination: MatchDetailView(match: match)) {
                        MatchRowView(match: match)
                    }
                }
            }
        }
        .navigationTitle(duty.type.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }
}