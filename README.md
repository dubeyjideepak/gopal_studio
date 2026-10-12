# 📸 Gopal Photography Studio Pro — Billing Software

A cross-platform billing, client ledger & cash memo software tailored for **Gopal Photography Studio & Video Mixing Lab** (Lalganj Ajhara, Pratapgarh).

---

## 🌟 Key Features

1. **Exact Cash Memo & Envelope Styling**
   - Theme inspired by the Studio cover: **Charcoal (#0D0D0D)** + **Rich Gold (#C9A84C)**.
   - Dual output: Professional **A4 PDF** and on-screen **Slip Preview** matching the physical print voucher format.
   - Prints: S.No, Particulars/Size, Qty, Rate, Amount, Total, Advance, and Balance Due.

2. **UPI QR Code on Hard & Soft Copy**
   - Automatically renders dynamic **UPI QR codes** embedded inside every receipt and printable PDF.
   - Customers can scan with Google Pay, PhonePe, or Paytm instantly to clear advance or dues.

3. **WhatsApp Share & Auto Payment Reminders**
   - One-touch WhatsApp bill sharing (pre-formatted receipt text + amounts).
   - Smart payment reminder templates with polite Indian rupee reminders.
   - Delivery date collection reminders.

4. **Accounts, Advance & Settlements Management**
   - Customer-wise ledger: tracks total dues, total advances, and remaining balances.
   - Partial payment settlements against outstanding bills.
   - Payment mode tracking (**Cash**, **UPI**, or both).

5. **Cloud Sync & Zero Data Loss**
   - Offline-first SQLite local store: bills are saved immediately without lag.
   - Cloud Firestore synchronization layer ensures all bills and customer records are backed up automatically.

6. **Continuous Delivery & Auto-Updates**
   - Ready-to-use `.github/workflows/build_and_release.yml` builds Android APKs and Web distributions automatically whenever a new version tag is pushed.

7. **Built-in AI Assistant (Gemini 1.5 Flash)**
   - Smart pricing suggestions based on historical photo print sizes.
   - Hinglish WhatsApp reminder generation.
   - Duplicate customer detection & auto-categorization.

---

## 🚀 Running the App

```bash
# Navigate to project
cd gopal_studio_pro

# Get dependencies
flutter pub get

# Run on macOS / Chrome / Android / iOS
flutter run
```
