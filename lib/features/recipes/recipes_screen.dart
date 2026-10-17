import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/bn_digits.dart';
import '../../data/models/recipe.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/net_image.dart';
import '../../state/app_data_controller.dart';
import '../../state/providers.dart';
import '../shop/product_sheet.dart';

/// "রেসিপি ও পুষ্টি টিপস" full screen — port of frontend/src/tabs/RecipesTab.tsx.
class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key, this.initialRecipeId});

  /// Opens this recipe's detail right away (from My Baby / food chart).
  final String? initialRecipeId;

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {
  static const _ages = [
    ('all', 'সকল বয়স'),
    ('6_8m', '৬-৮ মাস'),
    ('9_12m', '৯-১২ মাস'),
    ('1_2y', '১-২ বছর'),
    ('2y_plus', '২ বছর+'),
  ];
  String _query = '';
  String _age = 'all';

  @override
  void initState() {
    super.initState();
    final id = widget.initialRecipeId;
    if (id != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final r = ref.read(dataProvider).recipes.where((x) => x.id == id).firstOrNull;
        if (r != null && mounted) _openDetail(r.id);
      });
    }
  }

  Future<void> _toggleSave(String id) async {
    try {
      final r = await ref.read(apiProvider).toggleSaveRecipe(id);
      ref.read(appDataProvider.notifier).replaceRecipe(r);
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }

  void _openDetail(String id) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: false,
        builder: (_) => SheetDragToClose(child: _RecipeDetail(recipeId: id, onToggleSave: _toggleSave)),
      );

  @override
  Widget build(BuildContext context) {
    final recipes = ref.watch(dataProvider.select((d) => d.recipes));
    final q = _query.toLowerCase();
    final list = recipes
        .where((r) =>
            (r.title.toLowerCase().contains(q) || r.ingredients.any((i) => i.toLowerCase().contains(q))) &&
            (_age == 'all' || r.ageGroup == _age))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('রেসিপি ও পুষ্টি টিপস')),
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(children: [
              TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(prefixIcon: Icon(LucideIcons.search, size: 18), hintText: 'রেসিপি বা উপকরণ দিয়ে খুঁজুন...'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 34,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  for (final (id, label) in _ages) PillChip(label: label, selected: _age == id, onTap: () => setState(() => _age = id)),
                ]),
              ),
            ]),
          ),
        ),
        if (list.isEmpty)
          const SliverToBoxAdapter(child: EmptyState(icon: LucideIcons.chefHat, title: 'কোনো রেসিপি পাওয়া যায়নি'))
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              delegate: SliverChildBuilderDelegate((_, i) => _card(list[i]), childCount: list.length),
            ),
          ),
      ]),
    );
  }

  Widget _card(Recipe r) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openDetail(r.id),
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.sandA(0.7))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Stack(children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: NetImage(r.image, height: 120, width: double.infinity),
                ),
                Positioned(left: 8, top: 8, child: Tag(r.ageGroupLabel, bg: AppColors.olive, fg: Colors.white)),
                Positioned(
                  right: 4,
                  top: 4,
                  child: IconButton(
                    style: IconButton.styleFrom(backgroundColor: r.saved ? AppColors.maroon : Colors.white.withValues(alpha: 0.85)),
                    onPressed: () => _toggleSave(r.id),
                    icon: Icon(LucideIcons.bookmark, size: 15, color: r.saved ? Colors.white : AppColors.ink),
                  ),
                ),
              ]),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r.title, style: ts(12.5, weight: bold, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    Row(children: [
                      const Icon(LucideIcons.clock, size: 11, color: AppColors.grey500),
                      const SizedBox(width: 4),
                      Expanded(child: Text('প্রস্তুতি সময়: ${r.prepTime}', style: ts(10, color: AppColors.grey500), overflow: TextOverflow.ellipsis)),
                    ]),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      );
}

class _RecipeDetail extends ConsumerWidget {
  const _RecipeDetail({required this.recipeId, required this.onToggleSave});
  final String recipeId;
  final Future<void> Function(String id) onToggleSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(dataProvider);
    final r = d.recipes.where((x) => x.id == recipeId).firstOrNull;
    if (r == null) return const SizedBox(height: 100);
    final product = r.shopProductId == null ? null : d.productById(r.shopProductId!);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Stack(children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: NetImage(r.image, height: 220, width: double.infinity),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.65)],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Tag(r.ageGroupLabel, bg: AppColors.gold, fg: AppColors.maroon),
                const SizedBox(height: 6),
                Text(r.title, style: ts(18, weight: bold, color: Colors.white)),
              ]),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Row(children: [
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: r.saved ? AppColors.maroon : Colors.white),
                  onPressed: () => onToggleSave(r.id),
                  icon: Icon(LucideIcons.bookmark, size: 17, color: r.saved ? Colors.white : AppColors.ink),
                ),
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: Colors.white),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.x, size: 17, color: AppColors.ink),
                ),
              ]),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('প্রয়োজনীয় উপকরণ:', style: ts(14, weight: bold, color: AppColors.maroon)),
              const SizedBox(height: 8),
              for (final ing in r.ingredients)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: AppColors.olive, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(ing, style: ts(12.5, height: 1.5))),
                  ]),
                ),
              const SizedBox(height: 14),
              Text('প্রস্তুত প্রণালী:', style: ts(14, weight: bold, color: AppColors.maroon)),
              const SizedBox(height: 8),
              for (var i = 0; i < r.steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${toBnDigits(i + 1)}.', style: ts(12.5, weight: bold, color: AppColors.olive)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(r.steps[i], style: ts(12.5, height: 1.5))),
                  ]),
                ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.amber50, borderRadius: BorderRadius.circular(12)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('টেকচার ও সার্ভিং নোট:', style: ts(12, weight: bold, color: AppColors.amber800)),
                  Text(r.textureNotes, style: ts(12, color: AppColors.amber800, height: 1.5)),
                  const SizedBox(height: 8),
                  Text('এলার্জেন সতর্কতা:', style: ts(12, weight: bold, color: AppColors.red600)),
                  Text(r.allergens, style: ts(12, color: AppColors.red600, height: 1.5)),
                ]),
              ),
              if (product != null) ...[
                const SizedBox(height: 14),
                AppCard(
                  padding: const EdgeInsets.all(10),
                  child: Row(children: [
                    NetImage(product.image, width: 50, height: 50, radius: 10),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('এই রেসিপিতে ব্যবহৃত', style: ts(10, color: AppColors.grey500)),
                        Text(product.name, style: ts(12.5, weight: bold)),
                      ]),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      onPressed: () {
                        Navigator.pop(context);
                        showProductSheet(context, product);
                      },
                      icon: const Icon(LucideIcons.shoppingBag, size: 14),
                      label: const Text('কিনুন'),
                    ),
                  ]),
                ),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}
