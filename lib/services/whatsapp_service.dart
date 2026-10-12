import 'package:url_launcher/url_launcher.dart';
import '../shared/models/bill_model.dart';
import '../shared/models/business_profile_model.dart';
import '../core/constants/app_constants.dart';
import 'package:intl/intl.dart';

class WhatsAppService {
  static WhatsAppService? _instance;
  static WhatsAppService get instance => _instance ??= WhatsAppService._();
  WhatsAppService._();

  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  Future<bool> sendMessage(String phone, String message) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final number = cleaned.startsWith('91') ? cleaned : '91$cleaned';
    final encoded = Uri.encodeComponent(message);
    final url = Uri.parse('https://wa.me/$number?text=$encoded');
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> sendPaymentReminder({
    required Bill bill,
    required BusinessProfile business,
  }) async {
    if (bill.customerMobile == null || bill.customerMobile!.isEmpty) return false;
    
    final balance = _currencyFormat.format(bill.remainingBalance);
    final billDate = DateFormat('dd MMM yyyy').format(bill.createdAt);
    
    final message = '''
🙏 *${business.businessName}*

Namaste ${bill.customerName} Ji! 🌸

Your bill payment reminder:

📋 *Bill No:* #${bill.billNumber}
📅 *Date:* $billDate
💰 *Total Amount:* ${_currencyFormat.format(bill.totalAmount)}
✅ *Paid:* ${_currencyFormat.format(bill.paidAmount)}
⚠️ *Balance Due:* *$balance*

Please clear your dues at your earliest convenience.

Payment Options:
${business.upiId != null ? '📱 UPI: ${business.upiId}' : ''}

📞 Contact: ${business.phone1}${business.phone2 != null ? ' / ${business.phone2}' : ''}

_${business.tagline ?? 'Thank you for your business!'}_
    '''.trim();

    return sendMessage(bill.customerMobile!, message);
  }

  Future<bool> shareBill({
    required Bill bill,
    required BusinessProfile business,
    bool isPartial = false,
  }) async {
    if (bill.customerMobile == null || bill.customerMobile!.isEmpty) return false;

    final billDate = DateFormat('dd MMM yyyy').format(bill.createdAt);
    final itemsList = bill.items.map((item) =>
      '  • ${item.particulars}${item.size != null ? ' (${item.size})' : ''} × ${item.quantity.toStringAsFixed(0)} = ${_currencyFormat.format(item.amount)}'
    ).join('\n');

    String statusNote = '';
    if (isPartial) {
      statusNote = '\n⚠️ *Balance Due:* ${_currencyFormat.format(bill.remainingBalance)}';
    } else if (bill.isFullyPaid) {
      statusNote = '\n✅ *FULLY PAID — Thank You!*';
    }

    final message = '''
🎞️ *${business.businessName}*
${business.address ?? ''}
📞 ${business.phone1}${business.phone2 != null ? ' | ${business.phone2}' : ''}
━━━━━━━━━━━━━━━━━━━━
📋 *BILL RECEIPT #${bill.billNumber}*
📅 Date: $billDate
👤 Customer: ${bill.customerName}
━━━━━━━━━━━━━━━━━━━━
*Items:*
$itemsList
━━━━━━━━━━━━━━━━━━━━
💰 *Total:* ${_currencyFormat.format(bill.totalAmount)}
${bill.advanceAmount > 0 ? '💵 *Advance:* ${_currencyFormat.format(bill.advanceAmount)}\n' : ''}⚖️ *Balance:* ${_currencyFormat.format(bill.balanceAmount)}${statusNote}
━━━━━━━━━━━━━━━━━━━━
${business.upiId != null ? '📱 Pay via UPI: ${business.upiId}' : ''}

_${business.tagline ?? 'Thank you!'}_
    '''.trim();

    return sendMessage(bill.customerMobile!, message);
  }

  Future<bool> sendDeliveryReminder({
    required Bill bill,
    required BusinessProfile business,
  }) async {
    if (bill.customerMobile == null || bill.customerMobile!.isEmpty) return false;
    if (bill.deliveryDate == null) return false;

    final deliveryDate = DateFormat('dd MMM yyyy').format(bill.deliveryDate!);
    
    final message = '''
🎉 *${business.businessName}*

Namaste ${bill.customerName} Ji!

Your order (Bill #${bill.billNumber}) is ready for delivery!

📅 *Delivery Date:* $deliveryDate

Please visit us to collect your order.

📍 ${business.address ?? ''}
📞 ${business.phone1}

_${business.tagline ?? 'Thank you!'}_
    '''.trim();

    return sendMessage(bill.customerMobile!, message);
  }
}
