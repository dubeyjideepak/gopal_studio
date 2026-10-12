import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/customer_model.dart';
import '../../../services/local_db_service.dart';

final customersProvider = FutureProvider<List<Customer>>((ref) {
  return LocalDbService.instance.getAllCustomers();
});

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Clients & Accounts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded, color: AppColors.gold),
            onPressed: () async {
              await context.push('/customers/add');
              ref.invalidate(customersProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search by client name or mobile...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.gold),
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: customersAsync.when(
              data: (customers) {
                final filtered = customers
                    .where((c) =>
                        _searchQuery.isEmpty ||
                        c.name.toLowerCase().contains(_searchQuery) ||
                        (c.mobile?.contains(_searchQuery) ?? false))
                    .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.people_outline, color: AppColors.textMuted, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty ? 'No clients added yet' : 'No matching clients found',
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                        if (_searchQuery.isEmpty) ...[
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await context.push('/customers/add');
                              ref.invalidate(customersProvider);
                            },
                            icon: const Icon(Icons.person_add_rounded),
                            label: const Text('Add First Client'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(customersProvider.future),
                  color: AppColors.gold,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _CustomerTile(
                        customer: filtered[i],
                        onTap: () async {
                          await context.push('/customers/${filtered[i].id}');
                          ref.invalidate(customersProvider);
                        },
                      ).animate().fadeIn(delay: Duration(milliseconds: i * 40)),
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;
  const _CustomerTile({required this.customer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasBalance = customer.netBalance > 0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasBalance ? AppColors.warning.withOpacity(0.3) : AppColors.border,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.gold.withOpacity(0.15),
              child: Text(
                customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                  if (customer.mobile != null)
                    Text(customer.mobile!, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
            if (hasBalance)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Text(
                  'Due: ₹${customer.netBalance.toStringAsFixed(0)}',
                  style: const TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              )
            else
              const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
