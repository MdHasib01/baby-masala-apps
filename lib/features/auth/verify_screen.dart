import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/bn_digits.dart';
import '../../shared/widgets/common.dart';
import '../../state/session_controller.dart';
import 'auth_widgets.dart';

/// Port of components/auth/LoginVerifyScreen.tsx — 6 boxes, paste support,
/// 59 s resend countdown.
class VerifyScreen extends ConsumerStatefulWidget {
  const VerifyScreen({super.key});

  @override
  ConsumerState<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends ConsumerState<VerifyScreen> {
  final _ctrls = List.generate(6, (_) => TextEditingController());
  final _nodes = List.generate(6, (_) => FocusNode());
  Timer? _timer;
  int _countdown = 59;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _countdown = 59);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _countdown = _countdown > 0 ? _countdown - 1 : 0);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _code => _ctrls.map((c) => c.text).join();

  void _onChanged(int i, String v) {
    final digits = toAsciiDigits(v).replaceAll(RegExp(r'\D'), '');
    if (digits.length == 6) {
      // pasted the whole code
      for (var k = 0; k < 6; k++) {
        _ctrls[k].text = digits[k];
      }
      _nodes[5].requestFocus();
      setState(() {});
      return;
    }
    _ctrls[i].text = digits.isEmpty ? '' : digits.substring(digits.length - 1);
    _ctrls[i].selection = TextSelection.collapsed(offset: _ctrls[i].text.length);
    if (_ctrls[i].text.isNotEmpty && i < 5) _nodes[i + 1].requestFocus();
    if (_ctrls[i].text.isEmpty && i > 0) _nodes[i - 1].requestFocus();
    setState(() {});
  }

  Future<void> _verify() async {
    if (_code.length < 6) {
      setState(() => _error = 'দয়া করে ৬ ডিজিটের কোডটি সম্পূর্ণ করুন।');
      return;
    }
    setState(() => _error = null);
    final session = ref.read(sessionProvider.notifier);
    try {
      await session.verifyOtp(_code);
      if (!mounted) return;
      setState(() => _success = 'যাচাইকরণ সফল হয়েছে!');
      await Future<void>.delayed(const Duration(milliseconds: 800));
      await session.loadApp();
    } catch (e) {
      if (mounted) setState(() => _error = e is ApiException ? e.message : 'যাচাই করা যায়নি। আবার চেষ্টা করুন।');
    }
  }

  Future<void> _resend() async {
    setState(() => _error = null);
    try {
      await ref.read(sessionProvider.notifier).resendOtp();
      _startTimer();
    } catch (e) {
      if (mounted) setState(() => _error = e is ApiException ? e.message : 'কোড পাঠানো যায়নি।');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(sessionProvider);
    final session = ref.read(sessionProvider.notifier);
    final back = s.isLoginMode ? AuthStage.login : AuthStage.signup;

    return AuthScaffold(
      onBack: () => session.goTo(back),
      children: [
        AuthHeading(
          icon: LucideIcons.shieldCheck,
          title: 'ডেমো কোড যাচাইকরণ',
          subtitle: '${s.tempContact.isEmpty ? '01712345678' : s.tempContact} নম্বরে পাঠানো ৬ ডিজিটের কোড দিন।',
          note: Text.rich(TextSpan(style: ts(11, color: AppColors.grey500), children: [
            const TextSpan(text: '(ডেমো কোড: '),
            TextSpan(text: '123456', style: ts(11, weight: bold, color: AppColors.maroon)),
            const TextSpan(text: ')'),
          ])),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) {
            return SizedBox(
              width: 46,
              child: TextField(
                controller: _ctrls[i],
                focusNode: _nodes[i],
                autofocus: i == 0,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [LengthLimitingTextInputFormatter(6)],
                style: ts(20, weight: bold, color: AppColors.maroon),
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(vertical: 14)),
                onChanged: (v) => _onChanged(i, v),
              ),
            );
          }),
        ),
        if (_error != null) ...[const SizedBox(height: 12), ErrorBox(_error!)],
        if (_success != null) ...[
          const SizedBox(height: 12),
          InfoBox(_success!, icon: LucideIcons.circleCheck, bg: AppColors.green50, fg: AppColors.green700),
        ],
        const SizedBox(height: 18),
        BusyButton(label: 'কোড যাচাই করুন', busyLabel: 'যাচাই করা হচ্ছে...', onPressed: _verify),
        const SizedBox(height: 16),
        Center(
          child: _countdown > 0
              ? Text('কোড পাননি? পুনরায় পাঠান (${toBnDigits(_countdown)} সে.)', style: ts(12, color: AppColors.grey600))
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('কোড পাননি? ', style: ts(12, color: AppColors.grey600)),
                  GestureDetector(
                    onTap: _resend,
                    child: Text('কোড পুনরায় পাঠান', style: ts(12, weight: bold, color: AppColors.maroon)),
                  ),
                ]),
        ),
        const SizedBox(height: 6),
        Center(
          child: TextButton(onPressed: () => session.goTo(back), child: const Text('যোগাযোগ নম্বর পরিবর্তন করুন')),
        ),
      ],
    );
  }
}
