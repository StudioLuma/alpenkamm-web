import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';

import 'qr_scan_web.dart';

class BonusScreen extends StatefulWidget {
  final String username;
  final String salon;
  final String userId;

  const BonusScreen({
    super.key,
    required this.username,
    required this.salon,
    required this.userId,
  });

  @override
  State<BonusScreen> createState() => _BonusScreenState();
}

class _BonusScreenState extends State<BonusScreen>
    with TickerProviderStateMixin {
  int bonusPoints = 0;

  late ConfettiController _confettiController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  void vibrate() {
    if (!kIsWeb) {
      HapticFeedback.mediumImpact();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadBonusPointsFromFirestore();

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      lowerBound: 0.0,
      upperBound: 0.12,
    );

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadBonusPointsFromFirestore() async {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.userId)
        .get();

    if (doc.exists) {
      setState(() {
        bonusPoints = doc["bonusPoints"] ?? 0;
      });

      if (bonusPoints == 10) {
        _triggerPulse();
      }
    }
  }

  Future<void> _saveBonusPointsToFirestore() async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.userId)
        .update({
      "bonusPoints": bonusPoints,
    });
  }

  void _triggerPulse() {
    _pulseController.forward().then((_) {
      _pulseController.reverse();
    });
  }

  bool isValidBonusCode(String code) {
    if (widget.salon == "Studio Luma" && code == "LUMA_BONUS") {
      return true;
    }

    if (widget.salon == "Alpenkamm" && code == "ALPENKAMM_BONUS") {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    const beige = Color(0xFFE3D6C7);

    final Color salonColor = widget.salon == "Studio Luma"
        ? const Color(0xFF7A1F33)
        : const Color(0xFF556B2F);

    String activeLogo = widget.salon == "Studio Luma"
        ? 'assets/luma_color.png'
        : 'assets/alpenkamm_color.jpg';

    String inactiveLogo = widget.salon == "Studio Luma"
        ? 'assets/luma_gray.png'
        : 'assets/alpenkamm_gray.jpg';

    return Scaffold(
      backgroundColor: beige,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.salon,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 10),

                      Text(
                        widget.username,
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 40),

                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          final scale = bonusPoints == 10
                              ? 1 + _pulseAnimation.value
                              : 1.0;

                          return Transform.scale(
                            scale: scale,
                            child: child,
                          );
                        },
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 15,
                          runSpacing: 15,
                          children: List.generate(10, (index) {
                            bool isActive = index < bonusPoints;

                            return ClipOval(
                              child: Image.asset(
                                isActive ? activeLogo : inactiveLogo,
                                width: 55,
                                height: 55,
                                fit: BoxFit.cover,
                              ),
                            );
                          }),
                        ),
                      ),

                      const SizedBox(height: 40),

                      Text(
                        bonusPoints == 10
                            ? "Glückwunsch 🥳 deine Bonuskarte ist voll. Zeige sie beim nächsten Besuch vor und erhalte 15% auf die Dienstleistung."
                            : "Bei 10 Punkten erhältst du 15% Rabatt auf die nächste Dienstleistung",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: bonusPoints == 10
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 40),

                      _AnimatedButton(
                        title: "Punkte hinzufügen",
                        color: Colors.black87,
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QRScanWebPage(
                                username: widget.username,
                                salonName: widget.salon,
                              ),
                            ),
                          );

                          if (!mounted) return;

                          if (result != null) {
                            if (isValidBonusCode(result)) {
                              setState(() {
                                if (bonusPoints < 10) {
                                  bonusPoints++;
                                } else {
                                  bonusPoints = 1;
                                }
                              });

                              await _saveBonusPointsToFirestore();

                              _confettiController.play();
                              vibrate();

                              if (bonusPoints == 10) {
                                _triggerPulse();
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Ungültiger QR‑Code"),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        },
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),

            IgnorePointer(
              ignoring: true,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  colors: [
                    salonColor,
                    Colors.white,
                    Colors.grey.shade300,
                  ],
                  numberOfParticles: 80,
                  emissionFrequency: 0.05,
                  gravity: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// SCALE BUTTON
// ---------------------------------------------------------
class _AnimatedButton extends StatefulWidget {
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _AnimatedButton({
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
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
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.20),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}