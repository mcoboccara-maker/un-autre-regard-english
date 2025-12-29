/// SERVICE DE DÉTECTION DE LANGUE
/// 
/// Fichier : lib/services/language_detector.dart
/// Usage  : Détecte la langue du texte utilisateur pour sélectionner le bon prompt
/// 
/// Langues supportées : français (fr), anglais (en), hébreu (he)

class LanguageDetector {
  
  /// Codes de langue supportés
  static const String french = 'fr';
  static const String english = 'en';
  static const String hebrew = 'he';
  
  /// Langue par défaut si détection échoue
  static const String defaultLanguage = french;
  
  /// Détecte la langue du texte fourni
  /// Retourne le code de langue : 'fr', 'en', ou 'he'
  static String detect(String text) {
    if (text.isEmpty) return defaultLanguage;
    
    final trimmedText = text.trim();
    
    // ══════════════════════════════════════════════════════════════════════════
    // 1. DÉTECTION HÉBREU - Caractères Unicode spécifiques
    // ══════════════════════════════════════════════════════════════════════════
    // Plage Unicode hébreu : U+0590 à U+05FF
    if (_containsHebrew(trimmedText)) {
      return hebrew;
    }
    
    // ══════════════════════════════════════════════════════════════════════════
    // 2. DÉTECTION FRANÇAIS vs ANGLAIS - Mots-clés fréquents
    // ══════════════════════════════════════════════════════════════════════════
    
    final frenchScore = _calculateFrenchScore(trimmedText);
    final englishScore = _calculateEnglishScore(trimmedText);
    
    // Si les scores sont très proches, analyser plus en profondeur
    if ((frenchScore - englishScore).abs() <= 1) {
      return _deepAnalysis(trimmedText);
    }
    
    return frenchScore > englishScore ? french : english;
  }
  
  /// Vérifie si le texte contient des caractères hébreux
  static bool _containsHebrew(String text) {
    // Caractères hébreux : U+0590 - U+05FF (lettres, voyelles, cantillation)
    // Aussi U+FB1D - U+FB4F (formes de présentation)
    return RegExp(r'[\u0590-\u05FF\uFB1D-\uFB4F]').hasMatch(text);
  }
  
  /// Calcule un score de "francité" basé sur les mots fréquents
  static int _calculateFrenchScore(String text) {
    final lowerText = text.toLowerCase();
    int score = 0;
    
    // Pronoms personnels français
    final pronouns = ['je', 'tu', 'il', 'elle', 'nous', 'vous', 'ils', 'elles', 'on', 'moi', 'toi', 'lui'];
    
    // Articles français
    final articles = ['le', 'la', 'les', 'un', 'une', 'des', 'du', 'de', 'au', 'aux'];
    
    // Prépositions françaises
    final prepositions = ['dans', 'pour', 'avec', 'sur', 'par', 'chez', 'vers', 'sans', 'entre', 'sous'];
    
    // Verbes auxiliaires / modaux
    final verbs = ['suis', 'est', 'sont', 'étais', 'était', 'ai', 'as', 'avons', 'avez', 'ont', 'fait', 'faire', 'peux', 'peut', 'veux', 'veut', 'dois', 'doit'];
    
    // Connecteurs
    final connectors = ['que', 'qui', 'quoi', 'mais', 'donc', 'car', 'parce', 'comme', 'quand', 'comment', 'pourquoi'];
    
    // Démonstratifs / possessifs
    final demonstratives = ['ce', 'cette', 'ces', 'mon', 'ma', 'mes', 'ton', 'ta', 'tes', 'son', 'sa', 'ses', 'notre', 'votre', 'leur'];
    
    // Mots très spécifiques au français (avec apostrophes - utiliser contains)
    final specificFrench = ["c'est", "qu'", "n'", "d'", "l'", "j'", "m'", "s'", "aujourd'hui", 'être', 'avoir', 'très', 'plus', 'bien', 'aussi', 'encore', 'toujours', 'jamais', 'rien', 'tout', 'tous', 'peu', 'beaucoup', 'trop'];
    
    for (final word in pronouns) {
      if (RegExp('\\b$word\\b', caseSensitive: false).hasMatch(lowerText)) score += 2;
    }
    for (final word in articles) {
      if (RegExp('\\b$word\\b', caseSensitive: false).hasMatch(lowerText)) score += 2;
    }
    for (final word in prepositions) {
      if (RegExp('\\b$word\\b', caseSensitive: false).hasMatch(lowerText)) score += 1;
    }
    for (final word in verbs) {
      if (RegExp('\\b$word\\b', caseSensitive: false).hasMatch(lowerText)) score += 2;
    }
    for (final word in connectors) {
      if (RegExp('\\b$word\\b', caseSensitive: false).hasMatch(lowerText)) score += 1;
    }
    for (final word in demonstratives) {
      if (RegExp('\\b$word\\b', caseSensitive: false).hasMatch(lowerText)) score += 1;
    }
    for (final word in specificFrench) {
      if (lowerText.contains(word)) score += 3;
    }
    
    // Caractères accentués typiquement français
    if (RegExp(r'[éèêëàâäùûüôöîïç]').hasMatch(lowerText)) {
      score += 5;
    }
    
    return score;
  }
  
  /// Calcule un score d'"anglicité" basé sur les mots fréquents
  static int _calculateEnglishScore(String text) {
    final lowerText = text.toLowerCase();
    int score = 0;
    
    // Pronoms anglais
    final pronouns = ['i', 'you', 'he', 'she', 'it', 'we', 'they', 'me', 'him', 'her', 'us', 'them', 'my', 'your', 'his', 'its', 'our', 'their'];
    
    // Articles anglais
    final articles = ['the', 'a', 'an'];
    
    // Prépositions anglaises
    final prepositions = ['in', 'on', 'at', 'to', 'for', 'with', 'by', 'from', 'about', 'into', 'through', 'during', 'before', 'after', 'above', 'below', 'between', 'under', 'without'];
    
    // Verbes auxiliaires / modaux anglais
    final verbs = ['am', 'is', 'are', 'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could', 'should', 'may', 'might', 'must', 'can', 'shall'];
    
    // Connecteurs anglais
    final connectors = ['and', 'but', 'or', 'so', 'because', 'if', 'when', 'while', 'although', 'though', 'that', 'which', 'who', 'what', 'where', 'why', 'how'];
    
    // Mots très spécifiques à l'anglais (avec apostrophes - utiliser contains)
    final specificEnglish = ["i'm", "i've", "i'll", "i'd", "you're", "you've", "you'll", "he's", "she's", "it's", "we're", "they're", "don't", "doesn't", "didn't", "won't", "wouldn't", "can't", "couldn't", "shouldn't", "isn't", "aren't", "wasn't", "weren't", "haven't", "hasn't", "hadn't", 'not', 'just', 'only', 'even', 'also', 'still', 'already', 'always', 'never', 'ever', 'very', 'really', 'quite', 'too', 'enough', 'much', 'many', 'more', 'most', 'less', 'least', 'few', 'little', 'other', 'another', 'such', 'same', 'different'];
    
    for (final word in pronouns) {
      if (RegExp('\\b$word\\b', caseSensitive: false).hasMatch(lowerText)) score += 2;
    }
    for (final word in articles) {
      if (RegExp('\\b$word\\b', caseSensitive: false).hasMatch(lowerText)) score += 2;
    }
    for (final word in prepositions) {
      if (RegExp('\\b$word\\b', caseSensitive: false).hasMatch(lowerText)) score += 1;
    }
    for (final word in verbs) {
      if (RegExp('\\b$word\\b', caseSensitive: false).hasMatch(lowerText)) score += 2;
    }
    for (final word in connectors) {
      if (RegExp('\\b$word\\b', caseSensitive: false).hasMatch(lowerText)) score += 1;
    }
    for (final word in specificEnglish) {
      if (lowerText.contains(word)) score += 3;
    }
    
    return score;
  }
  
  /// Analyse approfondie pour les cas ambigus
  /// CORRIGÉ: Utilise contains() au lieu de RegExp pour les patterns avec apostrophes
  static String _deepAnalysis(String text) {
    final lowerText = text.toLowerCase();
    
    // ══════════════════════════════════════════════════════════════════════════
    // PHRASES FRANÇAISES TYPIQUES
    // ══════════════════════════════════════════════════════════════════════════
    
    // Pattern "je suis/me sens/pense/etc."
    if (RegExp(r'\bje (suis|me sens|pense|crois|veux|dois|ne)\b').hasMatch(lowerText)) {
      return french;
    }
    
    // Contractions françaises (utiliser contains pour éviter problèmes d'apostrophes)
    if (lowerText.contains("c'est")) return french;
    if (lowerText.contains("qu'est-ce")) return french;
    if (lowerText.contains("j'ai")) return french;
    if (lowerText.contains("j'étais")) return french;
    if (lowerText.contains("n'est")) return french;
    if (lowerText.contains("n'ai")) return french;
    if (lowerText.contains("d'accord")) return french;
    if (lowerText.contains("l'on")) return french;
    
    // ══════════════════════════════════════════════════════════════════════════
    // PHRASES ANGLAISES TYPIQUES
    // ══════════════════════════════════════════════════════════════════════════
    
    // Contractions anglaises (utiliser contains)
    if (lowerText.contains("i'm")) return english;
    if (lowerText.contains("i've")) return english;
    if (lowerText.contains("i'll")) return english;
    if (lowerText.contains("don't")) return english;
    if (lowerText.contains("doesn't")) return english;
    if (lowerText.contains("didn't")) return english;
    if (lowerText.contains("can't")) return english;
    if (lowerText.contains("won't")) return english;
    if (lowerText.contains("wouldn't")) return english;
    if (lowerText.contains("couldn't")) return english;
    if (lowerText.contains("shouldn't")) return english;
    if (lowerText.contains("it's")) return english;
    if (lowerText.contains("that's")) return english;
    if (lowerText.contains("what's")) return english;
    if (lowerText.contains("there's")) return english;
    
    // Patterns sans apostrophes (safe avec RegExp)
    if (RegExp(r'\bi (am|feel|think|believe|want|need)\b').hasMatch(lowerText)) {
      return english;
    }
    if (RegExp(r'\bwhat (is|are|do|does|did|should|would|could)\b').hasMatch(lowerText)) {
      return english;
    }
    if (RegExp(r'\bhow (do|does|can|should|would|could|is|are)\b').hasMatch(lowerText)) {
      return english;
    }
    
    // ══════════════════════════════════════════════════════════════════════════
    // TERMINAISONS DE MOTS TYPIQUES
    // ══════════════════════════════════════════════════════════════════════════
    
    // Terminaisons françaises
    int frenchEndings = 0;
    frenchEndings += RegExp(r'\w+tion\b').allMatches(lowerText).length; // nation, situation
    frenchEndings += RegExp(r'\w+ment\b').allMatches(lowerText).length; // vraiment, sentiment
    frenchEndings += RegExp(r'\w+eur\b').allMatches(lowerText).length;  // bonheur, malheur
    frenchEndings += RegExp(r'\w+euse\b').allMatches(lowerText).length; // heureuse
    frenchEndings += RegExp(r'\w+eux\b').allMatches(lowerText).length;  // heureux
    frenchEndings += RegExp(r'\w+ais\b').allMatches(lowerText).length;  // étais, avais
    frenchEndings += RegExp(r'\w+ait\b').allMatches(lowerText).length;  // était, avait
    
    // Terminaisons anglaises
    int englishEndings = 0;
    englishEndings += RegExp(r'\w+ing\b').allMatches(lowerText).length; // feeling, thinking
    englishEndings += RegExp(r'\w+ness\b').allMatches(lowerText).length; // happiness, sadness
    englishEndings += RegExp(r'\w+ly\b').allMatches(lowerText).length;  // really, actually
    englishEndings += RegExp(r'\w+ful\b').allMatches(lowerText).length; // hopeful, grateful
    englishEndings += RegExp(r'\w+ed\b').allMatches(lowerText).length;  // wanted, needed
    
    if (frenchEndings > englishEndings) return french;
    if (englishEndings > frenchEndings) return english;
    
    // Par défaut : français
    return defaultLanguage;
  }
  
  /// Méthode utilitaire pour obtenir le nom de la langue
  static String getLanguageName(String code) {
    switch (code) {
      case french: return 'Français';
      case english: return 'English';
      case hebrew: return 'עברית';
      default: return 'Unknown';
    }
  }
  
  /// Vérifie si un code de langue est supporté
  static bool isSupported(String code) {
    return code == french || code == english || code == hebrew;
  }
}
