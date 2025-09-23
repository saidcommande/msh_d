import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

class SecurityService {
  static const String AUTH_KEY = 'auth_key';
  static const String ADMIN_PASSWORD = 'said@1984'; // Votre mot de passe actuel

  // Vérifier si l'utilisateur est authentifié
  static Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(AUTH_KEY);
  }

  // Authentifier l'utilisateur
  static Future<bool> authenticate(String password) async {
    if (password == ADMIN_PASSWORD) {
      final prefs = await SharedPreferences.getInstance();
      final token = _generateToken(password);
      await prefs.setString(AUTH_KEY, token);
      return true;
    }
    return false;
  }

  // Déconnecter l'utilisateur
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AUTH_KEY);
  }

  // Générer un token simple
  static String _generateToken(String password) {
    final now = DateTime.now();
    final data = password + now.day.toString();
    return sha256.convert(utf8.encode(data)).toString();
  }
}
