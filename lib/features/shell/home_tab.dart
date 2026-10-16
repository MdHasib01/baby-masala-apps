import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom-navigation tabs. Web's 5th top tab (ফ্রেন্ডস) lives under
/// "আরও" (More) on mobile and opens as its own screen (`Routes.friends`).
enum HomeTab { home, baby, rewards, shop }

class HomeTabController extends Notifier<HomeTab> {
  @override
  HomeTab build() => HomeTab.home;
  void select(HomeTab t) => state = t;
}

final homeTabProvider = NotifierProvider<HomeTabController, HomeTab>(HomeTabController.new);
