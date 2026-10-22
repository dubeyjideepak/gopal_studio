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

  test('PdfService generates universal business cash memo with custom branding', () async {
    final bill = Bill(
      id: 'test-universal',
      billNumber: 108,
      customerId: 'cust-108',
      customerName: 'Vikram Malhotra',
      customerMobile: '9812345678',
      createdAt: DateTime(2026, 10, 12, 11, 30),
      deliveryDate: DateTime(2026, 10, 25),
      items: const [
        BillItem(
          id: 'item-1',
          particulars: 'Custom Designer Wardrobe & Furniture',
          size: '6x4 Ft | Teak Wood Matte Finish',
          quantity: 1,
          rate: 18000,
          amount: 18000,
        ),
        BillItem(
          id: 'item-2',
          particulars: 'Smart 4K LED Display & Audio System',
          size: '43 Inch UHD | 2 Yr On-site Warranty',
          quantity: 1,
          rate: 22000,
          amount: 22000,
        ),
        BillItem(
          id: 'item-3',
          particulars: 'Express Delivery & Setup Service',
          size: 'Standard Wall Mount Included',
          quantity: 1,
          rate: 1500,
          amount: 1500,
        ),
      ],
      totalAmount: 41500,
      advanceAmount: 15000,
      balanceAmount: 10000,
      paidAmount: 31500,
      status: BillStatus.partial,
      paymentHistory: [
        PaymentEntry(
          id: 'pay-1',
          amount: 15000,
          type: PaymentType.cash,
          date: DateTime(2026, 10, 12, 11, 30),
          note: 'Order Booking Advance Token',
        ),
        PaymentEntry(
          id: 'pay-2',
          amount: 16500,
          type: PaymentType.upi,
          date: DateTime(2026, 10, 18, 16, 45),
          note: 'Dispatch & Assembly Progress Payment',
          upiRef: 'UPI/729182930192',
        ),
      ],
      notes: 'Final balance payable at customer home handover',
    );

    final profile = BusinessProfile(
      id: 'universal-profile',
      businessName: 'ROYAL ENTERPRISES',
      ownerName: 'Business Owner',
      tagline: 'Quality Products & Reliable Service',
      address: 'Main Market Road, City Center',
      phone1: '9876543210',
      phone2: '9876543211',
      youtubeChannel: '@RoyalEnterprisesOfficial',
      instagramHandle: '@royal_enterprises_official',
      upiId: 'royalenterprises@upi',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 10, 12),
    );

    final pdfBytes = await PdfService.instance.generateBillPdf(bill, profile);
    expect(pdfBytes, isNotNull);
    expect(pdfBytes.length, greaterThan(1000));

    final file = File('/tmp/generic_studio_memo_sample.pdf');
    await file.writeAsBytes(pdfBytes);
  });
}
