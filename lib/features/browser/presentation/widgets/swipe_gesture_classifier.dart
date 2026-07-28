import 'package:flutter/material.dart';

enum SwipeDirection { back, forward, none }

class SwipeGestureClassifier {
  static const double navigationSwipeThreshold = 150.0;

  static SwipeDirection classify({
    required Offset startPosition,
    required Offset endPosition,
  }) {
    final dx = endPosition.dx - startPosition.dx;
    final dy = endPosition.dy - startPosition.dy;

    // Check if horizontal is dominant: horizontal delta must be at least twice the vertical delta
    if (dx.abs() <= dy.abs() * 2) {
      return SwipeDirection.none;
    }

    if (dx.abs() < navigationSwipeThreshold) {
      return SwipeDirection.none;
    }

    if (dx > 0) {
      return SwipeDirection.back; // Swipe Right -> Back
    } else {
      return SwipeDirection.forward; // Swipe Left -> Forward
    }
  }
}
