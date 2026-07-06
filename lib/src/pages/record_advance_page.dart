import 'package:flutter/material.dart';
import 'package:garage_management_system/src/models/garage_models.dart';
import 'package:garage_management_system/src/store/garage_store.dart';
import 'package:garage_management_system/src/theme/app_theme.dart';
import 'package:garage_management_system/src/utils/garage_utils.dart';
import 'package:garage_management_system/src/widgets/ui_components.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class RecordAdvancePage extends StatefulWidget {
  const RecordAdvancePage({super.key});

  @override
  State<RecordAdvancePage> createState() => _RecordAdvancePageState();
}

class _RecordAdvancePageState extends State<RecordAdvancePage> {
  String? selectedCustomerId;
  final partySearch = TextEditingController();
  final advanceAmount = TextEditingController();
  final advanceNote = TextEditingController();
  final listSearch = TextEditingController();

  @override
  void dispose() {
    partySearch.dispose();
    advanceAmount.dispose();
    advanceNote.dispose();
    listSearch.dispose();
    super.dispose();
  }

  void _selectParty(Customer customer) {
    setState(() {
      selectedCustomerId = customer.id;
      partySearch.text = customer.name;
    });
  }

  void _onPartySearchChanged(GarageStore store, String value) {
    final trimmed = value.trim();
    final selected = selectedCustomerId == null
        ? null
        : store.customers
            .where((customer) => customer.id == selectedCustomerId)
            .firstOrNull;
    if (selected != null && selected.name == trimmed) {
      return;
    }
    final match = store.customers
        .where(
          (customer) =>
              customer.name.toLowerCase() == trimmed.toLowerCase() ||
              customer.mobile == trimmed,
        )
        .firstOrNull;
    setState(() => selectedCustomerId = match?.id);
  }

  Future<void> _recordAdvance(GarageStore store) async {
    if (selectedCustomerId == null) {
      showAppSnackBar(context, 'Select a party first.');
      return;
    }
    final amount = double.tryParse(advanceAmount.text.trim()) ?? 0;
    if (amount <= 0) {
      showAppSnackBar(context, 'Enter a valid advance amount');
      return;
    }
    final error = await store.recordPaymentReceipt(
      customerId: selectedCustomerId!,
      amount: amount,
      note: advanceNote.text.trim(),
    );
    if (!mounted) {
      return;
    }
    if (error != null) {
      showAppSnackBar(context, error);
      return;
    }
    advanceAmount.clear();
    advanceNote.clear();
    showAppSnackBar(
      context,
      'Advance ${formatAmount(amount)} recorded',
      backgroundColor: AppColors.success,
    );
  }

  List<PaymentRecord> _advanceEntries(GarageStore store) {
    final query = listSearch.text.trim().toLowerCase();
    final advances = store.payments.where((payment) => payment.isAdvance).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (query.isEmpty) {
      return advances;
    }

    return advances.where((payment) {
      final name = store.customerName(payment.customerId).toLowerCase();
      final mobile = store.customerMobile(payment.customerId);
      return name.contains(query) ||
          mobile.contains(query) ||
          payment.note.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GarageStore>();
    final advances = _advanceEntries(store);
    final totalOnAccount = store.payments
        .where((payment) => payment.isAdvance)
        .fold<double>(0, (sum, payment) => sum + payment.amount);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Record Advance',
            subtitle: 'Customer pays before final bill — e.g. ₹10,000 at a time',
            icon: Icons.savings_outlined,
          ),
          SectionCard(
            title: 'New Advance',
            icon: Icons.add_card_rounded,
            child: store.customers.isEmpty
                ? const Text(
                    'Add a party under Party first.',
                    style: TextStyle(color: AppColors.textMuted),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PartySearchField(
                        controller: partySearch,
                        expand: true,
                        optionsBuilder: store.searchCustomers,
                        onSelected: _selectParty,
                        onChanged: (value) => _onPartySearchChanged(store, value),
                      ),
                      if (selectedCustomerId != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          '${store.customerName(selectedCustomerId!)} · '
                          '${store.customerMobile(selectedCustomerId!)}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Advance on account: '
                          '${formatAmount(store.customerAdvanceBalance(selectedCustomerId!))}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      AppFormRow(
                        children: [
                          AppTextField(
                            controller: advanceAmount,
                            label: 'Amount received now (₹) *',
                            expand: true,
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            hint: 'e.g. 10000',
                          ),
                          AppTextField(
                            controller: advanceNote,
                            label: 'Note (optional)',
                            expand: true,
                            hint: 'Cash / UPI',
                          ),
                        ],
                      ),
                      AppFormActions(
                        primary: FilledButton.icon(
                          onPressed: selectedCustomerId == null
                              ? null
                              : () => _recordAdvance(store),
                          icon: const Icon(Icons.savings_outlined, size: 20),
                          label: const Text('Record Advance'),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Advance Ledger',
            icon: Icons.receipt_long_outlined,
            subtitle:
                '${advances.length} open advances · ${formatAmount(totalOnAccount)} on account',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSearchField(
                  controller: listSearch,
                  hint: 'Search party, mobile, note…',
                  expand: true,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                if (advances.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No advances recorded yet.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                else
                  ...advances.map((payment) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.1),
                          child: const Icon(
                            Icons.savings_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          store.customerName(payment.customerId),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${store.customerMobile(payment.customerId)} · '
                          '${DateFormat('dd MMM yyyy, hh:mm a').format(payment.createdAt)}'
                          '${payment.note.isNotEmpty ? '\n${payment.note}' : ''}',
                        ),
                        isThreeLine: payment.note.isNotEmpty,
                        trailing: Text(
                          formatAmount(payment.amount),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
