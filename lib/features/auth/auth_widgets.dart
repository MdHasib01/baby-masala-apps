import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/common.dart';

/// Shared layout for login / signup / verify (cream background, back button,
/// white card).
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.onBack, required this.children, this.footer});

  final VoidCallback onBack;
  final List<Widget> children;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onBack();
      },
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton.outlined(
                    onPressed: onBack,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.sand),
                      foregroundColor: AppColors.maroon,
                    ),
                    icon: const Icon(LucideIcons.arrowLeft, size: 18),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.sandA(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.sandA(0.6)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipOval(
                          child: Image.asset('assets/images/logo_icon.png', width: 16, height: 16),
                        ),
                        const SizedBox(width: 6),
                        Text('Baby Care', style: ts(11, weight: bold, color: AppColors.maroon)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...children,
              if (footer != null) ...[
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipOval(
                      child: Image.asset('assets/images/logo_icon.png', width: 14, height: 14),
                    ),
                    const SizedBox(width: 6),
                    Text(footer!, textAlign: TextAlign.center, style: ts(11, color: AppColors.grey500)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// WhatsApp / Email segmented toggle.
class ContactMethodToggle extends StatelessWidget {
  const ContactMethodToggle({super.key, required this.method, required this.onChanged});
  final String method; // 'whatsapp' | 'email'
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget btn(String value, IconData icon, String label) {
      final on = method == value;
      return Expanded(
        child: Material(
          color: on ? AppColors.maroon : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: on ? AppColors.maroon : AppColors.sand),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onChanged(value),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, size: 15, color: on ? Colors.white : AppColors.grey600),
                const SizedBox(width: 6),
                Text(label, style: ts(12, weight: bold, color: on ? Colors.white : AppColors.grey600)),
              ]),
            ),
          ),
        ),
      );
    }

    return Row(children: [
      btn('whatsapp', LucideIcons.phone, 'হোয়াটসঅ্যাপ'),
      const SizedBox(width: 8),
      btn('email', LucideIcons.mail, 'ইমেইল'),
    ]);
  }
}

/// Same rules as LoginScreen.tsx / SignUpScreen.tsx.
String? validateContact(String method, String contact) {
  final c = contact.trim();
  if (c.isEmpty) return method == 'whatsapp' ? 'হোয়াটসঅ্যাপ নম্বর লিখুন।' : 'ইমেইল ঠিকানা লিখুন।';
  if (method == 'whatsapp' && !RegExp(r'^01[0-9]{9}$').hasMatch(c)) {
    return 'সঠিক ১১ ডিজিটের মোবাইল নম্বর দিন (যেমন: 01712345678)।';
  }
  if (method == 'email' && !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(c)) {
    return 'সঠিক ইমেইল ঠিকানা দিন।';
  }
  return null;
}

class AuthHeading extends StatelessWidget {
  const AuthHeading({super.key, required this.title, required this.subtitle, this.note, this.icon});
  final String title;
  final String subtitle;
  final Widget? note;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (icon != null) ...[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: AppColors.sandA(0.4), shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.maroon, size: 26),
          ),
          const SizedBox(height: 12),
        ],
        Text(title, style: ts(22, weight: FontWeight.w800, color: AppColors.maroon)),
        const SizedBox(height: 4),
        Text(subtitle, style: ts(13, color: AppColors.grey600, height: 1.5)),
        if (note != null) ...[const SizedBox(height: 6), note!],
        const SizedBox(height: 20),
      ]);
}
