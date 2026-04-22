import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:intl/intl.dart';
import 'package:pbn/core/constants/app_colors.dart';
import 'package:pbn/core/services/payment_service.dart';
import 'package:pbn/models/payment.dart';

import 'package:pbn/core/widgets/pbn_app_bar_actions.dart';

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
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() => _loading = true);
    try {
      _payments = await _service.getMyPayments();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    double totalPaid = 0;
    for (var p in _payments) {
      if (p.status == 'completed') totalPaid += p.amount;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 70,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('FINANCIAL CENTER',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textSecondary,
                    letterSpacing: 2)),
            Text('Billing & History',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                    letterSpacing: -0.5)),
          ],
        ),
        actions: [
          PbnAppBarActions(),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadPayments,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // ── Financial Overview Split Card ──────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFF0F172A).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10))
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text('Total Contributions',
                            style: TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5)),
                        const SizedBox(height: 12),
                        Text('LKR ${NumberFormat('#,##0').format(totalPaid)}',
                            style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -1)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Text('Verified Member Status', 
                            style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Text('TRANSACTION LOG',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 16),

                  if (_payments.isEmpty)
                    _buildEmptyState()
                  else
                    ..._payments.map((p) => _buildModernPaymentCard(p)),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(TablerIcons.credit_card_off, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('No billing records found', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _buildModernPaymentCard(Payment p) {
    final isCompleted = p.status == 'completed';
    final color = isCompleted ? Colors.green : p.status == 'failed' ? Colors.red : Colors.orange;
    final icon = isCompleted ? TablerIcons.receipt : p.status == 'failed' ? TablerIcons.alert_circle : TablerIcons.clock_play;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.reason ?? p.paymentType.replaceAll('_', ' ').toUpperCase(), 
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.text, letterSpacing: -0.2)),
                const SizedBox(height: 4),
                Text(_formatDate(p.createdAt), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('LKR ${NumberFormat('#,##0').format(p.amount)}', 
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.text, letterSpacing: -0.5)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(p.statusLabel.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) { return iso.split('T').first; }
  }
}
