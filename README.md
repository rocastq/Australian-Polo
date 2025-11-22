# Australian Polo

A comprehensive iOS and iPadOS application for managing polo tournaments, clubs, players, teams, horses, fields, and comprehensive statistics with a modern, streamlined interface.

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
- **Modern UI Design**: Liquid glass effects and contemporary design elements
- **Unified Navigation**: Streamlined 4-tab interface with intelligent grouping
- **Segmented Organization**: Multi-view tabs for efficient content management
- **Offline Capability**: Full functionality without internet connection
- **Advanced Statistics**: Comprehensive analytics across all data types
- **Smart Toolbars**: Context-aware interface elements
- **Settings Integration**: Centralized settings and administrative features

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
Australian Polo/
├── Australian_PoloApp.swift     # Main app entry point
├── ContentView.swift             # Root navigation with 4-tab structure
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
└── Views/                        # SwiftUI views organized by feature
    ├── TournamentViews.swift     # Tournaments & Matches (unified)
    ├── ClubViews.swift          # Clubs, Players, Teams, Fields, Horses (unified)
    ├── StatisticsView.swift     # Multi-category analytics
    ├── UserViews.swift          # User management
    ├── DutyViews.swift          # Official assignments
    ├── BreederViews.swift       # Breeder management
    ├── MatchViews.swift         # Match components
    ├── PlayerViews.swift        # Player components
    ├── TeamViews.swift          # Team components
    ├── FieldViews.swift         # Field components
    └── HorseViews.swift         # Horse components
```

## App Navigation

### Main Interface
The app features a clean, 4-tab navigation structure:

1. **Home Tab** 🏠
   - Welcome dashboard with liquid glass design elements
   - Summary tiles showing active tournaments, pending matches, and active players
   - Quick access sections for upcoming tournaments, recent matches, and top players
   - Settings button (⚙️) in top-right for additional features and app settings

2. **Tournaments Tab** 🏆
   - **Integrated tournament and match management**
   - Segmented picker to switch between "Tournaments" and "Matches"
   - Create, view, and manage tournaments
   - Complete match management with filtering by result (All, Win, Loss, Draw, Pending)
   - Smart toolbar adapts based on current view (Add Tournament/Add Match)

3. **Clubs Tab** 🏢
   - **Comprehensive club-related management hub**
   - 5-way segmented picker: Clubs | Players | Teams | Fields | Horses
   - All club-related entities organized in one cohesive interface
   - Unified management for club infrastructure and membership
   - Dynamic navigation and add buttons based on selected section

4. **Statistics Tab** 📊
   - **Advanced analytics and reporting**
   - Multi-category statistics with segmented picker: Matches | Players | Teams | Horses | Tournaments
   - Performance metrics, trends, and insights
   - Comprehensive data visualization and analysis tools

### Settings & Additional Features
Accessed via the settings button (⚙️) in the Home tab:

- **Additional Features**:
  - User management and profiles
  - Duty assignments and official coordination
  - Breeder information and horse lineage

- **App Settings**:
  - Application preferences and configuration
  - About information
  - Help and support

## Usage

### Getting Started
1. **Home Dashboard**: Start here for an overview of current activities and quick navigation
2. **Tournament Management**: Use the Tournaments tab to create events and manage match schedules
3. **Club Operations**: Access all club-related functions through the Clubs tab
4. **Data Analysis**: Review performance and trends in the Statistics tab
5. **Additional Features**: Access specialized functions through the Settings menu

### Key Workflows

#### Tournament & Match Management
- Navigate to Tournaments tab
- Switch between "Tournaments" and "Matches" using the segmented picker
- Create tournaments and schedule matches
- Track results and manage competition flow

#### Club & Member Management
- Navigate to Clubs tab
- Use segmented picker to access: Clubs | Players | Teams | Fields | Horses
- Manage all aspects of club operations from member registration to facility management
- Unified interface for comprehensive club administration

#### Performance Analysis
- Navigate to Statistics tab
- Select category using segmented picker: Matches | Players | Teams | Horses | Tournaments
- Review detailed analytics and performance metrics
- Export data and generate reports

#### Administrative Tasks
- Tap settings button (⚙️) in Home tab
- Access user management, duty assignments, and breeder information
- Configure app settings and preferences

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

## Recent Updates

### Navigation Architecture Redesign
- **Streamlined Interface**: Reduced from 6 tabs to 4 main tabs for improved usability
- **Unified Management**: Related features grouped together (e.g., all club-related entities in one tab)
- **Settings Integration**: Administrative features moved to accessible settings menu
- **Modern Design**: Liquid glass effects and contemporary UI elements

### Key Improvements
- **Tournament + Matches**: Combined into single tab with segmented picker
- **Clubs Hub**: Unified management for Clubs, Players, Teams, Fields, and Horses
- **Statistics**: Dedicated tab with comprehensive multi-category analytics
- **Settings**: Centralized access to Users, Duties, Breeders, and app preferences

---

Built with ❤️ for the polo community using Swift and SwiftUI.