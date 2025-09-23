import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String AUTH_TOKEN_KEY = 'auth_token';

  // Connexion avec email et mot de passe
  static Future<UserCredential?> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Sauvegarder le token d'authentification
      final token = await userCredential.user?.getIdToken();
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AUTH_TOKEN_KEY, token);
      }

      return userCredential;
    } catch (e) {
      print('Erreur de connexion: $e');
      return null;
    }
  }

  // Déconnexion
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AUTH_TOKEN_KEY);
    } catch (e) {
      print('Erreur de déconnexion: $e');
    }
  }

  // Vérifier si l'utilisateur est connecté
  static bool isSignedIn() {
    return _auth.currentUser != null;
  }

  // Obtenir le token d'authentification
  static Future<String?> getAuthToken() async {
    if (!isSignedIn()) return null;
    try {
      return await _auth.currentUser?.getIdToken();
    } catch (e) {
      print('Erreur lors de la récupération du token: $e');
      return null;
    }
  }

  // Vérifier si le token est stocké localement
  static Future<bool> hasStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(AUTH_TOKEN_KEY);
  }
}
