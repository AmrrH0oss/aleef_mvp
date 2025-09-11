# 🐾 Aleef - Pet Care Platform

A Flutter-based mobile and web application connecting pet owners with veterinary clinics.

## 🌟 Features

- **User Authentication**: Secure signup/login with Supabase
- **Clinic Discovery**: Browse and search veterinary clinics
- **Location-Based Sorting**: Clinics sorted by user's district and city
- **Appointment Booking**: Schedule appointments with clinics
- **Real-time Updates**: Live notifications and updates
- **Responsive Design**: Works on mobile, tablet, and desktop

## 🏗️ Architecture

### Frontend
- **Flutter**: Cross-platform UI framework
- **Supabase Flutter**: Authentication and database client
- **Material Design**: Modern, accessible UI components

### Backend
- **Supabase**: Backend-as-a-Service
  - PostgreSQL database
  - Authentication service
  - Edge Functions for custom logic
  - Row Level Security (RLS)

### Key Components
- **Authentication Service**: Handles user signup/login
- **Clinic Service**: Manages clinic data and location-based sorting
- **Edge Functions**: Server-side logic for clinic sorting and filtering

## 📊 Database Schema

### Core Tables
- **PetOwners**: User profiles with location data
- **Clinic**: Veterinary clinic information
- **Booking**: Appointment scheduling
- **Rating**: Clinic reviews and ratings
- **Pet**: Pet information
- **Doctor**: Clinic staff information

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable)
- Dart SDK
- Supabase account and project

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd test_screen
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Supabase**
   - Update `lib/core/supabase_client.dart` with your project credentials
   ```dart
   const supabaseUrl = 'YOUR_SUPABASE_URL';
   const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   ```

4. **Run the app**
   ```bash
   # For web
   flutter run -d chrome
   
   # For mobile (with device/emulator connected)
   flutter run
   ```

## 🧪 Testing

The app includes comprehensive test screens for development:

- **🔒 Auth-Only Test**: Tests basic Supabase authentication
- **✋ Without Trigger Test**: Tests manual PetOwners creation
- **🧪 Authentication Test**: Comprehensive auth flow testing
- **👥 Signup + PetOwners Test**: Full registration flow
- **🏥 Simple Clinics Page**: Clinic listing with location sorting

## 🗂️ Project Structure

```
lib/
├── core/               # Core configuration
├── data/              # Data layer (API calls, Edge Functions)
├── examples/          # Test and example screens
├── models/            # Data models
├── screens/           # UI screens
├── services/          # Business logic services
├── theme/             # App theming
└── widgets/           # Reusable UI components

supabase/
└── functions/         # Edge Functions
    └── clinics-list/  # Location-based clinic sorting
```

## 🔧 Key Features Implementation

### Location-Based Clinic Sorting
- **Server-side sorting** via Supabase Edge Functions
- **Ranking system**: Same district (rank 2) → Same city (rank 1) → Others (rank 0)
- **Automatic user location detection** from PetOwners table

### Authentication Flow
- **Supabase Auth integration** with email/password
- **Automatic profile creation** via database triggers
- **Session management** and JWT handling
- **Comprehensive error handling**

### Responsive Design
- **Adaptive layouts** for mobile, tablet, and desktop
- **Material Design 3** components
- **Accessibility features** built-in

## 🚀 Deployment

### Web Deployment
```bash
flutter build web
# Deploy the build/web folder to your hosting service
```

### Mobile Deployment
```bash
# Android
flutter build apk --release

# iOS (requires macOS and Xcode)
flutter build ios --release
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:
- Create an issue in this repository
- Check the test screens for debugging tools
- Review the comprehensive error handling in services

## 🎯 Roadmap

- [ ] Real-time chat with clinics
- [ ] Advanced appointment scheduling
- [ ] Pet medical records
- [ ] Push notifications
- [ ] Multi-language support
- [ ] Payment integration