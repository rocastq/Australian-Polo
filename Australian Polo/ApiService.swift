import Foundation

// MARK: - DTOs / Models for API

struct TournamentDTO: Codable, Identifiable {
    let id: Int
    let name: String
    let location: String?
    let start_date: String?
    let end_date: String?
}

struct TeamDTO: Codable, Identifiable {
    let id: Int
    let name: String
    let coach: String?
}

struct PlayerDTO: Codable, Identifiable {
    let id: Int
    let name: String
    let team_id: Int?
    let position: String?
}

struct HorseDTO: Codable, Identifiable {
    let id: Int
    let name: String
    let pedigree: [String: String]?
    let breeder_id: Int?
}

struct BreederDTO: Codable, Identifiable {
    let id: Int
    let name: String
    let contact_info: String?
}

struct AwardDTO: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String?
    let entity_type: String?
    let entity_id: Int?
}

struct MatchDTO: Codable, Identifiable {
    let id: Int
    let tournament_id: Int
    let team1_id: Int
    let team2_id: Int
    let scheduled_time: String?
    let result: String?
}

// MARK: - Request Bodies

// Use separate request structs for safety and type correctness
struct CreateOrUpdateTournamentRequest: Codable {
    let name: String
    let location: String?
    let start_date: String?
    let end_date: String?
}

struct CreateOrUpdateTeamRequest: Codable {
    let name: String
    let coach: String?
}

struct CreateOrUpdatePlayerRequest: Codable {
    let name: String
    let team_id: Int?
    let position: String?
}

struct CreateOrUpdateHorseRequest: Codable {
    let name: String
    let pedigree: [String: String]?
    let breeder_id: Int?
}

struct CreateOrUpdateBreederRequest: Codable {
    let name: String
    let contact_info: String?
}

struct CreateOrUpdateAwardRequest: Codable {
    let title: String
    let description: String?
    let entity_type: String?
    let entity_id: Int?
}

struct CreateOrUpdateMatchRequest: Codable {
    let tournament_id: Int
    let team1_id: Int
    let team2_id: Int
    let scheduled_time: String
    let result: String?
}

// MARK: - API Service

class ApiService {
    static let shared = ApiService()
    private init() {}

   //Add Url of local Backend
    let baseUrl = "http://13.236.118.154:3000/api"

    private func makeURL(_ path: String) -> URL? {
        return URL(string: baseUrl + path)
    }

    private func request<T: Codable>(
        _ url: URL,
        method: String = "GET",
        body: Data? = nil
    ) async throws -> (T, HTTPURLResponse) {
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let decoded = try decoder.decode(T.self, from: data)
            return (decoded, http)
        } catch {
            print("Decoding Error for \(T.self):", error)
            if let raw = String(data: data, encoding: .utf8) {
                print("Raw JSON:", raw)
            }
            throw error
        }
    }

    private func requestNoResponse(
        _ url: URL,
        method: String = "DELETE"
    ) async throws -> HTTPURLResponse {
        var req = URLRequest(url: url)
        req.httpMethod = method
        let (_, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        return http
    }

    // MARK: - Tournament APIs
    func getAllTournaments() async throws -> [TournamentDTO] {
        guard let url = makeURL("/tournaments") else { throw URLError(.badURL) }
        let (dtos, _): ([TournamentDTO], HTTPURLResponse) = try await request(url)
        return dtos
    }

    func getTournament(id: Int) async throws -> TournamentDTO {
        guard let url = makeURL("/tournaments/\(id)") else { throw URLError(.badURL) }
        let (dto, _): (TournamentDTO, HTTPURLResponse) = try await request(url)
        return dto
    }

    func createTournament(
        name: String,
        location: String?,
        startDate: String?,
        endDate: String?
    ) async throws -> TournamentDTO {
        guard let url = makeURL("/tournaments") else { throw URLError(.badURL) }
        let requestBody = CreateOrUpdateTournamentRequest(name: name, location: location, start_date: startDate, end_date: endDate)
        let bodyData = try JSONEncoder().encode(requestBody)
        let (dto, _): (TournamentDTO, HTTPURLResponse) = try await request(url, method: "POST", body: bodyData)
        return dto
    }

    func updateTournament(
        id: Int,
        name: String,
        location: String?,
        startDate: String?,
        endDate: String?
    ) async throws -> TournamentDTO {
        guard let url = makeURL("/tournaments/\(id)") else { throw URLError(.badURL) }
        let requestBody = CreateOrUpdateTournamentRequest(name: name, location: location, start_date: startDate, end_date: endDate)
        let bodyData = try JSONEncoder().encode(requestBody)
        let (dto, _): (TournamentDTO, HTTPURLResponse) = try await request(url, method: "PUT", body: bodyData)
        return dto
    }

    func deleteTournament(id: Int) async throws {
        guard let url = makeURL("/tournaments/\(id)") else { throw URLError(.badURL) }
        _ = try await requestNoResponse(url)
    }

    // MARK: - Team APIs
    func getAllTeams() async throws -> [TeamDTO] {
        guard let url = makeURL("/teams") else { throw URLError(.badURL) }
        let (dtos, _): ([TeamDTO], HTTPURLResponse) = try await request(url)
        return dtos
    }

    func createTeam(name: String, coach: String?) async throws -> TeamDTO {
        guard let url = makeURL("/teams") else { throw URLError(.badURL) }
        let bodyObj = CreateOrUpdateTeamRequest(name: name, coach: coach)
        let bodyData = try JSONEncoder().encode(bodyObj)
        let (dto, _): (TeamDTO, HTTPURLResponse) = try await request(url, method: "POST", body: bodyData)
        return dto
    }

    func updateTeam(id: Int, name: String, coach: String?) async throws -> TeamDTO {
        guard let url = makeURL("/teams/\(id)") else { throw URLError(.badURL) }
        let bodyObj = CreateOrUpdateTeamRequest(name: name, coach: coach)
        let bodyData = try JSONEncoder().encode(bodyObj)
        let (dto, _): (TeamDTO, HTTPURLResponse) = try await request(url, method: "PUT", body: bodyData)
        return dto
    }

    func deleteTeam(id: Int) async throws {
        guard let url = makeURL("/teams/\(id)") else { throw URLError(.badURL) }
        _ = try await requestNoResponse(url)
    }

    // MARK: - Player APIs
    func getAllPlayers() async throws -> [PlayerDTO] {
        guard let url = makeURL("/players") else { throw URLError(.badURL) }
        let (dtos, _): ([PlayerDTO], HTTPURLResponse) = try await request(url)
        return dtos
    }

    func createPlayer(name: String, teamId: Int?, position: String?) async throws -> PlayerDTO {
        guard let url = makeURL("/players") else { throw URLError(.badURL) }
        let bodyObj = CreateOrUpdatePlayerRequest(name: name, team_id: teamId, position: position)
        let bodyData = try JSONEncoder().encode(bodyObj)
        let (dto, _): (PlayerDTO, HTTPURLResponse) = try await request(url, method: "POST", body: bodyData)
        return dto
    }

    func updatePlayer(id: Int, name: String, teamId: Int?, position: String?) async throws -> PlayerDTO {
        guard let url = makeURL("/players/\(id)") else { throw URLError(.badURL) }
        let bodyObj = CreateOrUpdatePlayerRequest(name: name, team_id: teamId, position: position)
        let bodyData = try JSONEncoder().encode(bodyObj)
        let (dto, _): (PlayerDTO, HTTPURLResponse) = try await request(url, method: "PUT", body: bodyData)
        return dto
    }

    func deletePlayer(id: Int) async throws {
        guard let url = makeURL("/players/\(id)") else { throw URLError(.badURL) }
        _ = try await requestNoResponse(url)
    }

    // MARK: - Horse APIs
    func getAllHorses() async throws -> [HorseDTO] {
        guard let url = makeURL("/horses") else { throw URLError(.badURL) }
        let (dtos, _): ([HorseDTO], HTTPURLResponse) = try await request(url)
        return dtos
    }

    func createHorse(name: String, pedigree: [String: String]?, breederId: Int?) async throws -> HorseDTO {
        guard let url = makeURL("/horses") else { throw URLError(.badURL) }
        let bodyObj = CreateOrUpdateHorseRequest(name: name, pedigree: pedigree, breeder_id: breederId)
        let bodyData = try JSONEncoder().encode(bodyObj)
        let (dto, _): (HorseDTO, HTTPURLResponse) = try await request(url, method: "POST", body: bodyData)
        return dto
    }

    func updateHorse(id: Int, name: String, pedigree: [String: String]?, breederId: Int?) async throws -> HorseDTO {
        guard let url = makeURL("/horses/\(id)") else { throw URLError(.badURL) }
        let bodyObj = CreateOrUpdateHorseRequest(name: name, pedigree: pedigree, breeder_id: breederId)
        let bodyData = try JSONEncoder().encode(bodyObj)
        let (dto, _): (HorseDTO, HTTPURLResponse) = try await request(url, method: "PUT", body: bodyData)
        return dto
    }

    func deleteHorse(id: Int) async throws {
        guard let url = makeURL("/horses/\(id)") else { throw URLError(.badURL) }
        _ = try await requestNoResponse(url)
    }

    // MARK: - Breeder APIs
    func getAllBreeders() async throws -> [BreederDTO] {
        guard let url = makeURL("/breeders") else { throw URLError(.badURL) }
        let (dtos, _): ([BreederDTO], HTTPURLResponse) = try await request(url)
        return dtos
    }

    func createBreeder(name: String, contactInfo: String?) async throws -> BreederDTO {
        guard let url = makeURL("/breeders") else { throw URLError(.badURL) }
        let bodyObj = CreateOrUpdateBreederRequest(name: name, contact_info: contactInfo)
        let bodyData = try JSONEncoder().encode(bodyObj)
        let (dto, _): (BreederDTO, HTTPURLResponse) = try await request(url, method: "POST", body: bodyData)
        return dto
    }

    func updateBreeder(id: Int, name: String, contactInfo: String?) async throws -> BreederDTO {
        guard let url = makeURL("/breeders/\(id)") else { throw URLError(.badURL) }
        let bodyObj = CreateOrUpdateBreederRequest(name: name, contact_info: contactInfo)
        let bodyData = try JSONEncoder().encode(bodyObj)
        let (dto, _): (BreederDTO, HTTPURLResponse) = try await request(url, method: "PUT", body: bodyData)
        return dto
    }

    func deleteBreeder(id: Int) async throws {
        guard let url = makeURL("/breeders/\(id)") else { throw URLError(.badURL) }
        _ = try await requestNoResponse(url)
    }

    // MARK: - Award APIs
    func getAllAwards() async throws -> [AwardDTO] {
        guard let url = makeURL("/awards") else { throw URLError(.badURL) }
        let (dtos, _): ([AwardDTO], HTTPURLResponse) = try await request(url)
        return dtos
    }

    func createAward(title: String, description: String?, entityType: String?, entityId: Int?) async throws -> AwardDTO {
        guard let url = makeURL("/awards") else { throw URLError(.badURL) }
        let bodyObj = CreateOrUpdateAwardRequest(title: title, description: description, entity_type: entityType, entity_id: entityId)
        let bodyData = try JSONEncoder().encode(bodyObj)
        let (dto, _): (AwardDTO, HTTPURLResponse) = try await request(url, method: "POST", body: bodyData)
        return dto
    }

    func updateAward(id: Int, title: String, description: String?, entityType: String?, entityId: Int?) async throws -> AwardDTO {
        guard let url = makeURL("/awards/\(id)") else { throw URLError(.badURL) }
        let bodyObj = CreateOrUpdateAwardRequest(title: title, description: description, entity_type: entityType, entity_id: entityId)
        let bodyData = try JSONEncoder().encode(bodyObj)
        let (dto, _): (AwardDTO, HTTPURLResponse) = try await request(url, method: "PUT", body: bodyData)
        return dto
    }

    func deleteAward(id: Int) async throws {
        guard let url = makeURL("/awards/\(id)") else { throw URLError(.badURL) }
        _ = try await requestNoResponse(url)
    }

    // MARK: - Match APIs
    func getMatchesByTournament(tournamentId: Int) async throws -> [MatchDTO] {
        guard let url = makeURL("/matches/tournament/\(tournamentId)") else { throw URLError(.badURL) }
        let (dtos, _): ([MatchDTO], HTTPURLResponse) = try await request(url)
        return dtos
    }

    func getMatch(id: Int) async throws -> MatchDTO {
        guard let url = makeURL("/matches/\(id)") else { throw URLError(.badURL) }
        let (dto, _): (MatchDTO, HTTPURLResponse) = try await request(url)
        return dto
    }

    func createMatch(tournamentId: Int, team1Id: Int, team2Id: Int, scheduledTime: String) async throws -> MatchDTO {
        guard let url = makeURL("/matches") else { throw URLError(.badURL) }
        let bodyObj = CreateOrUpdateMatchRequest(tournament_id: tournamentId, team1_id: team1Id, team2_id: team2Id, scheduled_time: scheduledTime, result: nil)
        let bodyData = try JSONEncoder().encode(bodyObj)
        let (dto, _): (MatchDTO, HTTPURLResponse) = try await request(url, method: "POST", body: bodyData)
        return dto
    }

    func updateMatch(id: Int, team1Id: Int, team2Id: Int, scheduledTime: String, result: String?) async throws -> MatchDTO {
        guard let url = makeURL("/matches/\(id)") else { throw URLError(.badURL) }
        let bodyObj = CreateOrUpdateMatchRequest(tournament_id: 0, team1_id: team1Id, team2_id: team2Id, scheduled_time: scheduledTime, result: result)
        // tournament_id isn’t really needed for updating; backend might ignore
        let bodyData = try JSONEncoder().encode(bodyObj)
        let (dto, _): (MatchDTO, HTTPURLResponse) = try await request(url, method: "PUT", body: bodyData)
        return dto
    }

    func deleteMatch(id: Int) async throws {
        guard let url = makeURL("/matches/\(id)") else { throw URLError(.badURL) }
        _ = try await requestNoResponse(url)
    }
}
