# 🏀 Hooper Buddy

**Hooper Buddy** is a mobile basketball training and analytics app built with Flutter. Designed for players and coaches, it helps you design custom workout drills, execute training sessions with real-time sound cues, track session performance over time, and view detailed progress analytics.

---

##  Features

- **Custom Drill Builder**: Create and customize basketball drills with specific time limits, sets, and rep targets.
- **Interactive Drill Runner**: Execute workouts with dynamic timers, audio feedback (SFX), and haptic vibrations via a dedicated `AudioService`.
- **Analytics & Charts**: Visualize your shooting accuracy, training frequency, and overall progress with interactive `fl_chart` data visualizers.
- **Session History**: Store training logs offline using local SQLite (`sqflite`) storage.
- **Session Detail Sharing**: Easily share workout summaries and stats with teammates or coaches via `share_plus`.
- **Global Settings**: Customize sound preferences, audio feedback, and application defaults.
- **Custom Branding**: Unified UI styling featuring a fixed header system, custom high-resolution app launcher icon, and trademark footer.

---

##  Tech Stack

- **Framework**: [Flutter SDK](https://flutter.dev) (Dart)
- **Local Database**: `sqflite` & `path_provider`
- **Data Visualization**: `fl_chart`
- **Audio & Feedback**: `audioplayers` & Haptic Feedback
- **Preferences**: `shared_preferences`
- **Sharing**: `share_plus`

---

##  How to Install & Use the APK (Android)

If you just want to run the pre-built app on your Android device:

1. Go to the **Releases** tab on this GitHub repository.
2. Download the latest **`app-release.apk`**.
3. Transfer the `.apk` file to your Android phone (or download it directly on your device).
4. Tap the file to install it *(Note: You may need to enable "Install from Unknown Sources" in your phone settings)*.
5. Open **Hooper Buddy** and start training!

---

##  Developer Setup & Building from Source

To run or build the project locally on your machine:

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.0.0 or higher recommended)
- [Android Studio](https://developer.android.com/studio) or VS Code with Flutter extension
- Git installed

### 1. Clone the Repository
```bash
git clone https://github.com/YOUR-USERNAME/hooper_buddy.git
cd hooper_buddy
```

### 2. Install Dependencies
Fetch all the required pub packages:
```bash
flutter pub get
```

### 3. Generate Launcher Icons (Optional)
If you modify `assets/images/app_icon.png` or want to regenerate launcher icons:
```bash
dart run flutter_launcher_icons
```

### 4. Run the App
Connect an Android physical device or start an emulator, then run:
```bash
flutter run
```

### 5. Build Release APK
To compile an optimized Android Release APK:
```bash
flutter build apk --release
```

The output file will be saved at:
`build/app/outputs/flutter-apk/app-release.apk`

---

##  iOS Support Note

While Hooper Buddy is written in Flutter and fully cross-platform compatible, building for iOS requires a Mac with **Xcode** installed. To run on iOS:

1. Open the project on macOS.
2. Open the `ios/` directory in Xcode to set up signing certificates.
3. Run `flutter run` selecting an iOS Simulator or connected iPhone.

---

##  License

This project is created for personal and educational use. Feel free to fork, adapt, and improve it for your own basketball training!
