import '../data/models/bootstrap.dart';
import '../data/models/commerce.dart';
import '../data/models/community.dart';
import '../data/models/contest.dart';
import '../data/models/medical.dart';
import '../data/models/notification_item.dart';
import '../data/models/recipe.dart';
import '../data/models/social.dart';
import '../data/models/user.dart';

/// Everything the signed-in user sees. Equivalent of the useState hooks at the
/// top of frontend/src/App.tsx.
class AppData {
  const AppData({
    required this.user,
    this.children = const [],
    this.posts = const [],
    this.comments = const [],
    this.recipes = const [],
    this.products = const [],
    this.contests = const [],
    this.submissions = const [],
    this.gifts = const [],
    this.orders = const [],
    this.rewardTx = const [],
    this.giftRedemptions = const [],
    this.notifications = const [],
    this.cart = const [],
    this.friends = const [],
    this.conversations = const [],
    this.messages = const [],
    this.doctors = const [],
    this.doctorQuestions = const [],
    this.leaderboard = const [],
    this.postsCursor,
  });

  factory AppData.fromBootstrap(BootstrapData b) => AppData(
        user: b.user,
        children: b.children,
        posts: b.posts,
        comments: b.comments,
        recipes: b.recipes,
        products: b.products,
        contests: b.contests,
        submissions: b.submissions,
        gifts: b.gifts,
        orders: b.orders,
        rewardTx: b.rewardTx,
        giftRedemptions: b.giftRedemptions,
        notifications: b.notifications,
        cart: b.cart,
        friends: b.friends,
        conversations: b.conversations,
        messages: b.messages,
        doctors: b.doctors,
        doctorQuestions: b.doctorQuestions,
        leaderboard: b.leaderboard,
      );

  final User user;
  final List<Child> children;
  final List<Post> posts;
  final List<Comment> comments;
  final List<Recipe> recipes;
  final List<Product> products;
  final List<Contest> contests;
  final List<ContestSubmission> submissions;
  final List<GiftItem> gifts;
  final List<Order> orders;
  final List<RewardTransaction> rewardTx;
  final List<GiftRedemption> giftRedemptions;
  final List<NotificationItem> notifications;
  final List<CartItem> cart;
  final List<FriendUser> friends;
  final List<Conversation> conversations;
  final List<Message> messages;
  final List<Doctor> doctors;
  final List<DoctorQuestion> doctorQuestions;
  final List<LeaderboardEntry> leaderboard;

  /// ISO cursor for `GET /posts?before=` (null = not fetched yet / no more).
  final String? postsCursor;

  // ---- Derived values used by several screens ----
  int get unreadNotifications => notifications.where((n) => !n.read).length;
  int get unreadMessages => conversations.fold(0, (a, c) => a + c.unreadCount);
  int get cartCount => cart.fold(0, (a, c) => a + c.quantity);

  /// Same formula as RewardsTab.tsx: earned = Σ 'earn' transactions,
  /// spent = Σ gift redemption costs.
  int get earnedPoints => rewardTx.where((t) => t.type == 'earn').fold(0, (a, t) => a + t.points);
  int get spentPoints => giftRedemptions.fold(0, (a, r) => a + r.pointsCost);
  int get availablePoints => earnedPoints - spentPoints;

  Product? productById(String id) => products.where((p) => p.id == id).firstOrNull;

  AppData copyWith({
    User? user,
    List<Child>? children,
    List<Post>? posts,
    List<Comment>? comments,
    List<Recipe>? recipes,
    List<Product>? products,
    List<Contest>? contests,
    List<ContestSubmission>? submissions,
    List<GiftItem>? gifts,
    List<Order>? orders,
    List<RewardTransaction>? rewardTx,
    List<GiftRedemption>? giftRedemptions,
    List<NotificationItem>? notifications,
    List<CartItem>? cart,
    List<FriendUser>? friends,
    List<Conversation>? conversations,
    List<Message>? messages,
    List<Doctor>? doctors,
    List<DoctorQuestion>? doctorQuestions,
    List<LeaderboardEntry>? leaderboard,
    String? postsCursor,
    bool clearCursor = false,
  }) =>
      AppData(
        user: user ?? this.user,
        children: children ?? this.children,
        posts: posts ?? this.posts,
        comments: comments ?? this.comments,
        recipes: recipes ?? this.recipes,
        products: products ?? this.products,
        contests: contests ?? this.contests,
        submissions: submissions ?? this.submissions,
        gifts: gifts ?? this.gifts,
        orders: orders ?? this.orders,
        rewardTx: rewardTx ?? this.rewardTx,
        giftRedemptions: giftRedemptions ?? this.giftRedemptions,
        notifications: notifications ?? this.notifications,
        cart: cart ?? this.cart,
        friends: friends ?? this.friends,
        conversations: conversations ?? this.conversations,
        messages: messages ?? this.messages,
        doctors: doctors ?? this.doctors,
        doctorQuestions: doctorQuestions ?? this.doctorQuestions,
        leaderboard: leaderboard ?? this.leaderboard,
        postsCursor: clearCursor ? null : (postsCursor ?? this.postsCursor),
      );
}
