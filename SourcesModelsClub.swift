import Foundation
import SwiftData

@Model
class Club {
    @Attribute(.unique) var id: UUID
    var name: String
    var location: String
    var contactEmail: String?
    var contactPhone: String?
    var isActive: Bool
    var createdDate: Date
    var website: String?
    
    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \Tournament.clubs) var tournaments: [Tournament]
    @Relationship(deleteRule: .nullify, inverse: \Team.club) var teams: [Team]
    @Relationship(deleteRule: .nullify, inverse: \Player.club) var players: [Player]
    
    init(
        name: String,
        location: String,
        contactEmail: String? = nil,
        contactPhone: String? = nil,
        website: String? = nil,
        isActive: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.location = location
        self.contactEmail = contactEmail
        self.contactPhone = contactPhone
        self.website = website
        self.isActive = isActive
        self.createdDate = Date()
        self.tournaments = []
        self.teams = []
        self.players = []
    }
}