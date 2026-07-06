import 'dart:typed_data';

import 'package:garage_management_system/src/models/garage_models.dart';
import 'package:garage_management_system/src/store/garage_store.dart';
import 'package:garage_management_system/src/utils/sarathi_pdf_template.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<Uint8List> buildInvoicePdf({
  required Invoice invoice,
  required GarageStore store,
  required PdfPageFormat format,
}) async {
  final pdf = pw.Document();
  final customer = store.customers
          .where((item) => item.id == invoice.customerId)
          .firstOrNull ??
      const Customer(id: 'NA', name: 'Unknown', mobile: '-', address: '-');
  final vehicle = store.vehicles
          .where((item) => item.id == invoice.vehicleId)
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
          date: invoice.createdAt,
          docLabel: 'INB #${invoice.invoiceNumber}',
        ),
        pw.SizedBox(height: 10),
        SarathiPdf.infoGrid(
          customer: customer,
          vehicle: vehicle,
          kmReading: invoice.kmReading,
        ),
        pw.SizedBox(height: 10),
        SarathiPdf.labourSection(
          items: invoice.labourItems,
          subtotal: invoice.labourTotal,
        ),
        pw.SizedBox(height: 10),
        SarathiPdf.partsSection(
          items: invoice.partsItems,
          subtotal: invoice.partsTotal,
          store: store,
        ),
        pw.Spacer(),
        SarathiPdf.footer(
          remarks: invoice.remarks,
          labourTotal: invoice.labourTotal,
          partsTotal: invoice.partsTotal,
          grandTotal: invoice.grandTotal,
        ),
      ],
    ),
  );
  return pdf.save();
}
