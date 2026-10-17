import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/bn_digits.dart';
import '../../data/models/commerce.dart';
import '../../data/models/complaint.dart';
import '../../data/services/baby_care_api.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/net_image.dart';
import '../../state/app_data_controller.dart';
import '../../state/providers.dart';
import '../complaints/complaints_screen.dart';

/// Admin console — port of components/AdminModal.tsx (admins only).
///
/// Mobile extras (see MOBILE_SYNC.md §6): post status approve/reject
/// (`PATCH /admin/posts/:id`), submission moderation
/// (`PATCH /admin/submissions/:id`) and the real points rules.
class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  AdminOverview? _data;
  String? _error;
  late final AppDataController _store;

  @override
  void initState() {
    super.initState();
    _store = ref.read(appDataProvider.notifier);
    _load();
  }

  @override
  void dispose() {
    // Same as web: closing admin silently re-runs bootstrap.
    _store.refreshQuietly();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final d = await ref.read(apiProvider).admin.overview();
      if (mounted) setState(() => _data = d);
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(e));
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      await _load();
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }

  Future<void> _reply(Complaint c) async {
    final text = TextEditingController(text: c.adminReply);
    final reply = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('অভিযোগের উত্তর'),
        content: TextField(
          controller: text,
          autofocus: true,
          minLines: 3,
          maxLines: 6,
          maxLength: 1000,
          decoration: const InputDecoration(hintText: 'ইউজার নোটিফিকেশনে এই উত্তর দেখবেন'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, text.text.trim()), child: const Text('পাঠান')),
        ],
      ),
    );
    text.dispose();
    if (reply == null) return;
    // Replying moves a fresh complaint along to "in progress".
    await _run(() async => ref
        .read(apiProvider)
        .admin
        .updateComplaint(c.id, adminReply: reply, status: c.status == 'open' && reply.isNotEmpty ? 'in_progress' : null));
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    final contests = ref.watch(dataProvider.select((x) => x.contests));
    final admin = ref.read(apiProvider).admin;

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('ডেমো অ্যাডমিন প্যানেল'),
            Text('বেবি কেয়ার ও বেবি মসলা ম্যানেজমেন্ট কনসোল', style: ts(10.5, color: AppColors.grey500)),
          ]),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'পোস্ট ও রিপোর্ট (${toBnDigits(d?.posts.length ?? 0)})'),
              Tab(text: 'অভিযোগ (${toBnDigits(d?.complaints.where((c) => c.status != 'resolved').length ?? 0)})'),
              Tab(text: 'অর্ডার ও ডেলিভারি (${toBnDigits(d?.orders.length ?? 0)})'),
              Tab(text: 'প্রোডাক্ট ও স্টক (${toBnDigits(d?.products.length ?? 0)})'),
              Tab(text: 'কনটেস্ট ও সাবমিশন (${toBnDigits(d?.submissions.length ?? 0)})'),
              const Tab(text: 'কুপন ও পয়েন্ট রুলস'),
            ],
          ),
        ),
        body: _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    ErrorBox(_error!),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _load, child: const Text('আবার চেষ্টা করুন')),
                  ]),
                ),
              )
            : d == null
                ? const Center(child: CircularProgressIndicator(color: AppColors.maroon))
                : TabBarView(children: [
                    // ---- posts
                    _list([
                      for (final (:post, :reportsCount) in d.posts)
                        AppCard(
                          padding: const EdgeInsets.all(12),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: Text(post.authorName, style: ts(12.5, weight: bold))),
                              Tag(post.topic, bg: AppColors.cream),
                              if (reportsCount > 0) ...[
                                const SizedBox(width: 4),
                                Tag('রিপোর্ট ${toBnDigits(reportsCount)}', bg: AppColors.red50, fg: AppColors.red600),
                              ],
                            ]),
                            const SizedBox(height: 6),
                            Text(post.content, style: ts(12, height: 1.4), maxLines: 4, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(post.createdAt, style: ts(10, color: AppColors.grey500)),
                            const SizedBox(height: 8),
                            Row(children: [
                              _statusMenu(
                                value: post.status,
                                options: const {'approved': 'অনুমোদিত', 'pending': 'পেন্ডিং', 'rejected': 'প্রত্যাখ্যাত'},
                                onChanged: (s) => _run(() async => admin.setPostStatus(post.id, s)),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () async {
                                  if (await confirmDialog(context, 'পোস্টটি মুছে ফেলবেন?', danger: true)) {
                                    _run(() => admin.deletePost(post.id));
                                  }
                                },
                                icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.red600),
                              ),
                            ]),
                          ]),
                        ),
                    ]),
                    // ---- complaints
                    _list([
                      if (d.complaints.isEmpty)
                        const EmptyState(icon: LucideIcons.inbox, title: 'কোনো অভিযোগ নেই।')
                      else
                        for (final c in d.complaints)
                          ComplaintCard(
                            c,
                            showUser: true,
                            footer: Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Row(children: [
                                _statusMenu(
                                  value: c.status,
                                  options: complaintStatuses,
                                  onChanged: (s) => _run(() async => admin.updateComplaint(c.id, status: s)),
                                ),
                                const Spacer(),
                                TextButton.icon(
                                  onPressed: () => _reply(c),
                                  icon: const Icon(LucideIcons.reply, size: 15),
                                  label: Text(c.adminReply.isEmpty ? 'উত্তর দিন' : 'উত্তর এডিট'),
                                ),
                              ]),
                            ),
                          ),
                    ]),
                    // ---- orders
                    _list([
                      for (final o in d.orders)
                        AppCard(
                          padding: const EdgeInsets.all(12),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: Text('অর্ডার #${o.id} (${o.createdAt})', style: ts(12, weight: bold))),
                              Text(taka(o.totalAmount), style: ts(13, weight: bold, color: AppColors.maroon)),
                            ]),
                            const SizedBox(height: 4),
                            Text('শিপিং ঠিকানা: ${o.shippingAddress}', style: ts(11.5, color: AppColors.grey600)),
                            const SizedBox(height: 8),
                            Row(children: [
                              Text('স্ট্যাটাস পরিবর্তন: ', style: ts(11.5)),
                              _statusMenu(
                                value: o.status,
                                options: const {
                                  'pending': 'পেন্ডিং',
                                  'confirmed': 'নিশ্চিত',
                                  'shipped': 'শিপড',
                                  'delivered': 'ডেলিভারি সম্পন্ন',
                                  'cancelled': 'বাতিল (পয়েন্ট রিভার্স)',
                                },
                                enabled: o.status != 'cancelled',
                                onChanged: (s) => _run(() async => admin.updateOrderStatus(o.id, s)),
                              ),
                            ]),
                          ]),
                        ),
                    ]),
                    // ---- products
                    _list([for (final p in d.products) _ProductStockRow(product: p, onSave: (s) => _run(() async => admin.updateProduct(p.id, stock: s)))]),
                    // ---- contests & submissions
                    _list([
                      for (final c in contests)
                        AppCard(
                          padding: const EdgeInsets.all(12),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(c.title, style: ts(13, weight: bold, color: AppColors.maroon)),
                            Text(c.description, style: ts(11.5, color: AppColors.grey600)),
                            Text('পুরস্কার: ${c.prize}', style: ts(11.5, weight: semi, color: AppColors.olive)),
                          ]),
                        ),
                      if (d.submissions.isNotEmpty) Text('সাবমিশন', style: ts(13, weight: bold)),
                      for (final s in d.submissions)
                        AppCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(children: [
                            if (s.mediaUrl.isNotEmpty) ...[NetImage(s.mediaUrl, width: 48, height: 48, radius: 8), const SizedBox(width: 10)],
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(s.userName, style: ts(12, weight: bold)),
                                Text(s.description, style: ts(11.5), maxLines: 2, overflow: TextOverflow.ellipsis),
                              ]),
                            ),
                            _statusMenu(
                              value: s.status,
                              options: const {'pending': 'পেন্ডিং', 'approved': 'অনুমোদিত', 'rejected': 'প্রত্যাখ্যাত'},
                              onChanged: (st) => _run(() async => admin.setSubmissionStatus(s.id, st)),
                            ),
                          ]),
                        ),
                    ]),
                    // ---- coupons & rules
                    _list([
                      AppCard(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('সক্রিয় কুপন কোড', style: ts(13, weight: bold, color: AppColors.maroon)),
                          const SizedBox(height: 8),
                          Row(children: [
                            const Tag('BABYCARE', bg: AppColors.gold, fg: AppColors.maroon),
                            const SizedBox(width: 8),
                            Text('৳ ৮,০০০ মেম্বারশিপ ফ্রি', style: ts(12)),
                          ]),
                        ]),
                      ),
                      AppCard(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('পয়েন্ট অর্জনের রুলস (সার্ভার)', style: ts(13, weight: bold, color: AppColors.maroon)),
                          const SizedBox(height: 8),
                          for (final r in const [
                            'টেক্সট বা ছবি পোস্ট: +৫ পয়েন্ট',
                            'ভিডিও পোস্ট: +১০ পয়েন্ট',
                            'রিঅ্যাকশন (প্রতি পোস্টে প্রথমবার): +২ পয়েন্ট',
                            'কমেন্ট: +২ পয়েন্ট',
                            'কেনাকাটা: প্রোডাক্টের পয়েন্ট × পরিমাণ (না থাকলে প্রতি ১০ টাকায় ১ পয়েন্ট)',
                            'কনটেস্ট অংশগ্রহণ: কনটেস্টের পয়েন্ট (ডিফল্ট ৫০)',
                            'অর্ডার বাতিল: অর্জিত পয়েন্ট রিভার্স',
                          ])
                            Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('• $r', style: ts(12, height: 1.5))),
                        ]),
                      ),
                    ]),
                  ]),
      ),
    );
  }

  Widget _list(List<Widget> children) => RefreshIndicator(
        color: AppColors.maroon,
        onRefresh: _load,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: children.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, i) => children[i],
        ),
      );

  Widget _statusMenu({
    required String value,
    required Map<String, String> options,
    required void Function(String) onChanged,
    bool enabled = true,
  }) =>
      DropdownButton<String>(
        value: options.containsKey(value) ? value : null,
        isDense: true,
        style: ts(12, weight: bold, color: AppColors.maroon),
        items: [for (final e in options.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
        onChanged: enabled ? (v) => v != null && v != value ? onChanged(v) : null : null,
      );
}

class _ProductStockRow extends StatefulWidget {
  const _ProductStockRow({required this.product, required this.onSave});
  final Product product;
  final void Function(int stock) onSave;

  @override
  State<_ProductStockRow> createState() => _ProductStockRowState();
}

class _ProductStockRowState extends State<_ProductStockRow> {
  late final _ctrl = TextEditingController(text: '${widget.product.stock}');

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        NetImage(p.image, width: 48, height: 48, radius: 8),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.name, style: ts(12.5, weight: bold)),
            Text(taka(p.price), style: ts(11.5, color: AppColors.olive)),
          ]),
        ),
        Text('স্টক:', style: ts(11.5)),
        const SizedBox(width: 6),
        SizedBox(
          width: 64,
          child: TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            onSubmitted: (v) => widget.onSave((int.tryParse(v) ?? 0).clamp(0, 1 << 30)),
          ),
        ),
        IconButton(
          onPressed: () => widget.onSave((int.tryParse(_ctrl.text) ?? 0).clamp(0, 1 << 30)),
          icon: const Icon(LucideIcons.check, size: 18, color: AppColors.green700),
        ),
      ]),
    );
  }
}
