import Foundation
import SwiftData

@Model
class Player {
    @Attribute(.unique) var id: UUID
    var firstName: String
    var lastName: String
    var handicap: Double
    var isActive: Bool
    var createdDate: Date
    var birthDate: Date?
    var nationality: String?
    
    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \User.player) var user: User?
    @Relationship(deleteRule: .nullify, inverse: \Team.players) var teams: [Team]
    @Relationship(deleteRule: .nullify, inverse: \Club.players) var club: Club?
    @Relationship(deleteRule: .cascade, inverse: \Duty.player) var duties: [Duty]
    @Relationship(deleteRule: .nullify, inverse: \Award.player) var awards: [Award]
    @Relationship(deleteRule: .cascade, inverse: \PlayerStatistic.player) var statistics: [PlayerStatistic]
    
    init(
        firstName: String,
        lastName: String,
        handicap: Double,
        user: User? = nil,
        club: Club? = nil,
        birthDate: Date? = nil,
        nationality: String? = nil,
        isActive: Bool = true
    ) {
        self.id = UUID()
        self.firstName = firstName
        self.lastName = lastName
        self.handicap = max(-2, min(10, handicap)) // Polo handicaps range from -2 to 10
        self.user = user
        self.club = club
        self.birthDate = birthDate
        self.nationality = nationality
        self.isActive = isActive
        self.createdDate = Date()
        self.teams = []
        self.duties = []
        self.awards = []
        self.statistics = []
    }
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    var age: Int? {
        guard let birthDate = birthDate else { return nil }
        return Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year
    }
    
    var totalGoals: Int {
        statistics.reduce(0) { $0 + $1.goals }
    }
    
    var totalMatches: Int {
        statistics.count
    }
    
    var averageGoalsPerMatch: Double {
        guard totalMatches > 0 else { return 0 }
        return Double(totalGoals) / Double(totalMatches)
    }
}

@Model
class PlayerStatistic {
    @Attribute(.unique) var id: UUID
    var goals: Int
    var assists: Int
    var fouls: Int
    var yellowCards: Int
    var redCards: Int
    var matchDate: Date
    
    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \Player.statistics) var player: Player?
    @Relationship(deleteRule: .nullify, inverse: \Match.playerStatistics) var match: Match?
    
    init(
        player: Player,
        match: Match,
        goals: Int = 0,
        assists: Int = 0,
        fouls: Int = 0,
        yellowCards: Int = 0,
        redCards: Int = 0
    ) {
        self.id = UUID()
        self.player = player
        self.match = match
        self.goals = goals
        self.assists = assists
        self.fouls = fouls
        self.yellowCards = yellowCards
        self.redCards = redCards
        self.matchDate = match?.date ?? Date()
    }
}