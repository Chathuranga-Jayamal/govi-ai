import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../core/widgets/main_shell.dart';
import '../features/advisory/presentation/screens/advisory_chat_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/disease_detection/presentation/screens/capture_screen.dart';
import '../features/disease_detection/presentation/screens/result_screen.dart';
import '../features/marketplace/presentation/screens/product_list_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/capture/result',
      builder: (context, state) =>
          ResultScreen(image: state.extra! as XFile),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/capture',
              builder: (context, state) => const CaptureScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/advisory',
              builder: (context, state) => AdvisoryChatScreen(
                initialTopic: state.extra as String?,
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/marketplace',
              builder: (context, state) => const ProductListScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
