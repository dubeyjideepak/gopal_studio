extension StringExtensions on String {
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  String get titleCase {
    return split(' ').map((w) => w.capitalize).join(' ');
  }

  bool get isValidPhone {
    return RegExp(r'^[6-9]\d{9}$').hasMatch(this);
  }

  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }

  String get whatsappUrl {
    final cleaned = replaceAll(RegExp(r'[^0-9]'), '');
    final number = cleaned.startsWith('91') ? cleaned : '91$cleaned';
    return 'https://wa.me/$number';
  }
}

extension DoubleExtensions on double {
  String get inRupees => '₹${toStringAsFixed(2)}';
  String get inRupeesRounded => '₹${toStringAsFixed(0)}';
}
