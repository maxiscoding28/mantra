import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MantraApp());
}

class MantraApp extends StatelessWidget {
  const MantraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mantra',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3AED), // Light purple
          brightness: Brightness.light,
        ).copyWith(
          surface: Colors.white,
          onSurface: const Color(0xFF1F2937), // Dark gray
          primary: const Color(0xFF7C3AED), // Light purple
          onPrimary: Colors.white,
          secondary: const Color(0xFFF3F4F6), // Light gray
          onSecondary: const Color(0xFF6B7280), // Medium gray
        ),
        cardTheme: const CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor:
              const Color(0xFF8B5CF6), // Slightly lighter purple for dark
          brightness: Brightness.dark,
        ).copyWith(
          surface: const Color(0xFF111827), // Very dark gray
          onSurface: const Color(0xFFF9FAFB), // Light gray
          primary: const Color(0xFF8B5CF6), // Light purple
          onPrimary: Colors.white,
          secondary: const Color(0xFF374151), // Dark gray
          onSecondary: const Color(0xFF9CA3AF), // Medium gray
        ),
        cardTheme: const CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ),
      home: const MantraHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MantraHomePage extends StatefulWidget {
  const MantraHomePage({super.key});

  @override
  State<MantraHomePage> createState() => _MantraHomePageState();
}

class _MantraHomePageState extends State<MantraHomePage> {
  final ValueNotifier<TimerState> _timerState = ValueNotifier(TimerState());
  List<MeditationSession> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _timerState.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('mantra_history') ?? '[]';
    final List<dynamic> historyList = jsonDecode(historyJson);
    setState(() {
      _history =
          historyList.map((json) => MeditationSession.fromJson(json)).toList();
    });
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = jsonEncode(_history.map((s) => s.toJson()).toList());
    await prefs.setString('mantra_history', historyJson);
  }

  Future<void> _clearHistory() async {
    setState(() {
      _history.clear();
    });
    await _saveHistory();
  }

  void _startTimer() {
    HapticFeedback.lightImpact();
    final state = _timerState.value;
    if (state.remainingSeconds == 0) return;

    _timerState.value = state.copyWith(
      isRunning: true,
      timer: Timer.periodic(const Duration(seconds: 1), (timer) {
        final currentState = _timerState.value;
        if (currentState.remainingSeconds <= 1) {
          timer.cancel();
          _onTimerComplete();
        } else {
          _timerState.value = currentState.copyWith(
            remainingSeconds: currentState.remainingSeconds - 1,
          );
        }
      }),
    );
  }

  void _pauseTimer() {
    final state = _timerState.value;
    state.timer?.cancel();
    _timerState.value = state.copyWith(isRunning: false, timer: null);
  }

  void _resetTimer() {
    final state = _timerState.value;
    state.timer?.cancel();
    _timerState.value = TimerState(
      totalMinutes: state.totalMinutes,
      remainingSeconds: state.totalMinutes * 60,
    );
  }

  void _onTimerComplete() {
    HapticFeedback.heavyImpact();
    // In a real app, this would play the chime.mp3 asset
    // For now, we use haptic feedback as fallback

    _timerState.value = _timerState.value.copyWith(
      isRunning: false,
      isCompleted: true,
      timer: null,
    );

    // Navigate to completion screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CompletionScreen(
          minutes: _timerState.value.totalMinutes,
          onComplete: (notes, mantra) {
            final session = MeditationSession(
              timestamp: DateTime.now().millisecondsSinceEpoch,
              minutes: _timerState.value.totalMinutes,
              notes: notes,
              mantra: mantra,
            );

            setState(() {
              _history.insert(0, session);
              if (_history.length > 10) {
                _history = _history.take(10).toList();
              }
            });

            _saveHistory();
            _resetTimer();
          },
        ),
      ),
    );
  }

  void _setMinutes(int minutes) {
    final clampedMinutes = clampMinutes(minutes);
    _timerState.value = TimerState(
      totalMinutes: clampedMinutes,
      remainingSeconds: clampedMinutes * 60,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Header
              Text(
                'Mantra',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w300,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 48),

              // Main Timer Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color:
                        Theme.of(context).colorScheme.outline.withOpacity(0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.05),
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ValueListenableBuilder<TimerState>(
                  valueListenable: _timerState,
                  builder: (context, state, _) {
                    return Column(
                      children: [
                        // Minutes Selector
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: state.isRunning
                                  ? null
                                  : () => _setMinutes(state.totalMinutes - 1),
                              icon: Icon(
                                Icons.remove_circle_outline,
                                size: 32,
                                color: state.isRunning
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.3)
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            Container(
                              width: 120,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Text(
                                '${state.totalMinutes} min',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                              ),
                            ),
                            IconButton(
                              onPressed: state.isRunning
                                  ? null
                                  : () => _setMinutes(state.totalMinutes + 1),
                              icon: Icon(
                                Icons.add_circle_outline,
                                size: 32,
                                color: state.isRunning
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.3)
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 48),

                        // Timer Display
                        Text(
                          formatMMSS(state.remainingSeconds),
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w200,
                                fontSize: 84,
                                color: Theme.of(context).colorScheme.onSurface,
                                letterSpacing: 4,
                              ),
                        ),

                        const SizedBox(height: 48),

                        // Timer Controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!state.isRunning &&
                                state.remainingSeconds > 0) ...[
                              SizedBox(
                                width: 120,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _startTimer,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    foregroundColor:
                                        Theme.of(context).colorScheme.onPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    'Start',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ] else if (state.isRunning) ...[
                              SizedBox(
                                width: 120,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _pauseTimer,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.secondary,
                                    foregroundColor: Theme.of(context)
                                        .colorScheme
                                        .onSecondary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    'Pause',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            if (!state.isRunning &&
                                state.remainingSeconds !=
                                    state.totalMinutes * 60) ...[
                              const SizedBox(width: 16),
                              SizedBox(
                                width: 120,
                                height: 56,
                                child: TextButton(
                                  onPressed: _resetTimer,
                                  style: TextButton.styleFrom(
                                    foregroundColor: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.7),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline
                                            .withOpacity(0.3),
                                      ),
                                    ),
                                  ),
                                  child: const Text(
                                    'Reset',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 48),

              // History Section
              if (_history.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Sessions',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                          TextButton(
                            onPressed: _clearHistory,
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...(_history.take(5).map((session) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        session.mantra,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${session.minutes} min • ${_formatTimestamp(session.timestamp)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.6),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ))),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDate = DateTime(date.year, date.month, date.day);

    if (sessionDate == today) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }
}

class CompletionScreen extends StatefulWidget {
  final int minutes;
  final Function(String notes, String mantra) onComplete;

  const CompletionScreen({
    super.key,
    required this.minutes,
    required this.onComplete,
  });

  @override
  State<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends State<CompletionScreen> {
  final TextEditingController _notesController = TextEditingController();
  bool _isGeneratingMantra = false;
  String? _mantra;
  String? _error;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _generateMantra() async {
    final notes = _notesController.text.trim();
    if (!isValidNotes(notes)) return;

    setState(() {
      _isGeneratingMantra = true;
      _error = null;
    });

    try {
      final mantra = await _requestMantra(notes);
      setState(() {
        _mantra = mantra;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to generate mantra. Please try again.';
      });
    } finally {
      setState(() {
        _isGeneratingMantra = false;
      });
    }
  }

  Future<String> _requestMantra(String notes) async {
    const apiKey = String.fromEnvironment('MANTRA_API_KEY');
    if (apiKey.isEmpty) {
      return 'Breathe';
    }

    const apiUrl = String.fromEnvironment(
      'MANTRA_API_URL',
      defaultValue: 'https://api.openai.com/v1/chat/completions',
    );
    const model =
        String.fromEnvironment('MANTRA_MODEL', defaultValue: 'gpt-4o-mini');

    final response = await http
        .post(
          Uri.parse(apiUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': model,
            'messages': [
              {
                'role': 'system',
                'content':
                    'You are a meditation assistant. Generate a very short mantra (1-4 words) based on the user\'s meditation notes. Return only the mantra, nothing else.',
              },
              {
                'role': 'user',
                'content': 'My meditation notes: $notes',
              },
            ],
            'max_tokens': 20,
            'temperature': 0.7,
          }),
        )
        .timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices']?[0]?['message']?['content'] as String?;
      return sanitizeMantra(content);
    } else {
      throw HttpException('API request failed: ${response.statusCode}');
    }
  }

  void _complete() {
    final notes = _notesController.text.trim();
    final mantra = _mantra ?? 'Breathe';
    widget.onComplete(notes, mantra);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  48,
            ),
            child: Column(
              children: [
                // Main Content
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),

                    // Completion Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Completion Text
                    Text(
                      'Meditation Complete',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w400,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      '${widget.minutes} minutes of mindfulness',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7),
                          ),
                    ),

                    const SizedBox(height: 40),

                    // Notes Input
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How was your meditation?',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _notesController,
                            maxLength: 280,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Share your insights (optional)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withOpacity(0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Mantra Display
                    if (_mantra != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Your Mantra',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _mantra!,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Error Display
                    if (_error != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .error
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),

                // Spacer to push buttons to bottom
                const SizedBox(height: 40),

                // Action Buttons
                Column(
                  children: [
                    if (_mantra == null) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed:
                              _isGeneratingMantra ? null : _generateMantra,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isGeneratingMantra
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Generating...',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                )
                              : const Text(
                                  'Mantra',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: TextButton(
                        onPressed: _complete,
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withOpacity(0.3),
                            ),
                          ),
                        ),
                        child: Text(
                          _mantra != null ? 'Continue' : 'Skip',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Data Models
class TimerState {
  final int totalMinutes;
  final int remainingSeconds;
  final bool isRunning;
  final bool isCompleted;
  final Timer? timer;

  TimerState({
    this.totalMinutes = 10,
    int? remainingSeconds,
    this.isRunning = false,
    this.isCompleted = false,
    this.timer,
  }) : remainingSeconds = remainingSeconds ?? totalMinutes * 60;

  TimerState copyWith({
    int? totalMinutes,
    int? remainingSeconds,
    bool? isRunning,
    bool? isCompleted,
    Timer? timer,
  }) {
    return TimerState(
      totalMinutes: totalMinutes ?? this.totalMinutes,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
      isCompleted: isCompleted ?? this.isCompleted,
      timer: timer ?? this.timer,
    );
  }
}

class MeditationSession {
  final int timestamp;
  final int minutes;
  final String notes;
  final String mantra;

  MeditationSession({
    required this.timestamp,
    required this.minutes,
    required this.notes,
    required this.mantra,
  });

  Map<String, dynamic> toJson() {
    return {
      'ts': timestamp,
      'minutes': minutes,
      'notes': notes,
      'mantra': mantra,
    };
  }

  factory MeditationSession.fromJson(Map<String, dynamic> json) {
    return MeditationSession(
      timestamp: json['ts'] as int,
      minutes: json['minutes'] as int,
      notes: json['notes'] as String,
      mantra: json['mantra'] as String,
    );
  }
}

// Utility Functions
String formatMMSS(int totalSeconds) {
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

int clampMinutes(int minutes) {
  return minutes.clamp(0, 60);
}

bool isValidNotes(String notes) {
  return notes.trim().length <= 280;
}

String sanitizeMantra(String? response) {
  if (response == null || response.trim().isEmpty) {
    return 'Breathe';
  }

  final words = response.trim().split(RegExp(r'\s+'));
  if (words.length > 4) {
    return words.take(4).join(' ');
  }

  return response.trim();
}
