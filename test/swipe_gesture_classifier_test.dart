import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_browser/features/browser/presentation/widgets/swipe_gesture_classifier.dart';

void main() {
  group('SwipeGestureClassifier tests', () {
    test('large right swipe -> back', () {
      final direction = SwipeGestureClassifier.classify(
        startPosition: const Offset(10, 100),
        endPosition: const Offset(170, 100),
      );
      expect(direction, SwipeDirection.back);
    });

    test('large left swipe -> forward', () {
      final direction = SwipeGestureClassifier.classify(
        startPosition: const Offset(170, 100),
        endPosition: const Offset(10, 100),
      );
      expect(direction, SwipeDirection.forward);
    });

    test('small right movement -> nothing', () {
      final direction = SwipeGestureClassifier.classify(
        startPosition: const Offset(10, 100),
        endPosition: const Offset(50, 100),
      );
      expect(direction, SwipeDirection.none);
    });

    test('small left movement -> nothing', () {
      final direction = SwipeGestureClassifier.classify(
        startPosition: const Offset(50, 100),
        endPosition: const Offset(10, 100),
      );
      expect(direction, SwipeDirection.none);
    });

    test('vertical swipe -> nothing', () {
      final direction = SwipeGestureClassifier.classify(
        startPosition: const Offset(100, 10),
        endPosition: const Offset(100, 150),
      );
      expect(direction, SwipeDirection.none);
    });

    test('diagonal vertical-dominant swipe -> nothing', () {
      final direction = SwipeGestureClassifier.classify(
        startPosition: const Offset(10, 10),
        endPosition: const Offset(30, 150),
      );
      expect(direction, SwipeDirection.none);
    });
  });

  group('SwipeGestureClassifier.edgeSwipeFor', () {
    const width = 540.0;

    test('left edge start -> back', () {
      expect(
        SwipeGestureClassifier.edgeSwipeFor(const Offset(5, 300), width),
        SwipeDirection.back,
      );
    });

    test('right edge start -> forward', () {
      expect(
        SwipeGestureClassifier.edgeSwipeFor(const Offset(535, 300), width),
        SwipeDirection.forward,
      );
    });

    test('middle start -> none', () {
      expect(
        SwipeGestureClassifier.edgeSwipeFor(const Offset(270, 300), width),
        SwipeDirection.none,
      );
    });

    test('just inside the edge zone counts, just outside does not', () {
      const edge = SwipeGestureClassifier.edgeWidth;
      expect(
        SwipeGestureClassifier.edgeSwipeFor(const Offset(edge, 0), width),
        SwipeDirection.back,
      );
      expect(
        SwipeGestureClassifier.edgeSwipeFor(const Offset(edge + 1, 0), width),
        SwipeDirection.none,
      );
    });
  });
}
