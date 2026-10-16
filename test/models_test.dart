import 'package:baby_care/core/api/api_exception.dart';
import 'package:baby_care/data/models/bootstrap.dart';
import 'package:baby_care/data/models/commerce.dart';
import 'package:baby_care/data/models/medical.dart';
import 'package:baby_care/data/models/social.dart';
import 'package:baby_care/state/app_data.dart';
import 'package:flutter_test/flutter_test.dart';

/// Trimmed `GET /api/bootstrap` response in the exact shape the backend
/// serializers produce (backend/src/services/serializers.js).
final sampleBootstrap = <String, dynamic>{
  'user': {
    'id': 'user-abc',
    'name': 'রাবেয়া আক্তার',
    'contact': '01712345678',
    'contactMethod': 'whatsapp',
    'role': 'admin',
    'isAdmin': true,
    'isVerified': true,
    'isMember': true,
    'avatar': 'https://example.com/a.jpg',
    'addresses': [
      {'id': 'addr-1', 'title': 'বাসা', 'details': 'ধানমন্ডি, ঢাকা', 'phone': '01712345678', 'isDefault': true},
    ],
    'notificationPrefs': {'push': true, 'sms': false, 'email': false, 'communityAlerts': true},
    'privacySettings': {'shareProfile': true, 'showChildrenInfo': false},
    'earnedPoints': 120,
    'spentPoints': 20,
  },
  'children': [
    {'id': 'child-1', 'name': 'আয়ান', 'dob': '2025-11-02', 'allergies': 'কোনো এলার্জি নেই'},
  ],
  'posts': [
    {
      'id': 'post-1',
      'authorId': 'user-abc',
      'authorName': 'রাবেয়া আক্তার',
      'authorAvatar': '',
      'isVerifiedBuyer': true,
      'topic': 'খাবার',
      'content': 'হ্যালো',
      'mediaUrl': 'https://example.com/v.mp4',
      'createdAt': '২ ঘণ্টা আগে',
      'likes': 3,
      'likedByMe': true,
      'savedByMe': false,
      'commentsCount': 1,
      'status': 'approved',
    },
  ],
  'comments': [],
  'recipes': [],
  'products': [
    {'id': 'p1', 'name': 'বেবি মসলা', 'category': 'হার্বস ও স্পাইস', 'price': 350, 'image': '', 'description': '', 'weight': '100g', 'stock': 5, 'rating': 4.8, 'reviewsCount': 12},
  ],
  'contests': [],
  'submissions': [],
  'gifts': [],
  'orders': [
    {
      'id': 'ord-1',
      'items': [
        {
          'product': {'id': 'p1', 'name': 'বেবি মসলা', 'price': 350, 'stock': 5},
          'quantity': 2,
        }
      ],
      'subtotal': 700,
      'deliveryCharge': 60,
      'totalAmount': 760,
      'status': 'delivered',
      'shippingAddress': 'ঢাকা',
      'paymentMethod': 'cod',
      'createdAt': 'আজ',
      'pointsEarned': 70,
    }
  ],
  'rewardTx': [
    {'id': 'tx-1', 'date': 'আজ', 'description': 'পোস্ট', 'points': 5, 'type': 'earn'},
    {'id': 'tx-2', 'date': 'আজ', 'description': 'অর্ডার', 'points': 70, 'type': 'earn'},
    {'id': 'tx-3', 'date': 'আজ', 'description': 'গিফট', 'points': -20, 'type': 'redeem'},
  ],
  'giftRedemptions': [
    {'id': 'red-1', 'giftId': 'gift-1', 'giftName': 'গিফট', 'pointsCost': 20, 'status': 'pending', 'createdAt': 'আজ'},
  ],
  'notifications': [
    {'id': 'n1', 'title': 'স্বাগতম', 'message': '...', 'time': 'এইমাত্র', 'read': false, 'type': 'tip'},
  ],
  'cart': [
    {
      'product': {'id': 'p1', 'name': 'বেবি মসলা', 'price': 350},
      'quantity': 3,
    }
  ],
  'friends': [
    {'id': 'f1', 'name': 'সুমাইয়া', 'friendshipStatus': 'friends', 'mutualFriendsCount': 4},
  ],
  'conversations': [
    {
      'id': 'c1',
      'participant': {'id': 'f1', 'name': 'সুমাইয়া', 'friendshipStatus': 'friends'},
      'lastMessage': 'হাই',
      'lastTimestamp': '১০:০০',
      'unreadCount': 2,
    }
  ],
  'messages': [],
  'doctors': [],
  'doctorQuestions': [
    {
      'id': 'q1',
      'childNameOrGeneral': 'সাধারণ প্রশ্ন',
      'category': 'খাবার ও পুষ্টি',
      'title': 'প্রশ্ন',
      'detailedQuestion': '...',
      'status': 'উত্তর অপেক্ষায়',
      'submissionDate': 'আজ',
      'followUpQuestions': [
        {'sender': 'user', 'text': 'আরেকটি প্রশ্ন', 'time': 'এইমাত্র'},
      ],
      'isPrivate': true,
    }
  ],
  'leaderboard': [
    {'rank': 1, 'userId': 'user-abc', 'name': 'রাবেয়া', 'avatar': '', 'earned': 75, 'isMe': true},
  ],
};

void main() {
  group('BootstrapData.fromJson', () {
    final b = BootstrapData.fromJson(sampleBootstrap);

    test('parses the user, including admin flag and nested settings', () {
      expect(b.user.id, 'user-abc');
      expect(b.user.isAdmin, isTrue);
      expect(b.user.defaultAddress?.title, 'বাসা');
      expect(b.user.notificationPrefs.sms, isFalse);
      expect(b.user.privacySettings.showChildrenInfo, isFalse);
    });

    test('parses posts and infers video from the URL like the backend', () {
      expect(b.posts.single.likedByMe, isTrue);
      expect(b.posts.single.isVideo, isTrue);
    });

    test('parses orders with the fields types.ts omits', () {
      final o = b.orders.single;
      expect(o.subtotal, 700);
      expect(o.deliveryCharge, 60);
      expect(o.paymentMethod, 'cod');
      expect(o.items.single.quantity, 2);
    });

    test('tolerates partial product objects inside the cart', () {
      expect(b.cart.single.product.price, 350);
      expect(b.cart.single.product.stock, 0);
    });

    test('points match the web formula (earn tx − redemptions)', () {
      final d = AppData.fromBootstrap(b);
      expect(d.earnedPoints, 75);
      expect(d.spentPoints, 20);
      expect(d.availablePoints, 55);
      expect(d.unreadNotifications, 1);
      expect(d.unreadMessages, 2);
      expect(d.cartCount, 3);
    });
  });

  group('sync payloads (PUT /sync/:collection)', () {
    test('child round-trips and drops nulls', () {
      const c = Child(id: 'child-1', name: 'আয়ান', dob: '2025-11-02');
      expect(c.toJson(), {'id': 'child-1', 'name': 'আয়ান', 'dob': '2025-11-02'});
      expect(Child.fromJson(c.toJson()).dob, '2025-11-02');
    });

    test('conversation embeds the full participant', () {
      final conv = BootstrapData.fromJson(sampleBootstrap).conversations.single;
      final json = conv.toJson();
      expect((json['participant'] as Map)['name'], 'সুমাইয়া');
      expect(Conversation.fromJson(json).unreadCount, 2);
    });

    test('doctor question keeps follow-ups', () {
      final q = BootstrapData.fromJson(sampleBootstrap).doctorQuestions.single;
      final json = q.toJson();
      expect((json['followUpQuestions'] as List).single, {'sender': 'user', 'text': 'আরেকটি প্রশ্ন', 'time': 'এইমাত্র'});
    });

    test('cart item maps to {productId, quantity}', () {
      final item = BootstrapData.fromJson(sampleBootstrap).cart.single;
      expect(item.toApi(), {'productId': 'p1', 'quantity': 3});
    });
  });

  group('shop rules', () {
    test('delivery is free strictly over ৳1000', () {
      expect(deliveryFor(1000), 60);
      expect(deliveryFor(1001), 0);
    });

    test('points per product fall back to 1 per ৳10', () {
      const p = Product(id: 'x', name: '', category: '', price: 355, image: '', description: '', weight: '');
      expect(p.pointsFor(2), 71);
      const q = Product(id: 'y', name: '', category: '', price: 355, image: '', description: '', weight: '', pointsEarned: 20);
      expect(q.pointsFor(2), 40);
    });
  });

  group('ApiException', () {
    test('uses the server message and code', () {
      final e = ApiException.fromResponse(409, {'message': 'স্টক শেষ', 'code': 'OUT_OF_STOCK'});
      expect(e.status, 409);
      expect(e.message, 'স্টক শেষ');
      expect(e.code, 'OUT_OF_STOCK');
    });

    test('falls back to the generic Bengali message', () {
      final e = ApiException.fromResponse(500, null);
      expect(e.message, ApiException.genericMessage);
      expect(errorMessage(StateError('x')), ApiException.genericMessage);
    });
  });

  test('FriendUser.withStatus keeps other fields', () {
    const f = FriendUser(id: 'f1', name: 'A', location: 'ঢাকা', mutualFriendsCount: 3);
    final g = f.withStatus('request_sent');
    expect(g.friendshipStatus, 'request_sent');
    expect(g.location, 'ঢাকা');
  });
}
