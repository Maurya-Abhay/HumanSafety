import 'package:flutter/material.dart';
import '../../core/routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shield_outlined,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            const Text(
              'HumanSafety',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your Safety, Our Priority',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
          ],
        ),
      ),
    );
  }
}
