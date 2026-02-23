import 'package:flutter/material.dart';
import 'bonus_screen.dart';

class StudioSelectionScreen extends StatefulWidget {
  final String username;

  const StudioSelectionScreen({super.key, required this.username});

  @override
  State<StudioSelectionScreen> createState() => _StudioSelectionScreenState();
}

class _StudioSelectionScreenState extends State<StudioSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const beige = Color(0xFFE3D6C7);

    return Scaffold(
      backgroundColor: beige,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Salon auswählen",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // ⭐ Alpenkamm zuerst
                _StudioCard(
                  title: "Alpenkamm",
                  imagePath: "assets/alpenkamm_color.jpg",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BonusScreen(
                          username: widget.username,
                          salon: "Alpenkamm",
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 25),

                // ⭐ Studio Luma
                _StudioCard(
                  title: "Studio Luma",
                  imagePath: "assets/luma_color.png",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BonusScreen(
                          username: widget.username,
                          salon: "Studio Luma",
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ⭐ Studio-Karte mit Scale-Hover-Effekt + runden Logos
class _StudioCard extends StatefulWidget {
  final String title;
  final String imagePath;
  final VoidCallback onTap;

  const _StudioCard({
    required this.title,
    required this.imagePath,
    required this.onTap,
  });

  @override
  State<_StudioCard> createState() => _StudioCardState();
}

class _StudioCardState extends State<_StudioCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 0.08,
    );

    _scaleAnimation =
        CurvedAnimation(parent: _scaleController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _scaleController.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          final scale = 1 - _scaleAnimation.value;
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              // ⭐ Rundes Logo
              ClipOval(
                child: Image.asset(
                  widget.imagePath,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(width: 20),

              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}