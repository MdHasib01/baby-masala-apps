import 'package:baby_care/data/static/legal_texts.dart';
import 'package:baby_care/features/auth/signup_screen.dart';
import 'package:baby_care/features/legal/about_screen.dart';
import 'package:baby_care/features/legal/delete_account_screen.dart';
import 'package:baby_care/features/legal/legal_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

Widget _app(Widget child) => ProviderScope(child: MaterialApp(home: child));

void main() {
  testWidgets('privacy policy and terms render every section', (tester) async {
    for (final doc in [privacyPolicy, termsOfUse]) {
      await tester.pumpWidget(_app(LegalScreen(key: ValueKey(doc.title), doc: doc)));
      expect(find.text(doc.title), findsOneWidget);
      expect(find.text(doc.sections.first.title), findsOneWidget);
      await tester.scrollUntilVisible(find.text(doc.sections.last.title), 300);
      expect(find.text(doc.sections.last.title), findsOneWidget);
    }
  });

  testWidgets('about screen shows version, publisher and licenses entry', (tester) async {
    PackageInfo.setMockInitialValues(
      appName: 'Baby Care',
      packageName: 'com.nuktatechnology.baby_care',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    await tester.pumpWidget(_app(const AboutScreen()));
    await tester.pumpAndSettle();
    expect(find.text('সংস্করণ 1.0.0 (1)'), findsOneWidget);
    expect(find.textContaining('Nukta Technologies'), findsWidgets);
    await tester.scrollUntilVisible(find.text('ওপেন সোর্স লাইসেন্স'), 200);
    expect(find.text('ওপেন সোর্স লাইসেন্স'), findsOneWidget);
  });

  testWidgets('delete button stays disabled until the confirmation word is typed', (tester) async {
    await tester.pumpWidget(_app(const DeleteAccountScreen()));
    ElevatedButton button() => tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button().onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'মুছে ফেলুন');
    await tester.pump();
    expect(button().onPressed, isNotNull);
  });

  testWidgets('sign-up requires accepting the terms', (tester) async {
    await tester.pumpWidget(_app(const SignUpScreen()));
    await tester.enterText(find.byType(TextField).at(0), 'Test Mother');
    await tester.enterText(find.byType(TextField).at(1), 'mother@example.com');
    await tester.tap(find.text('যাচাইকরণ কোড পাঠান'));
    await tester.pump();
    expect(find.text('অ্যাকাউন্ট খুলতে শর্তাবলী ও গোপনীয়তা নীতিতে সম্মতি দিন।'), findsOneWidget);
    expect(find.byType(Checkbox), findsOneWidget);
  });
}
