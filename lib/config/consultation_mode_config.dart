/// Configuration des modes de consultation pour le service RAG
///
/// Définit les différents modes de consultation de l'Encyclopedia Judaica
/// et les paramètres associés (prompts, filtres, attributions).

/// Modes de consultation disponibles
enum ConsultationMode {
  unified('Unified', 'Combines all sources'),
  historian('Historian', 'Focus on historical sources and narratives'),
  encyclopedia('Encyclopedia', 'Focus on encyclopedic and academic sources');

  final String label;
  final String description;
  const ConsultationMode(this.label, this.description);
}

/// Configuration statique pour chaque mode de consultation
class ConsultationModeConfig {
  ConsultationModeConfig._();

  /// Retourne le prompt système adapté au mode
  static String getSystemPrompt(ConsultationMode mode) {
    switch (mode) {
      case ConsultationMode.unified:
        return 'You are an expert combining historical narratives and encyclopedic knowledge. '
            'Draw from all available sources to provide a rich, multi-faceted response.';
      case ConsultationMode.historian:
        return 'You are a historian specializing in Jewish history and culture. '
            'Focus on historical context, narratives, and the evolution of traditions over time.';
      case ConsultationMode.encyclopedia:
        return 'You are an encyclopedic scholar with deep knowledge of Jewish texts and traditions. '
            'Provide precise, well-referenced academic responses.';
    }
  }

  /// Retourne les filtres de catégorie pour le mode
  static Map<String, dynamic>? getCategoryFilters(ConsultationMode mode) {
    switch (mode) {
      case ConsultationMode.unified:
        return null; // No filter - all sources
      case ConsultationMode.historian:
        return {'category': 'historical'};
      case ConsultationMode.encyclopedia:
        return {'category': 'encyclopedic'};
    }
  }

  /// Retourne la catégorie principale pour le mode
  static String? getPrimaryCategory(ConsultationMode mode) {
    switch (mode) {
      case ConsultationMode.unified:
        return null;
      case ConsultationMode.historian:
        return 'historical';
      case ConsultationMode.encyclopedia:
        return 'encyclopedic';
    }
  }

  /// Retourne l'attribution de source pour le mode
  static String getSourceAttribution(ConsultationMode mode) {
    switch (mode) {
      case ConsultationMode.unified:
        return 'Sources from Encyclopedia Judaica';
      case ConsultationMode.historian:
        return 'Historical Sources from Encyclopedia Judaica';
      case ConsultationMode.encyclopedia:
        return 'Encyclopedic Sources from Encyclopedia Judaica';
    }
  }
}
