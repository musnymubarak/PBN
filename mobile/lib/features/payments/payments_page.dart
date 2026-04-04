import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/services/payment_service.dart';
import 'package:pbn/models/payment.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  final _service = PaymentService();
  List<Payment> _payments = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadPayments(); }

  Future<void> _loadPayments() async {
    setState(() => _loading = true);
    try { _payments = await _service.getMyPayments(); } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Payments', style: TextStyle(fontWeight: FontWeight.w800))),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _payments.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(TablerIcons.credit_card_off, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('No payments yet', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                ]))
              : RefreshIndicator(
                  onRefresh: _loadPayments,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _payments.length,
                    itemBuilder: (context, i) => _buildPaymentCard(_payments[i]),
                  ),
                ),
    );
  }

  Widget _buildPaymentCard(Payment payment) {
    final color = payment.status == 'completed' ? Colors.green : payment.status == 'failed' ? Colors.red : Colors.orange;
    final icon = payment.status == 'completed' ? TablerIcons.circle_check : payment.status == 'failed' ? TablerIcons.circle_x : TablerIcons.clock;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(payment.paymentType.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(payment.createdAt.split('T').first, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('LKR ${payment.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.text)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(payment.statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
          ),
        ]),
      ]),
    );
  }
}
