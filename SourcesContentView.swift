import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Dashboard")
                }
                .tag(0)
            
            TournamentListView()
                .tabItem {
                    Image(systemName: "trophy.fill")
                    Text("Tournaments")
                }
                .tag(1)
            
            TeamListView()
                .tabItem {
                    Image(systemName: "person.3.fill")
                    Text("Teams")
                }
                .tag(2)
            
            PlayerListView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Players")
                }
                .tag(3)
            
            HorseListView()
                .tabItem {
                    Image(systemName: "pawprint.fill")
                    Text("Horses")
                }
                .tag(4)
            
            StatisticsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Statistics")
                }
                .tag(5)
        }
    }
}