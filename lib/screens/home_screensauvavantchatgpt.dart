// lib/screens/home_screen.dart
// CARNET PRÉCIEUX - Épaisseur MASSIVE + Page Curl TRÈS PRONONCÉ
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../services/complete_auth_service.dart';
import '../widgets/slot_machine_dialog.dart';
import '../widgets/crossroads_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String _userEmail = '';
  
  // État du carnet
  bool _isOpen = false;
  int _currentPage = 0;
  final int _totalPages = 5;
  
  // Animation couverture
  late AnimationController _coverController;
  late Animation<double> _coverAnimation;
  
  // Animation page curl
  late AnimationController _pageController;
  late AnimationController _cornerHintController; // Animation coin qui invite
  double _dragProgress = 0.0;
  bool _isDragging = false;
  bool _isAnimating = false;
  int _dragDirection = 0;
  
  @override
  void initState() {
    super.initState();
    _loadUserEmail();
    
    _coverController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _coverAnimation = CurvedAnimation(
      parent: _coverController,
      curve: Curves.easeInOutCubic,
    );
    
    _coverController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _isOpen = true);
        // Démarrer l'animation du coin qui invite
        _cornerHintController.repeat(reverse: true);
      }
    });
    
    _pageController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    // Animation du coin de page qui se soulève pour inviter au swipe
    _cornerHintController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _coverController.forward();
    });
  }

  @override
  void dispose() {
    _coverController.dispose();
    _pageController.dispose();
    _cornerHintController.dispose();
    super.dispose();
  }

  Future<void> _loadUserEmail() async {
    await CompleteAuthService.instance.init();
    setState(() => _userEmail = CompleteAuthService.instance.currentUserEmail ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Stack(
          children: [
            _buildBackground(),
            Center(
              child: _isOpen ? _buildOpenNotebook() : _buildClosedNotebook(),
            ),
            Positioned(
              top: 12,
              right: 16,
              child: _buildDiscreteLogout(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [Color(0xFF2D2D2D), Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
        ),
      ),
    );
  }

  Widget _buildDiscreteLogout() {
    return GestureDetector(
      onTap: _showLogoutDialog,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(Icons.more_horiz, color: Colors.white.withOpacity(0.3), size: 20),
      ),
    );
  }

  // ============ CARNET FERMÉ ============
  
  Widget _buildClosedNotebook() {
    final size = MediaQuery.of(context).size;
    final notebookW = size.width * 0.82;
    final notebookH = size.height * 0.70;
    
    return AnimatedBuilder(
      animation: _coverAnimation,
      builder: (context, _) {
        final progress = _coverAnimation.value;
        
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(-0.03),
          child: SizedBox(
            width: notebookW + 40,
            height: notebookH + 40,
            child: Stack(
              children: [
                // Ombre principale
                Positioned(
                  left: 20,
                  right: -10,
                  bottom: -15,
                  top: 30,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.7),
                          blurRadius: 50,
                          spreadRadius: 10,
                          offset: const Offset(15, 25),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // ÉPAISSEUR MASSIVE - Pages intérieures
                Positioned(
                  left: 15,
                  right: 15,
                  top: 10,
                  bottom: 10,
                  child: _buildMassiveThickness(notebookW, notebookH),
                ),
                
                // Couverture qui s'ouvre
                Positioned.fill(
                  child: Transform(
                    alignment: Alignment.centerLeft,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0008)
                      ..rotateY(-progress * math.pi * 0.85),
                    child: _buildCover(notebookW, notebookH, progress),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ÉPAISSEUR MASSIVE du carnet
  Widget _buildMassiveThickness(double w, double h) {
    return Stack(
      children: [
        // 15 couches de pages très visibles
        ...List.generate(15, (i) {
          final reverseI = 15 - i;
          return Positioned(
            left: reverseI * 2.0,
            right: reverseI * 2.0,
            top: i * 1.2,
            bottom: i * 1.2,
            child: Container(
              decoration: BoxDecoration(
                color: Color.lerp(
                  const Color(0xFFF8F4ED),
                  const Color(0xFFE8E0D5),
                  i / 15,
                ),
                borderRadius: BorderRadius.circular(3),
                border: i == 0 ? Border.all(color: const Color(0xFFD5C8B8), width: 0.5) : null,
              ),
            ),
          );
        }),
        
        // Tranche droite TRÈS visible
        Positioned(
          right: 0,
          top: 8,
          bottom: 8,
          width: 30,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  const Color(0xFFE8E0D5),
                  const Color(0xFFF5EFE6),
                  const Color(0xFFE8E0D5),
                ],
              ),
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 4,
                  offset: const Offset(-2, 0),
                ),
              ],
            ),
            child: CustomPaint(painter: ThickPageEdgePainter()),
          ),
        ),
        
        // Tranche du bas
        Positioned(
          left: 30,
          right: 30,
          bottom: 0,
          height: 20,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF5EFE6), Color(0xFFE0D5C8)],
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(3)),
            ),
            child: CustomPaint(painter: BottomPageEdgePainter()),
          ),
        ),
      ],
    );
  }

  Widget _buildCover(double w, double h, double openProgress) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        boxShadow: openProgress < 0.5 ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.5 * (1 - openProgress)),
            blurRadius: 30,
            offset: const Offset(10, 10),
          ),
        ] : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          children: [
            // Fond bleu mat
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E3A5F),
                    Color(0xFF152A45),
                    Color(0xFF1E3A5F),
                    Color(0xFF0F1F33),
                  ],
                  stops: [0.0, 0.4, 0.7, 1.0],
                ),
              ),
            ),
            
            // Texture mate
            CustomPaint(size: Size(w, h), painter: MatteTexturePainter()),
            
            // Tranche dorée gauche
            Positioned(
              left: 0, top: 0, bottom: 0, width: 5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFD4AF37).withOpacity(0.9),
                      const Color(0xFFB8962E).withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),
            
            // Contenu
            _buildCoverContent(w, h),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverContent(double w, double h) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 40, 30),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5), width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'assets/univers_visuel/icone.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF1E3A5F),
                  child: const Icon(Icons.auto_stories, size: 50, color: Color(0xFFD4AF37)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'Un Autre',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 36,
              fontWeight: FontWeight.w300,
              color: const Color(0xFFD4AF37).withOpacity(0.9),
              letterSpacing: 4,
            ),
          ),
          Text(
            'Regard',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 44,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFD4AF37),
              letterSpacing: 6,
            ),
          ),
          const SizedBox(height: 30),
          Container(width: 60, height: 1, color: const Color(0xFFD4AF37).withOpacity(0.4)),
          const Spacer(flex: 3),
          if (_userEmail.isNotEmpty)
            Text(
              _userEmail,
              style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withOpacity(0.4), letterSpacing: 0.5),
            ),
          const SizedBox(height: 20),
          if (!_isOpen)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 1,
                color: const Color(0xFFD4AF37).withOpacity(0.4),
              ),
            ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }

  // ============ CARNET OUVERT ============
  
  Widget _buildOpenNotebook() {
    final size = MediaQuery.of(context).size;
    final notebookW = size.width * 0.94;
    final notebookH = size.height * 0.75;
    
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0008)
        ..rotateX(-0.025),
      child: SizedBox(
        width: notebookW,
        height: notebookH + 50,
        child: Stack(
          children: [
            // Ombre TRÈS profonde
            Positioned(
              left: 30,
              right: 10,
              bottom: 0,
              top: 40,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.6),
                      blurRadius: 50,
                      spreadRadius: 15,
                      offset: const Offset(10, 25),
                    ),
                  ],
                ),
              ),
            ),
            
            // Corps du carnet
            Positioned(
              top: 15,
              left: 0,
              right: 0,
              bottom: 35,
              child: GestureDetector(
                onHorizontalDragStart: _onDragStart,
                onHorizontalDragUpdate: _onDragUpdate,
                onHorizontalDragEnd: _onDragEnd,
                child: _buildOpenNotebookBody(notebookW, notebookH - 50),
              ),
            ),
            
            // Coin de page qui se soulève (invitation au swipe)
            if (!_isDragging && !_isAnimating && _currentPage < _totalPages - 1)
              Positioned(
                right: 5,
                bottom: 55,
                child: AnimatedBuilder(
                  animation: _cornerHintController,
                  builder: (context, _) {
                    final lift = _cornerHintController.value * 25;
                    return Transform(
                      alignment: Alignment.bottomRight,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.002)
                        ..rotateX(-lift * 0.01)
                        ..rotateY(lift * 0.015),
                      child: CustomPaint(
                        size: Size(60 + lift, 60 + lift),
                        painter: PageCornerPainter(lift: lift),
                      ),
                    );
                  },
                ),
              ),
            
            // Indicateur
            Positioned(
              bottom: 5,
              left: 0,
              right: 0,
              child: _buildPageIndicator(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpenNotebookBody(double w, double h) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ÉPAISSEUR MASSIVE en dessous
        _buildOpenNotebookThickness(w, h),
        
        // Double page actuelle
        _buildCurrentSpread(w, h),
        
        // Page qui se plie avec VRAI CURL
        if (_isDragging || _isAnimating)
          _buildRealCurlingPage(w, h),
      ],
    );
  }

  Widget _buildOpenNotebookThickness(double w, double h) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // BEAUCOUP de couches de pages
        ...List.generate(12, (i) {
          final offset = (12 - i) * 2.5;
          return Positioned(
            left: offset,
            right: offset,
            top: i * 1.5,
            bottom: i * 1.5,
            child: Container(
              decoration: BoxDecoration(
                color: Color.lerp(
                  const Color(0xFFFAF6EF),
                  const Color(0xFFE5DDD0),
                  i / 12,
                ),
                borderRadius: BorderRadius.circular(3),
                boxShadow: i == 0 ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
            ),
          );
        }),
        
        // Tranche gauche (reliure bleue)
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 18,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A5F), Color(0xFF2A4A6F), Color(0xFF1E3A5F)],
              ),
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(3, 0),
                ),
              ],
            ),
            child: CustomPaint(painter: SpineStitchPainter()),
          ),
        ),
        
        // Tranche droite (pages)
        Positioned(
          right: 0,
          top: 10,
          bottom: 10,
          width: 25,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE8E0D5), Color(0xFFF5EFE6), Color(0xFFE8E0D5)],
              ),
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(3)),
            ),
            child: CustomPaint(painter: ThickPageEdgePainter()),
          ),
        ),
        
        // Tranche du haut
        Positioned(
          left: 20,
          right: 25,
          top: 0,
          height: 15,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0xFFF5EFE6), Color(0xFFE0D5C8)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(2)),
            ),
          ),
        ),
        
        // Tranche du bas
        Positioned(
          left: 20,
          right: 25,
          bottom: 0,
          height: 18,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF5EFE6), Color(0xFFD5C8B8)],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(2)),
            ),
            child: CustomPaint(painter: BottomPageEdgePainter()),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentSpread(double w, double h) {
    final pageW = (w - 40) / 2; // -40 pour reliure + marges
    
    return Positioned(
      left: 18,
      right: 25,
      top: 15,
      bottom: 18,
      child: Row(
        children: [
          // Page gauche
          Expanded(child: _buildPage(_getPageData(_currentPage * 2), isLeft: true)),
          
          // Reliure centrale 3D
          _buildCentralSpine(h - 33),
          
          // Page droite
          Expanded(child: _buildPage(_getPageData(_currentPage * 2 + 1), isLeft: false)),
        ],
      ),
    );
  }

  Widget _buildCentralSpine(double h) {
    return Container(
      width: 22,
      height: h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFD5C8B8),
            const Color(0xFFF0E8DB),
            Colors.white.withOpacity(0.95),
            const Color(0xFFF0E8DB),
            const Color(0xFFD5C8B8),
          ],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6, offset: const Offset(-3, 0)),
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6, offset: const Offset(3, 0)),
        ],
      ),
      child: CustomPaint(painter: SpineStitchPainter()),
    );
  }

  // PAGE QUI SE PLIE VRAIMENT
  Widget _buildRealCurlingPage(double w, double h) {
    final pageW = (w - 40) / 2;
    final progress = _dragProgress.abs().clamp(0.0, 1.0);
    final goingNext = _dragProgress < 0;
    
    // Intensité du curl basée sur le progrès
    final curlIntensity = math.sin(progress * math.pi) * 0.6;
    final rotationAngle = progress * math.pi;
    
    return Positioned(
      left: goingNext ? pageW + 40 : 18,
      top: 15,
      width: pageW,
      height: h - 33,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Ombre de la page qui se tourne
          Positioned(
            left: goingNext ? -30 : null,
            right: goingNext ? null : -30,
            top: 10,
            bottom: 10,
            width: 60,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4 * progress),
                    blurRadius: 30 * progress,
                    spreadRadius: 5 * progress,
                  ),
                ],
              ),
            ),
          ),
          
          // Page avec transformation 3D
          Transform(
            alignment: goingNext ? Alignment.centerLeft : Alignment.centerRight,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateY(goingNext ? -rotationAngle : rotationAngle),
            child: Stack(
              children: [
                // La page elle-même avec effet de courbure
                ClipPath(
                  clipper: RealPageCurlClipper(
                    curlAmount: curlIntensity,
                    fromRight: goingNext,
                  ),
                  child: Container(
                    width: pageW,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: goingNext ? Alignment.centerRight : Alignment.centerLeft,
                        end: goingNext ? Alignment.centerLeft : Alignment.centerRight,
                        colors: const [
                          Color(0xFFFCF9F4),
                          Color(0xFFF8F4ED),
                          Color(0xFFF4EFE6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: progress < 0.5
                        ? _buildPage(
                            _getPageData(goingNext ? _currentPage * 2 + 1 : _currentPage * 2),
                            isLeft: !goingNext,
                          )
                        : Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..rotateY(math.pi),
                            child: _buildPage(
                              _getPageData(goingNext 
                                  ? (_currentPage + 1) * 2 
                                  : (_currentPage - 1) * 2 + 1),
                              isLeft: goingNext,
                            ),
                          ),
                  ),
                ),
                
                // Effet de pliure - gradient sombre
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: PageFoldShadowPainter(
                        progress: progress,
                        curlIntensity: curlIntensity,
                        fromRight: goingNext,
                      ),
                    ),
                  ),
                ),
                
                // Highlight brillant sur le pli
                Positioned(
                  left: goingNext ? 0 : null,
                  right: goingNext ? null : 0,
                  top: 0,
                  bottom: 0,
                  width: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.5 * curlIntensity),
                          Colors.white.withOpacity(0.2 * curlIntensity),
                          Colors.white.withOpacity(0.5 * curlIntensity),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Coin de page courbé visible
          if (curlIntensity > 0.1)
            Positioned(
              right: goingNext ? null : -5,
              left: goingNext ? -5 : null,
              bottom: 0,
              child: Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(goingNext ? -0.3 : 0.3),
                child: CustomPaint(
                  size: Size(70 * curlIntensity, 70 * curlIntensity),
                  painter: CurledCornerPainter(
                    intensity: curlIntensity,
                    fromRight: !goingNext,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPage(PageData data, {required bool isLeft}) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFCF9F4),
            Color(0xFFF8F4ED),
            Color(0xFFF4EFE6),
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: isLeft ? const Radius.circular(2) : Radius.zero,
          bottomLeft: isLeft ? const Radius.circular(2) : Radius.zero,
          topRight: !isLeft ? const Radius.circular(2) : Radius.zero,
          bottomRight: !isLeft ? const Radius.circular(2) : Radius.zero,
        ),
      ),
      child: Stack(
        children: [
          // Grain papier
          CustomPaint(size: Size.infinite, painter: PaperGrainPainter()),
          
          // Lignes
          CustomPaint(size: Size.infinite, painter: NotebookLinesPainter(isLeft: isLeft)),
          
          // Contenu
          Padding(
            padding: EdgeInsets.only(
              left: isLeft ? 20 : 12,
              right: isLeft ? 12 : 20,
              top: 18,
              bottom: 14,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2C3E50),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Container(height: 0.5, width: 35, color: const Color(0xFF2C3E50).withOpacity(0.25)),
                const SizedBox(height: 14),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(children: data.entries),
                  ),
                ),
                Align(
                  alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
                  child: Text(
                    '${data.pageNumber}',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 11,
                      color: const Color(0xFF8B7355).withOpacity(0.4),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '← glissez',
          style: GoogleFonts.inter(fontSize: 9, color: Colors.white.withOpacity(0.25)),
        ),
        const SizedBox(width: 15),
        ...List.generate(_totalPages, (i) {
          final isActive = i == _currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 22 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive 
                  ? const Color(0xFFD4AF37).withOpacity(0.9)
                  : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
        const SizedBox(width: 15),
        Text(
          'glissez →',
          style: GoogleFonts.inter(fontSize: 9, color: Colors.white.withOpacity(0.25)),
        ),
      ],
    );
  }

  // ============ GESTION DU SWIPE ============
  
  void _onDragStart(DragStartDetails d) {
    if (_isAnimating) return;
    _cornerHintController.stop();
    setState(() {
      _isDragging = true;
    });
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_isAnimating) return;
    
    final screenW = MediaQuery.of(context).size.width;
    final delta = d.delta.dx / (screenW * 0.4);
    
    setState(() {
      _dragProgress += delta;
      
      // Résistance aux bords
      if (_dragProgress < 0 && _currentPage >= _totalPages - 1) {
        _dragProgress = _dragProgress * 0.2;
      }
      if (_dragProgress > 0 && _currentPage <= 0) {
        _dragProgress = _dragProgress * 0.2;
      }
      
      _dragProgress = _dragProgress.clamp(-1.3, 1.3);
      _dragDirection = _dragProgress < 0 ? -1 : 1;
    });
  }

  void _onDragEnd(DragEndDetails d) {
    if (_isAnimating) return;
    
    final vel = d.velocity.pixelsPerSecond.dx;
    final shouldFlip = _dragProgress.abs() > 0.2 || vel.abs() > 400;
    
    if (shouldFlip && _dragProgress.abs() > 0.08) {
      _animatePageFlip(_dragDirection < 0);
    } else {
      _animateBack();
    }
  }

  void _animatePageFlip(bool next) {
    final targetPage = next 
        ? (_currentPage + 1).clamp(0, _totalPages - 1)
        : (_currentPage - 1).clamp(0, _totalPages - 1);
    
    if (targetPage == _currentPage) {
      _animateBack();
      return;
    }
    
    setState(() => _isAnimating = true);
    
    final start = _dragProgress;
    final end = next ? -1.0 : 1.0;
    
    _pageController.reset();
    
    final animation = Tween<double>(begin: start, end: end).animate(
      CurvedAnimation(parent: _pageController, curve: Curves.easeOutCubic),
    );
    
    animation.addListener(() => setState(() => _dragProgress = animation.value));
    
    _pageController.forward().then((_) {
      setState(() {
        _currentPage = targetPage;
        _dragProgress = 0;
        _isDragging = false;
        _isAnimating = false;
      });
      _cornerHintController.repeat(reverse: true);
    });
  }

  void _animateBack() {
    setState(() => _isAnimating = true);
    
    _pageController.reset();
    
    final animation = Tween<double>(begin: _dragProgress, end: 0.0).animate(
      CurvedAnimation(parent: _pageController, curve: Curves.elasticOut),
    );
    
    animation.addListener(() => setState(() => _dragProgress = animation.value));
    
    _pageController.forward().then((_) {
      setState(() {
        _dragProgress = 0;
        _isDragging = false;
        _isAnimating = false;
      });
      _cornerHintController.repeat(reverse: true);
    });
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Fermer le carnet',
            style: GoogleFonts.cormorantGaramond(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w600)),
        content: Text('Voulez-vous vous déconnecter ?',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await CompleteAuthService.instance.logout();
              if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/welcome', (r) => false);
            },
            child: Text('Déconnecter', style: GoogleFonts.inter(color: const Color(0xFFD4AF37))),
          ),
        ],
      ),
    );
  }

  // ============ DONNÉES ============
  
  PageData _getPageData(int index) {
    final pages = [
      PageData(title: 'Partage du jour', pageNumber: 1, entries: [
        _buildEntry('emotions.png', 'Émotions du jour', 'Identifie ce que tu ressens ici et maintenant', '/daily-mood'),
        const SizedBox(height: 14),
        _buildEntry('pensee.png', 'Pensée du jour', 'Exprime tes pensées pour y voir clair', '/main'),
      ]),
      PageData(title: 'Mon parcours', pageNumber: 2, entries: [
        _buildEntry('emotions.png', 'Historique des émotions', 'Mes émotions dans le temps', '/emotion-timeline'),
        const SizedBox(height: 14),
        _buildEntry('historique_des_pensees.png', 'Historique des pensées', 'Mes pensées dans le temps', '/history'),
      ]),
      PageData(title: 'Ce qui me ressemble', pageNumber: 3, entries: [
        _buildEntry('profil.png', 'Je suis', 'Pour avoir des éclairages qui me correspondent', '/profile'),
        const SizedBox(height: 14),
        _buildEntry('categorie_spirituelles.png', 'Spiritualités', 'Mes choix pour des éclairages selon mes croyances', '/sources-spirituelles'),
      ]),
      PageData(title: 'Je trouve des sources', pageNumber: 4, entries: [
        _buildDiscoveryEntry(Icons.quiz_outlined, 'Quiz', 'Découvre tes affinités', () => Navigator.pushNamed(context, '/orientation')),
        const SizedBox(height: 10),
        _buildDiscoveryEntry(Icons.casino_outlined, 'Roue', 'Laisse le hasard te guider', () async {
          final s = await SlotMachineDialog.show(context);
          if (s != null && s.isNotEmpty && mounted) Navigator.pushNamed(context, '/main', arguments: {'randomSources': s});
        }),
        const SizedBox(height: 10),
        _buildDiscoveryEntry(Icons.signpost_outlined, 'Panneaux', 'Choisis ta direction', () async {
          final s = await CrossroadsDialog.show(context);
          if (s != null && s.isNotEmpty && mounted) Navigator.pushNamed(context, '/main', arguments: {'randomSources': s});
        }),
      ]),
      PageData(title: 'Je choisis mes sources', pageNumber: 5, entries: [
        _buildEntry('categorie_psychologiques.png', 'Psychologie', 'Approches thérapeutiques', '/sources-psychologiques'),
        const SizedBox(height: 14),
        _buildEntry('categorie_litteraires.png', 'Littérature', 'Courants littéraires', '/sources-litteraires'),
      ]),
      PageData(title: 'Je choisis mes sources', pageNumber: 6, entries: [
        _buildEntry('philosophie.png', 'Philosophie', 'Écoles de pensée', '/sources-philosophiques'),
        const SizedBox(height: 14),
        _buildEntry('philosophes.png', 'Philosophes', 'Grands penseurs', '/sources-philosophes'),
      ]),
      PageData(title: 'Pensée', pageNumber: 7, entries: [_buildQuote()]),
      PageData(title: '', pageNumber: 8, entries: [const SizedBox.shrink()]),
      PageData(title: 'Notes', pageNumber: 9, entries: [const SizedBox.shrink()]),
      PageData(title: '', pageNumber: 10, entries: [const SizedBox.shrink()]),
    ];
    return pages[index.clamp(0, pages.length - 1)];
  }

  Widget _buildEntry(String icon, String title, String desc, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF2C3E50).withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset('assets/univers_visuel/$icon', fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(Icons.image_outlined, color: Colors.grey[400], size: 22)),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1E3A5F))),
                  const SizedBox(height: 2),
                  Text(desc, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF1E3A5F).withOpacity(0.55), height: 1.2)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: const Color(0xFF1E3A5F).withOpacity(0.25), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoveryEntry(IconData icon, String title, String desc, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [const Color(0xFF1E3A5F).withOpacity(0.06), const Color(0xFF1E3A5F).withOpacity(0.02)]),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF1E3A5F).withOpacity(0.12)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: const Color(0xFF1E3A5F).withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: const Color(0xFF1E3A5F), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1E3A5F))),
                  Text(desc, style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF1E3A5F).withOpacity(0.5))),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 12, color: const Color(0xFF1E3A5F).withOpacity(0.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuote() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Column(
        children: [
          Icon(Icons.format_quote, size: 28, color: const Color(0xFF8B7355).withOpacity(0.25)),
          const SizedBox(height: 12),
          Text(
            'Le véritable voyage de découverte ne consiste pas à chercher de nouveaux paysages, mais à avoir de nouveaux yeux.',
            style: GoogleFonts.cormorantGaramond(fontSize: 16, fontStyle: FontStyle.italic, color: const Color(0xFF5D4E37), height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          Text('— Marcel Proust', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF8B7355), letterSpacing: 1)),
        ],
      ),
    );
  }
}

class PageData {
  final String title;
  final int pageNumber;
  final List<Widget> entries;
  PageData({required this.title, required this.pageNumber, required this.entries});
}

// ============ PAINTERS ============

class MatteTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = math.Random(42);
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 1000; i++) {
      paint.color = (r.nextBool() ? Colors.white : Colors.black).withOpacity(r.nextDouble() * 0.012);
      canvas.drawCircle(Offset(r.nextDouble() * size.width, r.nextDouble() * size.height), r.nextDouble() * 1.2, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ThickPageEdgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 0.6;
    final r = math.Random(456);
    for (double y = 1; y < size.height - 1; y += 1.2) {
      final irregularity = r.nextDouble() * 1.5 - 0.75;
      paint.color = Color.lerp(const Color(0xFFDDD5C8), const Color(0xFFF0E8DB), r.nextDouble())!;
      canvas.drawLine(Offset(irregularity, y), Offset(size.width + irregularity * 0.5, y), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BottomPageEdgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 0.5;
    final r = math.Random(789);
    for (double x = 2; x < size.width - 2; x += 1.0) {
      paint.color = Color.lerp(const Color(0xFFD5C8B8), const Color(0xFFE8E0D5), r.nextDouble())!;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SpineStitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFBBB0A0)..strokeWidth = 1.5..strokeCap = StrokeCap.round;
    for (double y = 12; y < size.height - 12; y += 16) {
      canvas.drawLine(Offset(size.width / 2, y - 3), Offset(size.width / 2, y + 3), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PaperGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = math.Random(321);
    final paint = Paint();
    for (int i = 0; i < 400; i++) {
      paint.color = const Color(0xFF8B7355).withOpacity(r.nextDouble() * 0.015);
      canvas.drawCircle(Offset(r.nextDouble() * size.width, r.nextDouble() * size.height), r.nextDouble() * 0.6, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class NotebookLinesPainter extends CustomPainter {
  final bool isLeft;
  NotebookLinesPainter({this.isLeft = true});
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()..color = const Color(0xFFD4C4B0).withOpacity(0.35)..strokeWidth = 0.4;
    for (double y = 50; y < size.height - 20; y += 20) {
      canvas.drawLine(Offset(isLeft ? 18 : 10, y), Offset(size.width - (isLeft ? 10 : 18), y), linePaint);
    }
    final marginPaint = Paint()..color = const Color(0xFFCBB89D).withOpacity(0.25)..strokeWidth = 0.4;
    final mx = isLeft ? 16.0 : size.width - 16.0;
    canvas.drawLine(Offset(mx, 0), Offset(mx, size.height), marginPaint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PageCornerPainter extends CustomPainter {
  final double lift;
  PageCornerPainter({required this.lift});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF8F4ED), Color(0xFFE8E0D5)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.7, size.width * 0.5, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.7, size.height * 0.3, size.width, 0)
      ..close();
    
    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class RealPageCurlClipper extends CustomClipper<Path> {
  final double curlAmount;
  final bool fromRight;
  RealPageCurlClipper({required this.curlAmount, required this.fromRight});

  @override
  Path getClip(Size size) {
    final path = Path();
    final curl = curlAmount * size.width * 0.25;
    
    if (fromRight) {
      path.moveTo(0, 0);
      path.lineTo(size.width - curl, 0);
      
      // Courbe supérieure
      path.quadraticBezierTo(
        size.width + curl * 0.3, size.height * 0.25,
        size.width - curl * 0.5, size.height * 0.5,
      );
      
      // Courbe inférieure
      path.quadraticBezierTo(
        size.width + curl * 0.3, size.height * 0.75,
        size.width - curl, size.height,
      );
      
      path.lineTo(0, size.height);
    } else {
      path.moveTo(curl, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(curl, size.height);
      
      path.quadraticBezierTo(
        -curl * 0.3, size.height * 0.75,
        curl * 0.5, size.height * 0.5,
      );
      path.quadraticBezierTo(
        -curl * 0.3, size.height * 0.25,
        curl, 0,
      );
    }
    
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

class PageFoldShadowPainter extends CustomPainter {
  final double progress;
  final double curlIntensity;
  final bool fromRight;
  
  PageFoldShadowPainter({required this.progress, required this.curlIntensity, required this.fromRight});

  @override
  void paint(Canvas canvas, Size size) {
    final gradientWidth = 80 + (curlIntensity * 120);
    
    final gradient = LinearGradient(
      begin: fromRight ? Alignment.centerLeft : Alignment.centerRight,
      end: fromRight ? Alignment.centerRight : Alignment.centerLeft,
      colors: [
        Colors.black.withOpacity(0.3 * progress),
        Colors.black.withOpacity(0.1 * progress),
        Colors.transparent,
      ],
      stops: const [0.0, 0.4, 1.0],
    );
    
    final rect = fromRight
        ? Rect.fromLTWH(0, 0, gradientWidth, size.height)
        : Rect.fromLTWH(size.width - gradientWidth, 0, gradientWidth, size.height);
    
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CurledCornerPainter extends CustomPainter {
  final double intensity;
  final bool fromRight;
  
  CurledCornerPainter({required this.intensity, required this.fromRight});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: fromRight ? Alignment.topLeft : Alignment.topRight,
        end: fromRight ? Alignment.bottomRight : Alignment.bottomLeft,
        colors: const [Color(0xFFF8F4ED), Color(0xFFE0D5C8), Color(0xFFD5C8B8)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    
    final path = Path();
    if (fromRight) {
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.quadraticBezierTo(size.width * 0.4, size.height * 0.6, size.width, 0);
    } else {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.quadraticBezierTo(size.width * 0.6, size.height * 0.6, 0, 0);
    }
    path.close();
    
    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, paint);
    
    // Ligne de pli
    final foldPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 1;
    
    if (fromRight) {
      canvas.drawLine(Offset(size.width * 0.7, size.height * 0.3), Offset(size.width * 0.3, size.height * 0.9), foldPaint);
    } else {
      canvas.drawLine(Offset(size.width * 0.3, size.height * 0.3), Offset(size.width * 0.7, size.height * 0.9), foldPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
