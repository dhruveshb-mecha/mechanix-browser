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
}
