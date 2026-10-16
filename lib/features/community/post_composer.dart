import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/image_data_url.dart';
import '../../data/models/community.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/net_image.dart';
import '../../state/app_data_controller.dart';
import '../../state/providers.dart';

/// Create / edit post sheet (CommunityTab.tsx "showCreateModal").
///
/// [fixedTopic] is used by the User Timeline composer, which always posts as
/// 'মায়ের গল্প' (same as UserTimelineScreen.tsx).
Future<void> showPostComposer(BuildContext context, {Post? editing, String? fixedTopic, bool pickImageFirst = false}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      showDragHandle: false,
      builder: (_) => _PostComposer(editing: editing, fixedTopic: fixedTopic, pickImageFirst: pickImageFirst),
    );

class _PostComposer extends ConsumerStatefulWidget {
  const _PostComposer({this.editing, this.fixedTopic, this.pickImageFirst = false});
  final Post? editing;
  final String? fixedTopic;
  final bool pickImageFirst;

  @override
  ConsumerState<_PostComposer> createState() => _PostComposerState();
}

class _PostComposerState extends ConsumerState<_PostComposer> {
  late final _content = TextEditingController(text: widget.editing?.content ?? '');
  late String _topic = widget.fixedTopic ??
      (postTopics.contains(widget.editing?.topic) ? widget.editing!.topic : postTopics.first);
  late String? _media = widget.editing?.mediaUrl;
  String? _error;
  bool _success = false;

  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    if (widget.pickImageFirst) WidgetsBinding.instance.addPostFrameCallback((_) => _pickImage());
  }

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final url = await pickImageAsDataUrl(context);
      if (url != null) setState(() => _media = url);
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }

  Future<void> _close() async {
    if (_content.text.trim().isNotEmpty && !_success) {
      final ok = await confirmDialog(context, 'আপনার অসমাপ্ত পোস্টটি বাতিল করতে চান?');
      if (!ok) return;
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _publish() async {
    if (_content.text.trim().isEmpty) {
      setState(() => _error = 'পোস্টের বিষয়বস্তু খালি রাখা যাবে না।');
      return;
    }
    setState(() => _error = null);
    final api = ref.read(apiProvider);
    final data = ref.read(appDataProvider.notifier);
    try {
      if (_isEdit) {
        final p = await api.updatePost(widget.editing!.id, content: _content.text, topic: _topic, mediaUrl: _media ?? '');
        data.upsertPost(p);
      } else {
        // Points (+5 text/image, +10 video) are awarded by the server.
        final r = await api.createPost(content: _content.text, topic: _topic, mediaUrl: _media);
        data.upsertPost(r.post, prepend: true);
        data.addRewardTx(r.rewardTx);
      }
      setState(() => _success = true);
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = errorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(
                child: Text(_isEdit ? 'পোস্ট এডিট করুন' : 'নতুন পোস্ট তৈরি করুন',
                    style: ts(16, weight: bold, color: AppColors.maroon)),
              ),
              IconButton(onPressed: _close, icon: const Icon(LucideIcons.x, size: 20)),
            ]),
            const SizedBox(height: 8),
            if (widget.fixedTopic == null) ...[
              const FieldLabel('টপিক নির্বাচন করুন'),
              DropdownButtonFormField<String>(
                initialValue: _topic,
                items: [for (final t in postTopics) DropdownMenuItem(value: t, child: Text(t, style: ts(13)))],
                onChanged: (v) => setState(() => _topic = v ?? _topic),
              ),
              const SizedBox(height: 10),
            ],
            const FieldLabel('আপনার অভিজ্ঞতা লিখুন'),
            TextField(
              controller: _content,
              minLines: 4,
              maxLines: 10,
              maxLength: 5000,
              decoration: const InputDecoration(hintText: 'কী শেয়ার করতে চান মা?', counterText: ''),
            ),
            const SizedBox(height: 10),
            const FieldLabel('ছবি (ঐচ্ছিক)'),
            if (_media != null && _media!.isNotEmpty)
              Stack(children: [
                NetImage(_media, height: 180, width: double.infinity, radius: 12),
                Positioned(
                  top: 6,
                  right: 6,
                  child: IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: Colors.black54),
                    onPressed: () => setState(() => _media = null),
                    icon: const Icon(LucideIcons.x, size: 16, color: Colors.white),
                  ),
                ),
              ])
            else
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(LucideIcons.image, size: 16),
                label: const Text('ছবি যোগ করুন'),
              ),
            if (_error != null) ...[const SizedBox(height: 10), ErrorBox(_error!)],
            if (_success) ...[
              const SizedBox(height: 10),
              InfoBox(
                _isEdit ? 'পরিবর্তন সেভ হয়েছে!' : 'পোস্ট সফলভাবে প্রকাশিত হয়েছে!',
                icon: LucideIcons.circleCheck,
                bg: AppColors.green50,
                fg: AppColors.green700,
              ),
            ],
            const SizedBox(height: 14),
            BusyButton(
              label: _isEdit ? 'পরিবর্তন সেভ করুন' : 'পোস্ট প্রকাশ করুন (+৫ পয়েন্ট)',
              busyLabel: 'প্রকাশ করা হচ্ছে...',
              onPressed: _success ? null : _publish,
            ),
          ]),
        ),
      ),
    );
  }
}
