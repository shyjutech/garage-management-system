import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:garage_management_system/src/models/garage_models.dart';
import 'package:garage_management_system/src/store/garage_store.dart';
import 'package:garage_management_system/src/theme/app_theme.dart';
import 'package:garage_management_system/src/widgets/ui_components.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

class _PartyVehicleRow {
  const _PartyVehicleRow({
    required this.customer,
    this.vehicle,
  });

  final Customer customer;
  final Vehicle? vehicle;
}

List<_PartyVehicleRow> _buildRows(GarageStore store) {
  final customers = List<Customer>.from(store.customers)
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  final rows = <_PartyVehicleRow>[];
  for (final customer in customers) {
    final vehicles = store.vehicles
        .where((vehicle) => vehicle.customerId == customer.id)
        .toList()
      ..sort((a, b) => a.regNumber.compareTo(b.regNumber));

    if (vehicles.isEmpty) {
      rows.add(_PartyVehicleRow(customer: customer));
    } else {
      for (final vehicle in vehicles) {
        rows.add(_PartyVehicleRow(customer: customer, vehicle: vehicle));
      }
    }
  }
  return rows;
}

Future<Uint8List> buildPartiesListPdf({
  required GarageStore store,
  required PdfPageFormat format,
}) async {
  final pdf = pw.Document();
  final settings = store.settings;
  final rows = _buildRows(store);
  final tableData = rows.map((row) {
    final vehicle = row.vehicle;
    return [
      row.customer.name,
      row.customer.mobile,
      row.customer.address,
      vehicle?.regNumber ?? '—',
      vehicle?.brand ?? '—',
      vehicle?.model ?? '—',
      vehicle == null ? '—' : vehicle.year.toString(),
    ];
  }).toList();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: format,
      margin: const pw.EdgeInsets.all(24),
      build: (context) => [
        pw.Text(
          settings.businessName,
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        if (settings.tagline.isNotEmpty) pw.Text(settings.tagline),
        if (settings.phone.isNotEmpty) pw.Text(settings.phone),
        if (settings.address.isNotEmpty) pw.Text(settings.address),
        pw.SizedBox(height: 8),
        pw.Text(
          'Parties & Vehicles Register',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          'Printed: ${DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now())} · '
          '${store.customers.length} parties · ${store.vehicles.length} vehicles',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 12),
        if (tableData.isEmpty)
          pw.Text('No parties registered yet.')
        else
          pw.TableHelper.fromTextArray(
            headers: const [
              'Name',
              'Mobile',
              'Address',
              'Vehicle No.',
              'Brand',
              'Model',
              'Year',
            ],
            data: tableData,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
            ),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerLeft,
              4: pw.Alignment.centerLeft,
              5: pw.Alignment.centerLeft,
              6: pw.Alignment.center,
            },
            columnWidths: {
              0: const pw.FlexColumnWidth(1.8),
              1: const pw.FlexColumnWidth(1.1),
              2: const pw.FlexColumnWidth(2.2),
              3: const pw.FlexColumnWidth(1.2),
              4: const pw.FlexColumnWidth(1),
              5: const pw.FlexColumnWidth(1),
              6: const pw.FlexColumnWidth(0.6),
            },
          ),
      ],
    ),
  );

  return pdf.save();
}

class PartiesListPage extends StatefulWidget {
  const PartiesListPage({super.key});

  @override
  State<PartiesListPage> createState() => _PartiesListPageState();
}

class _PartiesListPageState extends State<PartiesListPage> {
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  List<_PartyVehicleRow> _filteredRows(GarageStore store) {
    final query = search.text.trim().toLowerCase();
    final rows = _buildRows(store);
    if (query.isEmpty) {
      return rows;
    }
    return rows.where((row) {
      final customer = row.customer;
      final vehicle = row.vehicle;
      return customer.name.toLowerCase().contains(query) ||
          customer.mobile.contains(query) ||
          customer.address.toLowerCase().contains(query) ||
          (vehicle?.regNumber.toLowerCase().contains(query) ?? false) ||
          (vehicle?.brand.toLowerCase().contains(query) ?? false) ||
          (vehicle?.model.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  Future<void> _print(GarageStore store) async {
    await Printing.layoutPdf(
      onLayout: (format) => buildPartiesListPdf(store: store, format: format),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GarageStore>();
    final rows = _filteredRows(store);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('All Parties & Vehicles'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Print',
            onPressed: store.customers.isEmpty ? null : () => _print(store),
            icon: const Icon(Icons.print_rounded),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${store.customers.length} parties · ${store.vehicles.length} vehicles',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: store.customers.isEmpty ? null : () => _print(store),
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                  label: const Text('Print'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppSearchField(
              controller: search,
              hint: 'Search name, mobile, vehicle…',
              expand: true,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: rows.isEmpty
                  ? const Center(
                      child: Text(
                        'No parties found.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  : Card(
                      clipBehavior: Clip.antiAlias,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              AppColors.primary.withValues(alpha: 0.08),
                            ),
                            columns: const [
                              DataColumn(label: Text('Name')),
                              DataColumn(label: Text('Mobile')),
                              DataColumn(label: Text('Address')),
                              DataColumn(label: Text('Vehicle No.')),
                              DataColumn(label: Text('Brand')),
                              DataColumn(label: Text('Model')),
                              DataColumn(label: Text('Year')),
                            ],
                            rows: rows.map((row) {
                              final vehicle = row.vehicle;
                              return DataRow(
                                cells: [
                                  DataCell(Text(row.customer.name)),
                                  DataCell(Text(row.customer.mobile)),
                                  DataCell(
                                    SizedBox(
                                      width: 200,
                                      child: Text(
                                        row.customer.address,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(vehicle?.regNumber ?? '—')),
                                  DataCell(Text(vehicle?.brand ?? '—')),
                                  DataCell(Text(vehicle?.model ?? '—')),
                                  DataCell(
                                    Text(
                                      vehicle == null ? '—' : '${vehicle.year}',
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
