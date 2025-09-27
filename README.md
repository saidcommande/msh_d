# PDF Commande - Application de Gestion de Catalogues

Une application Flutter web pour la gestion de catalogues de produits et la génération de PDF de commandes.

## 🌐 Application en Direct

**[https://saidcommande.github.io/msh_d/](https://saidcommande.github.io/msh_d/)**

## 🚀 Fonctionnalités

### 📱 Catalogue Partagé
- **Catalogue unifié** : Tous les utilisateurs voient le même catalogue
- **Actualisation automatique** : Synchronisation en temps réel
- **Bouton d'actualisation** : Force le rechargement du catalogue
- **Cache intelligent** : Fonctionne hors ligne avec les données mises en cache

### 🛒 Gestion des Commandes
- **Ajout au panier** : Interface intuitive pour sélectionner produits et quantités
- **Génération PDF** : Création automatique de PDFs de commandes
- **Export WhatsApp** : Partage direct des commandes via WhatsApp
- **Calculs automatiques** : Prix totaux avec conversion MAD

### 🔧 Administration
- **Upload de catalogues** : Import de fichiers ZIP avec produits et images
- **Modification sécurisée** : Code de sécurité pour les modifications
- **Gestion des produits** : Ajout, modification et suppression
- **Multi-format** : Support images JPEG, PNG, WEBP

### 🎨 Interface Utilisateur
- **Design responsive** : Optimisé pour mobile et desktop
- **Navigation intuitive** : Interface Material Design
- **Feedback utilisateur** : Messages d'état et notifications
- **Mode édition** : Interface dédiée pour l'administration

## 🛠️ Technologies Utilisées

- **Flutter Web** : Framework de développement
- **Dart** : Langage de programmation
- **GitHub Pages** : Hébergement et déploiement
- **GitHub Actions** : CI/CD automatique
- **PDF Generation** : Création de documents PDF
- **HTTP Requests** : Communication avec l'API
- **Local Storage** : Cache et persistance des données

## 📦 Structure du Projet

```
lib/
├── main.dart                 # Point d'entrée principal
├── services/
│   ├── shared_catalog_service.dart   # Gestion du catalogue partagé
│   └── security_service.dart         # Service de sécurité
└── widgets/
    └── login_dialog.dart            # Interface d'authentification

docs/                         # Fichiers web déployés
├── index.html               # Page principale
├── main.dart.js            # Code Flutter compilé
└── data/
    └── catalog.json        # Catalogue partagé

.github/workflows/
└── deploy.yml              # Déploiement automatique
```

## 🚀 Déploiement

Le déploiement est automatique via GitHub Actions :

1. **Push sur main** → Déclenche le build
2. **Flutter build web** → Compilation pour le web
3. **Deploy to Pages** → Mise en ligne automatique

### Commandes de développement :

```bash
# Build local
flutter build web --base-href "/msh_d/"

# Synchronisation manuelle (si nécessaire)
robocopy build\web docs /MIR

# Déploiement
git add . && git commit -m "Update" && git push
```

## 🔐 Sécurité

- **Code d'accès** : Protection des fonctions d'administration
- **Validation d'entrée** : Vérification des données utilisateur
- **Cache sécurisé** : Stockage local des données sensibles

## 📱 Utilisation

### Pour les Utilisateurs :
1. Visitez l'application web
2. Parcourez le catalogue
3. Ajoutez des produits au panier
4. Générez et partagez votre commande

### Pour les Administrateurs :
1. Utilisez le code de sécurité pour accéder aux fonctions d'administration
2. Chargez de nouveaux catalogues via fichiers ZIP
3. Modifiez ou supprimez des produits
4. Partagez le catalogue mis à jour

## 🐛 Résolution de Problèmes

### Catalogue ne se charge pas ?
- Cliquez sur le bouton d'actualisation (↻)
- Vérifiez votre connexion internet
- Videz le cache du navigateur

### PDF ne se génère pas ?
- Vérifiez que le panier contient des articles
- Essayez un autre navigateur
- Contactez l'administrateur

## 📞 Support

Pour toute question ou problème technique, contactez l'équipe de développement.

---

**Développé avec ❤️ en Flutter**
