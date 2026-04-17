/// Modello per la risposta di un Stripe Connect Marketplace Refund
/// Rappresenta il risultato di un rimborso gestito completamente da Stripe
class StripeRefund {
  final String id;
  final String object;
  final int amount;
  final String currency;
  final String paymentIntent;
  final String charge;
  final String status;
  final String? reason;
  final int created;

  StripeRefund({
    required this.id,
    required this.object,
    required this.amount,
    required this.currency,
    required this.paymentIntent,
    required this.charge,
    required this.status,
    this.reason,
    required this.created,
  });

  factory StripeRefund.fromJson(Map<String, dynamic> json) {
    return StripeRefund(
      id: json['id'] ?? '',
      object: json['object'] ?? 'refund',
      amount: json['amount'] ?? 0,
      currency: json['currency'] ?? 'eur',
      paymentIntent: json['payment_intent'] ?? '',
      charge: json['charge'] ?? '',
      status: json['status'] ?? 'pending',
      reason: json['reason'],
      created: json['created'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'object': object,
      'amount': amount,
      'currency': currency,
      'payment_intent': paymentIntent,
      'charge': charge,
      'status': status,
      'reason': reason,
      'created': created,
    };
  }

  /// Converte l'amount (in centesimi) in formato decimale
  double get amountDecimal => amount / 100.0;

  /// Formatta l'importo con il simbolo della valuta
  String get formattedAmount {
    final symbol = _getCurrencySymbol(currency);
    return '$symbol${amountDecimal.toStringAsFixed(2)}';
  }

  /// Verifica se il rimborso è completato con successo
  bool get isSuccessful => status == 'succeeded';

  /// Verifica se il rimborso è in attesa
  bool get isPending => status == 'pending';

  /// Verifica se il rimborso è fallito
  bool get isFailed => status == 'failed' || status == 'canceled';

  /// Ottiene il simbolo della valuta
  String _getCurrencySymbol(String currency) {
    switch (currency.toLowerCase()) {
      case 'eur':
        return '€';
      case 'usd':
        return '\$';
      case 'gbp':
        return '£';
      default:
        return currency.toUpperCase();
    }
  }

  /// Ottiene una descrizione user-friendly dello stato
  String get statusDescription {
    switch (status) {
      case 'succeeded':
        return 'Completato';
      case 'pending':
        return 'In elaborazione';
      case 'failed':
        return 'Fallito';
      case 'canceled':
        return 'Annullato';
      default:
        return 'Sconosciuto';
    }
  }

  /// Ottiene una descrizione user-friendly del motivo
  String get reasonDescription {
    if (reason == null) return 'Non specificato';

    switch (reason) {
      case 'requested_by_customer':
        return 'Richiesto dal cliente';
      case 'duplicate':
        return 'Pagamento duplicato';
      case 'fraudulent':
        return 'Transazione fraudolenta';
      default:
        return reason!;
    }
  }

  /// Converte il timestamp Unix in DateTime
  DateTime get createdDate => DateTime.fromMillisecondsSinceEpoch(created * 1000);

  @override
  String toString() {
    return 'StripeRefund(id: $id, amount: $formattedAmount, status: $statusDescription)';
  }
}

/// Wrapper per la risposta dell'API di refund
class StripeRefundResponse {
  final bool success;
  final StripeRefund refund;
  final String? error;

  StripeRefundResponse({
    required this.success,
    required this.refund,
    this.error,
  });

  factory StripeRefundResponse.fromJson(Map<String, dynamic> json) {
    return StripeRefundResponse(
      success: json['success'] ?? false,
      refund: StripeRefund.fromJson(json['refund'] ?? {}),
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'refund': refund.toJson(),
      'error': error,
    };
  }
}
