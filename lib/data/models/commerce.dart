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
    this.packLabel = '',
    this.short = '',
    this.badge = '',
    this.age = '',
    this.howToUse = '',
    this.benefits = const [],
    this.includes = const [],
    this.storeUrl,
    this.packs = const [],
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

  // ---- Baby Masala store fields (backend/src/services/storeCatalog.js) ----
  /// Pack name shown to the customer, e.g. "৫টি জারের সম্পূর্ণ সেট". `weight` is the store's pack key.
  final String packLabel;
  final String short;
  final String badge;
  final String age;
  final String howToUse;
  final List<String> benefits;

  /// Combo contents.
  final List<String> includes;
  final String? storeUrl;

  /// Every pack size of a listing. Each pack is its own cart item.
  final List<Product> packs;

  /// Packs to choose from; a product without packs (older server) is its own only pack.
  List<Product> get allPacks => packs.isEmpty ? [this] : packs;
  double get minPrice => allPacks.map((p) => p.price).reduce((a, b) => a < b ? a : b);
  String get packName => packLabel.isNotEmpty ? packLabel : weight;

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
        packLabel: jStr(j, 'packLabel'),
        short: jStr(j, 'short'),
        badge: jStr(j, 'badge'),
        age: jStr(j, 'age'),
        howToUse: jStr(j, 'howToUse'),
        benefits: jStrList(j, 'benefits'),
        includes: jStrList(j, 'includes'),
        storeUrl: jStrN(j, 'storeUrl'),
        packs: jList(j, 'packs', Product.fromJson),
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

/// Store delivery charges by area (`shop.delivery` in bootstrap / GET /products).
class ShopDelivery {
  const ShopDelivery({this.inside = 70, this.outside = 110});
  final double inside;
  final double outside;

  double forArea(String area) => area == 'outside' ? outside : inside;

  factory ShopDelivery.fromJson(Json j) => ShopDelivery(inside: jDouble(j, 'inside', 70), outside: jDouble(j, 'outside', 110));
}

const deliveryAreaLabels = {'inside': 'ঢাকার ভিতরে', 'outside': 'ঢাকার বাইরে'};

const orderStatuses = ['pending', 'confirmed', 'shipped', 'delivered', 'cancelled'];
const orderStatusLabels = {
  'pending': 'কনফার্মের অপেক্ষায়',
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
    this.storeOrderNo,
    this.phone,
    this.area,
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

  /// Order number on the Baby Masala store, e.g. "BM10042".
  final String? storeOrderNo;
  final String? phone;
  final String? area;

  String get displayNo => storeOrderNo ?? id;

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
        storeOrderNo: jStrN(j, 'storeOrderNo'),
        phone: jStrN(j, 'phone'),
        area: jStrN(j, 'area'),
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
