//
//  PoloAppTests.swift
//  Australian Polo Tests
//
//  Created by Rodrigo Castillo on 9/29/25.
//

import Testing
import SwiftUI
import SwiftData

@Suite("Australian Polo App Tests")
struct PoloAppTests {
    
    @Test("User Creation")
    func testUserCreation() throws {
        // Test user creation with different roles
        let adminUser = User(name: "Admin User", email: "admin@polo.com", role: .administrator)
        let playerUser = User(name: "Player User", email: "player@polo.com", role: .player)
        
        #expect(adminUser.name == "Admin User")
        #expect(adminUser.role == .administrator)
        #expect(adminUser.isActive == true)
        
        #expect(playerUser.role == .player)
        #expect(playerUser.email == "player@polo.com")
    }
    
    @Test("Player Handicap")
    func testPlayerHandicap() throws {
        let player = Player(name: "Test Player", handicap: 6.5)
        
        #expect(player.handicap == 6.5)
        #expect(player.gamesPlayed == 0)
        #expect(player.winPercentage == 0.0)
        
        // Test win percentage calculation
        player.gamesPlayed = 10
        player.wins = 7
        
        #expect(player.winPercentage == 70.0)
    }
    
    @Test("Team Statistics")
    func testTeamStatistics() throws {
        let team = Team(name: "Test Team", grade: .high)
        
        #expect(team.gamesPlayed == 0)
        #expect(team.goalDifference == 0)
        
        // Test after some games
        team.wins = 5
        team.losses = 3
        team.draws = 2
        team.goalsFor = 25
        team.goalsAgainst = 18
        
        #expect(team.gamesPlayed == 10)
        #expect(team.goalDifference == 7)
    }
    
    @Test("Horse Age")
    func testHorseAge() throws {
        let birthDate = Calendar.current.date(byAdding: .year, value: -5, to: Date())!
        let horse = Horse(name: "Test Horse", birthDate: birthDate, gender: .gelding, color: .bay)
        
        #expect(horse.age == 5)
        #expect(horse.name == "Test Horse")
        #expect(horse.gender == .gelding)
        #expect(horse.color == .bay)
    }
    
    @Test("Tournament")
    func testTournament() throws {
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!
        
        let tournament = Tournament(name: "Test Tournament", grade: .medium, startDate: startDate, endDate: endDate, location: "Test Location")
        
        #expect(tournament.name == "Test Tournament")
        #expect(tournament.grade == .medium)
        #expect(tournament.location == "Test Location")
        #expect(tournament.isActive == true)
    }
    
    @Test("Match Result")
    func testMatchResult() throws {
        let homeTeam = Team(name: "Home Team", grade: .medium)
        let awayTeam = Team(name: "Away Team", grade: .medium)
        let match = Match(date: Date(), homeTeam: homeTeam, awayTeam: awayTeam)
        
        #expect(match.result == .pending)
        #expect(match.homeScore == 0)
        #expect(match.awayScore == 0)
        
        // Test score update
        match.homeScore = 8
        match.awayScore = 6
        
        #expect(match.homeScore > match.awayScore)
    }
    
    @Test("Duty Assignment")
    func testDutyAssignment() throws {
        let player = Player(name: "Umpire Player", handicap: 4.0)
        let duty = Duty(type: .umpire, date: Date())
        duty.player = player
        
        #expect(duty.type == .umpire)
        #expect(duty.player?.name == "Umpire Player")
    }
    
    @Test("Club Team Relationship")
    func testClubTeamRelationship() throws {
        let club = Club(name: "Test Club", location: "Test City")
        let team = Team(name: "Club Team", grade: .low)
        
        team.club = club
        
        #expect(team.club?.name == "Test Club")
        #expect(club.name == "Test Club")
        #expect(club.location == "Test City")
        #expect(club.isActive == true)
    }
    
    @Test("Breeder Horse Relationship")
    func testBreederHorseRelationship() throws {
        let breeder = Breeder(name: "Test Breeder", location: "Farm Location")
        let horse = Horse(name: "Bred Horse", birthDate: Date(), gender: .mare, color: .chestnut)
        
        horse.breeder = breeder
        
        #expect(horse.breeder?.name == "Test Breeder")
        #expect(breeder.location == "Farm Location")
    }
    
    @Test("Field Match Association")
    func testFieldMatchAssociation() throws {
        let field = Field(name: "Polo Field 1", location: "Field Location", grade: .high)
        let homeTeam = Team(name: "Team A", grade: .high)
        let awayTeam = Team(name: "Team B", grade: .high)
        let match = Match(date: Date(), homeTeam: homeTeam, awayTeam: awayTeam)
        
        match.field = field
        
        #expect(match.field?.name == "Polo Field 1")
        #expect(field.grade == .high)
    }
    
    @Test("User Roles")
    func testUserRoles() throws {
        let roles = UserRole.allCases
        
        #expect(roles.contains(.administrator))
        #expect(roles.contains(.clubOperator))
        #expect(roles.contains(.player))
        #expect(roles.contains(.breeder))
        #expect(roles.contains(.user))
        #expect(roles.count == 5)
    }
    
    @Test("Match Score Calculation")
    func testMatchScoreCalculation() throws {
        let homeTeam = Team(name: "Home Team", grade: .medium)
        let awayTeam = Team(name: "Away Team", grade: .medium)
        let match = Match(date: Date(), homeTeam: homeTeam, awayTeam: awayTeam)
        
        // Test initial state
        #expect(homeTeam.wins == 0)
        #expect(awayTeam.wins == 0)
        #expect(homeTeam.goalsFor == 0)
        #expect(awayTeam.goalsFor == 0)
        
        // Simulate match completion
        match.homeScore = 10
        match.awayScore = 8
        match.result = .win
        
        #expect(match.homeScore == 10)
        #expect(match.awayScore == 8)
        #expect(match.result == .win)
    }
    
    @Test("Horse Awards")
    func testHorseAwards() throws {
        let horse = Horse(name: "Champion Horse", birthDate: Date(), gender: .stallion, color: .black)
        
        #expect(horse.awards.isEmpty)
        
        // Add awards
        horse.awards = ["Best Polo Pony 2024", "Tournament MVP"]
        
        #expect(horse.awards.count == 2)
        #expect(horse.awards.contains("Best Polo Pony 2024"))
        #expect(horse.awards.contains("Tournament MVP"))
    }
    
    @Test("Club Player Relationship")
    func testClubPlayerRelationship() throws {
        let club = Club(name: "Sydney Polo Club", location: "Sydney")
        let player1 = Player(name: "Player One", handicap: 5.0)
        let player2 = Player(name: "Player Two", handicap: 7.0)
        
        player1.club = club
        player2.club = club
        
        #expect(player1.club?.name == "Sydney Polo Club")
        #expect(player2.club?.name == "Sydney Polo Club")
    }
    
    @Test("Tournament Grades")
    func testTournamentGrades() throws {
        let grades = TournamentGrade.allCases
        
        #expect(grades.contains(.high))
        #expect(grades.contains(.medium))
        #expect(grades.contains(.low))
        #expect(grades.count == 3)
    }
    
    @Test("Horse Gender and Color")
    func testHorseGenderAndColor() throws {
        let genders = HorseGender.allCases
        let colors = HorseColor.allCases
        
        #expect(genders.contains(.stallion))
        #expect(genders.contains(.mare))
        #expect(genders.contains(.gelding))
        #expect(genders.count == 3)
        
        #expect(colors.contains(.bay))
        #expect(colors.contains(.chestnut))
        #expect(colors.contains(.black))
        #expect(colors.contains(.grey))
        #expect(colors.count == 8)
    }
    
    @Test("Duty Types")
    func testDutyTypes() throws {
        let dutyTypes = DutyType.allCases
        
        #expect(dutyTypes.contains(.umpire))
        #expect(dutyTypes.contains(.centreTable))
        #expect(dutyTypes.contains(.goalUmpire))
        #expect(dutyTypes.count == 3)
    }
}
