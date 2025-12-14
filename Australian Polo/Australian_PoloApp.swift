//
//  Australian_PoloApp.swift
//  Australian Polo
//
//  Created by Rodrigo Castillo on 9/29/25.
//

import SwiftUI
import SwiftData

@main
struct Australian_PoloApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            Tournament.self,
            Field.self,
            Club.self,
            Team.self,
            Duty.self,
            Player.self,
            Breeder.self,
            Horse.self,
            Match.self,
            MatchParticipation.self,
            Item.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // If migration fails, delete the old database and try again
            print("⚠️ ModelContainer creation failed: \(error)")
            print("🗑️ Attempting to delete old database and recreate...")

            // Get the default store URL
            let url = URL.applicationSupportDirectory.appending(path: "default.store")
            try? FileManager.default.removeItem(at: url)

            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer even after deleting old database: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
