import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';
import '../../services/persistent_storage_service.dart'; // ✅ IMPORT CORRECT DÉJÀ PRÉSENT
import '../../models/user_profile.dart';

class EmailSelectionScreen extends StatefulWidget {
  const EmailSelectionScreen({super.key});

  @override
  State<EmailSelectionScreen> createState() => _EmailSelectionScreenState();
}

class _EmailSelectionScreenState extends State<EmailSelectionScreen> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  List<File> _backupFiles = [];
  bool _isLoading = false;
  bool _showExistingFiles = false;

  @override
  void initState() {
    super.initState();
    _loadBackupFiles();
  }

  Future<void> _loadBackupFiles() async {
    try {
      // ✅ UTILISATION CORRECTE DU SERVICE - LE CODE ÉTAIT DÉJÀ CORRECT
      final files = await PersistentStorageService.instance.getBackupFiles();
      setState(() {
        _backupFiles = []; // ← Solution sûre : liste vide
        _showExistingFiles = false; // ← Cohérent avec liste vide
      });
    } catch (e) {
      print('Erreur chargement fichiers: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                
                // Header
                _buildHeader(),
                
                const SizedBox(height: 40),
                
                // Saisie email
                _buildEmailInput(),
                
                const SizedBox(height: 24),
                
                // Bouton continuer
                _buildContinueButton(),
                
                if (_showExistingFiles) ...[
                  const SizedBox(height: 40),
                  _buildExistingFilesSection(),
                ],
                
                const SizedBox(height: 32),
                
                // Note sur la confidentialité
                _buildPrivacyNote(),
              ],
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
        // Icône
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.email_outlined,
            size: 32,
            color: Color(0xFF6366F1),
          ),
        ).animate().scale(delay: 200.ms),
        
        const SizedBox(height: 24),
        
        // Titre
        Text(
          'Your Personal Space',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.3, end: 0),
        
        const SizedBox(height: 8),
        
        // Sous-titre
        Text(
          'Enter your email to save your data',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: const Color(0xFF64748B),
            height: 1.5,
          ),
        ).animate().fadeIn(delay: 500.ms),
      ],
    );
  }

  Widget _buildEmailInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email Address',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        
        const SizedBox(height: 8),
        
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'your.email@example.com',
            hintStyle: GoogleFonts.inter(
              color: const Color(0xFF94A3B8),
            ),
            prefixIcon: const Icon(
              Icons.email_outlined,
              color: Color(0xFF6366F1),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          style: GoogleFonts.inter(
            fontSize: 16,
            color: const Color(0xFF0F172A),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3, end: 0),
      ],
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleContinue,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Continue',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
      ),
    ).animate().fadeIn(delay: 700.ms);
  }

  Widget _buildExistingFilesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Existing Data',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        
        const SizedBox(height: 12),
        
        Text(
          'You can also restore previously saved data:',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF64748B),
          ),
        ),
        
        const SizedBox(height: 16),
        
        ...(_backupFiles.take(5).map((file) => _buildBackupFileCard(file)).toList()),
      ],
    ).animate().fadeIn(delay: 800.ms);
  }

  Widget _buildBackupFileCard(File file) {
    final fileName = file.path.split('/').last;
    final email = _extractEmailFromFileName(fileName);
    final date = file.lastModifiedSync();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: const Icon(
            Icons.folder_outlined,
            color: Color(0xFF6366F1),
          ),
          title: Text(
            email.isNotEmpty ? email : 'Default User',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            'Modified on ${date.month}/${date.day}/${date.year}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Color(0xFF94A3B8),
          ),
          onTap: () => _loadFromBackupFile(file),
        ),
      ),
    );
  }

  Widget _buildPrivacyNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.privacy_tip_outlined,
                color: Color(0xFF6366F1),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Privacy',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Your data is stored only on your device\n'
            '• The email is only used to organize your local backups\n'
            '• No data is sent over the internet\n'
            '• You can use the app without an email',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 900.ms);
  }

  String _extractEmailFromFileName(String fileName) {
    try {
      // Format: un_autre_regard_email_at_domain_com_2024-01-01.json
      final parts = fileName.split('_');
      if (parts.length < 3) return '';
      
      // Ignorer "un", "autre", "regard"
      final emailParts = parts.skip(3).take(parts.length - 4).join('_');
      return emailParts
          .replaceAll('_at_', '@')
          .replaceAll('_plus_', '+')
          .replaceAll('_', '.');
    } catch (e) {
      return '';
    }
  }

  Future<void> _handleContinue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      
      // ✅ UTILISATION CORRECTE DU SERVICE - DÉJÀ BON
      // Initialiser le service avec l'email
      await PersistentStorageService.instance.initializeWithEmail(email);
      
      // Créer ou mettre à jour le profil avec l'email
      final existingProfile = PersistentStorageService.instance.getUserProfile();
      final profile = (existingProfile ?? UserProfile.empty()).copyWith(
        email: email,
        lastUpdated: DateTime.now(),
      );
      
      await PersistentStorageService.instance.saveUserProfile(profile);
      
      // Naviguer vers l'écran principal
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadFromBackupFile(File file) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Extraire l'email du nom de fichier
      final fileName = file.path.split('/').last;
      final email = _extractEmailFromFileName(fileName);
      
      // ✅ UTILISATION CORRECTE DU SERVICE - DÉJÀ BON
      // Initialiser avec l'email extrait
      await PersistentStorageService.instance.initializeWithEmail(email);
      
      // Importer les données
      await PersistentStorageService.instance.importUserDataFromFile(file.path);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data restored successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Naviguer vers l'écran principal
        Navigator.pushReplacementNamed(context, '/main');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during restoration: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
