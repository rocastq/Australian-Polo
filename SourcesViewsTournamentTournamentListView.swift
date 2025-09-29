import SwiftUI
import SwiftData

struct TournamentListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tournaments: [Tournament]
    @State private var showingAddTournament = false
    @State private var searchText = ""
    
    var filteredTournaments: [Tournament] {
        if searchText.isEmpty {
            return tournaments.sorted { $0.startDate > $1.startDate }
        } else {
            return tournaments.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }.sorted { $0.startDate > $1.startDate }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredTournaments, id: \.id) { tournament in
                    NavigationLink(destination: TournamentDetailView(tournament: tournament)) {
                        TournamentRow(tournament: tournament)
                    }
                }
                .onDelete(perform: deleteTournaments)
            }
            .searchable(text: $searchText, prompt: "Search tournaments...")
            .navigationTitle("Tournaments")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddTournament = true
                    } label: {
                        Image(systemName: "plus")
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
                modelContext.delete(filteredTournaments[index])
            }
        }
    }
}

struct TournamentRow: View {
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
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)
            }
            
            HStack {
                Text(tournament.startDate, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let location = tournament.location {
                    Text("• \(location)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if tournament.isActive {
                    Text("Active")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
            }
            
            Text("\(tournament.matches.count) matches")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

struct AddTournamentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var selectedGrade = Grade.medium
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(7 * 24 * 60 * 60) // One week later
    @State private var location = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Tournament Details") {
                    TextField("Tournament Name", text: $name)
                    
                    Picker("Grade", selection: $selectedGrade) {
                        ForEach(Grade.allCases, id: \.self) { grade in
                            Text(grade.rawValue).tag(grade)
                        }
                    }
                    
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    
                    TextField("Location (Optional)", text: $location)
                }
            }
            .navigationTitle("New Tournament")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveTournament()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveTournament() {
        let tournament = Tournament(
            name: name,
            grade: selectedGrade,
            startDate: startDate,
            endDate: endDate,
            location: location.isEmpty ? nil : location
        )
        
        modelContext.insert(tournament)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            // Handle error
            print("Error saving tournament: \(error)")
        }
    }
}

#Preview {
    TournamentListView()
        .modelContainer(for: Tournament.self)
}