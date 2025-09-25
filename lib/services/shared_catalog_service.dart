import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/html.dart' as html;

class SharedCatalogService {
  static const String CATALOG_URL =
      'https://saidcommande.github.io/msh_d/data/catalog.json';
  static const String SHARED_CATALOG_KEY = 'shared_catalog';

  // Télécharger le catalogue partagé
  static Future<bool> uploadCatalog(List<dynamic> products) async {
    try {
      final catalogData = {
        'products': products,
        'lastUpdated': DateTime.now().toIso8601String()
      };

      // Sauvegarder dans le stockage local
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(SHARED_CATALOG_KEY, json.encode(catalogData));

      // Si nous sommes sur le web, sauvegarder dans localStorage
      if (html.window != null) {
        html.window.localStorage[SHARED_CATALOG_KEY] = json.encode(catalogData);
      }

      return true;
    } catch (e) {
      print('Erreur lors du téléchargement du catalogue: $e');
      return false;
    }
  }

  // Récupérer le catalogue partagé
  static Future<List<dynamic>> getCatalog() async {
    try {
      // D'abord essayer de charger depuis l'URL
      final response = await http.get(Uri.parse(CATALOG_URL));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['products'] ?? [];
      }

      // Si échec, essayer le stockage local
      final prefs = await SharedPreferences.getInstance();
      final localData = prefs.getString(SHARED_CATALOG_KEY);
      if (localData != null) {
        final data = json.decode(localData);
        return data['products'] ?? [];
      }

      return [];
    } catch (e) {
      print('Erreur lors de la récupération du catalogue: $e');
      return [];
    }
  }

  // Vérifier si un catalogue est disponible
  static Future<bool> isCatalogAvailable() async {
    try {
      final catalog = await getCatalog();
      return catalog.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
