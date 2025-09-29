//
//  Australian_PoloTests.swift
//  Australian PoloTests
//
//  Created by Rodrigo Castillo on 9/29/25.
//

import XCTest
import SwiftData
@testable import Australian_Polo

final class Australian_PoloTests: XCTestCase {
    
    func testUserCreation() throws {
        // Test user creation with different roles
        let adminUser = User(name: "Admin User", email: "admin@polo.com", role: .administrator)
        let playerUser = User(name: "Player User", email: "player@polo.com", role: .player)
        
        XCTAssertEqual(adminUser.name, "Admin User")
        XCTAssertEqual(adminUser.role, .administrator)
        XCTAssertTrue(adminUser.isActive)
        
        XCTAssertEqual(playerUser.role, .player)
        XCTAssertEqual(playerUser.email, "player@polo.com")
    }
    
    func testPlayerHandicap() throws {
        let player = Player(name: "Test Player", handicap: 6.5)
        
        XCTAssertEqual(player.handicap, 6.5)
        XCTAssertEqual(player.gamesPlayed, 0)
        XCTAssertEqual(player.winPercentage, 0.0)
        
        // Test win percentage calculation
        player.gamesPlayed = 10
        player.wins = 7
        
        XCTAssertEqual(player.winPercentage, 70.0)
    }
    
    func testTeamStatistics() throws {
        let team = Team(name: "Test Team", grade: .high)
        
        XCTAssertEqual(team.gamesPlayed, 0)
        XCTAssertEqual(team.goalDifference, 0)
        
        // Test after some games
        team.wins = 5
        team.losses = 3
        team.draws = 2
        team.goalsFor = 25
        team.goalsAgainst = 18
        
        XCTAssertEqual(team.gamesPlayed, 10)
        XCTAssertEqual(team.goalDifference, 7)
    }
    
    func testHorseAge() throws {
        let birthDate = Calendar.current.date(byAdding: .year, value: -5, to: Date())!
        let horse = Horse(name: "Test Horse", birthDate: birthDate, gender: .gelding, color: .bay)
        
        XCTAssertEqual(horse.age, 5)
        XCTAssertEqual(horse.name, "Test Horse")
        XCTAssertEqual(horse.gender, .gelding)
        XCTAssertEqual(horse.color, .bay)
    }
    
    func testTournament() throws {
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!
        
        let tournament = Tournament(name: "Test Tournament", grade: .medium, startDate: startDate, endDate: endDate, location: "Test Location")
        
        XCTAssertEqual(tournament.name, "Test Tournament")
        XCTAssertEqual(tournament.grade, .medium)
        XCTAssertEqual(tournament.location, "Test Location")
        XCTAssertTrue(tournament.isActive)
    }
    
    func testMatchResult() throws {
        let homeTeam = Team(name: "Home Team", grade: .medium)
        let awayTeam = Team(name: "Away Team", grade: .medium)
        let match = Match(date: Date(), homeTeam: homeTeam, awayTeam: awayTeam)
        
        XCTAssertEqual(match.result, .pending)
        XCTAssertEqual(match.homeScore, 0)
        XCTAssertEqual(match.awayScore, 0)
        
        // Test score update
        match.homeScore = 8
        match.awayScore = 6
        
        XCTAssertTrue(match.homeScore > match.awayScore)
    }
    
    func testDutyAssignment() throws {
        let player = Player(name: "Umpire Player", handicap: 4.0)
        let duty = Duty(type: .umpire, date: Date())
        duty.player = player
        
        XCTAssertEqual(duty.type, .umpire)
        XCTAssertEqual(duty.player?.name, "Umpire Player")
    }
    
    func testClubTeamRelationship() throws {
        let club = Club(name: "Test Club", location: "Test City")
        let team = Team(name: "Club Team", grade: .low)
        
        team.club = club
        
        XCTAssertEqual(team.club?.name, "Test Club")
        XCTAssertEqual(club.name, "Test Club")
        XCTAssertEqual(club.location, "Test City")
        XCTAssertTrue(club.isActive)
    }
    
    func testBreederHorseRelationship() throws {
        let breeder = Breeder(name: "Test Breeder", location: "Farm Location")
        let horse = Horse(name: "Bred Horse", birthDate: Date(), gender: .mare, color: .chestnut)
        
        horse.breeder = breeder
        
        XCTAssertEqual(horse.breeder?.name, "Test Breeder")
        XCTAssertEqual(breeder.location, "Farm Location")
    }
    
    func testFieldMatchAssociation() throws {
        let field = Field(name: "Polo Field 1", location: "Field Location", grade: .high)
        let homeTeam = Team(name: "Team A", grade: .high)
        let awayTeam = Team(name: "Team B", grade: .high)
        let match = Match(date: Date(), homeTeam: homeTeam, awayTeam: awayTeam)
        
        match.field = field
        
        XCTAssertEqual(match.field?.name, "Polo Field 1")
        XCTAssertEqual(field.grade, .high)
    }
    
    func testUserRoles() throws {
        let roles = UserRole.allCases
        
        XCTAssertTrue(roles.contains(.administrator))
        XCTAssertTrue(roles.contains(.clubOperator))
        XCTAssertTrue(roles.contains(.player))
        XCTAssertTrue(roles.contains(.breeder))
        XCTAssertTrue(roles.contains(.user))
        XCTAssertEqual(roles.count, 5)
    }
    
    func testMatchScoreCalculation() throws {
        let homeTeam = Team(name: "Home Team", grade: .medium)
        let awayTeam = Team(name: "Away Team", grade: .medium)
        let match = Match(date: Date(), homeTeam: homeTeam, awayTeam: awayTeam)
        
        // Test initial state
        XCTAssertEqual(homeTeam.wins, 0)
        XCTAssertEqual(awayTeam.wins, 0)
        XCTAssertEqual(homeTeam.goalsFor, 0)
        XCTAssertEqual(awayTeam.goalsFor, 0)
        
        // Simulate match completion
        match.homeScore = 10
        match.awayScore = 8
        match.result = .win
        
        XCTAssertEqual(match.homeScore, 10)
        XCTAssertEqual(match.awayScore, 8)
        XCTAssertEqual(match.result, .win)
    }
    
    func testHorseAwards() throws {
        let horse = Horse(name: "Champion Horse", birthDate: Date(), gender: .stallion, color: .black)
        
        XCTAssertTrue(horse.awards.isEmpty)
        
        // Add awards
        horse.awards = ["Best Polo Pony 2024", "Tournament MVP"]
        
        XCTAssertEqual(horse.awards.count, 2)
        XCTAssertTrue(horse.awards.contains("Best Polo Pony 2024"))
        XCTAssertTrue(horse.awards.contains("Tournament MVP"))
    }
    
    func testClubPlayerRelationship() throws {
        let club = Club(name: "Sydney Polo Club", location: "Sydney")
        let player1 = Player(name: "Player One", handicap: 5.0)
        let player2 = Player(name: "Player Two", handicap: 7.0)
        
        player1.club = club
        player2.club = club
        
        XCTAssertEqual(player1.club?.name, "Sydney Polo Club")
        XCTAssertEqual(player2.club?.name, "Sydney Polo Club")
    }
}
