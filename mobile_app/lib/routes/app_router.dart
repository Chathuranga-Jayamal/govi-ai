import 'package:go_router/go_router.dart';

import '../core/storage/token_storage.dart';
import '../core/widgets/main_shell.dart';
import '../features/advisory/domain/advisory_topic.dart';
import '../features/advisory/presentation/screens/advisory_chat_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/disease_detection/domain/capture_result_args.dart';
import '../features/disease_detection/presentation/screens/capture_screen.dart';
import '../features/disease_detection/presentation/screens/result_screen.dart';
import '../features/marketplace/domain/payhere_checkout.dart';
import '../features/marketplace/domain/product.dart';
import '../features/marketplace/presentation/screens/cart_screen.dart';
import '../features/marketplace/presentation/screens/checkout_screen.dart';
import '../features/marketplace/presentation/screens/order_confirmation_screen.dart';
import '../features/marketplace/presentation/screens/payhere_checkout_screen.dart';
import '../features/marketplace/presentation/screens/product_detail_screen.dart';
import '../features/marketplace/presentation/screens/product_list_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';

final TokenStorage _tokenStorage = TokenStorage();

const List<String> _authRoutes = ['/login', '/register'];

final GoRouter appRouter = GoRouter(
  initialLocation: '/dashboard',
  redirect: (context, state) async {
    final bool isAuthRoute = _authRoutes.contains(state.matchedLocation);
    final String? token = await _tokenStorage.readToken();
    final bool isLoggedIn = token != null;

    if (!isLoggedIn && !isAuthRoute) return '/login';
    if (isLoggedIn && isAuthRoute) return '/dashboard';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/capture/result',
      builder: (context, state) {
        final CaptureResultArgs args = state.extra! as CaptureResultArgs;
        return ResultScreen(image: args.image, result: args.result);
      },
    ),
    GoRoute(
      path: '/marketplace/product',
      builder: (context, state) =>
          ProductDetailScreen(product: state.extra! as Product),
    ),
    GoRoute(
      path: '/marketplace/cart',
      builder: (context, state) => const CartScreen(),
    ),
    GoRoute(
      path: '/marketplace/checkout',
      builder: (context, state) => const CheckoutScreen(),
    ),
    GoRoute(
      path: '/marketplace/order-confirmation',
      builder: (context, state) =>
          OrderConfirmationScreen(orderNumber: state.extra! as String),
    ),
    GoRoute(
      path: '/marketplace/payhere-checkout',
      builder: (context, state) =>
          PayHereCheckoutScreen(checkout: state.extra! as PayHereCheckoutData),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) =>
          ProfileScreen(scrollToOrderHistory: state.extra as bool? ?? false),
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
                initialTopic: state.extra as AdvisoryTopic?,
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
