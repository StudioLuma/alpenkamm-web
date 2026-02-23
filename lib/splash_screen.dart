import 'package:flutter/material.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _fadeController.forward();

    // ⭐ FIX: Navigation erst NACH vollständiger Web‑Initialisierung
    Future.microtask(() async {
      await Future.delayed(const Duration(milliseconds: 300)); // Web stabilisieren

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    });
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
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ClipOval(
            child: Image.asset(
              "assets/alpenkamm_color.jpg",
              width: 180,
              height: 180,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}