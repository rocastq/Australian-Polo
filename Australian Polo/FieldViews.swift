//
//  FieldViews.swift
//  Australian Polo
//
//  Created by Rodrigo Castillo on 9/29/25.
//

import SwiftUI
import SwiftData

// MARK: - Field List View

struct FieldListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var fields: [Field]
    @State private var showingAddField = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(fields.filter { $0.isActive }) { field in
                    NavigationLink(destination: FieldDetailView(field: field)) {
                        FieldRowView(field: field)
                    }
                }
                .onDelete(perform: deleteFields)
            }
            .navigationTitle("Fields")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddField = true }) {
                        Label("Add Field", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddField) {
                AddFieldView()
            }
        }
    }
    
    private func deleteFields(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let field = fields.filter { $0.isActive }[index]
                field.isActive = false
            }
        }
    }
}

struct FieldRowView: View {
    let field: Field
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(field.name)
                    .font(.headline)
                Spacer()
                Text(field.grade.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(gradeColor(for: field.grade))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            HStack {
                Image(systemName: "location")
                    .foregroundColor(.secondary)
                    .font(.caption)
                Text(field.location)
                    .foregroundColor(.secondary)
                    .font(.caption)
                Spacer()
                Text("\(field.matches.count) matches")
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
        case .zero: return .gray
        case .subzero: return .gray.opacity(0.5)
        }
    }
}

// MARK: - Add Field View

struct AddFieldView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var location = ""
    @State private var selectedGrade: TournamentGrade = .medium
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Field Information")) {
                    TextField("Name", text: $name)
                    TextField("Location", text: $location)
                    
                    Picker("Grade", selection: $selectedGrade) {
                        ForEach(TournamentGrade.allCases, id: \.self) { grade in
                            Text(grade.rawValue).tag(grade)
                        }
                    }
                }
            }
            .navigationTitle("Add Field")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        addField()
                    }
                    .disabled(name.isEmpty || location.isEmpty)
                }
            }
        }
    }
    
    private func addField() {
        let newField = Field(name: name, location: location, grade: selectedGrade)
        modelContext.insert(newField)
        dismiss()
    }
}

// MARK: - Field Detail View

struct FieldDetailView: View {
    @Bindable var field: Field
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        Form {
            Section(header: Text("Field Information")) {
                TextField("Name", text: $field.name)
                TextField("Location", text: $field.location)
                
                Picker("Grade", selection: $field.grade) {
                    ForEach(TournamentGrade.allCases, id: \.self) { grade in
                        Text(grade.rawValue).tag(grade)
                    }
                }
                
                Toggle("Active Field", isOn: $field.isActive)
            }
            
            Section(header: Text("Statistics")) {
                HStack {
                    Text("Total Tournaments")
                    Spacer()
                    Text("\(field.tournaments.count)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Total Matches")
                    Spacer()
                    Text("\(field.matches.count)")
                        .foregroundColor(.secondary)
                }
            }
            
            if !field.tournaments.isEmpty {
                Section(header: Text("Tournaments")) {
                    ForEach(field.tournaments, id: \.id) { tournament in
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
            
            if !field.matches.isEmpty {
                Section(header: Text("Recent Matches")) {
                    ForEach(field.matches.sorted { $0.date > $1.date }.prefix(5), id: \.id) { match in
                        NavigationLink(destination: MatchDetailView(match: match)) {
                            MatchRowView(match: match)
                        }
                    }
                }
            }
        }
        .navigationTitle(field.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
