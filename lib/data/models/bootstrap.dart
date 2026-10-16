import '../../core/utils/json.dart';
import 'commerce.dart';
import 'community.dart';
import 'contest.dart';
import 'medical.dart';
import 'notification_item.dart';
import 'recipe.dart';
import 'social.dart';
import 'user.dart';

/// Response of `GET /api/bootstrap` — same as `BootstrapData` in
/// frontend/src/services/babyCareService.ts.
class BootstrapData {
  const BootstrapData({
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
  });

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

  factory BootstrapData.fromJson(Json j) => BootstrapData(
        user: User.fromJson(jMap(j, 'user')),
        children: jList(j, 'children', Child.fromJson),
        posts: jList(j, 'posts', Post.fromJson),
        comments: jList(j, 'comments', Comment.fromJson),
        recipes: jList(j, 'recipes', Recipe.fromJson),
        products: jList(j, 'products', Product.fromJson),
        contests: jList(j, 'contests', Contest.fromJson),
        submissions: jList(j, 'submissions', ContestSubmission.fromJson),
        gifts: jList(j, 'gifts', GiftItem.fromJson),
        orders: jList(j, 'orders', Order.fromJson),
        rewardTx: jList(j, 'rewardTx', RewardTransaction.fromJson),
        giftRedemptions: jList(j, 'giftRedemptions', GiftRedemption.fromJson),
        notifications: jList(j, 'notifications', NotificationItem.fromJson),
        cart: jList(j, 'cart', CartItem.fromJson),
        friends: jList(j, 'friends', FriendUser.fromJson),
        conversations: jList(j, 'conversations', Conversation.fromJson),
        messages: jList(j, 'messages', Message.fromJson),
        doctors: jList(j, 'doctors', Doctor.fromJson),
        doctorQuestions: jList(j, 'doctorQuestions', DoctorQuestion.fromJson),
        leaderboard: jList(j, 'leaderboard', LeaderboardEntry.fromJson),
      );
}
