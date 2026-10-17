import 'package:flutter/material.dart';
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
    final subtotal = cartSubtotal(cart);
    final delivery = deliveryFor(subtotal);
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
                          Text(item.product.name, style: ts(13, weight: bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                          Text('${taka(item.product.price)} x ${toBnDigits(item.quantity)}', style: ts(11, color: AppColors.grey500)),
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
                PriceSummary(subtotal: subtotal, delivery: delivery),
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
  const PriceSummary({super.key, required this.subtotal, required this.delivery});
  final double subtotal;
  final double delivery;

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
      row('ডেলিভারি চার্জ:', delivery == 0 ? 'ফ্রি' : taka(delivery)),
      const Divider(height: 14),
      row('সর্বমোট প্রদেয়:', taka(subtotal + delivery), strong: true),
    ]);
  }
}

/// Checkout (ShopTab.tsx "showCheckout") → `POST /orders`.
Future<void> showCheckoutSheet(BuildContext context) async {
  final order = await showAppSheet<Order>(context, title: 'ডেমো চেকআউট ও পেমেন্ট', builder: (_) => const _Checkout());
  if (order != null && context.mounted) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(LucideIcons.circleCheck, size: 56, color: AppColors.green700),
          const SizedBox(height: 10),
          Text('অর্ডার সফল হয়েছে!', style: ts(17, weight: bold, color: AppColors.maroon)),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(style: ts(12.5), children: [
              const TextSpan(text: 'আপনার অর্ডার আইডি: '),
              TextSpan(text: '#${order.id}', style: ts(12.5, weight: bold)),
            ]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text('অর্ডার ডেলিভারির পর আপনি +${toBnDigits(order.pointsEarned)} পয়েন্ট অর্জন করবেন!',
              textAlign: TextAlign.center, style: ts(12, color: AppColors.olive, weight: semi)),
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

class _Checkout extends ConsumerStatefulWidget {
  const _Checkout();

  @override
  ConsumerState<_Checkout> createState() => _CheckoutState();
}

class _CheckoutState extends ConsumerState<_Checkout> {
  late final _address = TextEditingController(
    text: ref.read(dataProvider).user.defaultAddress?.details ?? 'রোড ৭/এ, ধানমন্ডি, ঢাকা - ১২০৯',
  );
  final _notes = TextEditingController();
  String _payment = 'cod';
  String? _error;

  @override
  void dispose() {
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cart = ref.read(dataProvider).cart;
    if (_address.text.trim().isEmpty) {
      setState(() => _error = 'শিপিং ঠিকানা লিখুন।');
      return;
    }
    if (cart.isEmpty) return;
    setState(() => _error = null);
    try {
      // Prices, stock and reward points are checked and calculated by the server.
      final r = await ref.read(apiProvider).placeOrder(
            cart: cart,
            shippingAddress: _address.text.trim(),
            notes: _notes.text,
            paymentMethod: _payment,
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
    final subtotal = cartSubtotal(cart);
    final delivery = deliveryFor(subtotal);
    final addresses = ref.watch(dataProvider.select((d) => d.user.addresses));

    Widget payBtn(String v, IconData icon, String label) {
      final on = _payment == v;
      return Expanded(
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            backgroundColor: on ? AppColors.maroon : Colors.white,
            foregroundColor: on ? Colors.white : AppColors.grey600,
            side: BorderSide(color: on ? AppColors.maroon : AppColors.sand),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            textStyle: ts(11.5, weight: bold),
          ),
          onPressed: () => setState(() => _payment = v),
          icon: Icon(icon, size: 15),
          label: Text(label, textAlign: TextAlign.center),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const FieldLabel('শিপিং ঠিকানা'),
      if (addresses.isNotEmpty) ...[
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final a in addresses)
            ActionChip(
              avatar: const Icon(LucideIcons.mapPin, size: 13),
              label: Text(a.title, style: ts(11)),
              onPressed: () => _address.text = a.details,
            ),
        ]),
        const SizedBox(height: 8),
      ],
      TextField(controller: _address, minLines: 3, maxLines: 4, maxLength: 500, decoration: const InputDecoration(counterText: '')),
      const SizedBox(height: 10),
      const FieldLabel('অর্ডার নোট (ঐচ্ছিক)'),
      TextField(
        controller: _notes,
        maxLength: 1000,
        decoration: const InputDecoration(hintText: 'যেমন: বাসায় পৌঁছে ফোন করবেন', counterText: ''),
      ),
      const SizedBox(height: 10),
      const FieldLabel('পেমেন্ট পদ্ধতি'),
      Row(children: [
        payBtn('cod', LucideIcons.banknote, 'ক্যাশ অন ডেলিভারি'),
        const SizedBox(width: 8),
        payBtn('online', LucideIcons.creditCard, 'অনলাইন পেমেন্ট (ডেমো)'),
      ]),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(12)),
        child: PriceSummary(subtotal: subtotal, delivery: delivery),
      ),
      if (_error != null) ...[const SizedBox(height: 10), ErrorBox(_error!)],
      const SizedBox(height: 14),
      BusyButton(
        label: 'অর্ডার করুন (${taka(subtotal + delivery)})',
        busyLabel: 'অর্ডার হচ্ছে...',
        onPressed: cart.isEmpty ? null : _submit,
      ),
    ]);
  }
}
