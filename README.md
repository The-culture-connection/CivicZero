# CivicZero

A Flutter application for civic engagement and community participation.

## Features

- **Authentication**: Secure login and registration with email/password
- **Governments View**: Browse and explore different government bodies and their information
- **Town Square**: Community discussion forum where users can share posts, like, and comment
- **Profile Management**: Edit user profile with personal information and settings

## Design

### Color Theme
- Primary Dark: `#1A1A1A`
- Primary Light: `#FFFFFF`

### Typography
- Font Family: Ubuntu (Regular, Light, Medium, Bold with italic variants)

## Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK

### Installation

1. Clone the repository:
```bash
git clone https://github.com/The-culture-connection/CivicZero.git
cd CivicZero
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── config/
│   └── app_theme.dart          # App theme configuration and colors
├── views/
│   ├── auth_view.dart          # Authentication screen
│   ├── main_tab_view.dart      # Main navigation with bottom tabs
│   ├── governments_view.dart   # Government bodies listing
│   ├── town_square_view.dart   # Community discussion forum
│   └── edit_profile_view.dart  # User profile editor
└── main.dart                   # App entry point

assets/
├── Fonts/                      # Ubuntu font family
└── Images/                     # App images and icons
```

## Views

### 1. Auth View
- Login/Sign up functionality
- Email and password validation
- Beautiful UI with the CivicZero logo

### 2. Governments View
- List of government bodies
- Search functionality
- Details including location, members, and meeting schedules

### 3. Town Square View
- Social feed with posts
- Like and comment functionality
- Create new posts
- Share posts

### 4. Edit Profile View
- Update personal information
- Change profile picture
- Manage notification and privacy settings

## Technologies Used

- **Flutter**: UI framework
- **Material Design 3**: Design system
- **Custom Theme**: Consistent branding throughout the app

## License

Copyright © 2026 The Culture Connection. All rights reserved.
