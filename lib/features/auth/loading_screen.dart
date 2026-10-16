import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/common.dart';
import '../../state/session_controller.dart';

/// Loading / error screen shown while `GET /bootstrap` runs (App.tsx).
class LoadingScreen extends ConsumerWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sessionProvider);
    final session = ref.read(sessionProvider.notifier);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: s.loadError != null
              ? Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(s.loadError!, textAlign: TextAlign.center, style: ts(14, weight: semi, color: AppColors.maroon)),
                  const SizedBox(height: 16),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    ElevatedButton(onPressed: session.loadApp, child: const Text('আবার চেষ্টা করুন')),
                    const SizedBox(width: 8),
                    OutlinedButton(onPressed: session.logout, child: const Text('লগআউট')),
                  ]),
                ])
              : Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: AppColors.sand, width: 2),
                    ),
                    child: ClipOval(
                      child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Wordmark(size: 24, center: true),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(color: AppColors.maroon),
                  const SizedBox(height: 12),
                  Text('লোড হচ্ছে...', style: ts(12, color: AppColors.grey600)),
                ]),
        ),
      ),
    );
  }
}
