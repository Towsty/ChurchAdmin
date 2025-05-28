# Church Admin App

A Flutter-based church administration application designed to help churches manage their congregation, events, and communications effectively.

## Features

### Member Management
- Profile management with first/last name support
- Role-based access control (Super Admin, Admin, Leader, Member, Visitor)
- Member directory with search functionality
- Join request system for new members

### Attendance Tracking
- Digital attendance recording for services and events
- Historical attendance data viewing
- Export attendance data to CSV
- Analytics and reporting features

### Small Groups Management
- Create and manage small groups
- Assign leaders and members
- Group communication features
- Event scheduling for groups

### Communication Tools
- Church-wide announcements
- Group-specific messaging
- Push notifications for important updates
- Communication groups for targeted messaging

### Devotionals
- Daily devotional content management
- Rich text formatting support
- Schedule and archive devotionals
- Tag-based categorization

### Administrative Features
- Church profile management
- Role and permission management
- Member approval workflow
- Data export capabilities

## Technical Requirements

### Prerequisites
- Flutter SDK ^3.7.2
- Firebase account for backend services
- iOS 11.0+ / Android 5.0+

### Dependencies
- Firebase Core ^2.27.0
- Cloud Firestore ^4.13.5
- Firebase Auth ^4.17.4
- Other dependencies as listed in pubspec.yaml

## Installation

1. Clone the repository:
```bash
git clone https://github.com/Towsty/ChurchAdmin.git
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure Firebase:
   - Create a new Firebase project
   - Add iOS/Android apps in Firebase console
   - Download and add configuration files
   - Enable Authentication and Firestore

4. Run the app:
```bash
flutter run
```

## Configuration

### Firebase Setup
1. Enable Email/Password authentication
2. Set up Firestore security rules
3. Configure storage rules for media
4. Set up Firebase Functions if needed

### Environment Variables
Create a `.env` file in the root directory with:
```
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_API_KEY=your_api_key
```

## Architecture

The app follows a service-based architecture with:
- Screens: UI components
- Services: Business logic and Firebase interactions
- Models: Data structures
- Widgets: Reusable UI components

## Security

- Role-based access control
- Firestore security rules
- Secure data transmission
- Input validation and sanitization

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## Version History

- v0.5.5
  - Role-based permission system
  - Profile management improvements
  - Debug mode features
  - Performance optimizations

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support, please open an issue in the GitHub repository or contact the development team.

## Acknowledgments

- Flutter team for the framework
- Firebase for backend services
- Contributors and testers

---
Built with ❤️ for churches worldwide
