class AppConstants {
  // App Info
  static const String appName = 'StudioBill Pro';
  static const String appVersion = '1.0.0';
  static const String tagline = 'Capturing Memory, Creating Story';

  // Storage Keys
  static const String keyBusinessProfile = 'business_profile';
  static const String keyLastBillNumber = 'last_bill_number';
  static const String keyIsFirstRun = 'is_first_run';
  static const String keyUserId = 'user_id';

  // Firestore Collections
  static const String collectionBills = 'bills';
  static const String collectionCustomers = 'customers';
  static const String collectionBusiness = 'business';
  static const String collectionPayments = 'payments';

  // WhatsApp
  static const String waBaseUrl = 'https://wa.me/';

  // GitHub Releases
  static const String githubReleasesUrl =
      'https://api.github.com/repos/gopalstudio/gopal-billing/releases/latest';

  // Default values
  static const int defaultBillStartNumber = 1;
  static const String defaultCurrency = '₹';

  // Item categories for suggestions
  static const List<String> itemCategories = [
    'Photo Print',
    'Album',
    'Frame',
    'Video Editing',
    'DVD/Pen Drive',
    'Passport Photo',
    'Photo Lamination',
    'Canvas Print',
    'Photo Book',
    'Other',
  ];

  // Common photo sizes
  static const List<String> photoSizes = [
    '4×6',
    '5×7',
    '6×8',
    '8×10',
    '10×12',
    '12×18',
    '16×20',
    '20×24',
    '24×30',
    'Passport',
    'Stamp',
  ];
}
