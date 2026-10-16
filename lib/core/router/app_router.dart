import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/social.dart';
import '../../features/admin/admin_screen.dart';
import '../../features/auth/loading_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/membership_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/auth/verify_screen.dart';
import '../../features/auth/welcome_screen.dart';
import '../../features/doctor/ask_doctor_screen.dart';
import '../../features/friends/friends_tab.dart';
import '../../features/messenger/messenger_screen.dart';
import '../../features/profile/address_manager_screen.dart';
import '../../features/profile/settings_screen.dart';
import '../../features/recipes/recipes_screen.dart';
import '../../features/shell/home_shell.dart';
import '../../features/timeline/user_timeline_screen.dart';
import '../../state/session_controller.dart';

/// Route paths. Full-screen pages match `currentScreen` / `activeTimelineTarget`
/// in frontend/src/App.tsx.
class Routes {
  static const loading = '/loading';
  static const welcome = '/welcome';
  static const login = '/login';
  static const signup = '/signup';
  static const verify = '/verify';
  static const membership = '/membership';
  static const home = '/home';
  static const recipes = '/recipes';
  static const messenger = '/messenger';
  static const doctor = '/doctor';
  static const timeline = '/timeline';
  static const admin = '/admin';
  static const settings = '/settings';
  static const addresses = '/addresses';
  static const friends = '/friends';
}

const _stageRoute = {
  AuthStage.starting: Routes.loading,
  AuthStage.loading: Routes.loading,
  AuthStage.welcome: Routes.welcome,
  AuthStage.login: Routes.login,
  AuthStage.signup: Routes.signup,
  AuthStage.verify: Routes.verify,
  AuthStage.membership: Routes.membership,
};

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionProvider.select((s) => s.stage), (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.loading,
    refreshListenable: refresh,
    redirect: (context, state) {
      final stage = ref.read(sessionProvider).stage;
      final loc = state.matchedLocation;
      final forced = _stageRoute[stage];
      if (forced != null) return loc == forced ? null : forced;
      // Signed in: keep the user out of the auth screens.
      if (_stageRoute.values.contains(loc)) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(path: Routes.loading, builder: (_, _) => const LoadingScreen()),
      GoRoute(path: Routes.welcome, builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: Routes.signup, builder: (_, _) => const SignUpScreen()),
      GoRoute(path: Routes.verify, builder: (_, _) => const VerifyScreen()),
      GoRoute(path: Routes.membership, builder: (_, _) => const MembershipScreen()),
      GoRoute(path: Routes.home, builder: (_, _) => const HomeShell()),
      GoRoute(path: Routes.recipes, builder: (_, s) => RecipesScreen(initialRecipeId: s.extra as String?)),
      GoRoute(path: Routes.messenger, builder: (_, s) => MessengerScreen(initialFriend: s.extra as FriendUser?)),
      GoRoute(path: Routes.doctor, builder: (_, _) => const AskDoctorScreen()),
      GoRoute(path: Routes.timeline, builder: (_, s) => UserTimelineScreen(target: s.extra as TimelineTarget)),
      GoRoute(path: Routes.admin, builder: (_, _) => const AdminScreen()),
      GoRoute(path: Routes.settings, builder: (_, _) => const SettingsScreen()),
      GoRoute(path: Routes.addresses, builder: (_, _) => const AddressManagerScreen()),
      GoRoute(path: Routes.friends, builder: (_, _) => const FriendsScreen()),
    ],
  );
});
