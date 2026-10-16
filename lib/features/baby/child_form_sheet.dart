import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/image_data_url.dart';
import '../../data/models/medical.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/net_image.dart';
import '../../state/app_data_controller.dart';

/// Add / edit child (MyBabyTab.tsx modal). Saves via `setChildren`, which
/// syncs `PUT /sync/children`. Returns the id of the saved child.
Future<String?> showChildForm(BuildContext context, WidgetRef ref, {Child? editing}) async {
  // Edit the freshest list so we don't overwrite a child added on the web.
  await ref.read(appDataProvider.notifier).refreshQuietly();
  if (!context.mounted) return null;
  return showAppSheet<String>(
    context,
    title: editing != null ? 'শিশু প্রোফাইল এডিট করুন' : 'নতুন সন্তান যোগ করুন',
    builder: (_) => _ChildForm(editing: editing),
  );
}

class _ChildForm extends ConsumerStatefulWidget {
  const _ChildForm({this.editing});
  final Child? editing;

  @override
  ConsumerState<_ChildForm> createState() => _ChildFormState();
}

class _ChildFormState extends ConsumerState<_ChildForm> {
  late final _name = TextEditingController(text: widget.editing?.name ?? '');
  late final _allergies = TextEditingController(text: widget.editing?.allergies ?? '');
  late String _dob = widget.editing?.dob ?? '';
  late String? _photo = widget.editing?.photo;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _allergies.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dob) ?? now.subtract(const Duration(days: 270)),
      firstDate: DateTime(now.year - 12),
      lastDate: now,
    );
    if (picked != null) setState(() => _dob = DateFormat('yyyy-MM-dd').format(picked));
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _dob.isEmpty) {
      setState(() => _error = 'শিশুর নাম ও জন্মতারিখ আবশ্যক।');
      return;
    }
    if (DateTime.parse(_dob).isAfter(DateTime.now())) {
      setState(() => _error = 'ভবিষ্যতের জন্মতারিখ গ্রহণযোগ্য নয়।');
      return;
    }
    final allergies = _allergies.text.trim().isEmpty ? 'কোনো এলার্জি নেই' : _allergies.text.trim();
    final list = ref.read(dataProvider).children;
    final data = ref.read(appDataProvider.notifier);
    final String id;
    if (widget.editing != null) {
      id = widget.editing!.id;
      data.setChildren([
        for (final c in list) c.id == id ? Child(id: id, name: _name.text.trim(), dob: _dob, photo: _photo, allergies: allergies) : c,
      ]);
    } else {
      // Same id format as the web: 'child-' + Date.now()
      id = 'child-${DateTime.now().millisecondsSinceEpoch}';
      data.setChildren([...list, Child(id: id, name: _name.text.trim(), dob: _dob, photo: _photo, allergies: allergies)]);
    }
    Navigator.pop(context, id);
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Center(
        child: GestureDetector(
          onTap: () async {
            try {
              final url = await pickImageAsDataUrl(context, maxSide: 600);
              if (url != null) setState(() => _photo = url);
            } catch (e) {
              if (context.mounted) toastError(context, e);
            }
          },
          child: Stack(children: [
            _photo != null
                ? ClipOval(child: NetImage(_photo, width: 88, height: 88))
                : Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(color: AppColors.sandA(0.4), shape: BoxShape.circle),
                    child: const Icon(LucideIcons.baby, size: 38, color: AppColors.maroon),
                  ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: AppColors.maroon, shape: BoxShape.circle),
                child: const Icon(LucideIcons.camera, size: 14, color: Colors.white),
              ),
            ),
          ]),
        ),
      ),
      if (_photo != null)
        Center(child: TextButton(onPressed: () => setState(() => _photo = null), child: const Text('ছবি সরান'))),
      const FieldLabel('শিশুর নাম'),
      TextField(controller: _name, maxLength: 80, decoration: const InputDecoration(hintText: 'নাম লিখুন', counterText: '')),
      const SizedBox(height: 8),
      const FieldLabel('জন্মতারিখ'),
      InkWell(
        onTap: _pickDob,
        child: InputDecorator(
          decoration: const InputDecoration(suffixIcon: Icon(LucideIcons.calendar, size: 18)),
          child: Text(_dob.isEmpty ? 'তারিখ নির্বাচন করুন' : _dob, style: ts(13, color: _dob.isEmpty ? AppColors.grey400 : null)),
        ),
      ),
      const SizedBox(height: 8),
      const FieldLabel('এলার্জি বা বিশেষ নোট'),
      TextField(controller: _allergies, maxLength: 500, decoration: const InputDecoration(hintText: 'যেমন: কোনো এলার্জি নেই', counterText: '')),
      if (_error != null) ...[const SizedBox(height: 10), ErrorBox(_error!)],
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('বাতিল'))),
        const SizedBox(width: 10),
        Expanded(child: BusyButton(label: 'সেভ করুন', onPressed: _save)),
      ]),
    ]);
  }
}
