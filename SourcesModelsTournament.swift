import Foundation
import SwiftData

@Model
class Tournament {
    @Attribute(.unique) var id: UUID
    var name: String
    var grade: Grade
    var startDate: Date
    var endDate: Date
    var location: String?
    var isActive: Bool
    var createdDate: Date
    
    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \Match.tournament) var matches: [Match]
    @Relationship(deleteRule: .nullify, inverse: \Field.tournaments) var fields: [Field]
    @Relationship(deleteRule: .nullify, inverse: \Club.tournaments) var clubs: [Club]
    @Relationship(deleteRule: .nullify, inverse: \Award.tournament) var awards: [Award]
    
    init(
        name: String,
        grade: Grade,
        startDate: Date,
        endDate: Date,
        location: String? = nil,
        isActive: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.grade = grade
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.isActive = isActive
        self.createdDate = Date()
        self.matches = []
        self.fields = []
        self.clubs = []
        self.awards = []
    }
    
    var duration: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
}

enum Grade: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case open = "Open"
    
    var handicapRange: ClosedRange<Double> {
        switch self {
        case .low: return 0...8
        case .medium: return 8...16
        case .high: return 16...26
        case .open: return 0...40
        }
    }
}