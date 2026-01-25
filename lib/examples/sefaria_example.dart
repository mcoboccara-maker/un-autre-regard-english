/// ═══════════════════════════════════════════════════════════════════════════════
/// EXEMPLE D'UTILISATION - SEFARIA API SERVICE
/// ═══════════════════════════════════════════════════════════════════════════════
///
/// Ce fichier montre comment utiliser le service Sefaria dans l'application.
///

import '../services/sefaria_api_service.dart';

/// Exemple 1: Récupérer la paracha de la semaine
Future<void> exempleParacha() async {
  final calendar = await SefariaApiService.instance.getCalendar();

  print('=== PARACHA DE LA SEMAINE ===');
  print('Date: ${calendar.date}');

  final parasha = calendar.parasha;
  if (parasha != null) {
    print('Nom hébreu: ${parasha.displayValue.he}');
    print('Nom anglais: ${parasha.displayValue.en}');
    print('Référence: ${parasha.ref}');
    print('Description: ${parasha.description?.en ?? "N/A"}');

    if (parasha.aliyot != null) {
      print('Aliyot:');
      for (int i = 0; i < parasha.aliyot!.length; i++) {
        print('  ${i + 1}. ${parasha.aliyot![i]}');
      }
    }
  }

  // Daf Yomi
  final dafYomi = calendar.dafYomi;
  if (dafYomi != null) {
    print('\n=== DAF YOMI ===');
    print('${dafYomi.displayValue.en} (${dafYomi.displayValue.he})');
  }
}

/// Exemple 2: Lire un texte spécifique
Future<void> exempleTexte() async {
  print('\n=== TEXTE: GENÈSE 1:1-5 ===');

  final text = await SefariaApiService.instance.getText('Genesis.1.1-5');

  print('Hébreu:');
  print(text.hebrewText);

  print('\nAnglais:');
  print(text.englishText);
}

/// Exemple 3: Obtenir les commentaires de Rashi
Future<void> exempleRashi() async {
  print('\n=== RASHI SUR GENÈSE 1:1 ===');

  final rashi = await SefariaApiService.instance.getRashiCommentary('Genesis.1.1');

  print('Texte hébreu du commentaire:');
  print(rashi.hebrewText);
}

/// Exemple 4: Explorer les commentaires disponibles
Future<void> exempleCommentaires() async {
  print('\n=== COMMENTAIRES DISPONIBLES SUR GENÈSE 1:1 ===');

  final related = await SefariaApiService.instance.getRelated('Genesis.1.1');

  print('Commentateurs disponibles:');
  for (final commentator in related.availableCommentators) {
    print('  - $commentator');
  }

  print('\nNombre de commentaires Rashi: ${related.rashi.length}');
  print('Nombre de commentaires Ramban: ${related.ramban.length}');
}

/// Exemple 5: Recherche dans les textes
Future<void> exempleRecherche() async {
  print('\n=== RECHERCHE: "Shema Israel" ===');

  final results = await SefariaApiService.instance.search(
    'Shema Israel',
    filters: ['Tanakh'],
    size: 5,
  );

  print('Résultats trouvés: ${results.total}');
  for (final hit in results.hits) {
    print('  - ${hit.ref}: ${hit.text.substring(0, 100.clamp(0, hit.text.length))}...');
  }
}

/// Exemple 6: Intégration avec l'Encyclopaedia Judaica
///
/// Flux recommandé pour le module "Éclairage":
/// 1. Utilisateur pose une question
/// 2. LLM génère un éclairage existentiel
/// 3. Torah Guide API (Encyclopaedia Judaica) ajoute le contexte historique
/// 4. Sefaria API propose les sources textuelles
///
Future<void> exempleFluxEclairage(String question) async {
  print('\n=== FLUX ÉCLAIRAGE ===');
  print('Question: $question');

  // Étape 1: Rechercher dans Sefaria
  final sefariaResults = await SefariaApiService.instance.search(question, size: 3);

  print('\nSources Sefaria suggérées:');
  for (final hit in sefariaResults.hits) {
    print('  📖 ${hit.ref}');
  }

  // Étape 2: Pour chaque source, on peut récupérer le texte complet
  if (sefariaResults.hits.isNotEmpty) {
    final firstRef = sefariaResults.hits.first.ref;
    final text = await SefariaApiService.instance.getText(firstRef);
    print('\nTexte de $firstRef:');
    print(text.hebrewText.substring(0, 200.clamp(0, text.hebrewText.length)));
  }

  // Étape 3: Le contexte historique viendrait de Torah Guide API
  // final context = await TorahGuideApiService.instance.search(question);
}

/// Point d'entrée pour tester
void main() async {
  try {
    await exempleParacha();
    await exempleTexte();
    await exempleRashi();
    await exempleCommentaires();
    await exempleRecherche();
    await exempleFluxEclairage('What is the meaning of Shabbat?');
  } catch (e) {
    print('Erreur: $e');
  }
}
