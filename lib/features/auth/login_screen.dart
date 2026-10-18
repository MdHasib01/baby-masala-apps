import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/api_exception.dart';
import '../../core/config/env.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/bn_digits.dart';
import '../../shared/widgets/common.dart';
import '../../state/session_controller.dart';
import 'auth_widgets.dart';

/// Port of components/auth/LoginScreen.tsx.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String _method = defaultContactMethod;
  final _contact = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _contact.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final contact = toAsciiDigits(_contact.text.trim());
    final err = validateContact(_method, contact);
    setState(() => _error = err);
    if (err != null) return;
    try {
      await ref.read(sessionProvider.notifier).requestLoginOtp(contact);
    } catch (e) {
      if (mounted) setState(() => _error = e is ApiException ? e.message : 'কোড পাঠানো যায়নি। আবার চেষ্টা করুন।');
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.read(sessionProvider.notifier);
    return AuthScaffold(
      onBack: () => session.goTo(AuthStage.welcome),
      footer: 'Baby Care by Baby Masala',
      children: [
        const AuthHeading(
          title: 'লগইন করুন',
          subtitle: 'আপনার অ্যাকাউন্টের ইমেইল দিন, আমরা সেখানে একটি যাচাই কোড পাঠাব।',
        ),
        FieldLabel(Env.phoneLoginEnabled ? 'লগইন মাধ্যম' : 'ইমেইল ঠিকানা'),
        ContactMethodToggle(
          method: _method,
          onChanged: (m) => setState(() {
            _method = m;
            _contact.clear();
            _error = null;
          }),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _contact,
          keyboardType: _method == 'whatsapp' ? TextInputType.phone : TextInputType.emailAddress,
          decoration: InputDecoration(
            prefixIcon: Icon(_method == 'whatsapp' ? LucideIcons.phone : LucideIcons.mail, size: 18),
            hintText: _method == 'whatsapp' ? '01712345678' : 'mother@gmail.com',
          ),
          onSubmitted: (_) => _submit(),
        ),
        if (_error != null) ...[const SizedBox(height: 10), ErrorBox(_error!)],
        const SizedBox(height: 16),
        BusyButton(label: 'কোড পাঠান', busyLabel: 'কোড পাঠানো হচ্ছে...', onPressed: _submit),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('অ্যাকাউন্ট নেই? ', style: ts(12, color: AppColors.grey600)),
          GestureDetector(
            onTap: () => session.goTo(AuthStage.signup),
            child: Text('এখানে অ্যাকাউন্ট খুলুন', style: ts(12, weight: bold, color: AppColors.maroon)),
          ),
        ]),
      ],
    );
  }
}
