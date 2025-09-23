import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/html.dart' as html;
import 'security_service.dart';

class CatalogService {
  static const String catalogUrl =
      'https://saidcommande.github.io/msh_d/data/catalog.json';
  static const String cacheKey = 'cached_catalog';
  static const String localCatalogKey = 'local_catalog';

  static Future<void> saveLocalCatalog(List<dynamic> products) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(localCatalogKey, json.encode(products));
  }

  static Future<List<dynamic>> getLocalCatalog() async {
    final prefs = await SharedPreferences.getInstance();
    final localData = prefs.getString(localCatalogKey);
    if (localData != null) {
      return json.decode(localData) as List<dynamic>;
    }
    return [];
  }

  static Future<List<dynamic>> fetchCatalog() async {
    try {
      // Essayer de charger depuis le serveur
      // Le catalogue est toujours accessible pour la lecture
      final response = await http.get(Uri.parse(catalogUrl));
      if (response.statusCode == 200) {
        // Cache the data in both SharedPreferences and localStorage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(cacheKey, response.body);

        if (kIsWeb) {
          html.window.localStorage[cacheKey] = response.body;
        }

        return json.decode(response.body) as List<dynamic>;
      }
      // If server request fails, try loading from cache
      return _loadFromCache();
    } catch (e) {
      // In case of error, try loading from cache
      return _loadFromCache();
    }
  }

  static Future<List<dynamic>> _loadFromCache() async {
    try {
      String? cachedData;

      // Try loading from localStorage in web
      if (kIsWeb) {
        cachedData = html.window.localStorage[cacheKey];
      }

      // If not found in localStorage or not web, try SharedPreferences
      if (cachedData == null) {
        final prefs = await SharedPreferences.getInstance();
        cachedData = prefs.getString(cacheKey);
      }

      if (cachedData != null) {
        return json.decode(cachedData) as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> updateCatalog(List<dynamic> products) async {
    // Vérifier l'authentification avant de permettre la mise à jour
    final isAuth = await SecurityService.isAuthenticated();
    if (!isAuth) {
      throw Exception(
          'Authentification requise pour mettre à jour le catalogue');
    }

    try {
      // Sauvegarder localement
      await saveLocalCatalog(products);

      // Mettre à jour le cache
      final jsonData = json.encode(products);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(cacheKey, jsonData);

      if (kIsWeb) {
        html.window.localStorage[cacheKey] = jsonData;
      }

      return true;
    } catch (e) {
      throw Exception(
          'Erreur lors de la mise à jour du catalogue: ${e.toString()}');
    }
  }
}
