import Foundation
import SwiftData

@Model
class User {
    @Attribute(.unique) var id: UUID
    var email: String
    var firstName: String
    var lastName: String
    var phoneNumber: String?
    var profileType: ProfileType
    var isActive: Bool
    var createdDate: Date
    var lastLoginDate: Date?
    
    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \Player.user) var player: Player?
    @Relationship(deleteRule: .nullify, inverse: \Horse.breeder) var bredHorses: [Horse]
    
    init(
        email: String,
        firstName: String,
        lastName: String,
        phoneNumber: String? = nil,
        profileType: ProfileType,
        isActive: Bool = true
    ) {
        self.id = UUID()
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.phoneNumber = phoneNumber
        self.profileType = profileType
        self.isActive = isActive
        self.createdDate = Date()
        self.bredHorses = []
    }
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
}

enum ProfileType: String, CaseIterable, Codable {
    case administrator = "Administrator"
    case operator_ = "Operator"
    case player = "Player"
    case breeder = "Breeder"
    case user = "User"
    
    var displayName: String {
        switch self {
        case .operator_: return "Operator"
        default: return rawValue
        }
    }
}