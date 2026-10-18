import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/api_exception.dart';
import '../../core/config/env.dart';
import '../../core/utils/bn_digits.dart';
import '../../shared/widgets/common.dart';
import '../../state/session_controller.dart';
import 'auth_widgets.dart';

/// Port of components/auth/SignUpScreen.tsx.
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  String _method = defaultContactMethod;
  bool _agreed = false;
  final _name = TextEditingController();
  final _contact = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final contact = toAsciiDigits(_contact.text.trim());
    final err = name.isEmpty
        ? 'দয়া করে আপনার নাম লিখুন।'
        : validateContact(_method, contact) ??
            (_agreed ? null : 'অ্যাকাউন্ট খুলতে শর্তাবলী ও গোপনীয়তা নীতিতে সম্মতি দিন।');
    setState(() => _error = err);
    if (err != null) return;
    try {
      await ref.read(sessionProvider.notifier).requestSignupOtp(name, contact);
    } catch (e) {
      if (mounted) setState(() => _error = e is ApiException ? e.message : 'কোড পাঠানো যায়নি। আবার চেষ্টা করুন।');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      onBack: () => ref.read(sessionProvider.notifier).goTo(AuthStage.welcome),
      footer: 'Baby Care by Baby Masala',
      children: [
        const AuthHeading(title: 'নতুন অ্যাকাউন্ট তৈরি করুন', subtitle: 'বেবি কেয়ার পরিবারে আপনাকে স্বাগতম।'),
        const FieldLabel('মায়ের নাম'),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          maxLength: 80,
          decoration: const InputDecoration(
            prefixIcon: Icon(LucideIcons.user, size: 18),
            hintText: 'আপনার পূর্ণ নাম লিখুন',
            counterText: '',
          ),
        ),
        const SizedBox(height: 8),
        FieldLabel(Env.phoneLoginEnabled ? 'যোগাযোগের মাধ্যম' : 'ইমেইল ঠিকানা'),
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
        const SizedBox(height: 8),
        LegalConsent(value: _agreed, onChanged: (v) => setState(() => _agreed = v)),
        if (_error != null) ...[const SizedBox(height: 10), ErrorBox(_error!)],
        const SizedBox(height: 16),
        BusyButton(label: 'যাচাইকরণ কোড পাঠান', busyLabel: 'কোড পাঠানো হচ্ছে...', onPressed: _submit),
      ],
    );
  }
}
