import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:garage_management_system/src/models/garage_models.dart';
import 'package:garage_management_system/src/utils/garage_utils.dart';

class GarageRepository {
  GarageRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;
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
    final ref = _db.collection('customers').doc();
    final customer = Customer(
      id: ref.id,
      name: name,
      mobile: mobile,
      address: address,
    );
    await ref.set(customer.toMap());
    return customer;
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
    String notes = '',
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
        notes: notes,
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

  Future<bool> convertJobCardToInvoice({
    required String jobCardId,
    required List<InvoiceLineDraft> labourItems,
    required List<PartLineDraft> partsItems,
    required PaymentStatus paymentStatus,
    required double amountPaid,
    required Iterable<StockItem> stockItems,
  }) async {
    final callable = _functions.httpsCallable('createInvoiceFromJobCard');
    try {
      await callable.call<Map<String, dynamic>>({
        'jobCardId': jobCardId,
        'labourItems': labourItemsToCallable(labourItems),
        'partsItems': partsDraftsToCallable(partsItems, stockItems),
        'amountPaid': amountPaid,
        'paymentStatus': paymentStatus.name,
      });
      return true;
    } on FirebaseFunctionsException {
      return false;
    }
  }

  Future<bool> convertEstimateToInvoice(String estimateId) async {
    final callable = _functions.httpsCallable('createInvoiceFromEstimate');
    try {
      await callable.call<Map<String, dynamic>>({'estimateId': estimateId});
      return true;
    } on FirebaseFunctionsException {
      return false;
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
