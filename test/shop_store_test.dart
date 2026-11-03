import 'package:baby_care/data/models/bootstrap.dart';
import 'package:baby_care/features/shop/cart_sheet.dart';
import 'package:baby_care/features/shop/product_sheet.dart';
import 'package:baby_care/features/shop/shop_tab.dart';
import 'package:baby_care/state/app_data_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Store listings as GET /api/bootstrap returns them (backend/src/services/storeCatalog.js),
// with the longest real names and badges so layout overflows show up.
Map<String, dynamic> _pack(String id, String weight, String label, num price, num compareAt, {Map<String, dynamic> extra = const {}}) => {
      'id': id,
      'name': 'অর্গানিক বেবি নাট ও ড্রাই ফ্রুটস পাউডার',
      'category': 'বাদাম ও বীজ',
      'price': price,
      'originalPrice': compareAt,
      'image': '',
      'description': 'কাজু, কাঠবাদাম, পেস্তা ও খেজুরের গুঁড়ো — শিশুর খাবারে প্রাকৃতিক শক্তি ও পুষ্টি যোগ করে।',
      'weight': weight,
      'packLabel': label,
      'badge': 'হট ডিল · মেগা অফার',
      'age': '৮ মাস+ বয়সী শিশুদের জন্য',
      'rating': 4.9,
      'reviewsCount': 210,
      'stock': 99,
      'benefits': ['প্রাকৃতিক শক্তি ও প্রোটিন', 'চিনি ও প্রিজারভেটিভ মুক্ত'],
      'howToUse': 'দিনে ১ চা চামচ খিচুড়ি বা দুধে মিশিয়ে দিন।',
      'storeUrl': 'https://store.babymasalabd.com/product/baby-nut-fruit-powder',
      ...extra,
    };

final _nutPacks = [
  _pack('store_n_250', '250g Glass Jar', '২৫০ গ্রাম গ্লাস জার', 690, 850),
  _pack('store_n_500', '500g Jar', '৫০০ গ্রাম ফ্যামিলি জার (দীর্ঘ লেবেল পরীক্ষা)', 1290, 1600),
];
final _comboPacks = [
  _pack('store_c_set', '5x30g Combo Pack', '৫টি জারের সম্পূর্ণ সেট (৩০ গ্রাম × ৫)', 1150, 1650,
      extra: {'name': '৫ প্রিমিয়াম হার্বস কম্বো', 'category': 'কম্বো প্যাক', 'includes': ['ব্যাসিল', 'ওরিগানো', 'থাইম', 'রোজমেরি', 'সেইজ']}),
  _pack('store_c_family', '5x60g Family Pack', 'ফ্যামিলি প্যাক (৬০ গ্রাম × ৫)', 1950, 2800,
      extra: {'name': '৫ প্রিমিয়াম হার্বস কম্বো', 'category': 'কম্বো প্যাক'}),
];
final _oregano = _pack('store_o_35', '35g Glass Jar', '৩৫ গ্রাম গ্লাস জার', 270, 350,
    extra: {'name': 'অর্গানিক বেবি ওরিগানো ফ্লেক্স', 'category': 'হার্বস ও স্পাইস', 'badge': ''});

Map<String, dynamic> _bootstrap({List<Map<String, dynamic>> cart = const []}) => {
      'user': {
        'id': 'u1',
        'name': 'সাদিয়া রহমান',
        'contact': 'sadia@example.com',
        'addresses': [
          {'id': 'a1', 'title': 'বাসা', 'details': 'বাড়ি ১২, রোড ৫, মিরপুর ১০, ঢাকা', 'phone': '', 'isDefault': true}
        ],
      },
      'products': [
        {..._comboPacks.first, 'packs': _comboPacks},
        {..._nutPacks.first, 'packs': _nutPacks},
        {..._oregano, 'packs': [_oregano]},
      ],
      'cart': cart,
      'shop': {
        'delivery': {'inside': 70, 'outside': 110}
      },
    };

Future<ProviderContainer> _pump(WidgetTester tester, Widget Function(BuildContext) home,
    {List<Map<String, dynamic>> cart = const []}) async {
  tester.view.physicalSize = const Size(360 * 3, 740 * 3); // small Android phone
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final container = ProviderContainer();
  addTearDown(container.dispose);
  container.read(appDataProvider.notifier).applyBootstrap(BootstrapData.fromJson(_bootstrap(cart: cart)));
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(home: Scaffold(body: Builder(builder: home))),
  ));
  await tester.pump();
  return container;
}

void main() {
  testWidgets('shop tab lists store products with categories and pack prices', (tester) async {
    await _pump(tester, (_) => const ShopTab());
    expect(find.text('Baby Masala অফিসিয়াল স্টোর'), findsOneWidget);
    expect(find.text('সব'), findsOneWidget);
    expect(find.text('কম্বো প্যাক'), findsWidgets); // chip (+ nothing else uses it as text)
    expect(find.text('থেকে'), findsNWidgets(2)); // the two multi-pack products
    expect(find.text('প্যাক বাছুন'), findsNWidgets(2));
    await tester.scrollUntilVisible(find.text('+ কার্ট'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('+ কার্ট'), findsOneWidget); // single-pack oregano
    await tester.scrollUntilVisible(find.text('সব'), -200, scrollable: find.byType(Scrollable).first);

    // Category chips scroll sideways and are built lazily.
    final chip = find.text('বাদাম ও বীজ');
    await tester.dragUntilVisible(chip, find.byType(ListView).first, const Offset(-80, 0));
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();
    await tester.pump();
    expect(find.text('অর্গানিক বেবি নাট ও ড্রাই ফ্রুটস পাউডার'), findsOneWidget);
    expect(find.text('অর্গানিক বেবি ওরিগানো ফ্লেক্স'), findsNothing);
  });

  testWidgets('product sheet switches packs and shows combo contents', (tester) async {
    final c = await _pump(tester, (ctx) => Center(
          child: ElevatedButton(
            onPressed: () => showProductSheet(ctx, ProviderScope.containerOf(ctx).read(dataProvider).products.first),
            child: const Text('open'),
          ),
        ));
    expect(c.read(dataProvider).products.first.allPacks, hasLength(2));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('৫টি জারের সম্পূর্ণ সেট (৩০ গ্রাম × ৫)'), findsOneWidget);
    expect(find.text('সেইজ'), findsOneWidget);
    expect(find.textContaining('৳১১৫০'), findsWidgets);

    await tester.tap(find.text('ফ্যামিলি প্যাক (৬০ গ্রাম × ৫)'));
    await tester.pump();
    expect(find.text('কার্টে যোগ করুন · ৳১৯৫০'), findsOneWidget);
  });

  testWidgets('checkout asks for phone and area, and prices delivery by area', (tester) async {
    await _pump(
      tester,
      (ctx) => Center(child: ElevatedButton(onPressed: () => showCheckoutSheet(ctx), child: const Text('checkout'))),
      cart: [
        {'product': _comboPacks.first, 'quantity': 1},
        {'product': _nutPacks.last, 'quantity': 2},
      ],
    );
    await tester.tap(find.text('checkout'));
    await tester.pumpAndSettle();

    expect(find.text('মোবাইল নম্বর'), findsOneWidget);
    expect(find.text('ঢাকার ভিতরে'), findsOneWidget);
    // 1150 + 2 × 1290 = 3730, inside Dhaka +70
    expect(find.text('অর্ডার কনফার্ম করুন · ৳৩৮০০'), findsOneWidget);
    await tester.tap(find.text('ঢাকার বাইরে'));
    await tester.pump();
    expect(find.text('অর্ডার কনফার্ম করুন · ৳৩৮৪০'), findsOneWidget);

    // No phone yet → validation message, nothing is sent.
    await tester.ensureVisible(find.text('অর্ডার কনফার্ম করুন · ৳৩৮৪০'));
    await tester.tap(find.text('অর্ডার কনফার্ম করুন · ৳৩৮৪০'));
    await tester.pump();
    expect(find.textContaining('সঠিক ১১ ডিজিটের মোবাইল নম্বর'), findsOneWidget);
  });
}
