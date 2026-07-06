import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:garage_management_system/src/models/garage_models.dart';
import 'package:garage_management_system/src/repositories/garage_repository.dart';
import 'package:garage_management_system/src/utils/garage_utils.dart';

class GarageStore extends ChangeNotifier {
  GarageStore.memory()
      : _repo = null,
        settings = GarageSettings.defaults();

  GarageStore.firestore(GarageRepository repo)
      : _repo = repo,
        settings = GarageSettings.defaults();

  final GarageRepository? _repo;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  bool _disposed = false;
  bool _initialized = false;

  final customers = <Customer>[];
  final vehicles = <Vehicle>[];
  final stockItems = <StockItem>[];
  final labourItems = <LabourItem>[];
  final jobCards = <JobCard>[];
  final estimates = <Estimate>[];
  final invoices = <Invoice>[];
  final stockTransactions = <StockTransaction>[];
  final payments = <PaymentRecord>[];
  final expenses = <Expense>[];

  GarageSettings settings;
  UserRole activeRole = UserRole.admin;
  bool loading = false;
  String? lastError;
  String? pendingEstimateJobCardId;

  bool get useFirestore => _repo != null;

  void openEstimateForJobCard(String jobCardId) {
    pendingEstimateJobCardId = jobCardId;
    notifyListeners();
  }

  void clearPendingEstimateJobCard() {
    if (pendingEstimateJobCardId == null) {
      return;
    }
    pendingEstimateJobCardId = null;
    notifyListeners();
  }

  int _customerCounter = 1;
  int _vehicleCounter = 1;
  int _stockCounter = 1;
  int _labourCounter = 1;
  int _paymentCounter = 1;
  int _expenseCounter = 1;

  Future<void> initialize() async {
    final repo = _repo;
    if (repo == null || _initialized || _disposed) {
      return;
    }
    _initialized = true;
    loading = true;
    notifyListeners();

    try {
      await repo.ensureSettings();
      if (_disposed) {
        return;
      }
      activeRole = await repo.loadUserRole();
      if (_disposed) {
        return;
      }

      _subscriptions
        ..add(repo.watchSettings().listen((value) {
          if (_disposed) {
            return;
          }
          settings = value;
          notifyListeners();
        }))
        ..add(repo.watchCustomers().listen((value) {
          if (_disposed) {
            return;
          }
          customers
            ..clear()
            ..addAll(value);
          notifyListeners();
        }))
        ..add(repo.watchVehicles().listen((value) {
          if (_disposed) {
            return;
          }
          vehicles
            ..clear()
            ..addAll(value);
          notifyListeners();
        }))
        ..add(repo.watchStockItems().listen((value) {
          if (_disposed) {
            return;
          }
          stockItems
            ..clear()
            ..addAll(value);
          notifyListeners();
        }))
        ..add(repo.watchLabourItems().listen((value) {
          if (_disposed) {
            return;
          }
          labourItems
            ..clear()
            ..addAll(value);
          notifyListeners();
        }))
        ..add(repo.watchJobCards().listen((value) {
          if (_disposed) {
            return;
          }
          jobCards
            ..clear()
            ..addAll(value);
          notifyListeners();
        }))
        ..add(repo.watchEstimates().listen((value) {
          if (_disposed) {
            return;
          }
          estimates
            ..clear()
            ..addAll(value);
          notifyListeners();
        }))
        ..add(repo.watchInvoices().listen((value) {
          if (_disposed) {
            return;
          }
          invoices
            ..clear()
            ..addAll(value);
          notifyListeners();
        }))
        ..add(repo.watchStockTransactions().listen((value) {
          if (_disposed) {
            return;
          }
          stockTransactions
            ..clear()
            ..addAll(value);
          notifyListeners();
        }))
        ..add(repo.watchPayments().listen((value) {
          if (_disposed) {
            return;
          }
          payments
            ..clear()
            ..addAll(value);
          notifyListeners();
        }))
        ..add(repo.watchExpenses().listen((value) {
          if (_disposed) {
            return;
          }
          expenses
            ..clear()
            ..addAll(value);
          notifyListeners();
        }));
    } catch (error) {
      if (!_disposed) {
        lastError = error.toString();
      }
    } finally {
      if (!_disposed) {
        loading = false;
        notifyListeners();
      }
    }
  }

  @override
  void notifyListeners() {
    if (_disposed) {
      return;
    }
    super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    super.dispose();
  }

  void seed() {
    if (!useFirestore && customers.isEmpty) {
      _seedDemoData();
    }
  }

  void _seedDemoData() {
    final customer = _addCustomerMemory(
      name: 'KRISHNAN K',
      mobile: '9961913343',
      address: 'Karimbil Kumbalapalli',
    );
    final vehicle = _addVehicleMemory(
      customerId: customer.id,
      regNumber: 'KL60K3139',
      brand: 'MARUTI',
      model: 'DZIRE',
      year: 2016,
      lastKm: 84210,
      notify: false,
    );
    _addStockItemMemory(
      name: 'Timing Belt',
      sku: 'TB-001',
      price: 590,
      currentStock: 12,
      minStockAlert: 3,
      notify: false,
    );
    _addStockItemMemory(
      name: 'Tensioner',
      sku: 'TN-002',
      price: 715,
      currentStock: 8,
      minStockAlert: 2,
      notify: false,
    );
    _addLabourItemMemory(name: 'Painting', defaultRate: 2500, notify: false);
    _addLabourItemMemory(name: 'Welding', defaultRate: 800, notify: false);
    _addLabourItemMemory(name: 'General Service', defaultRate: 500, notify: false);
    _addLabourItemMemory(name: 'AC Repair', defaultRate: 1200, notify: false);
    _addLabourItemMemory(name: 'Denting', defaultRate: 1500, notify: false);
    _addJobCardMemory(
      customerId: customer.id,
      vehicleId: vehicle.id,
      kmReading: 84500,
      fuelLevel: 'Half',
      customerComplaints: 'Timing belt noise on cold start',
      complaintItems: const ['Timing belt replace', 'Check tensioner'],
      observations: 'Belt worn, tensioner weak',
      requestedWorks: 'Replace timing belt and tensioner',
      otherNotes: '',
      internalNotes: '',
      remarks: '',
      mechanicName: 'Anoop',
      notify: false,
    );
    _createEstimateMemory(
      jobCardId: jobCards.first.id,
      labourItems: const [
        InvoiceLineDraft(description: 'TIMING BELT REPLACE', amount: 3000),
        InvoiceLineDraft(description: 'ALTERNATOR R&R', amount: 1400),
      ],
      partsItems: [
        PartLineDraft(stockItemId: stockItems[0].id, qty: 1),
        PartLineDraft(stockItemId: stockItems[1].id, qty: 1),
      ],
      remarks: 'Valid for 7 days',
      notify: false,
    );
    updateJobCardStatus(jobCards.first.id, JobStatus.completed, notify: false);
    notifyListeners();
  }

  Future<Customer?> addCustomer({
    required String name,
    required String mobile,
    required String address,
  }) async {
    final normalizedMobile = normalizeMobile(mobile);
    final existing = customerByMobile(normalizedMobile);
    if (existing != null) {
      lastError =
          'Party already exists: ${existing.name} (${existing.mobile})';
      notifyListeners();
      return null;
    }

    if (_repo == null) {
      return _addCustomerMemory(
        name: name,
        mobile: normalizedMobile,
        address: address,
      );
    }
    try {
      return await _repo.addCustomer(
        name: name,
        mobile: normalizedMobile,
        address: address,
      );
    } catch (error) {
      lastError = error.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateCustomer(Customer customer, {bool notify = true}) async {
    final mobileError = _validateMobileForUpdate(customer);
    if (mobileError != null) {
      lastError = mobileError;
      if (notify) {
        notifyListeners();
      }
      return false;
    }

    if (_repo != null) {
      try {
        await _repo.updateCustomer(customer);
        return true;
      } catch (error) {
        lastError = error.toString();
        if (notify) {
          notifyListeners();
        }
        return false;
      }
    }

    final index = customers.indexWhere((item) => item.id == customer.id);
    if (index == -1) {
      return false;
    }
    customers[index] = customer;
    if (notify) {
      notifyListeners();
    }
    return true;
  }

  String? _validateMobileForUpdate(Customer customer) {
    final normalized = normalizeMobile(customer.mobile);
    final clash = customers
        .where((item) =>
            item.id != customer.id && normalizeMobile(item.mobile) == normalized)
        .firstOrNull;
    if (clash != null) {
      return 'Another party already uses this mobile number: ${clash.name}';
    }
    return null;
  }

  Future<bool> deleteCustomer(String id, {bool notify = true}) async {
    final hasVehicles = vehicles.any((vehicle) => vehicle.customerId == id);
    if (hasVehicles) {
      lastError =
          'Remove or reassign this party\'s vehicles before deleting them.';
      if (notify) {
        notifyListeners();
      }
      return false;
    }

    if (_repo != null) {
      try {
        await _repo.deleteCustomer(id);
        return true;
      } catch (error) {
        lastError = error.toString();
        if (notify) {
          notifyListeners();
        }
        return false;
      }
    }

    final index = customers.indexWhere((item) => item.id == id);
    if (index == -1) {
      return false;
    }
    customers.removeAt(index);
    if (notify) {
      notifyListeners();
    }
    return true;
  }

  Customer? customerByMobile(String mobile) {
    final normalized = normalizeMobile(mobile);
    if (normalized.isEmpty) {
      return null;
    }
    return customers
        .where((customer) => normalizeMobile(customer.mobile) == normalized)
        .firstOrNull;
  }

  Customer _addCustomerMemory({
    required String name,
    required String mobile,
    required String address,
  }) {
    final customer = Customer(
      id: 'C${_customerCounter++}',
      name: name,
      mobile: mobile,
      address: address,
    );
    customers.insert(0, customer);
    notifyListeners();
    return customer;
  }

  Future<Vehicle?> addVehicle({
    required String customerId,
    required String regNumber,
    required String brand,
    required String model,
    required int year,
    required int lastKm,
    bool notify = true,
  }) async {
    if (_repo == null) {
      return _addVehicleMemory(
        customerId: customerId,
        regNumber: regNumber,
        brand: brand,
        model: model,
        year: year,
        lastKm: lastKm,
        notify: notify,
      );
    }
    try {
      return await _repo.addVehicle(
        customerId: customerId,
        regNumber: regNumber,
        brand: brand,
        model: model,
        year: year,
        lastKm: lastKm,
      );
    } catch (error) {
      lastError = error.toString();
      if (notify) {
        notifyListeners();
      }
      return null;
    }
  }

  Vehicle _addVehicleMemory({
    required String customerId,
    required String regNumber,
    required String brand,
    required String model,
    required int year,
    required int lastKm,
    bool notify = true,
  }) {
    final vehicle = Vehicle(
      id: 'V${_vehicleCounter++}',
      customerId: customerId,
      regNumber: regNumber.toUpperCase(),
      regNumberNormalized: normalizeRegNumber(regNumber),
      brand: brand,
      model: model,
      year: year,
      lastKmReading: lastKm,
    );
    vehicles.insert(0, vehicle);
    if (notify) {
      notifyListeners();
    }
    return vehicle;
  }

  Future<bool> updateVehicle(Vehicle vehicle, {bool notify = true}) async {
    if (_repo != null) {
      try {
        await _repo.updateVehicle(vehicle);
        return true;
      } catch (error) {
        lastError = error.toString();
        if (notify) {
          notifyListeners();
        }
        return false;
      }
    }

    final index = vehicles.indexWhere((item) => item.id == vehicle.id);
    if (index == -1) {
      return false;
    }
    vehicles[index] = vehicle;
    if (notify) {
      notifyListeners();
    }
    return true;
  }

  Future<bool> deleteVehicle(String id, {bool notify = true}) async {
    if (_repo != null) {
      try {
        await _repo.deleteVehicle(id);
        return true;
      } catch (error) {
        lastError = error.toString();
        if (notify) {
          notifyListeners();
        }
        return false;
      }
    }

    final index = vehicles.indexWhere((item) => item.id == id);
    if (index == -1) {
      return false;
    }
    vehicles.removeAt(index);
    if (notify) {
      notifyListeners();
    }
    return true;
  }

  Future<StockItem?> addStockItem({
    required String name,
    required String sku,
    required double price,
    required int currentStock,
    required int minStockAlert,
    bool notify = true,
  }) async {
    if (_repo == null) {
      return _addStockItemMemory(
        name: name,
        sku: sku,
        price: price,
        currentStock: currentStock,
        minStockAlert: minStockAlert,
        notify: notify,
      );
    }
    try {
      return await _repo.addStockItem(
        name: name,
        sku: sku,
        price: price,
        currentStock: currentStock,
        minStockAlert: minStockAlert,
      );
    } catch (error) {
      lastError = error.toString();
      if (notify) {
        notifyListeners();
      }
      return null;
    }
  }

  StockItem _addStockItemMemory({
    required String name,
    required String sku,
    required double price,
    required int currentStock,
    required int minStockAlert,
    bool notify = true,
  }) {
    final item = StockItem(
      id: 'S${_stockCounter++}',
      name: name,
      sku: sku,
      sellingPrice: price,
      currentStock: currentStock,
      minStockAlert: minStockAlert,
    );
    stockItems.insert(0, item);
    if (notify) {
      notifyListeners();
    }
    return item;
  }

  Future<bool> updateStockItem(StockItem item, {bool notify = true}) async {
    if (_repo != null) {
      try {
        await _repo.updateStockItem(item);
        return true;
      } catch (error) {
        lastError = error.toString();
        if (notify) {
          notifyListeners();
        }
        return false;
      }
    }

    final index = stockItems.indexWhere((stock) => stock.id == item.id);
    if (index == -1) {
      return false;
    }
    stockItems[index] = item;
    if (notify) {
      notifyListeners();
    }
    return true;
  }

  Future<bool> deleteStockItem(String id, {bool notify = true}) async {
    if (_repo != null) {
      try {
        await _repo.deleteStockItem(id);
        return true;
      } catch (error) {
        lastError = error.toString();
        if (notify) {
          notifyListeners();
        }
        return false;
      }
    }

    final index = stockItems.indexWhere((stock) => stock.id == id);
    if (index == -1) {
      return false;
    }
    stockItems.removeAt(index);
    if (notify) {
      notifyListeners();
    }
    return true;
  }

  Future<LabourItem?> addLabourItem({
    required String name,
    required double defaultRate,
    bool notify = true,
  }) async {
    final repo = _repo;
    if (repo != null) {
      try {
        return await repo.addLabourItem(name: name, defaultRate: defaultRate);
      } catch (error) {
        lastError = error.toString();
        if (notify) {
          notifyListeners();
        }
        return null;
      }
    }
    return _addLabourItemMemory(
      name: name,
      defaultRate: defaultRate,
      notify: notify,
    );
  }

  LabourItem _addLabourItemMemory({
    required String name,
    required double defaultRate,
    bool notify = true,
  }) {
    final item = LabourItem(
      id: 'L${_labourCounter++}',
      name: name,
      defaultRate: defaultRate,
    );
    labourItems.insert(0, item);
    if (notify) {
      notifyListeners();
    }
    return item;
  }

  Future<bool> updateLabourItem(LabourItem item, {bool notify = true}) async {
    if (_repo != null) {
      try {
        await _repo.updateLabourItem(item);
        return true;
      } catch (error) {
        lastError = error.toString();
        if (notify) {
          notifyListeners();
        }
        return false;
      }
    }

    final index = labourItems.indexWhere((labour) => labour.id == item.id);
    if (index == -1) {
      return false;
    }
    labourItems[index] = item;
    if (notify) {
      notifyListeners();
    }
    return true;
  }

  Future<bool> deleteLabourItem(String id, {bool notify = true}) async {
    if (_repo != null) {
      try {
        await _repo.deleteLabourItem(id);
        return true;
      } catch (error) {
        lastError = error.toString();
        if (notify) {
          notifyListeners();
        }
        return false;
      }
    }

    final index = labourItems.indexWhere((labour) => labour.id == id);
    if (index == -1) {
      return false;
    }
    labourItems.removeAt(index);
    if (notify) {
      notifyListeners();
    }
    return true;
  }

  Future<JobCard?> addJobCard({
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
    bool notify = true,
  }) async {
    if (_repo == null) {
      return _addJobCardMemory(
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
        notify: notify,
      );
    }
    try {
      return await _repo.addJobCard(
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
      );
    } catch (error) {
      lastError = error.toString();
      if (notify) {
        notifyListeners();
      }
      return null;
    }
  }

  JobCard _addJobCardMemory({
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
    bool notify = true,
  }) {
    final card = JobCard(
      id: 'J${settings.nextJobCardNumber}',
      jobCardNumber: settings.nextJobCardNumber,
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
    settings = settings.copyWith(nextJobCardNumber: settings.nextJobCardNumber + 1);
    jobCards.insert(0, card);
    if (notify) {
      notifyListeners();
    }
    return card;
  }

  Future<void> updateJobCardStatus(
    String id,
    JobStatus status, {
    bool notify = true,
  }) async {
    if (_repo != null) {
      try {
        await _repo.updateJobCardStatus(id, status);
      } catch (error) {
        lastError = error.toString();
        if (notify) {
          notifyListeners();
        }
      }
      return;
    }

    final index = jobCards.indexWhere((jobCard) => jobCard.id == id);
    if (index == -1) {
      return;
    }
    jobCards[index] = jobCards[index].copyWith(status: status);
    if (notify) {
      notifyListeners();
    }
  }

  Future<bool> updateJobCard(JobCard jobCard, {bool notify = true}) async {
    if (_repo != null) {
      try {
        await _repo.updateJobCard(jobCard);
        return true;
      } catch (error) {
        lastError = error.toString();
        if (notify) {
          notifyListeners();
        }
        return false;
      }
    }

    final index = jobCards.indexWhere((item) => item.id == jobCard.id);
    if (index == -1) {
      return false;
    }
    jobCards[index] = jobCard;
    if (notify) {
      notifyListeners();
    }
    return true;
  }

  /// Returns null when stock is OK, otherwise a short reason.
  String? validatePartsStock(List<PartLineDraft> partsItems) {
    if (partsItems.isEmpty) {
      return null;
    }
    final totals = <String, int>{};
    for (final line in partsItems) {
      totals[line.stockItemId] = (totals[line.stockItemId] ?? 0) + line.qty;
    }
    for (final entry in totals.entries) {
      final item =
          stockItems.where((stock) => stock.id == entry.key).firstOrNull;
      if (item == null) {
        return 'Part not found in stock list';
      }
      if (item.currentStock < entry.value) {
        return '${item.name}: need ${entry.value}, only ${item.currentStock} in stock';
      }
    }
    return null;
  }

  /// Returns null on success, or an error message.
  Future<String?> convertJobCardToInvoice({
    required String jobCardId,
    required List<InvoiceLineDraft> labourItems,
    required List<PartLineDraft> partsItems,
    required PaymentStatus paymentStatus,
    required double amountPaid,
  }) async {
    final stockError = validatePartsStock(partsItems);
    if (stockError != null) {
      lastError = stockError;
      return stockError;
    }

    if (_repo != null) {
      final error = await _repo.convertJobCardToInvoice(
        jobCardId: jobCardId,
        labourItems: labourItems,
        partsItems: partsItems,
        paymentStatus: paymentStatus,
        amountPaid: amountPaid,
        stockItems: stockItems,
      );
      if (error != null) {
        lastError = error;
      }
      return error;
    }

    final ok = _convertJobCardToInvoiceMemory(
      jobCardId: jobCardId,
      labourItems: labourItems,
      partsItems: partsItems,
      paymentStatus: paymentStatus,
      amountPaid: amountPaid,
    );
    if (!ok) {
      lastError = 'Could not create invoice';
      return lastError;
    }
    return null;
  }

  bool _convertJobCardToInvoiceMemory({
    required String jobCardId,
    required List<InvoiceLineDraft> labourItems,
    required List<PartLineDraft> partsItems,
    required PaymentStatus paymentStatus,
    required double amountPaid,
  }) {
    final jobCardIndex = jobCards.indexWhere((jobCard) => jobCard.id == jobCardId);
    if (jobCardIndex == -1) {
      return false;
    }
    for (final line in partsItems) {
      final stockIndex = stockItems.indexWhere((item) => item.id == line.stockItemId);
      if (stockIndex == -1) {
        return false;
      }
      final item = stockItems[stockIndex];
      stockItems[stockIndex] = item.copyWith(currentStock: item.currentStock - line.qty);
      stockTransactions.insert(
        0,
        StockTransaction(
          id: 'ST${stockTransactions.length + 1}',
          stockItemId: line.stockItemId,
          type: StockTransactionType.out,
          qty: line.qty,
          referenceType: 'invoice',
          referenceId: 'I${settings.nextInvoiceNumber}',
          createdAt: DateTime.now(),
        ),
      );
    }
    final jobCard = jobCards[jobCardIndex];
    final labourTotal = labourItems.fold<double>(0, (sum, item) => sum + item.amount);
    final partRecords = _partRecordsFromDrafts(partsItems);
    final partsTotal = partRecords.fold<double>(0, (sum, item) => sum + item.amount);
    invoices.insert(
      0,
      Invoice(
        id: 'I${settings.nextInvoiceNumber}',
        invoiceNumber: settings.nextInvoiceNumber,
        jobCardId: jobCard.id,
        customerId: jobCard.customerId,
        vehicleId: jobCard.vehicleId,
        vehicleNumber: vehicleNumber(jobCard.vehicleId),
        kmReading: jobCard.kmReading,
        labourItems: labourItems,
        partsItems: partRecords,
        labourTotal: labourTotal,
        partsTotal: partsTotal,
        amountPaid: amountPaid,
        paymentStatus: paymentStatus,
        remarks: jobCard.remarks,
        createdAt: DateTime.now(),
      ),
    );
    settings = settings.copyWith(nextInvoiceNumber: settings.nextInvoiceNumber + 1);
    jobCards[jobCardIndex] = jobCard.copyWith(status: JobStatus.delivered);
    notifyListeners();
    return true;
  }

  List<InvoicePartLine> _partRecordsFromDrafts(List<PartLineDraft> partsItems) {
    return partsItems.map((line) {
      final stock = stockItems.where((item) => item.id == line.stockItemId).firstOrNull;
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
        unitPrice: line.unitPriceOverride ?? stock.sellingPrice,
      );
    }).toList();
  }

  Future<bool> createEstimate({
    String? jobCardId,
    String? customerId,
    String? vehicleId,
    int? kmReading,
    required List<InvoiceLineDraft> labourItems,
    required List<PartLineDraft> partsItems,
    String remarks = '',
    bool notify = true,
  }) async {
    if (_repo != null) {
      try {
        return await _repo.createEstimate(
          jobCardId: jobCardId,
          customerId: customerId,
          vehicleId: vehicleId,
          kmReading: kmReading,
          labourItems: labourItems,
          partsItems: partsItems,
          remarks: remarks,
          stockItems: stockItems,
          vehicleNumberFor: vehicleNumber,
        );
      } catch (error) {
        lastError = error.toString();
        if (notify) {
          notifyListeners();
        }
        return false;
      }
    }
    return _createEstimateMemory(
      jobCardId: jobCardId,
      customerId: customerId,
      vehicleId: vehicleId,
      kmReading: kmReading,
      labourItems: labourItems,
      partsItems: partsItems,
      remarks: remarks,
      notify: notify,
    );
  }

  bool _createEstimateMemory({
    String? jobCardId,
    String? customerId,
    String? vehicleId,
    int? kmReading,
    required List<InvoiceLineDraft> labourItems,
    required List<PartLineDraft> partsItems,
    String remarks = '',
    bool notify = true,
  }) {
    if (labourItems.isEmpty && partsItems.isEmpty) {
      return false;
    }

    String resolvedCustomerId;
    String resolvedVehicleId;
    int resolvedKm;
    String? linkedJobCardId;

    if (jobCardId != null) {
      final jobCard = jobCards.where((item) => item.id == jobCardId).firstOrNull;
      if (jobCard == null) {
        return false;
      }
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

    final partRecords = _partRecordsFromDrafts(partsItems);
    final labourTotal = labourItems.fold<double>(0, (sum, item) => sum + item.amount);
    final partsTotal = partRecords.fold<double>(0, (sum, item) => sum + item.amount);

    estimates.insert(
      0,
      Estimate(
        id: 'E${settings.nextEstimateNumber}',
        estimateNumber: settings.nextEstimateNumber,
        jobCardId: linkedJobCardId,
        customerId: resolvedCustomerId,
        vehicleId: resolvedVehicleId,
        vehicleNumber: vehicleNumber(resolvedVehicleId),
        kmReading: resolvedKm,
        labourItems: List.of(labourItems),
        partsItems: partRecords,
        labourTotal: labourTotal,
        partsTotal: partsTotal,
        remarks: remarks,
        status: EstimateStatus.sent,
        createdAt: DateTime.now(),
      ),
    );
    settings = settings.copyWith(nextEstimateNumber: settings.nextEstimateNumber + 1);
    if (notify) {
      notifyListeners();
    }
    return true;
  }

  Future<bool> updateEstimate({
    required String id,
    required List<InvoiceLineDraft> labourLines,
    required List<PartLineDraft> partsItems,
    String remarks = '',
    bool notify = true,
  }) async {
    if (labourLines.isEmpty && partsItems.isEmpty) {
      return false;
    }

    if (_repo != null) {
      try {
        return await _repo.updateEstimate(
          id: id,
          labourItems: labourLines,
          partsItems: partsItems,
          remarks: remarks,
          stockItems: stockItems,
        );
      } catch (error) {
        lastError = error.toString();
        if (notify) {
          notifyListeners();
        }
        return false;
      }
    }

    final index = estimates.indexWhere((estimate) => estimate.id == id);
    if (index == -1) {
      return false;
    }
    final existing = estimates[index];
    if (existing.status == EstimateStatus.converted) {
      return false;
    }

    final partRecords = _partRecordsFromDrafts(partsItems);
    final labourTotal =
        labourLines.fold<double>(0, (sum, item) => sum + item.amount);
    final partsTotal =
        partRecords.fold<double>(0, (sum, item) => sum + item.amount);

    estimates[index] = existing.copyWith(
      labourItems: List.of(labourLines),
      partsItems: partRecords,
      labourTotal: labourTotal,
      partsTotal: partsTotal,
      remarks: remarks,
    );
    if (notify) {
      notifyListeners();
    }
    return true;
  }

  Future<void> reopenEstimate(String id, {bool notify = true}) async {
    if (_repo != null) {
      try {
        await _repo.reopenEstimate(id);
      } catch (error) {
        lastError = error.toString();
        if (notify) {
          notifyListeners();
        }
      }
      return;
    }

    final index = estimates.indexWhere((estimate) => estimate.id == id);
    if (index == -1) {
      return;
    }
    estimates[index] = estimates[index].copyWith(status: EstimateStatus.approved);
    if (notify) {
      notifyListeners();
    }
  }

  Future<void> updateEstimateStatus(
    String id,
    EstimateStatus status, {
    bool notify = true,
  }) async {
    if (status == EstimateStatus.converted) {
      return;
    }

    if (_repo != null) {
      try {
        await _repo.updateEstimateStatus(id, status);
      } catch (error) {
        lastError = error.toString();
        if (notify) {
          notifyListeners();
        }
      }
      return;
    }

    final index = estimates.indexWhere((estimate) => estimate.id == id);
    if (index == -1 || estimates[index].status == EstimateStatus.converted) {
      return;
    }
    estimates[index] = estimates[index].copyWith(status: status);
    if (notify) {
      notifyListeners();
    }
  }

  Future<String?> updateInvoicePayment({
    required String invoiceId,
    required double amountPaid,
    PaymentStatus? paymentStatus,
  }) async {
    final index = invoices.indexWhere((invoice) => invoice.id == invoiceId);
    if (index == -1) {
      lastError = 'Invoice not found';
      return lastError;
    }

    final invoice = invoices[index];
    final clampedPaid = amountPaid.clamp(0, invoice.grandTotal).toDouble();
    final resolvedStatus =
        paymentStatus ?? paymentStatusForAmount(clampedPaid, invoice.grandTotal);

    if (_repo != null) {
      final error = await _repo.updateInvoicePayment(
        invoiceId: invoiceId,
        amountPaid: clampedPaid,
        paymentStatus: resolvedStatus,
      );
      if (error != null) {
        lastError = error;
      }
      return error;
    }

    invoices[index] = invoice.copyWith(
      amountPaid: clampedPaid,
      paymentStatus: resolvedStatus,
    );
    notifyListeners();
    return null;
  }

  List<PaymentRecord> paymentsForInvoice(String invoiceId) {
    return payments
        .where((payment) => payment.invoiceId == invoiceId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<PaymentRecord> advancesForCustomer(String customerId) {
    return payments
        .where((payment) => payment.customerId == customerId && payment.isAdvance)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  double customerAdvanceBalance(String customerId) {
    return advancesForCustomer(customerId)
        .fold<double>(0, (sum, payment) => sum + payment.amount);
  }

  double _invoicePaidFromRecords(String invoiceId) {
    return paymentsForInvoice(invoiceId)
        .fold<double>(0, (sum, payment) => sum + payment.amount);
  }

  void _syncInvoicePaymentMemory(String invoiceId) {
    final index = invoices.indexWhere((invoice) => invoice.id == invoiceId);
    if (index == -1) {
      return;
    }
    final invoice = invoices[index];
    final totalPaid = _invoicePaidFromRecords(invoiceId);
    final clampedPaid = totalPaid.clamp(0, invoice.grandTotal).toDouble();
    invoices[index] = invoice.copyWith(
      amountPaid: clampedPaid,
      paymentStatus: paymentStatusForAmount(clampedPaid, invoice.grandTotal),
    );
  }

  Future<String?> recordPaymentReceipt({
    required String customerId,
    String? invoiceId,
    required double amount,
    String note = '',
  }) async {
    if (amount <= 0) {
      lastError = 'Enter a valid amount';
      return lastError;
    }

    if (_repo != null) {
      final error = await _repo.addPaymentReceipt(
        customerId: customerId,
        invoiceId: invoiceId,
        amount: amount,
        note: note,
      );
      if (error != null) {
        lastError = error;
      }
      return error;
    }

    payments.insert(
      0,
      PaymentRecord(
        id: 'P${_paymentCounter++}',
        customerId: customerId,
        invoiceId: invoiceId,
        amount: amount,
        note: note,
        createdAt: DateTime.now(),
      ),
    );
    if (invoiceId != null) {
      _syncInvoicePaymentMemory(invoiceId);
    }
    notifyListeners();
    return null;
  }

  Future<String?> addExpense({
    required String description,
    required double amount,
  }) async {
    if (description.trim().isEmpty) {
      lastError = 'Enter a description';
      return lastError;
    }
    if (amount <= 0) {
      lastError = 'Enter a valid amount';
      return lastError;
    }

    if (_repo != null) {
      final error = await _repo.addExpense(
        description: description.trim(),
        amount: amount,
      );
      if (error != null) {
        lastError = error;
      }
      return error;
    }

    expenses.insert(
      0,
      Expense(
        id: 'EX${_expenseCounter++}',
        description: description.trim(),
        amount: amount,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
    return null;
  }

  Future<String?> applyAdvanceToInvoice({
    required String paymentId,
    required String invoiceId,
  }) async {
    if (_repo != null) {
      final error = await _repo.applyAdvanceToInvoice(
        paymentId: paymentId,
        invoiceId: invoiceId,
      );
      if (error != null) {
        lastError = error;
      }
      return error;
    }

    final paymentIndex = payments.indexWhere((payment) => payment.id == paymentId);
    if (paymentIndex == -1) {
      lastError = 'Advance payment not found';
      return lastError;
    }
    final payment = payments[paymentIndex];
    if (!payment.isAdvance) {
      lastError = 'Payment is already linked to a bill';
      return lastError;
    }

    final invoiceIndex = invoices.indexWhere((invoice) => invoice.id == invoiceId);
    if (invoiceIndex == -1) {
      lastError = 'Invoice not found';
      return lastError;
    }
    final invoice = invoices[invoiceIndex];
    if (invoice.customerId != payment.customerId) {
      lastError = 'Advance belongs to a different customer';
      return lastError;
    }
    if (invoice.balanceAmount <= 0) {
      lastError = 'Invoice is already fully paid';
      return lastError;
    }

    payments[paymentIndex] = payment.copyWith(invoiceId: invoiceId);
    _syncInvoicePaymentMemory(invoiceId);
    notifyListeners();
    return null;
  }

  String? _applyInvoicePartStockChangeMemory({
    required List<InvoicePartLine> oldParts,
    required List<PartLineDraft> newPartDrafts,
    required String invoiceId,
  }) {
    final oldTotals = <String, int>{};
    for (final part in oldParts) {
      oldTotals[part.stockItemId] =
          (oldTotals[part.stockItemId] ?? 0) + part.qty;
    }
    final newTotals = <String, int>{};
    for (final draft in newPartDrafts) {
      newTotals[draft.stockItemId] =
          (newTotals[draft.stockItemId] ?? 0) + draft.qty;
    }

    final stockIds = {...oldTotals.keys, ...newTotals.keys};
    for (final stockId in stockIds) {
      final oldQty = oldTotals[stockId] ?? 0;
      final newQty = newTotals[stockId] ?? 0;
      final netChange = newQty - oldQty;
      if (netChange == 0) {
        continue;
      }

      final stockIndex = stockItems.indexWhere((item) => item.id == stockId);
      if (stockIndex == -1) {
        if (netChange > 0) {
          return 'Stock item not found';
        }
        continue;
      }

      final item = stockItems[stockIndex];
      if (netChange > 0) {
        if (item.currentStock < netChange) {
          return 'Insufficient stock for ${item.name}';
        }
        stockItems[stockIndex] =
            item.copyWith(currentStock: item.currentStock - netChange);
        stockTransactions.insert(
          0,
          StockTransaction(
            id: 'ST${stockTransactions.length + 1}',
            stockItemId: stockId,
            type: StockTransactionType.out,
            qty: netChange,
            referenceType: 'invoice_edit',
            referenceId: invoiceId,
            createdAt: DateTime.now(),
          ),
        );
      } else {
        final returnQty = -netChange;
        stockItems[stockIndex] =
            item.copyWith(currentStock: item.currentStock + returnQty);
        stockTransactions.insert(
          0,
          StockTransaction(
            id: 'ST${stockTransactions.length + 1}',
            stockItemId: stockId,
            type: StockTransactionType.inType,
            qty: returnQty,
            referenceType: 'invoice_edit',
            referenceId: invoiceId,
            createdAt: DateTime.now(),
          ),
        );
      }
    }
    return null;
  }

  Future<bool> updateInvoice({
    required String invoiceId,
    required List<InvoiceLineDraft> labourLines,
    required List<PartLineDraft> partsItems,
    String remarks = '',
    bool notify = true,
  }) async {
    if (labourLines.isEmpty && partsItems.isEmpty) {
      lastError = 'Add at least one labour item or part';
      return false;
    }

    if (_repo != null) {
      final error = await _repo.updateInvoice(
        invoiceId: invoiceId,
        labourItems: labourLines,
        partsItems: partsItems,
        remarks: remarks,
        stockItems: stockItems,
      );
      if (error != null) {
        lastError = error;
        if (notify) {
          notifyListeners();
        }
        return false;
      }
      return true;
    }

    final index = invoices.indexWhere((invoice) => invoice.id == invoiceId);
    if (index == -1) {
      lastError = 'Invoice not found';
      return false;
    }

    final existing = invoices[index];
    final stockError = _applyInvoicePartStockChangeMemory(
      oldParts: existing.partsItems,
      newPartDrafts: partsItems,
      invoiceId: existing.id,
    );
    if (stockError != null) {
      lastError = stockError;
      return false;
    }

    final partRecords = _partRecordsFromDrafts(partsItems);
    final labourTotal =
        labourLines.fold<double>(0, (sum, item) => sum + item.amount);
    final partsTotal =
        partRecords.fold<double>(0, (sum, item) => sum + item.amount);
    final grandTotal = labourTotal + partsTotal;
    final clampedPaid = existing.amountPaid.clamp(0, grandTotal).toDouble();
    final resolvedStatus =
        paymentStatusForAmount(clampedPaid, grandTotal);

    invoices[index] = existing.copyWith(
      labourItems: List.of(labourLines),
      partsItems: partRecords,
      labourTotal: labourTotal,
      partsTotal: partsTotal,
      amountPaid: clampedPaid,
      paymentStatus: resolvedStatus,
      remarks: remarks,
    );
    if (notify) {
      notifyListeners();
    }
    return true;
  }

  Future<String?> convertEstimateToInvoice(String estimateId) async {
    final estimate =
        estimates.where((item) => item.id == estimateId).firstOrNull;
    if (estimate == null) {
      lastError = 'Estimate not found';
      return lastError;
    }
    if (estimate.status == EstimateStatus.converted) {
      lastError = 'Estimate already converted';
      return lastError;
    }

    final partDrafts = estimate.partsItems
        .map(
          (line) => PartLineDraft(
            stockItemId: line.stockItemId,
            qty: line.qty,
          ),
        )
        .toList();
    final stockError = validatePartsStock(partDrafts);
    if (stockError != null) {
      lastError = stockError;
      return stockError;
    }

    if (_repo != null) {
      final error = await _repo.convertEstimateToInvoice(estimateId);
      if (error != null) {
        lastError = error;
      }
      return error;
    }

    final ok = _convertEstimateToInvoiceMemory(estimateId);
    if (!ok) {
      lastError = 'Could not create invoice';
      return lastError;
    }
    return null;
  }

  bool _convertEstimateToInvoiceMemory(String estimateId) {
    final estimateIndex = estimates.indexWhere((estimate) => estimate.id == estimateId);
    if (estimateIndex == -1) {
      return false;
    }
    final estimate = estimates[estimateIndex];
    if (estimate.status == EstimateStatus.converted) {
      return false;
    }

    final partDrafts = estimate.partsItems
        .map((line) => PartLineDraft(stockItemId: line.stockItemId, qty: line.qty))
        .toList();

    for (final line in partDrafts) {
      final item = stockItems.where((stock) => stock.id == line.stockItemId).firstOrNull;
      if (item == null || item.currentStock < line.qty) {
        return false;
      }
    }

    for (final line in partDrafts) {
      final stockIndex = stockItems.indexWhere((item) => item.id == line.stockItemId);
      if (stockIndex == -1) {
        return false;
      }
      final item = stockItems[stockIndex];
      stockItems[stockIndex] = item.copyWith(currentStock: item.currentStock - line.qty);
      stockTransactions.insert(
        0,
        StockTransaction(
          id: 'ST${stockTransactions.length + 1}',
          stockItemId: line.stockItemId,
          type: StockTransactionType.out,
          qty: line.qty,
          referenceType: 'invoice',
          referenceId: 'I${settings.nextInvoiceNumber}',
          createdAt: DateTime.now(),
        ),
      );
    }

    invoices.insert(
      0,
      Invoice(
        id: 'I${settings.nextInvoiceNumber}',
        invoiceNumber: settings.nextInvoiceNumber,
        jobCardId: estimate.jobCardId,
        customerId: estimate.customerId,
        vehicleId: estimate.vehicleId,
        vehicleNumber: estimate.vehicleNumber,
        kmReading: estimate.kmReading,
        labourItems: estimate.labourItems,
        partsItems: estimate.partsItems,
        labourTotal: estimate.labourTotal,
        partsTotal: estimate.partsTotal,
        amountPaid: 0,
        paymentStatus: PaymentStatus.unpaid,
        remarks: estimate.remarks,
        createdAt: DateTime.now(),
      ),
    );
    settings = settings.copyWith(nextInvoiceNumber: settings.nextInvoiceNumber + 1);
    estimates[estimateIndex] = estimate.copyWith(status: EstimateStatus.converted);

    if (estimate.jobCardId != null) {
      updateJobCardStatus(estimate.jobCardId!, JobStatus.delivered, notify: false);
    }

    notifyListeners();
    return true;
  }

  Future<void> updateSettings({
    required String businessName,
    required String tagline,
    required String address,
    required String phone,
    required String invoicePrefix,
    required int nextInvoiceNumber,
    required int nextJobCardNumber,
    required int nextEstimateNumber,
  }) async {
    final updated = settings.copyWith(
      businessName: businessName,
      tagline: tagline,
      address: address,
      phone: phone,
      invoicePrefix: invoicePrefix,
      nextInvoiceNumber: nextInvoiceNumber,
      nextJobCardNumber: nextJobCardNumber,
      nextEstimateNumber: nextEstimateNumber,
    );

    if (_repo != null) {
      try {
        await _repo.updateSettings(updated);
      } catch (error) {
        lastError = error.toString();
        notifyListeners();
      }
      return;
    }

    settings = updated;
    notifyListeners();
  }

  Vehicle? findVehicleByRegNumber(String query) {
    final normalized = normalizeRegNumber(query.trim());
    if (normalized.isEmpty) {
      return null;
    }
    final exact = vehicles
        .where((vehicle) => vehicle.regNumberNormalized == normalized)
        .firstOrNull;
    if (exact != null) {
      return exact;
    }
    return vehicles
        .where((vehicle) => vehicle.regNumberNormalized.contains(normalized))
        .firstOrNull;
  }

  List<Vehicle> searchVehicles(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return vehicles;
    }
    final normalized = normalizeRegNumber(trimmed);
    final lower = trimmed.toLowerCase();
    return vehicles.where((vehicle) {
      final customer =
          customers.where((item) => item.id == vehicle.customerId).firstOrNull;
      if (customer == null) {
        return false;
      }
      return vehicle.regNumberNormalized.contains(normalized) ||
          customer.mobile.contains(trimmed) ||
          customer.name.toLowerCase().contains(lower);
    }).toList();
  }

  List<Customer> searchCustomers(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return customers;
    }
    final lower = trimmed.toLowerCase();
    return customers.where((customer) {
      return customer.name.toLowerCase().contains(lower) ||
          customer.mobile.contains(trimmed) ||
          customer.address.toLowerCase().contains(lower);
    }).toList();
  }

  List<Invoice> invoicesByVehicle(String vehicleId) {
    return invoices
        .where((invoice) => invoice.vehicleId == vehicleId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<Estimate> estimatesByVehicle(String vehicleId) {
    return estimates
        .where((estimate) => estimate.vehicleId == vehicleId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  int get openEstimates => estimates
      .where(
        (estimate) =>
            estimate.status != EstimateStatus.converted &&
            estimate.status != EstimateStatus.rejected,
      )
      .length;

  Estimate? estimateForJobCard(String jobCardId) {
    return estimates
        .where(
          (estimate) =>
              estimate.jobCardId == jobCardId &&
              estimate.status != EstimateStatus.converted &&
              estimate.status != EstimateStatus.rejected,
        )
        .firstOrNull;
  }

  String customerName(String id) {
    return customers.where((item) => item.id == id).firstOrNull?.name ??
        'Unknown customer';
  }

  String customerMobile(String id) {
    return customers.where((item) => item.id == id).firstOrNull?.mobile ??
        '';
  }

  String vehicleNumber(String id) {
    return vehicles.where((item) => item.id == id).firstOrNull?.regNumber ??
        'Unknown vehicle';
  }

  String stockItemName(String id) {
    return stockItems.where((item) => item.id == id).firstOrNull?.name ??
        'Unknown item';
  }

  int get todayJobCards =>
      jobCards.where((item) => sameDay(item.createdAt, DateTime.now())).length;

  int get activeJobCards =>
      jobCards.where((item) => item.status != JobStatus.delivered).length;

  List<StockItem> get lowStockItems =>
      stockItems.where((item) => item.currentStock <= item.minStockAlert).toList();
}
