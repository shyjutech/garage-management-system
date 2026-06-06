# Sarathi Garage Management System

Phase 1 Flutter Web + Firebase implementation for SARATHI AUTOMOBILES.

## Modules included

- Dashboard metrics (sales, pending payments, low stock, in-service vehicles)
- Party (customer) and vehicle management
- Vehicle history search with registration normalization
- Stock management and low-stock alerts
- Job cards with workflow statuses
- Invoice creation with split labour and parts sections
- Payment status tracking (paid/unpaid/partial)
- Printable SARATHI-style PDF invoice
- Settings and role definitions

## Local run

```bash
flutter pub get
flutter run -d chrome
```

## Firebase setup

1. Update `lib/src/firebase_options.dart` with your Firebase app credentials.
2. Install Firebase CLI and login.
3. Deploy rules/indexes/functions when ready:

```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
cd functions && npm install && npm run build && cd ..
firebase deploy --only functions,hosting,storage
```

## Collections used

`customers`, `vehicles`, `jobcards`, `invoices`, `stock_items`, `stock_transactions`, `payments`, `settings`, `users`
