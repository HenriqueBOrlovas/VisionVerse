import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(const VisionVerseApp());
}

// ─────────────────────────────────────────────
// Paleta de Cores: Azul Fantasma + Preto Black C
// Ghost Blue  : #B0C4DE (azul acinzentado/fantasma)
// Dark Navy   : #0D1B2A (preto azulado profundo – Pantone Black C)
// Accent Blue : #4A90D9 (azul vibrante para destaques)
// ─────────────────────────────────────────────
class AppColors {
  // Azul Fantasma (Ghost Blue)
  static const Color ghostBlue = Color(0xFFB0C4DE);
  static const Color ghostBlueLight = Color(0xFFD6E4F0);
  static const Color ghostBlueMid = Color(0xFF7FAED4);

  // Preto Black C (Pantone Black C ≈ #0D1B2A, variações escuras)
  static const Color blackC = Color(0xFF0D1B2A);
  static const Color blackCLight = Color(0xFF1A2D40);
  static const Color blackCMid = Color(0xFF243447);

  // Accent e utilitários
  static const Color accent = Color(0xFF4A90D9);
  static const Color accentLight = Color(0xFF6AAEE8);
  static const Color gold = Color(0xFFFFD700);
  static const Color success = Color(0xFF4CAF8A);
  static const Color error = Color(0xFFE05252);
  static const Color surface = Color(0xFF142233);
  static const Color cardBg = Color(0xFF1E3348);
  static const Color divider = Color(0xFF2A4060);
}

// ─────────────────────────────────────────────
// Modelo de Dados
// ─────────────────────────────────────────────

/// Modelo de uma série disponível na VisionVerse.
class Product {
  final String id;
  final String name;
  final double price;
  final int stock;
  final String icon;
  final String rating;
  final String genre;
  final String shortDescription;
  final String longDescription;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.icon,
    required this.rating,
    required this.genre,
    required this.shortDescription,
    required this.longDescription,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      stock: json['stock'] as int,
      icon: json['icon'] as String,
      rating: (json['rating'] ?? '0.0') as String,
      genre: (json['genre'] ?? 'Drama') as String,
      shortDescription: json['shortDescription'] as String,
      longDescription: json['longDescription'] as String,
    );
  }
}

// ─────────────────────────────────────────────
// Controlador da Loja
// ─────────────────────────────────────────────

/// Controlador central — produtos, carrinho, pedido.
class StoreController extends ChangeNotifier {
  final Map<String, int> _cart = <String, int>{};

  List<Product> products = <Product>[];
  bool loading = true;
  String? loadError;
  String? confirmationNumber;

  Future<void> loadProducts() async {
    try {
      final String jsonText = await rootBundle.loadString('assets/products.json');
      final List<dynamic> decoded = json.decode(jsonText) as List<dynamic>;
      products = decoded
          .map((dynamic item) => Product.fromJson(item as Map<String, dynamic>))
          .toList();
      loading = false;
      notifyListeners();
    } catch (error) {
      loading = false;
      loadError = 'Não foi possível carregar o catálogo: $error';
      notifyListeners();
    }
  }

  Map<String, int> get cart => Map.unmodifiable(_cart);
  int get cartItemCount => _cart.values.fold(0, (int t, int q) => t + q);

  Product productById(String id) =>
      products.firstWhere((Product p) => p.id == id);

  int quantityOf(String productId) => _cart[productId] ?? 0;

  List<Product> get cartProducts => _cart.keys.map(productById).toList();

  bool addToCart(Product product) {
    final int next = quantityOf(product.id) + 1;
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

  void cancelOrder() {
    _cart.clear();
    confirmationNumber = null;
    notifyListeners();
  }

  String finishOrder() {
    final String number = 'VV-${DateTime.now().year}-${100000 + Random().nextInt(900000)}';
    confirmationNumber = number;
    notifyListeners();
    return number;
  }

  double get subtotal {
    double total = 0;
    _cart.forEach((String id, int qty) {
      total += productById(id).price * qty;
    });
    return total;
  }

  /// Frete grátis acima de R$ 300; abaixo disso R$ 19,90.
  double get shipping => subtotal == 0 ? 0 : (subtotal >= 300 ? 0 : 19.90);

  /// Imposto simulado de 10% para fins didáticos.
  double get taxes => subtotal * 0.10;

  double get total => subtotal + shipping + taxes;
}

// ─────────────────────────────────────────────
// App Root
// ─────────────────────────────────────────────

class VisionVerseApp extends StatefulWidget {
  const VisionVerseApp({super.key});

  @override
  State<VisionVerseApp> createState() => _VisionVerseAppState();
}

class _VisionVerseAppState extends State<VisionVerseApp> {
  final StoreController controller = StoreController();

  @override
  void initState() {
    super.initState();
    controller.loadProducts();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VisionVerse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.dark(
          primary: AppColors.accent,
          secondary: AppColors.ghostBlue,
          surface: AppColors.surface,
          background: AppColors.blackC,
          onPrimary: Colors.white,
          onSecondary: AppColors.blackC,
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: AppColors.blackC,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.blackCLight,
          foregroundColor: Colors.white,
          centerTitle: false,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.cardBg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.divider, width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.blackCLight,
          labelStyle: const TextStyle(color: AppColors.ghostBlue),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.accent, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.error, width: 2),
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.accent
                : AppColors.divider,
          ),
        ),
        dividerColor: AppColors.divider,
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: AppColors.blackCMid,
          contentTextStyle: TextStyle(color: Colors.white),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: AnimatedBuilder(
        animation: controller,
        builder: (BuildContext context, Widget? child) {
          if (controller.loading) return const LoadingPage();
          if (controller.loadError != null) {
            return ErrorPage(message: controller.loadError!);
          }
          return HomePage(controller: controller);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Páginas utilitárias
// ─────────────────────────────────────────────

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.blackC,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            VisionVerseLogo(size: 72),
            SizedBox(height: 24),
            CircularProgressIndicator(color: AppColors.ghostBlue),
            SizedBox(height: 14),
            Text(
              'Carregando catálogo...',
              style: TextStyle(color: AppColors.ghostBlue, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorPage extends StatelessWidget {
  final String message;
  const ErrorPage({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Erro')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.error_outline, color: AppColors.error, size: 52),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.ghostBlue)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// AppBar compartilhada
// ─────────────────────────────────────────────

class VisionVerseAppBar extends StatelessWidget implements PreferredSizeWidget {
  final StoreController controller;
  final String title;
  final bool showBack;

  const VisionVerseAppBar({
    required this.controller,
    required this.title,
    this.showBack = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: showBack,
      iconTheme: const IconThemeData(color: AppColors.ghostBlue),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const VisionVerseLogo(size: 28),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      actions: <Widget>[
        AnimatedBuilder(
          animation: controller,
          builder: (BuildContext context, Widget? child) {
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Badge(
                label: Text('${controller.cartItemCount}'),
                backgroundColor: AppColors.accent,
                isLabelVisible: controller.cartItemCount > 0,
                child: IconButton(
                  tooltip: 'Meu Carrinho',
                  icon: const Icon(Icons.shopping_cart_outlined,
                      color: AppColors.ghostBlue),
                  onPressed: () => openCart(context, controller),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// ─────────────────────────────────────────────
// Navegação global
// ─────────────────────────────────────────────

void openCart(BuildContext context, StoreController controller) {
  Navigator.push(
    context,
    MaterialPageRoute<void>(builder: (_) => CartPage(controller: controller)),
  );
}

void openProducts(BuildContext context, StoreController controller,
    {bool replace = false}) {
  final MaterialPageRoute<void> route = MaterialPageRoute<void>(
    builder: (_) => ProductsPage(controller: controller),
  );
  if (replace) {
    Navigator.pushReplacement(context, route);
  } else {
    Navigator.push(context, route);
  }
}

void showAppMessage(BuildContext context, String message,
    {bool success = false}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor:
          success ? AppColors.success : AppColors.blackCMid,
    ),
  );
}

// ─────────────────────────────────────────────
// Logo VisionVerse
// ─────────────────────────────────────────────

class VisionVerseLogo extends StatelessWidget {
  final double size;
  const VisionVerseLogo({required this.size, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[AppColors.blackCMid, AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(color: AppColors.ghostBlue, width: size * 0.04),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.ghostBlue.withOpacity(0.25),
            blurRadius: size * 0.3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        Icons.smart_display,
        size: size * 0.55,
        color: AppColors.ghostBlue,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Passo 1 – Página Inicial
// ─────────────────────────────────────────────

class HomePage extends StatelessWidget {
  final StoreController controller;
  const HomePage({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VisionVerseAppBar(controller: controller, title: 'VisionVerse'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            // Hero Banner
            const HeroBanner(),
            const SizedBox(height: 24),
            // Título
            const Text(
              'VisionVerse',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'As melhores séries do ranking IMDb\nem um só lugar.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.ghostBlue.withOpacity(0.85),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            // Badge IMDb
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5C518).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF5C518), width: 1),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.star, color: Color(0xFFF5C518), size: 16),
                    SizedBox(width: 5),
                    Text(
                      'Top Séries IMDb',
                      style: TextStyle(
                        color: Color(0xFFF5C518),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            // Botão principal
            _GhostButton(
              icon: Icons.movie_filter_outlined,
              label: 'Explorar Catálogo',
              filled: true,
              onPressed: () => openProducts(context, controller),
            ),
            const SizedBox(height: 12),
            _GhostButton(
              icon: Icons.shopping_cart_outlined,
              label: 'Meu Carrinho',
              filled: false,
              onPressed: () => openCart(context, controller),
            ),
            const SizedBox(height: 24),
            // Stats rápidas
            const _StatsRow(),
            const SizedBox(height: 20),
            const DidacticNote(
              title: 'O que esta tela ensina?',
              text:
                  'A Página Inicial apresenta a loja, seu tema e oferece navegação rápida para o catálogo e para o carrinho. O hero banner contextualiza o universo das séries.',
            ),
          ],
        ),
      ),
    );
  }
}

class HeroBanner extends StatelessWidget {
  const HeroBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.blackCMid, AppColors.surface, AppColors.blackCLight],
        ),
        border: Border.all(color: AppColors.divider),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.ghostBlue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          // Background glow
          Positioned(
            top: -20,
            left: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.ghostBlue.withOpacity(0.06),
              ),
            ),
          ),
          // Ícones de séries
          const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                _HeroBadge(icon: Icons.local_fire_department, label: '9.5★', sublabel: 'Breaking Bad'),
                _HeroBadge(icon: Icons.shield_outlined, label: '9.4★', sublabel: 'Chernobyl'),
                _HeroBadge(icon: Icons.auto_awesome, label: '9.2★', sublabel: 'Sopranos'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;

  const _HeroBadge({
    required this.icon,
    required this.label,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: <Color>[AppColors.blackCMid, AppColors.cardBg],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.ghostBlue.withOpacity(0.35)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.ghostBlue.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, size: 34, color: AppColors.ghostBlue),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(
                color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.bold)),
        Text(sublabel,
            style: TextStyle(color: AppColors.ghostBlue.withOpacity(0.7), fontSize: 10)),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _StatCard(icon: Icons.movie, value: '8', label: 'Séries'),
        const SizedBox(width: 10),
        _StatCard(icon: Icons.star, value: '9.5', label: 'Melhor nota'),
        const SizedBox(width: 10),
        _StatCard(icon: Icons.local_offer, value: 'R\$34', label: 'A partir de'),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatCard({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: AppColors.ghostBlue, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
            Text(label,
                style: TextStyle(
                    color: AppColors.ghostBlue.withOpacity(0.7), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Botão estilo Ghost Blue
// ─────────────────────────────────────────────

class _GhostButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onPressed;

  const _GhostButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: <Color>[AppColors.ghostBlueMid, AppColors.accent],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.accent.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.ghostBlue, width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, color: AppColors.ghostBlue, size: 20),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                      color: AppColors.ghostBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Passo 2 – Catálogo de Séries
// ─────────────────────────────────────────────

class ProductsPage extends StatelessWidget {
  final StoreController controller;
  const ProductsPage({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VisionVerseAppBar(
          controller: controller,
          title: 'VisionVerse',
          showBack: true),
      body: AnimatedBuilder(
        animation: controller,
        builder: (BuildContext context, Widget? child) {
          return ListView(
            padding: const EdgeInsets.all(14),
            children: <Widget>[
              const PageHeader(
                title: 'Catálogo de Séries',
                subtitle: 'Séries com maior ranking no IMDb. Toque em Selecionar para detalhes.',
              ),
              for (final Product product in controller.products)
                ProductCard(
                  product: product,
                  onSelect: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => ProductDetailsPage(
                            controller: controller, product: product),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onSelect;

  const ProductCard({required this.product, required this.onSelect, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onSelect,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Ícone da série
              ProductIconWidget(product: product, size: 72),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            product.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.white),
                          ),
                        ),
                        // Badge IMDb
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5C518),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '★ ${product.rating}',
                            style: const TextStyle(
                                color: Colors.black,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.genre,
                      style: TextStyle(
                          color: AppColors.ghostBlue.withOpacity(0.7),
                          fontSize: 12),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      product.shortDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: AppColors.ghostBlue.withOpacity(0.85),
                          fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          formatMoney(product.price),
                          style: const TextStyle(
                            color: AppColors.accentLight,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        _SmallFilledButton(
                          label: 'Selecionar',
                          onPressed: onSelect,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallFilledButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _SmallFilledButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: <Color>[AppColors.ghostBlueMid, AppColors.accent],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Passo 3 – Detalhes da Série
// ─────────────────────────────────────────────

class ProductDetailsPage extends StatelessWidget {
  final StoreController controller;
  final Product product;

  const ProductDetailsPage(
      {required this.controller, required this.product, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VisionVerseAppBar(
          controller: controller, title: 'VisionVerse', showBack: true),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: <Widget>[
          // Header da série
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ProductIconWidget(product: product, size: 100),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Badge gênero
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.blackCMid,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Text(
                          product.genre,
                          style: const TextStyle(
                              color: AppColors.ghostBlue, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('ID: ${product.id}',
                          style: TextStyle(
                              color: AppColors.ghostBlue.withOpacity(0.5),
                              fontSize: 11)),
                      const SizedBox(height: 10),
                      // Rating IMDb grande
                      Row(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5C518),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const Icon(Icons.star,
                                    color: Colors.black, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  product.rating,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const Text(
                                  '/10 IMDb',
                                  style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        formatMoney(product.price),
                        style: const TextStyle(
                          color: AppColors.accentLight,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: <Widget>[
                          const Icon(Icons.check_circle_outline,
                              color: AppColors.success, size: 16),
                          const SizedBox(width: 5),
                          Text(
                            'Disponível: ${product.stock} licenças',
                            style: const TextStyle(
                                color: AppColors.success, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // Sinopse
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Row(
                  children: <Widget>[
                    Icon(Icons.description_outlined,
                        color: AppColors.ghostBlue, size: 18),
                    SizedBox(width: 6),
                    Text('Sinopse',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  product.longDescription,
                  style: TextStyle(
                    color: AppColors.ghostBlue.withOpacity(0.85),
                    height: 1.6,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Botão adicionar ao carrinho com gradient
          _GhostButton(
            icon: Icons.add_shopping_cart,
            label: 'Adicionar ao Carrinho',
            filled: true,
            onPressed: () {
              final bool added = controller.addToCart(product);
              if (added) {
                showAppMessage(context, '${product.name} adicionado ao carrinho!',
                    success: true);
              } else {
                showAppMessage(
                    context, 'Quantidade excede o estoque disponível.');
              }
            },
          ),
          const SizedBox(height: 10),
          _GhostButton(
            icon: Icons.arrow_back,
            label: 'Ver Mais Séries',
            filled: false,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(height: 20),
          const DidacticNote(
            title: 'Regra de negócio',
            text:
                'O botão Adicionar ao Carrinho valida o estoque antes de confirmar. Cada série tem uma nota IMDb real que é exibida com destaque visual.',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Passo 4 – Carrinho
// ─────────────────────────────────────────────

class CartPage extends StatelessWidget {
  final StoreController controller;
  const CartPage({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VisionVerseAppBar(
          controller: controller, title: 'VisionVerse', showBack: true),
      body: AnimatedBuilder(
        animation: controller,
        builder: (BuildContext context, Widget? child) {
          return ListView(
            padding: const EdgeInsets.all(14),
            children: <Widget>[
              PageHeader(
                title: 'Carrinho (${controller.cartItemCount} itens)',
                subtitle:
                    'Revise as séries, ajuste quantidades e acompanhe o total.',
              ),
              if (controller.cartProducts.isEmpty)
                const EmptyCartCard()
              else ...<Widget>[
                for (final Product product in controller.cartProducts)
                  CartItemCard(controller: controller, product: product),
                const SizedBox(height: 8),
                SummaryCard(controller: controller),
              ],
              const SizedBox(height: 16),
              _GhostButton(
                icon: Icons.lock_outline,
                label: 'Finalizar Pedido',
                filled: true,
                onPressed: controller.cartProducts.isEmpty
                    ? () => showAppMessage(
                        context, 'Adicione séries antes de finalizar.')
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                              builder: (_) =>
                                  CheckoutPage(controller: controller)),
                        );
                      },
              ),
              const SizedBox(height: 10),
              // Cancelar pedido
              _OutlineErrorButton(
                icon: Icons.delete_outline,
                label: 'Cancelar Pedido',
                onPressed: () {
                  controller.cancelOrder();
                  showAppMessage(
                      context, 'Pedido cancelado. Carrinho esvaziado.');
                },
              ),
              const SizedBox(height: 10),
              _GhostButton(
                icon: Icons.movie_filter_outlined,
                label: 'Ver Mais Séries',
                filled: false,
                onPressed: () =>
                    openProducts(context, controller, replace: true),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OutlineErrorButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  const _OutlineErrorButton(
      {required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.error, width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, color: AppColors.error, size: 20),
                const SizedBox(width: 10),
                Text(label,
                    style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EmptyCartCard extends StatelessWidget {
  const EmptyCartCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: <Widget>[
          Icon(Icons.movie_outlined, size: 60, color: AppColors.ghostBlue.withOpacity(0.4)),
          const SizedBox(height: 12),
          const Text('Carrinho vazio',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          const SizedBox(height: 6),
          Text('Explore o catálogo e adicione suas séries favoritas.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.ghostBlue.withOpacity(0.7), fontSize: 13)),
        ],
      ),
    );
  }
}

class CartItemCard extends StatelessWidget {
  final StoreController controller;
  final Product product;

  const CartItemCard(
      {required this.controller, required this.product, super.key});

  @override
  Widget build(BuildContext context) {
    final int quantity = controller.quantityOf(product.id);
    final double itemSubtotal = product.price * quantity;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            ProductIconWidget(product: product, size: 60),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    product.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 14),
                  ),
                  Text(
                    'ID: ${product.id}',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.ghostBlue.withOpacity(0.5)),
                  ),
                  Text(formatMoney(product.price),
                      style: const TextStyle(
                          color: AppColors.accentLight, fontSize: 13)),
                  const SizedBox(height: 6),
                  QuantityControl(
                    quantity: quantity,
                    onDecrease: () =>
                        controller.updateQuantity(product, quantity - 1),
                    onIncrease: () {
                      final bool ok =
                          controller.updateQuantity(product, quantity + 1);
                      if (!ok) {
                        showAppMessage(context,
                            'Estoque disponível: ${product.stock} unidades.');
                      }
                    },
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text('Subtotal',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.ghostBlue.withOpacity(0.7))),
                Text(formatMoney(itemSubtotal),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class QuantityControl extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const QuantityControl({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.ghostBlue.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(8),
        color: AppColors.blackCLight,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          InkWell(
            onTap: onDecrease,
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Icon(Icons.remove, size: 16, color: AppColors.ghostBlue),
            ),
          ),
          Container(
            width: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.symmetric(
                vertical: BorderSide(
                    color: AppColors.ghostBlue.withOpacity(0.3))),
            ),
            child: Text('$quantity',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          InkWell(
            onTap: onIncrease,
            borderRadius:
                const BorderRadius.horizontal(right: Radius.circular(8)),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Icon(Icons.add, size: 16, color: AppColors.ghostBlue),
            ),
          ),
        ],
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final StoreController controller;
  const SummaryCard({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text('Resumo da compra',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          const SizedBox(height: 10),
          SummaryRow(
              label: 'Subtotal', value: formatMoney(controller.subtotal)),
          SummaryRow(label: 'Frete', value: formatMoney(controller.shipping)),
          SummaryRow(
              label: 'Impostos (10%)', value: formatMoney(controller.taxes)),
          Divider(color: AppColors.divider),
          SummaryRow(
              label: 'Total',
              value: formatMoney(controller.total),
              highlight: true),
          if (controller.shipping == 0 && controller.subtotal > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.local_shipping,
                      color: AppColors.success, size: 14),
                  const SizedBox(width: 4),
                  Text('Frete grátis aplicado!',
                      style: const TextStyle(
                          color: AppColors.success, fontSize: 12)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const SummaryRow(
      {required this.label,
      required this.value,
      this.highlight = false,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label,
              style: TextStyle(
                  color: highlight
                      ? Colors.white
                      : AppColors.ghostBlue.withOpacity(0.8),
                  fontWeight:
                      highlight ? FontWeight.bold : FontWeight.normal,
                  fontSize: highlight ? 16 : 14)),
          Text(value,
              style: TextStyle(
                  color: highlight ? AppColors.accentLight : Colors.white,
                  fontWeight:
                      highlight ? FontWeight.bold : FontWeight.normal,
                  fontSize: highlight ? 18 : 14)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Passo 5 – Finalização do Pedido
// ─────────────────────────────────────────────

class CheckoutPage extends StatefulWidget {
  final StoreController controller;
  const CheckoutPage({required this.controller, super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController billingName =
      TextEditingController(text: 'João da Silva');
  final TextEditingController billingStreet =
      TextEditingController(text: 'Rua das Flores, 123');
  final TextEditingController billingCity =
      TextEditingController(text: 'São Paulo');
  final TextEditingController billingState =
      TextEditingController(text: 'SP');
  final TextEditingController billingZip =
      TextEditingController(text: '01234-567');
  final TextEditingController billingPhone =
      TextEditingController(text: '(11) 99999-9999');

  final TextEditingController shippingName =
      TextEditingController(text: 'João da Silva');
  final TextEditingController shippingStreet =
      TextEditingController(text: 'Rua das Flores, 123');
  final TextEditingController shippingCity =
      TextEditingController(text: 'São Paulo');
  final TextEditingController shippingState =
      TextEditingController(text: 'SP');
  final TextEditingController shippingZip =
      TextEditingController(text: '01234-567');

  bool useSameAddress = true;

  @override
  void dispose() {
    billingName.dispose();
    billingStreet.dispose();
    billingCity.dispose();
    billingState.dispose();
    billingZip.dispose();
    billingPhone.dispose();
    shippingName.dispose();
    shippingStreet.dispose();
    shippingCity.dispose();
    shippingState.dispose();
    shippingZip.dispose();
    super.dispose();
  }

  void copyBillingToShipping() {
    shippingName.text = billingName.text;
    shippingStreet.text = billingStreet.text;
    shippingCity.text = billingCity.text;
    shippingState.text = billingState.text;
    shippingZip.text = billingZip.text;
  }

  void confirmOrder() {
    if (widget.controller.cartProducts.isEmpty) {
      showAppMessage(
          context, 'O carrinho está vazio. Adicione séries antes de finalizar.');
      return;
    }
    if (!(formKey.currentState?.validate() ?? false)) {
      showAppMessage(
          context, 'Preencha corretamente os endereços de cobrança e entrega.');
      return;
    }
    if (useSameAddress) copyBillingToShipping();
    final String number = widget.controller.finishOrder();
    showAppMessage(context, 'Pedido confirmado: $number', success: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VisionVerseAppBar(
          controller: widget.controller, title: 'VisionVerse', showBack: true),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (BuildContext context, Widget? child) {
          return Form(
            key: formKey,
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: <Widget>[
                const PageHeader(
                  title: 'Finalização do Pedido',
                  subtitle:
                      'Informe os endereços, revise o resumo e confirme sua assinatura.',
                ),
                AddressSection(
                  title: 'Endereço de cobrança',
                  icon: Icons.location_on,
                  controllers: <TextEditingController>[
                    billingName,
                    billingStreet,
                    billingCity,
                    billingState,
                    billingZip,
                    billingPhone
                  ],
                  labels: const <String>[
                    'Nome',
                    'Rua e número',
                    'Cidade',
                    'UF',
                    'CEP',
                    'Telefone'
                  ],
                ),
                const SizedBox(height: 12),
                // Checkbox mesmo endereço
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: CheckboxListTile(
                    value: useSameAddress,
                    onChanged: (bool? value) {
                      setState(() {
                        useSameAddress = value ?? false;
                        if (useSameAddress) copyBillingToShipping();
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('Usar mesmo endereço para entrega',
                        style: TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                ),
                if (!useSameAddress) ...<Widget>[
                  const SizedBox(height: 12),
                  AddressSection(
                    title: 'Endereço de entrega',
                    icon: Icons.local_shipping,
                    controllers: <TextEditingController>[
                      shippingName,
                      shippingStreet,
                      shippingCity,
                      shippingState,
                      shippingZip
                    ],
                    labels: const <String>[
                      'Nome',
                      'Rua e número',
                      'Cidade',
                      'UF',
                      'CEP'
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                CheckoutOrderSummary(controller: widget.controller),
                const SizedBox(height: 12),
                _GhostButton(
                  icon: Icons.lock_outline,
                  label: 'Confirmar Pedido',
                  filled: true,
                  onPressed: confirmOrder,
                ),
                if (widget.controller.confirmationNumber != null) ...<Widget>[
                  const SizedBox(height: 12),
                  ConfirmationCard(
                      number: widget.controller.confirmationNumber!),
                ],
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

class AddressSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<TextEditingController> controllers;
  final List<String> labels;

  const AddressSection({
    required this.title,
    required this.icon,
    required this.controllers,
    required this.labels,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, color: AppColors.ghostBlue, size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < controllers.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextFormField(
                controller: controllers[i],
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(labelText: labels[i]),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Campo obrigatório';
                  }
                  return null;
                },
              ),
            ),
        ],
      ),
    );
  }
}

class CheckoutOrderSummary extends StatelessWidget {
  final StoreController controller;
  const CheckoutOrderSummary({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Resumo do pedido',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          const SizedBox(height: 10),
          for (final Product product in controller.cartProducts)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: <Widget>[
                  ProductIconWidget(product: product, size: 40),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(product.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        Text(
                            'Qtd: ${controller.quantityOf(product.id)}',
                            style: TextStyle(
                                color: AppColors.ghostBlue.withOpacity(0.7),
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  Text(
                    formatMoney(product.price *
                        controller.quantityOf(product.id)),
                    style: const TextStyle(
                        color: AppColors.accentLight,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          Divider(color: AppColors.divider),
          SummaryRow(
              label: 'Subtotal', value: formatMoney(controller.subtotal)),
          SummaryRow(
              label: 'Frete', value: formatMoney(controller.shipping)),
          SummaryRow(
              label: 'Impostos (10%)', value: formatMoney(controller.taxes)),
          SummaryRow(
              label: 'Total',
              value: formatMoney(controller.total),
              highlight: true),
        ],
      ),
    );
  }
}

class ConfirmationCard extends StatelessWidget {
  final String number;
  const ConfirmationCard({required this.number, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Pedido Confirmado!',
                    style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                const SizedBox(height: 2),
                Text(number,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                Text('Os detalhes foram enviados ao e-mail cadastrado.',
                    style: TextStyle(
                        color: AppColors.ghostBlue.withOpacity(0.7),
                        fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Componentes reutilizáveis
// ─────────────────────────────────────────────

class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const PageHeader({required this.title, required this.subtitle, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
                color: AppColors.ghostBlue.withOpacity(0.75), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class DidacticNote extends StatelessWidget {
  final String title;
  final String text;

  const DidacticNote({required this.title, required this.text, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.ghostBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.ghostBlue.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.school, color: AppColors.ghostBlue, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  TextSpan(
                    text: '$title\n',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                  TextSpan(
                    text: text,
                    style: TextStyle(
                        color: AppColors.ghostBlue.withOpacity(0.8),
                        fontSize: 12,
                        height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ícone visual da série baseado no campo "icon" do JSON.
class ProductIconWidget extends StatelessWidget {
  final Product product;
  final double size;

  const ProductIconWidget({required this.product, required this.size, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[AppColors.blackCMid, AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(
            color: AppColors.ghostBlue.withOpacity(0.3), width: 1),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.ghostBlue.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        _seriesIcon(product.icon),
        size: size * 0.50,
        color: AppColors.ghostBlue,
      ),
    );
  }

  IconData _seriesIcon(String icon) {
    switch (icon) {
      case 'chemistry':
        return Icons.science;
      case 'city':
        return Icons.location_city;
      case 'nuclear':
        return Icons.dangerous;
      case 'military':
        return Icons.military_tech;
      case 'mafia':
        return Icons.gavel;
      case 'crown':
        return Icons.castle;
      case 'detective':
        return Icons.search;
      case 'timeloop':
        return Icons.loop;
      default:
        return Icons.smart_display;
    }
  }
}

// ─────────────────────────────────────────────
// Utilitário
// ─────────────────────────────────────────────

String formatMoney(double value) {
  return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
}