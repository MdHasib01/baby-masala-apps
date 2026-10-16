import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/commerce.dart';
import '../../state/app_data_controller.dart';

/// Cart helpers — same as handleAddToCart / handleUpdateCartQty in ShopTab.tsx.
/// Every change goes through `setCart`, which PUTs `/me/cart` after 600 ms.
extension CartOps on WidgetRef {
  void addToCart(Product p, [int qty = 1]) {
    final cart = read(dataProvider).cart;
    final exists = cart.any((i) => i.product.id == p.id);
    read(appDataProvider.notifier).setCart(exists
        ? [for (final i in cart) i.product.id == p.id ? i.withQuantity((i.quantity + qty).clamp(1, 99)) : i]
        : [...cart, CartItem(product: p, quantity: qty.clamp(1, 99))]);
  }

  void changeCartQty(String productId, int delta) {
    final cart = read(dataProvider).cart;
    read(appDataProvider.notifier).setCart([
      for (final i in cart)
        if (i.product.id != productId)
          i
        else if (i.quantity + delta > 0)
          i.withQuantity((i.quantity + delta).clamp(1, 99)),
    ]);
  }
}

double cartSubtotal(List<CartItem> cart) => cart.fold(0, (s, i) => s + i.product.price * i.quantity);
