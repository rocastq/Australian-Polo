import Foundation
import SwiftData

@Model
class Duty {
    @Attribute(.unique) var id: UUID
    var dutyType: DutyType
    var assignmentDate: Date
    var isCompleted: Bool
    var notes: String?
    var createdDate: Date
    
    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \Player.duties) var player: Player?
    @Relationship(deleteRule: .nullify) var match: Match?
    @Relationship(deleteRule: .nullify) var tournament: Tournament?
    
    init(
        player: Player,
        dutyType: DutyType,
        assignmentDate: Date,
        match: Match? = nil,
        tournament: Tournament? = nil,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.player = player
        self.dutyType = dutyType
        self.assignmentDate = assignmentDate
        self.match = match
        self.tournament = tournament
        self.notes = notes
        self.isCompleted = false
        self.createdDate = Date()
    }
}

enum DutyType: String, CaseIterable, Codable {
    case mountedUmpire = "Mounted Umpire"
    case goalUmpire = "Goal Umpire"
    case centreTable = "Centre Table"
    case timekeeper = "Timekeeper"
    case scorer = "Scorer"
    case announcer = "Announcer"
    case fieldMaintenance = "Field Maintenance"
    
    var description: String {
        switch self {
        case .mountedUmpire:
            return "Mounted umpire responsible for officiating the match on horseback"
        case .goalUmpire:
            return "Goal umpire positioned to judge goals and goal attempts"
        case .centreTable:
            return "Centre table official managing match administration"
        case .timekeeper:
            return "Official responsible for timing chukkers and match duration"
        case .scorer:
            return "Official responsible for recording match scores and statistics"
        case .announcer:
            return "Match announcer providing commentary and information"
        case .fieldMaintenance:
            return "Field maintenance crew ensuring field conditions"
        }
    }
    
    var requiresMounting: Bool {
        switch self {
        case .mountedUmpire:
            return true
        default:
            return false
        }
    }
}