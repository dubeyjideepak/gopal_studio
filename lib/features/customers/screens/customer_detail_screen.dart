import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/customer_model.dart';
import '../../../shared/models/bill_model.dart';
import '../../../services/local_db_service.dart';
import '../../../services/whatsapp_service.dart';
import '../../billing/widgets/bill_list_tile.dart';

final customerDetailProvider = FutureProvider.family<Customer?, String>((ref, id) {
  return LocalDbService.instance.getCustomerById(id);
});

final customerBillsProvider = FutureProvider.family<List<Bill>, String>((ref, id) {
  return LocalDbService.instance.getBillsByCustomer(id);
});

class CustomerDetailScreen extends ConsumerWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerDetailProvider(customerId));
    final billsAsync = ref.watch(customerBillsProvider(customerId));

    return customerAsync.when(
      data: (customer) {
        if (customer == null) {
          return Scaffold(appBar: AppBar(title: const Text('Client')), body: const Center(child: Text('Not found')));
        }
        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                backgroundColor: AppColors.surface,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: _CustomerHeader(customer: customer),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_rounded, color: AppColors.whatsapp),
                    onPressed: () async {
                      final bills = await LocalDbService.instance.getBillsByCustomer(customerId);
                      final pendingBills = bills.where((b) => b.status != BillStatus.paid).toList();
                      if (pendingBills.isEmpty || customer.mobile == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No pending bill or mobile number missing')),
                        );
                        return;
                      }
                      final profile = await LocalDbService.instance.getBusinessProfile();
                      await WhatsAppService.instance.sendPaymentReminder(
                        bill: pendingBills.first,
                        business: profile,
                      );
                    },
                    tooltip: 'Send WhatsApp Reminder',
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _BalanceCard(
                              label: 'Total Dues',
                              amount: customer.totalDue,
                              color: customer.totalDue > 0 ? AppColors.warning : AppColors.success,
                            ).animate().fadeIn(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _BalanceCard(
                              label: 'Total Advance',
                              amount: customer.totalAdvance,
                              color: AppColors.info,
                            ).animate().fadeIn(delay: 100.ms),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Billing History', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/bill/new'),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('New Bill'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              billsAsync.when(
                data: (bills) {
                  if (bills.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('No bills created for this customer yet', style: TextStyle(color: AppColors.textMuted)),
                        ),
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: BillListTile(
                          bill: bills[i],
                          onTap: () => context.push('/bill/${bills[i].id}'),
                        ).animate().fadeIn(delay: Duration(milliseconds: i * 60)),
                      ),
                      childCount: bills.length,
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
                error: (e, _) => SliverToBoxAdapter(child: Text('Error: $e')),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}

class _CustomerHeader extends StatelessWidget {
  final Customer customer;
  const _CustomerHeader({required this.customer});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(72, 16, 16, 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.gold.withOpacity(0.2),
                child: Text(
                  customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                  style: const TextStyle(color: AppColors.gold, fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(customer.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                    if (customer.mobile != null)
                      Text(customer.mobile!, style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
                    if (customer.address != null)
                      Text(customer.address!, style: const TextStyle(color: AppColors.textMuted, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const _BalanceCard({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 6),
          Text('₹${amount.toStringAsFixed(0)}',
              style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
