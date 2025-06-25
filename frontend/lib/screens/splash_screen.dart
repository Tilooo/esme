// lib/screens/splash_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/screens/map_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Setup the fade-in animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward(); // Start the animation

    // Setup the timer to navigate to the map screen
    Timer(const Duration(seconds: 3), () {
      // Use pushReplacement so the user can't press "back" to the splash screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MapScreen()),
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use theme's background color for a seamless look
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        // The FadeTransition widget handles the animation
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // A nice, big map icon
              Icon(
                Icons.map_outlined,
                size: 100.0,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              // Esme app's name
              Text(
                'ESME',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}