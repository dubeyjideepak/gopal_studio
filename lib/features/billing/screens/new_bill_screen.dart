import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/bill_model.dart';
import '../../../shared/models/customer_model.dart';
import '../../../services/local_db_service.dart';
import '../../../shared/widgets/gold_text_field.dart';

class NewBillScreen extends ConsumerStatefulWidget {
  const NewBillScreen({super.key});

  @override
  ConsumerState<NewBillScreen> createState() => _NewBillScreenState();
}

class _NewBillScreenState extends ConsumerState<NewBillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  // Customer
  Customer? _selectedCustomer;
  final _customerNameCtrl = TextEditingController();
  final _customerMobileCtrl = TextEditingController();

  // Items
  final List<_ItemRow> _items = [_ItemRow()];

  // Payment
  double _advanceAmount = 0;
  PaymentType _paymentType = PaymentType.cash;
  final _advanceCtrl = TextEditingController();

  // Delivery date
  DateTime? _deliveryDate;

  // Notes
  final _notesCtrl = TextEditingController();

  // Customers list
  List<Customer> _customers = [];
  bool _showCustomerSuggestions = false;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final list = await LocalDbService.instance.getAllCustomers();
    if (mounted) setState(() => _customers = list);
  }

  double get _totalAmount =>
      _items.fold(0, (sum, item) => sum + item.amount);

  double get _balanceAmount => _totalAmount - _advanceAmount;

  void _addItem() {
    setState(() => _items.add(_ItemRow()));
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() => _items.removeAt(index));
    }
  }

  Future<void> _pickDeliveryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.gold,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _deliveryDate = date);
  }

  Future<void> _saveBill() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.any((i) => i.particularsCtrl.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all item particulars')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      Customer customer;
      if (_selectedCustomer != null) {
        customer = _selectedCustomer!;
      } else {
        final name = _customerNameCtrl.text.trim();
        final mobile = _customerMobileCtrl.text.trim();
        customer = await LocalDbService.instance.createCustomer(
          name: name,
          mobile: mobile.isNotEmpty ? mobile : null,
        );
      }

      final billNumber = await LocalDbService.instance.getNextBillNumber();
      final billId = _uuid.v4();
      final now = DateTime.now();

      final items = _items.map((row) {
        final qty = double.tryParse(row.quantityCtrl.text) ?? 1;
        final rate = double.tryParse(row.rateCtrl.text) ?? 0;
        return BillItem(
          id: _uuid.v4(),
          particulars: row.particularsCtrl.text.trim(),
          size: row.sizeCtrl.text.trim().isEmpty ? null : row.sizeCtrl.text.trim(),
          quantity: qty,
          rate: rate,
          amount: qty * rate,
        );
      }).toList();

      final advance = double.tryParse(_advanceCtrl.text) ?? 0;
      final total = items.fold<double>(0, (s, i) => s + i.amount);
      final balance = total - advance;

      BillStatus status;
      if (advance >= total && total > 0) {
        status = BillStatus.paid;
      } else if (advance > 0) {
        status = BillStatus.partial;
      } else {
        status = BillStatus.pending;
      }

      final paymentEntries = <PaymentEntry>[];
      if (advance > 0) {
        paymentEntries.add(PaymentEntry(
          id: _uuid.v4(),
          amount: advance,
          type: _paymentType,
          date: now,
          note: 'Advance payment',
        ));
      }

      final bill = Bill(
        id: billId,
        billNumber: billNumber,
        customerId: customer.id,
        customerName: customer.name,
        customerMobile: customer.mobile,
        createdAt: now,
        deliveryDate: _deliveryDate,
        items: items,
        totalAmount: total,
        advanceAmount: advance,
        balanceAmount: balance < 0 ? 0 : balance,
        paidAmount: advance,
        status: status,
        paymentHistory: paymentEntries,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      await LocalDbService.instance.saveBill(bill);
      await LocalDbService.instance.recalculateCustomerBalance(customer.id);

      if (mounted) {
        context.pushReplacement('/bill/$billId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving bill: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _customerMobileCtrl.dispose();
    _advanceCtrl.dispose();
    _notesCtrl.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('New Bill'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _saveBill,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.gold))
                : const Icon(Icons.save_rounded, color: AppColors.gold),
            label: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer Section
              const _SectionHeader(title: 'Customer Details', icon: Icons.person_rounded),
              const SizedBox(height: 12),
              _buildCustomerSection(),
              const SizedBox(height: 24),

              // Items Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _SectionHeader(
                      title: 'Particulars & Items', icon: Icons.receipt_long_rounded),
                  TextButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add_circle_rounded,
                        color: AppColors.gold, size: 18),
                    label: const Text('Add Row'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildItemsTable(),
              const SizedBox(height: 24),

              // Totals
              _buildTotalsSection(),
              const SizedBox(height: 24),

              // Delivery Date
              const _SectionHeader(
                  title: 'Delivery Target Date', icon: Icons.calendar_today_rounded),
              const SizedBox(height: 12),
              _buildDeliveryDatePicker(),
              const SizedBox(height: 24),

              // Notes
              const _SectionHeader(title: 'Special Instructions / Notes', icon: Icons.notes_rounded),
              const SizedBox(height: 12),
              GoldTextField(
                controller: _notesCtrl,
                hintText: 'e.g. Frame type: MDF Glossy, Urgent print...',
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveBill,
                  icon: const Icon(Icons.receipt_rounded),
                  label: Text(_isSaving ? 'Generating Bill...' : 'Create & View Bill'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerSection() {
    final filteredCustomers = _customers
        .where((c) => c.name
            .toLowerCase()
            .contains(_customerNameCtrl.text.toLowerCase()))
        .take(5)
        .toList();

    return Column(
      children: [
        Stack(
          children: [
            GoldTextField(
              controller: _customerNameCtrl,
              hintText: 'Customer / Party Name *',
              prefixIcon: Icons.person_outline_rounded,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Customer name required' : null,
              onChanged: (v) {
                setState(() {
                  _showCustomerSuggestions = v.isNotEmpty;
                  _selectedCustomer = null;
                });
              },
            ),
            if (_showCustomerSuggestions && filteredCustomers.isNotEmpty)
              Positioned(
                top: 60,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.elevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: filteredCustomers.map((c) {
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.person,
                            color: AppColors.gold, size: 18),
                        title: Text(c.name,
                            style: const TextStyle(
                                color: AppColors.textPrimary)),
                        subtitle: c.mobile != null
                            ? Text(c.mobile!,
                                style: const TextStyle(
                                    color: AppColors.textMuted, fontSize: 12))
                            : null,
                        trailing: c.hasOutstanding
                            ? Text(
                                'Due: ₹${c.netBalance.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    color: AppColors.warning, fontSize: 11))
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedCustomer = c;
                            _customerNameCtrl.text = c.name;
                            _customerMobileCtrl.text = c.mobile ?? '';
                            _showCustomerSuggestions = false;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        GoldTextField(
          controller: _customerMobileCtrl,
          hintText: 'WhatsApp / Mobile Number',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
      ],
    );
  }

  Widget _buildItemsTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: _TableHeader('Particulars / Size')),
                Expanded(flex: 1, child: _TableHeader('Qty')),
                Expanded(flex: 2, child: _TableHeader('Rate (₹)')),
                Expanded(flex: 2, child: _TableHeader('Amount')),
                SizedBox(width: 32),
              ],
            ),
          ),
          ...List.generate(_items.length, (i) => _buildItemRow(i)),
        ],
      ),
    );
  }

  Widget _buildItemRow(int index) {
    final item = _items[index];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              children: [
                TextFormField(
                  controller: item.particularsCtrl,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Item (e.g. Photo Print)',
                    hintStyle:
                        TextStyle(color: AppColors.textMuted, fontSize: 12),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 4),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                TextFormField(
                  controller: item.sizeCtrl,
                  style: const TextStyle(
                      color: AppColors.textGold, fontSize: 11),
                  decoration: const InputDecoration(
                    hintText: 'Size (e.g. 12x18 / MDF)',
                    hintStyle:
                        TextStyle(color: AppColors.textMuted, fontSize: 11),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 4),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: TextFormField(
              controller: item.quantityCtrl,
              style:
                  const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: const InputDecoration(
                hintText: '1',
                hintStyle:
                    TextStyle(color: AppColors.textMuted, fontSize: 12),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 4),
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: item.rateCtrl,
              style:
                  const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: const InputDecoration(
                hintText: '0',
                hintStyle:
                    TextStyle(color: AppColors.textMuted, fontSize: 12),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 4),
                isDense: true,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '₹${item.amount.toStringAsFixed(0)}',
              style: const TextStyle(
                  color: AppColors.gold, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline,
                color: AppColors.error, size: 20),
            onPressed: () => _removeItem(index),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.gold.withOpacity(0.08), AppColors.cardColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          _TotalRow('Total Amount', '₹${_totalAmount.toStringAsFixed(2)}',
              isTotal: true),
          const Divider(color: AppColors.border),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Text('Advance Paid',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 14)),
              ),
              SizedBox(
                width: 140,
                child: TextFormField(
                  controller: _advanceCtrl,
                  style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600,
                      fontSize: 15),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    prefixText: '₹ ',
                    prefixStyle: const TextStyle(color: AppColors.gold),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.gold, width: 1.5),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) {
                    setState(
                        () => _advanceAmount = double.tryParse(v) ?? 0);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Payment Mode',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 14)),
              const Spacer(),
              ...PaymentType.values.map((type) {
                final selected = _paymentType == type;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _paymentType = type),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.gold.withOpacity(0.2)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected ? AppColors.gold : AppColors.border,
                          width: selected ? 1.5 : 0.5,
                        ),
                      ),
                      child: Text(
                        type.name.toUpperCase(),
                        style: TextStyle(
                          color: selected
                              ? AppColors.gold
                              : AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          const Divider(color: AppColors.border),
          _TotalRow(
            'Balance Due',
            '₹${_balanceAmount < 0 ? "0.00" : _balanceAmount.toStringAsFixed(2)}',
            color: _balanceAmount > 0 ? AppColors.warning : AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryDatePicker() {
    return GestureDetector(
      onTap: _pickDeliveryDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded,
                color: AppColors.gold, size: 20),
            const SizedBox(width: 12),
            Text(
              _deliveryDate != null
                  ? DateFormat('dd MMM yyyy').format(_deliveryDate!)
                  : 'Select delivery date (optional)',
              style: TextStyle(
                color: _deliveryDate != null
                    ? AppColors.textPrimary
                    : AppColors.textMuted,
              ),
            ),
            const Spacer(),
            if (_deliveryDate != null)
              GestureDetector(
                onTap: () => setState(() => _deliveryDate = null),
                child: const Icon(Icons.close,
                    color: AppColors.textMuted, size: 18),
              ),
          ],
        ),
      ),
    );
  }
}

class _ItemRow {
  final particularsCtrl = TextEditingController();
  final sizeCtrl = TextEditingController();
  final quantityCtrl = TextEditingController(text: '1');
  final rateCtrl = TextEditingController();

  double get amount {
    final qty = double.tryParse(quantityCtrl.text) ?? 1;
    final rate = double.tryParse(rateCtrl.text) ?? 0;
    return qty * rate;
  }

  void dispose() {
    particularsCtrl.dispose();
    sizeCtrl.dispose();
    quantityCtrl.dispose();
    rateCtrl.dispose();
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.gold, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.gold,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  final Color? color;

  const _TotalRow(this.label, this.value,
      {this.isTotal = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color:
                  isTotal ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight:
                  isTotal ? FontWeight.w700 : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color ?? (isTotal ? AppColors.gold : AppColors.textPrimary),
              fontWeight: FontWeight.w700,
              fontSize: isTotal ? 18 : 15,
            ),
          ),
        ],
      ),
    );
  }
}
