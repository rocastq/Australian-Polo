import SwiftUI
import SwiftData

struct TeamListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var teams: [Team]
    @State private var showingAddTeam = false
    @State private var searchText = ""
    @State private var selectedGradeFilter: Grade?
    
    var filteredTeams: [Team] {
        var filtered = teams
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply grade filter
        if let grade = selectedGradeFilter {
            filtered = filtered.filter { $0.grade == grade }
        }
        
        return filtered.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Grade Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        Button("All") {
                            selectedGradeFilter = nil
                        }
                        .buttonStyle(FilterButtonStyle(isSelected: selectedGradeFilter == nil))
                        
                        ForEach(Grade.allCases, id: \.self) { grade in
                            Button(grade.rawValue) {
                                selectedGradeFilter = grade
                            }
                            .buttonStyle(FilterButtonStyle(isSelected: selectedGradeFilter == grade))
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                List {
                    ForEach(filteredTeams, id: \.id) { team in
                        NavigationLink(destination: TeamDetailView(team: team)) {
                            TeamRow(team: team)
                        }
                    }
                    .onDelete(perform: deleteTeams)
                }
            }
            .searchable(text: $searchText, prompt: "Search teams...")
            .navigationTitle("Teams")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddTeam = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTeam) {
                AddTeamView()
            }
        }
    }
    
    private func deleteTeams(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredTeams[index])
            }
        }
    }
}

struct TeamRow: View {
    let team: Team
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                // Team color indicator
                if let colorName = team.teamColor {
                    Circle()
                        .fill(colorFromString(colorName))
                        .frame(width: 12, height: 12)
                }
                
                Text(team.name)
                    .font(.headline)
                
                Spacer()
                
                Text(team.grade.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)
            }
            
            HStack {
                Text("\(team.players.count) players")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if team.totalHandicap > 0 {
                    Text("Handicap: \(team.totalHandicap, specifier: "%.1f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let club = team.club {
                Text(club.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Win/Loss record
            if team.wins > 0 || team.losses > 0 {
                HStack {
                    Text("Record: \(team.wins)W - \(team.losses)L")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(team.winPercentage, specifier: "%.1f")% win rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func colorFromString(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "yellow": return .yellow
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "black": return .black
        case "white": return .white
        case "gray": return .gray
        default: return .blue
        }
    }
}

struct FilterButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                isSelected ? Color.blue : Color(.systemGray5)
            )
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct AddTeamView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var clubs: [Club]
    
    @State private var name = ""
    @State private var selectedGrade = Grade.medium
    @State private var selectedClub: Club?
    @State private var teamColor = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Team Details") {
                    TextField("Team Name", text: $name)
                    
                    Picker("Grade", selection: $selectedGrade) {
                        ForEach(Grade.allCases, id: \.self) { grade in
                            Text(grade.rawValue).tag(grade)
                        }
                    }
                    
                    Picker("Club", selection: $selectedClub) {
                        Text("No Club").tag(nil as Club?)
                        ForEach(clubs, id: \.id) { club in
                            Text(club.name).tag(club as Club?)
                        }
                    }
                    
                    TextField("Team Color (Optional)", text: $teamColor)
                }
            }
            .navigationTitle("New Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveTeam()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveTeam() {
        let team = Team(
            name: name,
            grade: selectedGrade,
            club: selectedClub,
            teamColor: teamColor.isEmpty ? nil : teamColor
        )
        
        modelContext.insert(team)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving team: \(error)")
        }
    }
}

#Preview {
    TeamListView()
        .modelContainer(for: [Team.self, Club.self])
}