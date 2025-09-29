import Foundation
import SwiftData

@Model
class Award {
    @Attribute(.unique) var id: UUID
    var name: String
    var awardType: AwardType
    var dateAwarded: Date
    var description: String?
    var createdDate: Date
    
    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \Tournament.awards) var tournament: Tournament?
    @Relationship(deleteRule: .nullify, inverse: \Player.awards) var player: Player?
    @Relationship(deleteRule: .nullify, inverse: \Horse.awards) var horse: Horse?
    @Relationship(deleteRule: .nullify) var team: Team?
    
    init(
        name: String,
        awardType: AwardType,
        dateAwarded: Date = Date(),
        tournament: Tournament? = nil,
        player: Player? = nil,
        horse: Horse? = nil,
        team: Team? = nil,
        description: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.awardType = awardType
        self.dateAwarded = dateAwarded
        self.tournament = tournament
        self.player = player
        self.horse = horse
        self.team = team
        self.description = description
        self.createdDate = Date()
    }
}

enum AwardType: String, CaseIterable, Codable {
    case tournamentWinner = "Tournament Winner"
    case runnerUp = "Runner Up"
    case mostValuablePlayer = "Most Valuable Player"
    case bestPlayingPony = "Best Playing Pony"
    case highestGoalScorer = "Highest Goal Scorer"
    case bestYoungPlayer = "Best Young Player"
    case sportsmanshipAward = "Sportsmanship Award"
    case fairPlay = "Fair Play"
    case bestTeam = "Best Team"
    case other = "Other"
    
    var isTeamAward: Bool {
        switch self {
        case .tournamentWinner, .runnerUp, .bestTeam:
            return true
        default:
            return false
        }
    }
    
    var isPlayerAward: Bool {
        switch self {
        case .mostValuablePlayer, .highestGoalScorer, .bestYoungPlayer, .sportsmanshipAward, .fairPlay:
            return true
        default:
            return false
        }
    }
    
    var isHorseAward: Bool {
        switch self {
        case .bestPlayingPony:
            return true
        default:
            return false
        }
    }
}