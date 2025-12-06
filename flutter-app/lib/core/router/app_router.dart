import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/task.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/screens/login_screen.dart';
import '../../presentation/screens/verify_code_screen.dart';
import '../../presentation/screens/home_screen_updated.dart';
import '../../presentation/screens/task_detail_screen.dart';
import '../../presentation/screens/chat_selection_screen.dart';
import '../../presentation/screens/splash_screen.dart';

// GoRouter listenable for auth state changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(this.ref) {
    ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }

  final Ref ref;
}

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    refreshListenable: GoRouterRefreshStream(ref),
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuthenticated = authState.isAuthenticated;
      final isOnSplash = state.matchedLocation == '/splash';
      final isOnLogin = state.matchedLocation == '/login';
      final isOnVerify = state.matchedLocation.startsWith('/verify');

      // Don't redirect from splash
      if (isOnSplash) {
        return null;
      }

      // Redirect to login if not authenticated
      if (!isAuthenticated && !isOnLogin && !isOnVerify) {
        return '/login';
      }

      // Redirect to home if authenticated and on login
      if (isAuthenticated && (isOnLogin || isOnVerify)) {
        return '/home';
      }

      return null;
    },
    routes: [
      // Splash Screen
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Login Screen
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Verify Code Screen
      GoRoute(
        path: '/verify',
        name: 'verify',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final phoneNumber = extra?['phoneNumber'] as String? ?? '';
          final phoneCodeHash = extra?['phoneCodeHash'] as String? ?? '';

          return VerifyCodeScreen(
            phoneNumber: phoneNumber,
            phoneCodeHash: phoneCodeHash,
          );
        },
      ),

      // Home Screen
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreenUpdated(),
      ),

      // Task Detail Screen
      GoRoute(
        path: '/task/:id',
        name: 'task-detail',
        builder: (context, state) {
          final task = state.extra as Task;
          return TaskDetailScreen(task: task);
        },
      ),

      // Chat Selection Screen
      GoRoute(
        path: '/chats',
        name: 'chat-selection',
        builder: (context, state) => const ChatSelectionScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Ошибка')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Страница не найдена',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(state.error.toString()),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('На главную'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
});
