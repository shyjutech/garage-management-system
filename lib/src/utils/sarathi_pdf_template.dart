import 'package:garage_management_system/src/models/garage_models.dart';
import 'package:garage_management_system/src/store/garage_store.dart';
import 'package:garage_management_system/src/utils/garage_utils.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// SARATHI AUTOMOBILES printed bill layout (physical invoice template).
class SarathiPdf {
  SarathiPdf._();

  static const PdfColor blue = PdfColor.fromInt(0xFF1976D2);

  static pw.TextStyle get whiteBold => pw.TextStyle(
        color: PdfColors.white,
        fontWeight: pw.FontWeight.bold,
        fontSize: 9,
      );

  static pw.TextStyle get labelBold => pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 8,
      );

  static const pw.TextStyle value = pw.TextStyle(fontSize: 8);

  static String amount(double value) => value.toStringAsFixed(2);

  static pw.Widget header({
    required GarageSettings settings,
    required DateTime date,
    String? docLabel,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              settings.businessName.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 26,
                fontWeight: pw.FontWeight.bold,
                color: blue,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              settings.tagline.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(settings.phone, style: value),
            pw.Text(
              settings.address.toUpperCase(),
              style: value,
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            if (docLabel != null && docLabel.isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text(
                  docLabel.toUpperCase(),
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: blue,
                    fontSize: 10,
                  ),
                ),
              ),
            pw.Text(
              DateFormat('dd-MM-yyyy').format(date),
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _infoField(String label, String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 52,
            child: pw.Text('${label.toUpperCase()}:', style: labelBold),
          ),
          pw.Expanded(child: pw.Text(text, style: value)),
        ],
      ),
    );
  }

  static pw.Widget infoGrid({
    required Customer customer,
    required Vehicle vehicle,
    required int kmReading,
    String gstin = '-',
    String? fuelLevel,
    String? mechanic,
    String? estimatedDelivery,
  }) {
    return pw.Column(
      children: [
        pw.Container(
          width: double.infinity,
          color: blue,
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: pw.Row(
            children: [
              pw.Expanded(child: pw.Text('CUSTOMER INFO', style: whiteBold)),
              pw.Expanded(child: pw.Text('VEHICLE INFO', style: whiteBold)),
            ],
          ),
        ),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _infoField('NAME', customer.name),
                    _infoField('ADDRESS', customer.address),
                    _infoField('GSTIN', gstin),
                    _infoField(
                      'PHONE',
                      customer.mobile.isEmpty ? '-' : customer.mobile,
                    ),
                  ],
                ),
              ),
            ),
            pw.Container(width: 1, color: blue),
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _infoField('MAKE', vehicle.brand),
                    _infoField('MODEL #', vehicle.model),
                    _infoField('YEAR', vehicle.year == 0 ? '-' : '${vehicle.year}'),
                    _infoField('REG NO', vehicle.regNumber),
                    _infoField('MILEAGE', kmReading == 0 ? '-' : '$kmReading'),
                    if (fuelLevel != null && fuelLevel.isNotEmpty)
                      _infoField('FUEL', fuelLevel),
                    if (mechanic != null && mechanic.isNotEmpty)
                      _infoField('MECHANIC', mechanic),
                    if (estimatedDelivery != null && estimatedDelivery.isNotEmpty)
                      _infoField('EST. DELIVERY', estimatedDelivery),
                  ],
                ),
              ),
            ),
          ],
        ),
        pw.Container(height: 1, color: blue),
      ],
    );
  }

  static pw.Widget sectionBar(
    String left, {
    String? right,
    List<String>? columns,
  }) {
    if (columns != null && columns.isNotEmpty) {
      return pw.Container(
        width: double.infinity,
        color: blue,
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: pw.Row(
          children: [
            for (var i = 0; i < columns.length; i++)
              pw.Expanded(
                flex: switch (i) {
                  0 => 2,
                  1 => 4,
                  _ => 2,
                },
                child: pw.Text(
                  columns[i].toUpperCase(),
                  style: whiteBold,
                  textAlign: i >= 2 ? pw.TextAlign.right : pw.TextAlign.left,
                ),
              ),
          ],
        ),
      );
    }

    return pw.Container(
      width: double.infinity,
      color: blue,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(left.toUpperCase(), style: whiteBold),
          if (right != null) pw.Text(right.toUpperCase(), style: whiteBold),
        ],
      ),
    );
  }

  static pw.Widget labourSection({
    required List<InvoiceLineDraft> items,
    required double subtotal,
    String title = 'JOB PERFORMED',
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        sectionBar(title, right: 'AMOUNT'),
        ...items.map(
          (line) => pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Text(line.description.toUpperCase(), style: value),
                ),
                pw.Text(amount(line.amount), style: value),
              ],
            ),
          ),
        ),
        if (items.isEmpty)
          pw.SizedBox(height: 28),
        pw.Container(height: 1, color: blue),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(8, 4, 8, 0),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text('SUB TOTAL', style: labelBold),
              pw.SizedBox(width: 12),
              pw.Text(amount(subtotal), style: labelBold),
            ],
          ),
        ),
      ],
    );
  }

  static String _partNumber(GarageStore store, String stockItemId) {
    if (stockItemId.isEmpty) {
      return '-';
    }
    final item = store.stockItems
        .where((stock) => stock.id == stockItemId)
        .firstOrNull;
    final sku = item?.sku ?? '';
    return sku.isEmpty ? '-' : sku;
  }

  static pw.Widget partsSection({
    required List<InvoicePartLine> items,
    required double subtotal,
    required GarageStore store,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        sectionBar(
          'PARTS',
          columns: const ['PART #', 'PART NAME', 'QTY', 'UNIT PRICE', 'AMOUNT'],
        ),
        ...items.map(
          (line) => pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    _partNumber(store, line.stockItemId),
                    style: value,
                  ),
                ),
                pw.Expanded(
                  flex: 4,
                  child: pw.Text(line.name.toUpperCase(), style: value),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    '${line.qty}',
                    style: value,
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    amount(line.unitPrice),
                    style: value,
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    amount(line.amount),
                    style: value,
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (items.isEmpty)
          pw.SizedBox(height: 28),
        pw.Container(height: 1, color: blue),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(8, 4, 8, 0),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text('SUB TOTAL', style: labelBold),
              pw.SizedBox(width: 12),
              pw.Text(amount(subtotal), style: labelBold),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget textSection(String title, String body) {
    if (body.trim().isEmpty) {
      return pw.SizedBox();
    }
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          sectionBar(title),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(body, style: value),
          ),
          pw.Container(height: 1, color: blue),
        ],
      ),
    );
  }

  static pw.Widget footer({
    required String remarks,
    required double labourTotal,
    required double partsTotal,
    required double grandTotal,
    bool showTotals = true,
    String totalLabel = 'TOTAL',
    String? footerNote,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('REMARKS', style: labelBold),
              pw.SizedBox(height: 4),
              pw.Container(
                width: double.infinity,
                constraints: const pw.BoxConstraints(minHeight: 36),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.black, width: 0.5),
                  ),
                ),
                child: pw.Text(remarks, style: value),
              ),
              if (footerNote != null && footerNote.isNotEmpty) ...[
                pw.SizedBox(height: 6),
                pw.Text(
                  footerNote,
                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                ),
              ],
            ],
          ),
        ),
        pw.SizedBox(width: 16),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            if (showTotals) ...[
              pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text('TOTAL LABOUR:', style: labelBold),
                  pw.SizedBox(width: 8),
                  pw.Text(amount(labourTotal), style: value),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text('TOTAL PARTS:', style: labelBold),
                  pw.SizedBox(width: 8),
                  pw.Text(amount(partsTotal), style: value),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Container(width: 160, height: 2, color: PdfColors.black),
              pw.SizedBox(height: 4),
              pw.Text(
                '$totalLabel: ${amount(grandTotal)}',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 11,
                  color: blue,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  static pw.Page page({
    required PdfPageFormat format,
    required List<pw.Widget> children,
  }) {
    return pw.Page(
      pageFormat: format,
      margin: const pw.EdgeInsets.all(16),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: children,
        );
      },
    );
  }
}