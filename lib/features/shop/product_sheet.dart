import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/bn_digits.dart';
import '../../data/models/commerce.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/net_image.dart';
import 'cart_logic.dart';
import 'cart_sheet.dart';

/// Product detail modal (ShopTab.tsx "activeProduct"). Also opened from the
/// Recipes screen's "কিনুন" button.
Future<void> showProductSheet(BuildContext context, Product p) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (_) => SheetDragToClose(child: _ProductSheet(product: p)),
    );

class _ProductSheet extends ConsumerStatefulWidget {
  const _ProductSheet({required this.product});
  final Product product;

  @override
  ConsumerState<_ProductSheet> createState() => _ProductSheetState();
}

class _ProductSheetState extends ConsumerState<_ProductSheet> {
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final outOfStock = p.stock <= 0;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Stack(children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: NetImage(p.image, height: 240, width: double.infinity),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: Colors.white),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(LucideIcons.x, size: 18, color: AppColors.ink),
              ),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Text(p.name, style: ts(18, weight: bold, color: AppColors.maroon))),
                Tag(p.weight),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Text(taka(p.price), style: ts(20, weight: FontWeight.w800, color: AppColors.olive)),
                if (p.originalPrice != null) ...[
                  const SizedBox(width: 8),
                  Text(taka(p.originalPrice!),
                      style: ts(13, color: AppColors.grey400).copyWith(decoration: TextDecoration.lineThrough)),
                ],
                const Spacer(),
                Tag(
                  outOfStock ? 'স্টক শেষ' : 'স্টকে আছে (${toBnDigits(p.stock)}টি)',
                  bg: outOfStock ? AppColors.red50 : AppColors.green50,
                  fg: outOfStock ? AppColors.red600 : AppColors.green700,
                ),
              ]),
              const SizedBox(height: 14),
              Text(p.description, style: ts(13, color: AppColors.grey600, height: 1.6)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(12)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('উপাদান ও ব্যবহার:', style: ts(12, weight: bold, color: AppColors.maroon)),
                  const SizedBox(height: 4),
                  Text('১০০% প্রাকৃতিক ও অর্গানিক হার্বস। শিশুর খিচুড়ি, সুপ বা পিউরিতে সামান্য পরিমাণে ব্যবহার করুন।',
                      style: ts(12, height: 1.5)),
                  const SizedBox(height: 10),
                  Text('সংরক্ষণ পদ্ধতি:', style: ts(12, weight: bold, color: AppColors.maroon)),
                  const SizedBox(height: 4),
                  Text('শুকনো ও ঠান্ডা স্থানে এয়ারটাইট বয়ামে সংরক্ষণ করুন।', style: ts(12, height: 1.5)),
                ]),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Text('পরিমাণ:', style: ts(13, weight: bold)),
                const Spacer(),
                QtyStepper(
                  qty: _qty,
                  onMinus: () => setState(() => _qty = (_qty - 1).clamp(1, 99)),
                  onPlus: () => setState(() => _qty = (_qty + 1).clamp(1, p.stock > 0 ? p.stock.clamp(1, 99) : 99)),
                ),
              ]),
              const SizedBox(height: 16),
              BusyButton(
                icon: LucideIcons.shoppingBag,
                label: 'কার্টে যোগ করুন (${taka(p.price * _qty)})',
                onPressed: outOfStock
                    ? null
                    : () async {
                        ref.addToCart(p, _qty);
                        Navigator.pop(context);
                        showCartSheet(context);
                      },
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class QtyStepper extends StatelessWidget {
  const QtyStepper({super.key, required this.qty, required this.onMinus, required this.onPlus, this.small = false});
  final int qty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final s = small ? 28.0 : 34.0;
    Widget b(IconData i, VoidCallback f) => SizedBox(
          width: s,
          height: s,
          child: IconButton(
            padding: EdgeInsets.zero,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.cream,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: AppColors.sand)),
            ),
            onPressed: f,
            icon: Icon(i, size: small ? 13 : 15, color: AppColors.maroon),
          ),
        );
    return Row(mainAxisSize: MainAxisSize.min, children: [
      b(LucideIcons.minus, onMinus),
      SizedBox(width: small ? 28 : 36, child: Text(toBnDigits(qty), textAlign: TextAlign.center, style: ts(14, weight: bold))),
      b(LucideIcons.plus, onPlus),
    ]);
  }
}
