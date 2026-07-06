import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:garage_management_system/src/models/garage_models.dart';
import 'package:garage_management_system/src/store/garage_store.dart';
import 'package:garage_management_system/src/theme/app_theme.dart';
import 'package:garage_management_system/src/utils/garage_utils.dart';
import 'package:garage_management_system/src/widgets/responsive.dart';
import 'package:garage_management_system/src/widgets/ui_components.dart';
import 'package:provider/provider.dart';

class EstimateEditorPage extends StatefulWidget {
  const EstimateEditorPage({
    super.key,
    required this.jobCard,
    this.existingEstimate,
  });

  final JobCard jobCard;
  final Estimate? existingEstimate;

  static Future<bool?> show(
    BuildContext context, {
    required JobCard jobCard,
    Estimate? existingEstimate,
  }) {
    final store = context.read<GarageStore>();
    return Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (routeContext) => ChangeNotifierProvider<GarageStore>.value(
          value: store,
          child: EstimateEditorPage(
            jobCard: jobCard,
            existingEstimate: existingEstimate,
          ),
        ),
      ),
    );
  }

  @override
  State<EstimateEditorPage> createState() => _EstimateEditorPageState();
}

class _EstimateEditorPageState extends State<EstimateEditorPage> {
  late final TextEditingController remarksController;
  late final TextEditingController labourDesc;
  late final TextEditingController labourAmount;
  late final TextEditingController partSearch;
  late final TextEditingController partQty;
  late final TextEditingController partPrice;
  late final List<InvoiceLineDraft> labourLines;
  late final List<PartLineDraft> partLines;
  final Map<String, FocusNode> _partPriceFocusNodes = {};
  String? partStockItemId;
  String? editingEstimateId;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final estimate = widget.existingEstimate;
    editingEstimateId = estimate?.id;
    remarksController = TextEditingController(text: estimate?.remarks ?? '');
    labourDesc = TextEditingController();
    labourAmount = TextEditingController();
    partSearch = TextEditingController();
    partQty = TextEditingController(text: '1');
    partPrice = TextEditingController();
    labourLines = List.of(estimate?.labourItems ?? const []);
    partLines = estimate?.partsItems
            .map(
              (part) => PartLineDraft(
                stockItemId: part.stockItemId,
                qty: part.qty,
                unitPriceOverride: part.unitPrice,
              ),
            )
            .toList() ??
        [];
  }

  @override
  void dispose() {
    remarksController.dispose();
    labourDesc.dispose();
    labourAmount.dispose();
    partSearch.dispose();
    partQty.dispose();
    partPrice.dispose();
    for (final node in _partPriceFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  FocusNode _priceFocusNodeFor(String stockItemId) {
    return _partPriceFocusNodes.putIfAbsent(stockItemId, () {
      final node = FocusNode();
      node.addListener(() {
        if (!node.hasFocus) {
          _handleExistingPriceCommitted(stockItemId);
        }
      });
      return node;
    });
  }

  double _draftLabourAmount() {
    final parsed = double.tryParse(labourAmount.text.trim()) ?? 0;
    if (labourDesc.text.trim().isEmpty || parsed <= 0) {
      return 0;
    }
    return parsed;
  }

  double? _draftPartPrice() => double.tryParse(partPrice.text.trim());

  double _draftPartsAmount(GarageStore store) {
    if (partStockItemId == null) {
      return 0;
    }
    final qty = int.tryParse(partQty.text.trim()) ?? 0;
    final price = _draftPartPrice();
    if (qty <= 0 || price == null || price < 0) {
      return 0;
    }
    return PartLineDraft(
      stockItemId: partStockItemId!,
      qty: qty,
      unitPriceOverride: price,
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
      final price = _draftPartPrice();
      if (qty > 0 && price != null && price >= 0) {
        final existingIndex =
            partLines.indexWhere((line) => line.stockItemId == partStockItemId);
        if (existingIndex >= 0) {
          final existing = partLines[existingIndex];
          partLines[existingIndex] = PartLineDraft(
            stockItemId: existing.stockItemId,
            qty: existing.qty + qty,
            unitPriceOverride: price,
          );
        } else {
          partLines.add(
            PartLineDraft(
              stockItemId: partStockItemId!,
              qty: qty,
              unitPriceOverride: price,
            ),
          );
        }
        partQty.text = '1';
        partPrice.clear();
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

  /// Prompts to sync the stock item's selling price when [newPrice] differs
  /// from it. Called right when a part's price is committed (Add click, or
  /// leaving an existing line's price field) rather than at final save.
  Future<void> _maybeSyncStockPrice(
    GarageStore store,
    String stockItemId,
    double newPrice,
  ) async {
    final stock =
        store.stockItems.where((item) => item.id == stockItemId).firstOrNull;
    if (stock == null || newPrice == stock.sellingPrice) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Update stock price?'),
        content: Text(
          '${stock.name} is priced at ${formatAmount(newPrice)} here, '
          'different from the stock price of ${formatAmount(stock.sellingPrice)}. '
          'Update the stock price too so future estimates use the new rate?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Just this estimate'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Update stock price'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await store.updateStockItem(stock.copyWith(sellingPrice: newPrice));
    }
  }

  Future<void> _handleExistingPriceCommitted(String stockItemId) async {
    final index = partLines.indexWhere((line) => line.stockItemId == stockItemId);
    if (index == -1) {
      return;
    }
    final price = partLines[index].unitPriceOverride;
    if (price == null) {
      return;
    }
    await _maybeSyncStockPrice(context.read<GarageStore>(), stockItemId, price);
  }

  Future<void> _addPart(GarageStore store) async {
    final stockItemId = partStockItemId;
    final qty = int.tryParse(partQty.text.trim()) ?? 0;
    final price = _draftPartPrice();
    if (stockItemId == null || qty <= 0 || price == null || price < 0) {
      return;
    }
    setState(() => _flushDraftLines(store));
    await _maybeSyncStockPrice(store, stockItemId, price);
  }

  Future<void> _save(GarageStore store) async {
    setState(() => _flushDraftLines(store));
    if (labourLines.isEmpty && partLines.isEmpty) {
      showAppSnackBar(context, 'Add at least one labour item or part');
      return;
    }

    setState(() => saving = true);
    final editing = editingEstimateId;
    final saved = editing == null
        ? await store.createEstimate(
            jobCardId: widget.jobCard.id,
            labourItems: labourLines,
            partsItems: partLines,
            remarks: remarksController.text.trim(),
          )
        : await store.updateEstimate(
            id: editing,
            labourLines: labourLines,
            partsItems: partLines,
            remarks: remarksController.text.trim(),
          );
    if (!mounted) {
      return;
    }
    setState(() => saving = false);

    if (!saved) {
      showAppSnackBar(context, store.lastError ?? 'Could not save estimate');
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GarageStore>();
    final vehicle = store.vehicles
        .where((item) => item.id == widget.jobCard.vehicleId)
        .firstOrNull;
    final labourTotal =
        labourLines.fold<double>(0, (sum, item) => sum + item.amount);
    final partsTotal =
        partLines.fold<double>(0, (sum, line) => sum + line.amountFor(store.stockItems));
    final displayLabourTotal = labourTotal + _draftLabourAmount();
    final displayPartsTotal = partsTotal + _draftPartsAmount(store);
    final isEdit = editingEstimateId != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Estimate' : 'New Estimate',
          style: const TextStyle(fontWeight: FontWeight.w700),
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
                          'Job Card #${widget.jobCard.jobCardNumber} · '
                          '${store.vehicleNumber(widget.jobCard.vehicleId)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${store.customerName(widget.jobCard.customerId)} · '
                          '${store.customerMobile(widget.jobCard.customerId)}',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                        if (vehicle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${vehicle.brand} ${vehicle.model} · KM ${widget.jobCard.kmReading}',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                          ),
                        ],
                        if (widget.jobCard.customerComplaints.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            widget.jobCard.customerComplaints,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
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
                  if (labourLines.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          for (final entry in labourLines.asMap().entries) ...[
                            if (entry.key != 0) const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              child: Row(
                                children: [
                                  Expanded(child: Text(entry.value.description)),
                                  Text(
                                    formatAmount(entry.value.amount),
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  IconButton(
                                    tooltip: 'Remove',
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => setState(
                                      () => labourLines.removeAt(entry.key),
                                    ),
                                    icon: const Icon(Icons.close_rounded, size: 18),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
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
                            partPrice.text = item.sellingPrice.toStringAsFixed(0);
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
                      AppTextField(
                        controller: partPrice,
                        label: 'Price (₹)',
                        width: 130,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                      ),
                      OutlinedButton.icon(
                        onPressed: partStockItemId == null || _draftPartPrice() == null
                            ? null
                            : () => _addPart(store),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  if (partLines.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Padding(
                      padding: EdgeInsets.only(left: 12, right: 48),
                      child: Row(
                        children: [
                          Expanded(child: SizedBox()),
                          SizedBox(
                            width: 56,
                            child: Text(
                              'Qty',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          SizedBox(
                            width: 100,
                            child: Text(
                              'Price (₹)',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          SizedBox(
                            width: 84,
                            child: Text(
                              'Amount',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          for (final entry in partLines.asMap().entries) ...[
                            if (entry.key != 0) const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      store.stockItemName(entry.value.stockItemId),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 56,
                                    child: TextFormField(
                                      key: ValueKey('part-qty-${entry.value.stockItemId}'),
                                      initialValue: '${entry.value.qty}',
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 8,
                                        ),
                                      ),
                                      onChanged: (value) {
                                        final qty = int.tryParse(value.trim());
                                        if (qty == null || qty <= 0) {
                                          return;
                                        }
                                        final index = entry.key;
                                        final line = entry.value;
                                        setState(() {
                                          partLines[index] = PartLineDraft(
                                            stockItemId: line.stockItemId,
                                            qty: qty,
                                            unitPriceOverride: line.unitPriceOverride,
                                          );
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 100,
                                    child: TextFormField(
                                      key: ValueKey(
                                        'part-price-${entry.value.stockItemId}',
                                      ),
                                      focusNode:
                                          _priceFocusNodeFor(entry.value.stockItemId),
                                      initialValue: entry.value
                                          .unitPriceFor(store.stockItems)
                                          .toStringAsFixed(0),
                                      textAlign: TextAlign.center,
                                      keyboardType: const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 8,
                                        ),
                                      ),
                                      onChanged: (value) {
                                        final price = double.tryParse(value.trim());
                                        if (price == null || price < 0) {
                                          return;
                                        }
                                        final index = entry.key;
                                        final line = entry.value;
                                        setState(() {
                                          partLines[index] = PartLineDraft(
                                            stockItemId: line.stockItemId,
                                            qty: line.qty,
                                            unitPriceOverride: price,
                                          );
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 84,
                                    child: Text(
                                      formatAmount(
                                        entry.value.amountFor(store.stockItems),
                                      ),
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Remove',
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () =>
                                        setState(() => partLines.removeAt(entry.key)),
                                    icon: const Icon(Icons.close_rounded, size: 18),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  AppMultilineField(
                    controller: remarksController,
                    label: 'Remarks',
                    hint: 'Shown on estimate PDF...',
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
                onPressed: saving || !_canSave(store) ? null : () => _save(store),
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(isEdit ? Icons.update_rounded : Icons.save_rounded, size: 18),
                label: Text(isEdit ? 'Update Estimate' : 'Save Estimate'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
