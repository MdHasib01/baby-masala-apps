import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/bn_digits.dart';
import '../../data/models/commerce.dart';
import '../../shared/widgets/common.dart';
import '../../state/app_data_controller.dart';

/// "আমার অর্ডার" — MOBILE-ONLY (web has no order history screen yet).
/// Uses `orders` from bootstrap; status changes made in Admin show up after
/// refresh.
Future<void> showOrdersSheet(BuildContext context) =>
    showAppSheet<void>(context, title: 'আমার অর্ডার', builder: (_) => const _Orders());

Color orderStatusColor(String s) => switch (s) {
      'delivered' => AppColors.green700,
      'cancelled' => AppColors.red600,
      'shipped' => AppColors.blue600,
      _ => AppColors.amber800,
    };

class _Orders extends ConsumerWidget {
  const _Orders();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(dataProvider.select((d) => d.orders));
    if (orders.isEmpty) {
      return const EmptyState(icon: LucideIcons.package, title: 'এখনো কোনো অর্ডার করা হয়নি');
    }
    return Column(children: [
      for (final o in orders)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text('#${o.id}', style: ts(12, weight: bold))),
                Tag(orderStatusLabels[o.status] ?? o.status,
                    bg: orderStatusColor(o.status).withValues(alpha: 0.1), fg: orderStatusColor(o.status)),
              ]),
              const SizedBox(height: 4),
              Text(o.createdAt, style: ts(10.5, color: AppColors.grey500)),
              const SizedBox(height: 8),
              for (final i in o.items)
                Text('• ${i.product.name} x ${toBnDigits(i.quantity)}', style: ts(12, height: 1.5)),
              const Divider(height: 18),
              Row(children: [
                Expanded(child: Text('সর্বমোট: ${taka(o.totalAmount)}', style: ts(13, weight: bold, color: AppColors.maroon))),
                Text('+${toBnDigits(o.pointsEarned)} পয়েন্ট', style: ts(11, weight: semi, color: AppColors.olive)),
              ]),
            ]),
          ),
        ),
    ]);
  }
}
