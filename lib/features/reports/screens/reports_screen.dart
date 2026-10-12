import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/bill_model.dart';
import '../../../services/local_db_service.dart';
import '../../billing/widgets/bill_list_tile.dart';

final allBillsProvider = FutureProvider<List<Bill>>((ref) {
  return LocalDbService.instance.getAllBills();
});

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final billsAsync = ref.watch(allBillsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reports & Statements'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.gold,
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'All Bills'),
            Tab(text: 'Dues & Pending'),
            Tab(text: 'Financial Summary'),
          ],
        ),
      ),
      body: billsAsync.when(
        data: (bills) => TabBarView(
          controller: _tabCtrl,
          children: [
            _AllBillsTab(bills: bills),
            _OutstandingTab(bills: bills),
            _SummaryTab(bills: bills),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _AllBillsTab extends StatelessWidget {
  final List<Bill> bills;
  const _AllBillsTab({required this.bills});

  @override
  Widget build(BuildContext context) {
    if (bills.isEmpty) {
      return const Center(child: Text('No bills created yet', style: TextStyle(color: AppColors.textMuted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: bills.length,
      itemBuilder: (ctx, i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: BillListTile(
          bill: bills[i],
          onTap: () => context.push('/bill/${bills[i].id}'),
        ).animate().fadeIn(delay: Duration(milliseconds: i * 30)),
      ),
    );
  }
}

class _OutstandingTab extends StatelessWidget {
  final List<Bill> bills;
  const _OutstandingTab({required this.bills});

  @override
  Widget build(BuildContext context) {
    final pending = bills
        .where((b) => b.status == BillStatus.pending || b.status == BillStatus.partial)
        .toList();

    if (pending.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success, size: 64),
            SizedBox(height: 12),
            Text('All cleared! No outstanding dues.', style: TextStyle(color: AppColors.success, fontSize: 16)),
          ],
        ),
      );
    }

    final totalDue = pending.fold<double>(0, (s, b) => s + b.remainingBalance);

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Outstanding Dues', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  Text('₹${totalDue.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.warning, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
              Text('${pending.length} unpaid / partial bills', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            itemCount: pending.length,
            itemBuilder: (ctx, i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: BillListTile(
                bill: pending[i],
                onTap: () => context.push('/bill/${pending[i].id}'),
              ).animate().fadeIn(delay: Duration(milliseconds: i * 30)),
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryTab extends StatelessWidget {
  final List<Bill> bills;
  const _SummaryTab({required this.bills});

  @override
  Widget build(BuildContext context) {
    final total = bills.fold<double>(0, (s, b) => s + b.totalAmount);
    final collected = bills.fold<double>(0, (s, b) => s + b.paidAmount);
    final outstanding = bills.fold<double>(0, (s, b) => s + b.remainingBalance);
    final paidBills = bills.where((b) => b.status == BillStatus.paid).length;
    final partialBills = bills.where((b) => b.status == BillStatus.partial).length;
    final pendingBills = bills.where((b) => b.status == BillStatus.pending).length;

    final today = DateTime.now();
    final todayBills = bills.where((b) =>
        b.createdAt.year == today.year && b.createdAt.month == today.month && b.createdAt.day == today.day);
    final todayRevenue = todayBills.fold<double>(0, (s, b) => s + b.paidAmount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _StatCard(label: "Today's Collection", value: '₹${todayRevenue.toStringAsFixed(0)}', icon: Icons.today_rounded, color: AppColors.success).animate().fadeIn(),
          const SizedBox(height: 12),
          _StatCard(label: 'Total Invoiced Amount', value: '₹${total.toStringAsFixed(0)}', icon: Icons.trending_up_rounded, color: AppColors.gold).animate().fadeIn(delay: 60.ms),
          const SizedBox(height: 12),
          _StatCard(label: 'Total Settled / Collected', value: '₹${collected.toStringAsFixed(0)}', icon: Icons.account_balance_wallet_rounded, color: AppColors.info).animate().fadeIn(delay: 120.ms),
          const SizedBox(height: 12),
          _StatCard(label: 'Total Pending Dues', value: '₹${outstanding.toStringAsFixed(0)}', icon: Icons.pending_actions_rounded, color: AppColors.warning).animate().fadeIn(delay: 180.ms),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _MiniStat('Fully Paid', paidBills.toString(), AppColors.success).animate().fadeIn(delay: 220.ms)),
              const SizedBox(width: 8),
              Expanded(child: _MiniStat('Partial', partialBills.toString(), AppColors.warning).animate().fadeIn(delay: 260.ms)),
              const SizedBox(width: 8),
              Expanded(child: _MiniStat('Unpaid Due', pendingBills.toString(), AppColors.error).animate().fadeIn(delay: 300.ms)),
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
              Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 0.8),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
