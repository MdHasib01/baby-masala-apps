import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/common.dart';
import '../../state/session_controller.dart';
import 'auth_widgets.dart';

/// Port of components/auth/LoginScreen.tsx (email + password).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    final err = validateContact('email', email) ?? (password.isEmpty ? 'পাসওয়ার্ড লিখুন।' : null);
    setState(() => _error = err);
    if (err != null) return;
    try {
      await ref.read(sessionProvider.notifier).login(email, password);
    } catch (e) {
      if (mounted) setState(() => _error = e is ApiException ? e.message : 'লগইন করা যায়নি। আবার চেষ্টা করুন।');
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
          subtitle: 'আপনার অ্যাকাউন্টের ইমেইল ও পাসওয়ার্ড দিন।',
        ),
        const FieldLabel('ইমেইল ঠিকানা'),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            prefixIcon: Icon(LucideIcons.mail, size: 18),
            hintText: 'mother@gmail.com',
          ),
        ),
        const SizedBox(height: 12),
        const FieldLabel('পাসওয়ার্ড'),
        PasswordField(controller: _password, onSubmitted: (_) => _submit()),
        if (_error != null) ...[const SizedBox(height: 10), ErrorBox(_error!)],
        const SizedBox(height: 16),
        BusyButton(label: 'লগইন', busyLabel: 'লগইন হচ্ছে...', onPressed: _submit),
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
