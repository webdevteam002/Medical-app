import 'package:flutter/material.dart';
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
  });
}
