import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/bn_digits.dart';
import '../../data/models/commerce.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/net_image.dart';
import '../../state/app_data_controller.dart';
import '../../state/providers.dart';
import 'cart_logic.dart';
import 'product_sheet.dart';

/// Cart bottom sheet (ShopTab.tsx "showCart").
Future<void> showCartSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (_) => const SheetDragToClose(child: _CartSheet()),
    );

class _CartSheet extends ConsumerWidget {
  const _CartSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(dataProvider.select((d) => d.cart));
    final delivery = ref.watch(dataProvider.select((d) => d.delivery));
    final subtotal = cartSubtotal(cart);
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 8, 6),
          child: Row(children: [
            const Icon(LucideIcons.shoppingBag, size: 18, color: AppColors.maroon),
            const SizedBox(width: 8),
            Expanded(child: Text('আপনার শপিং কার্ট', style: ts(15, weight: bold, color: AppColors.maroon))),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x, size: 20)),
          ]),
        ),
        const Divider(),
        Flexible(
          child: cart.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(40),
                  child: Text('কার্ট খালি রয়েছে।', style: ts(13, color: AppColors.grey500)),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final item = cart[i];
                    return Row(children: [
                      NetImage(item.product.image, width: 54, height: 54, radius: 10),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(item.product.name, style: ts(13, weight: bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                          if (item.product.packName.isNotEmpty)
                            Text(item.product.packName,
                                style: ts(10.5, color: AppColors.grey500), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('${taka(item.product.price)} × ${toBnDigits(item.quantity)}', style: ts(11.5, weight: semi)),
                        ]),
                      ),
                      QtyStepper(
                        small: true,
                        qty: item.quantity,
                        onMinus: () => ref.changeCartQty(item.product.id, -1),
                        onPlus: () => ref.changeCartQty(item.product.id, 1),
                      ),
                    ]);
                  },
                ),
        ),
        if (cart.isNotEmpty)
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: AppColors.cream, border: Border(top: BorderSide(color: AppColors.sand))),
              child: Column(children: [
                Row(children: [
                  Expanded(child: Text('সাবটোটাল:', style: ts(12))),
                  Text(taka(subtotal), style: ts(13, weight: bold)),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(LucideIcons.truck, size: 14, color: AppColors.grey500),
                  const SizedBox(width: 4),
                  Expanded(child: Text('ডেলিভারি চার্জ:', style: ts(12))),
                  Text('ঢাকায় ${taka(delivery.inside)} · বাইরে ${taka(delivery.outside)}', style: ts(11.5, color: AppColors.grey600)),
                ]),
                const SizedBox(height: 12),
                BusyButton(
                  label: 'চেকআউট করুন',
                  onPressed: () async {
                    Navigator.pop(context);
                    await showCheckoutSheet(context);
                  },
                ),
              ]),
            ),
          ),
      ]),
    );
  }
}

class PriceSummary extends StatelessWidget {
  const PriceSummary({super.key, required this.subtotal, required this.delivery, this.deliveryLabel = 'ডেলিভারি চার্জ:'});
  final double subtotal;
  final double delivery;
  final String deliveryLabel;

  @override
  Widget build(BuildContext context) {
    Widget row(String l, String v, {bool strong = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(children: [
            Expanded(child: Text(l, style: ts(strong ? 14 : 12, weight: strong ? bold : FontWeight.w400))),
            Text(v, style: ts(strong ? 15 : 12, weight: strong ? FontWeight.w800 : semi, color: strong ? AppColors.maroon : null)),
          ]),
        );
    return Column(children: [
      row('সাবটোটাল:', taka(subtotal)),
      row(deliveryLabel, delivery == 0 ? 'ফ্রি' : taka(delivery)),
      const Divider(height: 14),
      row('সর্বমোট:', taka(subtotal + delivery), strong: true),
    ]);
  }
}

/// Checkout (ShopTab.tsx "showCheckout") → `POST /orders`, placed on the store.
Future<void> showCheckoutSheet(BuildContext context) async {
  final order = await showAppSheet<Order>(context, title: 'চেকআউট', builder: (_) => const _Checkout());
  if (order != null && context.mounted) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(LucideIcons.circleCheck, size: 56, color: AppColors.green700),
          const SizedBox(height: 10),
          Text('অর্ডার গ্রহণ করা হয়েছে!', style: ts(17, weight: bold, color: AppColors.maroon)),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(style: ts(12.5), children: [
              const TextSpan(text: 'অর্ডার নম্বর: '),
              TextSpan(text: '#${order.displayNo}', style: ts(12.5, weight: bold)),
            ]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'কনফার্ম করতে আমরা ${order.phone != null ? toBnDigits(order.phone!) : 'আপনার'} নম্বরে ফোন করব। '
            'মোট ${taka(order.totalAmount)}, ক্যাশ অন ডেলিভারি।',
            textAlign: TextAlign.center,
            style: ts(12, color: AppColors.grey600, height: 1.5),
          ),
          if (order.pointsEarned > 0) ...[
            const SizedBox(height: 6),
            Text('আপনি +${toBnDigits(order.pointsEarned)} পয়েন্ট পেয়েছেন!',
                textAlign: TextAlign.center, style: ts(12, color: AppColors.olive, weight: semi)),
          ],
        ]),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('ঠিক আছে')),
          ),
        ],
      ),
    );
  }
}

final _bdMobile = RegExp(r'^01[3-9]\d{8}$');

/// "+880 1712-345678" / Bengali digits → "01712345678".
String _normalizeMobile(String raw) {
  var p = toAsciiDigits(raw).replaceAll(RegExp(r'[\s()-]'), '');
  if (p.startsWith('+880')) {
    p = p.substring(3);
  } else if (p.startsWith('880')) {
    p = p.substring(2);
  }
  return p;
}

class _Checkout extends ConsumerStatefulWidget {
  const _Checkout();

  @override
  ConsumerState<_Checkout> createState() => _CheckoutState();
}

class _CheckoutState extends ConsumerState<_Checkout> {
  late final _user = ref.read(dataProvider).user;
  late final _name = TextEditingController(text: _user.name);
  late final _phone = TextEditingController(
    text: _user.addresses.where((a) => a.phone.isNotEmpty).firstOrNull?.phone ?? '',
  );
  late final _address = TextEditingController(text: _user.defaultAddress?.details ?? '');
  final _notes = TextEditingController();
  String _area = 'inside';
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cart = ref.read(dataProvider).cart;
    final phone = _normalizeMobile(_phone.text);
    String? error;
    if (_name.text.trim().isEmpty) {
      error = 'আপনার নাম লিখুন।';
    } else if (!_bdMobile.hasMatch(phone)) {
      error = 'সঠিক ১১ ডিজিটের মোবাইল নম্বর দিন (যেমন: 01712345678)।';
    } else if (_address.text.trim().length < 5) {
      error = 'পূর্ণ ডেলিভারি ঠিকানা লিখুন।';
    }
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    if (cart.isEmpty) return;
    setState(() => _error = null);
    try {
      // The store prices the order; reward points are calculated by our server.
      final r = await ref.read(apiProvider).placeOrder(
            cart: cart,
            customerName: _name.text.trim(),
            phone: phone,
            area: _area,
            shippingAddress: _address.text.trim(),
            notes: _notes.text,
          );
      ref.read(appDataProvider.notifier).orderPlaced(r.order, r.rewardTx, r.products);
      if (mounted) Navigator.pop(context, r.order);
    } catch (e) {
      setState(() => _error = errorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(dataProvider.select((d) => d.cart));
    final delivery = ref.watch(dataProvider.select((d) => d.delivery));
    final addresses = ref.watch(dataProvider.select((d) => d.user.addresses));
    final subtotal = cartSubtotal(cart);
    final charge = delivery.forArea(_area);
    final points = cart.fold<int>(0, (s, i) => s + i.product.pointsFor(i.quantity));

    Widget areaBtn(String v) {
      final on = _area == v;
      return Expanded(
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor: on ? AppColors.maroon : Colors.white,
            foregroundColor: on ? Colors.white : AppColors.grey600,
            side: BorderSide(color: on ? AppColors.maroon : AppColors.sand),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          ),
          onPressed: () => setState(() => _area = v),
          child: Column(children: [
            Text(deliveryAreaLabels[v]!, style: ts(12, weight: bold, color: on ? Colors.white : AppColors.ink)),
            Text('ডেলিভারি ${taka(delivery.forArea(v))}', style: ts(10.5, color: on ? AppColors.sand : AppColors.grey500)),
          ]),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const FieldLabel('নাম'),
      TextField(controller: _name, maxLength: 120, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(counterText: '')),
      const SizedBox(height: 10),
      const FieldLabel('মোবাইল নম্বর'),
      TextField(
        controller: _phone,
        keyboardType: TextInputType.phone,
        maxLength: 20,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9০-৯+\s-]'))],
        decoration: const InputDecoration(hintText: '01XXXXXXXXX', counterText: '', prefixIcon: Icon(LucideIcons.phone, size: 16)),
      ),
      const SizedBox(height: 10),
      const FieldLabel('ডেলিভারি এলাকা'),
      Row(children: [areaBtn('inside'), const SizedBox(width: 8), areaBtn('outside')]),
      const SizedBox(height: 10),
      const FieldLabel('পূর্ণ ঠিকানা'),
      if (addresses.isNotEmpty) ...[
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final a in addresses)
            ActionChip(
              avatar: const Icon(LucideIcons.mapPin, size: 13),
              label: Text(a.title.isEmpty ? 'ঠিকানা' : a.title, style: ts(11)),
              onPressed: () {
                _address.text = a.details;
                if (a.phone.isNotEmpty) _phone.text = a.phone;
              },
            ),
        ]),
        const SizedBox(height: 8),
      ],
      TextField(
        controller: _address,
        minLines: 3,
        maxLines: 4,
        maxLength: 500,
        decoration: const InputDecoration(hintText: 'বাসা/রোড নম্বর, এলাকা, থানা, জেলা', counterText: ''),
      ),
      const SizedBox(height: 10),
      const FieldLabel('অর্ডার নোট (ঐচ্ছিক)'),
      TextField(
        controller: _notes,
        maxLength: 400,
        decoration: const InputDecoration(hintText: 'যেমন: বাসায় পৌঁছে ফোন করবেন', counterText: ''),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.sand)),
        child: Row(children: [
          const Icon(LucideIcons.banknote, size: 18, color: AppColors.olive),
          const SizedBox(width: 8),
          Expanded(
            child: Text('ক্যাশ অন ডেলিভারি — পণ্য হাতে পেয়ে টাকা দিন। কনফার্ম করতে আমরা আপনাকে ফোন করব।',
                style: ts(11.5, height: 1.45)),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          PriceSummary(subtotal: subtotal, delivery: charge, deliveryLabel: 'ডেলিভারি (${deliveryAreaLabels[_area]}):'),
          if (points > 0) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('এই অর্ডারে আপনি +${toBnDigits(points)} পয়েন্ট পাবেন।',
                  style: ts(11.5, weight: semi, color: AppColors.olive)),
            ),
          ],
        ]),
      ),
      if (_error != null) ...[const SizedBox(height: 10), ErrorBox(_error!)],
      const SizedBox(height: 14),
      BusyButton(
        label: 'অর্ডার কনফার্ম করুন · ${taka(subtotal + charge)}',
        busyLabel: 'অর্ডার হচ্ছে...',
        onPressed: cart.isEmpty ? null : _submit,
      ),
    ]);
  }
}
