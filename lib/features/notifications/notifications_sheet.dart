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
        const SheetHandle(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 12, 0),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('নোটিফিকেশন', style: ts(18, weight: FontWeight.w800, color: AppColors.maroon)),
                Text('সাম্প্রতিক আপডেটসমূহ', style: ts(11.5, color: AppColors.grey500)),
              ]),
            ),
            TextButton(
              onPressed: () {
                ref.read(appDataProvider.notifier).markAllNotificationsRead();
                ref.read(apiProvider).markAllNotificationsRead().catchError((Object e) => debugPrint('[notifications] $e'));
              },
              child: const Text('সব পঠিত করুন'),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        Flexible(
          child: list.isEmpty
              ? const EmptyState(icon: LucideIcons.bellOff, title: 'কোনো নতুন নোটিফিকেশন নেই।')
              : ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final n = list[i];
                    return Container(
                      decoration: BoxDecoration(
                        color: n.read ? Colors.white : AppColors.sandA(0.28),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.sandA(n.read ? 0.5 : 0.9)),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(color: AppColors.maroon.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                          child: Icon(_icon(n.type), size: 17, color: AppColors.maroon),
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
