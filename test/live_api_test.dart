// Live contract test against a running backend. Skipped unless LIVE_API is set:
//
//   flutter test test/live_api_test.dart --dart-define=LIVE_API=http://localhost:5000/api
//
// Logs in as LIVE_CONTACT (signing it up on an unseeded DB), bootstraps, and PUTs every client-owned list
// back UNCHANGED — proving the mobile payloads pass the server's validators
// (same contract the web uses). It does not modify data.
import 'package:baby_care/core/api/api_client.dart';
import 'package:baby_care/core/api/api_exception.dart';
import 'package:baby_care/core/api/token_store.dart';
import 'package:baby_care/data/services/baby_care_api.dart';
import 'package:flutter_test/flutter_test.dart';

const liveApi = String.fromEnvironment('LIVE_API');
const liveContact = String.fromEnvironment('LIVE_CONTACT', defaultValue: 'mobile.contract.test@babycare.demo');

void main() {
  // No TestWidgetsFlutterBinding here: it would stub all HTTP with 400s.
  // TokenStore swallows the missing secure-storage plugin and keeps the
  // token in memory.
  final skip = liveApi.isEmpty ? 'set --dart-define=LIVE_API=http://localhost:5000/api' : null;

  late BabyCareApi api;

  setUpAll(() async {
    if (skip != null) return;
    api = BabyCareApi(ApiClient(tokens: TokenStore(), baseUrl: liveApi));
    try {
      await api.requestOtp(contact: liveContact, mode: 'login');
    } on ApiException catch (e) {
      if (e.status == 404) {
        // Unseeded database: create the dedicated test account once.
        await api.requestOtp(contact: liveContact, mode: 'signup', name: 'Mobile Contract Test');
      } else if (e.code != 'RATE_LIMITED') {
        rethrow; // RATE_LIMITED: a code from <30 s ago is still valid
      }
    }
    await api.verifyOtp(liveContact, '123456'); // DEMO_OTP: run the local backend with DEMO_MODE=true
  });

  test('bootstrap parses and synced lists round-trip', () async {
    final b = await api.bootstrap();
    expect(b.user.id, isNotNull);

    await api.syncCollection('children', b.children.map((e) => e.toJson()).toList());
    await api.syncCollection('friends', b.friends.map((e) => e.toJson()).toList());
    await api.syncCollection('conversations', b.conversations.map((e) => e.toJson()).toList());
    await api.syncCollection('messages', b.messages.map((e) => e.toJson()).toList());
    await api.syncCollection('doctorQuestions', b.doctorQuestions.map((e) => e.toJson()).toList());
    await api.saveCart(b.cart);
    final u = await api.updateProfile(b.user);
    expect(u.id, b.user.id);

    final again = await api.bootstrap();
    expect(again.children.map((c) => c.toJson()).toList(), b.children.map((c) => c.toJson()).toList());
    expect(again.doctorQuestions.length, b.doctorQuestions.length);
    expect(again.cart.length, b.cart.length);
  }, skip: skip);

  test('paged posts + leaderboard + errors', () async {
    final page = await api.listPosts(limit: 2);
    expect(page.posts.length, lessThanOrEqualTo(2));
    expect(await api.getLeaderboard(), isNotEmpty);
    await expectLater(
      api.redeemGift('gift-does-not-exist', 'x'),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', anyOf(400, 404, 409))),
    );
  }, skip: skip);
}
