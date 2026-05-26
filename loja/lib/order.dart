// lib/models/order.dart
//
// Modelo de dados do Pedido.
// Representa uma compra finalizada salva no banco de dados.

class OrderItem {
  final String productId;
  final String productName;
  final double price;
  final int quantity;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
  });

  double get subtotal => price * quantity;

  Map<String, dynamic> toMap(String orderId) => {
    'orderId': orderId,
    'productId': productId,
    'productName': productName,
    'price': price,
    'quantity': quantity,
  };

  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
    productId: map['productId'] as String,
    productName: map['productName'] as String,
    price: (map['price'] as num).toDouble(),
    quantity: map['quantity'] as int,
  );
}

class Order {
  final String id;
  final DateTime createdAt;
  final String status;
  final double subtotal;
  final double shipping;
  final double taxes;
  final double total;
  final String billingName;
  final String billingStreet;
  final String billingCity;
  final String billingState;
  final String billingZip;
  final String billingPhone;
  final String shippingName;
  final String shippingStreet;
  final String shippingCity;
  final String shippingState;
  final String shippingZip;
  final List<OrderItem> items;

  const Order({
    required this.id,
    required this.createdAt,
    required this.status,
    required this.subtotal,
    required this.shipping,
    required this.taxes,
    required this.total,
    required this.billingName,
    required this.billingStreet,
    required this.billingCity,
    required this.billingState,
    required this.billingZip,
    required this.billingPhone,
    required this.shippingName,
    required this.shippingStreet,
    required this.shippingCity,
    required this.shippingState,
    required this.shippingZip,
    required this.items,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'status': status,
    'subtotal': subtotal,
    'shipping': shipping,
    'taxes': taxes,
    'total': total,
    'billingName': billingName,
    'billingStreet': billingStreet,
    'billingCity': billingCity,
    'billingState': billingState,
    'billingZip': billingZip,
    'billingPhone': billingPhone,
    'shippingName': shippingName,
    'shippingStreet': shippingStreet,
    'shippingCity': shippingCity,
    'shippingState': shippingState,
    'shippingZip': shippingZip,
  };

  factory Order.fromMap(Map<String, dynamic> map, List<OrderItem> items) => Order(
    id: map['id'] as String,
    createdAt: DateTime.parse(map['createdAt'] as String),
    status: map['status'] as String,
    subtotal: (map['subtotal'] as num).toDouble(),
    shipping: (map['shipping'] as num).toDouble(),
    taxes: (map['taxes'] as num).toDouble(),
    total: (map['total'] as num).toDouble(),
    billingName: map['billingName'] as String,
    billingStreet: map['billingStreet'] as String,
    billingCity: map['billingCity'] as String,
    billingState: map['billingState'] as String,
    billingZip: map['billingZip'] as String,
    billingPhone: map['billingPhone'] as String,
    shippingName: map['shippingName'] as String,
    shippingStreet: map['shippingStreet'] as String,
    shippingCity: map['shippingCity'] as String,
    shippingState: map['shippingState'] as String,
    shippingZip: map['shippingZip'] as String,
    items: items,
  );

  String get statusLabel {
    switch (status) {
      case 'confirmed':
        return 'Confirmado';
      case 'shipped':
        return 'Enviado';
      case 'delivered':
        return 'Entregue';
      default:
        return 'Processando';
    }
  }
}