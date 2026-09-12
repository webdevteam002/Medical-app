import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medstudy/features/exams/data/models/exam_question_model.dart';
import 'package:medstudy/features/exams/data/models/exam_start_session_model.dart';
import 'package:medstudy/features/exams/data/models/question_option_model.dart';
import 'package:medstudy/features/exams/presentation/pages/exam_session_page.dart';

void main() {
  Widget createWidgetUnderTest(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  group('Day 43-46 Exam Session Unit & Widget Tests', () {
    test('1. ExamStartSessionModel parses exact NestJS JSON response correctly',
        () {
      final json = {
        'attemptId': 'att_123',
        'durationMinutes': 60,
        'startedAt': '2026-09-03T09:00:00.000Z',
        'questions': [
          {
            'id': 'q1',
            'stem': 'Which nerve supplies the quadriceps femoris?',
            'options': [
              {'id': 'a', 'text': 'Femoral nerve'},
              {'id': 'b', 'text': 'Obturator nerve'},
              {'id': 'c', 'text': 'Sciatic nerve'},
              {'id': 'd', 'text': 'Tibial nerve'},
            ],
            'imageKey': null,
          },
        ],
      };

      final session = ExamStartSessionModel.fromJson(json);

      expect(session.attemptId, equals('att_123'));
      expect(session.durationMinutes, equals(60));
      expect(session.questions.length, equals(1));
      expect(session.questions.first.stem,
          equals('Which nerve supplies the quadriceps femoris?'));
      expect(session.questions.first.options.length, equals(4));
      expect(
          session.questions.first.options.first.text, equals('Femoral nerve'));
    });

    testWidgets(
        '2. ExamSessionPage renders question stem, option tiles, and progress bar',
        (WidgetTester tester) async {
      final session = ExamStartSessionModel(
        attemptId: 'att_101',
        durationMinutes: 45,
        startedAt: DateTime.now(),
        questions: const [
          ExamQuestionModel(
            id: 'q1',
            stem: 'Which structure passes through the saphenous opening?',
            options: [
              QuestionOptionModel(id: 'a', text: 'Great saphenous vein'),
              QuestionOptionModel(id: 'b', text: 'Small saphenous vein'),
              QuestionOptionModel(id: 'c', text: 'Femoral artery'),
              QuestionOptionModel(id: 'd', text: 'Deep femoral vein'),
            ],
          ),
          ExamQuestionModel(
            id: 'q2',
            stem: 'What is the action of the gluteus maximus?',
            options: [
              QuestionOptionModel(
                  id: 'a', text: 'Hip extension & lateral rotation'),
              QuestionOptionModel(id: 'b', text: 'Hip flexion'),
              QuestionOptionModel(id: 'c', text: 'Hip abduction'),
              QuestionOptionModel(id: 'd', text: 'Medial rotation'),
            ],
          ),
        ],
      );

      await tester.pumpWidget(createWidgetUnderTest(
        ExamSessionPage(
          examTitle: 'Anatomy Mock Exam',
          session: session,
        ),
      ));

      expect(find.text('Anatomy Mock Exam'), findsOneWidget);
      expect(find.text('Question 1 of 2'), findsOneWidget);
      expect(find.text('Which structure passes through the saphenous opening?'),
          findsOneWidget);
      expect(find.text('Great saphenous vein'), findsOneWidget);
      expect(find.text('Small saphenous vein'), findsOneWidget);
    });

    testWidgets('3. Tapping an option selects it and updates selection state',
        (WidgetTester tester) async {
      final session = ExamStartSessionModel(
        attemptId: 'att_101',
        durationMinutes: 45,
        startedAt: DateTime.now(),
        questions: const [
          ExamQuestionModel(
            id: 'q1',
            stem: 'Which structure passes through the saphenous opening?',
            options: [
              QuestionOptionModel(id: 'a', text: 'Great saphenous vein'),
              QuestionOptionModel(id: 'b', text: 'Small saphenous vein'),
            ],
          ),
        ],
      );

      await tester.pumpWidget(createWidgetUnderTest(
        ExamSessionPage(
          examTitle: 'Anatomy Mock Exam',
          session: session,
        ),
      ));

      expect(find.text('Unanswered'), findsOneWidget);

      await tester.tap(find.text('Great saphenous vein'));
      await tester.pump();

      expect(find.text('Answered'), findsOneWidget);
    });

    testWidgets('4. Next and Previous buttons navigate between questions',
        (WidgetTester tester) async {
      final session = ExamStartSessionModel(
        attemptId: 'att_101',
        durationMinutes: 45,
        startedAt: DateTime.now(),
        questions: const [
          ExamQuestionModel(
            id: 'q1',
            stem: 'Question 1 Stem Text',
            options: [
              QuestionOptionModel(id: 'a', text: 'Option A'),
            ],
          ),
          ExamQuestionModel(
            id: 'q2',
            stem: 'Question 2 Stem Text',
            options: [
              QuestionOptionModel(id: 'a', text: 'Option B'),
            ],
          ),
        ],
      );

      await tester.pumpWidget(createWidgetUnderTest(
        ExamSessionPage(
          examTitle: 'Anatomy Mock Exam',
          session: session,
        ),
      ));

      expect(find.text('Question 1 Stem Text'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pump();

      expect(find.text('Question 2 Stem Text'), findsOneWidget);

      await tester.tap(find.text('Previous'));
      await tester.pump();

      expect(find.text('Question 1 Stem Text'), findsOneWidget);
    });

    testWidgets(
        '5. Day 45: Persistent countdown timer initializes with formatted time',
        (WidgetTester tester) async {
      final session = ExamStartSessionModel(
        attemptId: 'att_101',
        durationMinutes: 60,
        startedAt: DateTime.now(),
        questions: const [
          ExamQuestionModel(
            id: 'q1',
            stem: 'Stem Text',
            options: [QuestionOptionModel(id: 'a', text: 'Opt')],
          ),
        ],
      );

      await tester.pumpWidget(createWidgetUnderTest(
        ExamSessionPage(
          examTitle: 'Anatomy Mock Exam',
          session: session,
        ),
      ));

      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.timer_rounded), findsOneWidget);
    });

    testWidgets(
        '6. Day 46: Question palette opens grid and allows direct question jumping',
        (WidgetTester tester) async {
      final session = ExamStartSessionModel(
        attemptId: 'att_101',
        durationMinutes: 60,
        startedAt: DateTime.now(),
        questions: const [
          ExamQuestionModel(
            id: 'q1',
            stem: 'Question One Stem',
            options: [QuestionOptionModel(id: 'a', text: 'Opt A')],
          ),
          ExamQuestionModel(
            id: 'q2',
            stem: 'Question Two Stem',
            options: [QuestionOptionModel(id: 'a', text: 'Opt B')],
          ),
          ExamQuestionModel(
            id: 'q3',
            stem: 'Question Three Stem',
            options: [QuestionOptionModel(id: 'a', text: 'Opt C')],
          ),
        ],
      );

      await tester.pumpWidget(createWidgetUnderTest(
        ExamSessionPage(
          examTitle: 'Anatomy Mock Exam',
          session: session,
        ),
      ));

      expect(find.text('Question One Stem'), findsOneWidget);

      // Open palette bottom sheet
      await tester.tap(find.byIcon(Icons.grid_view_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Question Palette'), findsOneWidget);
      expect(find.text('Unanswered (3)'), findsOneWidget);

      // Tap question 3 tile in grid
      await tester.tap(find.text('3'));
      await tester.pumpAndSettle();

      expect(find.text('Question Three Stem'), findsOneWidget);
    });

    testWidgets(
        '7. Day 72 Task 2: Desktop layout (>= 900px) renders persistent side-by-side palette',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final session = ExamStartSessionModel(
        attemptId: 'att_101',
        durationMinutes: 45,
        startedAt: DateTime.now(),
        questions: const [
          ExamQuestionModel(
            id: 'q1',
            stem: 'Desktop Question 1 Stem',
            options: [
              QuestionOptionModel(id: 'a', text: 'Desktop Opt A'),
              QuestionOptionModel(id: 'b', text: 'Desktop Opt B'),
            ],
          ),
          ExamQuestionModel(
            id: 'q2',
            stem: 'Desktop Question 2 Stem',
            options: [
              QuestionOptionModel(id: 'a', text: 'Desktop Opt C'),
            ],
          ),
        ],
      );

      await tester.pumpWidget(createWidgetUnderTest(
        ExamSessionPage(
          examTitle: 'Desktop Exam Test',
          session: session,
        ),
      ));
      await tester.pumpAndSettle();

      // Side-by-side persistent Question Palette title should be visible without opening bottom sheet
      expect(find.text('Question Palette'), findsOneWidget);
      // Grid view icon button in app bar is hidden on desktop layout
      expect(find.byIcon(Icons.grid_view_rounded), findsNothing);

      // Tapping tile '2' in persistent desktop palette jumps to Question 2
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();

      expect(find.text('Desktop Question 2 Stem'), findsOneWidget);
    });

    testWidgets(
        '8. Day 73 Task 3: Desktop Keyboard Navigation - ArrowLeft, ArrowRight, P, N, F, 1-5, A-E, boundaries & submission safety',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final session = ExamStartSessionModel(
        attemptId: 'att_keyboard_test',
        durationMinutes: 60,
        startedAt: DateTime.now(),
        questions: const [
          ExamQuestionModel(
            id: 'q1',
            stem: 'Question 1 Keyboard Stem',
            options: [
              QuestionOptionModel(id: 'a', text: 'Option A1'),
              QuestionOptionModel(id: 'b', text: 'Option B1'),
              QuestionOptionModel(id: 'c', text: 'Option C1'),
              QuestionOptionModel(id: 'd', text: 'Option D1'),
            ],
          ),
          ExamQuestionModel(
            id: 'q2',
            stem: 'Question 2 Keyboard 5-Option Stem',
            options: [
              QuestionOptionModel(id: 'a', text: 'Option A2'),
              QuestionOptionModel(id: 'b', text: 'Option B2'),
              QuestionOptionModel(id: 'c', text: 'Option C2'),
              QuestionOptionModel(id: 'd', text: 'Option D2'),
              QuestionOptionModel(id: 'e', text: 'Option E2'),
            ],
          ),
        ],
      );

      await tester.pumpWidget(createWidgetUnderTest(
        ExamSessionPage(
          examTitle: 'Keyboard Exam Test',
          session: session,
        ),
      ));
      await tester.pumpAndSettle();

      // 1. Initial State: Question 1 displayed, Unanswered (2)
      expect(find.text('Question 1 Keyboard Stem'), findsOneWidget);
      expect(find.text('Unanswered (2)'), findsOneWidget);

      // 2. Press ArrowLeft at first question -> boundary preserved (remains Q1)
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(find.text('Question 1 Keyboard Stem'), findsOneWidget);

      // 3. Press P at first question -> boundary preserved (remains Q1)
      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      await tester.pumpAndSettle();
      expect(find.text('Question 1 Keyboard Stem'), findsOneWidget);

      // 4. Press '1' -> selects option 1 (Option A1), palette updates to Answered (1)
      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.pumpAndSettle();
      expect(find.text('Answered (1)'), findsOneWidget);

      // 5. Press 'B' -> changes selection to option 2 (Option B1)
      await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
      await tester.pumpAndSettle();
      expect(find.text('Answered (1)'), findsOneWidget);

      // 6. Press '5' on 4-option question -> does nothing (out of bounds)
      await tester.sendKeyEvent(LogicalKeyboardKey.digit5);
      await tester.pumpAndSettle();

      // 7. Press 'F' -> toggles flag for review, palette updates to Flagged (1)
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.pumpAndSettle();
      expect(find.text('Flagged (1)'), findsOneWidget);

      // 8. Press ArrowRight -> moves to Question 2
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text('Question 2 Keyboard 5-Option Stem'), findsOneWidget);

      // 9. Press 'E' on 5-option question -> selects option 5 (Option E2)
      await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
      await tester.pumpAndSettle();
      expect(find.text('Answered (2)'), findsOneWidget);

      // 10. Press ArrowRight on final question -> boundary preserved, does NOT submit exam automatically
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text('Question 2 Keyboard 5-Option Stem'), findsOneWidget);
      expect(find.text('Submit Exam?'), findsNothing);

      // 11. Press 'N' on final question -> boundary preserved, does NOT submit exam automatically
      await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
      await tester.pumpAndSettle();
      expect(find.text('Question 2 Keyboard 5-Option Stem'), findsOneWidget);
      expect(find.text('Submit Exam?'), findsNothing);

      // 12. Press 'P' -> moves back to Question 1
      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      await tester.pumpAndSettle();
      expect(find.text('Question 1 Keyboard Stem'), findsOneWidget);
    });

    testWidgets(
        '9. Day 74 Task 4: Desktop Hover & Focus states - Option tile InkWell renders mouseCursor, hoverColor & focusColor',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final session = ExamStartSessionModel(
        attemptId: 'att_task4_test',
        durationMinutes: 45,
        startedAt: DateTime.now(),
        questions: const [
          ExamQuestionModel(
            id: 'q1',
            stem: 'Task 4 Interaction Polish Question Stem',
            options: [
              QuestionOptionModel(id: 'a', text: 'Interactive Option A'),
              QuestionOptionModel(id: 'b', text: 'Interactive Option B'),
            ],
          ),
        ],
      );

      await tester.pumpWidget(createWidgetUnderTest(
        ExamSessionPage(
          examTitle: 'Task 4 Polish Test',
          session: session,
        ),
      ));
      await tester.pumpAndSettle();

      // Find option tile InkWell
      final inkWellFinder =
          find.widgetWithText(InkWell, 'Interactive Option A');
      expect(inkWellFinder, findsOneWidget);

      final inkWell = tester.widget<InkWell>(inkWellFinder);
      expect(inkWell.mouseCursor, equals(SystemMouseCursors.click));
      expect(inkWell.hoverColor, isNotNull);
      expect(inkWell.focusColor, isNotNull);

      // Verify selecting option A updates UI and preserves security (no correct/incorrect feedback displayed)
      await tester.tap(inkWellFinder);
      await tester.pumpAndSettle();

      expect(find.text('Answered'), findsOneWidget);
      expect(find.text('Correct'), findsNothing);
      expect(find.text('Incorrect'), findsNothing);
    });
  });
}
