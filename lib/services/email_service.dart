// lib/services/email_service.dart
// Service d'envoi d'email via Resend
// Quota gratuit : 3 000 emails/mois

import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailService {
  static EmailService? _instance;
  static EmailService get instance => _instance ??= EmailService._();

  EmailService._();

  // ═══════════════════════════════════════════════════════════════════════════
  // CONFIGURATION RESEND
  // ═══════════════════════════════════════════════════════════════════════════

  static const String _apiUrl = 'https://api.resend.com/emails';

  // Clé API Resend — remplacer par ta clé (re_xxxxxxxx)
  static const String _apiKey = 're_H4hAZrL8_29xCXFzyBVThnJNiNbZrL1XU';

  // Expéditeur — utiliser onboarding@resend.dev en test,
  // ou ton domaine vérifié en production (ex: noreply@unautreregard.app)
  static const String _senderEmail = 'anotherperspective@binaiskit.com';
  static const String _senderName = 'Another Perspective';

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
        'from': '$_senderName <$_senderEmail>',
        'to': [_destinataireEmail],
        'subject': '🌟 Reflection from $toEmail - Another Perspective',
        'html': htmlContent,
      });

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: body,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        print('✅ Email envoyé avec succès à $_destinataireEmail (de: $toEmail)');
        return EmailResult(success: true, message: 'Email sent successfully');
      } else {
        print('❌ Erreur envoi email: ${response.statusCode}');
        print('Body: ${response.body}');
        return EmailResult(
          success: false,
          message: 'Error ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Exception envoi email: $e');
      return EmailResult(success: false, message: 'Error: $e');
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
      <h1>🌟 Another Perspective Reflection</h1>
      <p>Perspectives generated by the application</p>
    </div>

    ${userEmail != null ? '<div class="user-info">👤 User: $userEmail</div>' : ''}

    <div class="pensee-section">
      <div class="pensee-label">💭 Shared thought</div>
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
        <strong>💬 Your comment:</strong>
        ${_escapeHtml(comment)}
      </div>
      ''' : ''}
    </div>
''');
    });

    buffer.write('''
    <div class="footer">
      <p>Generated by <strong>Another Perspective</strong></p>
      <p>An app to explore different perspectives on your thoughts</p>
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
  // ENVOI MOT DE PASSE OUBLIÉ
  // ═══════════════════════════════════════════════════════════════════════════

  /// Envoie le nouveau mot de passe temporaire à l'utilisateur
  Future<EmailResult> sendPasswordReset({
    required String toEmail,
    required String tempPassword,
  }) async {
    try {
      final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      line-height: 1.6;
      color: #1E293B;
      background-color: #F8FAFC;
      margin: 0;
      padding: 20px;
    }
    .container {
      max-width: 500px;
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
      font-size: 22px;
      font-weight: 600;
    }
    .content {
      padding: 30px;
      text-align: center;
    }
    .password-box {
      background: #F0FDF9;
      border: 2px dashed #2E8B7B;
      border-radius: 12px;
      padding: 20px;
      margin: 20px 0;
    }
    .password {
      font-size: 28px;
      font-weight: bold;
      color: #2E8B7B;
      letter-spacing: 3px;
      font-family: monospace;
    }
    .warning {
      background: #FEF3C7;
      padding: 15px;
      border-radius: 8px;
      font-size: 13px;
      color: #92400E;
      margin-top: 20px;
    }
    .footer {
      text-align: center;
      padding: 20px;
      color: #64748B;
      font-size: 12px;
      border-top: 1px solid #E2E8F0;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🔐 Password Reset</h1>
    </div>
    <div class="content">
      <p>Hello,</p>
      <p>Here is your new temporary password for <strong>Another Perspective</strong>:</p>

      <div class="password-box">
        <div class="password">$tempPassword</div>
      </div>

      <p>Use this password to log in.</p>

      <div class="warning">
        ⚠️ <strong>Tip:</strong> For better security, we recommend changing this password after you log in.
      </div>
    </div>
    <div class="footer">
      <p>Another Perspective - Your reflection companion</p>
    </div>
  </div>
</body>
</html>
''';

      final body = jsonEncode({
        'from': '$_senderName <$_senderEmail>',
        'to': [toEmail],
        'subject': '🔐 Your new password - Another Perspective',
        'html': htmlContent,
      });

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: body,
      ).timeout(const Duration(seconds: 15));

      print('📧 Envoi email à: $toEmail');
      print('📧 Status code: ${response.statusCode}');
      print('📧 Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Email de réinitialisation envoyé à $toEmail');
        return EmailResult(success: true, message: 'Email sent successfully');
      } else {
        print('❌ Erreur envoi email: ${response.statusCode}');
        print('❌ Détails: ${response.body}');

        // Parser le message d'erreur Brevo pour un message plus clair
        String errorMsg = 'Error ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            errorMsg = errorData['message'];
          }
        } catch (_) {}

        return EmailResult(
          success: false,
          message: errorMsg,
        );
      }
    } catch (e) {
      print('❌ Exception envoi email: $e');
      return EmailResult(success: false, message: 'Network error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TEST DE CONNEXION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Teste si la configuration Resend fonctionne
  Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.resend.com/domains'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        print('✅ Connexion Resend OK');
        return true;
      } else {
        print('❌ Erreur connexion Resend: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Exception test Resend: $e');
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
