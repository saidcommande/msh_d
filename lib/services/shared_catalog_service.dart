import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/html.dart' as html;

class SharedCatalogService {
  static const String CATALOG_URL =
      'https://raw.githubusercontent.com/saidcommande/msh_d/main/docs/data/catalog.json';
  static const String SHARED_CATALOG_KEY = 'shared_catalog';
  static const String LAST_SYNC_KEY = 'last_catalog_sync';

  // Télécharger le catalogue partagé (pour l'instant, seulement local)
  static Future<bool> uploadCatalog(List<dynamic> products) async {
    try {
      // Optimiser les produits pour le stockage - enlever les imageBytes volumineux
      final optimizedProducts = products.map((product) {
        final Map<String, dynamic> optimizedProduct = Map.from(product);
        // Enlever imageBytes pour économiser l'espace de stockage
        optimizedProduct.remove('imageBytes');
        return optimizedProduct;
      }).toList();

      final catalogData = {
        'products': optimizedProducts,
        'lastUpdated': DateTime.now().toIso8601String()
      };

      // Sauvegarder dans le stockage local
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(SHARED_CATALOG_KEY, json.encode(catalogData));
      await prefs.setString(LAST_SYNC_KEY, DateTime.now().toIso8601String());

      // Si nous sommes sur le web, sauvegarder dans localStorage (optimisé)
      if (kIsWeb) {
        try {
          html.window.localStorage[SHARED_CATALOG_KEY] = json.encode(catalogData);
          html.window.localStorage[LAST_SYNC_KEY] =
              DateTime.now().toIso8601String();
        } catch (e) {
          print('Erreur localStorage (quota dépassé): $e');
          // En cas de quota dépassé, nettoyer et réessayer
          _clearOldCacheData();
          try {
            html.window.localStorage[SHARED_CATALOG_KEY] = json.encode(catalogData);
          } catch (e2) {
            print('Échec final du stockage localStorage: $e2');
            // Continuer sans localStorage si impossible
          }
        }
      }

      // Note: Pour une vraie synchronisation, il faudrait une API backend
      // ou utiliser Firebase/autre service cloud
      print('Catalogue sauvegardé localement avec ${products.length} produits');
      return true;
    } catch (e) {
      print('Erreur lors de la sauvegarde du catalogue: $e');
      return false;
    }
  }

  // Récupérer le catalogue partagé avec meilleure gestion d'erreurs
  static Future<List<dynamic>> getCatalog() async {
    try {
      // D'abord essayer de charger depuis l'URL distante
      print('Tentative de chargement du catalogue depuis: $CATALOG_URL');

      final response = await http.get(
        Uri.parse(CATALOG_URL),
        headers: {
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final products = data['products'] ?? [];
        print(
            'Catalogue chargé depuis le serveur: ${products.length} produits');

        // Sauvegarder en cache local
        _cacheData(response.body);

        return products;
      } else {
        print('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur réseau lors du chargement du catalogue: $e');
    }

    // Si échec, essayer le cache local
    final cachedProducts = await _loadFromCache();
    if (cachedProducts.isNotEmpty) {
      return cachedProducts;
    }

    // En dernier recours, retourner un catalogue minimal de démonstration
    print('Retour du catalogue de secours avec 5 produits de démonstration');
    return _getEmergencyFallbackCatalog();
  }

  // Catalogue de secours en cas d'échec total
  static List<dynamic> _getEmergencyFallbackCatalog() {
    return [
      {
        "id": "akasya-max_demo_1",
        "name": "BROSSE AKRO BLEU",
        "description": "Brosse professionnelle de haute qualité. Produit professionnel de la gamme AKASYA-MAX - Qualité premium pour usage professionnel et domestique.",
        "catalog": "AKASYA-MAX",
        "price": 5.0,
        "sizes": ["9", "12", "15", "18"],
        "prices": [5.0, 6.0, 7.0, 8.0],
        "imageBytes": null,
        "imageUrl": "https://raw.githubusercontent.com/saidcommande/msh_d/main/docs/assets/assets/images/akasya-max/prod_1752440345.png"
      },
      {
        "id": "akasya-max_demo_2",
        "name": "ROULEAU FACHADAS PRO SERIES",
        "description": "Produit professionnel de la gamme AKASYA-MAX - Qualité premium pour usage professionnel et domestique.",
        "catalog": "AKASYA-MAX",
        "price": 35.0,
        "sizes": ["18", "22", "23"],
        "prices": [35.0, 45.0, 60.0],
        "imageBytes": null,
        "imageUrl": "https://raw.githubusercontent.com/saidcommande/msh_d/main/docs/assets/assets/images/akasya-max/prod_1752441056.png"
      },
      {
        "id": "akasya-max_demo_3",
        "name": "PERCHE TELESCOPIQUE EN ALUMINIUM",
        "description": "Produit professionnel de la gamme AKASYA-MAX - Qualité premium pour usage professionnel et domestique.",
        "catalog": "AKASYA-MAX",
        "price": 75.0,
        "sizes": ["2M", "3M", "4M"],
        "prices": [75.0, 95.0, 120.0],
        "imageBytes": null,
        "imageUrl": "https://raw.githubusercontent.com/saidcommande/msh_d/main/docs/assets/assets/images/akasya-max/prod_1752442632.png"
      },
      {
        "id": "akasya-max_demo_4",
        "name": "SILICONE GUN",
        "description": "Produit d'étanchéité et de fixation professionnel. Produit professionnel de la gamme AKASYA-MAX - Qualité premium pour usage professionnel et domestique.",
        "catalog": "AKASYA-MAX",
        "price": 64.8,
        "sizes": ["Taille unique"],
        "prices": [64.8],
        "imageBytes": null,
        "imageUrl": "https://raw.githubusercontent.com/saidcommande/msh_d/main/docs/assets/assets/images/akasya-max/e7b3a6fc-8638-40c4-bf98-671500d01d466139302911328288278.jpg"
      },
      {
        "id": "akasya-max_demo_5",
        "name": "CATALOGUE COMPLET EN CHARGEMENT",
        "description": "Le catalogue complet AKASYA-MAX avec 113 produits se charge en arrière-plan. Veuillez utiliser le bouton 'Actualiser' pour charger la version complète.",
        "catalog": "AKASYA-MAX",
        "price": 0.0,
        "sizes": ["Info"],
        "prices": [0.0],
        "imageBytes": null,
        "imageUrl": "https://raw.githubusercontent.com/saidcommande/msh_d/main/docs/assets/assets/images/akasya-max/prod_1752440345.png"
      }
    ];
  }

  // Charger depuis le cache local
  static Future<List<dynamic>> _loadFromCache() async {
    try {
      String? cachedData;

      // Essayer localStorage en premier sur le web
      if (kIsWeb) {
        cachedData = html.window.localStorage[SHARED_CATALOG_KEY];
      }

      // Sinon essayer SharedPreferences
      if (cachedData == null) {
        final prefs = await SharedPreferences.getInstance();
        cachedData = prefs.getString(SHARED_CATALOG_KEY);
      }

      if (cachedData != null) {
        final data = json.decode(cachedData);
        final products = data['products'] ?? [];
        print(
            'Catalogue chargé depuis le cache local: ${products.length} produits');
        return products;
      }

      print('Aucun catalogue trouvé en cache local');
      return [];
    } catch (e) {
      print('Erreur lors du chargement du cache: $e');
      return [];
    }
  }

  // Sauvegarder en cache
  static Future<void> _cacheData(String jsonData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(SHARED_CATALOG_KEY, jsonData);
      await prefs.setString(LAST_SYNC_KEY, DateTime.now().toIso8601String());

      if (kIsWeb) {
        try {
          html.window.localStorage[SHARED_CATALOG_KEY] = jsonData;
          html.window.localStorage[LAST_SYNC_KEY] =
              DateTime.now().toIso8601String();
        } catch (e) {
          print('Erreur localStorage lors du cache: $e');
          // En cas d'erreur de quota, nettoyer et réessayer
          _clearOldCacheData();
          try {
            html.window.localStorage[SHARED_CATALOG_KEY] = jsonData;
          } catch (e2) {
            print('Échec final du cache localStorage: $e2');
            // Continuer sans localStorage si impossible
          }
        }
      }
    } catch (e) {
      print('Erreur lors de la mise en cache: $e');
    }
  }

  // Vérifier si un catalogue est disponible
  static Future<bool> isCatalogAvailable() async {
    try {
      final catalog = await getCatalog();
      return catalog.isNotEmpty;
    } catch (e) {
      print('Erreur lors de la vérification du catalogue: $e');
      return false;
    }
  }

  // Forcer le rechargement du catalogue depuis le serveur
  static Future<List<dynamic>> forceRefresh() async {
    try {
      print('Rechargement forcé du catalogue...');
      final response = await http.get(
        Uri.parse(CATALOG_URL),
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final products = data['products'] ?? [];
        print('Catalogue rechargé avec succès: ${products.length} produits');

        // Mettre à jour le cache local
        await _cacheData(response.body);

        return products;
      } else {
        print('Échec du rechargement: HTTP ${response.statusCode}');
        return _loadFromCache();
      }
    } catch (e) {
      print('Erreur lors du rechargement forcé: $e');
      return _loadFromCache();
    }
  }

  // Nettoyer les anciennes données de cache pour libérer l'espace
  static void _clearOldCacheData() {
    if (kIsWeb) {
      try {
        // Nettoyer les anciennes clés qui pourraient prendre de l'espace
        final keysToRemove = <String>[];
        for (int i = 0; i < html.window.localStorage.length; i++) {
          final key = html.window.localStorage.keys.elementAt(i);
          if (key.startsWith('user_catalogue_data') || 
              key.startsWith('cached_catalog') ||
              key.startsWith('old_')) {
            keysToRemove.add(key);
          }
        }
        for (String key in keysToRemove) {
          html.window.localStorage.remove(key);
        }
        print('Nettoyage du cache: ${keysToRemove.length} entrées supprimées');
      } catch (e) {
        print('Erreur lors du nettoyage du cache: $e');
      }
    }
  }

  // Obtenir la date de dernière synchronisation
  static Future<DateTime?> getLastSyncDate() async {
    try {
      String? lastSync;

      if (kIsWeb) {
        lastSync = html.window.localStorage[LAST_SYNC_KEY];
      } else {
        final prefs = await SharedPreferences.getInstance();
        lastSync = prefs.getString(LAST_SYNC_KEY);
      }

      if (lastSync != null) {
        return DateTime.parse(lastSync);
      }
    } catch (e) {
      print('Erreur lors de la récupération de la date de sync: $e');
    }
    return null;
  }
}
