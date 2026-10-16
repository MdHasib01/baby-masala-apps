import '../../core/api/api_client.dart';
import '../../core/utils/json.dart';
import '../models/bootstrap.dart';
import '../models/commerce.dart';
import '../models/community.dart';
import '../models/contest.dart';
import '../models/notification_item.dart';
import '../models/recipe.dart';
import '../models/user.dart';

/// Dart twin of `babyCareService` in frontend/src/services/babyCareService.ts.
///
/// KEEP 1:1 WITH THE WEB SERVICE. When an endpoint is added/changed on the
/// backend, update both files and the endpoint table in mobile/MOBILE_SYNC.md.
class BabyCareApi {
  BabyCareApi(this._c);

  final ApiClient _c;

  // ---------------------------------------------------------------- Auth --
  Future<void> requestOtp({required String contact, required String mode, String? name}) async {
    await _c.post('/auth/request-otp', compact({'contact': contact, 'mode': mode, 'name': name}));
  }

  /// Stores the token on success (same as the web).
  Future<({String token, User user, bool isNewUser})> verifyOtp(String contact, String code) async {
    final r = await _c.post('/auth/verify-otp', {'contact': contact, 'code': code});
    final token = jStr(r, 'token');
    await _c.tokens.set(token);
    return (token: token, user: User.fromJson(jMap(r, 'user')), isNewUser: jBool(r, 'isNewUser'));
  }

  Future<User> me() async => User.fromJson(jMap(await _c.get('/auth/me'), 'user'));

  Future<User> activateMembership(String couponCode) async =>
      User.fromJson(jMap(await _c.post('/auth/activate-membership', {'couponCode': couponCode}), 'user'));

  Future<User> demoPurchaseMembership() async => User.fromJson(jMap(await _c.post('/auth/demo-purchase'), 'user'));

  // ---------------------------------------------------------- Bootstrap --
  Future<BootstrapData> bootstrap() async => BootstrapData.fromJson(await _c.get('/bootstrap'));

  // ------------------------------------------ Profile, cart, notifications --
  Future<User> updateProfile(User user) async =>
      User.fromJson(jMap(await _c.patch('/me', user.toProfilePatch()), 'user'));

  Future<List<CartItem>> saveCart(List<CartItem> cart) async {
    final r = await _c.put('/me/cart', {'items': cart.map((i) => i.toApi()).toList()});
    return jList(r, 'cart', CartItem.fromJson);
  }

  Future<List<NotificationItem>> notifications() async =>
      jList(await _c.get('/notifications'), 'notifications', NotificationItem.fromJson);

  Future<void> markAllNotificationsRead() => _c.post('/notifications/read-all');

  // ---------------------------------------------------------- Community --
  Future<({List<Post> posts, String? nextCursor})> listPosts({int? limit, String? before, String? topic}) async {
    final r = await _c.get('/posts', query: {'limit': limit, 'before': before, 'topic': topic});
    return (posts: jList(r, 'posts', Post.fromJson), nextCursor: jStrN(r, 'nextCursor'));
  }

  Future<({Post post, RewardTransaction? rewardTx})> createPost({
    required String content,
    required String topic,
    String? mediaUrl,
    String? mediaType,
  }) async {
    final r = await _c.post(
        '/posts', compact({'content': content, 'topic': topic, 'mediaUrl': mediaUrl, 'mediaType': mediaType}));
    return (post: Post.fromJson(jMap(r, 'post')), rewardTx: _tx(r));
  }

  Future<Post> updatePost(String postId, {String? content, String? topic, String? mediaUrl, String? mediaType}) async {
    final r = await _c.patch('/posts/${seg(postId)}',
        compact({'content': content, 'topic': topic, 'mediaUrl': mediaUrl, 'mediaType': mediaType}));
    return Post.fromJson(jMap(r, 'post'));
  }

  Future<void> deletePost(String postId) => _c.delete('/posts/${seg(postId)}');

  Future<({Post post, RewardTransaction? rewardTx})> reactToPost(String postId) async {
    final r = await _c.post('/posts/${seg(postId)}/react');
    return (post: Post.fromJson(jMap(r, 'post')), rewardTx: _tx(r));
  }

  Future<Post> toggleSavePost(String postId) async =>
      Post.fromJson(jMap(await _c.post('/posts/${seg(postId)}/save'), 'post'));

  Future<void> hidePost(String postId) => _c.post('/posts/${seg(postId)}/hide');

  Future<void> reportPost(String postId, [String? reason]) =>
      _c.post('/posts/${seg(postId)}/report', compact({'reason': reason}));

  Future<List<Comment>> getComments(String postId) async =>
      jList(await _c.get('/posts/${seg(postId)}/comments'), 'comments', Comment.fromJson);

  Future<({Comment comment, Post post, RewardTransaction? rewardTx})> addComment(String postId, String content) async {
    final r = await _c.post('/posts/${seg(postId)}/comments', {'content': content});
    return (comment: Comment.fromJson(jMap(r, 'comment')), post: Post.fromJson(jMap(r, 'post')), rewardTx: _tx(r));
  }

  // ------------------------------------------------------------ Recipes --
  Future<Recipe> toggleSaveRecipe(String recipeId) async =>
      Recipe.fromJson(jMap(await _c.post('/recipes/${seg(recipeId)}/save'), 'recipe'));

  // --------------------------------------------------------------- Shop --
  Future<List<Product>> listProducts({String? category, String? q}) async =>
      jList(await _c.get('/products', query: {'category': category, 'q': q}), 'products', Product.fromJson);

  Future<List<Order>> listOrders() async => jList(await _c.get('/orders'), 'orders', Order.fromJson);

  Future<({Order order, RewardTransaction? rewardTx, List<Product> products})> placeOrder({
    required List<CartItem> cart,
    required String shippingAddress,
    String? notes,
    required String paymentMethod,
  }) async {
    final r = await _c.post(
        '/orders',
        compact({
          'items': cart.map((i) => i.toApi()).toList(),
          'shippingAddress': shippingAddress,
          'notes': (notes == null || notes.trim().isEmpty) ? null : notes,
          'paymentMethod': paymentMethod,
        }));
    return (
      order: Order.fromJson(jMap(r, 'order')),
      rewardTx: _tx(r),
      products: jList(r, 'products', Product.fromJson),
    );
  }

  // -------------------------------------------------- Rewards & contests --
  Future<List<LeaderboardEntry>> getLeaderboard({int? limit}) async =>
      jList(await _c.get('/rewards/leaderboard', query: {'limit': limit}), 'leaderboard', LeaderboardEntry.fromJson);

  Future<
      ({
        GiftRedemption redemption,
        RewardTransaction rewardTx,
        GiftItem gift,
        int earnedPoints,
        int spentPoints,
        int availablePoints
      })> redeemGift(String giftId, String deliveryAddress) async {
    final r = await _c.post('/rewards/redeem', {'giftId': giftId, 'deliveryAddress': deliveryAddress});
    return (
      redemption: GiftRedemption.fromJson(jMap(r, 'redemption')),
      rewardTx: RewardTransaction.fromJson(jMap(r, 'rewardTx')),
      gift: GiftItem.fromJson(jMap(r, 'gift')),
      earnedPoints: jInt(r, 'earnedPoints'),
      spentPoints: jInt(r, 'spentPoints'),
      availablePoints: jInt(r, 'availablePoints'),
    );
  }

  Future<({ContestSubmission submission, RewardTransaction? rewardTx})> submitContestEntry(
    String contestId, {
    required String description,
    String? mediaUrl,
    String? orderId,
  }) async {
    final r = await _c.post('/contests/${seg(contestId)}/submissions',
        compact({'description': description, 'mediaUrl': mediaUrl, 'orderId': orderId}));
    return (submission: ContestSubmission.fromJson(jMap(r, 'submission')), rewardTx: _tx(r));
  }

  // ---------------------------------------------- Synced per-user lists --
  /// collection ∈ children | friends | conversations | messages | doctorQuestions
  Future<void> syncCollection(String collection, List<Json> items) =>
      _c.put('/sync/$collection', {'items': items});

  // -------------------------------------------------------------- Admin --
  late final admin = _AdminApi(_c);

  RewardTransaction? _tx(Json r) {
    final t = r['rewardTx'];
    return t is Map ? RewardTransaction.fromJson(Map<String, dynamic>.from(t)) : null;
  }
}

class AdminOverview {
  const AdminOverview({required this.posts, required this.orders, required this.products, required this.submissions});

  final List<({Post post, int reportsCount})> posts;
  final List<Order> orders;
  final List<Product> products;
  final List<ContestSubmission> submissions;
}

class _AdminApi {
  _AdminApi(this._c);
  final ApiClient _c;

  Future<AdminOverview> overview() async {
    final r = await _c.get('/admin/overview');
    return AdminOverview(
      posts: jList(r, 'posts', (j) => (post: Post.fromJson(j), reportsCount: jInt(j, 'reportsCount'))),
      orders: jList(r, 'orders', Order.fromJson),
      products: jList(r, 'products', Product.fromJson),
      submissions: jList(r, 'submissions', ContestSubmission.fromJson),
    );
  }

  Future<Post> setPostStatus(String postId, String status) async =>
      Post.fromJson(jMap(await _c.patch('/admin/posts/${seg(postId)}', {'status': status}), 'post'));

  Future<void> deletePost(String postId) => _c.delete('/admin/posts/${seg(postId)}');

  Future<Order> updateOrderStatus(String orderId, String status) async =>
      Order.fromJson(jMap(await _c.patch('/admin/orders/${seg(orderId)}', {'status': status}), 'order'));

  Future<Product> updateProduct(String productId, {int? stock, num? price, int? pointsEarned}) async =>
      Product.fromJson(jMap(
          await _c.patch('/admin/products/${seg(productId)}',
              compact({'stock': stock, 'price': price, 'pointsEarned': pointsEarned})),
          'product'));

  Future<ContestSubmission> setSubmissionStatus(String id, String status) async => ContestSubmission.fromJson(
      jMap(await _c.patch('/admin/submissions/${seg(id)}', {'status': status}), 'submission'));
}
