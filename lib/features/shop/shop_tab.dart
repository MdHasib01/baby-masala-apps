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

/// Shop tab — port of frontend/src/tabs/ShopTab.tsx.
class ShopTab extends ConsumerStatefulWidget {
  const ShopTab({super.key});

  @override
  ConsumerState<ShopTab> createState() => _ShopTabState();
}

class _ShopTabState extends ConsumerState<ShopTab> {
  static const _categories = ['সব', 'হার্বস ও স্পাইস', 'কম্বো প্যাক'];
  String _query = '';
  String _category = 'সব';

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(dataProvider);
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
              Row(children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(LucideIcons.search, size: 18),
                      hintText: 'বেবি মসলা, বেসিল বা হার্বস খুঁজুন...',
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
                      for (final c in _categories)
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
        if (products.isEmpty)
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
                childAspectRatio: 0.62,
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
              Positioned(left: 8, top: 8, child: Tag(p.weight, bg: Colors.white)),
            ]),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.name, style: ts(12.5, weight: bold, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(LucideIcons.star, size: 11, color: AppColors.gold),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text('${toBnDigits(p.rating)} (${toBnDigits(p.reviewsCount)} রিভিউ)',
                          style: ts(10, color: AppColors.grey500), overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                  const Spacer(),
                  Row(children: [
                    Text(taka(p.price), style: ts(14, weight: FontWeight.w800, color: AppColors.olive)),
                    if (p.originalPrice != null) ...[
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(taka(p.originalPrice!),
                            style: ts(10, color: AppColors.grey400).copyWith(decoration: TextDecoration.lineThrough)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8), textStyle: ts(12, weight: bold)),
                      onPressed: p.stock <= 0
                          ? null
                          : () {
                              ref.addToCart(p);
                              showCartSheet(context);
                            },
                      child: Text(p.stock <= 0 ? 'স্টক শেষ' : '+ কার্ট'),
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
