import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/image_data_url.dart';
import '../../data/models/complaint.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/net_image.dart';
import '../../state/providers.dart';

/// "অভিযোগ ও সাপোর্ট": the user's complaints with status / admin reply,
/// plus a form to file a new one (`GET/POST /complaints`).
class ComplaintsScreen extends ConsumerStatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  ConsumerState<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends ConsumerState<ComplaintsScreen> {
  List<Complaint>? _items;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await ref.read(apiProvider).myComplaints();
      if (mounted) {
        setState(() {
          _items = items;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _new() async {
    final created = await showAppSheet<Complaint>(context, title: 'নতুন অভিযোগ', builder: (_) => const _ComplaintForm());
    if (created != null && mounted) {
      setState(() => _items = [created, ...?_items]);
      toast(context, 'আপনার অভিযোগ জমা হয়েছে। আমরা দ্রুত দেখব।');
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Scaffold(
      appBar: AppBar(title: const Text('অভিযোগ ও সাপোর্ট')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.maroon,
        foregroundColor: Colors.white,
        onPressed: _new,
        icon: const Icon(LucideIcons.plus, size: 18),
        label: const Text('নতুন অভিযোগ'),
      ),
      body: RefreshIndicator(
        color: AppColors.maroon,
        onRefresh: _load,
        child: _error != null && items == null
            ? ListView(children: [
                const SizedBox(height: 80),
                EmptyState(
                  icon: LucideIcons.wifiOff,
                  title: errorMessage(_error!),
                  action: TextButton(onPressed: _load, child: const Text('আবার চেষ্টা করুন')),
                ),
              ])
            : items == null
                ? const Center(child: CircularProgressIndicator(color: AppColors.maroon))
                : ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 96), children: [
                    const InfoBox(
                      'অর্ডার, প্রোডাক্ট, পেমেন্ট, অ্যাপ বা কমিউনিটির যেকোনো সমস্যা আমাদের জানান। অ্যাডমিন উত্তর দিলে নোটিফিকেশন পাবেন।',
                      icon: LucideIcons.messageSquareWarning,
                      bg: AppColors.blue50,
                      fg: AppColors.blue600,
                    ),
                    const SizedBox(height: 14),
                    if (items.isEmpty)
                      const EmptyState(icon: LucideIcons.inbox, title: 'এখনো কোনো অভিযোগ করেননি।')
                    else
                      for (final c in items) ...[ComplaintCard(c), const SizedBox(height: 10)],
                  ]),
      ),
    );
  }
}

/// One complaint with its status and the admin's reply. Also used by the admin inbox.
class ComplaintCard extends StatelessWidget {
  const ComplaintCard(this.c, {super.key, this.showUser = false, this.footer});

  final Complaint c;
  final bool showUser;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(c.categoryLabel, style: ts(13.5, weight: bold, color: AppColors.maroon))),
          ComplaintStatusChip(c.status),
        ]),
        const SizedBox(height: 2),
        Text(
          showUser ? '${c.userName} · ${c.userContact} · ${c.createdAt}' : '#${c.id} · ${c.createdAt}',
          style: ts(10.5, color: AppColors.grey500),
        ),
        const SizedBox(height: 8),
        Text(c.details, style: ts(12.5, height: 1.45)),
        if (c.attachmentUrl != null && c.attachmentUrl!.isNotEmpty) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => showDialog<void>(
              context: context,
              builder: (ctx) => GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: InteractiveViewer(child: Center(child: NetImage(c.attachmentUrl!, fit: BoxFit.contain))),
              ),
            ),
            child: NetImage(c.attachmentUrl!, height: 120, width: 160, radius: 10),
          ),
        ],
        if (c.adminReply.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.sandA(0.3), borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('অ্যাডমিনের উত্তর', style: ts(11, weight: bold, color: AppColors.olive)),
              const SizedBox(height: 2),
              Text(c.adminReply, style: ts(12.5, height: 1.4)),
            ]),
          ),
        ],
        ?footer,
      ]),
    );
  }
}

class ComplaintStatusChip extends StatelessWidget {
  const ComplaintStatusChip(this.status, {super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      'resolved' => (AppColors.green50, AppColors.green700),
      'in_progress' => (AppColors.blue50, AppColors.blue600),
      _ => (AppColors.amber50, AppColors.amber800),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(complaintStatuses[status] ?? status, style: ts(10.5, weight: bold, color: fg)),
    );
  }
}

class _ComplaintForm extends ConsumerStatefulWidget {
  const _ComplaintForm();

  @override
  ConsumerState<_ComplaintForm> createState() => _ComplaintFormState();
}

class _ComplaintFormState extends ConsumerState<_ComplaintForm> {
  String? _category;
  final _details = TextEditingController();
  String? _attachment;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    try {
      final url = await pickImageAsDataUrl(context, maxSide: 1280);
      if (url != null) setState(() => _attachment = url);
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }

  Future<void> _submit() async {
    if (_category == null) {
      toast(context, 'অভিযোগের ধরন নির্বাচন করুন।');
      return;
    }
    if (_details.text.trim().length < 10) {
      toast(context, 'সমস্যাটি একটু বিস্তারিত লিখুন (কমপক্ষে ১০ অক্ষর)।');
      return;
    }
    try {
      final c = await ref
          .read(apiProvider)
          .createComplaint(category: _category!, details: _details.text.trim(), attachmentUrl: _attachment);
      if (mounted) Navigator.pop(context, c);
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const FieldLabel('অভিযোগের ধরন'),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final e in complaintCategories.entries)
          PillChip(label: e.value, selected: _category == e.key, onTap: () => setState(() => _category = e.key)),
      ]),
      const SizedBox(height: 14),
      const FieldLabel('বিস্তারিত লিখুন'),
      TextField(
        controller: _details,
        minLines: 4,
        maxLines: 8,
        maxLength: 2000,
        decoration: const InputDecoration(hintText: 'কী সমস্যা হয়েছে? অর্ডার নম্বর থাকলে লিখুন।', counterText: ''),
      ),
      const SizedBox(height: 10),
      const FieldLabel('স্ক্রিনশট / ছবি (ঐচ্ছিক)'),
      if (_attachment == null)
        OutlinedButton.icon(onPressed: _pick, icon: const Icon(LucideIcons.imagePlus, size: 16), label: const Text('ছবি যোগ করুন'))
      else
        Row(children: [
          NetImage(_attachment!, height: 72, width: 72, radius: 10),
          const SizedBox(width: 10),
          TextButton(onPressed: () => setState(() => _attachment = null), child: const Text('ছবি সরান')),
        ]),
      const SizedBox(height: 18),
      BusyButton(label: 'অভিযোগ জমা দিন', busyLabel: 'জমা হচ্ছে...', onPressed: _submit),
    ]);
  }
}
