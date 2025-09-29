import SwiftUI
import SwiftData

struct FieldListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var fields: [Field]
    @State private var showingAddField = false
    @State private var searchText = ""
    
    var filteredFields: [Field] {
        if searchText.isEmpty {
            return fields.sorted { $0.name < $1.name }
        } else {
            return fields.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.location.localizedCaseInsensitiveContains(searchText)
            }.sorted { $0.name < $1.name }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredFields, id: \.id) { field in
                    FieldRow(field: field)
                }
                .onDelete(perform: deleteFields)
            }
            .searchable(text: $searchText, prompt: "Search fields...")
            .navigationTitle("Fields")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddField = true
                    } label: {
                        Image(systemName: "plus")
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
                modelContext.delete(filteredFields[index])
            }
        }
    }
}

struct FieldRow: View {
    let field: Field
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(field.name)
                    .font(.headline)
                
                Spacer()
                
                Text(field.grade.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(4)
            }
            
            Text(field.location)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Text(field.surface.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let length = field.length, let width = field.width {
                    Text("• \(Int(length))x\(Int(width)) yards")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !field.isActive {
                    Text("Inactive")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            if field.matches.count > 0 {
                Text("\(field.matches.count) matches played")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddFieldView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var location = ""
    @State private var selectedGrade = Grade.medium
    @State private var selectedSurface = FieldSurface.grass
    @State private var length = ""
    @State private var width = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Field Details") {
                    TextField("Field Name", text: $name)
                    TextField("Location", text: $location)
                    
                    Picker("Grade", selection: $selectedGrade) {
                        ForEach(Grade.allCases, id: \.self) { grade in
                            Text(grade.rawValue).tag(grade)
                        }
                    }
                    
                    Picker("Surface", selection: $selectedSurface) {
                        ForEach(FieldSurface.allCases, id: \.self) { surface in
                            Text(surface.rawValue).tag(surface)
                        }
                    }
                }
                
                Section("Dimensions (Optional)") {
                    TextField("Length (yards)", text: $length)
                        .keyboardType(.decimalPad)
                    TextField("Width (yards)", text: $width)
                        .keyboardType(.decimalPad)
                }
                
                Section("Notes") {
                    TextField("Notes (Optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New Field")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveField()
                    }
                    .disabled(name.isEmpty || location.isEmpty)
                }
            }
        }
    }
    
    private func saveField() {
        let field = Field(
            name: name,
            location: location,
            grade: selectedGrade,
            surface: selectedSurface,
            length: Double(length),
            width: Double(width),
            notes: notes.isEmpty ? nil : notes
        )
        
        modelContext.insert(field)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving field: \(error)")
        }
    }
}

#Preview {
    FieldListView()
        .modelContainer(for: Field.self)
}