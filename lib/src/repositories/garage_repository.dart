import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:garage_management_system/src/models/garage_models.dart';
import 'package:garage_management_system/src/utils/garage_utils.dart';

class _InvoiceException implements Exception {
  _InvoiceException(this.message);
  final String message;
}

class GarageRepository {
  GarageRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  DocumentReference<Map<String, dynamic>> get _settingsRef =>
      _db.doc('settings/garage');

  Future<void> ensureSettings() async {
    final snapshot = await _settingsRef.get();
    if (!snapshot.exists) {
      await _settingsRef.set(GarageSettings.defaults().toMap());
    }
  }

  Stream<GarageSettings> watchSettings() {
    return _settingsRef.snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return GarageSettings.defaults();
      }
      return GarageSettings.fromMap(snapshot.data()!);
    });
  }

  Future<void> updateSettings(GarageSettings settings) async {
    await _settingsRef.set(settings.toMap(), SetOptions(merge: true));
  }

  Future<UserRole> loadUserRole() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return UserRole.admin;
    }
    final snapshot = await _db.doc('users/$uid').get();
    if (!snapshot.exists || snapshot.data() == null) {
      return UserRole.admin;
    }
    return userRoleFromFirestore(snapshot.data()!['role'] as String?);
  }

  Stream<List<Customer>> watchCustomers() {
    return _db
        .collection('customers')
        .orderBy('name')
        .snapshots()
        .map(_mapCustomers);
  }

  Future<Customer> addCustomer({
    required String name,
    required String mobile,
    required String address,
  }) async {
    final normalizedMobile = normalizeMobile(mobile);
    final existing = await findCustomerByMobile(normalizedMobile);
    if (existing != null) {
      throw StateError(
        'Party already exists: ${existing.name} (${existing.mobile})',
      );
    }

    final ref = _db.collection('customers').doc();
    final customer = Customer(
      id: ref.id,
      name: name,
      mobile: normalizedMobile,
      address: address,
    );
    await ref.set(customer.toMap());
    return customer;
  }

  Future<Customer?> findCustomerByMobile(String mobile) async {
    final normalizedMobile = normalizeMobile(mobile);
    if (normalizedMobile.isEmpty) {
      return null;
    }
    final snapshot = await _db
        .collection('customers')
        .where('mobile', isEqualTo: normalizedMobile)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      return null;
    }
    final doc = snapshot.docs.first;
    return Customer.fromMap(doc.id, doc.data());
  }

  Stream<List<Vehicle>> watchVehicles() {
    return _db
        .collection('vehicles')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_mapVehicles);
  }

  Future<Vehicle> addVehicle({
    required String customerId,
    required String regNumber,
    required String brand,
    required String model,
    required int year,
    required int lastKm,
  }) async {
    final ref = _db.collection('vehicles').doc();
    final vehicle = Vehicle(
      id: ref.id,
      customerId: customerId,
      regNumber: regNumber.toUpperCase(),
      regNumberNormalized: normalizeRegNumber(regNumber),
      brand: brand,
      model: model,
      year: year,
      lastKmReading: lastKm,
    );
    await ref.set(vehicle.toMap());
    return vehicle;
  }

  Stream<List<StockItem>> watchStockItems() {
    return _db
        .collection('stock_items')
        .orderBy('name')
        .snapshots()
        .map(_mapStockItems);
  }

  Future<StockItem> addStockItem({
    required String name,
    required String sku,
    required double price,
    required int currentStock,
    required int minStockAlert,
  }) async {
    final ref = _db.collection('stock_items').doc();
    final item = StockItem(
      id: ref.id,
      name: name,
      sku: sku,
      sellingPrice: price,
      currentStock: currentStock,
      minStockAlert: minStockAlert,
    );
    await ref.set(item.toMap());
    return item;
  }

  Future<void> updateStockItem(StockItem item) async {
    await _db.doc('stock_items/${item.id}').update(item.toMap());
  }

  Future<void> deleteStockItem(String id) async {
    await _db.doc('stock_items/$id').delete();
  }

  Stream<List<LabourItem>> watchLabourItems() {
    return _db
        .collection('labour_items')
        .orderBy('name')
        .snapshots()
        .map(_mapLabourItems);
  }

  Future<LabourItem> addLabourItem({
    required String name,
    required double defaultRate,
  }) async {
    final ref = _db.collection('labour_items').doc();
    final item = LabourItem(
      id: ref.id,
      name: name,
      defaultRate: defaultRate,
    );
    await ref.set(item.toMap());
    return item;
  }

  Future<void> updateLabourItem(LabourItem item) async {
    await _db.doc('labour_items/${item.id}').update(item.toMap());
  }

  Future<void> deleteLabourItem(String id) async {
    await _db.doc('labour_items/$id').delete();
  }

  Stream<List<JobCard>> watchJobCards() {
    return _db
        .collection('jobcards')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_mapJobCards);
  }

  Future<JobCard> addJobCard({
    required String customerId,
    required String vehicleId,
    required int kmReading,
    required String fuelLevel,
    required String customerComplaints,
    required List<String> complaintItems,
    required String observations,
    required String requestedWorks,
    required String otherNotes,
    required String internalNotes,
    String remarks = '',
    required String mechanicName,
    DateTime? estimatedDelivery,
  }) async {
    final settingsRef = _settingsRef;
    final jobCardRef = _db.collection('jobcards').doc();

    return _db.runTransaction((transaction) async {
      final settingsSnap = await transaction.get(settingsRef);
      final jobCardNumber = settingsSnap.exists
          ? (settingsSnap.data()?['nextJobCardNumber'] as num?)?.toInt() ?? 900
          : 900;

      final card = JobCard(
        id: jobCardRef.id,
        jobCardNumber: jobCardNumber,
        customerId: customerId,
        vehicleId: vehicleId,
        kmReading: kmReading,
        fuelLevel: fuelLevel,
        customerComplaints: customerComplaints,
        complaintItems: complaintItems,
        observations: observations,
        requestedWorks: requestedWorks,
        otherNotes: otherNotes,
        internalNotes: internalNotes,
        remarks: remarks,
        mechanicName: mechanicName,
        estimatedDelivery: estimatedDelivery,
        status: JobStatus.pending,
        createdAt: DateTime.now(),
      );

      transaction.set(jobCardRef, card.toMap(jobCardNumber: jobCardNumber));
      transaction.set(
        settingsRef,
        {'nextJobCardNumber': jobCardNumber + 1},
        SetOptions(merge: true),
      );

      return card;
    });
  }

  Future<void> updateJobCardStatus(String id, JobStatus status) async {
    await _db.doc('jobcards/$id').update({'status': status.firestoreValue});
  }

  Stream<List<Estimate>> watchEstimates() {
    return _db
        .collection('estimates')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_mapEstimates);
  }

  Future<bool> createEstimate({
    String? jobCardId,
    String? customerId,
    String? vehicleId,
    int? kmReading,
    required List<InvoiceLineDraft> labourItems,
    required List<PartLineDraft> partsItems,
    String remarks = '',
    required Iterable<StockItem> stockItems,
    required String Function(String vehicleId) vehicleNumberFor,
  }) async {
    if (labourItems.isEmpty && partsItems.isEmpty) {
      return false;
    }

    String resolvedCustomerId;
    String resolvedVehicleId;
    int resolvedKm;
    String? linkedJobCardId;

    if (jobCardId != null) {
      final snapshot = await _db.doc('jobcards/$jobCardId').get();
      if (!snapshot.exists || snapshot.data() == null) {
        return false;
      }
      final jobCard = JobCard.fromMap(jobCardId, snapshot.data()!);
      resolvedCustomerId = jobCard.customerId;
      resolvedVehicleId = jobCard.vehicleId;
      resolvedKm = jobCard.kmReading;
      linkedJobCardId = jobCard.id;
    } else if (customerId != null && vehicleId != null) {
      resolvedCustomerId = customerId;
      resolvedVehicleId = vehicleId;
      resolvedKm = kmReading ?? 0;
    } else {
      return false;
    }

    final partRecords = _partRecordsFromDrafts(partsItems, stockItems);
    final labourTotal =
        labourItems.fold<double>(0, (sum, item) => sum + item.amount);
    final partsTotal =
        partRecords.fold<double>(0, (sum, item) => sum + item.amount);

    final settingsRef = _settingsRef;
    final estimateRef = _db.collection('estimates').doc();

    await _db.runTransaction((transaction) async {
      final settingsSnap = await transaction.get(settingsRef);
      final estimateNumber = settingsSnap.exists
          ? (settingsSnap.data()?['nextEstimateNumber'] as num?)?.toInt() ?? 1
          : 1;

      final estimate = Estimate(
        id: estimateRef.id,
        estimateNumber: estimateNumber,
        jobCardId: linkedJobCardId,
        customerId: resolvedCustomerId,
        vehicleId: resolvedVehicleId,
        vehicleNumber: vehicleNumberFor(resolvedVehicleId),
        kmReading: resolvedKm,
        labourItems: List.of(labourItems),
        partsItems: partRecords,
        labourTotal: labourTotal,
        partsTotal: partsTotal,
        remarks: remarks,
        status: EstimateStatus.sent,
        createdAt: DateTime.now(),
      );

      transaction.set(estimateRef, estimate.toMap(estimateNumber: estimateNumber));
      transaction.set(
        settingsRef,
        {'nextEstimateNumber': estimateNumber + 1},
        SetOptions(merge: true),
      );
    });

    return true;
  }

  Future<String?> updateInvoicePayment({
    required String invoiceId,
    required double amountPaid,
    required PaymentStatus paymentStatus,
  }) async {
    try {
      await _db.doc('invoices/$invoiceId').update({
        'amountPaid': amountPaid,
        'paymentStatus': paymentStatus.name,
      });
      return null;
    } catch (error) {
      return 'Could not update payment: $error';
    }
  }

  Future<String?> updateInvoice({
    required String invoiceId,
    required List<InvoiceLineDraft> labourItems,
    required List<PartLineDraft> partsItems,
    String remarks = '',
    required Iterable<StockItem> stockItems,
  }) async {
    if (labourItems.isEmpty && partsItems.isEmpty) {
      return 'Add at least one labour item or part';
    }

    try {
      await _db.runTransaction((transaction) async {
        final invoiceRef = _db.doc('invoices/$invoiceId');
        final invoiceSnap = await transaction.get(invoiceRef);
        if (!invoiceSnap.exists || invoiceSnap.data() == null) {
          throw _InvoiceException('Invoice not found');
        }

        final existing = Invoice.fromMap(invoiceId, invoiceSnap.data()!);
        final partRecords = _partRecordsFromDrafts(partsItems, stockItems);
        final stockSnaps = await _readStockSnapshots(
          transaction,
          [...existing.partsItems, ...partRecords],
        );

        _applyInvoiceStockAdjustment(
          transaction: transaction,
          invoiceId: invoiceId,
          oldParts: existing.partsItems,
          newParts: partRecords,
          stockSnaps: stockSnaps,
        );

        final labourTotal =
            labourItems.fold<double>(0, (sum, item) => sum + item.amount);
        final partsTotal =
            partRecords.fold<double>(0, (sum, item) => sum + item.amount);
        final grandTotal = labourTotal + partsTotal;
        final clampedPaid =
            existing.amountPaid.clamp(0, grandTotal).toDouble();
        final resolvedStatus =
            paymentStatusForAmount(clampedPaid, grandTotal);

        transaction.update(invoiceRef, {
          'labourItems': labourItems.map((item) => item.toMap()).toList(),
          'partsItems': partRecords.map((item) => item.toMap()).toList(),
          'labourTotal': labourTotal,
          'partsTotal': partsTotal,
          'amountPaid': clampedPaid,
          'paymentStatus': resolvedStatus.name,
          'remarks': remarks,
        });
      });
      return null;
    } on _InvoiceException catch (error) {
      return error.message;
    } catch (error) {
      return 'Could not update invoice: $error';
    }
  }

  Future<bool> updateEstimate({
    required String id,
    required List<InvoiceLineDraft> labourItems,
    required List<PartLineDraft> partsItems,
    String remarks = '',
    required Iterable<StockItem> stockItems,
  }) async {
    if (labourItems.isEmpty && partsItems.isEmpty) {
      return false;
    }

    final ref = _db.doc('estimates/$id');
    final snapshot = await ref.get();
    if (!snapshot.exists || snapshot.data() == null) {
      return false;
    }

    final existing = Estimate.fromMap(id, snapshot.data()!);
    if (existing.status == EstimateStatus.converted) {
      return false;
    }

    final partRecords = _partRecordsFromDrafts(partsItems, stockItems);
    final labourTotal =
        labourItems.fold<double>(0, (sum, item) => sum + item.amount);
    final partsTotal =
        partRecords.fold<double>(0, (sum, item) => sum + item.amount);

    await ref.update({
      'labourItems': labourItems.map((item) => item.toMap()).toList(),
      'partsItems': partRecords.map((item) => item.toMap()).toList(),
      'labourTotal': labourTotal,
      'partsTotal': partsTotal,
      'remarks': remarks,
    });
    return true;
  }

  Future<void> updateEstimateStatus(String id, EstimateStatus status) async {
    if (status == EstimateStatus.converted) {
      return;
    }
    await _db.doc('estimates/$id').update({'status': status.name});
  }

  Future<void> reopenEstimate(String id) async {
    await _db.doc('estimates/$id').update({'status': EstimateStatus.approved.name});
  }

  Stream<List<Invoice>> watchInvoices() {
    return _db
        .collection('invoices')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_mapInvoices);
  }

  Stream<List<StockTransaction>> watchStockTransactions() {
    return _db
        .collection('stock_transactions')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map(_mapStockTransactions);
  }

  Stream<List<PaymentRecord>> watchPayments() {
    return _db
        .collection('payments')
        .orderBy('createdAt', descending: true)
        .limit(500)
        .snapshots()
        .map(_mapPayments);
  }

  Future<String?> addPaymentReceipt({
    required String customerId,
    String? invoiceId,
    required double amount,
    String note = '',
  }) async {
    if (amount <= 0) {
      return 'Enter a valid amount';
    }
    try {
      final ref = _db.collection('payments').doc();
      await ref.set(
        PaymentRecord(
          id: ref.id,
          customerId: customerId,
          invoiceId: invoiceId,
          amount: amount,
          note: note,
          createdAt: DateTime.now(),
        ).toMap(),
      );
      if (invoiceId != null) {
        await _syncInvoicePaymentFromRecords(invoiceId);
      }
      return null;
    } catch (error) {
      return 'Could not record payment: $error';
    }
  }

  Future<String?> applyAdvanceToInvoice({
    required String paymentId,
    required String invoiceId,
  }) async {
    try {
      final paymentRef = _db.doc('payments/$paymentId');
      final paymentSnap = await paymentRef.get();
      if (!paymentSnap.exists || paymentSnap.data() == null) {
        return 'Advance payment not found';
      }
      final payment = PaymentRecord.fromMap(paymentId, paymentSnap.data()!);
      if (!payment.isAdvance) {
        return 'Payment is already linked to a bill';
      }

      final invoiceSnap = await _db.doc('invoices/$invoiceId').get();
      if (!invoiceSnap.exists || invoiceSnap.data() == null) {
        return 'Invoice not found';
      }
      final invoice = Invoice.fromMap(invoiceId, invoiceSnap.data()!);
      if (invoice.customerId != payment.customerId) {
        return 'Advance belongs to a different customer';
      }
      if (invoice.balanceAmount <= 0) {
        return 'Invoice is already fully paid';
      }

      await paymentRef.update({'invoiceId': invoiceId});
      await _syncInvoicePaymentFromRecords(invoiceId);
      return null;
    } catch (error) {
      return 'Could not apply advance: $error';
    }
  }

  Future<void> _syncInvoicePaymentFromRecords(String invoiceId) async {
    final snapshot = await _db
        .collection('payments')
        .where('invoiceId', isEqualTo: invoiceId)
        .get();
    final totalPaid = snapshot.docs.fold<double>(
      0,
      (sum, doc) => sum + ((doc.data()['amount'] as num?)?.toDouble() ?? 0),
    );

    final invoiceSnap = await _db.doc('invoices/$invoiceId').get();
    if (!invoiceSnap.exists || invoiceSnap.data() == null) {
      return;
    }
    final invoice = Invoice.fromMap(invoiceId, invoiceSnap.data()!);
    final clampedPaid = totalPaid.clamp(0, invoice.grandTotal).toDouble();
    final status = paymentStatusForAmount(clampedPaid, invoice.grandTotal);
    await _db.doc('invoices/$invoiceId').update({
      'amountPaid': clampedPaid,
      'paymentStatus': status.name,
    });
  }

  Future<String?> convertJobCardToInvoice({
    required String jobCardId,
    required List<InvoiceLineDraft> labourItems,
    required List<PartLineDraft> partsItems,
    required PaymentStatus paymentStatus,
    required double amountPaid,
    required Iterable<StockItem> stockItems,
  }) async {
    final partRecords = _partRecordsFromDrafts(partsItems, stockItems);
    try {
      await _db.runTransaction((transaction) async {
        final jobCardRef = _db.doc('jobcards/$jobCardId');
        final invoiceRef = _db.collection('invoices').doc();

        final settingsSnap = await transaction.get(_settingsRef);
        final jobCardSnap = await transaction.get(jobCardRef);

        if (!jobCardSnap.exists || jobCardSnap.data() == null) {
          throw _InvoiceException('Job card not found');
        }

        final jobCard = JobCard.fromMap(jobCardId, jobCardSnap.data()!);
        final invoiceNumber = settingsSnap.exists
            ? (settingsSnap.data()?['nextInvoiceNumber'] as num?)?.toInt() ?? 1
            : 1;

        final stockSnaps = await _readStockSnapshots(transaction, partRecords);
        final vehicleNumber = await _vehicleNumberInTransaction(
          transaction,
          jobCard.vehicleId,
        );
        _applyStockDeduction(
          transaction: transaction,
          partsItems: partRecords,
          invoiceId: invoiceRef.id,
          stockSnaps: stockSnaps,
        );

        final labourTotal =
            labourItems.fold<double>(0, (sum, item) => sum + item.amount);
        final partsTotal =
            partRecords.fold<double>(0, (sum, item) => sum + item.amount);

        transaction.set(invoiceRef, {
          'invoiceNumber': invoiceNumber,
          'jobCardId': jobCardId,
          'customerId': jobCard.customerId,
          'vehicleId': jobCard.vehicleId,
          'vehicleNumber': vehicleNumber,
          'kmReading': jobCard.kmReading,
          'labourItems': labourItems.map((item) => item.toMap()).toList(),
          'partsItems': partRecords.map((item) => item.toMap()).toList(),
          'labourTotal': labourTotal,
          'partsTotal': partsTotal,
          'grandTotal': labourTotal + partsTotal,
          'amountPaid': amountPaid,
          'paymentStatus': paymentStatus.name,
          'remarks': jobCard.remarks,
          'createdAt': FieldValue.serverTimestamp(),
        });

        transaction.update(jobCardRef, {'status': JobStatus.delivered.firestoreValue});
        transaction.set(
          _settingsRef,
          {'nextInvoiceNumber': invoiceNumber + 1},
          SetOptions(merge: true),
        );
      });
      return null;
    } on _InvoiceException catch (error) {
      return error.message;
    } catch (error) {
      return 'Invoice failed: $error';
    }
  }

  Future<String?> convertEstimateToInvoice(String estimateId) async {
    try {
      await _db.runTransaction((transaction) async {
        final estimateRef = _db.doc('estimates/$estimateId');
        final invoiceRef = _db.collection('invoices').doc();

        final settingsSnap = await transaction.get(_settingsRef);
        final estimateSnap = await transaction.get(estimateRef);

        if (!estimateSnap.exists || estimateSnap.data() == null) {
          throw _InvoiceException('Estimate not found');
        }

        final estimate = Estimate.fromMap(estimateId, estimateSnap.data()!);
        if (estimate.status == EstimateStatus.converted) {
          throw _InvoiceException('Estimate already converted');
        }

        final invoiceNumber = settingsSnap.exists
            ? (settingsSnap.data()?['nextInvoiceNumber'] as num?)?.toInt() ?? 1
            : 1;

        final stockSnaps =
            await _readStockSnapshots(transaction, estimate.partsItems);
        _applyStockDeduction(
          transaction: transaction,
          partsItems: estimate.partsItems,
          invoiceId: invoiceRef.id,
          stockSnaps: stockSnaps,
        );

        transaction.set(invoiceRef, {
          'invoiceNumber': invoiceNumber,
          'jobCardId': estimate.jobCardId,
          'customerId': estimate.customerId,
          'vehicleId': estimate.vehicleId,
          'vehicleNumber': estimate.vehicleNumber,
          'kmReading': estimate.kmReading,
          'labourItems':
              estimate.labourItems.map((item) => item.toMap()).toList(),
          'partsItems':
              estimate.partsItems.map((item) => item.toMap()).toList(),
          'labourTotal': estimate.labourTotal,
          'partsTotal': estimate.partsTotal,
          'grandTotal': estimate.grandTotal,
          'amountPaid': 0,
          'paymentStatus': PaymentStatus.unpaid.name,
          'remarks': estimate.remarks,
          'createdAt': FieldValue.serverTimestamp(),
        });

        transaction.update(estimateRef, {'status': EstimateStatus.converted.name});

        if (estimate.jobCardId != null) {
          transaction.update(
            _db.doc('jobcards/${estimate.jobCardId}'),
            {'status': JobStatus.delivered.firestoreValue},
          );
        }

        transaction.set(
          _settingsRef,
          {'nextInvoiceNumber': invoiceNumber + 1},
          SetOptions(merge: true),
        );
      });
      return null;
    } on _InvoiceException catch (error) {
      return error.message;
    } catch (error) {
      return 'Invoice failed: $error';
    }
  }

  Future<Map<String, DocumentSnapshot<Map<String, dynamic>>>> _readStockSnapshots(
    Transaction transaction,
    List<InvoicePartLine> partsItems,
  ) async {
    final ids = partsItems.map((part) => part.stockItemId).toSet();
    final snaps = <String, DocumentSnapshot<Map<String, dynamic>>>{};
    for (final id in ids) {
      snaps[id] = await transaction.get(_db.doc('stock_items/$id'));
    }
    return snaps;
  }

  Future<String> _vehicleNumberInTransaction(
    Transaction transaction,
    String vehicleId,
  ) async {
    final snap = await transaction.get(_db.doc('vehicles/$vehicleId'));
    if (!snap.exists || snap.data() == null) {
      return 'Unknown vehicle';
    }
    return snap.data()!['regNumber'] as String? ?? 'Unknown vehicle';
  }

  void _applyInvoiceStockAdjustment({
    required Transaction transaction,
    required String invoiceId,
    required List<InvoicePartLine> oldParts,
    required List<InvoicePartLine> newParts,
    required Map<String, DocumentSnapshot<Map<String, dynamic>>> stockSnaps,
  }) {
    final oldTotals = <String, int>{};
    for (final part in oldParts) {
      oldTotals[part.stockItemId] =
          (oldTotals[part.stockItemId] ?? 0) + part.qty;
    }
    final newTotals = <String, int>{};
    for (final part in newParts) {
      newTotals[part.stockItemId] = (newTotals[part.stockItemId] ?? 0) + part.qty;
    }

    final stockIds = {...oldTotals.keys, ...newTotals.keys};
    for (final stockId in stockIds) {
      final oldQty = oldTotals[stockId] ?? 0;
      final newQty = newTotals[stockId] ?? 0;
      final netChange = newQty - oldQty;
      if (netChange == 0) {
        continue;
      }

      final snap = stockSnaps[stockId];
      if (snap == null || !snap.exists || snap.data() == null) {
        if (netChange > 0) {
          throw _InvoiceException('Stock item $stockId missing');
        }
        continue;
      }

      final current = (snap.data()!['currentStock'] as num?)?.toInt() ?? 0;
      if (netChange > 0) {
        if (current < netChange) {
          final name = snap.data()!['name'] as String? ?? stockId;
          throw _InvoiceException('Insufficient stock for $name');
        }
        transaction.update(snap.reference, {
          'currentStock': current - netChange,
        });
        transaction.set(_db.collection('stock_transactions').doc(), {
          'stockItemId': stockId,
          'type': 'out',
          'qty': netChange,
          'referenceType': 'invoice_edit',
          'referenceId': invoiceId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        final returnQty = -netChange;
        transaction.update(snap.reference, {
          'currentStock': current + returnQty,
        });
        transaction.set(_db.collection('stock_transactions').doc(), {
          'stockItemId': stockId,
          'type': 'in',
          'qty': returnQty,
          'referenceType': 'invoice_edit',
          'referenceId': invoiceId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  void _applyStockDeduction({
    required Transaction transaction,
    required List<InvoicePartLine> partsItems,
    required String invoiceId,
    required Map<String, DocumentSnapshot<Map<String, dynamic>>> stockSnaps,
  }) {
    final totals = <String, int>{};
    final names = <String, String>{};
    for (final part in partsItems) {
      totals[part.stockItemId] = (totals[part.stockItemId] ?? 0) + part.qty;
      names[part.stockItemId] = part.name;
    }

    for (final entry in totals.entries) {
      final snap = stockSnaps[entry.key];
      if (snap == null || !snap.exists || snap.data() == null) {
        throw _InvoiceException('Stock item ${entry.key} missing');
      }
      final current =
          (snap.data()!['currentStock'] as num?)?.toInt() ?? 0;
      if (current < entry.value) {
        throw _InvoiceException(
          'Insufficient stock for ${names[entry.key] ?? entry.key}',
        );
      }
      transaction.update(snap.reference, {
        'currentStock': current - entry.value,
      });
    }

    for (final part in partsItems) {
      transaction.set(_db.collection('stock_transactions').doc(), {
        'stockItemId': part.stockItemId,
        'type': 'out',
        'qty': part.qty,
        'referenceType': 'invoice',
        'referenceId': invoiceId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  List<Customer> _mapCustomers(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map((doc) => Customer.fromMap(doc.id, doc.data()))
        .toList();
  }

  List<Vehicle> _mapVehicles(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map((doc) => Vehicle.fromMap(doc.id, doc.data()))
        .toList();
  }

  List<StockItem> _mapStockItems(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map((doc) => StockItem.fromMap(doc.id, doc.data()))
        .toList();
  }

  List<LabourItem> _mapLabourItems(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map((doc) => LabourItem.fromMap(doc.id, doc.data()))
        .toList();
  }

  List<JobCard> _mapJobCards(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map((doc) => JobCard.fromMap(doc.id, doc.data()))
        .toList();
  }

  List<Estimate> _mapEstimates(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map((doc) => Estimate.fromMap(doc.id, doc.data()))
        .toList();
  }

  List<Invoice> _mapInvoices(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map((doc) => Invoice.fromMap(doc.id, doc.data()))
        .toList();
  }

  List<StockTransaction> _mapStockTransactions(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map((doc) => StockTransaction.fromMap(doc.id, doc.data()))
        .toList();
  }

  List<PaymentRecord> _mapPayments(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map((doc) => PaymentRecord.fromMap(doc.id, doc.data()))
        .toList();
  }

  List<InvoicePartLine> _partRecordsFromDrafts(
    List<PartLineDraft> partsItems,
    Iterable<StockItem> stockItems,
  ) {
    return partsItems.map((line) {
      final stock =
          stockItems.where((item) => item.id == line.stockItemId).firstOrNull;
      if (stock == null) {
        return const InvoicePartLine(
          stockItemId: 'NA',
          name: 'Unknown item',
          qty: 0,
          unitPrice: 0,
        );
      }
      return InvoicePartLine(
        stockItemId: stock.id,
        name: stock.name,
        qty: line.qty,
        unitPrice: stock.sellingPrice,
      );
    }).toList();
  }
}
