import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/user_profile.dart';
import '../../services/complete_auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  List<String> _existingEmails = [];
  bool _isLoading = false;
  bool _showExistingAccounts = false;
  bool _obscurePassword = true;
  bool _isNewUser = true;

  @override
  void initState() {
    super.initState();
    _loadExistingAccounts();
  }

  Future<void> _loadExistingAccounts() async {
    try {
      final emails = await CompleteAuthService.instance.getAllUsers();
      setState(() {
        _existingEmails = emails;
        _showExistingAccounts = emails.isNotEmpty;
      });
    } catch (e) {
      print('Erreur chargement comptes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Fond bleu très évanescent - presque blanc avec touche de bleu
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8FBFE),  // Blanc avec infime touche de bleu
              Color(0xFFF5F9FD),  // Très légèrement plus bleuté
              Color(0xFFF8FBFE),  // Retour quasi blanc
            ],
            stops: [0.0, 0.5, 1.0],
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
                          backgroundColor: Colors.white.withOpacity(0.8),
                          foregroundColor: const Color(0xFF6366F1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Header avec icône
                  _buildHeader(),
                  
                  const SizedBox(height: 40),
                  
                  // Toggle inscription/connexion
                  _buildToggleButtons(),
                  
                  const SizedBox(height: 32),
                  
                  // Formulaire
                  _buildForm(),
                  
                  const SizedBox(height: 32),
                  
                  // Bouton principal
                  _buildActionButton(),
                  
                  // Comptes existants
                  if (_showExistingAccounts && !_isNewUser) ...[
                    const SizedBox(height: 40),
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

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icône PNG sans container blanc
        Image.asset(
          _isNewUser 
              ? 'assets/univers_visuel/inscription.png'
              : 'assets/univers_visuel/connexion.png',
          width: 80,
          height: 80,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              _isNewUser ? Icons.person_add : Icons.login,
              size: 64,
              color: const Color(0xFF3AA17E),
            );
          },
        ).animate().scale(delay: 200.ms),
        
        const SizedBox(height: 24),
        
        Text(
          _isNewUser ? 'Créer votre compte' : 'Se connecter',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.3, end: 0),
        
        const SizedBox(height: 8),
        
        Text(
          _isNewUser 
            ? 'Créez votre espace personnel sécurisé'
            : 'Accédez à votre espace personnel',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: const Color(0xFF64748B),
            height: 1.5,
          ),
        ).animate().fadeIn(delay: 500.ms),
      ],
    );
  }

  Widget _buildToggleButtons() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          // Bouton Inscription
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isNewUser = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _isNewUser 
                      ? const Color(0xFF6366F1) 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/univers_visuel/inscription.png',
                      width: 20,
                      height: 20,
                      color: _isNewUser ? Colors.white : const Color(0xFF64748B),
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.person_add,
                          size: 20,
                          color: _isNewUser ? Colors.white : const Color(0xFF64748B),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Inscription',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: _isNewUser ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Bouton Connexion
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isNewUser = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: !_isNewUser 
                      ? const Color(0xFF6366F1) 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/univers_visuel/connexion.png',
                      width: 20,
                      height: 20,
                      color: !_isNewUser ? Colors.white : const Color(0xFF64748B),
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.login,
                          size: 20,
                          color: !_isNewUser ? Colors.white : const Color(0xFF64748B),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Connexion',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: !_isNewUser ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Champ Email avec icône à gauche
        _buildFieldWithIcon(
          iconPath: 'assets/univers_visuel/mail.png',
          fallbackIcon: Icons.email_outlined,
          label: 'Adresse email',
          child: TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: const Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              hintText: 'votre.email@exemple.com',
              hintStyle: GoogleFonts.inter(
                color: const Color(0xFF94A3B8),
                fontSize: 14,
              ),
              filled: true,
              fillColor: Colors.white,
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
                borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
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
        ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3, end: 0),
        
        const SizedBox(height: 24),
        
        // Champ Mot de passe avec icône à gauche
        _buildFieldWithIcon(
          iconPath: 'assets/univers_visuel/password.png',
          fallbackIcon: Icons.lock_outlined,
          label: 'Mot de passe',
          child: TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: const Color(0xFF0F172A),
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
              fillColor: Colors.white,
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
                borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
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
        ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.3, end: 0),
      ],
    );
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
        // Icône PNG à gauche - hauteur = label + zone de saisie
        Image.asset(
          iconPath,
          width: 72,
          height: 72,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                fallbackIcon, 
                color: const Color(0xFF6366F1), 
                size: 32,
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
              // Label
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              
              // Champ de saisie
              child,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleAction,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                _isNewUser ? 'Créer mon compte' : 'Se connecter',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3, end: 0);
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
              padding: const EdgeInsets.all(16),
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
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Color(0xFF6366F1),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      email,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
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
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Email sélectionné : $email',
          style: GoogleFonts.inter(),
        ),
        backgroundColor: const Color(0xFF6366F1),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
            Navigator.pushReplacementNamed(context, '/home');
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
            Navigator.pushReplacementNamed(context, '/home');
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
