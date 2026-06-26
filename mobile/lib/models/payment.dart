class Payment {
  final String id;
  final double amount;
  final String paymentType;
  final String status;
  final String? gatewayRef;
  final String createdAt;
  final String? reason;
  final String? notes;
  final String? proofStatus;
  final String? proofNotes;

  Payment({
    required this.id,
    required this.amount,
    required this.paymentType,
    required this.status,
    this.gatewayRef,
    required this.createdAt,
    this.reason,
    this.notes,
    this.proofStatus,
    this.proofNotes,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id'] ?? '',
        amount: (json['amount'] ?? 0).toDouble(),
        paymentType: json['payment_type'] ?? '',
        status: (json['status'] ?? 'pending').toString().toLowerCase(),
        gatewayRef: json['gateway_reference'],
        createdAt: json['created_at'] ?? '',
        reason: json['reason'],
        notes: json['notes'],
        proofStatus: json['proof_status'],
        proofNotes: json['proof_notes'],
      );

  String get statusLabel {
    if (status == 'pending' && proofStatus != null) {
      if (proofStatus == 'pending_review') return 'Proof Pending';
      if (proofStatus == 'rejected') return 'Proof Rejected';
    }
    switch (status) {
      case 'pending': return 'Pending';
      case 'completed': return 'Completed';
      case 'failed': return 'Failed';
      case 'refunded': return 'Refunded';
      default: return status;
    }
  }
}
