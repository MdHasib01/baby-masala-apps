import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/common.dart';
import '../../state/app_data_controller.dart';
import '../../state/providers.dart';

/// Port of components/NotificationModal.tsx.
Future<void> showNotificationsSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (_) => const _NotificationsSheet(),
    );

class _NotificationsSheet extends ConsumerWidget {
  const _NotificationsSheet();

  IconData _icon(String type) => switch (type) {
        'reward' => LucideIcons.gift,
        'order' => LucideIcons.package,
        'community' => LucideIcons.users,
        'friend' => LucideIcons.userPlus,
        'message' => LucideIcons.messageCircle,
        'doctor' => LucideIcons.stethoscope,
        _ => LucideIcons.lightbulb,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(dataProvider.select((d) => d.notifications));
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          decoration: const BoxDecoration(
            color: AppColors.maroon,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 8, 14),
          child: Row(children: [
            const Icon(LucideIcons.bell, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('নোটিফিকেশন', style: ts(15, weight: bold, color: Colors.white))),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x, color: Colors.white, size: 20)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 12, 6),
          child: Row(children: [
            Expanded(child: Text('সাম্প্রতিক আপডেটসমূহ', style: ts(12, weight: semi, color: AppColors.grey600))),
            TextButton(
              onPressed: () {
                ref.read(appDataProvider.notifier).markAllNotificationsRead();
                ref.read(apiProvider).markAllNotificationsRead().catchError((Object e) => debugPrint('[notifications] $e'));
              },
              child: const Text('সব পঠিত করুন'),
            ),
          ]),
        ),
        const Divider(),
        Flexible(
          child: list.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text('কোনো নতুন নোটিফিকেশন নেই।', style: ts(13, color: AppColors.grey500)),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (_, i) {
                    final n = list[i];
                    return Container(
                      color: n.read ? null : AppColors.sandA(0.18),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.sandA(0.4), shape: BoxShape.circle),
                          child: Icon(_icon(n.type), size: 15, color: AppColors.maroon),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: Text(n.title, style: ts(13, weight: bold))),
                              Text(n.time, style: ts(10, color: AppColors.grey500)),
                            ]),
                            const SizedBox(height: 3),
                            Text(n.message, style: ts(12, color: AppColors.grey600, height: 1.4)),
                          ]),
                        ),
                      ]),
                    );
                  },
                ),
        ),
        const SizedBox(height: 12),
      ]),
    );
  }
}
