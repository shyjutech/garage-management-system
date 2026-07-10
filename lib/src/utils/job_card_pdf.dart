import 'dart:typed_data';

import 'package:garage_management_system/src/models/garage_models.dart';
import 'package:garage_management_system/src/store/garage_store.dart';
import 'package:garage_management_system/src/utils/garage_utils.dart';
import 'package:garage_management_system/src/utils/pdf_theme.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Plain black & white workshop job card — distinct from bill/estimate PDFs.
class JobCardPdf {
  JobCardPdf._();

  static pw.TextStyle get label => pw.TextStyle(
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.black,
      );

  static pw.TextStyle get value => const pw.TextStyle(
        fontSize: 8,
      );

  static pw.TextStyle get title => pw.TextStyle(
        fontSize: 14,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.black,
      );

  static pw.Widget header({
    required GarageSettings settings,
    required int jobCardNumber,
    required DateTime date,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('JOB CARD', style: title),
                pw.SizedBox(height: 4),
                pw.Text(settings.businessName.toUpperCase(), style: label),
                pw.Text(settings.tagline.toUpperCase(), style: value),
                pw.Text(settings.phone, style: value),
                pw.Text(settings.address.toUpperCase(), style: value),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('NO. $jobCardNumber', style: title),
                pw.SizedBox(height: 4),
                pw.Text(
                  DateFormat('dd-MM-yyyy, hh:mm a').format(date),
                  style: value,
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Container(height: 2, color: PdfColors.black),
      ],
    );
  }

  static pw.Widget _field(String labelText, String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 68,
            child: pw.Text('$labelText:', style: label),
          ),
          pw.Expanded(child: pw.Text(text, style: value)),
        ],
      ),
    );
  }

  static pw.Widget _sectionHeading(String text) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(text.toUpperCase(), style: label),
        pw.SizedBox(height: 3),
        pw.Container(height: 1, color: PdfColors.black),
        pw.SizedBox(height: 4),
      ],
    );
  }

  static pw.Widget infoGrid({
    required Customer customer,
    required Vehicle vehicle,
    required int kmReading,
    String? fuelLevel,
    String? mechanic,
    String? estimatedDelivery,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
          children: [
            pw.Expanded(child: pw.Text('CUSTOMER', style: label)),
            pw.Expanded(child: pw.Text('VEHICLE', style: label)),
          ],
        ),
        pw.SizedBox(height: 3),
        pw.Container(height: 1, color: PdfColors.black),
        pw.SizedBox(height: 6),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _field('Name', customer.name),
                  _field('Address', customer.address),
                  _field('Phone', customer.mobile.isEmpty ? '-' : customer.mobile),
                ],
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _field('Make', vehicle.brand),
                  _field('Model', vehicle.model),
                  _field('Reg No', vehicle.regNumber),
                  _field('KM', kmReading == 0 ? '-' : '$kmReading'),
                  if (fuelLevel != null && fuelLevel.isNotEmpty)
                    _field('Fuel', fuelLevel),
                  if (mechanic != null && mechanic.isNotEmpty)
                    _field('Mechanic', mechanic),
                  if (estimatedDelivery != null && estimatedDelivery.isNotEmpty)
                    _field('Est. delivery', estimatedDelivery),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget textBlock(String heading, String body) {
    if (body.trim().isEmpty) {
      return pw.SizedBox();
    }
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _sectionHeading(heading),
          pw.Text(body, style: value),
        ],
      ),
    );
  }

  static pw.Widget remarksBlock(String remarks) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _sectionHeading('Remarks'),
          pw.Container(
            constraints: const pw.BoxConstraints(minHeight: 28),
            child: pw.Text(remarks, style: value),
          ),
        ],
      ),
    );
  }

  static pw.Widget preliminaryEstimate({
    required double labourEstimated,
    required double partsEstimated,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _sectionHeading('Preliminary Estimate'),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Labour estimated', style: value),
              pw.Text(formatAmount(labourEstimated), style: value),
            ],
          ),
          pw.SizedBox(height: 2),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Parts estimated', style: value),
              pw.Text(formatAmount(partsEstimated), style: value),
            ],
          ),
          pw.SizedBox(height: 3),
          pw.Container(height: 0.5, color: PdfColors.black),
          pw.SizedBox(height: 3),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total estimate', style: label),
              pw.Text(
                formatAmount(labourEstimated + partsEstimated),
                style: label,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget estimateSummary({
    required Estimate estimate,
    required GarageStore store,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _sectionHeading('Estimated Work (reference only)'),
          if (estimate.labourItems.isNotEmpty) ...[
            pw.Text('Labour', style: label),
            ...estimate.labourItems.map(
              (line) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Row(
                  children: [
                    pw.Expanded(child: pw.Text(line.description, style: value)),
                    pw.Text(formatAmount(line.amount), style: value),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 6),
          ],
          if (estimate.partsItems.isNotEmpty) ...[
            pw.Text('Parts', style: label),
            ...estimate.partsItems.map(
              (line) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Text(
                  '${line.name} × ${formatQty(line.qty)} @ ${formatAmount(line.unitPrice)}',
                  style: value,
                ),
              ),
            ),
          ],
          pw.SizedBox(height: 3),
          pw.Container(height: 0.5, color: PdfColors.black),
          pw.SizedBox(height: 3),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Est. total: ${formatAmount(estimate.grandTotal)}',
              style: label,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget signatures() {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 16),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _signatureLine('Customer signature'),
          _signatureLine('Service advisor'),
        ],
      ),
    );
  }

  static pw.Widget _signatureLine(String caption) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(caption, style: value),
        pw.SizedBox(height: 22),
        pw.Container(width: 150, height: 1, color: PdfColors.black),
      ],
    );
  }
}

Future<Uint8List> buildJobCardPdf({
  required JobCard jobCard,
  required GarageStore store,
  required PdfPageFormat format,
  Estimate? estimate,
}) async {
  final customer = store.customers
          .where((item) => item.id == jobCard.customerId)
          .firstOrNull ??
      const Customer(id: 'NA', name: 'Unknown', mobile: '-', address: '-');
  final vehicle = store.vehicles
          .where((item) => item.id == jobCard.vehicleId)
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
  final pdf = pw.Document(
    theme: await buildPdfTheme(),
    title: '${vehicle.regNumber}_JC${jobCard.jobCardNumber}',
  );
  final s = store.settings;
  final deliveryText = jobCard.estimatedDelivery == null
      ? ''
      : DateFormat('dd-MM-yyyy').format(jobCard.estimatedDelivery!);
  final complaintChecklist = jobCard.complaintItems.isEmpty
      ? ''
      : jobCard.complaintItems.map((item) => '• $item').join('\n');

  pdf.addPage(
    pw.Page(
      pageFormat: format,
      margin: const pw.EdgeInsets.all(16),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            JobCardPdf.header(
              settings: s,
              jobCardNumber: jobCard.jobCardNumber,
              date: jobCard.createdAt,
            ),
            pw.SizedBox(height: 10),
            JobCardPdf.infoGrid(
              customer: customer,
              vehicle: vehicle,
              kmReading: jobCard.kmReading,
              fuelLevel: jobCard.fuelLevel,
              mechanic: jobCard.mechanicName,
              estimatedDelivery: deliveryText,
            ),
            JobCardPdf.textBlock('Customer complaints', jobCard.customerComplaints),
            if (complaintChecklist.isNotEmpty)
              JobCardPdf.textBlock('Complaint checklist', complaintChecklist),
            JobCardPdf.textBlock('Observations', jobCard.observations),
            JobCardPdf.textBlock('Requested works', jobCard.requestedWorks),
            JobCardPdf.textBlock('Other notes', jobCard.otherNotes),
            JobCardPdf.textBlock('Internal notes', jobCard.internalNotes),
            if (jobCard.remarks.isNotEmpty)
              JobCardPdf.remarksBlock(jobCard.remarks),
            if (jobCard.labourEstimated > 0 || jobCard.partsEstimated > 0)
              JobCardPdf.preliminaryEstimate(
                labourEstimated: jobCard.labourEstimated,
                partsEstimated: jobCard.partsEstimated,
              ),
            if (estimate != null)
              JobCardPdf.estimateSummary(estimate: estimate, store: store),
            pw.Spacer(),
            pw.Text(
              'Status: ${jobCard.status.label}',
              style: JobCardPdf.label,
            ),
            JobCardPdf.signatures(),
            pw.SizedBox(height: 8),
            pw.Text(
              'WORKSHOP COPY — NOT A BILL',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 7,
                color: PdfColors.grey700,
              ),
            ),
          ],
        );
      },
    ),
  );
  return pdf.save();
}
