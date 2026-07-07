import 'package:flutter_test/flutter_test.dart';
import 'package:agrimarketmob/utils/order_state_machine.dart';

void main() {
  group('OrderStateMachine Status Transition Tests', () {
    test('Allowed sequential seller transitions should return true', () {
      expect(OrderStateMachine.isValidTransition('pending', 'confirmed'), isTrue);
      expect(OrderStateMachine.isValidTransition('confirmed', 'preparing'), isTrue);
      expect(OrderStateMachine.isValidTransition('preparing', 'shipped'), isTrue);
      expect(OrderStateMachine.isValidTransition('shipped', 'delivered'), isTrue);
      expect(OrderStateMachine.isValidTransition('delivered', 'completed'), isTrue);
    });

    test('Allowed cancellation transitions should return true', () {
      expect(OrderStateMachine.isValidTransition('pending', 'cancelled'), isTrue);
      expect(OrderStateMachine.isValidTransition('confirmed', 'cancelled'), isTrue);
      expect(OrderStateMachine.isValidTransition('preparing', 'cancelled'), isTrue);
    });

    test('Forbidden transitions should return false', () {
      expect(OrderStateMachine.isValidTransition('shipped', 'cancelled'), isFalse);
      expect(OrderStateMachine.isValidTransition('delivered', 'cancelled'), isFalse);
      expect(OrderStateMachine.isValidTransition('cancelled', 'pending'), isFalse);
      expect(OrderStateMachine.isValidTransition('completed', 'confirmed'), isFalse);
      expect(OrderStateMachine.isValidTransition('pending', 'shipped'), isFalse);
    });

    test('Same status transitions should return true', () {
      expect(OrderStateMachine.isValidTransition('pending', 'pending'), isTrue);
      expect(OrderStateMachine.isValidTransition('confirmed', 'confirmed'), isTrue);
    });
  });

  group('OrderStateMachine Calculation & Validation Tests', () {
    test('calculateTotal should calculate correct values', () {
      expect(OrderStateMachine.calculateTotal(2.5, 10.0), equals(25.0));
      expect(OrderStateMachine.calculateTotal(3, 15.5), equals(46.5));
      expect(OrderStateMachine.calculateTotal(-1.0, 10), equals(0.0));
      expect(OrderStateMachine.calculateTotal(2, -5.0), equals(0.0));
    });

    test('isValidPrice should check bounds correctly', () {
      expect(OrderStateMachine.isValidPrice(10.0), isTrue);
      expect(OrderStateMachine.isValidPrice(-5.0), isFalse);
      expect(OrderStateMachine.isValidPrice(0.0), isFalse);
      expect(OrderStateMachine.isValidPrice(2000000.0), isFalse);
    });

    test('isValidQuantity should check bounds correctly', () {
      expect(OrderStateMachine.isValidQuantity(5.0), isTrue);
      expect(OrderStateMachine.isValidQuantity(-1.0), isFalse);
      expect(OrderStateMachine.isValidQuantity(0.0), isFalse);
      expect(OrderStateMachine.isValidQuantity(20000.0), isFalse);
    });
  });
}
