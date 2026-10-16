import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `ActiveTab` in App.tsx.
enum HomeTab { home, baby, friends, rewards, shop }

class HomeTabController extends Notifier<HomeTab> {
  @override
  HomeTab build() => HomeTab.home;
  void select(HomeTab t) => state = t;
}

final homeTabProvider = NotifierProvider<HomeTabController, HomeTab>(HomeTabController.new);
