import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences.dart';

class CatalogService {
  static const String CATALOG_URL = 'https://saidcommande.github.io/msh_d/data/catalog.json';
  static const String CACHE_KEY = 'cached_catalog';

  // Charger le catalogue depuis le serveur ou le cache
  static Future<List<dynamic>> loadCatalog() async {
    try {
      // Essayer de charger depuis le serveur
      final response = await http.get(Uri.parse(CATALOG_URL));
      if (response.statusCode == 200) {
        final catalog = json.decode(response.body);
        // Mettre en cache
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(CACHE_KEY, response.body);
        return catalog;
      }
    } catch (e) {
      print('Erreur lors du chargement du catalogue: $e');
    }

    // En cas d'échec, charger depuis le cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(CACHE_KEY);
      if (cachedData != null) {
        return json.decode(cachedData);
      }
    } catch (e) {
      print('Erreur lors du chargement du cache: $e');
    }

    // Si tout échoue, retourner une liste vide
    return [];
  }
}