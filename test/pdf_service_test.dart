import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:gopal_studio_pro/services/pdf_service.dart';
import 'package:gopal_studio_pro/shared/models/bill_model.dart';
import 'package:gopal_studio_pro/shared/models/business_profile_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PdfService generates luxury Cash Memo PDF bytes with zero errors', () async {
    final bill = Bill(
      id: 'test-1',
      billNumber: 1,
      customerId: 'cust-1',
      customerName: 'ABCD',
      customerMobile: '9935006921',
      createdAt: DateTime(2026, 10, 12),
      deliveryDate: DateTime(2026, 10, 15),
      items: const [
        BillItem(
          id: 'item-1',
          particulars: 'ITEM 1',
          size: '12X18',
          quantity: 1,
          rate: 50,
          amount: 50,
        ),
        BillItem(
          id: 'item-2',
          particulars: 'ITEM2',
          size: '13X15',
          quantity: 1,
          rate: 60,
          amount: 60,
        ),
      ],
      totalAmount: 110,
      advanceAmount: 50,
      balanceAmount: 30,
      paidAmount: 80,
      status: BillStatus.partial,
      paymentHistory: [
        PaymentEntry(
          id: 'pay-1',
          amount: 50,
          type: PaymentType.cash,
          date: DateTime(2026, 10, 12, 10, 30),
          note: 'Booking Advance',
        ),
        PaymentEntry(
          id: 'pay-2',
          amount: 30,
          type: PaymentType.upi,
          date: DateTime(2026, 10, 13, 16, 45),
          note: 'Photo Selection Progress Payment',
          upiRef: 'UPI/628192837192',
        ),
      ],
      notes: 'Studio portrait prints',
    );

    final profile = BusinessProfile.defaultProfile.copyWith(
      youtubeChannel: '@GopalPhotographyStudio',
      upiId: 'gopalstudio@upi',
    );

    final pdfBytes = await PdfService.instance.generateBillPdf(bill, profile);
    expect(pdfBytes, isNotNull);
    expect(pdfBytes.length, greaterThan(1000));

    final file = File('/tmp/gopal_cash_memo_sample.pdf');
    await file.writeAsBytes(pdfBytes);
  });

  test('PdfService generates luxury Cash Memo for fully paid bill with zero errors', () async {
    final bill = Bill(
      id: 'test-2',
      billNumber: 2,
      customerId: 'cust-2',
      customerName: 'Deepak Kumar',
      customerMobile: '9935006921',
      createdAt: DateTime(2026, 10, 10),
      deliveryDate: DateTime(2026, 10, 12),
      items: const [
        BillItem(
          id: 'item-1',
          particulars: 'Wedding Album 12x36 Matte Finish',
          size: '12X36',
          quantity: 1,
          rate: 4500,
          amount: 4500,
        ),
      ],
      totalAmount: 4500,
      advanceAmount: 2000,
      balanceAmount: 0,
      paidAmount: 4500,
      status: BillStatus.paid,
      paymentHistory: [
        PaymentEntry(
          id: 'pay-1',
          amount: 2000,
          type: PaymentType.cash,
          date: DateTime(2026, 10, 10, 11, 0),
          note: 'Booking Advance',
        ),
        PaymentEntry(
          id: 'pay-2',
          amount: 2500,
          type: PaymentType.upi,
          date: DateTime(2026, 10, 12, 18, 30),
          note: 'Final Handover Payment',
          upiRef: 'UPI/981726354123',
        ),
      ],
      notes: 'Delivered in premium box',
    );

    final profile = BusinessProfile.defaultProfile.copyWith(
      youtubeChannel: '@GopalPhotographyStudio',
      instagramHandle: '@gopal_photography_studio',
      upiId: 'gopalstudio@upi',
    );

    final pdfBytes = await PdfService.instance.generateBillPdf(bill, profile);
    expect(pdfBytes, isNotNull);
    expect(pdfBytes.length, greaterThan(1000));

    final file = File('/tmp/gopal_cash_memo_settled.pdf');
    await file.writeAsBytes(pdfBytes);
  });
}
