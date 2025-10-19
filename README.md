# FeedFlow 📰

A modern, beautiful RSS/Atom/JSON Feed reader for Android with a TikTok-style vertical scrolling interface.

## ✨ Features

- **Multi-Format Support**: Reads RSS 2.0, Atom 1.0, and JSON Feed 1.1 formats
- **Vertical Scrolling**: TikTok/Instagram Reels-style full-screen card interface
- **Feed Filtering**: Filter articles by source with an easy-to-use drawer menu
- **In-App WebView**: Read full articles without leaving the app
- **External Browser**: Option to open articles in your default browser
- **Pull-to-Refresh**: Swipe down to reload all feeds
- **Unicode Support**: Full support for Malayalam, Hindi, Tamil, and all other languages
- **Dark Mode**: Automatic dark/light theme based on system settings
- **Image Caching**: Fast loading with cached images
- **Go to Top**: Quick button to jump back to the first article

## 📱 Screenshots

[Add your screenshots here]

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Android Studio or VS Code with Flutter extensions
- Android device or emulator

### Installation

1. Clone the repository:
```bash
git clone https://github.com/soheshts/feedflow.git
cd feedflow
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure your feed sources in `assets/feeds.json`:
```json
[
  {
    "name": "TechCrunch",
    "url": "https://techcrunch.com/feed/"
  },
  {
    "name": "The Verge",
    "url": "https://www.theverge.com/rss/index.xml"
  }
]
```

4. Run the app:
```bash
flutter run
```

## 🏗️ Project Structure

```
feedflow/
├── assets/
│   └── feeds.json              # Feed source configuration
├── lib/
│   ├── main.dart               # App entry point
│   ├── models/
│   │   └── feed_item.dart      # Data models
│   ├── services/
│   │   ├── feed_parser.dart    # RSS/Atom/JSON parser
│   │   └── feed_service.dart   # Feed fetching service
│   ├── controllers/
│   │   └── feed_controller.dart # GetX state management
│   ├── screens/
│   │   ├── feed_screen.dart    # Main feed view
│   │   └── article_screen.dart # WebView article reader
│   └── widgets/
│       └── feed_card.dart      # Individual feed card UI
└── pubspec.yaml                # Dependencies
```

## 📦 Dependencies

- **get**: State management
- **http**: HTTP requests
- **xml**: XML parsing for RSS/Atom
- **webview_flutter**: In-app browser
- **url_launcher**: External browser links
- **cached_network_image**: Image caching
- **google_fonts**: Beautiful typography with multilingual support
- **intl**: Date formatting

## 🎨 Customization

### Adding Feed Sources

Edit `assets/feeds.json` to add or remove feed sources:

```json
[
  {
    "name": "Your Feed Name",
    "url": "https://example.com/feed.xml"
  }
]
```

Supported formats:
- RSS 2.0 (.xml, .rss)
- Atom 1.0 (.xml, .atom)
- JSON Feed 1.1 (.json)

### Changing Theme Colors

Edit `lib/main.dart` to customize the color scheme:

```dart
ColorScheme.fromSeed(
  seedColor: Colors.deepPurple, // Change this color
  brightness: Brightness.light,
),
```

### Adjusting Description Length

Edit `lib/widgets/feed_card.dart` to change how many lines of description are shown:

```dart
maxLines: 10, // Change this number
```

## 🔧 Configuration

### Android Permissions

The following permissions are required and already configured:

**AndroidManifest.xml** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.INTERNET" />

<queries>
  <intent>
    <action android:name="android.intent.action.VIEW" />
    <data android:scheme="https" />
  </intent>
  <intent>
    <action android:name="android.intent.action.VIEW" />
    <data android:scheme="http" />
  </intent>
</queries>
```

### iOS Configuration (if needed)

**Info.plist** (`ios/Runner/Info.plist`):
```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>https</string>
  <string>http</string>
</array>
```

## 🐛 Troubleshooting

### Malayalam or other languages not displaying correctly

Make sure you've rebuilt the app completely:
```bash
flutter clean
flutter pub get
flutter run
```

The app uses UTF-8 encoding and Google Fonts (Noto Sans) which supports all Unicode languages.

### WebView showing "err_blocked_by_orb"

The app includes a custom User-Agent to bypass most restrictions. If a site still blocks the WebView, use the "Open in Browser" button to view the article in your default browser.

### Feeds not loading

1. Check your internet connection
2. Verify the feed URLs in `assets/feeds.json` are correct and accessible
3. Check the console for error messages

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with Flutter and Dart
- Uses Google Fonts for beautiful typography
- Inspired by TikTok and Instagram Reels UI/UX
- Feed parsing based on RSS/Atom/JSON Feed specifications

## 📧 Contact

Your Name - [@yourtwitter](https://twitter.com/yourtwitter) - email@example.com

Project Link: [https://github.com/yourusername/feedflow](https://github.com/yourusername/feedflow)

---

Made with ❤️ using Flutter
