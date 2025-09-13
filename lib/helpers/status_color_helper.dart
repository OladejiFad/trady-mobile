import 'package:flutter/material.dart';

class StatusColorHelper {
  // Shipment (delivery) status
  static Color shipmentColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'processing':
        return Colors.orange;
      case 'out for delivery':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  static String shipmentLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case 'processing':
        return 'Processing';
      case 'out for delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      default:
        return 'Pending';
    }
  }

  // Satisfaction status
  static Color satisfactionColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'satisfied ❤':
        return Colors.green;
      case 'i like it 💛':
        return Colors.amber;
      case 'refund':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

 static String satisfactionLabel(String status) {
  switch (status.trim().toLowerCase()) {
    case 'satisfied ❤':
      return '❤ Satisfied';
    case 'i like it 💛':
      return '💛 I Like It';
    case 'refund':
      return '🙁 Refund';
    default:
      return '🙂 Not Rated';
  }
}


  // Payment status
  static Color paymentColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'success':
        return Colors.green;
      case 'refund':
        return Colors.red;
      case 'with BuyNest':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  static String paymentLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case 'success':
        return 'Paid';
      case 'refund':
        return 'Refunded';
      case 'with BuyNest':
        return 'With BuyNest';
      default:
        return 'Pending';
    }
  }

  // Order status
  static Color orderStatusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'success':
        return Colors.green;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static String orderStatusLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case 'success':
        return 'Completed';
      case 'failed':
        return 'Failed';
      default:
        return 'Pending';
    }
  }
}
