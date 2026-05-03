import 'package:flutter/material.dart';

/// Smooth page transition animations
class PageTransitions {
  static PageRouteBuilder<T> _buildRoute<T>(Widget page, {Offset begin = const Offset(1.0, 0.0)}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideTween = Tween<Offset>(begin: begin, end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic));
        final fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );
        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: animation.drive(slideTween),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 500),
      reverseTransitionDuration: const Duration(milliseconds: 420),
    );
  }

  /// Slide from right to left (horizontal)
  static PageRouteBuilder slideFromRight(Widget page) {
    return _buildRoute(page);
  }

  static Future<T?> pushSmooth<T>(BuildContext context, Widget page) {
    return Navigator.of(context).push<T>(_buildRoute<T>(page));
  }

  static Future<T?> replaceSmooth<T>(BuildContext context, Widget page) {
    return Navigator.of(context).pushReplacement<T, T>(_buildRoute<T>(page));
  }

  /// Fade transition with slight scale
  static PageRouteBuilder fadeWithScale(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var scaleAnimation = Tween(begin: 0.95, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: scaleAnimation, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  /// Smooth vertical slide (bottom to top)
  static PageRouteBuilder slideFromBottom(Widget page) {
    return _buildRoute(page, begin: const Offset(0.0, 1.0));
  }
}
