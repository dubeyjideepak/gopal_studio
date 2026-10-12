import 'package:google_generative_ai/google_generative_ai.dart';
import '../shared/models/bill_model.dart';
import '../shared/models/customer_model.dart';
import '../core/constants/app_constants.dart';

class AiService {
  static AiService? _instance;
  static AiService get instance => _instance ??= AiService._();
  AiService._();

  // Replace with your actual Gemini API key or load from env
  static const _apiKey = 'YOUR_GEMINI_API_KEY';
  
  GenerativeModel? _model;
  
  GenerativeModel get model {
    _model ??= GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );
    return _model!;
  }

  bool get isConfigured => _apiKey != 'YOUR_GEMINI_API_KEY';

  // ─── Price Suggestion ───────────────────────────────────────────────────
  Future<String> suggestPrice({
    required String itemDescription,
    required List<Bill> recentBills,
  }) async {
    if (!isConfigured) return 'Configure Gemini API key in settings for AI suggestions.';
    
    try {
      // Build context from recent bills
      final priceHistory = <String>[];
      for (final bill in recentBills.take(20)) {
        for (final item in bill.items) {
          priceHistory.add('${item.particulars} ${item.size ?? ""}: ₹${item.rate} per unit');
        }
      }

      final prompt = '''
You are a pricing assistant for a photography studio in India.
Based on these recent prices from this studio:
${priceHistory.join(', ')}

Suggest a fair price for: "$itemDescription"
Keep response under 50 words. Be direct and practical.
Provide price in Indian Rupees (₹).
      ''';

      final response = await model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Could not generate suggestion.';
    } catch (e) {
      return 'AI suggestion unavailable. Error: ${e.toString()}';
    }
  }

  // ─── WhatsApp Message Composer ──────────────────────────────────────────
  Future<String> composeReminderMessage({
    required String customerName,
    required double balance,
    required int billNumber,
    required String businessName,
  }) async {
    if (!isConfigured) {
      return _defaultReminderMessage(customerName, balance, billNumber, businessName);
    }
    
    try {
      final prompt = '''
Write a polite WhatsApp payment reminder message in Hindi/English mix (Hinglish) for:
- Customer: $customerName
- Amount Due: ₹$balance  
- Bill Number: #$billNumber
- Business: $businessName (Photography Studio, India)

Keep it friendly, respectful, and under 100 words. Use emojis appropriately.
      ''';

      final response = await model.generateContent([Content.text(prompt)]);
      return response.text ?? _defaultReminderMessage(customerName, balance, billNumber, businessName);
    } catch (e) {
      return _defaultReminderMessage(customerName, balance, billNumber, businessName);
    }
  }

  String _defaultReminderMessage(String name, double balance, int billNo, String business) {
    return '🙏 Namaste $name Ji!\n\nYour payment of ₹$balance is pending for Bill #$billNo at $business.\n\nPlease clear at your earliest. Thank you! 🙏';
  }

  // ─── Item Categorization ────────────────────────────────────────────────
  Future<String> categorizeItem(String itemDescription) async {
    final desc = itemDescription.toLowerCase();
    // Simple local classification — works offline
    if (desc.contains('photo') || desc.contains('print') || desc.contains('×') || desc.contains('x')) {
      if (desc.contains('passport') || desc.contains('stamp')) return 'Passport Photo';
      return 'Photo Print';
    }
    if (desc.contains('album')) return 'Album';
    if (desc.contains('frame')) return 'Frame';
    if (desc.contains('video') || desc.contains('mixing') || desc.contains('edit')) return 'Video Editing';
    if (desc.contains('dvd') || desc.contains('pen') || desc.contains('cd')) return 'DVD/Pen Drive';
    if (desc.contains('canvas')) return 'Canvas Print';
    if (desc.contains('lamina')) return 'Photo Lamination';
    return 'Other';
  }

  // ─── Duplicate Customer Detection ───────────────────────────────────────
  List<Customer> findSimilarCustomers(String name, List<Customer> existing) {
    final nameLower = name.toLowerCase().trim();
    return existing.where((c) {
      final cName = c.name.toLowerCase().trim();
      // Exact or starts-with match
      if (cName == nameLower || cName.startsWith(nameLower) || nameLower.startsWith(cName)) {
        return true;
      }
      // Levenshtein-like simple check
      return _similarity(nameLower, cName) > 0.7;
    }).toList();
  }

  double _similarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    final longer = a.length > b.length ? a : b;
    final shorter = a.length > b.length ? b : a;
    final longerLen = longer.length.toDouble();
    return (longerLen - _editDistance(longer, shorter)) / longerLen;
  }

  int _editDistance(String s1, String s2) {
    final m = s1.length, n = s2.length;
    final d = List.generate(m + 1, (i) => List.filled(n + 1, 0));
    for (var i = 0; i <= m; i++) d[i][0] = i;
    for (var j = 0; j <= n; j++) d[0][j] = j;
    for (var i = 1; i <= m; i++) {
      for (var j = 1; j <= n; j++) {
        d[i][j] = s1[i - 1] == s2[j - 1]
            ? d[i - 1][j - 1]
            : 1 + [d[i - 1][j], d[i][j - 1], d[i - 1][j - 1]].reduce((a, b) => a < b ? a : b);
      }
    }
    return d[m][n];
  }

  // ─── Smart Item Suggestions ─────────────────────────────────────────────
  List<String> getItemSuggestions(String query, List<Bill> recentBills) {
    final suggestions = <String>{};
    final queryLower = query.toLowerCase();

    for (final bill in recentBills) {
      for (final item in bill.items) {
        final desc = '${item.particulars}${item.size != null ? " ${item.size}" : ""}';
        if (desc.toLowerCase().contains(queryLower)) {
          suggestions.add(desc);
        }
      }
    }

    // Add predefined suggestions
    final predefined = [
      ...AppConstants.photoSizes.map((s) => '4×6 Print $s'),
      ...AppConstants.itemCategories,
    ];
    for (final p in predefined) {
      if (p.toLowerCase().contains(queryLower)) suggestions.add(p);
    }

    return suggestions.take(8).toList();
  }

  // ─── Bill Summary ────────────────────────────────────────────────────────
  Future<String> generateBillSummary(Bill bill) async {
    if (!isConfigured) {
      return 'Bill #${bill.billNumber} for ${bill.customerName} — ₹${bill.totalAmount.toStringAsFixed(0)} total, ₹${bill.remainingBalance.toStringAsFixed(0)} pending.';
    }
    
    try {
      final itemsText = bill.items.map((i) => '${i.particulars} ×${i.quantity.toStringAsFixed(0)}').join(', ');
      final prompt = '''
Summarize this photography studio bill in 1-2 friendly sentences:
- Customer: ${bill.customerName}
- Items: $itemsText
- Total: ₹${bill.totalAmount}
- Paid: ₹${bill.paidAmount}
- Balance: ₹${bill.remainingBalance}

Keep it natural and professional.
      ''';
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text ?? '';
    } catch (e) {
      return '';
    }
  }
}
