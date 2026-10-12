import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/bill_model.dart';

class BillListTile extends StatelessWidget {
  final Bill bill;
  final VoidCallback? onTap;
  const BillListTile({super.key, required this.bill, this.onTap});

  Color _statusColor(BillStatus s) {
    switch (s) {
      case BillStatus.paid: return AppColors.success;
      case BillStatus.partial: return AppColors.warning;
      case BillStatus.pending: return AppColors.error;
      case BillStatus.cancelled: return AppColors.textMuted;
    }
  }

  String _statusLabel(BillStatus s) {
    switch (s) {
      case BillStatus.paid: return 'PAID';
      case BillStatus.partial: return 'PARTIAL';
      case BillStatus.pending: return 'DUE';
      case BillStatus.cancelled: return 'CANCELLED';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(bill.status);
    final dateStr = DateFormat('dd MMM yy').format(bill.createdAt);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: statusColor.withOpacity(0.3), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gold.withOpacity(0.3)),
              ),
              child: Center(child: Text('#${bill.billNumber}', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 12))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bill.customerName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(bill.items.map((i) => i.particulars).join(', '), style: const TextStyle(color: AppColors.textMuted, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(dateStr, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('\u20b9${bill.totalAmount.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                  child: Text(_statusLabel(bill.status), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
                if (bill.status == BillStatus.partial || bill.status == BillStatus.pending)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('Due: \u20b9${bill.remainingBalance.toStringAsFixed(0)}', style: TextStyle(color: statusColor, fontSize: 10)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
