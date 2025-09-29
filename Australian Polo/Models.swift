//
//  Models.swift
//  Australian Polo
//
//  Created by Rodrigo Castillo on 9/29/25.
//

import Foundation
import SwiftData

// MARK: - User Management

enum UserRole: String, CaseIterable, Codable {
    case administrator = "Administrator"
    case clubOperator = "Club Operator"
    case player = "Player"
    case breeder = "Breeder"
    case user = "User"
}

@Model
final class User {
    var id: UUID
    var name: String
    var email: String
    var role: UserRole
    var createdAt: Date
    var isActive: Bool
    
    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \Player.user) var playerProfile: Player?
    @Relationship(deleteRule: .nullify, inverse: \Breeder.user) var breederProfile: Breeder?
    
    init(name: String, email: String, role: UserRole) {
        self.id = UUID()
        self.name = name
        self.email = email
        self.role = role
        self.createdAt = Date()
        self.isActive = true
    }
}

// MARK: - Tournament Management

enum TournamentGrade: String, CaseIterable, Codable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
}

@Model
final class Tournament {
    var id: UUID
    var name: String
    var grade: TournamentGrade
    var startDate: Date
    var endDate: Date
    var location: String
    var isActive: Bool
    
    // Relationships
    @Relationship(deleteRule: .cascade) var matches: [Match] = []
    @Relationship(deleteRule: .nullify, inverse: \Club.tournaments) var club: Club?
    @Relationship(deleteRule: .nullify) var field: Field?
    @Relationship(deleteRule: .nullify) var teams: [Team] = []
    
    init(name: String, grade: TournamentGrade, startDate: Date, endDate: Date, location: String) {
        self.id = UUID()
        self.name = name
        self.grade = grade
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.isActive = true
    }
}

// MARK: - Field Management

@Model
final class Field {
    var id: UUID
    var name: String
    var location: String
    var grade: TournamentGrade
    var isActive: Bool
    
    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \Tournament.field) var tournaments: [Tournament] = []
    @Relationship(deleteRule: .cascade) var matches: [Match] = []
    
    init(name: String, location: String, grade: TournamentGrade) {
        self.id = UUID()
        self.name = name
        self.location = location
        self.grade = grade
        self.isActive = true
    }
}

// MARK: - Club Management

@Model
final class Club {
    var id: UUID
    var name: String
    var location: String
    var foundedDate: Date
    var isActive: Bool
    
    // Relationships
    @Relationship(deleteRule: .nullify) var tournaments: [Tournament] = []
    @Relationship(deleteRule: .nullify, inverse: \Team.club) var teams: [Team] = []
    @Relationship(deleteRule: .nullify, inverse: \Player.club) var players: [Player] = []
    
    init(name: String, location: String, foundedDate: Date = Date()) {
        self.id = UUID()
        self.name = name
        self.location = location
        self.foundedDate = foundedDate
        self.isActive = true
    }
}

// MARK: - Team Management

@Model
final class Team {
    var id: UUID
    var name: String
    var grade: TournamentGrade
    var wins: Int
    var losses: Int
    var draws: Int
    var goalsFor: Int
    var goalsAgainst: Int
    
    // Relationships
    @Relationship(deleteRule: .nullify) var players: [Player] = []
    @Relationship(deleteRule: .nullify) var club: Club?
    @Relationship(deleteRule: .nullify) var tournaments: [Tournament] = []
    @Relationship(deleteRule: .cascade) var homeMatches: [Match] = []
    @Relationship(deleteRule: .cascade) var awayMatches: [Match] = []
    
    init(name: String, grade: TournamentGrade) {
        self.id = UUID()
        self.name = name
        self.grade = grade
        self.wins = 0
        self.losses = 0
        self.draws = 0
        self.goalsFor = 0
        self.goalsAgainst = 0
    }
    
    var gamesPlayed: Int { wins + losses + draws }
    var goalDifference: Int { goalsFor - goalsAgainst }
}

// MARK: - Duties Management

enum DutyType: String, CaseIterable, Codable {
    case umpire = "Umpire"
    case centreTable = "Centre Table"
    case goalUmpire = "Goal Umpire"
}

@Model
final class Duty {
    var id: UUID
    var type: DutyType
    var date: Date
    var notes: String
    
    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \Player.duties) var player: Player?
    @Relationship(deleteRule: .nullify, inverse: \Match.duties) var match: Match?
    
    init(type: DutyType, date: Date, notes: String = "") {
        self.id = UUID()
        self.type = type
        self.date = date
        self.notes = notes
    }
}

// MARK: - Player Management

@Model
final class Player {
    var id: UUID
    var name: String
    var handicap: Double
    var gamesPlayed: Int
    var goalsScored: Int
    var wins: Int
    var losses: Int
    var draws: Int
    var joinDate: Date
    var isActive: Bool
    
    // Relationships
    @Relationship(deleteRule: .nullify) var user: User?
    @Relationship(deleteRule: .nullify) var club: Club?
    @Relationship(deleteRule: .nullify) var teams: [Team] = []
    @Relationship(deleteRule: .cascade) var duties: [Duty] = []
    @Relationship(deleteRule: .cascade) var horses: [Horse] = []
    @Relationship(deleteRule: .cascade) var matchParticipations: [MatchParticipation] = []
    
    init(name: String, handicap: Double) {
        self.id = UUID()
        self.name = name
        self.handicap = handicap
        self.gamesPlayed = 0
        self.goalsScored = 0
        self.wins = 0
        self.losses = 0
        self.draws = 0
        self.joinDate = Date()
        self.isActive = true
    }
    
    var winPercentage: Double {
        guard gamesPlayed > 0 else { return 0.0 }
        return Double(wins) / Double(gamesPlayed) * 100
    }
}

// MARK: - Breeder Management

@Model
final class Breeder {
    var id: UUID
    var name: String
    var location: String
    var establishedDate: Date
    var isActive: Bool
    
    // Relationships
    @Relationship(deleteRule: .nullify) var user: User?
    @Relationship(deleteRule: .nullify, inverse: \Horse.breeder) var horses: [Horse] = []
    
    init(name: String, location: String, establishedDate: Date = Date()) {
        self.id = UUID()
        self.name = name
        self.location = location
        self.establishedDate = establishedDate
        self.isActive = true
    }
}

// MARK: - Horse Management

enum HorseGender: String, CaseIterable, Codable {
    case stallion = "Stallion"
    case mare = "Mare"
    case gelding = "Gelding"
}

enum HorseColor: String, CaseIterable, Codable {
    case bay = "Bay"
    case chestnut = "Chestnut"
    case black = "Black"
    case grey = "Grey"
    case brown = "Brown"
    case palomino = "Palomino"
    case pinto = "Pinto"
    case roan = "Roan"
}

@Model
final class Horse {
    var id: UUID
    var name: String
    var birthDate: Date
    var gender: HorseGender
    var color: HorseColor
    var pedigree: String
    var gamesPlayed: Int
    var tournamentsWon: Int
    var awards: [String]
    var isActive: Bool
    
    // Relationships
    @Relationship(deleteRule: .nullify) var breeder: Breeder?
    @Relationship(deleteRule: .nullify) var owner: Player?
    @Relationship(deleteRule: .cascade) var matchParticipations: [MatchParticipation] = []
    
    init(name: String, birthDate: Date, gender: HorseGender, color: HorseColor, pedigree: String = "") {
        self.id = UUID()
        self.name = name
        self.birthDate = birthDate
        self.gender = gender
        self.color = color
        self.pedigree = pedigree
        self.gamesPlayed = 0
        self.tournamentsWon = 0
        self.awards = []
        self.isActive = true
    }
    
    var age: Int {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year], from: birthDate, to: now)
        return components.year ?? 0
    }
}

// MARK: - Match and Statistics

enum MatchResult: String, CaseIterable, Codable {
    case win = "Win"
    case loss = "Loss"
    case draw = "Draw"
    case pending = "Pending"
}

@Model
final class Match {
    var id: UUID
    var date: Date
    var homeScore: Int
    var awayScore: Int
    var result: MatchResult
    var notes: String
    
    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \Team.homeMatches) var homeTeam: Team?
    @Relationship(deleteRule: .nullify, inverse: \Team.awayMatches) var awayTeam: Team?
    @Relationship(deleteRule: .nullify, inverse: \Tournament.matches) var tournament: Tournament?
    @Relationship(deleteRule: .nullify, inverse: \Field.matches) var field: Field?
    @Relationship(deleteRule: .cascade) var duties: [Duty] = []
    @Relationship(deleteRule: .cascade) var participations: [MatchParticipation] = []
    
    init(date: Date, homeTeam: Team, awayTeam: Team) {
        self.id = UUID()
        self.date = date
        self.homeScore = 0
        self.awayScore = 0
        self.result = .pending
        self.notes = ""
        self.homeTeam = homeTeam
        self.awayTeam = awayTeam
    }
}

@Model
final class MatchParticipation {
    var id: UUID
    var goalsScored: Int
    var fouls: Int
    var rating: Double
    
    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \Match.participations) var match: Match?
    @Relationship(deleteRule: .nullify, inverse: \Player.matchParticipations) var player: Player?
    @Relationship(deleteRule: .nullify, inverse: \Horse.matchParticipations) var horse: Horse?
    
    init(player: Player, horse: Horse? = nil) {
        self.id = UUID()
        self.goalsScored = 0
        self.fouls = 0
        self.rating = 0.0
        self.player = player
        self.horse = horse
    }
}