import SwiftUI
import SwiftData

@main
struct PoloManagerApp: App {
    let modelContainer: ModelContainer
    
    init() {
        do {
            let schema = Schema([
                User.self,
                Tournament.self,
                Field.self,
                Club.self,
                Team.self,
                Player.self,
                Horse.self,
                Match.self,
                Award.self,
                Duty.self
            ])
            
            modelContainer = try ModelContainer(for: schema)
        } catch {
            fatalError("Failed to create model container: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}