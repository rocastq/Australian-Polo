import SwiftUI
import SwiftData

struct DutyListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var duties: [Duty]
    @State private var showingAddDuty = false
    @State private var searchText = ""
    @State private var selectedDutyTypeFilter: DutyType?
    @State private var showCompletedOnly = false
    
    var filteredDuties: [Duty] {
        var filtered = duties
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.player?.fullName.localizedCaseInsensitiveContains(searchText) == true ||
                $0.dutyType.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply duty type filter
        if let dutyType = selectedDutyTypeFilter {
            filtered = filtered.filter { $0.dutyType == dutyType }
        }
        
        // Apply completion filter
        if showCompletedOnly {
            filtered = filtered.filter { $0.isCompleted }
        }
        
        return filtered.sorted { $0.assignmentDate > $1.assignmentDate }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        Menu("Duty Type") {
                            Button("All Types") {
                                selectedDutyTypeFilter = nil
                            }
                            ForEach(DutyType.allCases, id: \.self) { dutyType in
                                Button(dutyType.rawValue) {
                                    selectedDutyTypeFilter = dutyType
                                }
                            }
                        }
                        .buttonStyle(FilterMenuButtonStyle(isSelected: selectedDutyTypeFilter != nil))
                        
                        Button("Completed Only") {
                            showCompletedOnly.toggle()
                        }
                        .buttonStyle(FilterButtonStyle(isSelected: showCompletedOnly))
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                List {
                    ForEach(filteredDuties, id: \.id) { duty in
                        DutyRow(duty: duty)
                    }
                    .onDelete(perform: deleteDuties)
                }
            }
            .searchable(text: $searchText, prompt: "Search duties...")
            .navigationTitle("Duties")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddDuty = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddDuty) {
                AddDutyView()
            }
        }
    }
    
    private func deleteDuties(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredDuties[index])
            }
        }
    }
}

struct DutyRow: View {
    let duty: Duty
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(duty.dutyType.rawValue)
                        .font(.headline)
                    
                    if let player = duty.player {
                        Text("Assigned to: \(player.fullName)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Button {
                        toggleCompletion()
                    } label: {
                        Image(systemName: duty.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(duty.isCompleted ? .green : .gray)
                            .font(.title2)
                    }
                    
                    Text(duty.assignmentDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Context information
            HStack {
                if let match = duty.match {
                    Label("Match duty", systemImage: "sportscourt")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    if let teamA = match.teamA, let teamB = match.teamB {
                        Text("\(teamA.name) vs \(teamB.name)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if let tournament = duty.tournament {
                    Label("Tournament duty", systemImage: "trophy")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Text(tournament.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Status and notes
            HStack {
                Text(duty.isCompleted ? "Completed" : "Pending")
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(duty.isCompleted ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                    .foregroundColor(duty.isCompleted ? .green : .orange)
                    .cornerRadius(4)
                
                if let notes = duty.notes, !notes.isEmpty {
                    Text("• \(notes)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            // Duty description
            Text(duty.dutyType.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
        }
        .padding(.vertical, 4)
    }
    
    private func toggleCompletion() {
        duty.isCompleted.toggle()
        
        do {
            try modelContext.save()
        } catch {
            print("Error updating duty completion: \(error)")
        }
    }
}

struct AddDutyView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var players: [Player]
    @Query private var matches: [Match]
    @Query private var tournaments: [Tournament]
    
    @State private var selectedPlayer: Player?
    @State private var selectedDutyType = DutyType.mountedUmpire
    @State private var assignmentDate = Date()
    @State private var selectedMatch: Match?
    @State private var selectedTournament: Tournament?
    @State private var notes = ""
    @State private var selectedAssignmentType: AssignmentType = .match
    
    enum AssignmentType: String, CaseIterable {
        case match = "Match"
        case tournament = "Tournament"
        case general = "General"
    }
    
    var availableMatches: [Match] {
        matches.filter { $0.status != .completed }.sorted { $0.date < $1.date }
    }
    
    var availableTournaments: [Tournament] {
        tournaments.filter { $0.isActive }.sorted { $0.startDate < $1.startDate }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Duty Assignment") {
                    Picker("Player", selection: $selectedPlayer) {
                        Text("Select Player").tag(nil as Player?)
                        ForEach(players.filter { $0.isActive }, id: \.id) { player in
                            Text(player.fullName).tag(player as Player?)
                        }
                    }
                    
                    Picker("Duty Type", selection: $selectedDutyType) {
                        ForEach(DutyType.allCases, id: \.self) { dutyType in
                            Text(dutyType.rawValue).tag(dutyType)
                        }
                    }
                    
                    DatePicker("Assignment Date", selection: $assignmentDate, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section("Assignment Context") {
                    Picker("Assignment Type", selection: $selectedAssignmentType) {
                        ForEach(AssignmentType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    switch selectedAssignmentType {
                    case .match:
                        Picker("Match", selection: $selectedMatch) {
                            Text("Select Match").tag(nil as Match?)
                            ForEach(availableMatches, id: \.id) { match in
                                if let teamA = match.teamA, let teamB = match.teamB {
                                    Text("\(teamA.name) vs \(teamB.name) - \(match.date.formatted(date: .abbreviated, time: .shortened))").tag(match as Match?)
                                }
                            }
                        }
                    case .tournament:
                        Picker("Tournament", selection: $selectedTournament) {
                            Text("Select Tournament").tag(nil as Tournament?)
                            ForEach(availableTournaments, id: \.id) { tournament in
                                Text(tournament.name).tag(tournament as Tournament?)
                            }
                        }
                    case .general:
                        EmptyView()
                    }
                }
                
                Section("Additional Information") {
                    TextField("Notes (Optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Duty Description") {
                    Text(selectedDutyType.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            .navigationTitle("New Duty Assignment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveDuty()
                    }
                    .disabled(selectedPlayer == nil)
                }
            }
        }
    }
    
    private func saveDuty() {
        guard let player = selectedPlayer else { return }
        
        let duty = Duty(
            player: player,
            dutyType: selectedDutyType,
            assignmentDate: assignmentDate,
            match: selectedAssignmentType == .match ? selectedMatch : nil,
            tournament: selectedAssignmentType == .tournament ? selectedTournament : nil,
            notes: notes.isEmpty ? nil : notes
        )
        
        modelContext.insert(duty)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving duty: \(error)")
        }
    }
}

struct DutyCalendarView: View {
    @Query private var duties: [Duty]
    @State private var selectedDate = Date()
    
    var dutiesForSelectedDate: [Duty] {
        let calendar = Calendar.current
        return duties.filter { duty in
            calendar.isDate(duty.assignmentDate, inSameDayAs: selectedDate)
        }.sorted { $0.assignmentDate < $1.assignmentDate }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
                
                Text("Duties for \(selectedDate.formatted(date: .complete, time: .omitted))")
                    .font(.headline)
                    .padding(.horizontal)
                
                if dutiesForSelectedDate.isEmpty {
                    Text("No duties scheduled for this date")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    List {
                        ForEach(dutiesForSelectedDate, id: \.id) { duty in
                            DutyRow(duty: duty)
                        }
                    }
                }
            }
            .navigationTitle("Duty Calendar")
        }
    }
}

#Preview {
    DutyListView()
        .modelContainer(for: [Duty.self, Player.self, Match.self, Tournament.self])
}