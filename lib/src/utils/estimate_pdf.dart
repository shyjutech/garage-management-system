import 'dart:typed_data';

import 'package:garage_management_system/src/models/garage_models.dart';
import 'package:garage_management_system/src/store/garage_store.dart';
import 'package:garage_management_system/src/utils/sarathi_pdf_template.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<Uint8List> buildEstimatePdf({
  required Estimate estimate,
  required GarageStore store,
  required PdfPageFormat format,
}) async {
  final pdf = pw.Document();
  final customer = store.customers
          .where((item) => item.id == estimate.customerId)
          .firstOrNull ??
      const Customer(id: 'NA', name: 'Unknown', mobile: '-', address: '-');
  final vehicle = store.vehicles
          .where((item) => item.id == estimate.vehicleId)
          .firstOrNull ??
      const Vehicle(
        id: 'NA',
        customerId: 'NA',
        regNumber: '-',
        regNumberNormalized: '-',
        brand: '-',
        model: '-',
        year: 0,
        lastKmReading: 0,
      );
  final s = store.settings;

  pdf.addPage(
    SarathiPdf.page(
      format: format,
      children: [
        SarathiPdf.header(
          settings: s,
          date: estimate.createdAt,
          docLabel: 'ESTIMATE #${estimate.estimateNumber}',
        ),
        pw.SizedBox(height: 10),
        SarathiPdf.infoGrid(
          customer: customer,
          vehicle: vehicle,
          kmReading: estimate.kmReading,
        ),
        pw.SizedBox(height: 10),
        SarathiPdf.labourSection(
          items: estimate.labourItems,
          subtotal: estimate.labourTotal,
        ),
        pw.SizedBox(height: 10),
        SarathiPdf.partsSection(
          items: estimate.partsItems,
          subtotal: estimate.partsTotal,
          store: store,
        ),
        pw.Spacer(),
        SarathiPdf.footer(
          remarks: estimate.remarks,
          labourTotal: estimate.labourTotal,
          partsTotal: estimate.partsTotal,
          grandTotal: estimate.grandTotal,
          footerNote:
              'This is an estimate only. Final bill may vary after inspection.',
        ),
      ],
    ),
  );
  return pdf.save();
}
