import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:garage_management_system/src/pages/help_page.dart';
import 'package:garage_management_system/src/models/garage_models.dart';
import 'package:garage_management_system/src/store/garage_store.dart';
import 'package:garage_management_system/src/theme/app_theme.dart';
import 'package:garage_management_system/src/utils/garage_utils.dart';
import 'package:garage_management_system/src/widgets/ui_components.dart';
import 'package:garage_management_system/src/widgets/responsive.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

enum AppSection {
  dashboard,
  parties,
  history,
  stock,
  jobCards,
  estimates,
  invoices,
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
    (AppSection.parties, Icons.people_rounded, 'Party'),
    (AppSection.history, Icons.history_rounded, 'History'),
    (AppSection.stock, Icons.inventory_2_rounded, 'Stock'),
    (AppSection.jobCards, Icons.build_circle_rounded, 'Job Cards'),
    (AppSection.estimates, Icons.request_quote_rounded, 'Estimates'),
    (AppSection.invoices, Icons.receipt_long_rounded, 'Invoices'),
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

  Widget _buildSearchChips(List<Vehicle> searchResults) {
    if (globalSearchController.text.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppBreakpoints.isMobile(context) ? 12 : 28,
        12,
        AppBreakpoints.isMobile(context) ? 12 : 28,
        0,
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: searchResults
            .map(
              (vehicle) => ActionChip(
                avatar: const Icon(Icons.directions_car, size: 18),
                label: Text(vehicle.regNumber),
                onPressed: () {
                  highlightedVehicle = vehicle;
                  globalSearchController.clear();
                  setState(() => section = AppSection.history);
                },
              ),
            )
            .toList(),
      ),
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

  @override
  Widget build(BuildContext context) {
    final pages = <AppSection, Widget>{
      AppSection.dashboard: const DashboardPage(),
      AppSection.parties: const PartiesPage(),
      AppSection.history: const VehicleHistoryPage(),
      AppSection.stock: const StockPage(),
      AppSection.jobCards: const JobCardsPage(),
      AppSection.estimates: const EstimatesPage(),
      AppSection.invoices: const InvoicesPage(),
      AppSection.help: const HelpPage(),
    };
    final store = context.watch<GarageStore>();
    final searchResults =
        store.searchVehicles(globalSearchController.text).take(5).toList();
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
                child: AppSearchField(
                  controller: globalSearchController,
                  onChanged: (_) => setState(() {}),
                  expand: true,
                ),
              ),
              _buildSearchChips(searchResults),
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
                      AppSearchField(
                        controller: globalSearchController,
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),
                _buildSearchChips(searchResults),
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
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final regNumber = TextEditingController();
  final km = TextEditingController();
  final mechanic = TextEditingController();
  final complaints = TextEditingController();
  String fuelLevel = 'Half';
  Vehicle? matchedVehicle;

  @override
  void dispose() {
    regNumber.dispose();
    km.dispose();
    mechanic.dispose();
    complaints.dispose();
    super.dispose();
  }

  void _lookupVehicle(GarageStore store) {
    final vehicle = store.findVehicleByRegNumber(regNumber.text);
    setState(() {
      matchedVehicle = vehicle;
      if (vehicle != null && km.text.trim().isEmpty) {
        km.text = vehicle.lastKmReading.toString();
      }
    });
  }

  Future<void> _createQuickJobCard(GarageStore store) async {
    if (matchedVehicle == null) {
      _lookupVehicle(store);
      if (matchedVehicle == null) {
        showAppSnackBar(
          context,
          'Vehicle not found. Add party and vehicle first.',
        );
        return;
      }
    }

    final vehicle = matchedVehicle!;
    final kmError = FormValidators.positiveKm(km.text);
    final mechanicError = FormValidators.requiredText(mechanic.text, 'Mechanic');
    final complaintError =
        FormValidators.requiredText(complaints.text, 'Complaint');
    final error = kmError ?? mechanicError ?? complaintError;
    if (error != null) {
      showAppSnackBar(context, error);
      return;
    }

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
      mechanicName: mechanic.text.trim(),
    );

    if (!mounted) return;
    if (card == null) {
      showAppSnackBar(context, store.lastError ?? 'Could not create job card');
      return;
    }

    complaints.clear();
    mechanic.clear();
    showAppSnackBar(
      context,
      'Job card #${card.jobCardNumber} created',
      backgroundColor: AppColors.success,
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
          const PageHeader(
            title: 'Operations Overview',
            subtitle: 'Daily sales, workshop load, and payment status',
            icon: Icons.dashboard_rounded,
          ),
          SectionCard(
            title: 'Quick Job Card',
            icon: Icons.build_circle_rounded,
            subtitle: 'Enter vehicle number and open a job card immediately',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppFormRow(
                  children: [
                    AppTextField(
                      controller: regNumber,
                      label: 'Vehicle Number *',
                      expand: true,
                      textCapitalization: TextCapitalization.characters,
                      hint: 'e.g. KL60K3139',
                      onChanged: (_) => _lookupVehicle(store),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => _lookupVehicle(store),
                      icon: const Icon(Icons.search_rounded, size: 20),
                      label: const Text('Find'),
                    ),
                  ],
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
                    'Vehicle not found. Register the party and vehicle under Party first.',
                    style: TextStyle(color: AppColors.warning, fontSize: 13),
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
              ),
              MetricCard(
                label: 'Vehicles In Service',
                value: '${store.activeJobCards}',
                icon: Icons.car_repair_rounded,
              ),
              MetricCard(
                label: 'Low Stock Alerts',
                value: '${store.lowStockItems.length}',
                icon: Icons.warning_amber_rounded,
                accentColor: store.lowStockItems.isEmpty
                    ? AppColors.success
                    : AppColors.warning,
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
  final regNumber = TextEditingController();
  final brand = TextEditingController();
  final model = TextEditingController();
  final year = TextEditingController();
  final km = TextEditingController();

  @override
  void dispose() {
    customerName.dispose();
    mobile.dispose();
    address.dispose();
    regNumber.dispose();
    brand.dispose();
    model.dispose();
    year.dispose();
    km.dispose();
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
    await store.addCustomer(
      name: customerName.text.trim(),
      mobile: normalizeMobile(mobile.text),
      address: address.text.trim(),
    );
    customerName.clear();
    mobile.clear();
    address.clear();
    if (context.mounted) {
      showAppSnackBar(
        context,
        'Party added',
        backgroundColor: AppColors.success,
      );
    }
  }

  Future<void> _addVehicle(GarageStore store) async {
    final regError = FormValidators.vehicleNumber(regNumber.text);
    final brandError = FormValidators.requiredText(brand.text, 'Brand');
    final modelError = FormValidators.requiredText(model.text, 'Model');
    final yearError = FormValidators.vehicleYear(year.text);
    final kmError = FormValidators.positiveKm(km.text);
    final error = regError ?? brandError ?? modelError ?? yearError ?? kmError;
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
      lastKm: int.parse(km.text.trim()),
    );
    regNumber.clear();
    brand.clear();
    model.clear();
    year.clear();
    km.clear();
    if (context.mounted) {
      showAppSnackBar(
        context,
        'Vehicle added',
        backgroundColor: AppColors.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GarageStore>();
    if (store.customers.isEmpty) {
      selectedCustomerId = null;
    } else if (selectedCustomerId == null ||
        !store.customers.any((customer) => customer.id == selectedCustomerId)) {
      selectedCustomerId = store.customers.first.id;
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Party Management',
            subtitle: 'Customers and linked vehicles',
            icon: Icons.people_rounded,
          ),
          SectionCard(
            title: 'Add Party',
            icon: Icons.person_add_rounded,
            subtitle: 'Customer name, mobile, and address',
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
            title: 'Add Vehicle',
            icon: Icons.directions_car_rounded,
            subtitle: 'Link a vehicle to an existing party',
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
                      AppDropdownField<String>(
                        label: 'Party *',
                        icon: Icons.person_outline,
                        value: selectedCustomerId,
                        hint: 'Select party',
                        items: store.customers
                            .map(
                              (customer) => DropdownMenuItem(
                                value: customer.id,
                                child: Text(
                                  '${customer.name} · ${customer.mobile}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() {
                          selectedCustomerId = value;
                        }),
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
                      AppFormRow(
                        children: [
                          AppTextField(
                            controller: year,
                            label: 'Year *',
                            expand: true,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            hint: 'e.g. 2016',
                          ),
                          AppTextField(
                            controller: km,
                            label: 'KM Reading *',
                            expand: true,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            hint: 'Current odometer',
                          ),
                        ],
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
                      title: Text(
                        customer.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
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
                              trailing: Chip(
                                label: Text('KM ${vehicle.lastKmReading}'),
                                visualDensity: VisualDensity.compact,
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
    selectedVehicle = widget.preSelectedVehicle;
    if (selectedVehicle != null) {
      searchController.text = selectedVehicle!.regNumber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GarageStore>();
    final results = store.searchVehicles(searchController.text);
    final invoices = selectedVehicle == null
        ? const <Invoice>[]
        : store.invoicesByVehicle(selectedVehicle!.id);
    final estimates = selectedVehicle == null
        ? const <Estimate>[]
        : store.estimatesByVehicle(selectedVehicle!.id);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Vehicle History',
            subtitle: 'Past services, bills, and KM readings',
            icon: Icons.history_rounded,
          ),
          AppSearchField(
            controller: searchController,
            hint: 'Search by vehicle number / mobile / customer',
            width: 420,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: results
                .take(8)
                .map(
                  (vehicle) => ActionChip(
                    avatar: const Icon(Icons.directions_car, size: 18),
                    label: Text(vehicle.regNumber),
                    onPressed: () => setState(() => selectedVehicle = vehicle),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          if (selectedVehicle != null)
            SectionCard(
              title: '${selectedVehicle!.regNumber} · ${selectedVehicle!.brand} ${selectedVehicle!.model}',
              icon: Icons.directions_car_filled_rounded,
              child: Column(
                children: [
                  if (invoices.isEmpty && estimates.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'No history found for this vehicle yet.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  if (estimates.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Estimates',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    ...estimates.map(
                      (estimate) => DataListTile(
                        title: 'Estimate #${estimate.estimateNumber}',
                        subtitle:
                            '${estimate.status.label} · ${DateFormat('dd-MM-yyyy').format(estimate.createdAt)}',
                        trailing: Text(
                          formatAmount(estimate.grandTotal),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (invoices.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Invoices',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    ...invoices.map(
                      (invoice) => DataListTile(
                        title: 'Invoice #${invoice.invoiceNumber}',
                        subtitle:
                            'Date: ${DateFormat('dd-MM-yyyy').format(invoice.createdAt)} · KM: ${invoice.kmReading}',
                        trailing: Text(
                          formatAmount(invoice.grandTotal),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
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

class JobCardsPage extends StatefulWidget {
  const JobCardsPage({super.key});

  @override
  State<JobCardsPage> createState() => _JobCardsPageState();
}

class _JobCardsPageState extends State<JobCardsPage> {
  String? customerId;
  String? vehicleId;
  String fuelLevel = 'Half';
  final km = TextEditingController();
  final customerVoice = TextEditingController();
  final observations = TextEditingController();
  final requestedWorks = TextEditingController();
  final otherNotes = TextEditingController();
  final internalNotes = TextEditingController();
  final mechanic = TextEditingController();
  final complaintLineInput = TextEditingController();
  final deliveryDate = TextEditingController();
  final deliveryTime = TextEditingController();
  final complaintItems = <String>[];

  @override
  void dispose() {
    km.dispose();
    customerVoice.dispose();
    observations.dispose();
    requestedWorks.dispose();
    otherNotes.dispose();
    internalNotes.dispose();
    mechanic.dispose();
    complaintLineInput.dispose();
    deliveryDate.dispose();
    deliveryTime.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GarageStore>();
    customerId ??= store.customers.isNotEmpty ? store.customers.first.id : null;
    final customerVehicles = store.vehicles
        .where((vehicle) => vehicle.customerId == customerId)
        .toList();
    if (vehicleId == null && customerVehicles.isNotEmpty) {
      vehicleId = customerVehicles.first.id;
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Job Cards',
            subtitle: 'Track complaints, mechanics, and service status',
            icon: Icons.build_circle_rounded,
          ),
          SectionCard(
            title: 'New Job Card',
            icon: Icons.note_add_rounded,
            subtitle: 'Match your paper job card — write full complaints, not one line',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    DropdownButton<String>(
                      value: customerId,
                      hint: const Text('Party'),
                      items: store.customers
                          .map(
                            (customer) => DropdownMenuItem(
                              value: customer.id,
                              child: Text(customer.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() {
                        customerId = value;
                        vehicleId = null;
                      }),
                    ),
                    DropdownButton<String>(
                      value: vehicleId,
                      hint: const Text('Vehicle'),
                      items: customerVehicles
                          .map(
                            (vehicle) => DropdownMenuItem(
                              value: vehicle.id,
                              child: Text(vehicle.regNumber),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() {
                        vehicleId = value;
                      }),
                    ),
                    AppTextField(controller: km, label: 'KM Reading *', width: 140, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                    DropdownButton<String>(
                      value: fuelLevel,
                      items: const [
                        DropdownMenuItem(value: 'Empty', child: Text('Fuel: Empty')),
                        DropdownMenuItem(value: 'Quarter', child: Text('Fuel: 1/4')),
                        DropdownMenuItem(value: 'Half', child: Text('Fuel: 1/2')),
                        DropdownMenuItem(value: 'Three Quarter', child: Text('Fuel: 3/4')),
                        DropdownMenuItem(value: 'Full', child: Text('Fuel: Full')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => fuelLevel = value);
                      },
                    ),
                    AppTextField(controller: mechanic, label: 'Mechanic *', width: 160),
                  ],
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final useColumns = constraints.maxWidth > 900;
                    final customerField = AppMultilineField(
                      controller: customerVoice,
                      label: 'Customer Voice / Complaints',
                      hint:
                          'What the customer reported...\ne.g. Engine noise\nAC not cooling\nBrake sound',
                      minLines: 5,
                      maxLines: 10,
                    );
                    final observationsField = AppMultilineField(
                      controller: observations,
                      label: 'Observations',
                      hint: 'Mechanic findings after inspection...',
                      minLines: 5,
                      maxLines: 10,
                    );
                    final requestedField = AppMultilineField(
                      controller: requestedWorks,
                      label: 'Requested Works',
                      hint: 'Works customer asked for...',
                      minLines: 5,
                      maxLines: 10,
                    );
                    if (useColumns) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: customerField),
                          const SizedBox(width: 12),
                          Expanded(child: observationsField),
                          const SizedBox(width: 12),
                          Expanded(child: requestedField),
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        customerField,
                        const SizedBox(height: 12),
                        observationsField,
                        const SizedBox(height: 12),
                        requestedField,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Complaint checklist (add one line at a time)',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    AppTextField(
                      controller: complaintLineInput,
                      label: 'Add complaint line',
                      width: 320,
                      icon: Icons.report_problem_outlined,
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        final line = complaintLineInput.text.trim();
                        if (line.isEmpty) return;
                        setState(() {
                          complaintItems.add(line);
                          complaintLineInput.clear();
                        });
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Line'),
                    ),
                  ],
                ),
                if (complaintItems.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: complaintItems.asMap().entries.map((entry) {
                      return InputChip(
                        label: Text('${entry.key + 1}. ${entry.value}'),
                        onDeleted: () {
                          setState(() => complaintItems.removeAt(entry.key));
                        },
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 16),
                AppMultilineField(
                  controller: otherNotes,
                  label: 'Other Information',
                  hint: 'Insurance, warranty, outside work, etc.',
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                AppMultilineField(
                  controller: internalNotes,
                  label: 'Internal Notes (staff only)',
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    AppTextField(
                      controller: deliveryDate,
                      label: 'Delivery Date (DD-MM-YYYY)',
                      width: 200,
                    ),
                    AppTextField(
                      controller: deliveryTime,
                      label: 'Delivery Time',
                      width: 140,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: (customerId == null || vehicleId == null)
                      ? null
                      : () async {
                          final kmError = FormValidators.positiveKm(km.text);
                          final mechanicError =
                              FormValidators.requiredText(mechanic.text, 'Mechanic');
                          final error = kmError ?? mechanicError;
                          if (error != null) {
                            showAppSnackBar(context, error);
                            return;
                          }
                          if (!_hasAnyComplaintContent()) {
                            showAppSnackBar(
                              context,
                              'Add at least one complaint or work description',
                            );
                            return;
                          }
                          final card = await store.addJobCard(
                            customerId: customerId!,
                            vehicleId: vehicleId!,
                            kmReading: int.parse(km.text.trim()),
                            fuelLevel: fuelLevel,
                            customerComplaints: _buildComplaintsText(),
                            complaintItems: List.of(complaintItems),
                            observations: observations.text.trim(),
                            requestedWorks: requestedWorks.text.trim(),
                            otherNotes: otherNotes.text.trim(),
                            internalNotes: internalNotes.text.trim(),
                            mechanicName: mechanic.text.trim(),
                            estimatedDelivery: _parseDeliveryDateTime(),
                          );
                          if (!context.mounted) return;
                          if (card == null) {
                            showAppSnackBar(
                              context,
                              store.lastError ?? 'Could not create job card',
                            );
                            return;
                          }
                          _clearForm();
                          showAppSnackBar(
                            context,
                            'Job card #${card.jobCardNumber} created',
                            backgroundColor: AppColors.success,
                          );
                        },
                  icon: const Icon(Icons.save_rounded, size: 20),
                  label: const Text('Create Job Card'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Active Job Cards',
            icon: Icons.list_alt_rounded,
            child: Column(
              children: store.jobCards.map(
                (jobCard) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                    title: Text(
                      '#${jobCard.jobCardNumber} · ${store.vehicleNumber(jobCard.vehicleId)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${jobCard.mechanicName.isEmpty ? "Unassigned" : jobCard.mechanicName} · ${jobCard.status.label}',
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DropdownButtonFormField<JobStatus>(
                              value: jobCard.status,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              items: JobStatus.values
                                  .map(
                                    (status) => DropdownMenuItem(
                                      value: status,
                                      child: Text(status.label),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                store.updateJobCardStatus(jobCard.id, value);
                              },
                            ),
                            const SizedBox(height: 12),
                            _jobDetailRow('KM', '${jobCard.kmReading}'),
                            _jobDetailRow('Fuel', jobCard.fuelLevel),
                            if (jobCard.complaintItems.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              const Text('Complaints', style: TextStyle(fontWeight: FontWeight.w600)),
                              ...jobCard.complaintItems.map(
                                (item) => Text('• $item'),
                              ),
                            ],
                            if (jobCard.customerComplaints.isNotEmpty)
                              _jobDetailBlock('Customer Voice', jobCard.customerComplaints),
                            if (jobCard.observations.isNotEmpty)
                              _jobDetailBlock('Observations', jobCard.observations),
                            if (jobCard.requestedWorks.isNotEmpty)
                              _jobDetailBlock('Requested Works', jobCard.requestedWorks),
                            if (jobCard.otherNotes.isNotEmpty)
                              _jobDetailBlock('Other Info', jobCard.otherNotes),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasAnyComplaintContent() {
    return customerVoice.text.trim().isNotEmpty ||
        observations.text.trim().isNotEmpty ||
        requestedWorks.text.trim().isNotEmpty ||
        complaintItems.isNotEmpty;
  }

  String _buildComplaintsText() {
    final parts = <String>[];
    if (customerVoice.text.trim().isNotEmpty) {
      parts.add(customerVoice.text.trim());
    }
    if (complaintItems.isNotEmpty) {
      parts.add(complaintItems.map((item) => '• $item').join('\n'));
    }
    return parts.join('\n\n');
  }

  DateTime? _parseDeliveryDateTime() {
    final dateText = deliveryDate.text.trim();
    if (dateText.isEmpty) return null;
    final parsed = DateFormat('dd-MM-yyyy').tryParse(dateText);
    if (parsed == null) return null;
    final timeParts = deliveryTime.text.trim().split(':');
    if (timeParts.length >= 2) {
      final hour = int.tryParse(timeParts[0]) ?? 0;
      final minute = int.tryParse(timeParts[1]) ?? 0;
      return DateTime(parsed.year, parsed.month, parsed.day, hour, minute);
    }
    return parsed;
  }

  void _clearForm() {
    km.clear();
    customerVoice.clear();
    observations.clear();
    requestedWorks.clear();
    otherNotes.clear();
    internalNotes.clear();
    mechanic.clear();
    complaintLineInput.clear();
    deliveryDate.clear();
    deliveryTime.clear();
    setState(() => complaintItems.clear());
  }

  Widget _jobDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _jobDetailBlock(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value),
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
  String? selectedJobCardId;
  final labourDesc = TextEditingController();
  final labourAmount = TextEditingController();
  String? partStockItemId;
  final partQty = TextEditingController(text: '1');

  final labourLines = <InvoiceLineDraft>[];
  final partLines = <PartLineDraft>[];
  String paymentStatus = PaymentStatus.unpaid.name;
  final amountPaidController = TextEditingController(text: '0');

  @override
  void dispose() {
    labourDesc.dispose();
    labourAmount.dispose();
    partQty.dispose();
    amountPaidController.dispose();
    super.dispose();
  }

  Future<void> _recordPayment(GarageStore store, Invoice invoice) async {
    final amountController = TextEditingController(
      text: invoice.grandTotal.toStringAsFixed(0),
    );
    var selectedStatus = paymentStatusForAmount(
      invoice.grandTotal,
      invoice.grandTotal,
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final amount = double.tryParse(amountController.text.trim()) ?? 0;
          final suggested = paymentStatusForAmount(amount, invoice.grandTotal);
          return AlertDialog(
            title: Text('Payment · Invoice #${invoice.invoiceNumber}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Bill total: ${formatAmount(invoice.grandTotal)} · '
                  'Paid so far: ${formatAmount(invoice.amountPaid)} · '
                  'Balance: ${formatAmount(invoice.balanceAmount)}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: amountController,
                  label: 'Total amount paid *',
                  expand: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setDialogState(() {
                    selectedStatus = paymentStatusForAmount(
                      double.tryParse(amountController.text.trim()) ?? 0,
                      invoice.grandTotal,
                    );
                  }),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PaymentStatus>(
                  value: selectedStatus,
                  decoration: const InputDecoration(labelText: 'Payment status'),
                  items: PaymentStatus.values
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() => selectedStatus = value);
                  },
                ),
                if (suggested != selectedStatus)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Suggested: ${suggested.label} based on amount',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
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
      return;
    }

    final totalPaid = double.tryParse(amountController.text.trim()) ?? 0;
    amountController.dispose();
    if (totalPaid < 0) {
      showAppSnackBar(context, 'Enter a valid amount');
      return;
    }

    final error = await store.updateInvoicePayment(
      invoiceId: invoice.id,
      amountPaid: totalPaid,
      paymentStatus: selectedStatus,
    );

    if (!mounted) return;
    if (error != null) {
      showAppSnackBar(context, error);
      return;
    }
    showAppSnackBar(
      context,
      'Payment recorded for invoice #${invoice.invoiceNumber}',
      backgroundColor: AppColors.success,
    );
  }

  Future<void> _markInvoiceFullyPaid(GarageStore store, Invoice invoice) async {
    if (invoice.paymentStatus == PaymentStatus.paid) {
      return;
    }
    final error = await store.updateInvoicePayment(
      invoiceId: invoice.id,
      amountPaid: invoice.grandTotal,
      paymentStatus: PaymentStatus.paid,
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

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GarageStore>();
    final completedJobCards = store.jobCards
        .where((jobCard) => jobCard.status == JobStatus.completed)
        .toList();
    if (completedJobCards.isEmpty) {
      selectedJobCardId = null;
    } else if (selectedJobCardId == null ||
        !completedJobCards.any((jobCard) => jobCard.id == selectedJobCardId)) {
      selectedJobCardId = completedJobCards.first.id;
    }
    if (store.stockItems.isEmpty) {
      partStockItemId = null;
    } else if (partStockItemId == null ||
        !store.stockItems.any((item) => item.id == partStockItemId)) {
      partStockItemId = store.stockItems.first.id;
    }

    final labourTotal = labourLines.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    final partsTotal = partLines.fold<double>(
      0,
      (sum, line) => sum + line.amountFor(store.stockItems),
    );
    final stockWarning = store.validatePartsStock(partLines);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Invoices',
            subtitle: 'Split labour and parts, then generate bill',
            icon: Icons.receipt_long_rounded,
          ),
          SectionCard(
            title: 'Create Invoice',
            icon: Icons.post_add_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    DropdownButton<String>(
                      value: selectedJobCardId,
                      hint: const Text('Completed Job Card'),
                      items: completedJobCards
                          .map(
                            (jobCard) => DropdownMenuItem(
                              value: jobCard.id,
                              child: Text(
                                '#${jobCard.jobCardNumber} · ${store.vehicleNumber(jobCard.vehicleId)}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => selectedJobCardId = value),
                    ),
                    FilledButton.icon(
                      onPressed: selectedJobCardId == null
                          ? null
                          : () async {
                              final error = await store.convertJobCardToInvoice(
                                jobCardId: selectedJobCardId!,
                                labourItems: labourLines,
                                partsItems: partLines,
                                paymentStatus: PaymentStatus.values.firstWhere(
                                  (status) => status.name == paymentStatus,
                                ),
                                amountPaid: double.tryParse(
                                        amountPaidController.text.trim()) ??
                                    0,
                              );
                              if (error != null) {
                                showAppSnackBar(context, error);
                                return;
                              }
                              setState(() {
                                labourLines.clear();
                                partLines.clear();
                              });
                            },
                      icon: const Icon(Icons.receipt_rounded, size: 20),
                      label: const Text('Create Invoice'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
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
              AppTextField(controller: labourDesc, label: 'Description', width: 260),
              AppTextField(controller: labourAmount, label: 'Amount'),
              OutlinedButton.icon(
                onPressed: () {
                  final parsed = double.tryParse(labourAmount.text.trim()) ?? 0;
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
                  });
                  labourDesc.clear();
                  labourAmount.clear();
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Labour'),
              ),
            ],
          ),
          ...labourLines.map(
            (line) => DataListTile(
              title: line.description,
              trailing: Text(
                formatAmount(line.amount),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Parts',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              DropdownButton<String>(
                value: partStockItemId,
                items: store.stockItems
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.id,
                        child: Text('${item.name} (${item.currentStock})'),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => partStockItemId = value),
              ),
              AppTextField(controller: partQty, label: 'Qty', width: 100),
              OutlinedButton.icon(
                onPressed: partStockItemId == null
                    ? null
                    : () {
                        final qty = int.tryParse(partQty.text.trim()) ?? 0;
                        if (qty <= 0) {
                          return;
                        }
                        setState(() {
                          final existingIndex = partLines.indexWhere(
                            (line) => line.stockItemId == partStockItemId,
                          );
                          if (existingIndex >= 0) {
                            final existing = partLines[existingIndex];
                            partLines[existingIndex] = PartLineDraft(
                              stockItemId: existing.stockItemId,
                              qty: existing.qty + qty,
                            );
                          } else {
                            partLines.add(
                              PartLineDraft(
                                stockItemId: partStockItemId!,
                                qty: qty,
                              ),
                            );
                          }
                        });
                        partQty.text = '1';
                      },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Part'),
              ),
            ],
          ),
          if (stockWarning != null) ...[
            const SizedBox(height: 8),
            Text(
              stockWarning,
              style: const TextStyle(color: AppColors.warning, fontSize: 13),
            ),
          ],
          ...partLines.map(
            (line) => DataListTile(
              title: store.stockItemName(line.stockItemId),
              subtitle: 'Qty ${line.qty}',
              trailing: Text(
                formatAmount(line.amountFor(store.stockItems)),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ResponsiveTotalsBar(
            items: [
              ('Labour', formatAmount(labourTotal)),
              ('Parts', formatAmount(partsTotal)),
            ],
            grandTotalLabel:
                'Grand Total: ${formatAmount(labourTotal + partsTotal)}',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              DropdownMenu<String>(
                initialSelection: paymentStatus,
                label: const Text('Payment Status'),
                dropdownMenuEntries: PaymentStatus.values
                    .map(
                      (status) => DropdownMenuEntry(
                        value: status.name,
                        label: status.label,
                      ),
                    )
                    .toList(),
                onSelected: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    paymentStatus = value;
                  });
                },
              ),
              AppTextField(
                controller: amountPaidController,
                label: 'Amount Paid',
                width: 180,
              ),
            ],
          ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Recent Invoices',
            icon: Icons.history_rounded,
            child: Column(
              children: store.invoices.map(
                (invoice) => DataListTile(
                  title: '#${invoice.invoiceNumber} · ${store.vehicleNumber(invoice.vehicleId)}',
                  subtitle:
                      '${invoice.paymentStatus.label} · Balance ${formatAmount(invoice.balanceAmount)}',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatAmount(invoice.grandTotal),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      if (invoice.paymentStatus != PaymentStatus.paid) ...[
                        IconButton(
                          tooltip: 'Mark fully paid',
                          onPressed: () => _markInvoiceFullyPaid(store, invoice),
                          icon: const Icon(
                            Icons.payments_rounded,
                            color: AppColors.success,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Record payment',
                          onPressed: () => _recordPayment(store, invoice),
                          icon: const Icon(
                            Icons.account_balance_wallet_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                      IconButton(
                        tooltip: 'Print PDF',
                        onPressed: () async {
                          await Printing.layoutPdf(
                            onLayout: (format) => buildInvoicePdf(
                              invoice: invoice,
                              store: store,
                              format: format,
                            ),
                          );
                        },
                        icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary),
                      ),
                    ],
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

class EstimatesPage extends StatefulWidget {
  const EstimatesPage({super.key});

  @override
  State<EstimatesPage> createState() => _EstimatesPageState();
}

class _EstimatesPageState extends State<EstimatesPage> {
  String? selectedJobCardId;
  String? directCustomerId;
  String? directVehicleId;
  bool useDirectVehicle = false;
  final kmController = TextEditingController();
  final notesController = TextEditingController();
  final labourDesc = TextEditingController();
  final labourAmount = TextEditingController();
  String? partStockItemId;
  final partQty = TextEditingController(text: '1');
  final labourLines = <InvoiceLineDraft>[];
  final partLines = <PartLineDraft>[];

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GarageStore>();
    final openJobCards = store.jobCards
        .where((jobCard) => jobCard.status != JobStatus.delivered)
        .toList();

    if (openJobCards.isEmpty) {
      selectedJobCardId = null;
    } else if (!useDirectVehicle &&
        (selectedJobCardId == null ||
            !openJobCards.any((jobCard) => jobCard.id == selectedJobCardId))) {
      selectedJobCardId = openJobCards.first.id;
    }

    directCustomerId ??=
        store.customers.isNotEmpty ? store.customers.first.id : null;
    final directVehicles = store.vehicles
        .where((vehicle) => vehicle.customerId == directCustomerId)
        .toList();
    if (directVehicles.isEmpty) {
      directVehicleId = null;
    } else if (directVehicleId == null ||
        !directVehicles.any((vehicle) => vehicle.id == directVehicleId)) {
      directVehicleId = directVehicles.first.id;
    }

    if (store.stockItems.isEmpty) {
      partStockItemId = null;
    } else if (partStockItemId == null ||
        !store.stockItems.any((item) => item.id == partStockItemId)) {
      partStockItemId = store.stockItems.first.id;
    }

    final labourTotal =
        labourLines.fold<double>(0, (sum, item) => sum + item.amount);
    final partsTotal =
        partLines.fold<double>(0, (sum, line) => sum + line.amountFor(store.stockItems));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Estimates',
            subtitle: 'Quote labour and parts before billing the customer',
            icon: Icons.request_quote_rounded,
          ),
          SectionCard(
            title: 'Create Estimate',
            icon: Icons.calculate_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilterChip(
                      label: const Text('From Job Card'),
                      selected: !useDirectVehicle,
                      onSelected: (_) => setState(() => useDirectVehicle = false),
                    ),
                    FilterChip(
                      label: const Text('Direct Vehicle'),
                      selected: useDirectVehicle,
                      onSelected: (_) => setState(() => useDirectVehicle = true),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (!useDirectVehicle)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      DropdownButton<String>(
                        value: selectedJobCardId,
                        hint: const Text('Open Job Card'),
                        items: openJobCards
                            .map(
                              (jobCard) => DropdownMenuItem(
                                value: jobCard.id,
                                child: Text(
                                  '#${jobCard.jobCardNumber} · ${store.vehicleNumber(jobCard.vehicleId)}',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => selectedJobCardId = value),
                      ),
                    ],
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      DropdownButton<String>(
                        value: directCustomerId,
                        hint: const Text('Party'),
                        items: store.customers
                            .map(
                              (customer) => DropdownMenuItem(
                                value: customer.id,
                                child: Text(customer.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() {
                          directCustomerId = value;
                          directVehicleId = null;
                        }),
                      ),
                      DropdownButton<String>(
                        value: directVehicleId,
                        hint: const Text('Vehicle'),
                        items: directVehicles
                            .map(
                              (vehicle) => DropdownMenuItem(
                                value: vehicle.id,
                                child: Text(vehicle.regNumber),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => directVehicleId = value),
                      ),
                      AppTextField(
                        controller: kmController,
                        label: 'KM Reading',
                        width: 140,
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Labour',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    AppTextField(
                      controller: labourDesc,
                      label: 'Description',
                      width: 260,
                    ),
                    AppTextField(controller: labourAmount, label: 'Amount'),
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
                      label: const Text('Add Labour'),
                    ),
                  ],
                ),
                ...labourLines.map(
                  (line) => DataListTile(
                    title: line.description,
                    trailing: Text(
                      formatAmount(line.amount),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Parts',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    DropdownButton<String>(
                      value: partStockItemId,
                      items: store.stockItems
                          .map(
                            (item) => DropdownMenuItem(
                              value: item.id,
                              child: Text('${item.name} (${item.currentStock})'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => partStockItemId = value),
                    ),
                    AppTextField(
                      controller: partQty,
                      label: 'Qty',
                      width: 100,
                    ),
                    OutlinedButton.icon(
                      onPressed: partStockItemId == null
                          ? null
                          : () {
                              final qty = int.tryParse(partQty.text.trim()) ?? 0;
                              if (qty <= 0) return;
                              setState(() {
                                partLines.add(
                                  PartLineDraft(
                                    stockItemId: partStockItemId!,
                                    qty: qty,
                                  ),
                                );
                                partQty.text = '1';
                              });
                            },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Part'),
                    ),
                  ],
                ),
                ...partLines.map(
                  (line) => DataListTile(
                    title: store.stockItemName(line.stockItemId),
                    subtitle: 'Qty ${line.qty}',
                    trailing: Text(
                      formatAmount(line.amountFor(store.stockItems)),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: notesController,
                  label: 'Notes / Validity',
                  width: 360,
                ),
                const SizedBox(height: 16),
                ResponsiveTotalsBar(
                  items: [
                    ('Labour', formatAmount(labourTotal)),
                    ('Parts', formatAmount(partsTotal)),
                  ],
                  grandTotalLabel:
                      'Estimate Total: ${formatAmount(labourTotal + partsTotal)}',
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _canSaveEstimate(store)
                      ? () async {
                          final saved = await store.createEstimate(
                            jobCardId:
                                useDirectVehicle ? null : selectedJobCardId,
                            customerId: useDirectVehicle ? directCustomerId : null,
                            vehicleId: useDirectVehicle ? directVehicleId : null,
                            kmReading: useDirectVehicle
                                ? int.tryParse(kmController.text.trim())
                                : null,
                            labourItems: labourLines,
                            partsItems: partLines,
                            notes: notesController.text.trim(),
                          );
                          if (!saved) return;
                          setState(() {
                            labourLines.clear();
                            partLines.clear();
                            notesController.clear();
                            kmController.clear();
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Estimate saved'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.save_rounded, size: 20),
                  label: const Text('Save Estimate'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Saved Estimates',
            icon: Icons.list_alt_rounded,
            subtitle:
                'Use Convert to Invoice to bill the customer. Status becomes Converted automatically.',
            child: store.estimates.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No estimates yet. Create one above.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                : Column(
              children: store.estimates.map((estimate) {
                final isConverted = estimate.status == EstimateStatus.converted;
                final isRejected = estimate.status == EstimateStatus.rejected;
                final canConvert = !isConverted && !isRejected;
                return DataListTile(
                  title:
                      '#${estimate.estimateNumber} · ${estimate.vehicleNumber}',
                  subtitle:
                      '${estimate.status.label} · ${DateFormat('dd-MM-yyyy').format(estimate.createdAt)}',
                  trailing: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 520;
                      final statusControl = isConverted
                          ? Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              children: [
                                Chip(
                                  label: Text(estimate.status.label),
                                  backgroundColor:
                                      AppColors.success.withValues(alpha: 0.12),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    await store.reopenEstimate(estimate.id);
                                    if (context.mounted) {
                                      showAppSnackBar(
                                        context,
                                        'Estimate reopened — use Convert to Invoice to bill',
                                        backgroundColor: AppColors.success,
                                      );
                                    }
                                  },
                                  child: const Text('Reopen'),
                                ),
                              ],
                            )
                          : DropdownButton<EstimateStatus>(
                              value: estimate.status,
                              items: EstimateStatus.values
                                  .where(
                                    (status) =>
                                        status != EstimateStatus.converted,
                                  )
                                  .map(
                                    (status) => DropdownMenuItem(
                                      value: status,
                                      child: Text(status.label),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                store.updateEstimateStatus(estimate.id, value);
                              },
                            );
                      final amount = Text(
                        formatAmount(estimate.grandTotal),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      );
                      final pdfButton = IconButton(
                        tooltip: 'Print Estimate',
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
                          color: AppColors.primary,
                        ),
                      );
                      final convertButton = canConvert
                          ? FilledButton.tonalIcon(
                              onPressed: () async {
                                final error = await store.convertEstimateToInvoice(
                                  estimate.id,
                                );
                                if (!context.mounted) return;
                                if (error != null) {
                                  showAppSnackBar(context, error);
                                  return;
                                }
                                showAppSnackBar(
                                  context,
                                  'Invoice created — check Invoices tab',
                                  backgroundColor: AppColors.success,
                                );
                              },
                              icon: const Icon(Icons.receipt_long_rounded, size: 18),
                              label: Text(compact ? 'Bill' : 'Convert to Invoice'),
                            )
                          : null;

                      if (compact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                statusControl,
                                const SizedBox(width: 8),
                                amount,
                                pdfButton,
                              ],
                            ),
                            if (convertButton != null) ...[
                              const SizedBox(height: 8),
                              convertButton,
                            ],
                          ],
                        );
                      }

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          statusControl,
                          const SizedBox(width: 8),
                          amount,
                          pdfButton,
                          if (convertButton != null) ...[
                            const SizedBox(width: 8),
                            convertButton,
                          ],
                        ],
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  bool _canSaveEstimate(GarageStore store) {
    if (labourLines.isEmpty && partLines.isEmpty) return false;
    if (useDirectVehicle) {
      return directCustomerId != null && directVehicleId != null;
    }
    return selectedJobCardId != null;
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
  String selectedRole = UserRole.admin.name;

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
    selectedRole = context.read<GarageStore>().activeRole.name;
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
            subtitle: 'Garage profile, numbering, and user roles',
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
                  DropdownMenu<String>(
                    initialSelection: selectedRole,
                    label: const Text('Current user role'),
                    dropdownMenuEntries: UserRole.values
                        .map(
                          (role) => DropdownMenuEntry(
                            value: role.name,
                            label: role.label,
                          ),
                        )
                        .toList(),
                    onSelected: (value) {
                      if (value == null) {
                        return;
                      }
                      selectedRole = value;
                    },
                  ),
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
                      store.setActiveRole(
                        UserRole.values.firstWhere(
                          (role) => role.name == selectedRole,
                        ),
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
            title: 'Role Permissions',
            icon: Icons.admin_panel_settings_rounded,
            child: Column(
              children: UserRole.values.map(
                (role) => DataListTile(
                  title: role.label,
                  subtitle: store.roleDescription(role),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: const Icon(Icons.badge_outlined, color: AppColors.primary, size: 20),
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

  pw.Widget headerCell(String title, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 90, child: pw.Text(title, style: const pw.TextStyle(fontSize: 9))),
          pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 9))),
        ],
      ),
    );
  }

  pdf.addPage(
    pw.Page(
      pageFormat: format,
      build: (context) {
        return pw.Container(
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey700)),
          padding: const pw.EdgeInsets.all(12),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(s.businessName,
                  style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.Text(s.tagline),
              pw.Text('${s.phone}'),
              pw.Text(s.address),
              pw.SizedBox(height: 8),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text('Date: ${DateFormat('dd-MM-yyyy').format(invoice.createdAt)}'),
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey500),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('CUSTOMER INFO',
                              style: pw.TextStyle(
                                  color: PdfColors.blue800, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 6),
                          headerCell('Name', customer.name),
                          headerCell('Address', customer.address),
                          headerCell('Mobile', customer.mobile),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey500),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('VEHICLE INFO',
                              style: pw.TextStyle(
                                  color: PdfColors.blue800, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 6),
                          headerCell('Make', vehicle.brand),
                          headerCell('Model', vehicle.model),
                          headerCell('Year', '${vehicle.year}'),
                          headerCell('Reg No', vehicle.regNumber),
                          headerCell('Mileage', '${invoice.kmReading}'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Text('JOB PERFORMED',
                  style: pw.TextStyle(color: PdfColors.blue800, fontWeight: pw.FontWeight.bold)),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey500),
                columnWidths: const {
                  0: pw.FlexColumnWidth(4),
                  1: pw.FlexColumnWidth(1.2),
                },
                children: [
                  ...invoice.labourItems.map(
                    (line) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(line.description),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Align(
                            alignment: pw.Alignment.centerRight,
                            child: pw.Text(line.amount.toStringAsFixed(2)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text('SUB TOTAL: ${invoice.labourTotal.toStringAsFixed(2)}'),
              ),
              pw.SizedBox(height: 12),
              pw.Text('PARTS',
                  style: pw.TextStyle(color: PdfColors.blue800, fontWeight: pw.FontWeight.bold)),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey500),
                columnWidths: const {
                  0: pw.FlexColumnWidth(3),
                  1: pw.FlexColumnWidth(1),
                  2: pw.FlexColumnWidth(1.2),
                  3: pw.FlexColumnWidth(1.2),
                },
                children: [
                  ...invoice.partsItems.map(
                    (line) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(line.name),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('${line.qty}'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(line.unitPrice.toStringAsFixed(2)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Align(
                            alignment: pw.Alignment.centerRight,
                            child: pw.Text(line.amount.toStringAsFixed(2)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text('SUB TOTAL: ${invoice.partsTotal.toStringAsFixed(2)}'),
              ),
              pw.Spacer(),
              pw.Row(
                children: [
                  pw.Expanded(child: pw.Text('COMMENTS')),
                  pw.SizedBox(
                    width: 180,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('TOTAL LABOUR: ${invoice.labourTotal.toStringAsFixed(2)}'),
                        pw.Text('TOTAL PARTS: ${invoice.partsTotal.toStringAsFixed(2)}'),
                        pw.Text('TOTAL: ${invoice.grandTotal.toStringAsFixed(2)}',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
  return pdf.save();
}

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

  pw.Widget headerCell(String title, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 90,
            child: pw.Text(title, style: const pw.TextStyle(fontSize: 9)),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
          ),
        ],
      ),
    );
  }

  pdf.addPage(
    pw.Page(
      pageFormat: format,
      build: (context) {
        return pw.Container(
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey700)),
          padding: const pw.EdgeInsets.all(12),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    s.businessName,
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.blue800, width: 2),
                    ),
                    child: pw.Text(
                      'ESTIMATE #${estimate.estimateNumber}',
                      style: pw.TextStyle(
                        color: PdfColors.blue800,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              pw.Text(s.tagline),
              pw.Text(s.phone),
              pw.Text(s.address),
              pw.SizedBox(height: 8),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Date: ${DateFormat('dd-MM-yyyy').format(estimate.createdAt)}',
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey500),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'CUSTOMER INFO',
                            style: pw.TextStyle(
                              color: PdfColors.blue800,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          headerCell('Name', customer.name),
                          headerCell('Address', customer.address),
                          headerCell('Mobile', customer.mobile),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey500),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'VEHICLE INFO',
                            style: pw.TextStyle(
                              color: PdfColors.blue800,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          headerCell('Make', vehicle.brand),
                          headerCell('Model', vehicle.model),
                          headerCell('Year', '${vehicle.year}'),
                          headerCell('Reg No', vehicle.regNumber),
                          headerCell('Mileage', '${estimate.kmReading}'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Text(
                'JOB PERFORMED (ESTIMATED)',
                style: pw.TextStyle(
                  color: PdfColors.blue800,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey500),
                columnWidths: const {
                  0: pw.FlexColumnWidth(4),
                  1: pw.FlexColumnWidth(1.2),
                },
                children: [
                  ...estimate.labourItems.map(
                    (line) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(line.description),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Align(
                            alignment: pw.Alignment.centerRight,
                            child: pw.Text(line.amount.toStringAsFixed(2)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'SUB TOTAL: ${estimate.labourTotal.toStringAsFixed(2)}',
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Text(
                'PARTS (ESTIMATED)',
                style: pw.TextStyle(
                  color: PdfColors.blue800,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey500),
                columnWidths: const {
                  0: pw.FlexColumnWidth(3),
                  1: pw.FlexColumnWidth(1),
                  2: pw.FlexColumnWidth(1.2),
                  3: pw.FlexColumnWidth(1.2),
                },
                children: [
                  ...estimate.partsItems.map(
                    (line) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(line.name),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('${line.qty}'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(line.unitPrice.toStringAsFixed(2)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Align(
                            alignment: pw.Alignment.centerRight,
                            child: pw.Text(line.amount.toStringAsFixed(2)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'SUB TOTAL: ${estimate.partsTotal.toStringAsFixed(2)}',
                ),
              ),
              pw.Spacer(),
              if (estimate.notes.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Text('Notes: ${estimate.notes}'),
                ),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      'This is an estimate only. Final bill may vary after inspection.',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ),
                  pw.SizedBox(
                    width: 180,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'TOTAL LABOUR: ${estimate.labourTotal.toStringAsFixed(2)}',
                        ),
                        pw.Text(
                          'TOTAL PARTS: ${estimate.partsTotal.toStringAsFixed(2)}',
                        ),
                        pw.Text(
                          'ESTIMATE TOTAL: ${estimate.grandTotal.toStringAsFixed(2)}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
  return pdf.save();
}
