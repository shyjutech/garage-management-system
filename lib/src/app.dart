import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:garage_management_system/src/pages/estimate_editor_page.dart';
import 'package:garage_management_system/src/pages/expenses_page.dart';
import 'package:garage_management_system/src/pages/help_page.dart';
import 'package:garage_management_system/src/pages/job_cards_page.dart';
import 'package:garage_management_system/src/pages/monthly_summary_page.dart';
import 'package:garage_management_system/src/pages/outstanding_balances_page.dart';
import 'package:garage_management_system/src/pages/parties_list_page.dart';
import 'package:garage_management_system/src/pages/record_advance_page.dart';
import 'package:garage_management_system/src/models/garage_models.dart';
import 'package:garage_management_system/src/services/firebase_bootstrap.dart';
import 'package:garage_management_system/src/store/garage_store.dart';
import 'package:garage_management_system/src/theme/app_theme.dart';
import 'package:garage_management_system/src/utils/browser_cache_clearer.dart';
import 'package:garage_management_system/src/utils/estimate_pdf.dart';
import 'package:garage_management_system/src/utils/garage_utils.dart';
import 'package:garage_management_system/src/utils/invoice_pdf.dart';
import 'package:garage_management_system/src/widgets/invoice_editor_dialog.dart';
import 'package:garage_management_system/src/widgets/ui_components.dart';
import 'package:garage_management_system/src/widgets/responsive.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> confirmLogout(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Log out?'),
      content: const Text('You will need to sign in again to continue.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Log out'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    await FirebaseAuth.instance.signOut();
  }
}

enum AppSection {
  dashboard,
  monthlySummary,
  parties,
  history,
  stock,
  labour,
  jobCards,
  estimates,
  invoices,
  advances,
  expenses,
  outstandingBalances,
  help,
  settings,
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  AppSection section = AppSection.dashboard;
  final globalSearchController = TextEditingController();
  Vehicle? highlightedVehicle;
  bool _sidebarVisible = true;

  static const navItems = <(AppSection, IconData, String)>[
    (AppSection.dashboard, Icons.dashboard_rounded, 'Dashboard'),
    (
      AppSection.monthlySummary,
      Icons.calendar_month_rounded,
      'Monthly Summary',
    ),
    (AppSection.parties, Icons.people_rounded, 'Party'),
    (AppSection.history, Icons.history_rounded, 'History'),
    (AppSection.stock, Icons.inventory_2_rounded, 'Stock'),
    (AppSection.labour, Icons.handyman_rounded, 'Labour'),
    (AppSection.jobCards, Icons.build_circle_rounded, 'Job Cards'),
    (AppSection.estimates, Icons.request_quote_rounded, 'Estimates'),
    (AppSection.invoices, Icons.receipt_long_rounded, 'Invoices'),
    (AppSection.advances, Icons.savings_outlined, 'Advance'),
    (AppSection.expenses, Icons.currency_rupee_rounded, 'Expenses'),
    (
      AppSection.outstandingBalances,
      Icons.account_balance_wallet_rounded,
      'Outstanding',
    ),
    (AppSection.help, Icons.help_outline_rounded, 'Help'),
    (AppSection.settings, Icons.settings_rounded, 'Settings'),
  ];

  @override
  void dispose() {
    globalSearchController.dispose();
    super.dispose();
  }

  void _selectSection(AppSection value) {
    setState(() => section = value);
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  void _closeDrawer() {
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }


  Widget _buildSidebarContent(
    GarageStore store, {
    required bool isDrawer,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, isDrawer ? 12 : 28, 12, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.directions_car_filled_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'SARATHI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'AUTOMOBILES',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Garage Management',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: isDrawer ? 'Close menu' : 'Hide menu',
                onPressed: isDrawer
                    ? _closeDrawer
                    : () => setState(() => _sidebarVisible = false),
                icon: Icon(
                  isDrawer ? Icons.close_rounded : Icons.chevron_left_rounded,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white24, height: 1, indent: 16, endIndent: 16),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: navItems
                .map(
                  (item) => SidebarNavItem(
                    icon: item.$2,
                    label: item.$3,
                    selected: section == item.$1,
                    onTap: () => _selectSection(item.$1),
                  ),
                )
                .toList(),
          ),
        ),
        if (FirebaseBootstrap.isConfigured) ...[
          const Divider(color: Colors.white24, height: 1, indent: 16, endIndent: 16),
          SidebarNavItem(
            icon: Icons.logout_rounded,
            label: 'Log out',
            selected: false,
            onTap: () => confirmLogout(context),
          ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Text(
            store.settings.businessName,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _openVehicleHistory(Vehicle vehicle) {
    setState(() {
      highlightedVehicle = vehicle;
      globalSearchController.text = vehicle.regNumber;
      section = AppSection.history;
    });
    _closeDrawer();
  }

  Widget _buildGlobalVehicleSearch(GarageStore store, {required bool expand}) {
    return VehicleSearchField(
      controller: globalSearchController,
      expand: expand,
      headerStyle: true,
      optionsBuilder: store.searchVehicles,
      customerName: store.customerName,
      customerMobile: store.customerMobile,
      onSelected: _openVehicleHistory,
    );
  }

  Widget _buildPage(
    Map<AppSection, Widget> pages,
  ) {
    return switch (section) {
      AppSection.history => VehicleHistoryPage(
          preSelectedVehicle: highlightedVehicle,
        ),
      AppSection.settings => const SettingsPage(),
      _ => pages[section]!,
    };
  }

  void _goToJobCards() {
    _selectSection(AppSection.jobCards);
  }

  void _goToEstimates() {
    _selectSection(AppSection.estimates);
  }

  void _goToInvoices() {
    _selectSection(AppSection.invoices);
  }

  void _goToStock() {
    _selectSection(AppSection.stock);
  }

  @override
  Widget build(BuildContext context) {
    final pages = <AppSection, Widget>{
      AppSection.dashboard: DashboardPage(
        onJobCardCreated: (_) => _goToJobCards(),
        onOpenJobCards: _goToJobCards,
        onOpenEstimates: _goToEstimates,
        onOpenStock: _goToStock,
      ),
      AppSection.monthlySummary: const MonthlySummaryPage(),
      AppSection.parties: const PartiesPage(),
      AppSection.history: const VehicleHistoryPage(),
      AppSection.stock: const StockPage(),
      AppSection.labour: const LabourPage(),
      AppSection.jobCards: JobCardsPage(onEstimateSaved: _goToEstimates),
      AppSection.estimates: EstimatesPage(onInvoiceCreated: _goToInvoices),
      AppSection.invoices: const InvoicesPage(),
      AppSection.advances: const RecordAdvancePage(),
      AppSection.expenses: const ExpensesPage(),
      AppSection.outstandingBalances: const OutstandingBalancesPage(),
      AppSection.help: const HelpPage(),
    };
    final store = context.watch<GarageStore>();
    final compact = AppBreakpoints.isCompact(context);
    final currentTitle = navItems.firstWhere((n) => n.$1 == section).$3;

    if (compact) {
      return Scaffold(
        backgroundColor: AppColors.background,
        drawer: Drawer(
          width: 280,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.sidebar, AppColors.primaryDark],
              ),
            ),
            child: SafeArea(
              child: _buildSidebarContent(store, isDrawer: true),
            ),
          ),
        ),
        appBar: AppBar(
          title: Text(currentTitle),
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: _buildGlobalVehicleSearch(store, expand: true),
              ),
              Expanded(
                child: Padding(
                  padding: AppBreakpoints.pagePadding(context),
                  child: _buildPage(pages),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          if (_sidebarVisible)
            SizedBox(
              width: 240,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.sidebar, AppColors.primaryDark],
                  ),
                ),
                child: SafeArea(
                  child: _buildSidebarContent(store, isDrawer: false),
                ),
              ),
            ),
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      if (!_sidebarVisible)
                        IconButton(
                          tooltip: 'Show menu',
                          onPressed: () => setState(() => _sidebarVisible = true),
                          icon: const Icon(Icons.menu_rounded),
                        ),
                      Expanded(
                        child: Text(
                          currentTitle,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      _buildGlobalVehicleSearch(store, expand: false),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: AppBreakpoints.pagePadding(context),
                    child: _buildPage(pages),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    this.onJobCardCreated,
    this.onOpenJobCards,
    this.onOpenEstimates,
    this.onOpenStock,
  });

  final void Function(String jobCardId)? onJobCardCreated;
  final VoidCallback? onOpenJobCards;
  final VoidCallback? onOpenEstimates;
  final VoidCallback? onOpenStock;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final regNumber = TextEditingController();
  final km = TextEditingController();
  final mechanic = TextEditingController();
  final complaints = TextEditingController();
  final remarks = TextEditingController();
  String fuelLevel = 'Half';
  Vehicle? matchedVehicle;

  @override
  void dispose() {
    regNumber.dispose();
    km.dispose();
    mechanic.dispose();
    complaints.dispose();
    remarks.dispose();
    super.dispose();
  }

  void _selectVehicle(Vehicle vehicle) {
    setState(() {
      matchedVehicle = vehicle;
      regNumber.text = vehicle.regNumber;
      if (km.text.trim().isEmpty) {
        km.text = vehicle.lastKmReading.toString();
      }
    });
  }

  Future<void> _createQuickJobCard(GarageStore store) async {
    if (matchedVehicle == null) {
      showAppSnackBar(
        context,
        'Select a vehicle from the search list.',
      );
      return;
    }
    final kmError = FormValidators.positiveKm(km.text);
    final mechanicError = FormValidators.requiredText(mechanic.text, 'Mechanic');
    final complaintError =
        FormValidators.requiredText(complaints.text, 'Complaint');
    final error = kmError ?? mechanicError ?? complaintError;
    if (error != null) {
      showAppSnackBar(context, error);
      return;
    }

    final vehicle = matchedVehicle!;

    final card = await store.addJobCard(
      customerId: vehicle.customerId,
      vehicleId: vehicle.id,
      kmReading: int.parse(km.text.trim()),
      fuelLevel: fuelLevel,
      customerComplaints: complaints.text.trim(),
      complaintItems: const [],
      observations: '',
      requestedWorks: '',
      otherNotes: '',
      internalNotes: '',
      remarks: remarks.text.trim(),
      mechanicName: mechanic.text.trim(),
    );

    if (!mounted) return;
    if (card == null) {
      showAppSnackBar(context, store.lastError ?? 'Could not create job card');
      return;
    }

    complaints.clear();
    remarks.clear();
    mechanic.clear();
    regNumber.clear();
    setState(() => matchedVehicle = null);

    widget.onJobCardCreated?.call(card.id);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Job card #${card.jobCardNumber} created — add labour & parts next',
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GarageStore>();
    final now = DateTime.now();
    final todayInvoices = store.invoices
        .where((invoice) => sameDay(invoice.createdAt, now))
        .toList();
    final monthInvoices = store.invoices
        .where((invoice) =>
            invoice.createdAt.year == now.year &&
            invoice.createdAt.month == now.month)
        .toList();
    final todaySales = todayInvoices.fold<double>(
      0,
      (sum, item) => sum + item.grandTotal,
    );
    final monthlySales = monthInvoices.fold<double>(
      0,
      (sum, item) => sum + item.grandTotal,
    );
    final pending = store.invoices
        .where((invoice) => invoice.paymentStatus != PaymentStatus.paid)
        .fold<double>(0, (sum, invoice) => sum + invoice.balanceAmount);
    final labourRevenue = monthInvoices.fold<double>(
      0,
      (sum, invoice) => sum + invoice.labourTotal,
    );
    final partsRevenue = monthInvoices.fold<double>(
      0,
      (sum, invoice) => sum + invoice.partsTotal,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionCard(
            title: 'Quick Job Card',
            icon: Icons.build_circle_rounded,
            subtitle:
                'New customer? Add them under Party first, then start a job here',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                VehicleSearchField(
                  controller: regNumber,
                  expand: true,
                  optionsBuilder: store.searchVehicles,
                  customerName: store.customerName,
                  customerMobile: store.customerMobile,
                  onSelected: _selectVehicle,
                  onChanged: (_) => setState(() => matchedVehicle = null),
                ),
                if (matchedVehicle != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
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
                          matchedVehicle!.regNumber,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${store.customerName(matchedVehicle!.customerId)} · '
                          '${matchedVehicle!.brand} ${matchedVehicle!.model}',
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
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
                        label: 'Mechanic *',
                        expand: true,
                      ),
                      DropdownButtonFormField<String>(
                        value: fuelLevel,
                        decoration: const InputDecoration(labelText: 'Fuel level'),
                        items: const [
                          DropdownMenuItem(value: 'Empty', child: Text('Empty')),
                          DropdownMenuItem(value: 'Quarter', child: Text('1/4')),
                          DropdownMenuItem(value: 'Half', child: Text('1/2')),
                          DropdownMenuItem(value: 'Three Quarter', child: Text('3/4')),
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
                  AppMultilineField(
                    controller: complaints,
                    label: 'Customer complaint *',
                    hint: 'What the customer reported...',
                    minLines: 2,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  AppMultilineField(
                    controller: remarks,
                    label: 'Remarks',
                    hint: 'Optional notes for job card print...',
                    minLines: 2,
                    maxLines: 4,
                  ),
                  AppFormActions(
                    primary: FilledButton.icon(
                      onPressed: () => _createQuickJobCard(store),
                      icon: const Icon(Icons.note_add_rounded, size: 20),
                      label: const Text('Create Job Card'),
                    ),
                  ),
                ] else if (regNumber.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Pick a vehicle from the search results above.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              MetricCard(
                label: 'Today Sales',
                value: formatAmount(todaySales),
                icon: Icons.payments_rounded,
              ),
              MetricCard(
                label: 'Monthly Sales',
                value: formatAmount(monthlySales),
                icon: Icons.calendar_month_rounded,
                accentColor: AppColors.primaryDark,
              ),
              MetricCard(
                label: 'Pending Payments',
                value: formatAmount(pending),
                icon: Icons.pending_actions_rounded,
                accentColor: AppColors.warning,
              ),
              MetricCard(
                label: 'Job Cards Today',
                value: '${store.todayJobCards}',
                icon: Icons.assignment_rounded,
                onTap: widget.onOpenJobCards,
              ),
              MetricCard(
                label: 'Live Job Cards',
                value: '${store.activeJobCards}',
                icon: Icons.build_circle_rounded,
                accentColor: AppColors.primary,
                onTap: widget.onOpenJobCards,
              ),
              if (store.activeRole == UserRole.admin)
                MetricCard(
                  label: 'Low Stock Alerts',
                  value: '${store.lowStockItems.length}',
                  icon: Icons.warning_amber_rounded,
                  accentColor: store.lowStockItems.isEmpty
                      ? AppColors.success
                      : AppColors.warning,
                  onTap: widget.onOpenStock,
                ),
              MetricCard(
                label: 'Labour Revenue',
                value: formatAmount(labourRevenue),
                icon: Icons.handyman_rounded,
              ),
              MetricCard(
                label: 'Parts Revenue',
                value: formatAmount(partsRevenue),
                icon: Icons.precision_manufacturing_rounded,
              ),
              MetricCard(
                label: 'Open Estimates',
                value: '${store.openEstimates}',
                icon: Icons.request_quote_rounded,
                accentColor: AppColors.primaryLight,
                onTap: widget.onOpenEstimates,
              ),
            ],
          ),
          const SizedBox(height: 24),
          SectionCard(
            title: 'Recent Invoices',
            icon: Icons.receipt_long_rounded,
            child: Column(
              children: store.invoices.take(5).map(
                (invoice) => DataListTile(
                  title: 'Invoice #${invoice.invoiceNumber}',
                  subtitle:
                      '${store.customerName(invoice.customerId)} · ${invoice.vehicleNumber}',
                  trailing: Text(
                    formatAmount(invoice.grandTotal),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Disposing a dialog's [TextEditingController]s synchronously right after
/// `Navigator.pop` races the dialog's closing transition (which still reads
/// the controller for a frame or two). Deferring to the next frame avoids
/// the "used after being disposed" assertion.
void _disposeAfterFrame(List<TextEditingController> controllers) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    for (final controller in controllers) {
      controller.dispose();
    }
  });
}

class PartiesPage extends StatefulWidget {
  const PartiesPage({super.key});

  @override
  State<PartiesPage> createState() => _PartiesPageState();
}

class _PartiesPageState extends State<PartiesPage> {
  final customerName = TextEditingController();
  final mobile = TextEditingController();
  final address = TextEditingController();
  String? selectedCustomerId;
  final partySearch = TextEditingController();
  final regNumber = TextEditingController();
  final brand = TextEditingController();
  final model = TextEditingController();
  final year = TextEditingController();

  @override
  void dispose() {
    customerName.dispose();
    mobile.dispose();
    address.dispose();
    partySearch.dispose();
    regNumber.dispose();
    brand.dispose();
    model.dispose();
    year.dispose();
    super.dispose();
  }

  Future<void> _addParty(GarageStore store) async {
    final nameError = FormValidators.requiredText(customerName.text, 'Name');
    final mobileError = FormValidators.mobile(mobile.text);
    final addressError = FormValidators.requiredText(address.text, 'Address');
    final error = nameError ?? mobileError ?? addressError;
    if (error != null) {
      showAppSnackBar(context, error);
      return;
    }
    final addedMobile = normalizeMobile(mobile.text);
    final existing = store.customerByMobile(addedMobile);
    if (existing != null) {
      _selectParty(existing);
      showAppSnackBar(
        context,
        'Party already exists — ${existing.name} selected for Add Vehicle',
      );
      return;
    }

    final added = await store.addCustomer(
      name: customerName.text.trim(),
      mobile: addedMobile,
      address: address.text.trim(),
    );
    customerName.clear();
    mobile.clear();
    address.clear();
    if (!context.mounted) {
      return;
    }
    if (added == null) {
      showAppSnackBar(context, store.lastError ?? 'Could not add party');
      return;
    }
    _selectParty(added);
    showAppSnackBar(
        context,
        'Party added',
        backgroundColor: AppColors.success,
      );
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

  Future<void> _addVehicle(GarageStore store) async {
    if (selectedCustomerId == null) {
      showAppSnackBar(context, 'Select a party from the search list.');
      return;
    }
    final regError = FormValidators.vehicleNumber(regNumber.text);
    final brandError = FormValidators.requiredText(brand.text, 'Brand');
    final modelError = FormValidators.requiredText(model.text, 'Model');
    final yearError = FormValidators.vehicleYear(year.text);
    final error = regError ?? brandError ?? modelError ?? yearError;
    if (error != null) {
      showAppSnackBar(context, error);
      return;
    }
    await store.addVehicle(
      customerId: selectedCustomerId!,
      regNumber: regNumber.text.trim(),
      brand: brand.text.trim(),
      model: model.text.trim(),
      year: int.parse(year.text.trim()),
      lastKm: 0,
    );
    regNumber.clear();
    brand.clear();
    model.clear();
    year.clear();
    if (context.mounted) {
      showAppSnackBar(
        context,
        'Vehicle added',
        backgroundColor: AppColors.success,
      );
    }
  }

  Future<void> _showEditCustomerDialog(GarageStore store, Customer customer) async {
    final editName = TextEditingController(text: customer.name);
    final editMobile = TextEditingController(text: customer.mobile);
    final editAddress = TextEditingController(text: customer.address);

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Party'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(controller: editName, label: 'Name *', expand: true),
              const SizedBox(height: 12),
              AppTextField(
                controller: editMobile,
                label: 'Mobile *',
                expand: true,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 12),
              AppTextField(controller: editAddress, label: 'Address *', expand: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved != true) {
      _disposeAfterFrame([editName, editMobile, editAddress]);
      return;
    }

    final nameError = FormValidators.requiredText(editName.text, 'Name');
    final mobileError = FormValidators.mobile(editMobile.text);
    final addressError = FormValidators.requiredText(editAddress.text, 'Address');
    final error = nameError ?? mobileError ?? addressError;

    final updated = customer.copyWith(
      name: editName.text.trim(),
      mobile: normalizeMobile(editMobile.text),
      address: editAddress.text.trim(),
    );
    _disposeAfterFrame([editName, editMobile, editAddress]);

    if (error != null) {
      if (mounted) {
        showAppSnackBar(context, error);
      }
      return;
    }

    final ok = await store.updateCustomer(updated);
    if (!mounted) return;
    if (!ok) {
      showAppSnackBar(context, store.lastError ?? 'Could not update party');
      return;
    }
    showAppSnackBar(context, 'Party updated', backgroundColor: AppColors.success);
  }

  Future<void> _confirmDeleteCustomer(GarageStore store, Customer customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete party?'),
        content: Text(
          'Remove "${customer.name}" permanently? This cannot be undone. '
          'Their vehicles must be removed first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final ok = await store.deleteCustomer(customer.id);
    if (!mounted) return;
    if (!ok) {
      showAppSnackBar(context, store.lastError ?? 'Could not delete party');
      return;
    }
    if (selectedCustomerId == customer.id) {
      setState(() {
        selectedCustomerId = null;
        partySearch.clear();
      });
    }
    showAppSnackBar(context, 'Party deleted', backgroundColor: AppColors.success);
  }

  Future<void> _showEditVehicleDialog(GarageStore store, Vehicle vehicle) async {
    final editReg = TextEditingController(text: vehicle.regNumber);
    final editBrand = TextEditingController(text: vehicle.brand);
    final editModel = TextEditingController(text: vehicle.model);
    final editYear = TextEditingController(text: vehicle.year.toString());
    final editKm = TextEditingController(text: vehicle.lastKmReading.toString());

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Vehicle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: editReg,
                label: 'Vehicle Number *',
                expand: true,
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 12),
              AppTextField(controller: editBrand, label: 'Brand *', expand: true),
              const SizedBox(height: 12),
              AppTextField(controller: editModel, label: 'Model *', expand: true),
              const SizedBox(height: 12),
              AppTextField(
                controller: editYear,
                label: 'Year *',
                expand: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: editKm,
                label: 'Last KM Reading',
                expand: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved != true) {
      _disposeAfterFrame([editReg, editBrand, editModel, editYear, editKm]);
      return;
    }

    final regError = FormValidators.vehicleNumber(editReg.text);
    final brandError = FormValidators.requiredText(editBrand.text, 'Brand');
    final modelError = FormValidators.requiredText(editModel.text, 'Model');
    final yearError = FormValidators.vehicleYear(editYear.text);
    final kmValue = int.tryParse(editKm.text.trim());
    final error = regError ??
        brandError ??
        modelError ??
        yearError ??
        (kmValue == null || kmValue < 0 ? 'Enter a valid KM reading' : null);

    final updated = vehicle.copyWith(
      regNumber: editReg.text.trim().toUpperCase(),
      brand: editBrand.text.trim(),
      model: editModel.text.trim(),
      year: int.tryParse(editYear.text.trim()),
      lastKmReading: kmValue,
    );
    _disposeAfterFrame([editReg, editBrand, editModel, editYear, editKm]);

    if (error != null) {
      if (mounted) {
        showAppSnackBar(context, error);
      }
      return;
    }

    final ok = await store.updateVehicle(updated);
    if (!mounted) return;
    if (!ok) {
      showAppSnackBar(context, store.lastError ?? 'Could not update vehicle');
      return;
    }
    showAppSnackBar(context, 'Vehicle updated', backgroundColor: AppColors.success);
  }

  Future<void> _confirmDeleteVehicle(GarageStore store, Vehicle vehicle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete vehicle?'),
        content: Text(
          'Remove "${vehicle.regNumber}" permanently? Past job cards and '
          'invoices for this vehicle will keep their records but show '
          '"Unknown vehicle".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final ok = await store.deleteVehicle(vehicle.id);
    if (!mounted) return;
    if (!ok) {
      showAppSnackBar(context, store.lastError ?? 'Could not delete vehicle');
      return;
    }
    showAppSnackBar(context, 'Vehicle deleted', backgroundColor: AppColors.success);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GarageStore>();
    if (store.customers.isEmpty) {
      selectedCustomerId = null;
      if (partySearch.text.isNotEmpty) {
        partySearch.clear();
      }
    } else if (selectedCustomerId != null &&
        !store.customers.any((customer) => customer.id == selectedCustomerId)) {
      selectedCustomerId = null;
      partySearch.clear();
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Party',
            subtitle: 'New customer? Add name & mobile, then add their vehicle',
            icon: Icons.people_rounded,
            trailing: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const PartiesListPage(),
                  ),
                );
              },
              icon: const Icon(Icons.table_rows_rounded, size: 18),
              label: const Text('View All Parties'),
            ),
          ),
          SectionCard(
            title: 'Step 1 — Add Customer',
            icon: Icons.person_add_rounded,
            subtitle: 'Owner name, 10-digit mobile, and address',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppFormRow(
                  children: [
                    AppTextField(
                      controller: customerName,
                      label: 'Name *',
                      icon: Icons.person,
                      expand: true,
                    ),
                    AppTextField(
                      controller: mobile,
                      label: 'Mobile *',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      expand: true,
                      hint: '10-digit number',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: address,
                  label: 'Address *',
                  icon: Icons.location_on_outlined,
                  expand: true,
                ),
                AppFormActions(
                  primary: FilledButton.icon(
                    onPressed: () => _addParty(store),
                    icon: const Icon(Icons.person_add_rounded, size: 20),
                    label: const Text('Add Party'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Step 2 — Add Vehicle',
            icon: Icons.directions_car_rounded,
            subtitle: 'Select customer above, then enter vehicle details',
            child: store.customers.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.textMuted),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Add a party first, then you can register their vehicle here.',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
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
                      const SizedBox(height: 12),
                      AppFormRow(
                        children: [
                          AppTextField(
                            controller: regNumber,
                            label: 'Vehicle Number *',
                            expand: true,
                            textCapitalization: TextCapitalization.characters,
                            hint: 'e.g. KL60K3139',
                          ),
                          AppTextField(
                            controller: brand,
                            label: 'Brand *',
                            expand: true,
                            hint: 'e.g. MARUTI',
                          ),
                          AppTextField(
                            controller: model,
                            label: 'Model *',
                            expand: true,
                            hint: 'e.g. DZIRE',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: year,
                        label: 'Year *',
                        expand: true,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        hint: 'e.g. 2016',
                      ),
                      AppFormActions(
                        primary: FilledButton.icon(
                          onPressed: selectedCustomerId == null
                              ? null
                              : () => _addVehicle(store),
                          icon: const Icon(Icons.directions_car_rounded, size: 20),
                          label: const Text('Add Vehicle'),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Existing Parties & Vehicles',
            icon: Icons.folder_open_rounded,
            child: Column(
              children: store.customers.map(
                (customer) {
                  final vehicles = store.vehicles
                      .where((vehicle) => vehicle.customerId == customer.id)
                      .toList();
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              customer.name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Edit party',
                            onPressed: () => _showEditCustomerDialog(store, customer),
                            icon: const Icon(Icons.edit_outlined, size: 20),
                          ),
                          IconButton(
                            tooltip: 'Delete party',
                            onPressed: () => _confirmDeleteCustomer(store, customer),
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 20,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(customer.mobile),
                      children: vehicles
                          .map(
                            (vehicle) => ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                child: const Icon(Icons.directions_car, size: 20, color: AppColors.primary),
                              ),
                              title: Text(vehicle.regNumber),
                              subtitle: Text('${vehicle.brand} ${vehicle.model}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Chip(
                                    label: Text('KM ${vehicle.lastKmReading}'),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  IconButton(
                                    tooltip: 'Edit vehicle',
                                    onPressed: () => _showEditVehicleDialog(store, vehicle),
                                    icon: const Icon(Icons.edit_outlined, size: 20),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete vehicle',
                                    onPressed: () => _confirmDeleteVehicle(store, vehicle),
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 20,
                                      color: AppColors.warning,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  );
                },
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class VehicleHistoryPage extends StatefulWidget {
  const VehicleHistoryPage({super.key, this.preSelectedVehicle});

  final Vehicle? preSelectedVehicle;

  @override
  State<VehicleHistoryPage> createState() => _VehicleHistoryPageState();
}

class _VehicleHistoryPageState extends State<VehicleHistoryPage> {
  final searchController = TextEditingController();
  Vehicle? selectedVehicle;

  @override
  void initState() {
    super.initState();
    _applyPreselectedVehicle(widget.preSelectedVehicle);
  }

  @override
  void didUpdateWidget(covariant VehicleHistoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.preSelectedVehicle?.id != oldWidget.preSelectedVehicle?.id) {
      _applyPreselectedVehicle(widget.preSelectedVehicle);
    }
  }

  void _applyPreselectedVehicle(Vehicle? vehicle) {
    selectedVehicle = vehicle;
    if (vehicle != null) {
      searchController.text = vehicle.regNumber;
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _selectVehicle(Vehicle vehicle) {
    setState(() {
      selectedVehicle = vehicle;
      searchController.text = vehicle.regNumber;
    });
  }

  Widget _historyLineItem({
    required String title,
    String? subtitle,
    required String amount,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(GarageStore store, Invoice invoice) {
    final jobCard = invoice.jobCardId == null
        ? null
        : store.jobCards
            .where((item) => item.id == invoice.jobCardId)
            .firstOrNull;
    final isPaid = invoice.paymentStatus == PaymentStatus.paid;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invoice #${invoice.invoiceNumber}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM yyyy').format(invoice.createdAt),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      if (invoice.kmReading > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          'KM: ${invoice.kmReading}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        '${invoice.paymentStatus.label} · '
                        'Paid ${formatAmount(invoice.amountPaid)} · '
                        'Balance ${formatAmount(invoice.balanceAmount)}',
                        style: TextStyle(
                          color: isPaid ? AppColors.success : AppColors.warning,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatAmount(invoice.grandTotal),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final saved = await InvoiceEditorDialog.show(
                              context,
                              invoice: invoice,
                            );
                            if (!context.mounted || saved != true) {
                              return;
                            }
                            showAppSnackBar(
                              context,
                              'Invoice #${invoice.invoiceNumber} updated',
                              backgroundColor: AppColors.success,
                            );
                          },
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Edit'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await Printing.layoutPdf(
                              onLayout: (format) => buildInvoicePdf(
                                invoice: invoice,
                                store: store,
                                format: format,
                              ),
                            );
                          },
                          icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                          label: const Text('Print'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            if (jobCard != null &&
                (jobCard.customerComplaints.isNotEmpty ||
                    jobCard.mechanicName.isNotEmpty)) ...[
              const Divider(height: 24),
              const Text(
                'Job details',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              if (jobCard.mechanicName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Mechanic: ${jobCard.mechanicName}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              if (jobCard.customerComplaints.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Complaint: ${jobCard.customerComplaints}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                ),
            ],
            if (invoice.labourItems.isNotEmpty) ...[
              const Divider(height: 24),
              const Text(
                'Labour / works done',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              ...invoice.labourItems.map(
                (line) => _historyLineItem(
                  title: line.description,
                  amount: formatAmount(line.amount),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Labour total: ${formatAmount(invoice.labourTotal)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
            if (invoice.partsItems.isNotEmpty) ...[
              const Divider(height: 24),
              const Text(
                'Parts used',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              ...invoice.partsItems.map(
                (line) => _historyLineItem(
                  title: line.name,
                  subtitle: 'Qty ${line.qty} × ${formatAmount(line.unitPrice)}',
                  amount: formatAmount(line.amount),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Parts total: ${formatAmount(invoice.partsTotal)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GarageStore>();
    final invoices = selectedVehicle == null
        ? const <Invoice>[]
        : store.invoicesByVehicle(selectedVehicle!.id);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Vehicle History',
            subtitle: 'Past bills and work done for a vehicle',
            icon: Icons.history_rounded,
          ),
          VehicleSearchField(
            controller: searchController,
            expand: true,
            width: 420,
            optionsBuilder: store.searchVehicles,
            customerName: store.customerName,
            customerMobile: store.customerMobile,
            onSelected: _selectVehicle,
          ),
          const SizedBox(height: 16),
          if (selectedVehicle == null)
            const SectionCard(
              title: 'Select a vehicle',
              icon: Icons.directions_car_outlined,
              child: Text(
                'Search by vehicle number, mobile, or customer name above.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            )
          else ...[
            SectionCard(
              title:
                  '${selectedVehicle!.regNumber} · ${selectedVehicle!.brand} ${selectedVehicle!.model}',
              icon: Icons.directions_car_filled_rounded,
              subtitle:
                  '${store.customerName(selectedVehicle!.customerId)} · '
                  '${store.customerMobile(selectedVehicle!.customerId)}',
              child: invoices.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No invoices yet for this vehicle.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '${invoices.length} invoice${invoices.length == 1 ? '' : 's'} · newest first',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...invoices.map(
                          (invoice) => _buildInvoiceCard(store, invoice),
                        ),
                      ],
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class LabourPage extends StatefulWidget {
  const LabourPage({super.key});

  @override
  State<LabourPage> createState() => _LabourPageState();
}

class _LabourPageState extends State<LabourPage> {
  final name = TextEditingController();
  final defaultRate = TextEditingController();

  @override
  void dispose() {
    name.dispose();
    defaultRate.dispose();
    super.dispose();
  }

  Future<void> _showEditLabourDialog(GarageStore store, LabourItem item) async {
    final editName = TextEditingController(text: item.name);
    final editRate =
        TextEditingController(text: item.defaultRate.toStringAsFixed(0));

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Labour Work'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(controller: editName, label: 'Work Name *', expand: true),
              const SizedBox(height: 12),
              AppTextField(
                controller: editRate,
                label: 'Default Rate (₹) *',
                expand: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved != true) {
      editName.dispose();
      editRate.dispose();
      return;
    }

    final nameError = FormValidators.requiredText(editName.text, 'Work name');
    final rateValue = double.tryParse(editRate.text.trim());
    final error = nameError ??
        (rateValue == null || rateValue < 0
            ? 'Default rate must be a valid number'
            : null);

    final trimmedName = editName.text.trim();
    editName.dispose();
    editRate.dispose();

    if (error != null) {
      if (mounted) {
        showAppSnackBar(context, error);
      }
      return;
    }

    final ok = await store.updateLabourItem(
      item.copyWith(name: trimmedName, defaultRate: rateValue!),
    );

    if (!mounted) return;
    if (!ok) {
      showAppSnackBar(context, store.lastError ?? 'Could not update labour work');
      return;
    }
    showAppSnackBar(
      context,
      'Labour work updated',
      backgroundColor: AppColors.success,
    );
  }

  Future<void> _confirmDeleteLabour(GarageStore store, LabourItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete labour work?'),
        content: Text('Remove "${item.name}" from the labour catalog?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final ok = await store.deleteLabourItem(item.id);
    if (!mounted) return;
    if (!ok) {
      showAppSnackBar(context, store.lastError ?? 'Could not delete labour work');
      return;
    }
    showAppSnackBar(
      context,
      'Labour work deleted',
      backgroundColor: AppColors.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GarageStore>();
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Labour Works',
            subtitle: 'Common jobs used when building estimates',
            icon: Icons.handyman_rounded,
          ),
          SectionCard(
            title: 'Add Labour Work',
            icon: Icons.add_box_rounded,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                AppTextField(
                  controller: name,
                  label: 'Work Name',
                  hint: 'e.g. Painting, Welding',
                ),
                AppTextField(
                  controller: defaultRate,
                  label: 'Default Rate (₹)',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                FilledButton(
                  onPressed: () async {
                    final nameError =
                        FormValidators.requiredText(name.text, 'Work name');
                    final rate = double.tryParse(defaultRate.text.trim());
                    if (nameError != null) {
                      showAppSnackBar(context, nameError);
                      return;
                    }
                    if (rate == null || rate < 0) {
                      showAppSnackBar(context, 'Enter a valid default rate');
                      return;
                    }
                    final item = await store.addLabourItem(
                      name: name.text.trim(),
                      defaultRate: rate,
                    );
                    if (!context.mounted) return;
                    if (item == null) {
                      showAppSnackBar(
                        context,
                        store.lastError ?? 'Could not add labour work',
                      );
                      return;
                    }
                    name.clear();
                    defaultRate.clear();
                    showAppSnackBar(
                      context,
                      'Labour work added',
                      backgroundColor: AppColors.success,
                    );
                  },
                  child: const Text('Add Work'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Labour Catalog',
            icon: Icons.list_alt_rounded,
            child: store.labourItems.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No labour works yet. Add painting, welding, service, etc.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                : Column(
                    children: store.labourItems.map((item) {
                      return DataListTile(
                        title: item.name,
                        subtitle: 'Default rate for estimates',
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              formatAmount(item.defaultRate),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Edit',
                              onPressed: () => _showEditLabourDialog(store, item),
                              icon: const Icon(Icons.edit_outlined, size: 20),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              onPressed: () => _confirmDeleteLabour(store, item),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  final name = TextEditingController();
  final sku = TextEditingController();
  final price = TextEditingController();
  final stock = TextEditingController();
  final minStock = TextEditingController();

  @override
  void dispose() {
    name.dispose();
    sku.dispose();
    price.dispose();
    stock.dispose();
    minStock.dispose();
    super.dispose();
  }

  Future<void> _showEditStockDialog(GarageStore store, StockItem item) async {
    final editName = TextEditingController(text: item.name);
    final editSku = TextEditingController(text: item.sku);
    final editPrice = TextEditingController(text: item.sellingPrice.toString());
    final editStock = TextEditingController(text: item.currentStock.toString());
    final editMinStock =
        TextEditingController(text: item.minStockAlert.toString());

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Stock Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(controller: editName, label: 'Item Name *', expand: true),
              const SizedBox(height: 12),
              AppTextField(controller: editSku, label: 'SKU', expand: true),
              const SizedBox(height: 12),
              AppTextField(
                controller: editPrice,
                label: 'Selling Price *',
                expand: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: editStock,
                label: 'Current Stock *',
                expand: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: editMinStock,
                label: 'Min Alert *',
                expand: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved != true) {
      editName.dispose();
      editSku.dispose();
      editPrice.dispose();
      editStock.dispose();
      editMinStock.dispose();
      return;
    }

    final nameError = FormValidators.requiredText(editName.text, 'Item name');
    final priceValue = double.tryParse(editPrice.text.trim());
    final stockValue = int.tryParse(editStock.text.trim());
    final minValue = int.tryParse(editMinStock.text.trim());
    final error = nameError ??
        (priceValue == null || priceValue < 0
            ? 'Selling price must be a valid number'
            : null) ??
        (stockValue == null || stockValue < 0
            ? 'Current stock must be a valid number'
            : null) ??
        (minValue == null || minValue < 0
            ? 'Min alert must be a valid number'
            : null);

    if (error != null) {
      editName.dispose();
      editSku.dispose();
      editPrice.dispose();
      editStock.dispose();
      editMinStock.dispose();
      if (mounted) {
        showAppSnackBar(context, error);
      }
      return;
    }

    final ok = await store.updateStockItem(
      item.copyWith(
        name: editName.text.trim(),
        sku: editSku.text.trim(),
        sellingPrice: priceValue!,
        currentStock: stockValue!,
        minStockAlert: minValue!,
      ),
    );

    editName.dispose();
    editSku.dispose();
    editPrice.dispose();
    editStock.dispose();
    editMinStock.dispose();

    if (!mounted) return;
    if (!ok) {
      showAppSnackBar(context, store.lastError ?? 'Could not update item');
      return;
    }
    showAppSnackBar(
      context,
      'Stock item updated',
      backgroundColor: AppColors.success,
    );
  }

  Future<void> _confirmDeleteStock(GarageStore store, StockItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete stock item?'),
        content: Text(
          'Remove "${item.name}" from inventory?\n\n'
          'Past invoices that used this part will keep their records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final ok = await store.deleteStockItem(item.id);
    if (!mounted) return;
    if (!ok) {
      showAppSnackBar(context, store.lastError ?? 'Could not delete item');
      return;
    }
    showAppSnackBar(
      context,
      'Stock item deleted',
      backgroundColor: AppColors.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GarageStore>();
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Stock Management',
            subtitle: 'Parts inventory and low-stock alerts',
            icon: Icons.inventory_2_rounded,
          ),
          SectionCard(
            title: 'Add Stock Item',
            icon: Icons.add_box_rounded,
            child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  AppTextField(controller: name, label: 'Item Name'),
                  AppTextField(controller: sku, label: 'SKU'),
                  AppTextField(controller: price, label: 'Selling Price'),
                  AppTextField(controller: stock, label: 'Current Stock'),
                  AppTextField(controller: minStock, label: 'Min Alert'),
                  FilledButton(
                    onPressed: () async {
                      if (name.text.trim().isEmpty) {
                        return;
                      }
                      await store.addStockItem(
                        name: name.text.trim(),
                        sku: sku.text.trim(),
                        price: double.tryParse(price.text.trim()) ?? 0,
                        currentStock: int.tryParse(stock.text.trim()) ?? 0,
                        minStockAlert: int.tryParse(minStock.text.trim()) ?? 0,
                      );
                      name.clear();
                      sku.clear();
                      price.clear();
                      stock.clear();
                      minStock.clear();
                    },
                    child: const Text('Add Item'),
                  ),
                ],
              ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Inventory',
            icon: Icons.warehouse_rounded,
            child: Column(
              children: store.stockItems.map(
                (item) {
                  final low = item.currentStock <= item.minStockAlert;
                  return DataListTile(
                    title: '${item.name} (${item.sku})',
                    subtitle: 'Stock: ${item.currentStock} · Min: ${item.minStockAlert}',
                    leading: CircleAvatar(
                      backgroundColor: (low ? AppColors.warning : AppColors.success)
                          .withValues(alpha: 0.12),
                      child: Icon(
                        low ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                        color: low ? AppColors.warning : AppColors.success,
                        size: 22,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatAmount(item.sellingPrice),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Edit',
                          onPressed: () => _showEditStockDialog(store, item),
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          onPressed: () => _confirmDeleteStock(store, item),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({super.key});

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> {
  final search = TextEditingController();
  PaymentStatus? statusFilter;

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  List<Invoice> _filteredInvoices(GarageStore store) {
    final query = search.text.trim().toLowerCase();
    var invoices = List<Invoice>.from(store.invoices)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final filter = statusFilter;
    if (filter != null) {
      invoices = invoices.where((invoice) => invoice.paymentStatus == filter).toList();
    }

    if (query.isEmpty) {
      return invoices;
    }

    return invoices.where((invoice) {
      return invoice.vehicleNumber.toLowerCase().contains(query) ||
          invoice.invoiceNumber.toString().contains(query) ||
          store.customerName(invoice.customerId).toLowerCase().contains(query) ||
          invoice.paymentStatus.label.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _editInvoice(
    BuildContext context,
    GarageStore store,
    Invoice invoice,
  ) async {
    final saved = await InvoiceEditorDialog.show(context, invoice: invoice);
    if (!context.mounted) {
      return;
    }
    if (saved == true) {
      showAppSnackBar(
        context,
        'Invoice #${invoice.invoiceNumber} updated',
        backgroundColor: AppColors.success,
      );
    }
  }

  Future<void> _recordPayment(GarageStore store, Invoice invoice) async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final history = store.paymentsForInvoice(invoice.id);
          return AlertDialog(
            title: Text('Record Payment · Invoice #${invoice.invoiceNumber}'),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Bill total: ${formatAmount(invoice.grandTotal)} · '
                      'Paid so far: ${formatAmount(invoice.amountPaid)} · '
                      'Balance: ${formatAmount(invoice.balanceAmount)}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                    if (store.customerAdvanceBalance(invoice.customerId) > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Advance on account: '
                        '${formatAmount(store.customerAdvanceBalance(invoice.customerId))}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: amountController,
                      label: 'Amount received now (₹) *',
                      expand: true,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      hint: 'e.g. 10000',
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: noteController,
                      label: 'Note (optional)',
                      expand: true,
                      hint: 'Cash / UPI',
                    ),
                    if (history.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Payment history',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...history.map(
                        (payment) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${DateFormat('dd MMM yyyy').format(payment.createdAt)}'
                                  '${payment.note.isNotEmpty ? ' · ${payment.note}' : ''}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              Text(
                                formatAmount(payment.amount),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Save Payment'),
              ),
            ],
          );
        },
      ),
    );

    if (saved != true) {
      amountController.dispose();
      noteController.dispose();
      return;
    }

    final amount = double.tryParse(amountController.text.trim()) ?? 0;
    final note = noteController.text.trim();
    amountController.dispose();
    noteController.dispose();
    if (amount <= 0) {
      showAppSnackBar(context, 'Enter a valid amount');
      return;
    }

    final error = await store.recordPaymentReceipt(
      customerId: invoice.customerId,
      invoiceId: invoice.id,
      amount: amount,
      note: note,
    );

    if (!mounted) return;
    if (error != null) {
      showAppSnackBar(context, error);
      return;
    }
    showAppSnackBar(
      context,
      'Payment of ${formatAmount(amount)} recorded',
      backgroundColor: AppColors.success,
    );
  }

  Future<void> _applyAdvancesToInvoice(
    GarageStore store,
    Invoice invoice,
  ) async {
    final advances = store.advancesForCustomer(invoice.customerId);
    if (advances.isEmpty) {
      showAppSnackBar(context, 'No advance on account for this customer');
      return;
    }

    for (final advance in advances) {
      final current = store.invoices
          .where((item) => item.id == invoice.id)
          .firstOrNull;
      if (current == null || current.balanceAmount <= 0) {
        break;
      }
      final error = await store.applyAdvanceToInvoice(
        paymentId: advance.id,
        invoiceId: invoice.id,
      );
      if (error != null) {
        if (!mounted) return;
        showAppSnackBar(context, error);
        return;
      }
    }

    if (!mounted) return;
    showAppSnackBar(
      context,
      'Advance applied to invoice #${invoice.invoiceNumber}',
      backgroundColor: AppColors.success,
    );
  }

  Future<void> _markInvoiceFullyPaid(GarageStore store, Invoice invoice) async {
    if (invoice.paymentStatus == PaymentStatus.paid) {
      return;
    }
    final balance = invoice.balanceAmount;
    if (balance <= 0) {
      return;
    }
    final error = await store.recordPaymentReceipt(
      customerId: invoice.customerId,
      invoiceId: invoice.id,
      amount: balance,
      note: 'Marked fully paid',
    );
    if (!mounted) return;
    if (error != null) {
      showAppSnackBar(context, error);
      return;
    }
    showAppSnackBar(
      context,
      'Invoice #${invoice.invoiceNumber} marked as Paid',
      backgroundColor: AppColors.success,
    );
  }

  Widget _statusFilterChip({
    required String label,
    required PaymentStatus? value,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: statusFilter == value,
      onSelected: (_) => setState(() => statusFilter = value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GarageStore>();
    final invoices = _filteredInvoices(store);
    final unpaidCount = store.invoices
        .where((invoice) => invoice.paymentStatus == PaymentStatus.unpaid)
        .length;
    final partialCount = store.invoices
        .where((invoice) => invoice.paymentStatus == PaymentStatus.partial)
        .length;
    final paidCount = store.invoices
        .where((invoice) => invoice.paymentStatus == PaymentStatus.paid)
        .length;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Invoices',
            subtitle: 'Bills created from estimates — record payment here',
            icon: Icons.receipt_long_rounded,
          ),
          SectionCard(
            title: 'All Invoices',
            icon: Icons.history_rounded,
            subtitle: unpaidCount + partialCount > 0
                ? '$unpaidCount unpaid · $partialCount partial'
                : '${store.invoices.length} total',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSearchField(
                  controller: search,
                  hint: 'Search vehicle, invoice #, customer, status…',
                  expand: true,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _statusFilterChip(
                      label: 'All (${store.invoices.length})',
                      value: null,
                    ),
                    _statusFilterChip(
                      label: 'Unpaid ($unpaidCount)',
                      value: PaymentStatus.unpaid,
                    ),
                    _statusFilterChip(
                      label: 'Partial ($partialCount)',
                      value: PaymentStatus.partial,
                    ),
                    _statusFilterChip(
                      label: 'Paid ($paidCount)',
                      value: PaymentStatus.paid,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (invoices.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No invoices yet. Convert an estimate to create one.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                else
                  ...invoices.map((invoice) {
                    final isPaid = invoice.paymentStatus == PaymentStatus.paid;
                    final advanceBalance =
                        store.customerAdvanceBalance(invoice.customerId);
                    final paymentHistory = store.paymentsForInvoice(invoice.id);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '#${invoice.invoiceNumber} · ${invoice.vehicleNumber}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${store.customerName(invoice.customerId)} · '
                                        '${DateFormat('dd MMM yyyy').format(invoice.createdAt)}',
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${invoice.paymentStatus.label} · '
                                        'Balance ${formatAmount(invoice.balanceAmount)}',
                                        style: TextStyle(
                                          color: isPaid
                                              ? AppColors.success
                                              : AppColors.warning,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  formatAmount(invoice.grandTotal),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            if (paymentHistory.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Payments: ${paymentHistory.map((p) => formatAmount(p.amount)).join(', ')}',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      _editInvoice(context, store, invoice),
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  label: const Text('Edit'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    await Printing.layoutPdf(
                                      onLayout: (format) => buildInvoicePdf(
                                        invoice: invoice,
                                        store: store,
                                        format: format,
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.picture_as_pdf_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('Print'),
                                ),
                                if (!isPaid) ...[
                                  if (advanceBalance > 0)
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          _applyAdvancesToInvoice(store, invoice),
                                      icon: const Icon(Icons.savings_outlined, size: 18),
                                      label: Text(
                                        'Apply Advance (${formatAmount(advanceBalance)})',
                                      ),
                                    ),
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        _recordPayment(store, invoice),
                                    icon: const Icon(
                                      Icons.account_balance_wallet_outlined,
                                      size: 18,
                                    ),
                                    label: const Text('Record Payment'),
                                  ),
                                  FilledButton.icon(
                                    onPressed: () =>
                                        _markInvoiceFullyPaid(store, invoice),
                                    icon: const Icon(Icons.payments_rounded, size: 18),
                                    label: const Text('Mark Paid'),
                                  ),
                                ],
                              ],
                            ),
                          ],
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

class EstimatesPage extends StatefulWidget {
  const EstimatesPage({super.key, this.onInvoiceCreated});

  /// Called after "Convert to Invoice" succeeds, so the shell can switch the
  /// user straight to the Invoices tab instead of leaving them here.
  final VoidCallback? onInvoiceCreated;

  @override
  State<EstimatesPage> createState() => _EstimatesPageState();
}

class _EstimatesPageState extends State<EstimatesPage> {
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  List<Estimate> _openEstimates(GarageStore store) {
    final query = search.text.trim().toLowerCase();
    final estimates = store.estimates
        .where(
          (estimate) =>
              estimate.status != EstimateStatus.converted &&
              estimate.status != EstimateStatus.rejected,
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (query.isEmpty) {
      return estimates;
    }

    return estimates.where((estimate) {
      return estimate.vehicleNumber.toLowerCase().contains(query) ||
          estimate.estimateNumber.toString().contains(query) ||
          store.customerName(estimate.customerId).toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _editEstimate(
    BuildContext context,
    GarageStore store,
    Estimate estimate,
  ) async {
    final jobCardId = estimate.jobCardId;
    if (jobCardId == null) {
      showAppSnackBar(context, 'This estimate is not linked to a job card');
      return;
    }
    final jobCard =
        store.jobCards.where((item) => item.id == jobCardId).firstOrNull;
    if (jobCard == null) {
      showAppSnackBar(context, 'Job card not found');
      return;
    }
    final saved = await EstimateEditorPage.show(
      context,
      jobCard: jobCard,
      existingEstimate: estimate,
    );
    if (saved == true && context.mounted) {
      showAppSnackBar(
        context,
        'Estimate updated',
        backgroundColor: AppColors.success,
      );
    }
  }

  Future<void> _convertToInvoice(
    BuildContext context,
    GarageStore store,
    Estimate estimate,
  ) async {
    final error = await store.convertEstimateToInvoice(estimate.id);
    if (!context.mounted) {
      return;
    }
    if (error != null) {
      showAppSnackBar(context, error);
      return;
    }
    if (estimate.jobCardId != null) {
      await store.updateJobCardStatus(estimate.jobCardId!, JobStatus.delivered);
    }
    if (!context.mounted) {
      return;
    }
    showAppSnackBar(
      context,
      'Invoice created',
      backgroundColor: AppColors.success,
    );
    widget.onInvoiceCreated?.call();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GarageStore>();
    final openEstimates = _openEstimates(store);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Estimates',
            subtitle: 'Print, edit, or convert to invoice when customer agrees',
            icon: Icons.request_quote_rounded,
          ),
          SectionCard(
            title: 'Open Estimates',
            icon: Icons.list_alt_rounded,
            subtitle: '${openEstimates.length} waiting',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSearchField(
                  controller: search,
                  hint: 'Search vehicle, estimate #, or customer…',
                  expand: true,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                if (openEstimates.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No open estimates. Create one from Job Cards.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                else
                  ...openEstimates.map((estimate) {
                    final jobCard = estimate.jobCardId == null
                        ? null
                        : store.jobCards
                            .where((item) => item.id == estimate.jobCardId)
                            .firstOrNull;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '#${estimate.estimateNumber} · ${estimate.vehicleNumber}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${store.customerName(estimate.customerId)} · '
                                        '${DateFormat('dd MMM yyyy').format(estimate.createdAt)}',
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 13,
                                        ),
                                      ),
                                      if (jobCard != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Job #${jobCard.jobCardNumber} · ${jobCard.status.label}',
                                          style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Text(
                                  formatAmount(estimate.grandTotal),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (estimate.jobCardId != null)
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        _editEstimate(context, store, estimate),
                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                    label: const Text('Edit'),
                                  ),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    await Printing.layoutPdf(
                                      onLayout: (format) => buildEstimatePdf(
                                        estimate: estimate,
                                        store: store,
                                        format: format,
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.picture_as_pdf_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('Print'),
                                ),
                                FilledButton.icon(
                                  onPressed: () =>
                                      _convertToInvoice(context, store, estimate),
                                  icon: const Icon(
                                    Icons.receipt_long_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('Convert to Invoice'),
                                ),
                              ],
                            ),
                          ],
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
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController businessName;
  late final TextEditingController tagline;
  late final TextEditingController address;
  late final TextEditingController phone;
  late final TextEditingController invoicePrefix;
  late final TextEditingController startInvoiceNumber;
  late final TextEditingController startJobCardNumber;
  late final TextEditingController startEstimateNumber;

  @override
  void initState() {
    super.initState();
    final settings = context.read<GarageStore>().settings;
    businessName = TextEditingController(text: settings.businessName);
    tagline = TextEditingController(text: settings.tagline);
    address = TextEditingController(text: settings.address);
    phone = TextEditingController(text: settings.phone);
    invoicePrefix = TextEditingController(text: settings.invoicePrefix);
    startInvoiceNumber =
        TextEditingController(text: settings.nextInvoiceNumber.toString());
    startJobCardNumber =
        TextEditingController(text: settings.nextJobCardNumber.toString());
    startEstimateNumber =
        TextEditingController(text: settings.nextEstimateNumber.toString());
  }

  Future<void> _confirmAndClearBrowserCache() async {
    if (!isBrowserCacheClearSupported) {
      showAppSnackBar(
        context,
        'Cache clear is available on the web app in Chrome/browser only.',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear browser cache?'),
        content: const Text(
          'This clears saved app data in this browser (temporary files, '
          'offline copies) and reloads the page.\n\n'
          'Your garage records in Firebase are safe — only this browser\'s '
          'cached copy is removed.\n\n'
          'Use this if the screen looks stuck or shows old data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Clear & Reload'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await clearBrowserCache();
    } catch (error) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(context, 'Could not clear cache: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GarageStore>();
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Settings',
            subtitle: 'Garage profile and document numbering',
            icon: Icons.settings_rounded,
          ),
          SectionCard(
            title: 'Garage Profile',
            icon: Icons.store_rounded,
            child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AppTextField(controller: businessName, label: 'Business name', width: 240),
                  AppTextField(controller: tagline, label: 'Tagline', width: 240),
                  AppTextField(controller: address, label: 'Address', width: 320),
                  AppTextField(controller: phone, label: 'Phone'),
                  AppTextField(controller: invoicePrefix, label: 'Invoice prefix'),
                  AppTextField(controller: startInvoiceNumber, label: 'Next invoice number'),
                  AppTextField(controller: startJobCardNumber, label: 'Next job card number'),
                  AppTextField(controller: startEstimateNumber, label: 'Next estimate number'),
                  FilledButton(
                    onPressed: () async {
                      await store.updateSettings(
                        businessName: businessName.text.trim(),
                        tagline: tagline.text.trim(),
                        address: address.text.trim(),
                        phone: phone.text.trim(),
                        invoicePrefix: invoicePrefix.text.trim(),
                        nextInvoiceNumber:
                            int.tryParse(startInvoiceNumber.text.trim()) ??
                                store.settings.nextInvoiceNumber,
                        nextJobCardNumber:
                            int.tryParse(startJobCardNumber.text.trim()) ??
                                store.settings.nextJobCardNumber,
                        nextEstimateNumber:
                            int.tryParse(startEstimateNumber.text.trim()) ??
                                store.settings.nextEstimateNumber,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Settings updated'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                    child: const Text('Save Settings'),
                  ),
                ],
              ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Browser Cache',
            icon: Icons.cleaning_services_rounded,
            subtitle: 'If the app looks stuck or shows old data',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'No need to open browser settings. Tap below to clear this '
                  'browser\'s saved app cache and reload fresh.',
                  style: TextStyle(color: AppColors.textMuted, height: 1.45),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _confirmAndClearBrowserCache,
                  icon: const Icon(Icons.cached_rounded, size: 20),
                  label: const Text('Clear Browser Cache & Reload'),
                ),
              ],
            ),
          ),
          if (FirebaseBootstrap.isConfigured) ...[
            const SizedBox(height: 16),
            SectionCard(
              title: 'Account',
              icon: Icons.account_circle_rounded,
              subtitle: 'Signed in on this device',
              child: OutlinedButton.icon(
                onPressed: () => confirmLogout(context),
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text('Log out'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
