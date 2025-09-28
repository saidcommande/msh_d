import 'dart:io';
import 'dart:convert';

void main() {
  // Lire le fichier GOTASPAIN
  final gotaspainFile = File('GOTASPAIN_extracted/GOTASPAIN.json');
  final gotaspainContent = gotaspainFile.readAsStringSync();
  final gotaspainData = json.decode(gotaspainContent);

  // Créer le nouveau format pour l'application web
  final List<Map<String, dynamic>> products = [];

  // Convertir chaque produit
  for (int i = 0; i < gotaspainData['products'].length; i++) {
    final product = gotaspainData['products'][i];

    // Créer une description basée sur le nom
    String description = _generateDescription(product['name']);

    // Extraire le nom du fichier image depuis le chemin original
    String? imagePath = product['image_path'];
    String? imageUrl;

    if (imagePath != null) {
      // Extraire le nom du fichier (ex: prod_1752440345.png)
      String fileName = imagePath.split('/').last;
      // Construire l'URL GitHub Pages pour l'image
      imageUrl =
          'https://saidcommande.github.io/msh_d/docs/assets/images/gotaspain/$fileName';
    }

    products.add({
      'id': 'gotaspain_${i + 1}',
      'name': product['name'],
      'description': description,
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

  final webCatalog = {
    'products': products,
    'lastUpdated': DateTime.now().toIso8601String()
  };

  // Écrire le nouveau catalogue
  final outputFile = File('docs/data/catalog.json');
  outputFile
      .writeAsStringSync(JsonEncoder.withIndent('  ').convert(webCatalog));

  print('Catalogue converti avec succès !');
  print('Nombre de produits: ${products.length}');
}

String _generateDescription(String name) {
  // Générer une description basée sur le nom du produit
  if (name.toLowerCase().contains('brosse')) {
    return 'Brosse de qualité professionnelle pour tous types de travaux de peinture';
  } else if (name.toLowerCase().contains('rouleau')) {
    return 'Rouleau de peinture haute performance pour finition parfaite';
  } else if (name.toLowerCase().contains('spatule')) {
    return 'Spatule robuste pour application et lissage de matériaux';
  } else if (name.toLowerCase().contains('pinceau')) {
    return 'Pinceau de précision pour détails et finitions soignées';
  } else if (name.toLowerCase().contains('spray') ||
      name.toLowerCase().contains('pistolet')) {
    return 'Équipement de pulvérisation professionnel pour application uniforme';
  } else if (name.toLowerCase().contains('kreppe') ||
      name.toLowerCase().contains('ruban')) {
    return 'Produit de masquage et protection pour travaux de précision';
  } else if (name.toLowerCase().contains('bache')) {
    return 'Protection plastique résistante pour tous vos chantiers';
  } else if (name.toLowerCase().contains('tuyau')) {
    return 'Tuyau flexible de qualité supérieure pour usage intensif';
  } else if (name.toLowerCase().contains('mecanisme') ||
      name.toLowerCase().contains('flotteur')) {
    return 'Mécanisme de plomberie fiable et durable';
  } else {
    return 'Produit professionnel de haute qualité pour vos projets';
  }
}
