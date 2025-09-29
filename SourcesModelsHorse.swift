import Foundation
import SwiftData

@Model
class Horse {
    @Attribute(.unique) var id: UUID
    var name: String
    var birthDate: Date
    var gender: HorseGender
    var color: HorseColor
    var isActive: Bool
    var createdDate: Date
    var registrationNumber: String?
    var notes: String?
    
    // Pedigree
    var sire: String?
    var dam: String?
    
    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \User.bredHorses) var breeder: User?
    @Relationship(deleteRule: .cascade, inverse: \HorseStatistic.horse) var statistics: [HorseStatistic]
    @Relationship(deleteRule: .nullify, inverse: \Award.horse) var awards: [Award]
    
    init(
        name: String,
        birthDate: Date,
        gender: HorseGender,
        color: HorseColor,
        breeder: User? = nil,
        sire: String? = nil,
        dam: String? = nil,
        registrationNumber: String? = nil,
        notes: String? = nil,
        isActive: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.birthDate = birthDate
        self.gender = gender
        self.color = color
        self.breeder = breeder
        self.sire = sire
        self.dam = dam
        self.registrationNumber = registrationNumber
        self.notes = notes
        self.isActive = isActive
        self.createdDate = Date()
        self.statistics = []
        self.awards = []
    }
    
    var age: Int {
        Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
    }
    
    var totalGames: Int {
        statistics.count
    }
    
    var totalTournaments: Int {
        Set(statistics.compactMap { $0.match?.tournament }).count
    }
}

@Model
class HorseStatistic {
    @Attribute(.unique) var id: UUID
    var matchDate: Date
    var performance: HorsePerformance
    var injuries: String?
    var notes: String?
    
    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \Horse.statistics) var horse: Horse?
    @Relationship(deleteRule: .nullify, inverse: \Match.horseStatistics) var match: Match?
    
    init(
        horse: Horse,
        match: Match,
        performance: HorsePerformance = .good,
        injuries: String? = nil,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.horse = horse
        self.match = match
        self.performance = performance
        self.injuries = injuries
        self.notes = notes
        self.matchDate = match.date
    }
}

enum HorseGender: String, CaseIterable, Codable {
    case stallion = "Stallion"
    case mare = "Mare"
    case gelding = "Gelding"
    case colt = "Colt"
    case filly = "Filly"
}

enum HorseColor: String, CaseIterable, Codable {
    case bay = "Bay"
    case chestnut = "Chestnut"
    case black = "Black"
    case gray = "Gray"
    case brown = "Brown"
    case palomino = "Palomino"
    case pinto = "Pinto"
    case roan = "Roan"
    case other = "Other"
}

enum HorsePerformance: String, CaseIterable, Codable {
    case excellent = "Excellent"
    case good = "Good"
    case average = "Average"
    case poor = "Poor"
    case injured = "Injured"
}