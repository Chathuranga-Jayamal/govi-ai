import 'package:go_router/go_router.dart';

import '../features/advisory/presentation/screens/advisory_chat_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/disease_detection/presentation/screens/capture_screen.dart';
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
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/capture',
      builder: (context, state) => const CaptureScreen(),
    ),
    GoRoute(
      path: '/advisory',
      builder: (context, state) => const AdvisoryChatScreen(),
    ),
    GoRoute(
      path: '/marketplace',
      builder: (context, state) => const ProductListScreen(),
    ),
  ],
);
