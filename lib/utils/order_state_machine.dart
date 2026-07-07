class OrderStateMachine {
  // Order Status Constants
  static const String statusPending = 'pending';
  static const String statusConfirmed = 'confirmed';
  static const String statusPreparing = 'preparing';
  static const String statusShipped = 'shipped';
  static const String statusDelivered = 'delivered';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

  /// Returns true if transition from [currentStatus] to [newStatus] is allowed.
  static bool isValidTransition(String currentStatus, String newStatus) {
    final current = currentStatus.toLowerCase().trim();
    final next = newStatus.toLowerCase().trim();

    if (current == next) return true;

    switch (current) {
      case statusPending:
        return next == statusConfirmed || next == statusCancelled;
      case statusConfirmed:
        return next == statusPreparing || next == statusCancelled;
      case statusPreparing:
        return next == statusShipped || next == statusCancelled;
      case statusShipped:
        return next == statusDelivered || next == statusCompleted;
      case statusDelivered:
        return next == statusCompleted;
      case statusCompleted:
      case statusCancelled:
        // Terminal states cannot transition to any other status
        return false;
      default:
        return false;
    }
  }

  /// Calculates the total cost of an order line item.
  static double calculateTotal(double quantity, double price) {
    if (quantity <= 0 || price <= 0) return 0.0;
    return double.parse((quantity * price).toStringAsFixed(2));
  }

  /// Validates price input.
  static bool isValidPrice(double price) {
    return price > 0.0 && price <= 1000000.0;
  }

  /// Validates quantity input.
  static bool isValidQuantity(double quantity) {
    return quantity > 0.0 && quantity <= 10000.0;
  }
}
