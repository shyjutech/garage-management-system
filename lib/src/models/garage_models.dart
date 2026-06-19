import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:garage_management_system/src/utils/garage_utils.dart';

class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.mobile,
    required this.address,
  });

  final String id;
  final String name;
  final String mobile;
  final String address;

  factory Customer.fromMap(String id, Map<String, dynamic> data) {
    return Customer(
      id: id,
      name: data['name'] as String? ?? '',
      mobile: data['mobile'] as String? ?? '',
      address: data['address'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'mobile': mobile,
        'address': address,
      };
}

class Vehicle {
  const Vehicle({
    required this.id,
    required this.customerId,
    required this.regNumber,
    required this.regNumberNormalized,
    required this.brand,
    required this.model,
    required this.year,
    required this.lastKmReading,
  });

  final String id;
  final String customerId;
  final String regNumber;
  final String regNumberNormalized;
  final String brand;
  final String model;
  final int year;
  final int lastKmReading;

  factory Vehicle.fromMap(String id, Map<String, dynamic> data) {
    return Vehicle(
      id: id,
      customerId: data['customerId'] as String? ?? '',
      regNumber: data['regNumber'] as String? ?? '',
      regNumberNormalized: data['regNumberNormalized'] as String? ?? '',
      brand: data['brand'] as String? ?? '',
      model: data['model'] as String? ?? '',
      year: (data['year'] as num?)?.toInt() ?? 0,
      lastKmReading: (data['lastKmReading'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'customerId': customerId,
        'regNumber': regNumber,
        'regNumberNormalized': regNumberNormalized,
        'brand': brand,
        'model': model,
        'year': year,
        'lastKmReading': lastKmReading,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

class StockItem {
  const StockItem({
    required this.id,
    required this.name,
    required this.sku,
    required this.sellingPrice,
    required this.currentStock,
    required this.minStockAlert,
  });

  final String id;
  final String name;
  final String sku;
  final double sellingPrice;
  final int currentStock;
  final int minStockAlert;

  StockItem copyWith({
    String? id,
    String? name,
    String? sku,
    double? sellingPrice,
    int? currentStock,
    int? minStockAlert,
  }) {
    return StockItem(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      currentStock: currentStock ?? this.currentStock,
      minStockAlert: minStockAlert ?? this.minStockAlert,
    );
  }

  factory StockItem.fromMap(String id, Map<String, dynamic> data) {
    return StockItem(
      id: id,
      name: data['name'] as String? ?? '',
      sku: data['sku'] as String? ?? '',
      sellingPrice: (data['sellingPrice'] as num?)?.toDouble() ?? 0,
      currentStock: (data['currentStock'] as num?)?.toInt() ?? 0,
      minStockAlert: (data['minStockAlert'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'sku': sku,
        'sellingPrice': sellingPrice,
        'currentStock': currentStock,
        'minStockAlert': minStockAlert,
      };
}

class LabourItem {
  const LabourItem({
    required this.id,
    required this.name,
    required this.defaultRate,
  });

  final String id;
  final String name;
  final double defaultRate;

  LabourItem copyWith({
    String? id,
    String? name,
    double? defaultRate,
  }) {
    return LabourItem(
      id: id ?? this.id,
      name: name ?? this.name,
      defaultRate: defaultRate ?? this.defaultRate,
    );
  }

  factory LabourItem.fromMap(String id, Map<String, dynamic> data) {
    return LabourItem(
      id: id,
      name: data['name'] as String? ?? '',
      defaultRate: (data['defaultRate'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'defaultRate': defaultRate,
      };
}

enum JobStatus { pending, inProgress, completed, delivered }

extension JobStatusX on JobStatus {
  String get label => switch (this) {
        JobStatus.pending => 'Pending',
        JobStatus.inProgress => 'In Progress',
        JobStatus.completed => 'Completed',
        JobStatus.delivered => 'Delivered',
      };

  String get firestoreValue => switch (this) {
        JobStatus.pending => 'pending',
        JobStatus.inProgress => 'in_progress',
        JobStatus.completed => 'completed',
        JobStatus.delivered => 'delivered',
      };
}

JobStatus jobStatusFromFirestore(String? value) {
  return switch (value) {
    'in_progress' => JobStatus.inProgress,
    'completed' => JobStatus.completed,
    'delivered' => JobStatus.delivered,
    _ => JobStatus.pending,
  };
}

class JobCard {
  const JobCard({
    required this.id,
    required this.jobCardNumber,
    required this.customerId,
    required this.vehicleId,
    required this.kmReading,
    required this.fuelLevel,
    required this.customerComplaints,
    required this.complaintItems,
    required this.observations,
    required this.requestedWorks,
    required this.otherNotes,
    required this.internalNotes,
    required this.mechanicName,
    required this.estimatedDelivery,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final int jobCardNumber;
  final String customerId;
  final String vehicleId;
  final int kmReading;
  final String fuelLevel;
  final String customerComplaints;
  final List<String> complaintItems;
  final String observations;
  final String requestedWorks;
  final String otherNotes;
  final String internalNotes;
  final String mechanicName;
  final DateTime? estimatedDelivery;
  final JobStatus status;
  final DateTime createdAt;

  String get complaint => customerComplaints;

  JobCard copyWith({
    String? id,
    int? jobCardNumber,
    String? customerId,
    String? vehicleId,
    int? kmReading,
    String? fuelLevel,
    String? customerComplaints,
    List<String>? complaintItems,
    String? observations,
    String? requestedWorks,
    String? otherNotes,
    String? internalNotes,
    String? mechanicName,
    DateTime? estimatedDelivery,
    JobStatus? status,
    DateTime? createdAt,
  }) {
    return JobCard(
      id: id ?? this.id,
      jobCardNumber: jobCardNumber ?? this.jobCardNumber,
      customerId: customerId ?? this.customerId,
      vehicleId: vehicleId ?? this.vehicleId,
      kmReading: kmReading ?? this.kmReading,
      fuelLevel: fuelLevel ?? this.fuelLevel,
      customerComplaints: customerComplaints ?? this.customerComplaints,
      complaintItems: complaintItems ?? this.complaintItems,
      observations: observations ?? this.observations,
      requestedWorks: requestedWorks ?? this.requestedWorks,
      otherNotes: otherNotes ?? this.otherNotes,
      internalNotes: internalNotes ?? this.internalNotes,
      mechanicName: mechanicName ?? this.mechanicName,
      estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory JobCard.fromMap(String id, Map<String, dynamic> data) {
    final delivery = data['estimatedDelivery'];
    return JobCard(
      id: id,
      jobCardNumber: (data['jobCardNumber'] as num?)?.toInt() ?? 0,
      customerId: data['customerId'] as String? ?? '',
      vehicleId: data['vehicleId'] as String? ?? '',
      kmReading: (data['kmReading'] as num?)?.toInt() ?? 0,
      fuelLevel: data['fuelLevel'] as String? ?? '',
      customerComplaints: data['customerComplaints'] as String? ?? '',
      complaintItems: List<String>.from(data['complaintItems'] as List? ?? []),
      observations: data['observations'] as String? ?? '',
      requestedWorks: data['requestedWorks'] as String? ?? '',
      otherNotes: data['otherNotes'] as String? ?? '',
      internalNotes: data['internalNotes'] as String? ?? '',
      mechanicName: data['mechanicName'] as String? ?? '',
      estimatedDelivery: delivery is Timestamp
          ? delivery.toDate()
          : delivery is DateTime
              ? delivery
              : null,
      status: jobStatusFromFirestore(data['status'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap({required int jobCardNumber}) => {
        'jobCardNumber': jobCardNumber,
        'customerId': customerId,
        'vehicleId': vehicleId,
        'kmReading': kmReading,
        'fuelLevel': fuelLevel,
        'customerComplaints': customerComplaints,
        'complaintItems': complaintItems,
        'observations': observations,
        'requestedWorks': requestedWorks,
        'otherNotes': otherNotes,
        'internalNotes': internalNotes,
        'mechanicName': mechanicName,
        'estimatedDelivery': estimatedDelivery == null
            ? null
            : Timestamp.fromDate(estimatedDelivery!),
        'status': status.firestoreValue,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

enum PaymentStatus { paid, unpaid, partial }

extension PaymentStatusX on PaymentStatus {
  String get label => switch (this) {
        PaymentStatus.paid => 'Paid',
        PaymentStatus.unpaid => 'Unpaid',
        PaymentStatus.partial => 'Partial',
      };
}

PaymentStatus paymentStatusFromFirestore(String? value) {
  return PaymentStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => PaymentStatus.unpaid,
  );
}

enum EstimateStatus { draft, sent, approved, converted, rejected }

extension EstimateStatusX on EstimateStatus {
  String get label => switch (this) {
        EstimateStatus.draft => 'Draft',
        EstimateStatus.sent => 'Sent',
        EstimateStatus.approved => 'Approved',
        EstimateStatus.converted => 'Converted',
        EstimateStatus.rejected => 'Rejected',
      };
}

EstimateStatus estimateStatusFromFirestore(String? value) {
  return EstimateStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => EstimateStatus.sent,
  );
}

enum UserRole { admin, billing, mechanic, accountant }

extension UserRoleX on UserRole {
  String get label => switch (this) {
        UserRole.admin => 'Admin',
        UserRole.billing => 'Billing Staff',
        UserRole.mechanic => 'Mechanic',
        UserRole.accountant => 'Accountant',
      };
}

UserRole userRoleFromFirestore(String? value) {
  return UserRole.values.firstWhere(
    (role) => role.name == value,
    orElse: () => UserRole.admin,
  );
}

enum StockTransactionType { inType, out, adjust }

StockTransactionType stockTransactionTypeFromFirestore(String? value) {
  return switch (value) {
    'in' => StockTransactionType.inType,
    'adjust' => StockTransactionType.adjust,
    _ => StockTransactionType.out,
  };
}

String stockTransactionTypeToFirestore(StockTransactionType type) {
  return switch (type) {
    StockTransactionType.inType => 'in',
    StockTransactionType.out => 'out',
    StockTransactionType.adjust => 'adjust',
  };
}

class Invoice {
  const Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.jobCardId,
    required this.customerId,
    required this.vehicleId,
    required this.vehicleNumber,
    required this.kmReading,
    required this.labourItems,
    required this.partsItems,
    required this.labourTotal,
    required this.partsTotal,
    required this.amountPaid,
    required this.paymentStatus,
    required this.createdAt,
  });

  final String id;
  final int invoiceNumber;
  final String? jobCardId;
  final String customerId;
  final String vehicleId;
  final String vehicleNumber;
  final int kmReading;
  final List<InvoiceLineDraft> labourItems;
  final List<InvoicePartLine> partsItems;
  final double labourTotal;
  final double partsTotal;
  final double amountPaid;
  final PaymentStatus paymentStatus;
  final DateTime createdAt;

  double get grandTotal => labourTotal + partsTotal;
  double get balanceAmount =>
      (grandTotal - amountPaid).clamp(0, grandTotal).toDouble();

  Invoice copyWith({
    List<InvoiceLineDraft>? labourItems,
    List<InvoicePartLine>? partsItems,
    double? labourTotal,
    double? partsTotal,
    double? amountPaid,
    PaymentStatus? paymentStatus,
  }) {
    return Invoice(
      id: id,
      invoiceNumber: invoiceNumber,
      jobCardId: jobCardId,
      customerId: customerId,
      vehicleId: vehicleId,
      vehicleNumber: vehicleNumber,
      kmReading: kmReading,
      labourItems: labourItems ?? this.labourItems,
      partsItems: partsItems ?? this.partsItems,
      labourTotal: labourTotal ?? this.labourTotal,
      partsTotal: partsTotal ?? this.partsTotal,
      amountPaid: amountPaid ?? this.amountPaid,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt,
    );
  }

  factory Invoice.fromMap(String id, Map<String, dynamic> data) {
    return Invoice(
      id: id,
      invoiceNumber: (data['invoiceNumber'] as num?)?.toInt() ?? 0,
      jobCardId: data['jobCardId'] as String?,
      customerId: data['customerId'] as String? ?? '',
      vehicleId: data['vehicleId'] as String? ?? '',
      vehicleNumber: data['vehicleNumber'] as String? ?? '',
      kmReading: (data['kmReading'] as num?)?.toInt() ?? 0,
      labourItems: _parseLabourItems(data['labourItems']),
      partsItems: _parsePartLines(data['partsItems']),
      labourTotal: (data['labourTotal'] as num?)?.toDouble() ?? 0,
      partsTotal: (data['partsTotal'] as num?)?.toDouble() ?? 0,
      amountPaid: (data['amountPaid'] as num?)?.toDouble() ?? 0,
      paymentStatus: paymentStatusFromFirestore(data['paymentStatus'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class Estimate {
  const Estimate({
    required this.id,
    required this.estimateNumber,
    required this.jobCardId,
    required this.customerId,
    required this.vehicleId,
    required this.vehicleNumber,
    required this.kmReading,
    required this.labourItems,
    required this.partsItems,
    required this.labourTotal,
    required this.partsTotal,
    required this.notes,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final int estimateNumber;
  final String? jobCardId;
  final String customerId;
  final String vehicleId;
  final String vehicleNumber;
  final int kmReading;
  final List<InvoiceLineDraft> labourItems;
  final List<InvoicePartLine> partsItems;
  final double labourTotal;
  final double partsTotal;
  final String notes;
  final EstimateStatus status;
  final DateTime createdAt;

  double get grandTotal => labourTotal + partsTotal;

  Estimate copyWith({
    String? id,
    int? estimateNumber,
    String? jobCardId,
    String? customerId,
    String? vehicleId,
    String? vehicleNumber,
    int? kmReading,
    List<InvoiceLineDraft>? labourItems,
    List<InvoicePartLine>? partsItems,
    double? labourTotal,
    double? partsTotal,
    String? notes,
    EstimateStatus? status,
    DateTime? createdAt,
  }) {
    return Estimate(
      id: id ?? this.id,
      estimateNumber: estimateNumber ?? this.estimateNumber,
      jobCardId: jobCardId ?? this.jobCardId,
      customerId: customerId ?? this.customerId,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      kmReading: kmReading ?? this.kmReading,
      labourItems: labourItems ?? this.labourItems,
      partsItems: partsItems ?? this.partsItems,
      labourTotal: labourTotal ?? this.labourTotal,
      partsTotal: partsTotal ?? this.partsTotal,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Estimate.fromMap(String id, Map<String, dynamic> data) {
    return Estimate(
      id: id,
      estimateNumber: (data['estimateNumber'] as num?)?.toInt() ?? 0,
      jobCardId: data['jobCardId'] as String?,
      customerId: data['customerId'] as String? ?? '',
      vehicleId: data['vehicleId'] as String? ?? '',
      vehicleNumber: data['vehicleNumber'] as String? ?? '',
      kmReading: (data['kmReading'] as num?)?.toInt() ?? 0,
      labourItems: _parseLabourItems(data['labourItems']),
      partsItems: _parsePartLines(data['partsItems']),
      labourTotal: (data['labourTotal'] as num?)?.toDouble() ?? 0,
      partsTotal: (data['partsTotal'] as num?)?.toDouble() ?? 0,
      notes: data['notes'] as String? ?? '',
      status: estimateStatusFromFirestore(data['status'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap({required int estimateNumber}) => {
        'estimateNumber': estimateNumber,
        'jobCardId': jobCardId,
        'customerId': customerId,
        'vehicleId': vehicleId,
        'vehicleNumber': vehicleNumber,
        'kmReading': kmReading,
        'labourItems': labourItems.map((item) => item.toMap()).toList(),
        'partsItems': partsItems.map((item) => item.toMap()).toList(),
        'labourTotal': labourTotal,
        'partsTotal': partsTotal,
        'notes': notes,
        'status': status.name,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

class GarageSettings {
  const GarageSettings({
    required this.businessName,
    required this.tagline,
    required this.address,
    required this.phone,
    required this.invoicePrefix,
    required this.nextInvoiceNumber,
    required this.nextJobCardNumber,
    required this.nextEstimateNumber,
  });

  final String businessName;
  final String tagline;
  final String address;
  final String phone;
  final String invoicePrefix;
  final int nextInvoiceNumber;
  final int nextJobCardNumber;
  final int nextEstimateNumber;

  static GarageSettings defaults() => const GarageSettings(
        businessName: 'SARATHI AUTOMOBILES',
        tagline: 'THE MULTIBRAND CAR SERVICE',
        address: 'NEAR KATTUKULANGARA TEMPLE GATE MAVUNGAL',
        phone: '9746039993, 9778288101',
        invoicePrefix: 'INV',
        nextInvoiceNumber: 1,
        nextJobCardNumber: 900,
        nextEstimateNumber: 1,
      );

  GarageSettings copyWith({
    String? businessName,
    String? tagline,
    String? address,
    String? phone,
    String? invoicePrefix,
    int? nextInvoiceNumber,
    int? nextJobCardNumber,
    int? nextEstimateNumber,
  }) {
    return GarageSettings(
      businessName: businessName ?? this.businessName,
      tagline: tagline ?? this.tagline,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      nextInvoiceNumber: nextInvoiceNumber ?? this.nextInvoiceNumber,
      nextJobCardNumber: nextJobCardNumber ?? this.nextJobCardNumber,
      nextEstimateNumber: nextEstimateNumber ?? this.nextEstimateNumber,
    );
  }

  factory GarageSettings.fromMap(Map<String, dynamic> data) {
    return GarageSettings(
      businessName: data['businessName'] as String? ?? defaults().businessName,
      tagline: data['tagline'] as String? ?? defaults().tagline,
      address: data['address'] as String? ?? defaults().address,
      phone: data['phone'] as String? ?? defaults().phone,
      invoicePrefix: data['invoicePrefix'] as String? ?? defaults().invoicePrefix,
      nextInvoiceNumber: (data['nextInvoiceNumber'] as num?)?.toInt() ?? 1,
      nextJobCardNumber: (data['nextJobCardNumber'] as num?)?.toInt() ?? 900,
      nextEstimateNumber: (data['nextEstimateNumber'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toMap() => {
        'businessName': businessName,
        'tagline': tagline,
        'address': address,
        'phone': phone,
        'invoicePrefix': invoicePrefix,
        'nextInvoiceNumber': nextInvoiceNumber,
        'nextJobCardNumber': nextJobCardNumber,
        'nextEstimateNumber': nextEstimateNumber,
      };
}

class InvoiceLineDraft {
  const InvoiceLineDraft({required this.description, required this.amount});

  final String description;
  final double amount;

  factory InvoiceLineDraft.fromMap(Map<String, dynamic> data) {
    return InvoiceLineDraft(
      description: data['description'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'description': description,
        'amount': amount,
      };
}

class PartLineDraft {
  const PartLineDraft({required this.stockItemId, required this.qty});

  final String stockItemId;
  final int qty;

  double amountFor(Iterable<StockItem> stockItems) {
    final item =
        stockItems.where((stock) => stock.id == stockItemId).firstOrNull;
    if (item == null) {
      return 0;
    }
    return qty * item.sellingPrice;
  }
}

class InvoicePartLine {
  const InvoicePartLine({
    required this.stockItemId,
    required this.name,
    required this.qty,
    required this.unitPrice,
  });

  final String stockItemId;
  final String name;
  final int qty;
  final double unitPrice;

  double get amount => qty * unitPrice;

  factory InvoicePartLine.fromMap(Map<String, dynamic> data) {
    return InvoicePartLine(
      stockItemId: data['stockItemId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      qty: (data['qty'] as num?)?.toInt() ?? 0,
      unitPrice: (data['unitPrice'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'stockItemId': stockItemId,
        'name': name,
        'qty': qty,
        'unitPrice': unitPrice,
        'amount': amount,
      };
}

class StockTransaction {
  const StockTransaction({
    required this.id,
    required this.stockItemId,
    required this.type,
    required this.qty,
    required this.referenceType,
    required this.referenceId,
    required this.createdAt,
  });

  final String id;
  final String stockItemId;
  final StockTransactionType type;
  final int qty;
  final String referenceType;
  final String referenceId;
  final DateTime createdAt;

  factory StockTransaction.fromMap(String id, Map<String, dynamic> data) {
    return StockTransaction(
      id: id,
      stockItemId: data['stockItemId'] as String? ?? '',
      type: stockTransactionTypeFromFirestore(data['type'] as String?),
      qty: (data['qty'] as num?)?.toInt() ?? 0,
      referenceType: data['referenceType'] as String? ?? '',
      referenceId: data['referenceId'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Cash received from a customer — linked to an invoice or held as advance.
class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.customerId,
    this.invoiceId,
    required this.amount,
    required this.note,
    required this.createdAt,
  });

  final String id;
  final String customerId;
  final String? invoiceId;
  final double amount;
  final String note;
  final DateTime createdAt;

  bool get isAdvance => invoiceId == null || invoiceId!.isEmpty;

  factory PaymentRecord.fromMap(String id, Map<String, dynamic> data) {
    return PaymentRecord(
      id: id,
      customerId: data['customerId'] as String? ?? '',
      invoiceId: data['invoiceId'] as String?,
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      note: data['note'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'customerId': customerId,
        if (invoiceId != null) 'invoiceId': invoiceId,
        'amount': amount,
        'note': note,
        'createdAt': FieldValue.serverTimestamp(),
      };

  PaymentRecord copyWith({String? invoiceId}) {
    return PaymentRecord(
      id: id,
      customerId: customerId,
      invoiceId: invoiceId ?? this.invoiceId,
      amount: amount,
      note: note,
      createdAt: createdAt,
    );
  }
}

List<InvoiceLineDraft> _parseLabourItems(Object? raw) {
  if (raw is! List) {
    return const [];
  }
  return raw
      .whereType<Map>()
      .map((item) => InvoiceLineDraft.fromMap(Map<String, dynamic>.from(item)))
      .toList();
}

List<InvoicePartLine> _parsePartLines(Object? raw) {
  if (raw is! List) {
    return const [];
  }
  return raw
      .whereType<Map>()
      .map((item) => InvoicePartLine.fromMap(Map<String, dynamic>.from(item)))
      .toList();
}

Map<String, dynamic> labourItemsToFirestore(List<InvoiceLineDraft> items) {
  return {'labourItems': items.map((item) => item.toMap()).toList()};
}

List<Map<String, dynamic>> partsItemsToCallable(List<InvoicePartLine> items) {
  return items
      .map(
        (item) => {
          'stockItemId': item.stockItemId,
          'name': item.name,
          'qty': item.qty,
          'unitPrice': item.unitPrice,
          'amount': item.amount,
        },
      )
      .toList();
}

List<Map<String, dynamic>> partsDraftsToCallable(
  List<PartLineDraft> drafts,
  Iterable<StockItem> stockItems,
) {
  return drafts.map((draft) {
    final stock =
        stockItems.where((item) => item.id == draft.stockItemId).firstOrNull;
    final unitPrice = stock?.sellingPrice ?? 0;
    return {
      'stockItemId': draft.stockItemId,
      'name': stock?.name ?? 'Unknown item',
      'qty': draft.qty,
      'unitPrice': unitPrice,
      'amount': draft.qty * unitPrice,
    };
  }).toList();
}

List<Map<String, dynamic>> labourItemsToCallable(List<InvoiceLineDraft> items) {
  return items
      .map(
        (item) => {
          'description': item.description,
          'amount': item.amount,
        },
      )
      .toList();
}
