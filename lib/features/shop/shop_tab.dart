import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/bn_digits.dart';
import '../../data/models/commerce.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/net_image.dart';
import '../../state/app_data_controller.dart';
import 'cart_logic.dart';
import 'cart_sheet.dart';
import 'orders_sheet.dart';
import 'product_sheet.dart';

/// Shop tab — port of frontend/src/tabs/ShopTab.tsx. Products come from the
/// Baby Masala store (store.babymasalabd.com) through our backend.
class ShopTab extends ConsumerStatefulWidget {
  const ShopTab({super.key});

  @override
  ConsumerState<ShopTab> createState() => _ShopTabState();
}

class _ShopTabState extends ConsumerState<ShopTab> {
  String _query = '';
  String _category = 'সব';

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(dataProvider);
    final categories = ['সব', ...{for (final p in d.products) if (p.category.isNotEmpty) p.category}];
    if (!categories.contains(_category)) _category = 'সব';
    final q = _query.toLowerCase();
    final products = d.products
        .where((p) =>
            (p.name.toLowerCase().contains(q) || p.description.toLowerCase().contains(q)) &&
            (_category == 'সব' || p.category == _category))
        .toList();

    return RefreshIndicator(
      color: AppColors.maroon,
      onRefresh: () => ref.read(appDataProvider.notifier).refresh(),
      child: CustomScrollView(slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Column(children: [
              const _StoreBanner(),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(LucideIcons.search, size: 18),
                      hintText: 'বেসিল, খিচুড়ি মিক্স বা কম্বো খুঁজুন...',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CountBadge(
                  count: d.cartCount,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13)),
                    onPressed: () => showCartSheet(context),
                    icon: const Icon(LucideIcons.shoppingBag, size: 16),
                    label: const Text('কার্ট'),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: SizedBox(
                    height: 34,
                    child: ListView(scrollDirection: Axis.horizontal, children: [
                      for (final c in categories)
                        PillChip(label: c, selected: _category == c, onTap: () => setState(() => _category = c)),
                    ]),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => showOrdersSheet(context),
                  icon: const Icon(LucideIcons.package, size: 15),
                  label: const Text('আমার অর্ডার'),
                ),
              ]),
              const SizedBox(height: 12),
            ]),
          ),
        ),
        if (d.products.isEmpty)
          const SliverToBoxAdapter(
            child: EmptyState(
                icon: LucideIcons.store, title: 'শপ এই মুহূর্তে লোড হচ্ছে না', message: 'নিচে টেনে রিফ্রেশ করুন বা একটু পরে চেষ্টা করুন।'),
          )
        else if (products.isEmpty)
          SliverToBoxAdapter(
            child: EmptyState(icon: LucideIcons.search, title: 'কোনো পণ্য পাওয়া যায়নি', message: 'অন্য কিছু লিখে খুঁজে দেখুন।'),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                // Fixed row height: names wrap to 2 lines and multi-pack cards add a line.
                mainAxisExtent: 300,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, i) => _ProductCard(product: products[i]),
                childCount: products.length,
              ),
            ),
          ),
      ]),
    );
  }
}

class _ProductCard extends ConsumerWidget {
  const _ProductCard({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = product;
    final packs = p.allPacks;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showProductSheet(context, p),
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.sandA(0.7))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: NetImage(p.image, height: 130, width: double.infinity),
              ),
              if (p.badge.isNotEmpty)
                Positioned(
                  left: 8,
                  top: 8,
                  right: 44,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Tag(p.badge, bg: AppColors.maroon, fg: Colors.white),
                  ),
                ),
              if (p.originalPrice != null && p.originalPrice! > p.price)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Tag('-${toBnDigits(((1 - p.price / p.originalPrice!) * 100).round())}%', bg: AppColors.gold, fg: AppColors.maroon),
                ),
            ]),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.name, style: ts(12.5, weight: bold, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(packs.length > 1 ? '${toBnDigits(packs.length)}টি প্যাক সাইজ' : p.weight,
                      style: ts(10, color: AppColors.grey500), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(LucideIcons.star, size: 11, color: AppColors.gold),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text('${toBnDigits(p.rating)} (${toBnDigits(p.reviewsCount)} রিভিউ)',
                          style: ts(10, color: AppColors.grey500), overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                  const Spacer(),
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(taka(p.minPrice), style: ts(14, weight: FontWeight.w800, color: AppColors.olive)),
                    const SizedBox(width: 4),
                    if (packs.length > 1)
                      Text('থেকে', style: ts(10, color: AppColors.grey500))
                    else if (p.originalPrice != null)
                      Flexible(
                        child: Text(taka(p.originalPrice!),
                            style: ts(10, color: AppColors.grey400).copyWith(decoration: TextDecoration.lineThrough)),
                      ),
                  ]),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8), textStyle: ts(12, weight: bold)),
                      onPressed: p.stock <= 0
                          ? null
                          : () {
                              if (packs.length > 1) {
                                showProductSheet(context, p);
                              } else {
                                ref.addToCart(packs.first);
                                showCartSheet(context);
                              }
                            },
                      child: Text(p.stock <= 0
                          ? 'স্টক শেষ'
                          : packs.length > 1
                              ? 'প্যাক বাছুন'
                              : '+ কার্ট'),
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// "Baby Masala অফিসিয়াল স্টোর" header card.
class _StoreBanner extends StatelessWidget {
  const _StoreBanner();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: const Icon(LucideIcons.leaf, color: AppColors.sand, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Baby Masala অফিসিয়াল স্টোর', style: ts(13.5, weight: bold, color: Colors.white)),
              const SizedBox(height: 2),
              Text('ক্যাশ অন ডেলিভারি · সারা দেশে ডেলিভারি · প্রতি অর্ডারে পয়েন্ট',
                  style: ts(10.5, color: Colors.white.withValues(alpha: 0.8), height: 1.35)),
            ]),
          ),
        ]),
      );
}
