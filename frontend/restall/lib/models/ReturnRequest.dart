import 'package:intl/intl.dart';

class ReturnRequest {
  final String id;
  final String orderId;
  final String status;
  final String reason;
  final String amount;
  final String createdAt;

  ReturnRequest({
    required this.id,
    required this.orderId,
    required this.status,
    required this.reason,
    required this.amount,
    required this.createdAt,
  });

  String get formattedDate {
    try {
      final dt = DateTime.parse(createdAt);
      return DateFormat('dd/MM/yyyy - HH:mm', 'it_IT').format(dt);
    } catch (e) {
      return createdAt;
    }
  }

  String get formattedAmount {
    try {
      final a = double.parse(amount);
      return NumberFormat.currency(locale: 'it_IT', symbol: '€').format(a);
    } catch (e) {
      return '€$amount';
    }
  }

  factory ReturnRequest.fromJson(Map<String, dynamic> json) {
    return ReturnRequest(
      id: json['id']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? json['order']?.toString() ?? '',
      status: json['status'] ?? 'unknown',
      reason: json['reason'] ?? json['return_reason'] ?? '',
      amount: json['amount']?.toString() ?? json['total']?.toString() ?? '0.00',
      createdAt: json['created_at'] ?? json['date_created'] ?? '',
    );
  }
}
