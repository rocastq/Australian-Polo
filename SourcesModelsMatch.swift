import Foundation
import SwiftData

@Model
class Match {
    @Attribute(.unique) var id: UUID
    var date: Date
    var startTime: Date
    var endTime: Date?
    var status: MatchStatus
    var createdDate: Date
    
    // Score tracking
    var teamAScore: Int
    var teamBScore: Int
    var currentChukker: Int
    var totalChukkers: Int
    
    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \Tournament.matches) var tournament: Tournament?
    @Relationship(deleteRule: .nullify, inverse: \Field.matches) var field: Field?
    @Relationship(deleteRule: .nullify, inverse: \Team.matchesAsTeamA) var teamA: Team?
    @Relationship(deleteRule: .nullify, inverse: \Team.matchesAsTeamB) var teamB: Team?
    @Relationship(deleteRule: .cascade, inverse: \PlayerStatistic.match) var playerStatistics: [PlayerStatistic]
    @Relationship(deleteRule: .cascade, inverse: \HorseStatistic.match) var horseStatistics: [HorseStatistic]
    @Relationship(deleteRule: .cascade, inverse: \ChukkerScore.match) var chukkerScores: [ChukkerScore]
    
    init(
        tournament: Tournament,
        field: Field,
        teamA: Team,
        teamB: Team,
        date: Date,
        startTime: Date,
        totalChukkers: Int = 6
    ) {
        self.id = UUID()
        self.tournament = tournament
        self.field = field
        self.teamA = teamA
        self.teamB = teamB
        self.date = date
        self.startTime = startTime
        self.totalChukkers = totalChukkers
        self.teamAScore = 0
        self.teamBScore = 0
        self.currentChukker = 0
        self.status = .scheduled
        self.createdDate = Date()
        self.playerStatistics = []
        self.horseStatistics = []
        self.chukkerScores = []
    }
    
    var winner: Team? {
        guard status == .completed else { return nil }
        if teamAScore > teamBScore {
            return teamA
        } else if teamBScore > teamAScore {
            return teamB
        }
        return nil // Tie
    }
    
    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
    
    var isLive: Bool {
        status == .inProgress
    }
}

@Model
class ChukkerScore {
    @Attribute(.unique) var id: UUID
    var chukkerNumber: Int
    var teamAScore: Int
    var teamBScore: Int
    var timestamp: Date
    
    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \Match.chukkerScores) var match: Match?
    
    init(
        match: Match,
        chukkerNumber: Int,
        teamAScore: Int,
        teamBScore: Int
    ) {
        self.id = UUID()
        self.match = match
        self.chukkerNumber = chukkerNumber
        self.teamAScore = teamAScore
        self.teamBScore = teamBScore
        self.timestamp = Date()
    }
}

enum MatchStatus: String, CaseIterable, Codable {
    case scheduled = "Scheduled"
    case inProgress = "In Progress"
    case completed = "Completed"
    case cancelled = "Cancelled"
    case postponed = "Postponed"
}