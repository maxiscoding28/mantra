import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mantra/main.dart';

void main() {
  group('Mantra App Tests', () {
    testWidgets('Timer initializes to 10 minutes', (WidgetTester tester) async {
      await tester.pumpWidget(const MantraApp());

      // Find the timer display
      expect(find.text('10:00'), findsOneWidget);
      expect(find.text('10 min'), findsOneWidget);
    });

    testWidgets('Notes field is hidden before completion',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MantraApp());

      // Notes input should not be visible initially
      expect(find.text('Share your insights (optional)'), findsNothing);
      expect(find.text('Generate Mantra'), findsNothing);
    });

    testWidgets('Start button is enabled initially',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MantraApp());

      // Start button should be enabled
      final startButton = find.text('Start');
      expect(startButton, findsOneWidget);

      final startButtonWidget = tester.widget<ElevatedButton>(
        find
            .ancestor(of: startButton, matching: find.byType(ElevatedButton))
            .first,
      );
      expect(startButtonWidget.onPressed, isNotNull);
    });
  });

  group('Utility Functions Tests', () {
    test('formatMMSS formats time correctly', () {
      expect(formatMMSS(0), '00:00');
      expect(formatMMSS(60), '01:00');
      expect(formatMMSS(125), '02:05');
      expect(formatMMSS(3661), '61:01');
    });

    test('clampMinutes clamps values correctly', () {
      expect(clampMinutes(-5), 0);
      expect(clampMinutes(0), 0);
      expect(clampMinutes(30), 30);
      expect(clampMinutes(60), 60);
      expect(clampMinutes(100), 60);
    });

    test('isValidNotes validates notes length', () {
      expect(isValidNotes(''), true);
      expect(isValidNotes('Short note'), true);
      expect(isValidNotes('a' * 280), true);
      expect(isValidNotes('a' * 281), false);
      expect(isValidNotes('  trimmed  '), true);
    });

    test('sanitizeMantra handles various inputs', () {
      expect(sanitizeMantra(null), 'Breathe');
      expect(sanitizeMantra(''), 'Breathe');
      expect(sanitizeMantra('  '), 'Breathe');
      expect(sanitizeMantra('Peace'), 'Peace');
      expect(sanitizeMantra('Be Present Now'), 'Be Present Now');
      expect(
          sanitizeMantra('This is a very long mantra that exceeds four words'),
          'This is a very');
    });
  });

  group('MeditationSession Tests', () {
    test('MeditationSession serialization works correctly', () {
      final session = MeditationSession(
        timestamp: 1712345678901,
        minutes: 10,
        notes: 'Test notes',
        mantra: 'Breathe',
      );

      final json = session.toJson();
      expect(json['ts'], 1712345678901);
      expect(json['minutes'], 10);
      expect(json['notes'], 'Test notes');
      expect(json['mantra'], 'Breathe');

      final restored = MeditationSession.fromJson(json);
      expect(restored.timestamp, session.timestamp);
      expect(restored.minutes, session.minutes);
      expect(restored.notes, session.notes);
      expect(restored.mantra, session.mantra);
    });
  });
}
