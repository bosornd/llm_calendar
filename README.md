# LLM Calendar

A Flutter chatbot application with Google Generative AI and calendar integration. This app combines the power of AI assistance with calendar management for Windows and Android platforms.

## Features

- 🤖 **AI Chatbot**: Powered by Google Generative AI (Gemini)
- 📅 **Calendar Integration**: Full calendar view with event management
- 🎨 **Modern UI**: Material Design 3 with light/dark theme support
- 🔄 **Cross-platform**: Supports Windows and Android
- 💬 **Interactive Chat**: Markdown support for rich AI responses
- ⚡ **Real-time**: Instant AI responses with loading indicators

## Getting Started

### Prerequisites

- Flutter SDK (3.7.2 or higher)
- Dart SDK
- Google AI API Key

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd llm_calendar
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Set up your Google AI API Key:
   - Get your API key from [Google AI Studio](https://makersuite.google.com/app/apikey)
   - Create a `.env` file in the project root
   - Add your API key:
     ```
     GEMINI_API_KEY=your_api_key_here
     ```

4. Run the application:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── chat_message.dart
│   └── calendar_event.dart
├── providers/                # State management
│   ├── chat_provider.dart
│   └── calendar_provider.dart
├── screens/                  # UI screens
│   ├── home_screen.dart
│   ├── chat_screen.dart
│   └── calendar_screen.dart
└── services/                 # External services
    └── gemini_service.dart
```

## Key Dependencies

- `google_generative_ai`: Google's Generative AI SDK
- `provider`: State management
- `table_calendar`: Calendar widget
- `flutter_markdown`: Markdown rendering
- `flutter_dotenv`: Environment variables

## Usage

### Chat Features
- Ask the AI assistant about calendar management
- Get help with scheduling and reminders
- General conversation support
- Markdown formatted responses

### Calendar Features
- Monthly calendar view
- Add/remove events
- Event details with time management
- Visual event indicators

## Platform Support

- ✅ Windows
- ✅ Android
- 🚧 iOS (not configured)
- 🚧 macOS (not configured)
- 🚧 Linux (not configured)
- 🚧 Web (not configured)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on both Windows and Android
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
