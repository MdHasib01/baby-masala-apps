import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/bootstrap.dart';
import '../data/models/commerce.dart';
import '../data/models/community.dart';
import '../data/models/contest.dart';
import '../data/models/medical.dart';
import '../data/models/recipe.dart';
import '../data/models/social.dart';
import '../data/models/user.dart';
import '../data/services/baby_care_api.dart';
import 'app_data.dart';
import 'providers.dart';

/// Keys of the debounced saves — identical to the `useServerSync` calls in
/// frontend/src/App.tsx.
enum SyncKey { user, cart, children, friends, conversations, messages, doctorQuestions }

/// Holds [AppData] and saves client-owned lists the same way the web does:
/// 600 ms after the last change, the whole list is PUT to the server.
class AppDataController extends Notifier<AppData?> {
  static const debounce = Duration(milliseconds: 600);

  final Map<SyncKey, Timer> _timers = {};

  BabyCareApi get _api => ref.read(apiProvider);

  @override
  AppData? build() {
    ref.onDispose(() {
      for (final t in _timers.values) {
        t.cancel();
      }
    });
    return null;
  }

  AppData get data => state!;

  // ------------------------------------------------------------ loading --

  void applyBootstrap(BootstrapData b) {
    _cancelAll();
    state = AppData.fromBootstrap(b);
  }

  void clear() {
    _cancelAll();
    state = null;
  }

  /// Re-fetch everything without touching unsaved local edits: pending saves
  /// are flushed first so the server copy includes them.
  Future<void> refresh() async {
    if (state == null) return;
    await flush();
    final b = await _api.bootstrap();
    if (state == null) return; // logged out meanwhile
    state = AppData.fromBootstrap(b);
  }

  /// Used before opening an editor for a synced list (children, addresses,
  /// doctor questions…) so we edit the latest server copy. Never throws.
  Future<void> refreshQuietly() async {
    try {
      await refresh().timeout(const Duration(seconds: 6));
    } catch (e) {
      debugPrint('[refresh] $e');
    }
  }

  Future<void> refreshLeaderboard() async {
    try {
      final lb = await _api.getLeaderboard();
      if (state != null) state = data.copyWith(leaderboard: lb);
    } catch (e) {
      debugPrint('[leaderboard] $e');
    }
  }

  // ------------------------------------------------ synced (debounced) --

  void setUser(User user) => _set(data.copyWith(user: user), SyncKey.user);
  void setCart(List<CartItem> cart) => _set(data.copyWith(cart: cart), SyncKey.cart);
  void setChildren(List<Child> v) => _set(data.copyWith(children: v), SyncKey.children);
  void setFriends(List<FriendUser> v) => _set(data.copyWith(friends: v), SyncKey.friends);
  void setConversations(List<Conversation> v) => _set(data.copyWith(conversations: v), SyncKey.conversations);
  void setMessages(List<Message> v) => _set(data.copyWith(messages: v), SyncKey.messages);
  void setDoctorQuestions(List<DoctorQuestion> v) =>
      _set(data.copyWith(doctorQuestions: v), SyncKey.doctorQuestions);

  void _set(AppData next, SyncKey key) {
    state = next;
    _timers[key]?.cancel();
    _timers[key] = Timer(debounce, () => _save(key));
  }

  /// Sends all pending saves now (used before refresh and when the app is
  /// backgrounded so nothing is lost).
  Future<void> flush() async {
    final keys = _timers.keys.toList();
    _cancelAll();
    await Future.wait(keys.map(_save));
  }

  void _cancelAll() {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
  }

  Future<void> _save(SyncKey key) async {
    _timers.remove(key);
    final d = state;
    if (d == null) return;
    try {
      switch (key) {
        case SyncKey.user:
          await _api.updateProfile(d.user);
        case SyncKey.cart:
          await _api.saveCart(d.cart);
        case SyncKey.children:
          await _api.syncCollection('children', d.children.map((c) => c.toJson()).toList());
        case SyncKey.friends:
          await _api.syncCollection('friends', d.friends.map((c) => c.toJson()).toList());
        case SyncKey.conversations:
          await _api.syncCollection('conversations', d.conversations.map((c) => c.toJson()).toList());
        case SyncKey.messages:
          await _api.syncCollection('messages', d.messages.map((c) => c.toJson()).toList());
        case SyncKey.doctorQuestions:
          await _api.syncCollection('doctorQuestions', d.doctorQuestions.map((c) => c.toJson()).toList());
      }
    } catch (e) {
      debugPrint('[sync ${key.name}] $e');
    }
  }

  // --------------------------------- server-confirmed local updates only --
  // These mirror state the server already changed (no sync needed).

  void setUserFromServer(User user) => state = data.copyWith(user: user);

  void addRewardTx(RewardTransaction? tx) {
    if (tx != null) state = data.copyWith(rewardTx: [tx, ...data.rewardTx]);
  }

  void upsertPost(Post p, {bool prepend = false}) {
    final exists = data.posts.any((x) => x.id == p.id);
    state = data.copyWith(
      posts: exists ? [for (final x in data.posts) x.id == p.id ? p : x] : (prepend ? [p, ...data.posts] : [...data.posts, p]),
    );
  }

  void removePostsBy(String authorId) => state = data.copyWith(
        posts: data.posts.where((p) => p.authorId != authorId).toList(),
      );

  void removePost(String id) => state = data.copyWith(
        posts: data.posts.where((p) => p.id != id).toList(),
        comments: data.comments.where((c) => c.postId != id).toList(),
      );

  void appendPosts(List<Post> more, String? cursor) {
    final ids = data.posts.map((p) => p.id).toSet();
    state = data.copyWith(
      posts: [...data.posts, ...more.where((p) => !ids.contains(p.id))],
      postsCursor: cursor,
      clearCursor: cursor == null,
    );
  }

  void addComment(Comment c) => state = data.copyWith(comments: [...data.comments, c]);

  void setCommentsFor(String postId, List<Comment> list) => state = data.copyWith(
        comments: [...data.comments.where((c) => c.postId != postId), ...list],
      );

  void replaceRecipe(Recipe r) => state = data.copyWith(recipes: [for (final x in data.recipes) x.id == r.id ? r : x]);

  void replaceProducts(List<Product> updated) {
    final byId = {for (final p in updated) p.id: p};
    state = data.copyWith(products: [for (final p in data.products) byId[p.id] ?? p]);
  }

  /// After `POST /orders`: server already cleared the cart.
  void orderPlaced(Order order, RewardTransaction? tx, List<Product> products) {
    _timers.remove(SyncKey.cart)?.cancel();
    replaceProducts(products);
    state = data.copyWith(orders: [order, ...data.orders], cart: const []);
    addRewardTx(tx);
  }

  void giftRedeemed(GiftRedemption r, RewardTransaction tx, GiftItem gift) {
    state = data.copyWith(
      giftRedemptions: [r, ...data.giftRedemptions],
      gifts: [for (final g in data.gifts) g.id == gift.id ? gift : g],
    );
    addRewardTx(tx);
  }

  void addSubmission(ContestSubmission s, RewardTransaction? tx) {
    state = data.copyWith(submissions: [s, ...data.submissions]);
    addRewardTx(tx);
  }

  void markAllNotificationsRead() =>
      state = data.copyWith(notifications: data.notifications.map((n) => n.markRead()).toList());
}

final appDataProvider = NotifierProvider<AppDataController, AppData?>(AppDataController.new);

/// Convenience: non-null data for screens that are only reachable when signed
/// in. Falls back to an empty store during the logout transition.
final dataProvider = Provider<AppData>((ref) => ref.watch(appDataProvider) ?? const AppData(user: User.empty));
