import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'dart:io' show Platform;
import 'complete_auth_service.dart';

/// Service d'authentification sociale (Google, Apple)
/// Wrapper autour des SDKs natifs qui délègue la création/connexion
/// du compte local à [CompleteAuthService.socialLogin].
class SocialAuthService {
  static SocialAuthService? _instance;
  static SocialAuthService get instance => _instance ??= SocialAuthService._();
  SocialAuthService._();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // ========== GOOGLE SIGN-IN ==========

  /// Connexion via Google. Retourne l'email en cas de succès, null sinon.
  Future<String?> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        debugPrint('ℹ️ Google Sign-In annulé par l\'utilisateur');
        return null; // Annulation
      }

      final email = account.email;
      final displayName = account.displayName;
      final photoUrl = account.photoUrl;

      final success = await CompleteAuthService.instance.socialLogin(
        email: email,
        method: AuthMethod.google,
        displayName: displayName,
        photoUrl: photoUrl,
      );

      if (success) {
        debugPrint('✅ Google Sign-In réussi: $email');
        return email;
      }
      return null;
    } catch (e, stackTrace) {
      debugPrint('❌ Google Sign-In erreur: $e');
      debugPrint('❌ Stack: $stackTrace');
      rethrow;
    }
  }

  /// Déconnexion Google (optionnel, pour permettre de changer de compte)
  Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  // ========== APPLE SIGN-IN ==========

  /// Connexion via Apple. Retourne l'email en cas de succès, null sinon.
  Future<String?> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Apple ne renvoie l'email qu'à la PREMIÈRE connexion
      String? email = credential.email;
      final givenName = credential.givenName;
      final familyName = credential.familyName;
      final userIdentifier = credential.userIdentifier;

      if (email == null && userIdentifier != null) {
        // Connexion suivante — retrouver l'email via le mapping stocké
        email = await _lookupAppleEmail(userIdentifier);
        if (email == null) {
          debugPrint('❌ Apple Sign-In: impossible de retrouver l\'email');
          return null;
        }
      }

      if (email == null) {
        debugPrint('❌ Apple Sign-In: aucun email disponible');
        return null;
      }

      // Stocker le mapping userIdentifier → email (pour les connexions futures)
      if (userIdentifier != null) {
        await _storeAppleEmailMapping(userIdentifier, email);
      }

      final displayName = [givenName, familyName]
          .where((n) => n != null && n.isNotEmpty)
          .join(' ');

      final success = await CompleteAuthService.instance.socialLogin(
        email: email,
        method: AuthMethod.apple,
        displayName: displayName.isNotEmpty ? displayName : null,
      );

      if (success) {
        debugPrint('✅ Apple Sign-In réussi: $email');
        return email;
      }
      return null;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        debugPrint('ℹ️ Apple Sign-In annulé par l\'utilisateur');
        return null; // Annulation, pas une erreur
      }
      debugPrint('❌ Apple Sign-In erreur: ${e.code} — ${e.message}');
      return null;
    } catch (e) {
      debugPrint('❌ Apple Sign-In erreur: $e');
      return null;
    }
  }

  /// Vérifie si Sign in with Apple est disponible sur cette plateforme
  Future<bool> isAppleSignInAvailable() async {
    try {
      if (kIsWeb) return false; // Nécessite un backend, désactivé pour l'instant
      if (Platform.isIOS || Platform.isMacOS) {
        return await SignInWithApple.isAvailable();
      }
      return false; // Android : nécessite un backend OAuth, désactivé
    } catch (_) {
      return false;
    }
  }

  // ========== FACEBOOK SIGN-IN ==========

  /// Connexion via Facebook. Retourne l'email en cas de succès, null sinon.
  Future<String?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.cancelled) {
        debugPrint('ℹ️ Facebook Sign-In annulé par l\'utilisateur');
        return null;
      }

      if (result.status != LoginStatus.success) {
        debugPrint('❌ Facebook Sign-In échoué: ${result.status} — ${result.message}');
        return null;
      }

      // Récupérer les données utilisateur
      final userData = await FacebookAuth.instance.getUserData(fields: 'email,name,picture');
      final email = userData['email'] as String?;
      final displayName = userData['name'] as String?;
      final photoUrl = userData['picture']?['data']?['url'] as String?;

      if (email == null) {
        debugPrint('❌ Facebook Sign-In: aucun email disponible');
        await FacebookAuth.instance.logOut();
        return null;
      }

      final success = await CompleteAuthService.instance.socialLogin(
        email: email,
        method: AuthMethod.facebook,
        displayName: displayName,
        photoUrl: photoUrl,
      );

      if (success) {
        debugPrint('✅ Facebook Sign-In réussi: $email');
        return email;
      }
      return null;
    } catch (e, stackTrace) {
      debugPrint('❌ Facebook Sign-In erreur: $e');
      debugPrint('❌ Stack: $stackTrace');
      return null;
    }
  }

  /// Déconnexion Facebook
  Future<void> signOutFacebook() async {
    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {}
  }

  // ========== MAPPING APPLE USER ID ↔ EMAIL ==========

  static const String _appleMapPrefix = 'apple_uid_';

  Future<void> _storeAppleEmailMapping(String appleUserId, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_appleMapPrefix$appleUserId', email.toLowerCase().trim());
    debugPrint('📎 Mapping Apple stocké: $appleUserId → $email');
  }

  Future<String?> _lookupAppleEmail(String appleUserId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_appleMapPrefix$appleUserId');
  }
}
