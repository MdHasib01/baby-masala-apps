import '../../core/utils/json.dart';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.originalPrice,
    required this.image,
    required this.description,
    required this.weight,
    this.stock = 0,
    this.rating = 0,
    this.reviewsCount = 0,
    this.pointsEarned,
  });

  final String id;
  final String name;
  final String category;
  final double price;
  final double? originalPrice;
  final String image;
  final String description;
  final String weight;
  final int stock;
  final double rating;
  final int reviewsCount;
  final int? pointsEarned;

  /// Same rule as the backend: `pointsEarned × qty`, or 1 point per ৳10.
  int pointsFor(int qty) => pointsEarned != null ? pointsEarned! * qty : (price * qty / 10).floor();

  factory Product.fromJson(Json j) => Product(
        id: jStr(j, 'id'),
        name: jStr(j, 'name'),
        category: jStr(j, 'category'),
        price: jDouble(j, 'price'),
        originalPrice: jDoubleN(j, 'originalPrice'),
        image: jStr(j, 'image'),
        description: jStr(j, 'description'),
        weight: jStr(j, 'weight'),
        stock: jInt(j, 'stock'),
        rating: jDouble(j, 'rating'),
        reviewsCount: jInt(j, 'reviewsCount'),
        pointsEarned: jIntN(j, 'pointsEarned'),
      );
}

class CartItem {
  const CartItem({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  factory CartItem.fromJson(Json j) => CartItem(product: Product.fromJson(jMap(j, 'product')), quantity: jInt(j, 'quantity', 1));

  /// Shape for `PUT /me/cart` and `POST /orders`.
  Json toApi() => {'productId': product.id, 'quantity': quantity};

  CartItem withQuantity(int q) => CartItem(product: product, quantity: q);
}

/// Delivery rule shared with the backend (routes/shop.js): free over ৳1000.
const freeDeliveryThreshold = 1000;
const deliveryCharge = 60;
double deliveryFor(double subtotal) => subtotal > freeDeliveryThreshold ? 0 : deliveryCharge.toDouble();

const orderStatuses = ['pending', 'confirmed', 'shipped', 'delivered', 'cancelled'];
const orderStatusLabels = {
  'pending': 'অপেক্ষমাণ',
  'confirmed': 'নিশ্চিত',
  'shipped': 'পাঠানো হয়েছে',
  'delivered': 'ডেলিভারি সম্পন্ন',
  'cancelled': 'বাতিল',
};

class Order {
  const Order({
    required this.id,
    required this.items,
    this.subtotal,
    this.deliveryCharge,
    required this.totalAmount,
    required this.status,
    required this.shippingAddress,
    this.notes,
    this.paymentMethod,
    required this.createdAt,
    this.pointsEarned = 0,
    this.userId,
  });

  final String id;
  final List<CartItem> items;
  final double? subtotal;
  final double? deliveryCharge;
  final double totalAmount;
  final String status;
  final String shippingAddress;
  final String? notes;
  final String? paymentMethod; // 'cod' | 'online'
  final String createdAt; // day label
  final int pointsEarned;
  final String? userId; // admin overview only

  factory Order.fromJson(Json j) => Order(
        id: jStr(j, 'id'),
        items: jList(j, 'items', CartItem.fromJson),
        subtotal: jDoubleN(j, 'subtotal'),
        deliveryCharge: jDoubleN(j, 'deliveryCharge'),
        totalAmount: jDouble(j, 'totalAmount'),
        status: jStr(j, 'status', 'pending'),
        shippingAddress: jStr(j, 'shippingAddress'),
        notes: jStrN(j, 'notes'),
        paymentMethod: jStrN(j, 'paymentMethod'),
        createdAt: jStr(j, 'createdAt'),
        pointsEarned: jInt(j, 'pointsEarned'),
        userId: jStrN(j, 'userId'),
      );
}

class GiftItem {
  const GiftItem({
    required this.id,
    required this.name,
    required this.pointsCost,
    required this.image,
    this.stock = 0,
    this.description = '',
  });

  final String id;
  final String name;
  final int pointsCost;
  final String image;
  final int stock;
  final String description;

  factory GiftItem.fromJson(Json j) => GiftItem(
        id: jStr(j, 'id'),
        name: jStr(j, 'name'),
        pointsCost: jInt(j, 'pointsCost'),
        image: jStr(j, 'image'),
        stock: jInt(j, 'stock'),
        description: jStr(j, 'description'),
      );
}

class GiftRedemption {
  const GiftRedemption({
    required this.id,
    required this.giftId,
    required this.giftName,
    required this.pointsCost,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String giftId;
  final String giftName;
  final int pointsCost;
  final String status; // pending | processing | shipped | delivered
  final String createdAt;

  factory GiftRedemption.fromJson(Json j) => GiftRedemption(
        id: jStr(j, 'id'),
        giftId: jStr(j, 'giftId'),
        giftName: jStr(j, 'giftName'),
        pointsCost: jInt(j, 'pointsCost'),
        status: jStr(j, 'status', 'pending'),
        createdAt: jStr(j, 'createdAt'),
      );
}

class RewardTransaction {
  const RewardTransaction({
    required this.id,
    required this.date,
    required this.description,
    required this.points,
    required this.type,
  });

  final String id;
  final String date;
  final String description;
  final int points; // can be negative (reversal / redeem)
  final String type; // 'earn' | 'redeem'

  factory RewardTransaction.fromJson(Json j) => RewardTransaction(
        id: jStr(j, 'id'),
        date: jStr(j, 'date'),
        description: jStr(j, 'description'),
        points: jInt(j, 'points'),
        type: jStr(j, 'type', 'earn'),
      );
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.name,
    required this.avatar,
    required this.earned,
    required this.isMe,
  });

  final int rank;
  final String userId;
  final String name;
  final String avatar;
  final int earned;
  final bool isMe;

  factory LeaderboardEntry.fromJson(Json j) => LeaderboardEntry(
        rank: jInt(j, 'rank'),
        userId: jStr(j, 'userId'),
        name: jStr(j, 'name'),
        avatar: jStr(j, 'avatar'),
        earned: jInt(j, 'earned'),
        isMe: jBool(j, 'isMe'),
      );
}
