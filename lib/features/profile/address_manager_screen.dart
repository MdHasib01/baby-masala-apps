import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/bn_digits.dart';
import '../../data/models/user.dart';
import '../../shared/widgets/common.dart';
import '../../state/app_data_controller.dart';

/// Port of components/profile/AddressManagerModal.tsx — unreachable on web,
/// opened from the drawer on mobile. Saves `user.addresses` via `PATCH /me`.
class AddressManagerScreen extends ConsumerStatefulWidget {
  const AddressManagerScreen({super.key});

  @override
  ConsumerState<AddressManagerScreen> createState() => _AddressManagerScreenState();
}

class _AddressManagerScreenState extends ConsumerState<AddressManagerScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(appDataProvider.notifier).refreshQuietly();
  }

  void _setAddresses(List<Address> list) {
    final u = ref.read(dataProvider).user;
    ref.read(appDataProvider.notifier).setUser(u.copyWith(addresses: list));
  }

  Future<void> _delete(Address a) async {
    final list = ref.read(dataProvider).user.addresses;
    if (list.length <= 1) {
      await alertDialog(context, 'কমপক্ষে একটি ঠিকানা থাকা আবশ্যক।');
      return;
    }
    final rest = list.where((x) => x.id != a.id).toList();
    if (a.isDefault && rest.isNotEmpty) rest[0] = rest[0].copyWith(isDefault: true);
    _setAddresses(rest);
  }

  @override
  Widget build(BuildContext context) {
    final addresses = ref.watch(dataProvider.select((d) => d.user.addresses));
    return Scaffold(
      appBar: AppBar(title: const Text('ঠিকানা ম্যানেজমেন্ট')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.maroon,
        foregroundColor: Colors.white,
        onPressed: () => showAppSheet<void>(context, title: 'নতুন ঠিকানা যোগ করুন', builder: (_) => _AddressForm(onSave: _setAddresses)),
        icon: const Icon(LucideIcons.plus),
        label: const Text('নতুন ঠিকানা'),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 96), children: [
        Text('আপনার সেভ করা ঠিকানা (${toBnDigits(addresses.length)})', style: ts(13, weight: bold, color: AppColors.maroon)),
        const SizedBox(height: 10),
        if (addresses.isEmpty) const EmptyState(icon: LucideIcons.mapPin, title: 'কোনো ঠিকানা সেভ করা নেই'),
        for (final a in addresses)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              padding: const EdgeInsets.all(12),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(LucideIcons.mapPin, size: 18, color: AppColors.olive),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(a.title, style: ts(13, weight: bold)),
                      if (a.isDefault) ...[
                        const SizedBox(width: 6),
                        const Tag('ডিফল্ট', bg: AppColors.green50, fg: AppColors.green700),
                      ],
                    ]),
                    const SizedBox(height: 2),
                    Text(a.details, style: ts(12, color: AppColors.grey600, height: 1.4)),
                    if (a.phone.isNotEmpty) Text(a.phone, style: ts(11, color: AppColors.grey500)),
                    if (!a.isDefault)
                      TextButton(
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 30)),
                        onPressed: () => _setAddresses([for (final x in addresses) x.copyWith(isDefault: x.id == a.id)]),
                        child: const Text('ডিফল্ট করুন'),
                      ),
                  ]),
                ),
                IconButton(
                  onPressed: () => showAppSheet<void>(context,
                      title: 'ঠিকানা সংশোধন', builder: (_) => _AddressForm(editing: a, onSave: _setAddresses)),
                  icon: const Icon(LucideIcons.pencil, size: 16, color: AppColors.olive),
                ),
                IconButton(onPressed: () => _delete(a), icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.red600)),
              ]),
            ),
          ),
      ]),
    );
  }
}

class _AddressForm extends ConsumerStatefulWidget {
  const _AddressForm({this.editing, required this.onSave});
  final Address? editing;
  final void Function(List<Address>) onSave;

  @override
  ConsumerState<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends ConsumerState<_AddressForm> {
  static const _districts = ['ঢাকা', 'চট্টগ্রাম', 'সিলেট', 'রাজশাহী', 'খুলনা', 'বরিশাল', 'রংপুর', 'ময়মনসিংহ'];
  late final _title = TextEditingController(text: widget.editing?.title ?? '');
  late final _phone = TextEditingController(text: widget.editing?.phone ?? ref.read(dataProvider).user.contact);
  final _area = TextEditingController();
  late final _details = TextEditingController(text: widget.editing?.details ?? '');
  String _district = _districts.first;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _phone.dispose();
    _area.dispose();
    _details.dispose();
    super.dispose();
  }

  void _save() {
    final isEdit = widget.editing != null;
    if ((!isEdit && _area.text.trim().isEmpty) || _details.text.trim().isEmpty) {
      setState(() => _error = 'এলাকা ও বিস্তারিত ঠিকানা আবশ্যক।');
      return;
    }
    // Same format as the web: "{area}, {district} - {details}"
    final details = _area.text.trim().isEmpty ? _details.text.trim() : '${_area.text.trim()}, $_district - ${_details.text.trim()}';
    final title = _title.text.trim().isEmpty ? 'বাসা' : _title.text.trim();
    final list = ref.read(dataProvider).user.addresses;
    widget.onSave(isEdit
        ? [for (final a in list) a.id == widget.editing!.id ? a.copyWith(title: title, details: details, phone: _phone.text.trim()) : a]
        : [
            ...list,
            Address(
              id: 'addr-${DateTime.now().millisecondsSinceEpoch}',
              title: title,
              details: details,
              phone: _phone.text.trim(),
              isDefault: list.isEmpty,
            ),
          ]);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const FieldLabel('ঠিকানার নাম (যেমন: বাসা / অফিস)'),
      TextField(controller: _title, decoration: const InputDecoration(hintText: 'বাসা')),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const FieldLabel('জেলা'),
            DropdownButtonFormField<String>(
              initialValue: _district,
              items: [for (final d in _districts) DropdownMenuItem(value: d, child: Text(d, style: ts(13)))],
              onChanged: (v) => setState(() => _district = v ?? _district),
            ),
          ]),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const FieldLabel('এলাকা'),
            TextField(controller: _area, decoration: const InputDecoration(hintText: 'ধানমন্ডি / গুলশান')),
          ]),
        ),
      ]),
      const SizedBox(height: 8),
      const FieldLabel('বিস্তারিত ঠিকানা'),
      TextField(controller: _details, minLines: 2, maxLines: 3, decoration: const InputDecoration(hintText: 'রোড নম্বর, বাসা নম্বর...')),
      const SizedBox(height: 8),
      const FieldLabel('মোবাইল'),
      TextField(controller: _phone, keyboardType: TextInputType.phone),
      if (_error != null) ...[const SizedBox(height: 10), ErrorBox(_error!)],
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('বাতিল'))),
        const SizedBox(width: 10),
        Expanded(child: BusyButton(label: 'সংরক্ষণ করুন', onPressed: () async => _save())),
      ]),
    ]);
  }
}
