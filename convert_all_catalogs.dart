import 'dart:io';
import 'dart:convert';

void main() {
  final List<Map<String, dynamic>> allProducts = [];

  // Convertir AKRO (version mise à jour)
  print('🔵 Conversion du catalogue AKRO...');
  final akroProducts =
      convertCatalog('catalogue/AKRO_new.json', 'AKRO', 'akro');
  allProducts.addAll(akroProducts);
  print('✅ AKRO: ${akroProducts.length} produits ajoutés');

  // Convertir AKRO2 (si disponible)
  print('🟣 Conversion du catalogue AKRO2...');
  final akro2Products = convertCatalog('data/AKRO2.json', 'AKRO2', 'akro2');
  allProducts.addAll(akro2Products);
  print('✅ AKRO2: ${akro2Products.length} produits ajoutés');

  // Convertir ANBO (version mise à jour)
  print('🟡 Conversion du catalogue ANBO...');
  final anboProducts =
      convertCatalog('catalogue/ANBO_new.json', 'ANBO', 'anbo');
  allProducts.addAll(anboProducts);
  print('✅ ANBO: ${anboProducts.length} produits ajoutés');

  // Convertir GOSTASPAIN (version mise à jour)
  print('🟢 Conversion du catalogue GOSTASPAIN...');
  final gostaspainProducts = convertCatalog(
      'catalogue/GOSTASPAIN_new.json', 'GOSTASPAIN', 'gostaspain');
  allProducts.addAll(gostaspainProducts);
  print('✅ GOSTASPAIN: ${gostaspainProducts.length} produits ajoutés');

  // Créer le catalogue unifié
  final unifiedCatalog = {
    'products': allProducts,
    'catalogs': {
      'AKRO': akroProducts.length,
      'AKRO2': akro2Products.length,
      'ANBO': anboProducts.length,
      'GOSTASPAIN': gostaspainProducts.length,
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
          'https://saidcommande.github.io/msh_d/assets/assets/images/$imageFolder/$fileName';
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
