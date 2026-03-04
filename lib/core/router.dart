import 'package:go_router/go_router.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/splash_screen.dart';
import '../presentation/screens/choice_screen.dart';
import '../presentation/screens/banker_calendar_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/choice', builder: (context, state) => const ChoiceScreen()),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/banker-calendar', builder: (context, state) => const BankerCalendarScreen()),
  ],
);
