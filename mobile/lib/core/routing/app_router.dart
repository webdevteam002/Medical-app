import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/exams/data/models/exam_attempt_review_model.dart';
import '../../features/exams/data/models/exam_model.dart';
import '../../features/exams/data/models/exam_start_session_model.dart';
import '../../features/exams/data/models/exam_submit_result_model.dart';
import '../../features/exams/presentation/pages/exam_detail_page.dart';
import '../../features/exams/presentation/pages/exam_history_page.dart';
import '../../features/exams/presentation/pages/exam_review_page.dart';
import '../../features/exams/presentation/pages/exam_session_page.dart';
import '../../features/exams/presentation/pages/exam_submit_result_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/study/presentation/pages/bookmarks_page.dart';
import '../../features/study/presentation/pages/materials_page.dart';
import '../../features/study/presentation/pages/offline_materials_page.dart';
import '../../features/study/presentation/pages/pdf_viewer_page.dart';
import '../../features/study/presentation/pages/subjects_page.dart';
import '../../features/study/presentation/pages/topics_page.dart';
import '../../features/subscriptions/presentation/pages/subscription_page.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/bookmarks',
        name: 'bookmarks',
        builder: (context, state) => const BookmarksPage(),
      ),
      GoRoute(
        path: '/offline-materials',
        name: 'offlineMaterials',
        builder: (context, state) => const OfflineMaterialsPage(),
      ),
      GoRoute(
        path: '/subscriptions',
        name: 'subscriptions',
        builder: (context, state) => const SubscriptionPage(),
      ),
      GoRoute(
        path: '/subjects/:yearSlug',
        name: 'subjects',
        builder: (context, state) {
          final yearSlug = state.pathParameters['yearSlug'] ?? '';
          final yearName = state.extra as String?;
          return SubjectsPage(
            yearSlug: yearSlug,
            yearName: yearName,
          );
        },
      ),
      GoRoute(
        path: '/subjects/:subjectId/topics',
        name: 'topics',
        builder: (context, state) {
          final subjectId = state.pathParameters['subjectId'] ?? '';
          final subjectName = state.extra as String?;
          return TopicsPage(
            subjectId: subjectId,
            subjectName: subjectName,
          );
        },
      ),
      GoRoute(
        path: '/subjects/:subjectId/topics/:topicId/materials',
        name: 'materials',
        builder: (context, state) {
          final subjectId = state.pathParameters['subjectId'] ?? '';
          final topicId = state.pathParameters['topicId'] ?? '';
          final topicName = state.extra as String?;
          return MaterialsPage(
            subjectId: subjectId,
            topicId: topicId,
            topicName: topicName,
          );
        },
      ),
      GoRoute(
        path: '/materials/:materialId/view',
        name: 'pdfViewer',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final title = extra['title'] as String? ?? 'PDF Document';
          final pdfUrl = extra['pdfUrl'] as String? ?? '';
          final watermarkText = extra['watermarkText'] as String?;
          return PdfViewerPage(
            title: title,
            pdfUrl: pdfUrl,
            watermarkText: watermarkText,
          );
        },
      ),
      GoRoute(
        path: '/exams/history',
        name: 'examHistory',
        builder: (context, state) => const ExamHistoryPage(),
      ),
      GoRoute(
        path: '/exams/:examId/detail',
        name: 'examDetail',
        builder: (context, state) {
          final examId = state.pathParameters['examId'] ?? '';
          final exam = state.extra as ExamModel? ??
              ExamModel(
                id: examId,
                title: 'Exam Detail',
                durationMinutes: 60,
                questionCount: 0,
              );
          return ExamDetailPage(exam: exam);
        },
      ),
      GoRoute(
        path: '/exams/session/:attemptId',
        name: 'examSession',
        builder: (context, state) {
          final attemptId = state.pathParameters['attemptId'] ?? '';
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final examTitle = extra['examTitle'] as String? ?? 'Exam Session';
          final session = extra['session'] as ExamStartSessionModel? ??
              ExamStartSessionModel(
                attemptId: attemptId,
                durationMinutes: 60,
                startedAt: DateTime.now(),
                questions: const [],
              );
          return ExamSessionPage(
            examTitle: examTitle,
            session: session,
          );
        },
      ),
      GoRoute(
        path: '/exams/results',
        name: 'examResults',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final examTitle = extra['examTitle'] as String? ?? 'Exam Results';
          final result = extra['result'] as ExamSubmitResultModel? ??
              const ExamSubmitResultModel(
                score: 0,
                total: 0,
                percentage: 0.0,
                details: [],
              );
          return ExamSubmitResultPage(
            examTitle: examTitle,
            result: result,
          );
        },
      ),
      GoRoute(
        path: '/exams/attempts/:attemptId/review',
        name: 'examReview',
        builder: (context, state) {
          final attemptId = state.pathParameters['attemptId'] ?? '';
          final initialReview = state.extra as ExamAttemptReviewModel?;
          return ExamReviewPage(
            attemptId: attemptId,
            initialReview: initialReview,
          );
        },
      ),
    ],
  );
}
