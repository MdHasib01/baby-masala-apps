import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/api_exception.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/bn_digits.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/net_image.dart';
import '../../state/app_data_controller.dart';
import '../../state/providers.dart';
import '../../state/session_controller.dart';
import '../timeline/user_timeline_screen.dart';
import 'home_tab.dart';

/// Port of components/profile/ProfileDrawer.tsx.
///
/// Mobile differences (see MOBILE_SYNC.md §6):
///  * "ঠিকানা ব্যবস্থাপনা" and "সেটিংস" entries open the Address manager and
///    Settings screens (unreachable on web).
///  * Coupon calls `POST /auth/activate-membership` instead of a local check.
class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  bool _membershipOpen = true;
  final _coupon = TextEditingController();
  String? _couponError;
  String? _couponSuccess;

  @override
  void dispose() {
    _coupon.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  void _tab(HomeTab t) {
    _close();
    ref.read(homeTabProvider.notifier).select(t);
  }

  void _push(String route, {Object? extra}) {
    _close();
    context.push(route, extra: extra);
  }

  Future<void> _activateCoupon() async {
    if (_coupon.text.trim().isEmpty) {
      setState(() => _couponError = 'দয়া করে কুপন কোড লিখুন।');
      return;
    }
    try {
      final user = await ref.read(apiProvider).activateMembership(_coupon.text.trim());
      ref.read(appDataProvider.notifier).setUserFromServer(user);
      setState(() {
        _couponSuccess = 'অভিনন্দন! আপনার প্রিমিয়াম মেম্বারশিপ সক্রিয় হয়েছে।';
        _couponError = null;
      });
    } catch (e) {
      setState(() => _couponError = errorMessage(e));
    }
  }

  Future<void> _logout() async {
    final ok = await confirmDialog(
      context,
      'লগআউট করবেন?\nআবার লগইন করে আপনার অ্যাকাউন্টে ফিরতে পারবেন।',
      confirm: 'লগআউট',
      danger: true,
    );
    if (!ok || !mounted) return;
    _close();
    await ref.read(sessionProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(dataProvider);
    final user = d.user;
    final width = MediaQuery.of(context).size.width * 0.88;

    return Drawer(
      width: width > 380 ? 380 : width,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(right: Radius.circular(24))),
      child: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
          Row(children: [
            const Icon(LucideIcons.sparkles, color: AppColors.gold, size: 18),
            const SizedBox(width: 6),
            Expanded(child: Text('Baby Care মেনু', style: ts(15, weight: bold, color: AppColors.maroon))),
            IconButton(onPressed: _close, icon: const Icon(LucideIcons.x, size: 20)),
          ]),
          const SizedBox(height: 8),
          // Profile card → own timeline
          AppCard(
            padding: const EdgeInsets.all(12),
            onTap: () => _push(Routes.timeline, extra: const TimelineTarget.me()),
            child: Row(children: [
              AppAvatar(user.avatar, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user.name, style: ts(15, weight: bold, color: AppColors.maroon), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(children: [
                    Icon(LucideIcons.shieldCheck, size: 12, color: user.isMember ? AppColors.gold : AppColors.grey400),
                    const SizedBox(width: 4),
                    Text(user.isMember ? 'প্রিমিয়াম মেম্বার' : 'স্ট্যান্ডার্ড অ্যাকাউন্ট',
                        style: ts(11, weight: semi, color: AppColors.olive)),
                  ]),
                ]),
              ),
              const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.grey400),
            ]),
          ),
          const SizedBox(height: 16),
          Text('আপনার শর্টকাট', style: ts(11, weight: bold, color: AppColors.grey500)),
          const SizedBox(height: 8),
          Row(children: [
            _shortcut(LucideIcons.baby, 'নির্বাচিত শিশু', d.children.firstOrNull?.name ?? '—', () => _tab(HomeTab.baby)),
            const SizedBox(width: 8),
            _shortcut(LucideIcons.users, 'কমিউনিটি', 'ফ্রেন্ডস', () => _tab(HomeTab.friends)),
            const SizedBox(width: 8),
            _shortcut(LucideIcons.stethoscope, 'মেডিকেল', 'ডাক্তার', () => _push(Routes.doctor)),
          ]),
          const SizedBox(height: 16),
          _menuGroup([
            _item(LucideIcons.users, 'ফ্রেন্ডস', () => _tab(HomeTab.friends)),
            _item(LucideIcons.messageSquare, 'মেসেঞ্জার', () => _push(Routes.messenger),
                badge: d.unreadMessages > 0 ? '${toBnDigits(d.unreadMessages)}টি নতুন' : null),
            _item(LucideIcons.stethoscope, 'ডাক্তারকে জিজ্ঞেস করুন', () => _push(Routes.doctor)),
            _item(LucideIcons.baby, 'আমার বেবি', () => _tab(HomeTab.baby)),
            _item(LucideIcons.gift, 'পয়েন্ট ও গিফট', () => _tab(HomeTab.rewards)),
            _item(LucideIcons.utensils, 'রেসিপি ও টিপস', () => _push(Routes.recipes)),
          ]),
          const SizedBox(height: 12),
          _menuGroup([
            _item(LucideIcons.mapPin, 'ঠিকানা ব্যবস্থাপনা', () => _push(Routes.addresses)),
            _item(LucideIcons.settings, 'সেটিংস ও গোপনীয়তা', () => _push(Routes.settings)),
          ]),
          const SizedBox(height: 12),
          _membershipCard(user.isMember),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.red600, backgroundColor: Colors.white),
            onPressed: _logout,
            icon: const Icon(LucideIcons.logOut, size: 16),
            label: const Text('লগআউট'),
          ),
          const SizedBox(height: 12),
          Center(child: Text('Baby Care by Baby Masala', style: ts(10, color: AppColors.grey400))),
        ]),
      ),
    );
  }

  Widget _shortcut(IconData icon, String caption, String value, VoidCallback onTap) => Expanded(
        child: AppCard(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          onTap: onTap,
          child: Column(children: [
            Icon(icon, size: 18, color: AppColors.maroon),
            const SizedBox(height: 4),
            Text(caption, style: ts(9, color: AppColors.grey500)),
            Text(value, style: ts(11, weight: bold), overflow: TextOverflow.ellipsis),
          ]),
        ),
      );

  Widget _menuGroup(List<Widget> items) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.sand),
        ),
        child: Column(children: [
          for (var i = 0; i < items.length; i++) ...[if (i > 0) const Divider(indent: 48), items[i]],
        ]),
      );

  Widget _item(IconData icon, String label, VoidCallback onTap, {String? badge}) => ListTile(
        dense: true,
        leading: Icon(icon, size: 18, color: AppColors.maroon),
        title: Text(label, style: ts(13, weight: semi)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (badge != null) Tag(badge, bg: AppColors.red600, fg: Colors.white),
          const SizedBox(width: 4),
          const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.grey400),
        ]),
        onTap: onTap,
      );

  Widget _membershipCard(bool isMember) => Container(
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          InkWell(
            onTap: () => setState(() => _membershipOpen = !_membershipOpen),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                const Icon(LucideIcons.sparkles, size: 16, color: AppColors.gold),
                const SizedBox(width: 8),
                Expanded(child: Text('Baby Care মেম্বারশিপ', style: ts(13, weight: bold, color: Colors.white))),
                Icon(_membershipOpen ? LucideIcons.chevronDown : LucideIcons.chevronRight, size: 16, color: Colors.white),
              ]),
            ),
          ),
          if (_membershipOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  Text('মূল্য: ', style: ts(11, color: AppColors.sand)),
                  Text('৳ ৮,০০০', style: ts(11, weight: bold, color: Colors.white).copyWith(decoration: TextDecoration.lineThrough)),
                  const Spacer(),
                  const Tag('ফ্রি কুপন উপলব্ধ', bg: AppColors.gold, fg: AppColors.maroon),
                ]),
                const SizedBox(height: 10),
                if (isMember)
                  Row(children: [
                    const Icon(LucideIcons.circleCheck, size: 15, color: AppColors.gold),
                    const SizedBox(width: 6),
                    Text('আপনার মেম্বারশিপ সক্রিয়', style: ts(12, weight: bold, color: Colors.white)),
                  ])
                else ...[
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _coupon,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(hintText: 'কুপন কোড (BABYCARE)'),
                      ),
                    ),
                    const SizedBox(width: 6),
                    BusyButton(label: 'অ্যাক্টিভ', expand: false, color: AppColors.gold, onPressed: _activateCoupon),
                  ]),
                  if (_couponError != null) ...[
                    const SizedBox(height: 6),
                    Text(_couponError!, style: ts(11, weight: semi, color: AppColors.sand)),
                  ],
                ],
                if (_couponSuccess != null) ...[
                  const SizedBox(height: 6),
                  Text(_couponSuccess!, style: ts(11, weight: semi, color: AppColors.gold)),
                ],
              ]),
            ),
        ]),
      );
}
