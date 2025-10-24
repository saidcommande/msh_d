import 'dart:io';
import 'dart:convert';

void main() {
  final List<Map<String, dynamic>> allProducts = [];

  // Convertir AKASYA-MAX (catalogue principal)
  print('� Conversion du catalogue AKASYA-MAX...');
  final akasyaMaxProducts = convertCatalog(
      'catalogue/akasya-max/akasya-max.json', 'AKASYA-MAX', 'akasya-max');
  allProducts.addAll(akasyaMaxProducts);
  print('✅ AKASYA-MAX: ${akasyaMaxProducts.length} produits ajoutés');

  // Créer le catalogue unifié
  final unifiedCatalog = {
    'products': allProducts,
    'catalogs': {
      'AKASYA-MAX': akasyaMaxProducts.length,
      'total': allProducts.length
    },
    'lastUpdated': DateTime.now().toIso8601String()
  };

  // Sauvegarder dans data/catalog.json
  final outputFile = File('data/catalog.json');
  outputFile.writeAsStringSync(json.encode(unifiedCatalog));

  print(
      '🎉 Catalogue unifié créé avec ${allProducts.length} produits au total !');
  print('📁 Sauvegardé dans: data/catalog.json');
}

List<Map<String, dynamic>> convertCatalog(
    String filePath, String catalogName, String imageFolder) {
  final catalogFile = File(filePath);
  if (!catalogFile.existsSync()) {
    print('❌ Fichier non trouvé: $filePath');
    return [];
  }

  final catalogContent = catalogFile.readAsStringSync();
  final catalogData = json.decode(catalogContent);

  final List<Map<String, dynamic>> products = [];

  // Convertir chaque produit
  for (int i = 0; i < catalogData['products'].length; i++) {
    final product = catalogData['products'][i];

    // Créer une description basée sur le nom et le catalogue
    String description = _generateDescription(product['name'], catalogName);

    // Extraire le nom du fichier image depuis le chemin original
    String? imagePath = product['image_path'];
    String? imageUrl;

    if (imagePath != null) {
      // Extraire le nom du fichier (ex: prod_1752440345.png)
      String fileName = imagePath.split('/').last;
      // Si le chemin contient des backslashes Windows, les gérer aussi
      if (fileName.contains('\\')) {
        fileName = fileName.split('\\').last;
      }
      // Construire l'URL GitHub Pages pour l'image
      imageUrl =
          'https://raw.githubusercontent.com/saidcommande/msh_d/main/docs/assets/assets/images/$imageFolder/$fileName';
    }

    products.add({
      'id': '${catalogName.toLowerCase()}_${i + 1}',
      'name': _cleanProductName(product['name']),
      'description': description,
      'catalog': catalogName,
      'price': (product['prices'] as List).isNotEmpty
          ? (product['prices'][0] as num).toDouble()
          : 0.0,
      'sizes': List<String>.from(product['sizes']),
      'prices': List<double>.from(
          (product['prices'] as List).map((p) => (p as num).toDouble())),
      'imageBytes': null,
      'imageUrl': imageUrl
    });
  }

  return products;
}

String _generateDescription(String name, String catalogName) {
  // Générer une description professionnelle basée sur le nom et le catalogue
  final Map<String, String> catalogDescriptions = {
    'AKASYA-MAX':
        'Produit professionnel de la gamme AKASYA-MAX - Qualité premium pour usage professionnel et domestique.',
    'AKRO':
        'Produit professionnel de la gamme AKRO - Qualité supérieure pour usage professionnel et domestique.',
    'ANBO':
        'Article de la collection ANBO - Ensemble premium avec finitions de haute qualité.',
    'GOSTASPAIN':
        'Mécanisme GOSTASPAIN - Technologie espagnole de pointe pour équipements sanitaires.',
  };

  String baseDescription =
      catalogDescriptions[catalogName] ?? 'Produit de qualité professionnelle.';

  if (name.toLowerCase().contains('brosse')) {
    return 'Brosse professionnelle de haute qualité. $baseDescription Disponible en plusieurs tailles pour s\'adapter à tous vos besoins.';
  } else if (name.toLowerCase().contains('mecanisme')) {
    return 'Mécanisme de précision conçu pour la durabilité. $baseDescription Installation simple et performance optimale.';
  } else if (name.toLowerCase().contains('ensemble')) {
    return 'Ensemble complet avec tous les accessoires nécessaires. $baseDescription Finitions soignées et matériaux durables.';
  } else if (name.toLowerCase().contains('disque') ||
      name.toLowerCase().contains('abrasif')) {
    return 'Disque abrasif professionnel haute performance. $baseDescription Résistance et efficacité garanties pour tous travaux.';
  } else if (name.toLowerCase().contains('silicone') ||
      name.toLowerCase().contains('colle')) {
    return 'Produit d\'étanchéité et de fixation professionnel. $baseDescription Adhérence exceptionnelle et durabilité maximale.';
  } else {
    return '$baseDescription Conception robuste et fiable pour une utilisation intensive.';
  }
}

String _cleanProductName(String name) {
  // Nettoyer le nom du produit
  String cleanName = name.trim();

  // Remplacer les caractères spéciaux et espaces multiples
  cleanName = cleanName.replaceAll(RegExp(r'\s+'), ' ');

  // Ajouter des espaces dans les noms collés (ex: "2ENSEMBLES20171/PATINE" -> "2 ENSEMBLES 2017 1/PATINE")
  cleanName = cleanName.replaceAllMapped(
      RegExp(r'(\d)([A-Z])'), (match) => '${match.group(1)} ${match.group(2)}');
  cleanName = cleanName.replaceAllMapped(RegExp(r'([a-z])([A-Z])'),
      (match) => '${match.group(1)} ${match.group(2)}');
  cleanName = cleanName.replaceAllMapped(
      RegExp(r'([A-Z])(\d)'), (match) => '${match.group(1)} ${match.group(2)}');

  return cleanName;
}
