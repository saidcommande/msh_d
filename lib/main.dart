// main.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:archive/archive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/html.dart' as html;
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'services/security_service.dart';
import 'services/shared_catalog_service.dart';
import 'widgets/login_dialog.dart';

// Constante pour la conversion Euro -> MAD
const double euroToMad = 1.00;

// Fonction pour formater les prix en MAD
String formatPrice(double price) {
  return '${(price * euroToMad).toStringAsFixed(2)} MAD';
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Commande Pro',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2),
          brightness: Brightness.light,
        ),
        cardTheme: const CardThemeData(
          elevation: 3,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16))),
          shadowColor: Colors.black26,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 2,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          elevation: 8,
          selectedItemColor: const Color(0xFF1976D2),
          unselectedItemColor: Colors.grey.shade600,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: MainInterface(),
    );
  }
}

class MainInterface extends StatefulWidget {
  const MainInterface({super.key});

  static _MainInterfaceState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MainInterfaceState>();

  @override
  _MainInterfaceState createState() => _MainInterfaceState();
}

class _MainInterfaceState extends State<MainInterface> {
  int _currentIndex = 0;
  final _catalogueKey = GlobalKey<_CataloguePageState>();
  bool _isLoggedIn = false;
  late final List<Widget> _pages = [
    CataloguePage(key: _catalogueKey),
    CommandPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await SecurityService.isAuthenticated();
    setState(() {
      _isLoggedIn = isLoggedIn;
    });
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LoginDialog(
        onLoginSuccess: () {
          setState(() {
            _isLoggedIn = true;
          });
        },
      ),
    );
  }

  Future<void> _handleLogout() async {
    await SecurityService.logout();
    setState(() {
      _isLoggedIn = false;
    });
  }

  void navigateToPage(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.shopping_cart, color: Colors.white),
            SizedBox(width: 10),
            Text('PDF Commande', style: TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: Colors.blue[700],
        actions: [
          // Bouton de connexion/déconnexion
          Container(
            margin: EdgeInsets.symmetric(horizontal: 8),
            child: IconButton(
              icon: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isLoggedIn ? Icons.logout : Icons.login,
                    color: Colors.white70,
                    size: 24,
                  ),
                  Text(
                    _isLoggedIn ? 'Déconnexion' : 'Connexion',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              onPressed: _isLoggedIn ? _handleLogout : _showLoginDialog,
              tooltip: _isLoggedIn ? 'Déconnexion' : 'Connexion',
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'load_creator',
                child: Row(
                  children: [
                    Icon(Icons.inventory, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Charger catalogue créateur'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'share_catalog',
                child: Row(
                  children: [
                    Icon(Icons.share, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Partager le catalogue'),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'load_creator') {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => CreatorCataloguePage(),
                ));
              } else if (value == 'share_catalog') {
                // Vérifier le code de sécurité avant de partager
                final TextEditingController securityController =
                    TextEditingController();
                final bool? confirmed = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Code de sécurité'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                              'Cette action mettra à jour le catalogue pour tous les utilisateurs.'),
                          SizedBox(height: 16),
                          TextField(
                            controller: securityController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Entrez le code de sécurité',
                              prefixIcon: Icon(Icons.security),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text('Annuler'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (securityController.text == "said@1984") {
                              Navigator.of(context).pop(true);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Code de sécurité incorrect'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          child: Text('Confirmer'),
                        ),
                      ],
                    );
                  },
                );

                if (confirmed == true) {
                  try {
                    // Get the products from the CataloguePage state
                    final catalogueProducts =
                        _catalogueKey.currentState?._products ?? [];

                    // Convertir les produits en JSON
                    final List<Map<String, dynamic>> catalogData =
                        catalogueProducts.map((p) => p.toJson()).toList();

                    // Mettre à jour le catalogue en utilisant le SharedCatalogService
                    final success =
                        await SharedCatalogService.uploadCatalog(catalogData);

                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Catalogue partagé avec succès!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      throw Exception('Échec du partage du catalogue');
                    }
                  } catch (e) {
                    print('Error sharing catalog: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur lors du partage du catalogue'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey.shade600,
        elevation: 8,
        backgroundColor: Theme.of(context).colorScheme.surface,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Catalogue',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                Icon(Icons.shopping_cart_outlined),
                if (globalCart.isNotEmpty)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${globalCart.length}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onError,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            activeIcon: Stack(
              children: [
                Icon(Icons.shopping_cart),
                if (globalCart.isNotEmpty)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${globalCart.length}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onError,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Commande',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Paramètres',
          ),
        ],
      ),
    );
  }
}

class Product {
  final String id;
  final String name;
  final String description;
  final String? catalog;
  final double price;
  final List<String> sizes;
  final List<double> prices;
  final Uint8List? imageBytes;
  final String? imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.description,
    this.catalog,
    required this.price,
    required this.sizes,
    required this.prices,
    this.imageBytes,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'catalog': catalog,
      'price': price,
      'sizes': sizes,
      'prices': prices,
      'imageBytes': imageBytes != null ? base64Encode(imageBytes!) : null,
      'imageUrl': imageUrl,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      catalog: json['catalog'],
      price: (json['price'] is int)
          ? (json['price'] as int).toDouble()
          : (json['price'] is String)
              ? double.tryParse(json['price']) ?? 0.0
              : json['price'] ?? 0.0,
      sizes: List<String>.from(json['sizes'] ?? []),
      prices: List<double>.from((json['prices'] ?? []).map((p) => (p is int)
          ? p.toDouble()
          : (p is String ? double.tryParse(p) ?? 0.0 : p))),
      imageBytes:
          json['imageBytes'] != null ? base64Decode(json['imageBytes']) : null,
      imageUrl: json['imageUrl'],
    );
  }
}

// Variable globale pour le panier
List<CartItem> globalCart = [];

class CataloguePage extends StatefulWidget {
  CataloguePage({Key? key}) : super(key: key);

  @override
  _CataloguePageState createState() => _CataloguePageState();
}

class _CataloguePageState extends State<CataloguePage> {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  bool _isEditMode = false;
  String? _selectedCatalog;
  Map<String, int> _catalogCounts = {};
  final List<String> _availableCatalogs = [
    'TOUS',
    'AKRO',
    'ANBO',
    'GOSTASPAIN'
  ];

  @override
  void initState() {
    super.initState();
    _loadCatalogueFromPreferences();
  }

  Future<void> _loadCatalogueFromPreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Début du chargement du catalogue...');

      // Charger le catalogue partagé
      List<dynamic> catalogData = await SharedCatalogService.getCatalog();

      setState(() {
        _products = catalogData.map((data) => Product.fromJson(data)).toList();
        _filteredProducts = _products;
        _selectedCatalog = 'TOUS';
        _updateCatalogCounts();
        _isLoading = false;
      });

      // Afficher un message de succès ou d'information
      if (_products.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Catalogue vide - Chargez un catalogue pour commencer'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Actualiser',
              onPressed: _refreshCatalog,
            ),
          ),
        );
      } else {
        print('Catalogue chargé avec succès: ${_products.length} produits');
      }
    } catch (e) {
      print('Error loading catalogue: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement du catalogue'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Réessayer',
            onPressed: _refreshCatalog,
          ),
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Nouvelle méthode pour actualiser le catalogue
  Future<void> _refreshCatalog() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Actualisation forcée du catalogue...');

      // Forcer le rechargement depuis le serveur
      List<dynamic> catalogData = await SharedCatalogService.forceRefresh();

      setState(() {
        _products = catalogData.map((data) => Product.fromJson(data)).toList();
        _filteredProducts = _products;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Catalogue actualisé (${_products.length} produits)'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Erreur lors de l\'actualisation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible d\'actualiser le catalogue'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterProducts(String query) {
    setState(() {
      _filteredProducts = _products.where((product) {
        // Filtrer par catalogue si un catalogue spécifique est sélectionné
        bool catalogMatch = _selectedCatalog == null ||
            _selectedCatalog == 'TOUS' ||
            product.catalog == _selectedCatalog;

        // Filtrer par texte de recherche
        bool textMatch = query.isEmpty ||
            product.name.toLowerCase().contains(query.toLowerCase()) ||
            product.description.toLowerCase().contains(query.toLowerCase());

        return catalogMatch && textMatch;
      }).toList();
    });
  }

  void _updateCatalogCounts() {
    _catalogCounts.clear();
    for (var product in _products) {
      final catalog = product.catalog ?? 'INCONNU';
      _catalogCounts[catalog] = (_catalogCounts[catalog] ?? 0) + 1;
    }
  }

  void _selectCatalog(String? catalog) {
    setState(() {
      _selectedCatalog = catalog;
    });
    _filterProducts(_searchController.text);
  }

  Color _getCatalogColor(String catalog) {
    switch (catalog.toUpperCase()) {
      case 'AKRO':
        return Colors.blue.shade600;
      case 'ANBO':
        return Colors.orange.shade600;
      case 'GOSTASPAIN':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  void _showSecurityDialog() {
    final TextEditingController securityController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Code de sécurité'),
          content: TextField(
            controller: securityController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Entrez le code de sécurité',
              prefixIcon: Icon(Icons.security, color: Colors.blue),
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (securityController.text == "said@1984") {
                  Navigator.of(context).pop();
                  setState(() {
                    _isEditMode = !_isEditMode;
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Code de sécurité incorrect'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Valider'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editProduct(int index) async {
    final product = _filteredProducts[index];
    final nameController = TextEditingController(text: product.name);
    final descriptionController =
        TextEditingController(text: product.description);
    final sizesController =
        TextEditingController(text: product.sizes.join(', '));
    final pricesController = TextEditingController(
        text: product.prices.map((p) => p.toString()).join(', '));

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Modifier le produit'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nom du produit',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: sizesController,
                  decoration: InputDecoration(
                    labelText: 'Tailles (séparées par des virgules)',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: pricesController,
                  decoration: InputDecoration(
                    labelText: 'Prix (séparés par des virgules)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Créer un nouveau produit avec les valeurs modifiées
                final updatedProduct = Product(
                  id: product.id,
                  name: nameController.text,
                  description: descriptionController.text,
                  sizes: sizesController.text
                      .split(',')
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .toList(),
                  prices: pricesController.text
                      .split(',')
                      .map((p) => double.tryParse(p.trim()) ?? 0.0)
                      .where((p) => p > 0)
                      .toList(),
                  imageBytes: product.imageBytes,
                  price: product.price,
                );

                // Mettre à jour le produit dans la liste
                setState(() {
                  _products[_products.indexWhere((p) => p.id == product.id)] =
                      updatedProduct;
                  _filteredProducts = _products;
                });

                // Sauvegarder dans SharedPreferences
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('user_catalogue_data',
                    json.encode(_products.map((p) => p.toJson()).toList()));

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Produit modifié avec succès')),
                );
              },
              child: Text('Enregistrer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteProduct(int index) async {
    final product = _filteredProducts[index];
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Supprimer le produit'),
          content: Text('Êtes-vous sûr de vouloir supprimer ${product.name} ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  _products.removeWhere((p) => p.id == product.id);
                  _filteredProducts = _products;
                });

                // Mettre à jour le catalogue partagé
                final catalogData = _products.map((p) => p.toJson()).toList();
                await SharedCatalogService.uploadCatalog(catalogData);

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Produit supprimé avec succès')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_outlined),
          onPressed: () {
            MainInterface.of(context)?.navigateToPage(1);
            if (context.findAncestorStateOfType<_MainInterfaceState>() !=
                null) {
              context
                  .findAncestorStateOfType<_MainInterfaceState>()!
                  .setState(() {
                context
                    .findAncestorStateOfType<_MainInterfaceState>()!
                    ._currentIndex = 1;
              });
            }
          },
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                color: theme.colorScheme.onPrimaryContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Catalogue',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 2,
        actions: [
          // Badge panier moderne
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton.filledTonal(
              icon: Stack(
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 24),
                  if (globalCart.isNotEmpty)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 1.5,
                          ),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '${globalCart.length}',
                          style: TextStyle(
                            color: theme.colorScheme.onError,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => CommandPage()),
                );
              },
              tooltip: 'Voir le panier',
            ),
          ),
          // Bouton actualiser moderne
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton.outlined(
              icon: const Icon(Icons.refresh_outlined),
              onPressed: _isLoading ? null : _refreshCatalog,
              tooltip: 'Actualiser le catalogue',
            ),
          ),
          // Menu moderne
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_outlined),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'upload',
                  child: Row(
                    children: [
                      Icon(Icons.upload_file_outlined,
                          color: theme.colorScheme.primary, size: 20),
                      const SizedBox(width: 12),
                      const Text('Charger catalogue'),
                    ],
                  ),
                ),
                if (_products.isNotEmpty)
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                            _isEditMode
                                ? Icons.done_outlined
                                : Icons.edit_outlined,
                            color: theme.colorScheme.primary,
                            size: 20),
                        const SizedBox(width: 12),
                        Text(_isEditMode ? 'Terminer' : 'Modifier'),
                      ],
                    ),
                  ),
              ],
              onSelected: (value) {
                if (value == 'upload') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => CreatorCataloguePage()),
                  );
                } else if (value == 'edit') {
                  _showSecurityDialog();
                }
              },
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_products.isNotEmpty) ...[
              // Barre de recherche moderne
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Rechercher des produits',
                    hintText: 'Tapez pour rechercher...',
                    prefixIcon: Icon(
                      Icons.search_outlined,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_outlined),
                            onPressed: () {
                              _searchController.clear();
                              _filterProducts('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor:
                        theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  ),
                  onChanged: _filterProducts,
                ),
              ),
              // Sélecteur de catalogue moderne
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _availableCatalogs.map((catalog) {
                      final isSelected = _selectedCatalog == catalog;
                      final count = catalog == 'TOUS'
                          ? _products.length
                          : _catalogCounts[catalog] ?? 0;

                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            '$catalog ($count)',
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (_) => _selectCatalog(catalog),
                          backgroundColor: theme.colorScheme.surfaceVariant,
                          selectedColor: theme.colorScheme.primary,
                          checkmarkColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              // Compteur de produits
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_filteredProducts.length} produit${_filteredProducts.length > 1 ? 's' : ''} trouvé${_filteredProducts.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            _isLoading
                ? Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Chargement du catalogue...',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Expanded(
                    child: _products.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(
                                    Icons.inventory_2_outlined,
                                    size: 64,
                                    color: theme.colorScheme.onErrorContainer,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Aucun catalogue chargé',
                                  style:
                                      theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Le créateur doit charger un catalogue',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                FilledButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CreatorCataloguePage(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.upload_file_outlined),
                                  label: const Text('Charger un catalogue'),
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed: _refreshCatalog,
                                  icon: const Icon(Icons.refresh_outlined),
                                  label: const Text('Actualiser'),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 6,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 0.8,
                            ),
                            itemCount: _filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = _filteredProducts[index];
                              return GestureDetector(
                                onTap: () {
                                  if (_isEditMode) {
                                    _deleteProduct(index);
                                  } else {
                                    _showAddToCartDialog(context, product);
                                  }
                                },
                                onLongPress: () {
                                  setState(() {
                                    _isEditMode = true;
                                  });
                                },
                                child: Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Stack(
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Expanded(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.vertical(
                                                        top: Radius.circular(
                                                            12)),
                                                color: Colors.blue.shade50,
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.vertical(
                                                        top: Radius.circular(
                                                            12)),
                                                child: product.imageBytes !=
                                                        null
                                                    ? Image.memory(
                                                        product.imageBytes!,
                                                        fit: BoxFit.cover,
                                                        width: double.infinity,
                                                        height: double.infinity,
                                                      )
                                                    : product.imageUrl != null
                                                        ? Image.network(
                                                            product.imageUrl!,
                                                            fit: BoxFit.cover,
                                                            width:
                                                                double.infinity,
                                                            height:
                                                                double.infinity,
                                                            loadingBuilder:
                                                                (context, child,
                                                                    loadingProgress) {
                                                              if (loadingProgress ==
                                                                  null)
                                                                return child;
                                                              return Center(
                                                                child:
                                                                    CircularProgressIndicator(
                                                                  value: loadingProgress
                                                                              .expectedTotalBytes !=
                                                                          null
                                                                      ? loadingProgress
                                                                              .cumulativeBytesLoaded /
                                                                          loadingProgress
                                                                              .expectedTotalBytes!
                                                                      : null,
                                                                ),
                                                              );
                                                            },
                                                            errorBuilder:
                                                                (context, error,
                                                                    stackTrace) {
                                                              return Center(
                                                                child: Column(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    Icon(
                                                                      Icons
                                                                          .image_not_supported_outlined,
                                                                      size: 32,
                                                                      color: Colors
                                                                          .grey
                                                                          .shade400,
                                                                    ),
                                                                    const SizedBox(
                                                                        height:
                                                                            4),
                                                                    Text(
                                                                      'Image indisponible',
                                                                      style:
                                                                          TextStyle(
                                                                        fontSize:
                                                                            10,
                                                                        color: Colors
                                                                            .grey
                                                                            .shade600,
                                                                      ),
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                          )
                                                        : Center(
                                                            child: Column(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                Icon(
                                                                  Icons
                                                                      .inventory_2_outlined,
                                                                  size: 40,
                                                                  color: Colors
                                                                      .blue
                                                                      .shade300,
                                                                ),
                                                                const SizedBox(
                                                                    height: 4),
                                                                Text(
                                                                  'Produit',
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        10,
                                                                    color: Colors
                                                                        .blue
                                                                        .shade600,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  product.name,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  product.description,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[700],
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  'À partir de ${formatPrice(product.price)}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Badge du catalogue en haut à gauche
                                      if (product.catalog != null)
                                        Positioned(
                                          top: 8,
                                          left: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _getCatalogColor(
                                                  product.catalog!),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.2),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              product.catalog!,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      if (_isEditMode)
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              CircleAvatar(
                                                backgroundColor: Colors.blue,
                                                radius: 14,
                                                child: IconButton(
                                                  padding: EdgeInsets.zero,
                                                  icon: Icon(Icons.edit,
                                                      size: 16,
                                                      color: Colors.white),
                                                  onPressed: () {
                                                    _editProduct(index);
                                                  },
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              CircleAvatar(
                                                backgroundColor: Colors.red,
                                                radius: 14,
                                                child: IconButton(
                                                  padding: EdgeInsets.zero,
                                                  icon: Icon(Icons.delete,
                                                      size: 16,
                                                      color: Colors.white),
                                                  onPressed: () =>
                                                      _deleteProduct(index),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ],
        ),
      ),
    );
  }

  void _showAddToCartDialog(BuildContext context, Product product) {
    String selectedSize = product.sizes.isNotEmpty ? product.sizes[0] : '';
    int quantity = 1;
    double selectedPrice =
        product.prices.isNotEmpty ? product.prices[0] : product.price;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Ajouter au panier'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(product.name,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  if (product.sizes.length > 1)
                    DropdownButtonFormField<String>(
                      value: selectedSize,
                      items: product.sizes.map((String size) {
                        return DropdownMenuItem<String>(
                          value: size,
                          child: Text(size),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedSize = newValue!;
                          final index = product.sizes.indexOf(selectedSize);
                          if (index >= 0 && index < product.prices.length) {
                            selectedPrice = product.prices[index];
                          }
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Taille',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Quantité:'),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove, color: Colors.blue),
                            onPressed: () {
                              if (quantity > 1) {
                                setState(() {
                                  quantity--;
                                });
                              }
                            },
                          ),
                          Text('$quantity'),
                          IconButton(
                            icon: Icon(Icons.add, color: Colors.blue),
                            onPressed: () {
                              setState(() {
                                quantity++;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text('Prix: ${formatPrice(selectedPrice)}',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Text('Total: ${formatPrice(selectedPrice * quantity)}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Ajouter au panier global
                    globalCart.add(CartItem(
                      product: product,
                      quantity: quantity,
                      selectedSize: selectedSize,
                      selectedPrice: selectedPrice,
                    ));

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product.name} ajouté au panier'),
                        backgroundColor: Colors.green,
                        action: SnackBarAction(
                          label: 'Voir le panier',
                          textColor: Colors.white,
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                  builder: (context) => CommandPage()),
                            );
                          },
                        ),
                      ),
                    );
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: Text('Ajouter', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class CreatorCataloguePage extends StatefulWidget {
  @override
  _CreatorCataloguePageState createState() => _CreatorCataloguePageState();
}

class _CreatorCataloguePageState extends State<CreatorCataloguePage> {
  final TextEditingController _securityCodeController = TextEditingController();
  bool _isLoading = false;
  String? _selectedZipFileName;
  Uint8List? _selectedZipBytes;

  Future<void> _selectZipFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedZipFileName = result.files.first.name;
          _selectedZipBytes = result.files.first.bytes;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erreur lors de la sélection du fichier ZIP: $e')),
      );
    }
  }

  Future<void> _loadCatalogueFromZipBytes(Uint8List bytes) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final Archive archive = ZipDecoder().decodeBytes(bytes);

      String? jsonContent;
      final Map<String, Uint8List> imageBytesMap = {};

      for (final file in archive.files) {
        final String filename = file.name.replaceAll('\\', '/');
        final ext = path.extension(filename).toLowerCase();
        if (ext == '.json' && jsonContent == null) {
          jsonContent = String.fromCharCodes(file.content);
        } else if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext)) {
          imageBytesMap[path.basename(filename)] =
              Uint8List.fromList(file.content);
        }
      }

      if (jsonContent == null) {
        throw Exception('Aucun fichier JSON trouvé dans le ZIP');
      }

      await _parseAndSaveCatalogueFromJsonText(jsonContent, imageBytesMap);
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Catalogue chargé avec succès depuis ZIP'),
            backgroundColor: Colors.green),
      );

      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erreur lors du chargement du catalogue: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _parseAndSaveCatalogueFromJsonText(
      String jsonContent, Map<String, Uint8List> imageBytesMap) async {
    dynamic decoded = json.decode(jsonContent);
    List<dynamic> productsList = [];

    if (decoded is Map && decoded.containsKey('products')) {
      productsList = decoded['products'];
    } else if (decoded is List) {
      productsList = decoded;
    } else {
      throw Exception('Format JSON catalogue non reconnu');
    }

    List<Product> loadedProducts = [];

    for (final data in productsList) {
      try {
        String? imagePathField;
        if (data is Map && data.containsKey('image_path')) {
          imagePathField = data['image_path']?.toString();
        }

        Uint8List? imageBytes;
        if (imagePathField != null && imagePathField.isNotEmpty) {
          final basename = path.basename(imagePathField);
          if (imageBytesMap.containsKey(basename)) {
            imageBytes = imageBytesMap[basename];
          }
          if (imageBytes == null && imageBytesMap.containsKey(imagePathField)) {
            imageBytes = imageBytesMap[imagePathField];
          }
          if (imageBytes == null) {
            final lowerTarget = basename.toLowerCase();
            for (final key in imageBytesMap.keys) {
              if (key.toLowerCase().contains(lowerTarget) ||
                  lowerTarget.contains(key.toLowerCase())) {
                imageBytes = imageBytesMap[key];
                break;
              }
            }
          }
        }

        final id = (data['id'] ??
                data['name'] ??
                'unknown_${DateTime.now().millisecondsSinceEpoch}')
            .toString();
        final name = (data['name'] ?? 'Sans nom').toString();
        final description = (data['description'] ?? '').toString();

        List<String> sizes = [];
        if (data['sizes'] != null && data['sizes'] is List) {
          sizes = List<String>.from(
              (data['sizes'] as List).map((s) => s.toString()));
        }

        List<double> prices = [];
        if (data['prices'] != null && data['prices'] is List) {
          prices = (data['prices'] as List).map((p) {
            if (p == null) return 0.0;
            if (p is int) return p.toDouble();
            if (p is double) return p;
            if (p is String)
              return double.tryParse(p.replaceAll(',', '.')) ?? 0.0;
            return 0.0;
          }).toList();
        }

        double mainPrice = 0.0;
        if (prices.isNotEmpty) mainPrice = prices[0];
        if (mainPrice == 0.0 && data['price'] != null) {
          final pval = data['price'];
          if (pval is num)
            mainPrice = pval.toDouble();
          else if (pval is String)
            mainPrice = double.tryParse(pval.replaceAll(',', '.')) ?? 0.0;
        }

        loadedProducts.add(Product(
          id: id,
          name: name,
          description: description,
          price: mainPrice,
          sizes: sizes,
          prices: prices,
          imageBytes: imageBytes,
        ));
      } catch (e) {
        print('Erreur parsing produit: $e');
      }
    }

    // Sauvegarder le catalogue dans le stockage web
    final catalogueData =
        json.encode(loadedProducts.map((p) => p.toJson()).toList());
    if (kIsWeb) {
      html.window.localStorage['shared_catalogue_data'] = catalogueData;
    }

    // Sauvegarder aussi localement pour les applications natives
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_catalogue_data', catalogueData);
  }

  Future<void> _loadCatalogueFromZip() async {
    if (_selectedZipBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez sélectionner un fichier ZIP')),
      );
      return;
    }
    await _loadCatalogueFromZipBytes(_selectedZipBytes!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Catalogue Créateur'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_upload,
              size: 64,
              color: Colors.blue[700],
            ),
            SizedBox(height: 24),
            Text(
              'Charger un nouveau catalogue',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Sélectionnez un fichier ZIP contenant les images et les informations du catalogue',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            TextField(
              controller: _securityCodeController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Code de sécurité',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.security, color: Colors.blue),
              ),
            ),
            SizedBox(height: 20),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _selectZipFile,
                      icon: Icon(Icons.folder_open),
                      label: Text('Sélectionner un fichier ZIP'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        textStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_selectedZipFileName != null) ...[
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Fichier sélectionné : $_selectedZipFileName',
                                style: TextStyle(color: Colors.green[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            Text(
              _selectedZipFileName != null
                  ? 'Fichier sélectionné: $_selectedZipFileName'
                  : 'Aucun fichier sélectionné',
              textAlign: TextAlign.center,
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () {
                      if (_securityCodeController.text == "said@1984") {
                        if (_selectedZipBytes != null) {
                          _loadCatalogueFromZip();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Veuillez sélectionner un ZIP avant de charger')),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Code de sécurité incorrect')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    ),
                    child: Text('Charger Catalogue'),
                  ),
          ],
        ),
      ),
    );
  }
}

class CartItem {
  final Product product;
  int quantity;
  String selectedSize;
  double selectedPrice;

  CartItem({
    required this.product,
    required this.quantity,
    required this.selectedSize,
    required this.selectedPrice,
  });
}

class CommandPage extends StatefulWidget {
  @override
  _CommandPageState createState() => _CommandPageState();
}

class _CommandPageState extends State<CommandPage> {
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String _commercialName = 'Commercial 1';
  int _commercialCounter = 1;

  @override
  void initState() {
    super.initState();
    _loadCommercialCounter();
  }

  Future<void> _loadCommercialCounter() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _commercialCounter = prefs.getInt('commercial_counter') ?? 1;
    });
  }

  Future<void> _saveCommercialCounter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('commercial_counter', _commercialCounter);
  }

  Future<void> _sendWhatsAppMessage(String message,
      {String? pdfFilePath}) async {
    final phoneNumber = "+212672506116";

    try {
      if (kIsWeb) {
        // En mode web, ouvrir WhatsApp Web avec le message détaillé
        final whatsappUrl =
            "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}";
        html.window.open(whatsappUrl, '_blank');

        // Afficher une confirmation à l'utilisateur
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Commande prête'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 50),
                  SizedBox(height: 16),
                  Text('Le PDF a été téléchargé et la commande est prête !'),
                  SizedBox(height: 8),
                  Text(
                    'WhatsApp Web s\'ouvrira dans un nouvel onglet avec votre commande.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      } else if (pdfFilePath != null) {
        // Sur mobile/desktop, utiliser Share.shareFiles
        await Share.shareFiles(
          [pdfFilePath],
          text: message,
        );
      } else {
        // Fallback pour le partage standard
        final uri = Uri.parse(
            "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}");
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          throw 'Could not launch WhatsApp';
        }
      }
    } catch (e) {
      print('Error sharing: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du partage: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  double get _total {
    return globalCart.fold(
        0, (sum, item) => sum + (item.selectedPrice * item.quantity));
  }

  void _editItem(int index) {
    final item = globalCart[index];
    String selectedSize = item.selectedSize;
    int quantity = item.quantity;
    double selectedPrice = item.selectedPrice;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Modifier l\'article'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item.product.name,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  if (item.product.sizes.length > 1)
                    DropdownButtonFormField<String>(
                      value: selectedSize,
                      items: item.product.sizes.map((String size) {
                        return DropdownMenuItem<String>(
                          value: size,
                          child: Text(size),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedSize = newValue!;
                          final index =
                              item.product.sizes.indexOf(selectedSize);
                          if (index >= 0 &&
                              index < item.product.prices.length) {
                            selectedPrice = item.product.prices[index];
                          }
                        });
                      },
                      decoration: InputDecoration(labelText: 'Taille'),
                    ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Quantité:'),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove, color: Colors.blue),
                            onPressed: () {
                              if (quantity > 1) {
                                setState(() {
                                  quantity--;
                                });
                              }
                            },
                          ),
                          Text('$quantity'),
                          IconButton(
                            icon: Icon(Icons.add, color: Colors.blue),
                            onPressed: () {
                              setState(() {
                                quantity++;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text('Prix: ${formatPrice(selectedPrice)}',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Text('Total: ${formatPrice(selectedPrice * quantity)}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      globalCart[index] = CartItem(
                        product: item.product,
                        quantity: quantity,
                        selectedSize: selectedSize,
                        selectedPrice: selectedPrice,
                      );
                    });
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: Text('Enregistrer',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _generatePDF() async {
    if (globalCart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Le panier est vide')),
      );
      return;
    }

    if (_clientNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez saisir le nom du client')),
      );
      return;
    }

    final pdf = pw.Document();
    final now = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text("BON DE COMMANDE",
                textAlign: pw.TextAlign.center,
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("INFORMATIONS CLIENT",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 10),
                    pw.Text("Nom: ${_clientNameController.text}"),
                    pw.Text("Adresse: ${_addressController.text}"),
                    pw.Text("Téléphone: ${_phoneController.text}"),
                    pw.Text("Email: ${_emailController.text}"),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text("INFORMATIONS COMMANDE",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 10),
                    pw.Text(
                        "Date: ${DateFormat('dd/MM/yyyy à HH:mm').format(now)}"),
                    pw.Text("N° Commande: $_commercialCounter"),
                    pw.Text("Commercial: $_commercialName"),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 30),
          pw.TableHelper.fromTextArray(
            context: context,
            border: pw.TableBorder.all(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
            headers: [
              'Produit',
              'Description',
              'Taille',
              'Prix U.',
              'Qté',
              'Total'
            ],
            data: globalCart
                .map((item) => [
                      item.product.name,
                      item.product.description,
                      item.selectedSize,
                      formatPrice(item.selectedPrice),
                      '${item.quantity}',
                      formatPrice(item.selectedPrice * item.quantity)
                    ])
                .toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                padding: pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Text(
                  "TOTAL: ${formatPrice(_total)}",
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 40),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              pw.Column(
                children: [
                  pw.Text("Signature client",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 40),
                  pw.Text("_________________________"),
                ],
              ),
              pw.Column(
                children: [
                  pw.Text("Signature commercial",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 40),
                  pw.Text("_________________________"),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    try {
      final pdfBytes = await pdf.save();

      if (kIsWeb) {
        // Sauvegarder le PDF dans le stockage local du navigateur
        final base64Pdf = base64Encode(pdfBytes);
        html.window.localStorage['lastPdf'] = base64Pdf;

        // Créer le blob pour le téléchargement
        final blob = html.Blob([pdfBytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);

        // Créer un message détaillé avec les informations de la commande
        final detailsCommande = globalCart
            .map((item) =>
                "${item.product.name} (${item.selectedSize}) - ${item.quantity}x - ${formatPrice(item.selectedPrice * item.quantity)}")
            .join("\n");

        final message = """Bonjour,
Nouvelle commande n°$_commercialCounter

Client: ${_clientNameController.text}
${_addressController.text.isNotEmpty ? "Adresse: ${_addressController.text}\n" : ""}
${_phoneController.text.isNotEmpty ? "Tél: ${_phoneController.text}\n" : ""}

Détails de la commande:
$detailsCommande

Total: ${formatPrice(_total)}

Lien PDF: $url""";
        "Montant total: ${formatPrice(_total)}";
        await _sendWhatsAppMessage(message);
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final commandDir = Directory(path.join(directory.path, 'Commandes'));
        if (!await commandDir.exists()) {
          await commandDir.create(recursive: true);
        }

        final pdfFile = File(
            path.join(commandDir.path, 'commande_${_commercialCounter}.pdf'));
        await pdfFile.writeAsBytes(pdfBytes);

        // Afficher l'aperçu d'impression
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfBytes,
        );

        setState(() {
          _commercialCounter++;
        });
        await _saveCommercialCounter();

        final message = "Bonjour, voici ma commande n°$_commercialCounter.\n"
            "Montant total: ${formatPrice(_total)}\n"
            "Veuillez trouver le bon de commande en pièce jointe.";

        // Partager le PDF et le message via WhatsApp
        await _sendWhatsAppMessage(message, pdfFilePath: pdfFile.path);
      }

      // Vider le panier après envoi
      globalCart.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF généré et partagé'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la génération du PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearCart() {
    setState(() {
      globalCart.clear();
    });
  }

  void _removeItem(int index) {
    setState(() {
      globalCart.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Commande'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Text(
                      'NOUVELLE COMMANDE',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              'Informations Client',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 16),
                            TextField(
                              controller: _clientNameController,
                              decoration: InputDecoration(
                                labelText: 'Nom du client *',
                                border: OutlineInputBorder(),
                                prefixIcon:
                                    Icon(Icons.person, color: Colors.blue),
                              ),
                            ),
                            SizedBox(height: 10),
                            TextField(
                              controller: _addressController,
                              decoration: InputDecoration(
                                labelText: 'Adresse',
                                border: OutlineInputBorder(),
                                prefixIcon:
                                    Icon(Icons.location_on, color: Colors.blue),
                              ),
                              maxLines: 2,
                            ),
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _phoneController,
                                    decoration: InputDecoration(
                                      labelText: 'Téléphone',
                                      border: OutlineInputBorder(),
                                      prefixIcon:
                                          Icon(Icons.phone, color: Colors.blue),
                                    ),
                                    keyboardType: TextInputType.phone,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _emailController,
                                    decoration: InputDecoration(
                                      labelText: 'Email',
                                      border: OutlineInputBorder(),
                                      prefixIcon:
                                          Icon(Icons.email, color: Colors.blue),
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              value: _commercialName,
                              items: [
                                'Commercial 1',
                                'Commercial 2',
                                'Commercial 3',
                                'Commercial 4'
                              ].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  _commercialName = newValue!;
                                });
                              },
                              decoration: InputDecoration(
                                labelText: 'Commercial',
                                border: OutlineInputBorder(),
                                prefixIcon:
                                    Icon(Icons.person, color: Colors.blue),
                              ),
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Articles commandés',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            ...globalCart.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              return Card(
                                margin: EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  leading: item.product.imageBytes != null
                                      ? Container(
                                          width: 50,
                                          height: 50,
                                          child: Image.memory(
                                            item.product.imageBytes!,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Icon(Icons.image_not_supported),
                                  title: Text(
                                    item.product.name,
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Taille: ${item.selectedSize}'),
                                      Text(
                                          'Prix: ${formatPrice(item.selectedPrice)}'),
                                      Text('Quantité: ${item.quantity}'),
                                      Text(
                                        'Total: ${formatPrice(item.selectedPrice * item.quantity)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit,
                                            color: Colors.blue[700]),
                                        onPressed: () => _editItem(index),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: Text(
                                                    'Supprimer l\'article'),
                                                content: Text(
                                                    'Voulez-vous vraiment supprimer cet article ?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(context)
                                                            .pop(),
                                                    child: Text('Annuler'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      _removeItem(index);
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    style: TextButton.styleFrom(
                                                      foregroundColor:
                                                          Colors.red,
                                                    ),
                                                    child: Text('Supprimer'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  isThreeLine: true,
                                ),
                              );
                            }).toList(),
                            if (globalCart.isEmpty)
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Text(
                                  'Aucun article dans la commande',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            if (globalCart.isNotEmpty) ...[
                              Divider(height: 32),
                              Text(
                                'Total de la commande: ${formatPrice(_total)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Articles',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        if (globalCart.isNotEmpty)
                          TextButton(
                            onPressed: _clearCart,
                            child: Text('Vider le panier',
                                style: TextStyle(color: Colors.red)),
                          ),
                      ],
                    ),
                    SizedBox(height: 10),
                    globalCart.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                Icon(Icons.shopping_cart_outlined,
                                    size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'Votre panier est vide',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.grey),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Ajoutez des articles depuis le catalogue',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              ...globalCart.asMap().entries.map((entry) {
                                final index = entry.key;
                                final item = entry.value;
                                return Dismissible(
                                  key: Key('${item.product.id}-$index'),
                                  background: Container(color: Colors.red),
                                  onDismissed: (direction) {
                                    _removeItem(index);
                                  },
                                  child: Card(
                                    margin: EdgeInsets.symmetric(vertical: 4),
                                    child: ListTile(
                                      leading: item.product.imageBytes != null
                                          ? CircleAvatar(
                                              backgroundImage: MemoryImage(
                                                item.product.imageBytes!,
                                              ),
                                              radius: 20,
                                            )
                                          : CircleAvatar(
                                              backgroundColor:
                                                  Colors.blue.shade100,
                                              child: Icon(Icons.shopping_bag,
                                                  color: Colors.blue),
                                            ),
                                      title: Text(item.product.name),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Taille: ${item.selectedSize}'),
                                          Text(
                                              'Prix: ${formatPrice(item.selectedPrice)}'),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.edit,
                                                size: 20, color: Colors.blue),
                                            onPressed: () => _editItem(index),
                                          ),
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text('${item.quantity}'),
                                              Text(
                                                formatPrice(item.selectedPrice *
                                                    item.quantity),
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                              Divider(),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total:',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      formatPrice(_total),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (context) => CataloguePage()),
                      );
                    },
                    icon: Icon(Icons.add),
                    label: Text('Ajouter articles'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _generatePDF,
                    icon: Icon(Icons.picture_as_pdf),
                    label: Text('Générer PDF'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text('Paramètres'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paramètres',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: Icon(Icons.person, color: Colors.blue),
                title: Text('Profil'),
                subtitle: Text('Gérer vos informations personnelles'),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () {},
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.notifications, color: Colors.orange),
                title: Text('Notifications'),
                subtitle: Text('Configurer les préférences de notification'),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () {},
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.security, color: Colors.green),
                title: Text('Confidentialité'),
                subtitle: Text('Gérer vos paramètres de confidentialité'),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () {},
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.help, color: Colors.purple),
                title: Text('Aide & Support'),
                subtitle: Text('FAQ et support technique'),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () {},
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.info, color: Colors.blueGrey),
                title: Text('À propos'),
                subtitle: Text('Informations sur l\'application'),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'PDF Commande',
                    applicationVersion: '1.0.0',
                    applicationIcon:
                        Icon(Icons.shopping_cart, color: Colors.blue),
                  );
                },
              ),
            ),
            Spacer(),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.logout),
                label: Text('Déconnexion'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
