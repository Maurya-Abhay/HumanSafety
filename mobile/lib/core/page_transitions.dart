import 'package:flutter/material.dart';

/// Smooth page transition animations
class PageTransitions {
  /// Slide from right to left (horizontal)
  static PageRouteBuilder slideFromRight(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
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
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }
}
