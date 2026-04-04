class Payment {
  final String id;
  final double amount;
  final String paymentType;
  final String status;
  final String? gatewayRef;
  final String createdAt;
  final String? paidAt;

  Payment({
    required this.id,
    required this.amount,
    required this.paymentType,
    required this.status,
    this.gatewayRef,
    required this.createdAt,
    this.paidAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id'] ?? '',
        amount: (json['amount'] ?? 0).toDouble(),
        paymentType: json['payment_type'] ?? '',
        status: json['status'] ?? 'pending',
        gatewayRef: json['gateway_ref'],
        createdAt: json['created_at'] ?? '',
        paidAt: json['paid_at'],
      );

  String get statusLabel {
    switch (status) {
      case 'pending': return 'Pending';
      case 'completed': return 'Completed';
      case 'failed': return 'Failed';
      case 'refunded': return 'Refunded';
      default: return status;
    }
  }
}
