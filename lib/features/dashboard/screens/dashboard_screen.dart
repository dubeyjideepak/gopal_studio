import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/bill_model.dart';
import '../../../services/local_db_service.dart';
import '../../../shared/models/business_profile_model.dart';
import '../../billing/widgets/bill_list_tile.dart';

final dashboardBillsProvider = FutureProvider<List<Bill>>((ref) {
  return LocalDbService.instance.getAllBills();
});

final businessProfileProvider = FutureProvider<BusinessProfile>((ref) {
  return LocalDbService.instance.getBusinessProfile();
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(dashboardBillsProvider);
    final profileAsync = ref.watch(businessProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppColors.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: _DashboardHeader(profileAsync: profileAsync),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                color: AppColors.gold,
                onPressed: () {},
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: billsAsync.when(
              data: (bills) => _SummarySection(bills: bills),
              loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SizedBox(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _QuickActions(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Outstanding Bills',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          )),
                  TextButton(
                    onPressed: () => context.go('/reports'),
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),
          ),
          billsAsync.when(
            data: (bills) {
              final pending = bills
                  .where((b) =>
                      b.status == BillStatus.pending ||
                      b.status == BillStatus.partial)
                  .take(10)
                  .toList();
              if (pending.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle_outline,
                              color: AppColors.success, size: 48),
                          const SizedBox(height: 12),
                          Text('No outstanding bills!',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.success)),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: BillListTile(
                      bill: pending[i],
                      onTap: () => context.push('/bill/${pending[i].id}'),
                    ).animate().fadeIn(delay: Duration(milliseconds: i * 60)),
                  ),
                  childCount: pending.length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final AsyncValue<BusinessProfile> profileAsync;
  const _DashboardHeader({required this.profileAsync});

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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.gold, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/images/gopal_media_crest.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.camera_alt_rounded,
                          color: AppColors.gold,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: profileAsync.when(
                      data: (p) {
                        final name = p.businessName;
                        final isGopal = name.toLowerCase().contains('gopal');
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isGopal) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    'Gopal',
                                    style: GoogleFonts.greatVibes(
                                      color: AppColors.gold,
                                      fontSize: 34,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    name.replaceAll(RegExp(r'gopal', caseSensitive: false), '').trim().toUpperCase(),
                                    style: GoogleFonts.inter(
                                      color: AppColors.textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              Text(
                                name,
                                style: GoogleFonts.greatVibes(
                                  color: AppColors.gold,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                            const SizedBox(height: 2),
                            Text(
                              p.tagline ?? 'Capturing Memory, Creating Story',
                              style: GoogleFonts.inter(
                                color: AppColors.textMuted,
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  final List<Bill> bills;
  const _SummarySection({required this.bills});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayBills = bills.where((b) =>
        b.createdAt.year == today.year &&
        b.createdAt.month == today.month &&
        b.createdAt.day == today.day);
    final todayCollection = todayBills.fold<double>(0, (sum, b) => sum + b.paidAmount);
    final totalDue = bills.fold<double>(0, (sum, b) => sum + b.remainingBalance);
    final pendingCount = bills.where((b) => b.status == BillStatus.pending || b.status == BillStatus.partial).length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _SummaryCard(title: "Today's Collection", value: '\u20b9${todayCollection.toStringAsFixed(0)}', icon: Icons.today_rounded, color: AppColors.success).animate().fadeIn().slideX(begin: -0.2)),
              const SizedBox(width: 12),
              Expanded(child: _SummaryCard(title: 'Total Due', value: '\u20b9${totalDue.toStringAsFixed(0)}', icon: Icons.account_balance_wallet_rounded, color: AppColors.warning).animate().fadeIn(delay: 100.ms).slideX(begin: 0.2)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _SummaryCard(title: 'Total Bills', value: bills.length.toString(), icon: Icons.receipt_long_rounded, color: AppColors.info).animate().fadeIn(delay: 150.ms)),
              const SizedBox(width: 12),
              Expanded(child: _SummaryCard(title: 'Pending', value: pendingCount.toString(), icon: Icons.pending_actions_rounded, color: AppColors.error).animate().fadeIn(delay: 200.ms)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _SummaryCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'PlayfairDisplay')),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Row(
          children: [
            _ActionBtn(icon: Icons.add_circle_rounded, label: 'New Bill', color: AppColors.gold, onTap: () => context.push('/bill/new')),
            const SizedBox(width: 8),
            _ActionBtn(icon: Icons.person_add_rounded, label: 'Add Client', color: AppColors.info, onTap: () => context.push('/customers/add')),
            const SizedBox(width: 8),
            _ActionBtn(icon: Icons.bar_chart_rounded, label: 'Reports', color: AppColors.success, onTap: () => context.go('/reports')),
            const SizedBox(width: 8),
            _ActionBtn(icon: Icons.history_rounded, label: 'History', color: AppColors.warning, onTap: () => context.go('/reports')),
          ],
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
