// lib/services/database_service.dart
//
// Serviço de Banco de Dados - SQLite via sqflite.
//
// Responsabilidades:
//   - Criar e versionar o banco de dados local.
//   - CRUD de pedidos (orders) e itens de pedido (order_items).
//   - CRUD de produtos favoritos (favorites).
//   - CRUD de produtos em cache local (products).
//
// Conceito didático:
//   O SQLite é um banco de dados relacional embutido no dispositivo.
//   Diferente de um arquivo JSON, ele suporta consultas SQL, índices e
//   relacionamentos entre tabelas — características de bancos profissionais.

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/order.dart';
import '../models/product.dart';

class DatabaseService {
  // Padrão Singleton: garante que só existe uma instância do banco aberta.
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  // ─── Abertura e inicialização ──────────────────────────────────────────────

  Future<Database> get database async {
    _db ??= await _openDatabase();
    return _db!;
  }

  Future<Database> _openDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'loja_online_pro.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  /// Criação das tabelas ao instalar o app pela primeira vez.
  Future<void> _onCreate(Database db, int version) async {
    // Tabela de produtos (cache local do catálogo)
    await db.execute('''
      CREATE TABLE products (
        id          TEXT PRIMARY KEY,
        name        TEXT NOT NULL,
        price       REAL NOT NULL,
        stock       INTEGER NOT NULL,
        icon        TEXT NOT NULL,
        category    TEXT NOT NULL,
        rating      REAL DEFAULT 0,
        reviewCount INTEGER DEFAULT 0,
        shortDescription TEXT,
        longDescription  TEXT,
        features    TEXT
      )
    ''');

    // Tabela de favoritos (relaciona usuário → produto)
    await db.execute('''
      CREATE TABLE favorites (
        productId TEXT PRIMARY KEY
      )
    ''');

    // Tabela de pedidos
    await db.execute('''
      CREATE TABLE orders (
        id          TEXT PRIMARY KEY,
        createdAt   TEXT NOT NULL,
        status      TEXT NOT NULL DEFAULT 'confirmed',
        subtotal    REAL NOT NULL,
        shipping    REAL NOT NULL,
        taxes       REAL NOT NULL,
        total       REAL NOT NULL,
        billingName    TEXT,
        billingStreet  TEXT,
        billingCity    TEXT,
        billingState   TEXT,
        billingZip     TEXT,
        billingPhone   TEXT,
        shippingName   TEXT,
        shippingStreet TEXT,
        shippingCity   TEXT,
        shippingState  TEXT,
        shippingZip    TEXT
      )
    ''');

    // Tabela de itens do pedido (N itens para 1 pedido)
    await db.execute('''
      CREATE TABLE order_items (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        orderId     TEXT NOT NULL,
        productId   TEXT NOT NULL,
        productName TEXT NOT NULL,
        price       REAL NOT NULL,
        quantity    INTEGER NOT NULL,
        FOREIGN KEY (orderId) REFERENCES orders(id)
      )
    ''');
  }

  // ─── Produtos (cache) ──────────────────────────────────────────────────────

  Future<void> upsertProducts(List<Product> products) async {
    final db = await database;
    final batch = db.batch();
    for (final p in products) {
      batch.insert(
        'products',
        p.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Product>> getCachedProducts() async {
    final db = await database;
    final rows = await db.query('products', orderBy: 'name ASC');
    return rows.map(Product.fromMap).toList();
  }

  // ─── Favoritos ─────────────────────────────────────────────────────────────

  Future<Set<String>> getFavorites() async {
    final db = await database;
    final rows = await db.query('favorites');
    return rows.map((r) => r['productId'] as String).toSet();
  }

  Future<void> toggleFavorite(String productId) async {
    final db = await database;
    final exists = await db.query(
      'favorites',
      where: 'productId = ?',
      whereArgs: [productId],
    );
    if (exists.isEmpty) {
      await db.insert('favorites', {'productId': productId});
    } else {
      await db.delete('favorites', where: 'productId = ?', whereArgs: [productId]);
    }
  }

  Future<bool> isFavorite(String productId) async {
    final db = await database;
    final rows = await db.query(
      'favorites',
      where: 'productId = ?',
      whereArgs: [productId],
    );
    return rows.isNotEmpty;
  }

  // ─── Pedidos ───────────────────────────────────────────────────────────────

  Future<void> saveOrder(Order order) async {
    final db = await database;
    await db.insert('orders', order.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    final batch = db.batch();
    for (final item in order.items) {
      batch.insert('order_items', item.toMap(order.id));
    }
    await batch.commit(noResult: true);
  }

  Future<List<Order>> getAllOrders() async {
    final db = await database;
    final orderRows = await db.query('orders', orderBy: 'createdAt DESC');
    final List<Order> orders = [];
    for (final row in orderRows) {
      final itemRows = await db.query(
        'order_items',
        where: 'orderId = ?',
        whereArgs: [row['id']],
      );
      final items = itemRows.map(OrderItem.fromMap).toList();
      orders.add(Order.fromMap(row, items));
    }
    return orders;
  }

  Future<Order?> getOrder(String id) async {
    final db = await database;
    final rows = await db.query('orders', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final itemRows = await db.query(
      'order_items',
      where: 'orderId = ?',
      whereArgs: [id],
    );
    return Order.fromMap(rows.first, itemRows.map(OrderItem.fromMap).toList());
  }

  /// Estatísticas para o dashboard
  Future<Map<String, dynamic>> getStats() async {
    final db = await database;
    final orderCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM orders')) ?? 0;
    final totalSpent = (await db.rawQuery(
        'SELECT COALESCE(SUM(total), 0) as s FROM orders'))
        .first['s'] as double? ?? 0.0;
    final favoriteCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM favorites')) ?? 0;
    return {
      'orderCount': orderCount,
      'totalSpent': totalSpent,
      'favoriteCount': favoriteCount,
    };
  }
}