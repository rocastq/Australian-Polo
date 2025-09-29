import Foundation
import SwiftData

@Model
class Field {
    @Attribute(.unique) var id: UUID
    var name: String
    var location: String
    var grade: Grade
    var isActive: Bool
    var createdDate: Date
    var notes: String?
    
    // Field specifications
    var length: Double? // in yards
    var width: Double? // in yards
    var surface: FieldSurface
    
    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \Tournament.fields) var tournaments: [Tournament]
    @Relationship(deleteRule: .cascade, inverse: \Match.field) var matches: [Match]
    
    init(
        name: String,
        location: String,
        grade: Grade,
        surface: FieldSurface = .grass,
        length: Double? = nil,
        width: Double? = nil,
        notes: String? = nil,
        isActive: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.location = location
        self.grade = grade
        self.surface = surface
        self.length = length
        self.width = width
        self.notes = notes
        self.isActive = isActive
        self.createdDate = Date()
        self.tournaments = []
        self.matches = []
    }
}

enum FieldSurface: String, CaseIterable, Codable {
    case grass = "Grass"
    case sand = "Sand"
    case artificial = "Artificial"
    case mixed = "Mixed"
}