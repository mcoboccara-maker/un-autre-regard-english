// lib/services/email_service.dart
// Service d'envoi d'email via Brevo (ex-Sendinblue)
// Quota gratuit : 300 emails/jour (9000/mois)

import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailService {
  static EmailService? _instance;
  static EmailService get instance => _instance ??= EmailService._();
  
  EmailService._();

  // ═══════════════════════════════════════════════════════════════════════════
  // CONFIGURATION BREVO
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const String _apiUrl = 'https://api.brevo.com/v3/smtp/email';
  
  // ⚠️ REMPLACE PAR TA NOUVELLE CLÉ API BREVO
  static const String _apiKey = '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';
  
  // Expéditeur (vérifié dans Brevo)
  static const String _senderEmail = 'appunautreregard@gmail.com';
  static const String _senderName = 'Un Autre Regard';
  
  // ═══════════════════════════════════════════════════════════════════════════
  // DESTINATAIRE FIXE (toutes les réflexions arrivent ici)
  // ═══════════════════════════════════════════════════════════════════════════
  static const String _destinataireEmail = 'appunautreregard@gmail.com';

  // ═══════════════════════════════════════════════════════════════════════════
  // ENVOI DES PERSPECTIVES PAR EMAIL
  // ═══════════════════════════════════════════════════════════════════════════

  /// Envoie les perspectives générées par email
  /// 
  /// [toEmail] : Email de l'utilisateur (pour info dans le mail, PAS comme destinataire)
  /// [pensee] : La pensée originale de l'utilisateur
  /// [perspectives] : Map<nomSource, réponseIA>
  /// [evaluations] : Map<nomSource, note 0-10> (optionnel)
  /// 
  /// ⚠️ L'email est TOUJOURS envoyé à appunautreregard@gmail.com
  Future<EmailResult> sendPerspectives({
    required String toEmail,  // Email de l'utilisateur (pour référence seulement)
    required String pensee,
    required Map<String, String> perspectives,
    Map<String, int>? evaluations,
    Map<String, String>? commentaires,
  }) async {
    try {
      // Construire le HTML (avec l'email utilisateur pour référence)
      final htmlContent = _buildPerspectivesHtml(
        pensee: pensee,
        perspectives: perspectives,
        evaluations: evaluations,
        commentaires: commentaires,
        userEmail: toEmail,  // Afficher qui a envoyé
      );

      // Construire le corps de la requête
      // ═══════════════════════════════════════════════════════════════════════
      // ENVOI TOUJOURS À appunautreregard@gmail.com (pas à toEmail!)
      // ═══════════════════════════════════════════════════════════════════════
      final body = jsonEncode({
        'sender': {
          'name': _senderName,
          'email': _senderEmail,
        },
        'to': [
          {'email': _destinataireEmail}  // ✅ Toujours vers appunautreregard@gmail.com
        ],
        'subject': '🌟 Réflexion de $toEmail - Un Autre Regard',
        'htmlContent': htmlContent,
      });

      // Appeler l'API Brevo
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'api-key': _apiKey,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 201) {
        print('✅ Email envoyé avec succès à $_destinataireEmail (de: $toEmail)');
        return EmailResult(success: true, message: 'Email envoyé avec succès');
      } else {
        print('❌ Erreur envoi email: ${response.statusCode}');
        print('Body: ${response.body}');
        return EmailResult(
          success: false, 
          message: 'Erreur ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Exception envoi email: $e');
      return EmailResult(success: false, message: 'Erreur: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONSTRUCTION DU HTML
  // ═══════════════════════════════════════════════════════════════════════════

  String _buildPerspectivesHtml({
    required String pensee,
    required Map<String, String> perspectives,
    Map<String, int>? evaluations,
    Map<String, String>? commentaires,
    String? userEmail,
  }) {
    final buffer = StringBuffer();
    
    buffer.write('''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
      line-height: 1.6;
      color: #1E293B;
      background-color: #F8FAFC;
      margin: 0;
      padding: 20px;
    }
    .container {
      max-width: 600px;
      margin: 0 auto;
      background: white;
      border-radius: 16px;
      overflow: hidden;
      box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
    }
    .header {
      background: linear-gradient(135deg, #2E8B7B 0%, #3A9D8C 100%);
      color: white;
      padding: 30px;
      text-align: center;
    }
    .header h1 {
      margin: 0;
      font-size: 24px;
      font-weight: 600;
    }
    .header p {
      margin: 10px 0 0;
      opacity: 0.9;
      font-size: 14px;
    }
    .user-info {
      background: #E0F2FE;
      padding: 10px 20px;
      text-align: center;
      font-size: 13px;
      color: #0369A1;
    }
    .pensee-section {
      background: #F0FDF9;
      padding: 20px 30px;
      border-left: 4px solid #2E8B7B;
      margin: 20px;
      border-radius: 0 8px 8px 0;
    }
    .pensee-label {
      font-size: 12px;
      color: #2E8B7B;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      margin-bottom: 8px;
    }
    .pensee-text {
      font-size: 16px;
      font-style: italic;
      color: #334155;
    }
    .perspective-card {
      margin: 20px;
      border: 1px solid #E2E8F0;
      border-radius: 12px;
      overflow: hidden;
    }
    .perspective-header {
      background: #F8FAFC;
      padding: 15px 20px;
      border-bottom: 1px solid #E2E8F0;
      display: flex;
      align-items: center;
      justify-content: space-between;
    }
    .perspective-title {
      font-weight: 600;
      color: #2E8B7B;
      font-size: 16px;
    }
    .perspective-rating {
      background: #2E8B7B;
      color: white;
      padding: 4px 10px;
      border-radius: 12px;
      font-size: 12px;
      font-weight: 600;
    }
    .perspective-content {
      padding: 20px;
      font-size: 15px;
      color: #334155;
    }
    .perspective-comment {
      background: #FEF3C7;
      padding: 12px 15px;
      margin: 0 20px 20px;
      border-radius: 8px;
      font-size: 13px;
      color: #92400E;
    }
    .perspective-comment strong {
      display: block;
      margin-bottom: 4px;
    }
    .footer {
      text-align: center;
      padding: 20px;
      color: #64748B;
      font-size: 12px;
      border-top: 1px solid #E2E8F0;
    }
    .footer a {
      color: #2E8B7B;
      text-decoration: none;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🌟 Réflexion Un Autre Regard</h1>
      <p>Perspectives générées par l'application</p>
    </div>
    
    ${userEmail != null ? '<div class="user-info">👤 Utilisateur : $userEmail</div>' : ''}
    
    <div class="pensee-section">
      <div class="pensee-label">💭 Pensée partagée</div>
      <div class="pensee-text">"$pensee"</div>
    </div>
''');

    // Ajouter chaque perspective
    int index = 0;
    perspectives.forEach((source, response) {
      index++;
      final rating = evaluations?[source];
      final comment = commentaires?[source];
      
      buffer.write('''
    <div class="perspective-card">
      <div class="perspective-header">
        <span class="perspective-title">$index. $source</span>
        ${rating != null ? '<span class="perspective-rating">$rating/10</span>' : ''}
      </div>
      <div class="perspective-content">
        ${_escapeHtml(response)}
      </div>
      ${comment != null && comment.isNotEmpty ? '''
      <div class="perspective-comment">
        <strong>💬 Ton commentaire :</strong>
        ${_escapeHtml(comment)}
      </div>
      ''' : ''}
    </div>
''');
    });

    buffer.write('''
    <div class="footer">
      <p>Généré par <strong>Un Autre Regard</strong></p>
      <p>Une app pour explorer différentes perspectives sur tes pensées</p>
    </div>
  </div>
</body>
</html>
''');

    return buffer.toString();
  }

  /// Échappe les caractères HTML spéciaux
  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;')
        .replaceAll('\n', '<br>');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TEST DE CONNEXION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Teste si la configuration Brevo fonctionne
  Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.brevo.com/v3/account'),
        headers: {
          'api-key': _apiKey,
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Connexion Brevo OK');
        print('   Compte: ${data['email']}');
        print('   Plan: ${data['plan']}');
        return true;
      } else {
        print('❌ Erreur connexion Brevo: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Exception test Brevo: $e');
      return false;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CLASSE RÉSULTAT
// ═══════════════════════════════════════════════════════════════════════════

class EmailResult {
  final bool success;
  final String message;
  
  EmailResult({required this.success, required this.message});
}
