import Foundation
import SwiftData

@Model
class Team {
    @Attribute(.unique) var id: UUID
    var name: String
    var grade: Grade
    var isActive: Bool
    var createdDate: Date
    var teamColor: String?
    
    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \Player.teams) var players: [Player]
    @Relationship(deleteRule: .nullify, inverse: \Club.teams) var club: Club?
    @Relationship(deleteRule: .cascade, inverse: \Match.teamA) var matchesAsTeamA: [Match]
    @Relationship(deleteRule: .cascade, inverse: \Match.teamB) var matchesAsTeamB: [Match]
    
    init(
        name: String,
        grade: Grade,
        club: Club? = nil,
        teamColor: String? = nil,
        isActive: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.grade = grade
        self.club = club
        self.teamColor = teamColor
        self.isActive = isActive
        self.createdDate = Date()
        self.players = []
        self.matchesAsTeamA = []
        self.matchesAsTeamB = []
    }
    
    var totalHandicap: Double {
        players.reduce(0) { $0 + $1.handicap }
    }
    
    var averageHandicap: Double {
        guard !players.isEmpty else { return 0 }
        return totalHandicap / Double(players.count)
    }
    
    var allMatches: [Match] {
        matchesAsTeamA + matchesAsTeamB
    }
    
    var wins: Int {
        allMatches.filter { match in
            match.winner == self
        }.count
    }
    
    var losses: Int {
        allMatches.filter { match in
            match.winner != nil && match.winner != self
        }.count
    }
    
    var winPercentage: Double {
        let totalGames = wins + losses
        guard totalGames > 0 else { return 0 }
        return Double(wins) / Double(totalGames) * 100
    }
}