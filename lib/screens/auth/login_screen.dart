import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/user_profile.dart';
import '../../services/complete_auth_service.dart';
import '../../services/email_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // Constantes pour le mode invité
  static const String guestEmail = 'invite@unautreregard.app';
  static const String guestPassword = 'invite';
  
  List<String> _existingEmails = [];
  bool _isLoading = false;
  bool _isLoadingGuest = false;
  bool _showExistingAccounts = false;
  bool _obscurePassword = true;
  bool _isNewUser = true;
  
  // 🆕 État pour afficher/masquer le formulaire
  bool _showForm = false;

  @override
  void initState() {
    super.initState();
    _loadExistingAccounts();
  }

  Future<void> _loadExistingAccounts() async {
    try {
      final emails = await CompleteAuthService.instance.getAllUsers();
      // Filtrer l'email invité de la liste
      emails.remove(guestEmail);
      setState(() {
        _existingEmails = emails;
        _showExistingAccounts = emails.isNotEmpty;
      });
    } catch (e) {
      print('Erreur chargement comptes: $e');
    }
  }

  /// Connexion en mode invité
  Future<void> _loginAsGuest() async {
    setState(() => _isLoadingGuest = true);

    try {
      // Vérifier si le compte invité existe, sinon le créer
      final existingUsers = await CompleteAuthService.instance.getAllUsers();
      
      if (!existingUsers.contains(guestEmail)) {
        print('Création du compte invité...');
        await CompleteAuthService.instance.register(guestEmail, guestPassword);
      }
      
      // Connexion en tant qu'invité
      print('Connexion en mode invité...');
      final success = await CompleteAuthService.instance.login(guestEmail, guestPassword);
      
      if (success) {
        // Effacer l'historique de l'invité à chaque nouvelle connexion
        print('🗑️ Effacement de l\'historique invité...');
        final reflections = await CompleteAuthService.instance.getAllReflections();
        for (var reflection in reflections) {
          if (reflection['id'] != null) {
            await CompleteAuthService.instance.deleteReflection(reflection['id']);
          }
        }
        print('✅ Historique invité effacé');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Text('Bienvenue en mode invité !', style: GoogleFonts.inter()),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
          
          await Future.delayed(const Duration(milliseconds: 500));
          Navigator.pushReplacementNamed(context, '/menu');
        }
      } else {
        throw Exception('Échec de la connexion invité');
      }
    } catch (e) {
      print('❌ Erreur mode invité: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e', style: GoogleFonts.inter()),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingGuest = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Fond violet pastel - cohérent avec welcome_screen
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF8B7FC7),  // Violet pastel
              Color(0xFFA89ED8),  // Violet pastel clair
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  
                  // Bouton retour
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Header simplifié
                  _buildSimpleHeader(),
                  
                  const SizedBox(height: 32),
                  
                  // ════════════════════════════════════════
                  // 🆕 LES 3 OPTIONS AU MÊME NIVEAU
                  // ════════════════════════════════════════
                  
                  // Option 1 : MODE INVITÉ (carte complète avec rappel)
                  _buildGuestCard(),
                  
                  const SizedBox(height: 16),
                  
                  // Options 2 & 3 : INSCRIPTION et CONNEXION (côte à côte)
                  Row(
                    children: [
                      Expanded(child: _buildCreateAccountCard()),
                      const SizedBox(width: 12),
                      Expanded(child: _buildLoginCard()),
                    ],
                  ),
                  
                  // ════════════════════════════════════════
                  // FORMULAIRE (apparaît si inscription ou connexion sélectionné)
                  // ════════════════════════════════════════
                  if (_showForm) ...[
                    const SizedBox(height: 32),
                    _buildFormSection(),
                  ],
                  
                  // Comptes existants
                  if (_showExistingAccounts && !_isNewUser && _showForm) ...[
                    const SizedBox(height: 32),
                    _buildExistingAccountsSection(),
                  ],
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Header simplifié
  Widget _buildSimpleHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Icône de l'app CENTRÉE - SANS CERCLE
        Center(
          child: Image.asset(
            'assets/univers_visuel/brain_loading.png',
            width: 100,
            height: 100,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.visibility,
                size: 60,
                color: Colors.white,
              );
            },
          ).animate().scale(delay: 200.ms),
        ),
        
        const SizedBox(height: 24),
        
        // Titre "Bienvenue dans Un Autre Regard" en GRAS
        Text(
          'Bienvenue dans',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.9),
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 300.ms),
        
        Text(
          'Un Autre Regard',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.2, end: 0),
        
        const SizedBox(height: 12),
        
        Text(
          'Choisis comment tu veux commencer',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: Colors.white.withOpacity(0.8),
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  /// ════════════════════════════════════════
  /// CARTE MODE INVITÉ (avec rappel complet)
  /// ════════════════════════════════════════
  Widget _buildGuestCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF2E8B7B).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E8B7B).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Icône invite.png
              if (_isLoadingGuest)
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E8B7B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF2E8B7B),
                      ),
                    ),
                  ),
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/univers_visuel/invite.png',
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E8B7B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: Color(0xFF2E8B7B),
                        size: 28,
                      ),
                    ),
                  ),
                ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mode Invité',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2E8B7B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Essaie l\'application librement',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF5A8A8A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // ════════════════════════════════════════
          // TEXTE DE RAPPEL (demandé par l'utilisateur)
          // ════════════════════════════════════════
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E7),  // Fond jaune très clair
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE6D5A8),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: const Color(0xFFB8960C),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Rappel : dans ce mode tu as accès à toutes les fonctionnalités mais pas de sauvegarde de ton historique de pensées et émotions',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF8B7355),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Bouton "Entrer en tant qu'invité"
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoadingGuest ? null : _loginAsGuest,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E8B7B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoadingGuest
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Entrer en tant qu\'invité',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0);
  }

  /// ════════════════════════════════════════
  /// CARTE CRÉER UN COMPTE
  /// ════════════════════════════════════════
  Widget _buildCreateAccountCard() {
    final isSelected = _showForm && _isNewUser;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _isNewUser = true;
          _showForm = true;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E8B7B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF2E8B7B)
                : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Image.asset(
              'assets/univers_visuel/inscription.png',
              width: 44,
              height: 44,
              color: isSelected ? Colors.white : null,
              errorBuilder: (_, __, ___) => Icon(
                Icons.person_add,
                size: 40,
                color: isSelected ? Colors.white : const Color(0xFF5A8A8A),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Créer un\ncompte',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF1A3A3A),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0);
  }

  /// ════════════════════════════════════════
  /// CARTE SE CONNECTER
  /// ════════════════════════════════════════
  Widget _buildLoginCard() {
    final isSelected = _showForm && !_isNewUser;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _isNewUser = false;
          _showForm = true;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E8B7B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF2E8B7B)
                : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Image.asset(
              'assets/univers_visuel/connexion.png',
              width: 44,
              height: 44,
              color: isSelected ? Colors.white : null,
              errorBuilder: (_, __, ___) => Icon(
                Icons.login,
                size: 40,
                color: isSelected ? Colors.white : const Color(0xFF5A8A8A),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Se\nconnecter',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF1A3A3A),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2, end: 0);
  }

  /// ════════════════════════════════════════
  /// SECTION FORMULAIRE (apparaît quand Inscription ou Connexion sélectionné)
  /// ════════════════════════════════════════
  Widget _buildFormSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre du formulaire
          Row(
            children: [
              Icon(
                _isNewUser ? Icons.person_add : Icons.login,
                color: const Color(0xFF2E8B7B),
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                _isNewUser ? 'Créer votre compte' : 'Se connecter',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A3A3A),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Champ Email
          _buildFieldWithIcon(
            iconPath: 'assets/univers_visuel/mail.png',
            fallbackIcon: Icons.email_outlined,
            label: 'Adresse email',
            child: TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: const Color(0xFF1A3A3A),
              ),
              decoration: InputDecoration(
                hintText: 'votre.email@exemple.com',
                hintStyle: GoogleFonts.inter(
                  color: const Color(0xFF94A3B8),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: const Color(0xFFF5F9F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2E8B7B), width: 2),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez saisir votre email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Veuillez saisir un email valide';
                }
                return null;
              },
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Champ Mot de passe
          _buildFieldWithIcon(
            iconPath: 'assets/univers_visuel/password.png',
            fallbackIcon: Icons.lock_outlined,
            label: 'Mot de passe',
            child: TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: const Color(0xFF1A3A3A),
              ),
              decoration: InputDecoration(
                hintText: _isNewUser ? 'Créez un mot de passe sécurisé' : 'Votre mot de passe',
                hintStyle: GoogleFonts.inter(
                  color: const Color(0xFF94A3B8),
                  fontSize: 14,
                ),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF64748B),
                  ),
                ),
                filled: true,
                fillColor: const Color(0xFFF5F9F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2E8B7B), width: 2),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez saisir votre mot de passe';
                }
                if (_isNewUser && value.length < 6) {
                  return 'Le mot de passe doit contenir au moins 6 caractères';
                }
                return null;
              },
            ),
          ),

          // Lien "Mot de passe oublié ?" (seulement en mode connexion)
          if (!_isNewUser) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: _handleForgotPassword,
                child: Text(
                  'Mot de passe oublié ?',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF2E8B7B),
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Bouton d'action
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E8B7B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _isNewUser ? 'Créer mon compte' : 'Se connecter',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildFieldWithIcon({
    required String iconPath,
    required IconData fallbackIcon,
    required String label,
    required Widget child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icône PNG à gauche
        Image.asset(
          iconPath,
          width: 56,
          height: 56,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF2E8B7B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                fallbackIcon, 
                color: const Color(0xFF2E8B7B), 
                size: 28,
              ),
            );
          },
        ),
        const SizedBox(width: 12),
        
        // Colonne droite : label + champ
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A3A3A),
                ),
              ),
              const SizedBox(height: 6),
              child,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExistingAccountsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              height: 1,
              width: 40,
              color: const Color(0xFFE2E8F0),
            ),
            const SizedBox(width: 12),
            Text(
              'Comptes existants',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 1,
                color: const Color(0xFFE2E8F0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        ...(_existingEmails.map((email) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => _prefillEmail(email),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E8B7B).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Color(0xFF2E8B7B),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      email,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF1A3A3A),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),
        ))),
      ],
    );
  }

  void _prefillEmail(String email) {
    setState(() {
      _emailController.text = email;
      _isNewUser = false;
      _showForm = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Email sélectionné : $email',
          style: GoogleFonts.inter(),
        ),
        backgroundColor: const Color(0xFF2E8B7B),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Gestion du mot de passe oublié
  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();

    // Vérifier si un email est saisi
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Veuillez d\'abord saisir votre adresse email',
                  style: GoogleFonts.inter(),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    // Afficher dialogue de confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.lock_reset, color: Color(0xFF2E8B7B)),
            const SizedBox(width: 12),
            Text(
              'Mot de passe oublié',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Text(
          'Un nouveau mot de passe temporaire sera envoyé à :\n\n$email\n\nVoulez-vous continuer ?',
          style: GoogleFonts.inter(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: GoogleFonts.inter(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E8B7B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Envoyer',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Afficher indicateur de chargement
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF2E8B7B)),
      ),
    );

    try {
      // Réinitialiser le mot de passe
      final tempPassword = await CompleteAuthService.instance.resetPassword(email);

      if (tempPassword == null) {
        if (!mounted) return;
        Navigator.pop(context); // Fermer le loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Aucun compte trouvé avec cet email',
                    style: GoogleFonts.inter(),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        return;
      }

      // Envoyer l'email avec le nouveau mot de passe
      final result = await EmailService.instance.sendPasswordReset(
        toEmail: email,
        tempPassword: tempPassword,
      );

      if (!mounted) return;
      Navigator.pop(context); // Fermer le loader

      if (result.success) {
        // Afficher le dialogue pour définir un nouveau mot de passe
        await _showSetNewPasswordDialog(email);
      } else {
        // Afficher le message d'erreur détaillé
        print('❌ Erreur envoi email mot de passe: ${result.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Erreur: ${result.message}',
                    style: GoogleFonts.inter(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Fermer le loader
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e', style: GoogleFonts.inter()),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  /// Dialogue pour définir un nouveau mot de passe après réception du temporaire
  Future<void> _showSetNewPasswordDialog(String email) async {
    final tempPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    bool isLoading = false;
    String? errorMessage;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.lock_reset, color: Color(0xFF2E8B7B)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Définir un nouveau mot de passe',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Un mot de passe temporaire a été envoyé à $email',
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),

                // Champ mot de passe temporaire
                Text(
                  'Mot de passe temporaire',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: tempPasswordController,
                  decoration: InputDecoration(
                    hintText: 'Entrez le mot de passe reçu par email',
                    hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  style: GoogleFonts.inter(fontSize: 14),
                ),
                const SizedBox(height: 16),

                // Champ nouveau mot de passe
                Text(
                  'Nouveau mot de passe',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Choisissez votre nouveau mot de passe',
                    hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  style: GoogleFonts.inter(fontSize: 14),
                ),

                // Message d'erreur
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorMessage!,
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.red),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
              child: Text(
                'Annuler',
                style: GoogleFonts.inter(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final tempPwd = tempPasswordController.text.trim();
                      final newPwd = newPasswordController.text.trim();

                      if (tempPwd.isEmpty || newPwd.isEmpty) {
                        setDialogState(() {
                          errorMessage = 'Veuillez remplir les deux champs';
                        });
                        return;
                      }

                      if (newPwd.length < 4) {
                        setDialogState(() {
                          errorMessage = 'Le nouveau mot de passe doit faire au moins 4 caractères';
                        });
                        return;
                      }

                      setDialogState(() {
                        isLoading = true;
                        errorMessage = null;
                      });

                      final success = await CompleteAuthService.instance
                          .verifyTempAndSetNewPassword(email, tempPwd, newPwd);

                      if (success) {
                        Navigator.pop(dialogContext);
                        if (mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.white),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Mot de passe modifié avec succès !',
                                      style: GoogleFonts.inter(),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: const Color(0xFF10B981),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          );
                        }
                      } else {
                        setDialogState(() {
                          isLoading = false;
                          errorMessage = 'Mot de passe temporaire incorrect';
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E8B7B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Valider',
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      bool success;
      if (_isNewUser) {
        success = await CompleteAuthService.instance.register(email, password);
        
        if (success) {
          await Future.delayed(const Duration(milliseconds: 500));
          
          final profile = UserProfile.empty().copyWith(
            email: email,
            lastUpdated: DateTime.now(),
          );
          
          await CompleteAuthService.instance.saveProfile(profile.toJson());
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 12),
                    Text('Compte créé avec succès !', style: GoogleFonts.inter()),
                  ],
                ),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
            
            await Future.delayed(const Duration(milliseconds: 1000));
            Navigator.pushReplacementNamed(context, '/menu');
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.white),
                    const SizedBox(width: 12),
                    Text('Cet email est déjà utilisé', style: GoogleFonts.inter()),
                  ],
                ),
                backgroundColor: const Color(0xFFF59E0B),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
            setState(() => _isNewUser = false);
          }
        }
      } else {
        success = await CompleteAuthService.instance.login(email, password);
        
        if (success) {
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 12),
                    Text('Connexion réussie !', style: GoogleFonts.inter()),
                  ],
                ),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
            
            await Future.delayed(const Duration(milliseconds: 1000));
            Navigator.pushReplacementNamed(context, '/menu');
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    Text('Email ou mot de passe incorrect', style: GoogleFonts.inter()),
                  ],
                ),
                backgroundColor: const Color(0xFFEF4444),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e', style: GoogleFonts.inter()),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
