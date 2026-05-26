// lib/services/store_controller.dart
//
// Controlador Principal da Loja.
//
// Usa ChangeNotifier (padrão Provider) para notificar as telas
// sempre que o estado mudar. Integra com o DatabaseService para
// persistir pedidos, favoritos e cache de produtos.

import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/order.dart';
import '../models/product.dart';
import 'database_service.dart';

class StoreController extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  // ── Estado dos produtos ────────────────────────────────────────────────────
  List<Product> _allProducts = [];
  List<Product> get products => _filteredProducts;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String _selectedCategory = 'Todos';
  String get selectedCategory => _selectedCategory;

  String _sortBy = 'name'; // name | price_asc | price_desc | rating
  String get sortBy => _sortBy;

  bool loading = true;
  String? loadError;

  // ── Carrinho ───────────────────────────────────────────────────────────────
  final Map<String, int> _cart = {};
  Map<String, int> get cart => Map.unmodifiable(_cart);
  int get cartItemCount => _cart.values.fold(0, (t, q) => t + q);

  // ── Favoritos ──────────────────────────────────────────────────────────────
  Set<String> _favorites = {};
  bool isFavorite(String id) => _favorites.contains(id);

  // ── Pedidos ────────────────────────────────────────────────────────────────
  List<Order> _orders = [];
  List<Order> get orders => List.unmodifiable(_orders);
  String? confirmationNumber;

  // ── Inicialização ──────────────────────────────────────────────────────────

  Future<void> initialize() async {
    try {
      // 1. Carrega produtos do JSON (fonte primária)
      final String jsonText =
      await rootBundle.loadString('assets/products.json');
      final List<dynamic> decoded =
      json.decode(jsonText) as List<dynamic>;
      _allProducts = decoded
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList();

      // 2. Persiste/atualiza cache no SQLite
      await _db.upsertProducts(_allProducts);

      // 3. Carrega favoritos e pedidos do banco
      _favorites = await _db.getFavorites();
      _orders = await _db.getAllOrders();

      loading = false;
      notifyListeners();
    } catch (error) {
      // Se o JSON falhar, tenta usar o cache do banco
      try {
        _allProducts = await _db.getCachedProducts();
        _favorites = await _db.getFavorites();
        _orders = await _db.getAllOrders();
        loading = false;
        notifyListeners();
      } catch (_) {
        loading = false;
        loadError = 'Não foi possível carregar o inventário: $error';
        notifyListeners();
      }
    }
  }

  // ── Busca e Filtros ────────────────────────────────────────────────────────

  List<String> get categories {
    final cats = _allProducts.map((p) => p.category).toSet().toList()..sort();
    return ['Todos', ...cats];
  }

  List<Product> get _filteredProducts {
    List<Product> result = List.from(_allProducts);

    // Filtro por categoria
    if (_selectedCategory != 'Todos') {
      result = result.where((p) => p.category == _selectedCategory).toList();
    }

    // Filtro por busca
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where((p) =>
      p.name.toLowerCase().contains(q) ||
          p.shortDescription.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q))
          .toList();
    }

    // Ordenação
    switch (_sortBy) {
      case 'price_asc':
        result.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        result.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'rating':
        result.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      default:
        result.sort((a, b) => a.name.compareTo(b.name));
    }

    return result;
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSortBy(String sort) {
    _sortBy = sort;
    notifyListeners();
  }

  // ── Carrinho ───────────────────────────────────────────────────────────────

  Product productById(String id) =>
      _allProducts.firstWhere((p) => p.id == id);

  int quantityOf(String productId) => _cart[productId] ?? 0;

  List<Product> get cartProducts =>
      _cart.keys.map(productById).toList();

  bool addToCart(Product product) {
    final next = quantityOf(product.id) + 1;
    if (next > product.stock) return false;
    _cart[product.id] = next;
    confirmationNumber = null;
    notifyListeners();
    return true;
  }

  bool updateQuantity(Product product, int quantity) {
    if (quantity < 0) return true;
    if (quantity > product.stock) return false;
    if (quantity == 0) {
      _cart.remove(product.id);
    } else {
      _cart[product.id] = quantity;
    }
    confirmationNumber = null;
    notifyListeners();
    return true;
  }

  void removeFromCart(String productId) {
    _cart.remove(productId);
    notifyListeners();
  }

  void cancelOrder() {
    _cart.clear();
    confirmationNumber = null;
    notifyListeners();
  }

  // ── Cálculos financeiros ───────────────────────────────────────────────────

  double get subtotal {
    double total = 0;
    _cart.forEach((id, qty) {
      total += productById(id).price * qty;
    });
    return total;
  }

  /// Frete grátis acima de R$ 300,00; abaixo, R$ 29,90.
  double get shipping =>
      subtotal == 0 ? 0 : (subtotal >= 300 ? 0 : 29.90);

  /// Imposto simulado de 10% sobre o subtotal.
  double get taxes => subtotal * 0.10;

  double get total => subtotal + shipping + taxes;

  // ── Finalização do pedido ──────────────────────────────────────────────────

  Future<String> finishOrder({
    required String billingName,
    required String billingStreet,
    required String billingCity,
    required String billingState,
    required String billingZip,
    required String billingPhone,
    required String shippingName,
    required String shippingStreet,
    required String shippingCity,
    required String shippingState,
    required String shippingZip,
  }) async {
    final now = DateTime.now();
    final number =
        'PED-${now.year}-${100000 + Random().nextInt(900000)}';

    final items = cartProducts.map((p) {
      return OrderItem(
        productId: p.id,
        productName: p.name,
        price: p.price,
        quantity: quantityOf(p.id),
      );
    }).toList();

    final order = Order(
      id: number,
      createdAt: now,
      status: 'confirmed',
      subtotal: subtotal,
      shipping: shipping,
      taxes: taxes,
      total: total,
      billingName: billingName,
      billingStreet: billingStreet,
      billingCity: billingCity,
      billingState: billingState,
      billingZip: billingZip,
      billingPhone: billingPhone,
      shippingName: shippingName,
      shippingStreet: shippingStreet,
      shippingCity: shippingCity,
      shippingState: shippingState,
      shippingZip: shippingZip,
      items: items,
    );

    // Persiste no banco de dados SQLite
    await _db.saveOrder(order);

    // Atualiza a lista de pedidos em memória
    _orders = await _db.getAllOrders();

    confirmationNumber = number;
    _cart.clear();
    notifyListeners();
    return number;
  }

  // ── Favoritos ──────────────────────────────────────────────────────────────

  Future<void> toggleFavorite(String productId) async {
    await _db.toggleFavorite(productId);
    _favorites = await _db.getFavorites();
    notifyListeners();
  }

  List<Product> get favoriteProducts =>
      _allProducts.where((p) => _favorites.contains(p.id)).toList();

  // ── Estatísticas ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getStats() => _db.getStats();
}