class RefundRequest {
  final int id;
  final int orderId;
  final double amount;
  final String reason;
  final String status; // pending, approved, declined, refunded
  final List<RefundLineItem> lineItems;
  final DateTime createdAt;
  final DateTime updatedAt;

  RefundRequest({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.reason,
    required this.status,
    required this.lineItems,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RefundRequest.fromJson(Map<String, dynamic> json) {
    return RefundRequest(
      id: json['id'] as int,
      orderId: json['order_id'] as int,
      amount: (json['amount'] is int)
          ? (json['amount'] as int).toDouble()
          : (json['amount'] as double),
      reason: json['reason'] as String,
      status: json['status'] as String,
      lineItems: (json['line_items'] as List<dynamic>?)
              ?.map((item) => RefundLineItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'amount': amount,
      'reason': reason,
      'status': status,
      'line_items': lineItems.map((item) => item.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper per verificare lo stato
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isDeclined => status == 'declined';
  bool get isRefunded => status == 'refunded';

  // Helper per status badge color
  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'In Attesa';
      case 'approved':
        return 'Approvato';
      case 'declined':
        return 'Rifiutato';
      case 'refunded':
        return 'Rimborsato';
      default:
        return status;
    }
  }
}

class RefundLineItem {
  final int id;
  final int quantity;

  RefundLineItem({
    required this.id,
    required this.quantity,
  });

  factory RefundLineItem.fromJson(Map<String, dynamic> json) {
    return RefundLineItem(
      id: json['id'] as int,
      quantity: json['quantity'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quantity': quantity,
    };
  }
}

// DTO per la creazione di una richiesta di reso
class CreateRefundRequestDto {
  final int orderId;
  final double amount;
  final String reason;
  final List<RefundLineItem> lineItems;

  CreateRefundRequestDto({
    required this.orderId,
    required this.amount,
    required this.reason,
    required this.lineItems,
  });

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'amount': amount,
      'reason': reason,
      'lineItems': lineItems.map((item) => item.toJson()).toList(),
    };
  }
}

// Response del rimborso completo
class RefundResult {
  final RefundRequest refundRequest;
  final StripeRefund? stripeRefund;
  final WcRefund? wcRefund;

  RefundResult({
    required this.refundRequest,
    this.stripeRefund,
    this.wcRefund,
  });

  factory RefundResult.fromJson(Map<String, dynamic> json) {
    return RefundResult(
      refundRequest: RefundRequest.fromJson(json['refundRequest'] as Map<String, dynamic>),
      stripeRefund: json['refundResult']?['stripeRefund'] != null
          ? StripeRefund.fromJson(json['refundResult']['stripeRefund'] as Map<String, dynamic>)
          : null,
      wcRefund: json['refundResult']?['wcRefund'] != null
          ? WcRefund.fromJson(json['refundResult']['wcRefund'] as Map<String, dynamic>)
          : null,
    );
  }
}

class StripeRefund {
  final String id;
  final String status;

  StripeRefund({
    required this.id,
    required this.status,
  });

  factory StripeRefund.fromJson(Map<String, dynamic> json) {
    return StripeRefund(
      id: json['id'] as String,
      status: json['status'] as String,
    );
  }
}

class WcRefund {
  final int id;
  final String amount;
  final String reason;

  WcRefund({
    required this.id,
    required this.amount,
    required this.reason,
  });

  factory WcRefund.fromJson(Map<String, dynamic> json) {
    return WcRefund(
      id: json['id'] as int,
      amount: json['amount'].toString(),
      reason: json['reason'] as String,
    );
  }
}
