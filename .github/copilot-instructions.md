<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# LLM Calendar - Flutter Chatbot App

This is a Flutter application that integrates Google Generative AI (Gemini) with calendar functionality.

## Project Structure
- **lib/main.dart**: Main application entry point with Provider setup
- **lib/providers/**: State management with Provider pattern
- **lib/screens/**: UI screens (Home, Chat, Calendar)
- **lib/models/**: Data models for chat messages and calendar events
- **lib/services/**: External service integrations (Gemini AI)

## Key Features
- AI-powered chatbot using Google Generative AI (Gemini)
- Calendar view with event management
- Cross-platform support (Windows and Android)
- Material Design 3 UI

## Development Guidelines
- Use Provider pattern for state management
- Follow Flutter best practices and Material Design guidelines
- Implement proper error handling for API calls
- Ensure responsive design for different screen sizes
- Use proper null safety throughout the codebase

## Dependencies
- google_generative_ai: For AI chatbot functionality
- provider: State management
- table_calendar: Calendar widget
- flutter_markdown: Markdown rendering for AI responses
- flutter_dotenv: Environment variable management

## Environment Setup
- Add GEMINI_API_KEY to .env file
- Get API key from: https://makersuite.google.com/app/apikey
