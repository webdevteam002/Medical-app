import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/study/presentation/pages/bookmarks_page.dart';
import '../../features/study/presentation/pages/materials_page.dart';
import '../../features/study/presentation/pages/offline_materials_page.dart';
import '../../features/study/presentation/pages/pdf_viewer_page.dart';
import '../../features/study/presentation/pages/subjects_page.dart';
import '../../features/study/presentation/pages/topics_page.dart';

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
    ],
  );
}
