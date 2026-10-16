import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/common.dart';
import '../../state/session_controller.dart';

/// Port of components/auth/WelcomeScreen.tsx.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.read(sessionProvider.notifier);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const Spacer(),
            Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
              Container(
                width: 112,
                height: 112,
                // No blurred BoxShadow here: on the Android emulator's Impeller
                // backend it made the heart, badge and wordmark vanish.
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.brandGradient,
                  border: Border.all(color: AppColors.sandA(0.6), width: 4),
                ),
                child: const Icon(LucideIcons.heart, color: Colors.white, size: 52),
              ),
              Positioned(
                bottom: -10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(20)),
                  child: Text('১০০% নিরাপদ', style: ts(10, weight: bold, color: AppColors.maroon)),
                ),
              ),
            ]),
            const SizedBox(height: 32),
            const Wordmark(size: 34, center: true),
            const SizedBox(height: 16),
            Text(
              'বাংলাদেশের মায়েদের জন্য আস্থার সাথে তৈরি শিশুর পুষ্টি, সঠিক পরিচর্যা ও মমতাময়ী কমিউনিটি প্ল্যাটফর্ম।',
              textAlign: TextAlign.center,
              style: ts(13, color: AppColors.grey600, height: 1.6),
            ),
            const SizedBox(height: 20),
            _feature(LucideIcons.shieldCheck, 'বিশেষজ্ঞ নির্দেশিকা ও বয়সভিত্তিক চার্ট'),
            const SizedBox(height: 8),
            _feature(LucideIcons.sparkles, 'প্রিমিয়াম হার্বস ও রিওয়ার্ডস ক্লাব'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => session.goTo(AuthStage.signup),
                child: const Text('অ্যাকাউন্ট খুলুন'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(backgroundColor: Colors.white),
                onPressed: () => session.goTo(AuthStage.login),
                child: const Text('লগইন করুন'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _feature(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.sand),
        ),
        child: Row(children: [
          Icon(icon, size: 16, color: AppColors.olive),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: ts(12, weight: semi))),
        ]),
      );
}
