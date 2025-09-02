# FYP - Flutter Project

Final Year Project for Semester 6 - A Flutter application with Firebase integration.

## Features

- User authentication and registration
- Business location mapping
- Menu management
- Review and reporting system
- Admin panel functionality

## Setup Instructions

### Prerequisites

- Flutter SDK (latest stable version)
- Android Studio / VS Code
- Firebase project setup

### Installation

1. Clone the repository:
```bash
git clone https://github.com/YOUR_USERNAME/YOUR_REPOSITORY_NAME.git
cd fyp
```

2. Install dependencies:
```bash
flutter pub get
```

3. **Firebase Configuration (IMPORTANT):**
   - Copy `android/app/google-services.json.template` to `android/app/google-services.json`
   - Replace the placeholder values with your actual Firebase configuration:
     - `YOUR_PROJECT_NUMBER`: Your Firebase project number
     - `YOUR_PROJECT_ID`: Your Firebase project ID
     - `YOUR_STORAGE_BUCKET`: Your Firebase storage bucket
     - `YOUR_MOBILE_SDK_APP_ID`: Your mobile SDK app ID
     - `YOUR_API_KEY_HERE`: Your Firebase API key
   - **Never commit the actual `google-services.json` file to version control**

4. Run the application:
```bash
flutter run
```

## Security Notice

- The `google-services.json` file contains sensitive API keys and is excluded from version control
- Always use the template file and replace with your own Firebase configuration
- Never share your actual Firebase API keys publicly

## Getting Started with Flutter

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
