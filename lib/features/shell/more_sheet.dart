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
import '../notifications/notifications_sheet.dart';
import '../shop/orders_sheet.dart';
import '../timeline/user_timeline_screen.dart';
import 'home_tab.dart';

/// "আরও" (More) — opened from the bottom navigation. Holds every option of
/// the web's ProfileDrawer.tsx plus the mobile-only entries (MOBILE_SYNC.md §6):
/// profile card, selected child, friends, messenger, doctor, recipes,
/// notifications, orders, addresses, settings, admin (admins only),
/// membership coupon and logout.
Future<void> showMoreSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (_) => SheetDragToClose(child: _MoreSheet(rootContext: context)),
    );

class _MoreSheet extends ConsumerStatefulWidget {
  const _MoreSheet({required this.rootContext});

  /// Context below the shell, used to navigate after the sheet closes.
  final BuildContext rootContext;

  @override
  ConsumerState<_MoreSheet> createState() => _MoreSheetState();
}

class _MoreSheetState extends ConsumerState<_MoreSheet> {
  final _coupon = TextEditingController();
  String? _couponError;
  String? _couponSuccess;

  @override
  void dispose() {
    _coupon.dispose();
    super.dispose();
  }

  BuildContext get _root => widget.rootContext;

  void _go(String route, {Object? extra}) {
    Navigator.pop(context);
    _root.push(route, extra: extra);
  }

  void _tab(HomeTab t) {
    Navigator.pop(context);
    ref.read(homeTabProvider.notifier).select(t);
  }

  void _then(void Function(BuildContext root) action) {
    Navigator.pop(context);
    action(_root);
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
    Navigator.pop(context);
    await ref.read(sessionProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(dataProvider);
    final user = d.user;
    final child = d.children.firstOrNull;

    final items = <_MoreItem>[
      _MoreItem(LucideIcons.users, 'ফ্রেন্ডস', AppColors.olive, () => _go(Routes.friends)),
      _MoreItem(LucideIcons.messageCircle, 'মেসেঞ্জার', AppColors.maroon, () => _go(Routes.messenger), badge: d.unreadMessages),
      _MoreItem(LucideIcons.stethoscope, 'ডাক্তারকে জিজ্ঞেস করুন', AppColors.blue600, () => _go(Routes.doctor)),
      _MoreItem(LucideIcons.utensils, 'রেসিপি ও টিপস', AppColors.amber800, () => _go(Routes.recipes)),
      _MoreItem(LucideIcons.bell, 'নোটিফিকেশন', AppColors.maroon, () => _then(showNotificationsSheet), badge: d.unreadNotifications),
      _MoreItem(LucideIcons.package, 'আমার অর্ডার', AppColors.olive, () => _then(showOrdersSheet)),
      _MoreItem(LucideIcons.gift, 'পয়েন্ট ও গিফট', AppColors.gold, () => _tab(HomeTab.rewards)),
      _MoreItem(LucideIcons.mapPin, 'ঠিকানা', AppColors.green700, () => _go(Routes.addresses)),
      _MoreItem(LucideIcons.messageSquareWarning, 'অভিযোগ ও সাপোর্ট', AppColors.red600, () => _go(Routes.complaints)),
      _MoreItem(LucideIcons.settings, 'সেটিংস ও গোপনীয়তা', AppColors.grey600, () => _go(Routes.settings)),
      if (user.isAdmin) _MoreItem(LucideIcons.shield, 'অ্যাডমিন', AppColors.red600, () => _go(Routes.admin)),
    ];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SheetHandle(),
            const SizedBox(height: 6),
            // ---- profile card → own timeline
            Material(
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _go(Routes.timeline, extra: const TimelineTarget.me()),
                child: Ink(
                  decoration: const BoxDecoration(gradient: AppColors.brandGradient),
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.gold, width: 2)),
                        child: AppAvatar(user.avatar, size: 54, ring: false),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(user.name, style: ts(17, weight: bold, color: Colors.white), overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Row(children: [
                            Icon(LucideIcons.shieldCheck, size: 13, color: user.isMember ? AppColors.gold : AppColors.sand),
                            const SizedBox(width: 4),
                            Text(user.isMember ? 'প্রিমিয়াম মেম্বার' : 'স্ট্যান্ডার্ড অ্যাকাউন্ট',
                                style: ts(12, weight: semi, color: AppColors.sand)),
                          ]),
                        ]),
                      ),
                      const Icon(LucideIcons.chevronRight, color: Colors.white),
                    ]),
                    const SizedBox(height: 14),
                    Row(children: [
                      _miniStat(LucideIcons.sparkles, '${toBnDigits(d.availablePoints)} পয়েন্ট', () => _tab(HomeTab.rewards)),
                      const SizedBox(width: 8),
                      _miniStat(LucideIcons.baby, child?.name ?? 'শিশু যোগ করুন', () => _tab(HomeTab.baby)),
                    ]),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text('সব অপশন', style: ts(13, weight: bold, color: AppColors.grey500)),
            ),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.98,
              children: [for (final i in items) _tile(i)],
            ),
            const SizedBox(height: 16),
            _membershipCard(user.isMember),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.red600,
                backgroundColor: Colors.white,
                side: BorderSide(color: AppColors.red600.withValues(alpha: 0.25)),
              ),
              onPressed: _logout,
              icon: const Icon(LucideIcons.logOut, size: 17),
              label: const Text('লগআউট'),
            ),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipOval(
                    child: Image.asset('assets/images/logo_icon.png', width: 16, height: 16),
                  ),
                  const SizedBox(width: 6),
                  Text('Baby Care by Baby Masala', style: ts(10.5, color: AppColors.grey400)),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _miniStat(IconData icon, String label, VoidCallback onTap) => Expanded(
        child: Material(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              child: Row(children: [
                Icon(icon, size: 15, color: AppColors.gold),
                const SizedBox(width: 6),
                Expanded(child: Text(label, style: ts(12, weight: bold, color: Colors.white), overflow: TextOverflow.ellipsis)),
              ]),
            ),
          ),
        ),
      );

  Widget _tile(_MoreItem i) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: i.onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.sandA(0.55)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              CountBadge(
                count: i.badge,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: i.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)),
                  child: Icon(i.icon, size: 22, color: i.color),
                ),
              ),
              const SizedBox(height: 8),
              Text(i.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ts(11.5, weight: semi, height: 1.25)),
            ]),
          ),
        ),
      );

  /// Same card as the web drawer, but the coupon is checked by the server.
  Widget _membershipCard(bool isMember) => AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
              child: const Icon(LucideIcons.sparkles, size: 18, color: AppColors.gold),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Baby Care মেম্বারশিপ', style: ts(14, weight: bold, color: AppColors.maroon)),
                Row(children: [
                  Text('মূল্য: ', style: ts(11, color: AppColors.grey500)),
                  Text('৳ ৮,০০০', style: ts(11, color: AppColors.grey500).copyWith(decoration: TextDecoration.lineThrough)),
                  const SizedBox(width: 6),
                  const Tag('ফ্রি কুপন উপলব্ধ', bg: Color(0xFFFEF3C7), fg: AppColors.amber800),
                ]),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          if (isMember)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.green50, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(LucideIcons.circleCheck, size: 16, color: AppColors.green700),
                const SizedBox(width: 8),
                Text('আপনার মেম্বারশিপ সক্রিয়', style: ts(12.5, weight: bold, color: AppColors.green700)),
              ]),
            )
          else ...[
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _coupon,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(hintText: 'কুপন কোড (BABYCARE)'),
                ),
              ),
              const SizedBox(width: 8),
              BusyButton(label: 'অ্যাক্টিভ', expand: false, onPressed: _activateCoupon),
            ]),
            if (_couponError != null) ...[const SizedBox(height: 8), ErrorBox(_couponError!)],
          ],
          if (_couponSuccess != null) ...[
            const SizedBox(height: 8),
            Text(_couponSuccess!, style: ts(12, weight: semi, color: AppColors.green700)),
          ],
        ]),
      );
}

class _MoreItem {
  const _MoreItem(this.icon, this.label, this.color, this.onTap, {this.badge = 0});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final int badge;
}
