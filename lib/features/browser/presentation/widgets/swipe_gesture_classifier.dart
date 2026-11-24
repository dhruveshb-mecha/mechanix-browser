import 'package:flutter/material.dart';

enum SwipeDirection { back, forward, none }

class SwipeGestureClassifier {
  static const double navigationSwipeThreshold = 150.0;

  /// A back/forward swipe has to start this close to the screen edge
  /// (logical px), like the system back gesture, so swipes in the middle of a
  /// page are left alone.
  static const double edgeWidth = 24.0;

  /// The navigation a touch starting at [start] may perform in a view
  /// [viewWidth] wide: back from the left edge, forward from the right edge,
  /// none elsewhere.
  static SwipeDirection edgeSwipeFor(Offset start, double viewWidth) {
    if (start.dx <= edgeWidth) return SwipeDirection.back;
    if (start.dx >= viewWidth - edgeWidth) return SwipeDirection.forward;
    return SwipeDirection.none;
  }

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
