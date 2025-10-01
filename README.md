# Polo Manager

A comprehensive iOS and iPadOS application for managing polo tournaments, teams, players, horses, and statistics.

## Features

### User Management
- **Multiple User Profiles**: Support for Administrators, Operators, Players, Breeders, and general Users
- **User Registration**: Complete profile management with contact information
- **Role-based Access**: Different permissions and views based on user type

### Tournament Management
- **Tournament Creation**: Name, grade, dates, and location management
- **Tournament Statistics**: Comprehensive tracking of tournament performance
- **Awards Management**: Track and assign various tournament awards
- **Match Scheduling**: Schedule and manage matches within tournaments

### Field Management
- **Field Registration**: Name, location, grade, and surface type
- **Field Specifications**: Track dimensions, surface conditions, and notes
- **Match Assignment**: Link matches to specific fields

### Club Management
- **Club Profiles**: Name, location, contact information
- **Member Management**: Track players and teams associated with clubs
- **Tournament Hosting**: Link clubs to tournaments they host or participate in

### Team Management
- **Team Creation**: Name, grade, club affiliation, and team colors
- **Player Roster**: Manage team player assignments
- **Team Statistics**: Win/loss records, handicap totals, performance metrics
- **Match History**: Complete record of team matches and results

### Player Management
- **Player Profiles**: Name, handicap, club affiliation, nationality
- **Statistics Tracking**: Goals, matches played, performance metrics
- **Duty Assignments**: Track officiating and volunteer duties
- **Awards Recognition**: Individual player awards and achievements

### Horse Management
- **Horse Registration**: Name, birth date, gender, color, pedigree
- **Breeder Information**: Track breeding lineage and ownership
- **Performance Statistics**: Games played, tournaments, performance ratings
- **Awards Tracking**: Horse-specific awards and recognition

### Duties Management
- **Official Assignments**: Mounted umpires, goal umpires, centre table officials
- **Volunteer Coordination**: Timekeepers, scorers, announcers, field maintenance
- **Match and Tournament Duties**: Link duties to specific events
- **Completion Tracking**: Mark duties as completed with notes

### Statistics and Reporting
- **Match Results**: Comprehensive match outcome tracking
- **Player Performance**: Goal scoring, averages, participation metrics
- **Horse Statistics**: Activity levels, tournament participation
- **Awards Summary**: Complete awards history and distribution
- **Tournament Analytics**: Performance trends and insights

## Technical Implementation

### Architecture
- **SwiftUI**: Modern declarative UI framework
- **SwiftData**: Core Data successor for data persistence
- **MVVM Pattern**: Model-View-ViewModel architecture
- **Swift Concurrency**: Async/await for data operations

### Data Models
- **User**: Profile management with role-based permissions
- **Tournament**: Competition structure with dates and grading
- **Field**: Venue information with specifications
- **Club**: Organization profiles with contact details
- **Team**: Group management with player rosters
- **Player**: Individual profiles with handicaps and statistics
- **Horse**: Animal registration with pedigree tracking
- **Match**: Game records with scores and statistics
- **Award**: Recognition system for achievements
- **Duty**: Assignment system for officials and volunteers

### Key Features
- **Universal App**: Optimized for both iPhone and iPad
- **Offline Capability**: Full functionality without internet connection
- **Search and Filtering**: Advanced search across all data types
- **Statistics Dashboard**: Real-time analytics and performance metrics
- **Data Export**: Share statistics and results
- **Role-based Views**: Different interfaces for different user types

## Getting Started

### Requirements
- iOS 17.0+ / iPadOS 17.0+
- Xcode 15.0+
- Swift 6.0+

### Installation
1. Clone the repository
2. Open the project in Xcode
3. Build and run on simulator or device

### Project Structure
```
Sources/
├── PoloManagerApp.swift          # Main app entry point
├── ContentView.swift             # Root navigation view
├── Models/                       # SwiftData models
│   ├── User.swift
│   ├── Tournament.swift
│   ├── Field.swift
│   ├── Club.swift
│   ├── Team.swift
│   ├── Player.swift
│   ├── Horse.swift
│   ├── Match.swift
│   ├── Award.swift
│   └── Duty.swift
└── Views/                        # SwiftUI views
    ├── DashboardView.swift       # Main dashboard
    ├── Tournament/               # Tournament management
    ├── Team/                     # Team management
    ├── Player/                   # Player management
    ├── Horse/                    # Horse management
    ├── Management/               # Field, Club, Duty management
    └── StatisticsView.swift      # Analytics and reporting
```

## Usage

### Dashboard
The main dashboard provides:
- Live match updates
- Today's match schedule
- Overview statistics
- Quick access to all management areas

### Tournament Management
- Create and manage tournaments
- Schedule matches
- Track results and standings
- Award management

### Team and Player Management
- Register teams and players
- Manage rosters and assignments
- Track performance statistics
- Handle duty assignments

### Horse and Breeder Management
- Register horses with complete pedigree
- Track performance across tournaments
- Manage breeding records
- Award tracking for equine achievements

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions, please create an issue in the repository.

---

Built with ❤️ for the polo community using Swift and SwiftUI.