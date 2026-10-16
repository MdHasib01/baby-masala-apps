import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/child_age.dart';
import '../../data/models/medical.dart';
import '../../data/models/recipe.dart';
import '../../data/static/age_tips.dart';
import '../../data/static/tips.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/net_image.dart';
import '../../state/app_data_controller.dart';
import 'child_form_sheet.dart';

/// My Baby tab — port of frontend/src/tabs/MyBabyTab.tsx
/// (views: main · foodChart · tips · tipDetail).
class MyBabyTab extends ConsumerStatefulWidget {
  const MyBabyTab({super.key});

  @override
  ConsumerState<MyBabyTab> createState() => _MyBabyTabState();
}

class _MyBabyTabState extends ConsumerState<MyBabyTab> {
  String? _selectedId;
  String _view = 'main';
  TipItem? _tip;
  String _tipCategory = 'সব';
  String _day = daysOfWeek.first;

  /// Tip bookmarks are local-only (same as web — the API has no endpoint).
  late final Set<String> _savedTips = {for (final t in tips) if (t.savedByDefault) t.id};

  void _openRecipes([String? recipeId]) => context.push(Routes.recipes, extra: recipeId);

  Future<void> _add() async {
    final id = await showChildForm(context, ref);
    if (id != null) setState(() => _selectedId = id);
  }

  Future<void> _delete(Child child) async {
    final list = ref.read(dataProvider).children;
    if (list.length <= 1) {
      await alertDialog(context, 'সর্বনিম্ন একটি শিশু প্রোফাইল থাকা আবশ্যক।');
      return;
    }
    if (!mounted) return;
    if (!await confirmDialog(context, 'আপনি কি নিশ্চিতভাবে এই শিশুর প্রোফাইল মুছে ফেলতে চান?', danger: true, confirm: 'মুছে ফেলুন')) return;
    final updated = list.where((c) => c.id != child.id).toList();
    ref.read(appDataProvider.notifier).setChildren(updated);
    setState(() => _selectedId = updated.first.id);
  }

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(dataProvider);
    if (d.children.isEmpty) {
      return ListView(children: [
        EmptyState(
          icon: LucideIcons.baby,
          title: 'কোনো শিশু প্রোফাইল যোগ করা হয়নি',
          message: 'আপনার সন্তানের বয়স অনুযায়ী সঠিক খাবারের চার্ট, টিপস ও রেসিপি পেতে একটি শিশু প্রোফাইল যোগ করুন।',
          action: ElevatedButton.icon(onPressed: _add, icon: const Icon(LucideIcons.plus, size: 16), label: const Text('প্রথম শিশু যোগ করুন')),
        ),
      ]);
    }

    final child = d.children.where((c) => c.id == _selectedId).firstOrNull ?? d.children.first;
    final age = detailedAge(child.dob);
    final tip = ageTipFor(age.ageGroup);

    return switch (_view) {
      'tipDetail' when _tip != null => _tipDetail(_tip!),
      'tips' => _tipsList(),
      'foodChart' => _foodChart(child, age),
      _ => _main(d.children, child, age, tip),
    };
  }

  // --------------------------------------------------------------- main --
  Widget _main(List<Child> children, Child child, ChildAge age, AgeTip tip) {
    final recipes = ref.watch(dataProvider.select((d) => d.recipes));
    final recommended = age.ageGroup == 'under_6m'
        ? const <Recipe>[]
        : recipes.where((r) => r.ageGroup == age.ageGroup || r.ageGroup == '9_12m').take(3).toList();

    return RefreshIndicator(
      color: AppColors.maroon,
      onRefresh: () => ref.read(appDataProvider.notifier).refresh(),
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 14, 16, 32), children: [
        // Child switcher
        SizedBox(
          height: 38,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            for (final c in children)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  avatar: Icon(LucideIcons.baby, size: 14, color: c.id == child.id ? Colors.white : AppColors.maroon),
                  label: Text(c.name),
                  selected: c.id == child.id,
                  showCheckmark: false,
                  selectedColor: AppColors.maroon,
                  backgroundColor: AppColors.cream,
                  labelStyle: ts(12, weight: bold, color: c.id == child.id ? Colors.white : AppColors.ink),
                  onSelected: (_) => setState(() => _selectedId = c.id),
                ),
              ),
            ActionChip(
              avatar: const Icon(LucideIcons.plus, size: 14, color: AppColors.olive),
              label: Text('শিশু যোগ করুন', style: ts(12, weight: bold, color: AppColors.olive)),
              onPressed: _add,
            ),
          ]),
        ),
        const SizedBox(height: 12),
        // Ask doctor banner
        Material(
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.push(Routes.doctor),
            child: Ink(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(gradient: AppColors.brandGradientReverse, borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                const Icon(LucideIcons.stethoscope, color: AppColors.gold),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('ডাক্তারকে জিজ্ঞেস করুন', style: ts(14, weight: bold, color: Colors.white)),
                    Text('(${child.name}) এর স্বাস্থ্য নিয়ে বিশেষজ্ঞের পরামর্শ নিন', style: ts(11, color: AppColors.sand)),
                  ]),
                ),
                const Icon(LucideIcons.chevronRight, color: Colors.white),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Child card
        AppCard(
          child: Column(children: [
            Row(children: [
              child.photo != null
                  ? ClipOval(child: NetImage(child.photo, width: 64, height: 64))
                  : Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(color: AppColors.sandA(0.4), shape: BoxShape.circle),
                      child: const Icon(LucideIcons.baby, color: AppColors.maroon, size: 30),
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Tag(tip.title),
                  const SizedBox(height: 4),
                  Text(child.name, style: ts(17, weight: bold, color: AppColors.maroon)),
                  Text('বয়স: ${age.ageStr}', style: ts(12, color: AppColors.grey600)),
                ]),
              ),
              IconButton(
                tooltip: 'প্রোফাইল এডিট',
                onPressed: () => showChildForm(context, ref, editing: child),
                icon: const Icon(LucideIcons.pencil, size: 17, color: AppColors.olive),
              ),
              IconButton(
                tooltip: 'মুছে ফেলুন',
                onPressed: () => _delete(child),
                icon: const Icon(LucideIcons.trash2, size: 17, color: AppColors.red600),
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: Text('এলার্জি নোট: ${child.allergies ?? 'কোনো এলার্জি নেই'}', style: ts(11, color: AppColors.amber800))),
              const Icon(LucideIcons.lock, size: 11, color: AppColors.grey400),
              const SizedBox(width: 3),
              Text('সুরক্ষিত ও গোপনীয়', style: ts(10, color: AppColors.grey400)),
            ]),
          ]),
        ),
        const SizedBox(height: 12),
        Row(children: [
          _navCard(LucideIcons.utensils, 'খাবারের চার্ট', 'সাপ্তাহিক রুটিন ও মিল প্ল্যান', () => setState(() => _view = 'foodChart')),
          const SizedBox(width: 10),
          _navCard(LucideIcons.sparkles, 'বয়স অনুযায়ী টিপস', 'ঘুম, বিকাশ ও যত্ন গাইডলাইন', () => setState(() => _view = 'tips')),
        ]),
        const SizedBox(height: 12),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionTitle('পুষ্টি গাইডলাইন ও চার্ট সারসংক্ষেপ', icon: LucideIcons.utensils),
            const SizedBox(height: 10),
            for (final item in tip.foodChart)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(LucideIcons.circleCheck, size: 15, color: AppColors.olive),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item, style: ts(12, height: 1.5))),
                ]),
              ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('আজকের গুরুত্বপূর্ণ টিপস', style: ts(12, weight: bold, color: AppColors.maroon)),
                const SizedBox(height: 6),
                for (final t in tip.tips)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(t, style: ts(12, height: 1.5))),
                    ]),
                  ),
              ]),
            ),
            const SizedBox(height: 10),
            InfoBox(tip.medicalDisclaimer),
          ]),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionTitle(
              'প্রস্তাবিত রেসিপি',
              trailing: GestureDetector(
                onTap: _openRecipes,
                child: Text('সব রেসিপি দেখুন →', style: ts(11.5, weight: bold, color: AppColors.olive)),
              ),
            ),
            const SizedBox(height: 10),
            if (age.ageGroup == 'under_6m')
              Text('৬ মাসের কম বয়সী শিশুর জন্য শুধুমাত্র বুকের দুধ প্রযোজ্য। কোনো সলিড রেসিপি নেই।', style: ts(12, color: AppColors.grey600))
            else if (recommended.isEmpty)
              Text('এই বয়সের জন্য কোনো রেসিপি নেই।', style: ts(12, color: AppColors.grey600))
            else
              for (final r in recommended)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: () => _openRecipes(r.id),
                  leading: NetImage(r.image, width: 52, height: 52, radius: 10),
                  title: Text(r.title, style: ts(12.5, weight: bold)),
                  subtitle: Text('প্রস্তুতি: ${r.prepTime} · ${r.ageGroupLabel}', style: ts(10.5, color: AppColors.grey500)),
                  trailing: const Icon(LucideIcons.chevronRight, size: 16),
                ),
          ]),
        ),
      ]),
    );
  }

  Widget _navCard(IconData icon, String title, String sub, VoidCallback onTap) => Expanded(
        child: AppCard(
          onTap: onTap,
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.sandA(0.4), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: AppColors.maroon),
            ),
            const SizedBox(height: 10),
            Text(title, style: ts(13, weight: bold, color: AppColors.maroon)),
            Text(sub, style: ts(10.5, color: AppColors.grey500)),
          ]),
        ),
      );

  Widget _backHeader(String title, {String? subtitle, Widget? trailing}) => Row(children: [
        IconButton.outlined(
          style: IconButton.styleFrom(backgroundColor: Colors.white, side: const BorderSide(color: AppColors.sand)),
          onPressed: () => setState(() => _view = _view == 'tipDetail' ? 'tips' : 'main'),
          icon: const Icon(LucideIcons.arrowLeft, size: 18, color: AppColors.maroon),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: ts(15, weight: bold, color: AppColors.maroon)),
            if (subtitle != null) Text(subtitle, style: ts(11, color: AppColors.grey500)),
          ]),
        ),
        ?trailing,
      ]);

  // ---------------------------------------------------------- food chart --
  Widget _foodChart(Child child, ChildAge age) {
    final recipes = ref.read(dataProvider).recipes;
    String? recipeFor(String kind) => switch (kind) {
          'breakfast' => (recipes.where((r) => r.ageGroup == age.ageGroup).firstOrNull ?? recipes.firstOrNull)?.id,
          'lunch' => recipes.firstOrNull?.id,
          _ => recipes.length > 1 ? recipes[1].id : null,
        };
    final icons = {'breakfast': LucideIcons.sun, 'lunch': LucideIcons.sparkles, 'dinner': LucideIcons.moon};

    return ListView(padding: const EdgeInsets.fromLTRB(16, 14, 16, 32), children: [
      _backHeader('খাবারের চার্ট (ডিমো)',
          subtitle: '${child.name} · ${age.ageStr}',
          trailing: TextButton(
            onPressed: () => toast(context, 'সাপ্তাহিক চার্ট সফলভাবে সেভ করা হয়েছে!'),
            child: const Text('চার্ট সেভ করুন'),
          )),
      const SizedBox(height: 12),
      SizedBox(
        height: 34,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          for (final day in daysOfWeek) PillChip(label: day, selected: _day == day, onTap: () => setState(() => _day = day)),
        ]),
      ),
      const SizedBox(height: 14),
      if (age.totalMonths < 6)
        AppCard(
          color: AppColors.amber50,
          child: Column(children: [
            const Icon(LucideIcons.circleAlert, color: AppColors.amber800, size: 30),
            const SizedBox(height: 8),
            Text('সলিড খাবার প্রযোজ্য নয়', style: ts(14, weight: bold, color: AppColors.amber800)),
            const SizedBox(height: 6),
            Text(
              'আপনার শিশুর বয়স ৬ মাসের কম (${age.ageStr})। বিশ্ব স্বাস্থ্য সংস্থা অনুযায়ী ৬ মাসের কম বয়সী শিশুর জন্য শুধুমাত্র বুকের দুধ প্রযোজ্য।',
              textAlign: TextAlign.center,
              style: ts(12, color: AppColors.amber800, height: 1.5),
            ),
          ]),
        )
      else ...[
        for (final m in foodChartMeals)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(icons[m.kind], size: 15, color: AppColors.gold),
                  const SizedBox(width: 6),
                  Expanded(child: Text(m.label, style: ts(12, weight: bold, color: AppColors.olive))),
                  Text(m.time, style: ts(11, color: AppColors.grey500)),
                ]),
                const SizedBox(height: 8),
                Text(m.title, style: ts(13.5, weight: bold)),
                Text(m.note, style: ts(11.5, color: AppColors.grey600)),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                    onPressed: () => _openRecipes(recipeFor(m.kind)),
                    child: const Text('রেসিপি দেখুন'),
                  ),
                ),
              ]),
            ),
          ),
        const InfoBox('নোট: এটি একটি নমুনা বা ডেমো খাবারের চার্ট। শিশুর বয়স ও রুচি অনুযায়ী পরিবর্তনশীল। প্রফেশনাল পুষ্টিবিদ দ্বারা পর্যালোচিত নয়।'),
      ],
    ]);
  }

  // ---------------------------------------------------------------- tips --
  Widget _tipsList() {
    final list = _tipCategory == 'সব' ? tips : tips.where((t) => t.category == _tipCategory).toList();
    return ListView(padding: const EdgeInsets.fromLTRB(16, 14, 16, 32), children: [
      _backHeader('বয়স অনুযায়ী টিপস ও গাইডলাইন'),
      const SizedBox(height: 12),
      SizedBox(
        height: 34,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          for (final c in tipCategories) PillChip(label: c, selected: _tipCategory == c, onTap: () => setState(() => _tipCategory = c)),
        ]),
      ),
      const SizedBox(height: 12),
      for (final t in list)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            onTap: () => setState(() {
              _tip = t;
              _view = 'tipDetail';
            }),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Tag(t.category),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _savedTips.contains(t.id) ? _savedTips.remove(t.id) : _savedTips.add(t.id)),
                  child: Icon(LucideIcons.bookmark, size: 18, color: _savedTips.contains(t.id) ? AppColors.maroon : AppColors.grey400),
                ),
              ]),
              const SizedBox(height: 8),
              Text(t.title, style: ts(13.5, weight: bold, color: AppColors.maroon)),
              const SizedBox(height: 4),
              Text(t.preview, style: ts(12, color: AppColors.grey600, height: 1.5)),
            ]),
          ),
        ),
    ]);
  }

  Widget _tipDetail(TipItem t) {
    final saved = _savedTips.contains(t.id);
    return ListView(padding: const EdgeInsets.fromLTRB(16, 14, 16, 32), children: [
      _backHeader(t.title, subtitle: t.category),
      const SizedBox(height: 12),
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.content, style: ts(13, height: 1.7)),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: Text('পেশাদার পুষ্টিবিদ ও শিশু বিশেষজ্ঞ দ্বারা পরীক্ষিত', style: ts(10.5, color: AppColors.grey400))),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: saved ? AppColors.maroon : AppColors.cream,
                foregroundColor: saved ? Colors.white : AppColors.maroon,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: () => setState(() => saved ? _savedTips.remove(t.id) : _savedTips.add(t.id)),
              icon: const Icon(LucideIcons.bookmark, size: 14),
              label: Text(saved ? 'সংরক্ষিত' : 'সেভ করুন'),
            ),
          ]),
        ]),
      ),
    ]);
  }
}
