import 'package:flutter/material.dart';
import '../theme/app_themes.dart';
import 'dashboard_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  final AppThemeData theme;

  const SplashScreen({super.key, required this.theme});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardSelectionScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Scaffold(
      backgroundColor: t.background,
      body: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Smart Home Logo
              Container(
                width: 132, height: 132,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(36),
                  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF10243A), Color(0xFF07111F)]),
                  border: Border.all(color: t.primary.withOpacity(.45), width: 1.5),
                  boxShadow: [BoxShadow(color: t.primary.withOpacity(.22), blurRadius: 24, spreadRadius: 2)],
                ),
                child: Stack(alignment: Alignment.center, children: [
                  Positioned(top: 12, child: Icon(Icons.wifi_rounded, size: 43, color: const Color(0xFF7CDE52))),
                  Padding(padding: const EdgeInsets.only(top: 20), child: Icon(Icons.home_rounded, size: 82, color: const Color(0xFF62C8F0))),
                  const Positioned(bottom: 25, child: Icon(Icons.eco_rounded, size: 27, color: Color(0xFF7CDE52))),
                ]),
              ),
              const SizedBox(height: 28),
              Text(
                'KHANJAN',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: t.text,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'IOT HOME',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: t.text.withOpacity(0.55),
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(t.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
