import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'state/app_data_controller.dart';
import 'state/session_controller.dart';

class BabyCareApp extends ConsumerStatefulWidget {
  const BabyCareApp({super.key});

  @override
  ConsumerState<BabyCareApp> createState() => _BabyCareAppState();
}

class _BabyCareAppState extends ConsumerState<BabyCareApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() => ref.read(sessionProvider.notifier).start());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Sync rules (see MOBILE_SYNC.md):
  /// * backgrounded → flush pending debounced saves immediately
  /// * foregrounded → re-bootstrap so edits made on the web show up
  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (ref.read(sessionProvider).stage != AuthStage.app) return;
    final data = ref.read(appDataProvider.notifier);
    if (s == AppLifecycleState.paused || s == AppLifecycleState.hidden) {
      data.flush();
    } else if (s == AppLifecycleState.resumed) {
      data.refresh().catchError((Object e) => debugPrint('[resume refresh] $e'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Baby Care',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: const Locale('bn', 'BD'),
      supportedLocales: const [Locale('bn', 'BD'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
