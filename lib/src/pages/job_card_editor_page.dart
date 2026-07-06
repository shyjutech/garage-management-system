import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:garage_management_system/src/models/garage_models.dart';
import 'package:garage_management_system/src/store/garage_store.dart';
import 'package:garage_management_system/src/theme/app_theme.dart';
import 'package:garage_management_system/src/utils/garage_utils.dart';
import 'package:garage_management_system/src/widgets/responsive.dart';
import 'package:garage_management_system/src/widgets/ui_components.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class JobCardEditorPage extends StatefulWidget {
  const JobCardEditorPage({super.key, required this.jobCard});

  final JobCard jobCard;

  static Future<bool?> show(
    BuildContext context, {
    required JobCard jobCard,
  }) {
    final store = context.read<GarageStore>();
    return Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (routeContext) => ChangeNotifierProvider<GarageStore>.value(
          value: store,
          child: JobCardEditorPage(jobCard: jobCard),
        ),
      ),
    );
  }

  @override
  State<JobCardEditorPage> createState() => _JobCardEditorPageState();
}

class _JobCardEditorPageState extends State<JobCardEditorPage> {
  late final TextEditingController km;
  late final TextEditingController mechanic;
  late final TextEditingController complaints;
  late final TextEditingController complaintChecklist;
  late final TextEditingController observations;
  late final TextEditingController requestedWorks;
  late final TextEditingController remarks;
  late final TextEditingController labourEstimated;
  late final TextEditingController partsEstimated;
  late String fuelLevel;
  DateTime? estimatedDelivery;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final jobCard = widget.jobCard;
    km = TextEditingController(text: '${jobCard.kmReading}');
    mechanic = TextEditingController(text: jobCard.mechanicName);
    complaints = TextEditingController(text: jobCard.customerComplaints);
    complaintChecklist =
        TextEditingController(text: jobCard.complaintItems.join('\n'));
    observations = TextEditingController(text: jobCard.observations);
    requestedWorks = TextEditingController(text: jobCard.requestedWorks);
    remarks = TextEditingController(text: jobCard.remarks);
    labourEstimated = TextEditingController(
      text: jobCard.labourEstimated == 0
          ? ''
          : jobCard.labourEstimated.toStringAsFixed(0),
    );
    partsEstimated = TextEditingController(
      text: jobCard.partsEstimated == 0
          ? ''
          : jobCard.partsEstimated.toStringAsFixed(0),
    );
    fuelLevel = jobCard.fuelLevel.isEmpty ? 'Half' : jobCard.fuelLevel;
    estimatedDelivery = jobCard.estimatedDelivery;
  }

  @override
  void dispose() {
    km.dispose();
    mechanic.dispose();
    complaints.dispose();
    complaintChecklist.dispose();
    observations.dispose();
    requestedWorks.dispose();
    remarks.dispose();
    labourEstimated.dispose();
    partsEstimated.dispose();
    super.dispose();
  }

  double get _labourEstimatedValue =>
      double.tryParse(labourEstimated.text.trim()) ?? 0;

  double get _partsEstimatedValue =>
      double.tryParse(partsEstimated.text.trim()) ?? 0;

  Future<void> _pickEstimatedDelivery() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: estimatedDelivery ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => estimatedDelivery = picked);
    }
  }

  Future<void> _save(GarageStore store) async {
    final kmError = FormValidators.positiveKm(km.text);
    if (kmError != null) {
      showAppSnackBar(context, kmError);
      return;
    }

    setState(() => saving = true);
    final updated = widget.jobCard.copyWith(
      kmReading: int.parse(km.text.trim()),
      fuelLevel: fuelLevel,
      mechanicName: mechanic.text.trim(),
      customerComplaints: complaints.text.trim(),
      complaintItems: complaintChecklist.text
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList(),
      observations: observations.text.trim(),
      requestedWorks: requestedWorks.text.trim(),
      remarks: remarks.text.trim(),
      estimatedDelivery: estimatedDelivery,
      labourEstimated: _labourEstimatedValue,
      partsEstimated: _partsEstimatedValue,
    );

    final saved = await store.updateJobCard(updated);
    if (!mounted) {
      return;
    }
    setState(() => saving = false);

    if (!saved) {
      showAppSnackBar(context, store.lastError ?? 'Could not save job card');
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GarageStore>();
    final jobCard = widget.jobCard;
    final vehicle = store.vehicles
        .where((item) => item.id == jobCard.vehicleId)
        .firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Edit Job Card',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Job Card #${jobCard.jobCardNumber} · '
                          '${store.vehicleNumber(jobCard.vehicleId)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${store.customerName(jobCard.customerId)} · '
                          '${store.customerMobile(jobCard.customerId)}',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                        if (vehicle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${vehicle.brand} ${vehicle.model}',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppFormRow(
                    children: [
                      AppTextField(
                        controller: km,
                        label: 'KM Reading *',
                        expand: true,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                      AppTextField(
                        controller: mechanic,
                        label: 'Mechanic',
                        expand: true,
                      ),
                      AppDropdownField<String>(
                        label: 'Fuel level',
                        value: fuelLevel,
                        items: const [
                          DropdownMenuItem(value: 'Empty', child: Text('Empty')),
                          DropdownMenuItem(value: 'Quarter', child: Text('1/4')),
                          DropdownMenuItem(value: 'Half', child: Text('1/2')),
                          DropdownMenuItem(
                            value: 'Three Quarter',
                            child: Text('3/4'),
                          ),
                          DropdownMenuItem(value: 'Full', child: Text('Full')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => fuelLevel = value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: _pickEstimatedDelivery,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Estimated delivery',
                        suffixIcon: Icon(Icons.calendar_month_rounded, size: 20),
                      ),
                      child: Text(
                        estimatedDelivery == null
                            ? 'Not set'
                            : DateFormat('dd MMM yyyy').format(estimatedDelivery!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppMultilineField(
                    controller: complaints,
                    label: 'Customer complaints',
                    hint: 'What the customer reported...',
                    minLines: 2,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  AppMultilineField(
                    controller: complaintChecklist,
                    label: 'Complaint checklist',
                    hint: 'One item per line, shown as a checklist on print...',
                    minLines: 2,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  AppMultilineField(
                    controller: observations,
                    label: 'Observations',
                    hint: 'What the mechanic found...',
                    minLines: 2,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  AppMultilineField(
                    controller: requestedWorks,
                    label: 'Requested works',
                    hint: 'Work to be carried out...',
                    minLines: 2,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  AppMultilineField(
                    controller: remarks,
                    label: 'Remarks',
                    hint: 'Shown on job card print...',
                    minLines: 2,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Preliminary Estimate',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  AppFormRow(
                    children: [
                      AppTextField(
                        controller: labourEstimated,
                        label: 'Labour estimated (₹)',
                        expand: true,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                      ),
                      AppTextField(
                        controller: partsEstimated,
                        label: 'Parts estimated (₹)',
                        expand: true,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ResponsiveTotalsBar(
                    items: [
                      ('Labour est.', formatAmount(_labourEstimatedValue)),
                      ('Parts est.', formatAmount(_partsEstimatedValue)),
                    ],
                    grandTotalLabel:
                        'Total estimate: ${formatAmount(_labourEstimatedValue + _partsEstimatedValue)}',
                  ),
                  const SizedBox(height: 88),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: saving ? null : () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: saving ? null : () => _save(store),
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded, size: 18),
                label: const Text('Save Job Card'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
