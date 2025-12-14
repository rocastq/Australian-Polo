import Foundation

// Shared ISO8601 formatters for API payloads
private let apiISODateFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.formatOptions = [.withFullDate]
    return formatter
}()

private let apiISODateTimeFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
}()

extension Date {
    func apiISODateString() -> String {
        apiISODateFormatter.string(from: self)
    }

    func apiISODateTimeString() -> String {
        apiISODateTimeFormatter.string(from: self)
    }

    static func apiDate(from string: String) -> Date? {
        if let isoWithTime = apiISODateTimeFormatter.date(from: string) {
            return isoWithTime
        }
        if let isoDateOnly = apiISODateFormatter.date(from: string) {
            return isoDateOnly
        }

        // Fallbacks for legacy MySQL-style formats
        let dateTime = DateFormatter()
        dateTime.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateTime.timeZone = TimeZone(identifier: "UTC")
        if let parsed = dateTime.date(from: string) {
            return parsed
        }

        let dateOnly = DateFormatter()
        dateOnly.dateFormat = "yyyy-MM-dd"
        dateOnly.timeZone = TimeZone(identifier: "UTC")
        return dateOnly.date(from: string)
    }
}

// MARK: - DTOs / Models for API

struct TournamentDTO: Codable, Identifiable {
    let id: Int
    let name: String
    let location: String?
    let startDate: String?
    let endDate: String?
}

struct TeamDTO: Codable, Identifiable {
    let id: Int
    let name: String
    let coach: String?
    let clubId: Int?
    let createdAt: String?
    let updatedAt: String?
}

struct PlayerDTO: Codable, Identifiable {
    let id: Int
    let firstName: String
    let surname: String
    let state: String?
    let handicapJun2025: Double?
    let womensHandicapJun2025: Double?
    let handicapDec2026: Double?
    let womensHandicapDec2026: Double?
    let teamId: Int?
    let position: String?
    let clubId: Int?
    let createdAt: String?
    let updatedAt: String?

    // Convenience computed property for display name
    var displayName: String {
        "\(firstName) \(surname)"
    }
}

struct HorseDTO: Codable, Identifiable {
    let id: Int
    let name: String
    let pedigree: [String: String]?
    let breederId: Int?
    let owner: String?
    let tamer: String?
    let createdAt: String?
    let updatedAt: String?
}

struct BreederDTO: Codable, Identifiable {
    let id: Int
    let name: String
    let contactInfo: String?
    let createdAt: String?
    let updatedAt: String?
}

struct AwardDTO: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String?
    let entityType: String?
    let entityId: Int?
}

struct MatchDTO: Codable, Identifiable {
    let id: Int
    let tournamentId: Int
    let team1Id: Int
    let team2Id: Int
    let scheduledTime: String?
    let result: String?
}

struct ClubDTO: Codable, Identifiable {
    let id: Int
    let name: String
    let location: String?
    let foundedDate: String?
    let isActive: Int?
    let createdAt: String?
    let updatedAt: String?
}

struct FieldDTO: Codable, Identifiable {
    let id: Int
    let name: String
    let location: String?
    let grade: String?
    let isActive: Int?
    let createdAt: String?
    let updatedAt: String?
}

struct DutyDTO: Codable, Identifiable {
    let id: Int
    let type: String
    let date: String?
    let notes: String?
    let playerId: Int?
    let matchId: Int?
    let playerName: String?
    let matchTime: String?
    let createdAt: String?
    let updatedAt: String?
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
    let first_name: String
    let surname: String
    let state: String?
    let handicap_jun_2025: Double?
    let womens_handicap_jun_2025: Double?
    let handicap_dec_2026: Double?
    let womens_handicap_dec_2026: Double?
    let team_id: Int?
    let position: String?
    let club_id: Int?
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

struct CreateOrUpdateClubRequest: Codable {
    let name: String
    let location: String?
    let founded_date: String?
}

struct CreateOrUpdateFieldRequest: Codable {
    let name: String
    let location: String?
    let grade: String?
}

struct CreateOrUpdateDutyRequest: Codable {
    let type: String
    let date: String?
    let notes: String?
    let player_id: Int?
    let match_id: Int?
}

// MARK: - API Error (using shared enum from AuthenticationService)

struct ErrorResponse: Codable {
    let status: String?
    let message: String
    let error: ErrorDetail?

    struct ErrorDetail: Codable {
        let statusCode: Int?
        let isOperational: Bool?
        let status: String?
    }
}

// MARK: - Paginated Response

struct PaginatedResponse<T: Codable>: Codable {
    let data: [T]
    let pagination: Pagination?

    struct Pagination: Codable {
        let page: Int
        let limit: Int
        let total: Int
        let totalPages: Int
    }
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

        print("📤 API Request: \(method) \(url.absoluteString)")
        if let bodyData = body, let bodyString = String(data: bodyData, encoding: .utf8) {
            print("📦 Request Body: \(bodyString)")
        }

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        print("📥 API Response Status: \(http.statusCode)")
        if let raw = String(data: data, encoding: .utf8) {
            print("📄 Response Data: \(raw)")
        }

        guard (200...299).contains(http.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ API Error (\(http.statusCode)): \(errorMessage)")

            // Try to parse backend error response
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.message)
            }

            // Fallback to generic error
            throw APIError.serverError("Server returned status code \(http.statusCode)")
        }

        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let decoded = try decoder.decode(T.self, from: data)
            print("✅ Successfully decoded \(T.self)")
            return (decoded, http)
        } catch {
            print("❌ Decoding Error for \(T.self):", error)
            if let raw = String(data: data, encoding: .utf8) {
                print("📄 Raw JSON that failed to decode:", raw)
            }
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("❌ Key '\(key.stringValue)' not found:", context.debugDescription)
                case .typeMismatch(let type, let context):
                    print("❌ Type mismatch for type '\(type)':", context.debugDescription)
                case .valueNotFound(let type, let context):
                    print("❌ Value not found for type '\(type)':", context.debugDescription)
                case .dataCorrupted(let context):
                    print("❌ Data corrupted:", context.debugDescription)
                @unknown default:
                    print("❌ Unknown decoding error")
                }
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
        guard let url = makeURL("/tournaments?limit=1000") else { throw URLError(.badURL) }
        let (response, _): (PaginatedResponse<TournamentDTO>, HTTPURLResponse) = try await request(url)
        return response.data
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
        guard let url = makeURL("/teams?limit=1000") else { throw URLError(.badURL) }
        let (response, _): (PaginatedResponse<TeamDTO>, HTTPURLResponse) = try await request(url)
        return response.data
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
        guard let url = makeURL("/players?limit=1000") else { throw URLError(.badURL) }
        let (response, _): (PaginatedResponse<PlayerDTO>, HTTPURLResponse) = try await request(url)
        print("📊 Players API returned \(response.data.count) players (total: \(response.pagination?.total ?? 0))")
        return response.data
    }

    func createPlayer(
        firstName: String,
        surname: String,
        state: String?,
        handicapJun2025: Double?,
        womensHandicapJun2025: Double?,
        handicapDec2026: Double?,
        womensHandicapDec2026: Double?,
        teamId: Int?,
        position: String?,
        clubId: Int?
    ) async throws -> PlayerDTO {
        guard let url = makeURL("/players") else { throw URLError(.badURL) }
        let bodyObj = CreateOrUpdatePlayerRequest(
            first_name: firstName,
            surname: surname,
            state: state,
            handicap_jun_2025: handicapJun2025,
            womens_handicap_jun_2025: womensHandicapJun2025,
            handicap_dec_2026: handicapDec2026,
            womens_handicap_dec_2026: womensHandicapDec2026,
            team_id: teamId,
            position: position,
            club_id: clubId
        )
        let bodyData = try JSONEncoder().encode(bodyObj)
        let (dto, _): (PlayerDTO, HTTPURLResponse) = try await request(url, method: "POST", body: bodyData)
        return dto
    }

    func updatePlayer(
        id: Int,
        firstName: String,
        surname: String,
        state: String?,
        handicapJun2025: Double?,
        womensHandicapJun2025: Double?,
        handicapDec2026: Double?,
        womensHandicapDec2026: Double?,
        teamId: Int?,
        position: String?,
        clubId: Int?
    ) async throws -> PlayerDTO {
        guard let url = makeURL("/players/\(id)") else { throw URLError(.badURL) }
        let bodyObj = CreateOrUpdatePlayerRequest(
            first_name: firstName,
            surname: surname,
            state: state,
            handicap_jun_2025: handicapJun2025,
            womens_handicap_jun_2025: womensHandicapJun2025,
            handicap_dec_2026: handicapDec2026,
            womens_handicap_dec_2026: womensHandicapDec2026,
            team_id: teamId,
            position: position,
            club_id: clubId
        )
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
        guard let url = makeURL("/horses?limit=1000") else { throw URLError(.badURL) }
        let (response, _): (PaginatedResponse<HorseDTO>, HTTPURLResponse) = try await request(url)
        return response.data
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
        guard let url = makeURL("/breeders?limit=1000") else { throw URLError(.badURL) }
        let (response, _): (PaginatedResponse<BreederDTO>, HTTPURLResponse) = try await request(url)
        return response.data
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
        guard let url = makeURL("/awards?limit=1000") else { throw URLError(.badURL) }
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

    func updateMatch(
        id: Int,
        tournamentId: Int,
        team1Id: Int,
        team2Id: Int,
        scheduledTime: String,
        result: String?
    ) async throws -> MatchDTO {
        guard let url = makeURL("/matches/\(id)") else { throw URLError(.badURL) }
        let bodyObj = CreateOrUpdateMatchRequest(
            tournament_id: tournamentId,
            team1_id: team1Id,
            team2_id: team2Id,
            scheduled_time: scheduledTime,
            result: result
        )
        let bodyData = try JSONEncoder().encode(bodyObj)
        let (dto, _): (MatchDTO, HTTPURLResponse) = try await request(url, method: "PUT", body: bodyData)
        return dto
    }

    func deleteMatch(id: Int) async throws {
        guard let url = makeURL("/matches/\(id)") else { throw URLError(.badURL) }
        _ = try await requestNoResponse(url)
    }

    // MARK: - Club APIs
    func getAllClubs() async throws -> [ClubDTO] {
        guard let url = makeURL("/clubs?limit=1000") else { throw URLError(.badURL) }
        let (response, _): (PaginatedResponse<ClubDTO>, HTTPURLResponse) = try await request(url)
        return response.data
    }

    func createClub(name: String, location: String?, foundedDate: String?) async throws -> ClubDTO {
        guard let url = makeURL("/clubs") else { throw URLError(.badURL) }
        let bodyObj = CreateOrUpdateClubRequest(name: name, location: location, founded_date: foundedDate)
        let bodyData = try JSONEncoder().encode(bodyObj)
        let (dto, _): (ClubDTO, HTTPURLResponse) = try await request(url, method: "POST", body: bodyData)
        return dto
    }

    func updateClub(id: Int, name: String, location: String?, foundedDate: String?) async throws -> ClubDTO {
        guard let url = makeURL("/clubs/\(id)") else { throw URLError(.badURL) }
        let bodyObj = CreateOrUpdateClubRequest(name: name, location: location, founded_date: foundedDate)
        let bodyData = try JSONEncoder().encode(bodyObj)
        let (dto, _): (ClubDTO, HTTPURLResponse) = try await request(url, method: "PUT", body: bodyData)
        return dto
    }

    func deleteClub(id: Int) async throws {
        guard let url = makeURL("/clubs/\(id)") else { throw URLError(.badURL) }
        _ = try await requestNoResponse(url)
    }

    // MARK: - Field APIs
    func getAllFields() async throws -> [FieldDTO] {
        guard let url = makeURL("/fields?limit=1000") else { throw URLError(.badURL) }
        let (response, _): (PaginatedResponse<FieldDTO>, HTTPURLResponse) = try await request(url)
        return response.data
    }

    func createField(name: String, location: String?, grade: String?) async throws -> FieldDTO {
        guard let url = makeURL("/fields") else { throw URLError(.badURL) }
        let bodyObj = CreateOrUpdateFieldRequest(name: name, location: location, grade: grade)
        let bodyData = try JSONEncoder().encode(bodyObj)
        let (dto, _): (FieldDTO, HTTPURLResponse) = try await request(url, method: "POST", body: bodyData)
        return dto
    }

    func updateField(id: Int, name: String, location: String?, grade: String?) async throws -> FieldDTO {
        guard let url = makeURL("/fields/\(id)") else { throw URLError(.badURL) }
        let bodyObj = CreateOrUpdateFieldRequest(name: name, location: location, grade: grade)
        let bodyData = try JSONEncoder().encode(bodyObj)
        let (dto, _): (FieldDTO, HTTPURLResponse) = try await request(url, method: "PUT", body: bodyData)
        return dto
    }

    func deleteField(id: Int) async throws {
        guard let url = makeURL("/fields/\(id)") else { throw URLError(.badURL) }
        _ = try await requestNoResponse(url)
    }

    // MARK: - Duty APIs
    func getAllDuties() async throws -> [DutyDTO] {
        guard let url = makeURL("/duties?limit=1000") else { throw URLError (.badURL) }
        let (response, _): (PaginatedResponse<DutyDTO>, HTTPURLResponse) = try await request(url)
        return response.data
    }

    func createDuty(type: String, date: String?, notes: String?, playerId: Int?, matchId: Int?) async throws -> DutyDTO {
        guard let url = makeURL("/duties") else { throw URLError(.badURL) }
        let bodyObj = CreateOrUpdateDutyRequest(type: type, date: date, notes: notes, player_id: playerId, match_id: matchId)
        let bodyData = try JSONEncoder().encode(bodyObj)
        let (dto, _): (DutyDTO, HTTPURLResponse) = try await request(url, method: "POST", body: bodyData)
        return dto
    }

    func updateDuty(id: Int, type: String, date: String?, notes: String?, playerId: Int?, matchId: Int?) async throws -> DutyDTO {
        guard let url = makeURL("/duties/\(id)") else { throw URLError(.badURL) }
        let bodyObj = CreateOrUpdateDutyRequest(type: type, date: date, notes: notes, player_id: playerId, match_id: matchId)
        let bodyData = try JSONEncoder().encode(bodyObj)
        let (dto, _): (DutyDTO, HTTPURLResponse) = try await request(url, method: "PUT", body: bodyData)
        return dto
    }

    func deleteDuty(id: Int) async throws {
        guard let url = makeURL("/duties/\(id)") else { throw URLError(.badURL) }
        _ = try await requestNoResponse(url)
    }
}
