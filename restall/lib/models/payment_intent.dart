class PaymentIntent {
  final String id;
  final String clientSecret;
  final int amount;
  final String currency;
  final String status;

  PaymentIntent({
    required this.id,
    required this.clientSecret,
    required this.amount,
    required this.currency,
    required this.status,
  });

  factory PaymentIntent.fromJson(Map<String, dynamic> json) {
    return PaymentIntent(
      id: json['id'] ?? '',
      clientSecret: json['client_secret'] ?? '',
      amount: json['amount'] ?? 0,
      currency: json['currency'] ?? 'eur',
      status: json['status'] ?? '',
    );
  }
}
