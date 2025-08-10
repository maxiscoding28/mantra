# Mantra

A minimalist meditation timer with AI-powered mantra generation built with Flutter.

## Features

- **Meditation Timer**: Set meditation length from 0 to 60 minutes with Start, Pause, and Reset controls
- **Large Countdown Display**: Easy-to-read mm:ss format with Material 3 design
- **AI Mantra Generation**: Generate personalized mantras based on your meditation insights
- **Session History**: Keep track of your last 10 meditation sessions
- **Audio & Haptic Feedback**: Subtle chime and vibration on completion
- **Accessible Design**: Mobile-first with large touch targets and high contrast
- **Light & Dark Theme**: Automatic theme support

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.4.0)

### Installation

1. Clone or download this project
2. Navigate to the project directory:
   ```bash
   cd mantra
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

### Running the App

#### With AI Features (OpenAI API)

To use AI-powered mantra generation, you'll need an OpenAI API key:

```bash
flutter run \
  --dart-define=MANTRA_API_KEY=sk-your-openai-api-key \
  --dart-define=MANTRA_API_URL=https://api.openai.com/v1/chat/completions \
  --dart-define=MANTRA_MODEL=gpt-4o-mini
```

#### Without AI (Fallback Mode)

The app works without an API key and will use "Breathe" as the default mantra:

```bash
flutter run
```

### Building for Release

#### Android
```bash
flutter build apk --dart-define=MANTRA_API_KEY=sk-your-key
```

#### iOS
```bash
flutter build ios --dart-define=MANTRA_API_KEY=sk-your-key
```

## Configuration

The app supports the following environment variables via `--dart-define`:

- `MANTRA_API_KEY`: Your OpenAI API key (optional)
- `MANTRA_API_URL`: API endpoint (default: OpenAI's chat completions)
- `MANTRA_MODEL`: AI model to use (default: gpt-4o-mini)

## Usage

1. **Set Timer**: Use the +/- buttons to set your meditation duration (0-60 minutes)
2. **Start Meditation**: Tap "Start" to begin your session
3. **Meditation Controls**: Use "Pause" to temporarily stop, "Reset" to start over
4. **Completion**: When the timer reaches 00:00, you'll feel a vibration
5. **Add Notes**: Optionally share your meditation insights (280 character limit)
6. **Generate Mantra**: Tap "Generate Mantra" to create a personalized mantra
7. **View History**: See your recent sessions in the history section below

## Architecture

### File Structure
```
lib/
  main.dart           # Complete app implementation
test/
  widget_test.dart    # Unit and widget tests
assets/
  chime.mp3          # Meditation completion sound
```

### Key Components

- **TimerState**: Manages meditation timer state using ValueNotifier
- **MeditationSession**: Data model for session storage
- **AI Integration**: HTTP requests to OpenAI-compatible APIs
- **Local Storage**: Uses shared_preferences for session history

### State Management

The app uses Flutter's built-in state management:
- `ValueNotifier<TimerState>` for timer state
- `StatefulWidget` for UI state
- `SharedPreferences` for data persistence

## API Integration

The app integrates with OpenAI-compatible chat completion APIs:

```json
{
  "model": "gpt-4o-mini",
  "messages": [
    {
      "role": "system", 
      "content": "Generate a very short mantra (1-4 words)..."
    },
    {
      "role": "user",
      "content": "My meditation notes: [user input]"
    }
  ],
  "max_tokens": 20,
  "temperature": 0.7
}
```

## Data Storage

Sessions are stored locally in the following format:

```json
{
  "ts": 1712345678901,
  "minutes": 10,
  "notes": "Felt peaceful and centered",
  "mantra": "Be Present"
}
```

## Testing

Run the test suite:

```bash
flutter test
```

The tests cover:
- Timer initialization and controls
- Notes field visibility
- Utility function validation
- Data serialization
- UI widget behavior

## Contributing

This is a minimal implementation focused on simplicity and performance. When contributing:

1. Keep dependencies minimal
2. Maintain mobile-first design
3. Ensure accessibility compliance
4. Follow Material 3 design principles
5. Add tests for new features

## Privacy

- Notes content is never logged
- All data is stored locally on device
- API requests only include user-provided notes for mantra generation
- No analytics or tracking

## License

This project is provided as-is for educational and personal use.
