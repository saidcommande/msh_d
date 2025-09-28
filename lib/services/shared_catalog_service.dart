import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/html.dart' as html;

class SharedCatalogService {
  static const String CATALOG_URL =
      'https://saidcommande.github.io/msh_d/docs/data/catalog.json';
  static const String SHARED_CATALOG_KEY = 'shared_catalog';
  static const String LAST_SYNC_KEY = 'last_catalog_sync';

  // Télécharger le catalogue partagé (pour l'instant, seulement local)
  static Future<bool> uploadCatalog(List<dynamic> products) async {
    try {
      final catalogData = {
        'products': products,
        'lastUpdated': DateTime.now().toIso8601String()
      };

      // Sauvegarder dans le stockage local
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(SHARED_CATALOG_KEY, json.encode(catalogData));
      await prefs.setString(LAST_SYNC_KEY, DateTime.now().toIso8601String());

      // Si nous sommes sur le web, sauvegarder dans localStorage
      if (kIsWeb) {
        html.window.localStorage[SHARED_CATALOG_KEY] = json.encode(catalogData);
        html.window.localStorage[LAST_SYNC_KEY] =
            DateTime.now().toIso8601String();
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
    return _loadFromCache();
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
        html.window.localStorage[SHARED_CATALOG_KEY] = jsonData;
        html.window.localStorage[LAST_SYNC_KEY] =
            DateTime.now().toIso8601String();
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
