import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WonderousAnimations {
  /// Standard duration constants
  static const Duration fast = Duration(milliseconds: 250);
  static const Duration normal = Duration(milliseconds: 450);
  static const Duration slow = Duration(milliseconds: 700);

  /// Curve constants matching Wonderous style
  static const Curve curveEnter = Curves.easeOutCubic;
  static const Curve curveExit = Curves.easeInCubic;
  static const Curve curveFluid = Curves.easeInOutCubic;

  /// Custom PageRoute with Wonderous-style subtle scale & smooth crossfade
  static Route<T> pageRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 500),
      reverseTransitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curveEnter,
          reverseCurve: curveExit,
        );

        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }
}

/// Extension methods for quick Wonderous-inspired animations on widgets
extension WonderousWidgetExtensions on Widget {
  /// Staggered card entrance: fade in + slight slide up + subtle scale
  Widget animateCardEntrance({int index = 0, int baseDelayMs = 80}) {
    return animate(delay: Duration(milliseconds: index * baseDelayMs))
        .fadeIn(duration: 400.ms, curve: Curves.easeOutCubic)
        .slideY(begin: 0.12, end: 0.0, duration: 500.ms, curve: Curves.easeOutCubic)
        .scaleXY(begin: 0.96, end: 1.0, duration: 450.ms, curve: Curves.easeOutCubic);
  }

  /// Header entrance: fade in + gentle slide down
  Widget animateHeaderEntrance({int delayMs = 0}) {
    return animate(delay: Duration(milliseconds: delayMs))
        .fadeIn(duration: 400.ms, curve: Curves.easeOutCubic)
        .slideY(begin: -0.15, end: 0.0, duration: 450.ms, curve: Curves.easeOutCubic);
  }

  /// Gentle breathing pulse (great for active status or live indicator)
  Widget animateBreathing({bool isPlaying = true}) {
    if (!isPlaying) return this;
    return animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 1.0, end: 1.05, duration: 1200.ms, curve: Curves.easeInOut);
  }

  /// Shimmer highlight effect
  Widget animateGlow({bool isPlaying = true}) {
    if (!isPlaying) return this;
    return animate(onPlay: (c) => c.repeat(reverse: true))
        .boxShadow(
          begin: const BoxShadow(color: Colors.transparent, blurRadius: 0),
          end: const BoxShadow(color: Color(0x556366F1), blurRadius: 20, spreadRadius: 4),
          duration: 1000.ms,
          curve: Curves.easeInOut,
        );
  }
}
