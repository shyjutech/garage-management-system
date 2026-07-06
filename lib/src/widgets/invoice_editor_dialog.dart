import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:garage_management_system/src/models/garage_models.dart';
import 'package:garage_management_system/src/store/garage_store.dart';
import 'package:garage_management_system/src/theme/app_theme.dart';
import 'package:garage_management_system/src/utils/garage_utils.dart';
import 'package:garage_management_system/src/widgets/responsive.dart';
import 'package:garage_management_system/src/widgets/ui_components.dart';
import 'package:provider/provider.dart';

class InvoiceEditorDialog extends StatefulWidget {
  const InvoiceEditorDialog({super.key, required this.invoice});

  final Invoice invoice;

  static Future<bool?> show(BuildContext context, {required Invoice invoice}) {
    final store = context.read<GarageStore>();
    return showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) => ChangeNotifierProvider<GarageStore>.value(
        value: store,
        child: InvoiceEditorDialog(invoice: invoice),
      ),
    );
  }

  @override
  State<InvoiceEditorDialog> createState() => _InvoiceEditorDialogState();
}

class _InvoiceEditorDialogState extends State<InvoiceEditorDialog> {
  late final TextEditingController remarksController;
  late final TextEditingController labourDesc;
  late final TextEditingController labourAmount;
  late final TextEditingController partSearch;
  late final TextEditingController partQty;
  late final List<InvoiceLineDraft> labourLines;
  late final List<PartLineDraft> partLines;
  String? partStockItemId;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    remarksController = TextEditingController(text: widget.invoice.remarks);
    labourDesc = TextEditingController();
    labourAmount = TextEditingController();
    partSearch = TextEditingController();
    partQty = TextEditingController(text: '1');
    labourLines = List.of(widget.invoice.labourItems);
    partLines = widget.invoice.partsItems
        .map(
          (part) => PartLineDraft(
            stockItemId: part.stockItemId,
            qty: part.qty,
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    remarksController.dispose();
    labourDesc.dispose();
    labourAmount.dispose();
    partSearch.dispose();
    partQty.dispose();
    super.dispose();
  }

  double _draftLabourAmount() {
    final parsed = double.tryParse(labourAmount.text.trim()) ?? 0;
    if (labourDesc.text.trim().isEmpty || parsed <= 0) {
      return 0;
    }
    return parsed;
  }

  double _draftPartsAmount(GarageStore store) {
    if (partStockItemId == null) {
      return 0;
    }
    final qty = int.tryParse(partQty.text.trim()) ?? 0;
    if (qty <= 0) {
      return 0;
    }
    return PartLineDraft(
      stockItemId: partStockItemId!,
      qty: qty,
    ).amountFor(store.stockItems);
  }

  void _flushDraftLines(GarageStore store) {
    final labour = _draftLabourAmount();
    if (labour > 0) {
      labourLines.add(
        InvoiceLineDraft(
          description: labourDesc.text.trim(),
          amount: labour,
        ),
      );
      labourDesc.clear();
      labourAmount.clear();
    }

    if (partStockItemId != null) {
      final qty = int.tryParse(partQty.text.trim()) ?? 0;
      if (qty > 0) {
        final existingIndex =
            partLines.indexWhere((line) => line.stockItemId == partStockItemId);
        if (existingIndex >= 0) {
          final existing = partLines[existingIndex];
          partLines[existingIndex] = PartLineDraft(
            stockItemId: existing.stockItemId,
            qty: existing.qty + qty,
          );
        } else {
          partLines.add(
            PartLineDraft(stockItemId: partStockItemId!, qty: qty),
          );
        }
        partQty.text = '1';
        partSearch.clear();
        partStockItemId = null;
      }
    }
  }

  bool _canSave(GarageStore store) {
    final hasLines = labourLines.isNotEmpty || partLines.isNotEmpty;
    final hasDraft =
        _draftLabourAmount() > 0 || _draftPartsAmount(store) > 0;
    return hasLines || hasDraft;
  }

  Future<void> _save(GarageStore store) async {
    setState(() => _flushDraftLines(store));
    if (labourLines.isEmpty && partLines.isEmpty) {
      showAppSnackBar(context, 'Add at least one labour item or part');
      return;
    }

    setState(() => saving = true);
    final saved = await store.updateInvoice(
      invoiceId: widget.invoice.id,
      labourLines: labourLines,
      partsItems: partLines,
      remarks: remarksController.text.trim(),
    );
    if (!mounted) {
      return;
    }
    setState(() => saving = false);

    if (!saved) {
      showAppSnackBar(context, store.lastError ?? 'Could not update invoice');
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GarageStore>();
    final invoice = widget.invoice;
    final labourTotal =
        labourLines.fold<double>(0, (sum, item) => sum + item.amount);
    final partsTotal =
        partLines.fold<double>(0, (sum, line) => sum + line.amountFor(store.stockItems));
    final displayLabourTotal = labourTotal + _draftLabourAmount();
    final displayPartsTotal = partsTotal + _draftPartsAmount(store);

    return AlertDialog(
      title: Text(
        'Edit Invoice #${invoice.invoiceNumber}',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
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
                      '${invoice.vehicleNumber} · ${store.customerName(invoice.customerId)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${store.customerMobile(invoice.customerId)} · '
                      'Paid ${formatAmount(invoice.amountPaid)}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Labour',
                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  LabourSearchField(
                    controller: labourDesc,
                    items: store.labourItems,
                    onSelected: (item) {
                      setState(() {
                        labourDesc.text = item.name;
                        labourAmount.text = item.defaultRate.toStringAsFixed(0);
                      });
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                  AppTextField(
                    controller: labourAmount,
                    label: 'Amount (₹)',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      final parsed =
                          double.tryParse(labourAmount.text.trim()) ?? 0;
                      if (labourDesc.text.trim().isEmpty || parsed <= 0) {
                        return;
                      }
                      setState(() {
                        labourLines.add(
                          InvoiceLineDraft(
                            description: labourDesc.text.trim(),
                            amount: parsed,
                          ),
                        );
                        labourDesc.clear();
                        labourAmount.clear();
                      });
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
              ...labourLines.asMap().entries.map(
                (entry) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(entry.value.description),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatAmount(entry.value.amount),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      IconButton(
                        tooltip: 'Remove',
                        onPressed: () =>
                            setState(() => labourLines.removeAt(entry.key)),
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Parts (optional)',
                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  PartSearchField(
                    controller: partSearch,
                    items: store.stockItems,
                    onSelected: (item) {
                      setState(() {
                        partStockItemId = item.id;
                        partSearch.text = item.name;
                      });
                    },
                    onChanged: (_) => setState(() => partStockItemId = null),
                  ),
                  AppTextField(
                    controller: partQty,
                    label: 'Qty',
                    width: 100,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() {}),
                  ),
                  OutlinedButton.icon(
                    onPressed: partStockItemId == null
                        ? null
                        : () => setState(() => _flushDraftLines(store)),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
              ...partLines.asMap().entries.map(
                (entry) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(store.stockItemName(entry.value.stockItemId)),
                  subtitle: Text('Qty ${entry.value.qty}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatAmount(entry.value.amountFor(store.stockItems)),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      IconButton(
                        tooltip: 'Remove',
                        onPressed: () =>
                            setState(() => partLines.removeAt(entry.key)),
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppMultilineField(
                controller: remarksController,
                label: 'Remarks',
                hint: 'Shown on invoice PDF...',
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              ResponsiveTotalsBar(
                items: [
                  ('Labour', formatAmount(displayLabourTotal)),
                  ('Parts', formatAmount(displayPartsTotal)),
                ],
                grandTotalLabel:
                    'Total: ${formatAmount(displayLabourTotal + displayPartsTotal)}',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: saving || !_canSave(store) ? null : () => _save(store),
          icon: saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.update_rounded, size: 18),
          label: const Text('Update Invoice'),
        ),
      ],
    );
  }
}
