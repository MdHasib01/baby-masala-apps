import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/bn_digits.dart';
import '../../core/utils/links.dart';
import '../../data/models/commerce.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/net_image.dart';
import 'cart_logic.dart';
import 'cart_sheet.dart';

/// Product detail modal (ShopTab.tsx "activeProduct"). Also opened from the
/// Recipes screen's "কিনুন" button. The customer picks a pack size; each pack
/// is added to the cart on its own.
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
  late String _packId = widget.product.allPacks.first.id;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final packs = p.allPacks;
    final pack = packs.firstWhere((x) => x.id == _packId, orElse: () => packs.first);
    final outOfStock = pack.stock <= 0;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Flexible(
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Stack(children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: NetImage(p.image, height: 260, width: double.infinity),
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
                if (p.badge.isNotEmpty)
                  Positioned(left: 12, bottom: 12, child: Tag(p.badge, bg: AppColors.maroon, fg: Colors.white)),
              ]),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.name, style: ts(18, weight: bold, color: AppColors.maroon, height: 1.3)),
                  const SizedBox(height: 4),
                  Wrap(spacing: 12, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    if (p.age.isNotEmpty) Text(p.age, style: ts(11.5, weight: semi, color: AppColors.olive)),
                    if (p.reviewsCount > 0)
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(LucideIcons.star, size: 12, color: AppColors.gold),
                        const SizedBox(width: 3),
                        Text('${toBnDigits(p.rating)} · ${toBnDigits(p.reviewsCount)} রিভিউ',
                            style: ts(11, weight: semi, color: AppColors.amber800)),
                      ]),
                  ]),
                  const SizedBox(height: 16),
                  Text('প্যাক সাইজ', style: ts(13, weight: bold, color: AppColors.maroon)),
                  const SizedBox(height: 8),
                  for (final x in packs) _PackTile(pack: x, selected: x.id == pack.id, onTap: () => setState(() => _packId = x.id)),
                  if (p.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(p.description, style: ts(13, color: AppColors.grey600, height: 1.6)),
                  ],
                  if (p.includes.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text('কম্বোতে যা আছে', style: ts(12.5, weight: bold, color: AppColors.maroon)),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      for (final i in p.includes) Tag(i, bg: AppColors.olive.withValues(alpha: 0.1), fg: AppColors.olive),
                    ]),
                  ],
                  if (p.benefits.isNotEmpty || p.howToUse.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(12)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        if (p.benefits.isNotEmpty) ...[
                          Text('উপকারিতা', style: ts(12, weight: bold, color: AppColors.maroon)),
                          const SizedBox(height: 6),
                          for (final b in p.benefits)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(LucideIcons.circleCheck, size: 13, color: AppColors.olive),
                                ),
                                const SizedBox(width: 6),
                                Expanded(child: Text(b, style: ts(12, height: 1.5))),
                              ]),
                            ),
                        ],
                        if (p.howToUse.isNotEmpty) ...[
                          if (p.benefits.isNotEmpty) const SizedBox(height: 8),
                          Text('ব্যবহারের নিয়ম', style: ts(12, weight: bold, color: AppColors.maroon)),
                          const SizedBox(height: 4),
                          Text(p.howToUse, style: ts(12, height: 1.5)),
                        ],
                      ]),
                    ),
                  ],
                  if (p.storeUrl != null) ...[
                    const SizedBox(height: 6),
                    TextButton.icon(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, foregroundColor: AppColors.maroon),
                      onPressed: () => openUrl(context, p.storeUrl!),
                      icon: const Icon(LucideIcons.externalLink, size: 14),
                      label: Text('স্টোরে বিস্তারিত দেখুন', style: ts(12, weight: semi, color: AppColors.maroon)),
                    ),
                  ],
                ]),
              ),
            ]),
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.sand))),
            child: Row(children: [
              QtyStepper(
                qty: _qty,
                onMinus: () => setState(() => _qty = (_qty - 1).clamp(1, 99)),
                onPlus: () => setState(() => _qty = (_qty + 1).clamp(1, 99)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BusyButton(
                  icon: LucideIcons.shoppingBag,
                  label: outOfStock ? 'স্টক শেষ' : 'কার্টে যোগ করুন · ${taka(pack.price * _qty)}',
                  onPressed: outOfStock
                      ? null
                      : () async {
                          ref.addToCart(pack, _qty);
                          Navigator.pop(context);
                          showCartSheet(context);
                        },
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _PackTile extends StatelessWidget {
  const _PackTile({required this.pack, required this.selected, required this.onTap});
  final Product pack;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: selected ? AppColors.maroon : AppColors.sand, width: selected ? 2 : 1),
              ),
              child: Row(children: [
                Icon(selected ? LucideIcons.circleDot : LucideIcons.circle,
                    size: 18, color: selected ? AppColors.maroon : AppColors.grey400),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(pack.packName, style: ts(12.5, weight: bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (pack.packLabel.isNotEmpty && pack.packLabel != pack.weight)
                      Text(pack.weight, style: ts(10.5, color: AppColors.grey500)),
                  ]),
                ),
                const SizedBox(width: 8),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(taka(pack.price), style: ts(13.5, weight: FontWeight.w800, color: AppColors.olive)),
                  if (pack.originalPrice != null)
                    Text(taka(pack.originalPrice!),
                        style: ts(10, color: AppColors.grey400).copyWith(decoration: TextDecoration.lineThrough)),
                ]),
              ]),
            ),
          ),
        ),
      );
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
