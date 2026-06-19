import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:garage_management_system/src/models/garage_models.dart';
import 'package:garage_management_system/src/theme/app_theme.dart';
import 'package:garage_management_system/src/utils/garage_utils.dart';
import 'package:garage_management_system/src/widgets/responsive.dart';

void showAppSnackBar(
  BuildContext context,
  String message, {
  Color backgroundColor = AppColors.warning,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 26),
            ),
          if (icon != null) const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppBreakpoints.isMobile(context) ? 14 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.accentColor,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primary;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = screenWidth < 400
        ? screenWidth - 24
        : screenWidth < AppBreakpoints.tablet
            ? (screenWidth - 40) / 2
            : 200.0;

    final content = Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
              const Spacer(),
              if (onTap != null)
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: color.withValues(alpha: 0.7),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );

    return SizedBox(
      width: cardWidth,
      child: onTap == null
          ? Card(child: content)
          : Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: content,
              ),
            ),
    );
  }
}

class AppMultilineField extends StatelessWidget {
  const AppMultilineField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.minLines = 4,
    this.maxLines = 8,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      textAlignVertical: TextAlignVertical.top,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: true,
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.width = 200,
    this.icon,
    this.keyboardType,
    this.inputFormatters,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
    this.expand = false,
    this.hint,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final double width;
  final IconData? icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final TextCapitalization textCapitalization;
  final bool expand;
  final String? hint;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final useFullWidth = expand || AppBreakpoints.isMobile(context);
    return SizedBox(
      width: useFullWidth ? double.infinity : AppBreakpoints.fieldWidth(context, width),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLength: maxLength,
        textCapitalization: textCapitalization,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon:
              icon != null ? Icon(icon, size: 20, color: AppColors.textMuted) : null,
          counterText: maxLength != null ? '' : null,
        ),
      ),
    );
  }
}

class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.icon,
    this.hint,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final IconData? icon;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon:
            icon != null ? Icon(icon, size: 20, color: AppColors.textMuted) : null,
      ),
    );
  }
}

class AppFormRow extends StatelessWidget {
  const AppFormRow({
    super.key,
    required this.children,
    this.spacing = 12,
    this.breakpoint = 640,
  });

  final List<Widget> children;
  final double spacing;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: spacing),
                children[i],
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) SizedBox(width: spacing),
              Expanded(child: children[i]),
            ],
          ],
        );
      },
    );
  }
}

class AppFormActions extends StatelessWidget {
  const AppFormActions({
    super.key,
    required this.primary,
    this.secondary,
  });

  final Widget primary;
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    final compact = AppBreakpoints.isMobile(context);
    final actions = <Widget>[
      if (secondary != null) ...[
        secondary!,
        const SizedBox(width: 12),
      ],
      primary,
    ];

    if (compact) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: actions,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: actions,
      ),
    );
  }
}

class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.controller,
    this.hint = 'Search vehicle / mobile / name',
    this.onChanged,
    this.width = 360,
    this.expand = false,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final double width;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final useFullWidth =
        expand || AppBreakpoints.isCompact(context);
    return SizedBox(
      width: useFullWidth ? double.infinity : width,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: AppColors.background,
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class DataListTile extends StatelessWidget {
  const DataListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final compact = AppBreakpoints.isCompact(context);

    if (compact && trailing != null) {
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              trailing!,
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: leading,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              )
            : null,
        trailing: trailing,
      ),
    );
  }
}

class SidebarNavItem extends StatelessWidget {
  const SidebarNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Material(
        color: selected ? AppColors.sidebarSelected : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: selected ? Colors.white : Colors.white.withValues(alpha: 0.75),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white.withValues(alpha: 0.85),
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LabourSearchField extends StatefulWidget {
  const LabourSearchField({
    super.key,
    required this.controller,
    required this.items,
    required this.onSelected,
    this.onChanged,
    this.width = 260,
  });

  final TextEditingController controller;
  final List<LabourItem> items;
  final ValueChanged<LabourItem> onSelected;
  final ValueChanged<String>? onChanged;
  final double width;

  @override
  State<LabourSearchField> createState() => _LabourSearchFieldState();
}

class _LabourSearchFieldState extends State<LabourSearchField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fieldWidth = AppBreakpoints.fieldWidth(context, widget.width);
    return SizedBox(
      width: fieldWidth,
      child: RawAutocomplete<LabourItem>(
        textEditingController: widget.controller,
        focusNode: _focusNode,
        optionsBuilder: (textEditingValue) {
          final query = textEditingValue.text.trim().toLowerCase();
          if (query.isEmpty) {
            return widget.items.take(10);
          }
          return widget.items
              .where((item) => item.name.toLowerCase().contains(query))
              .take(10);
        },
        onSelected: widget.onSelected,
        displayStringForOption: (item) => item.name,
        fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
          return TextField(
            controller: fieldController,
            focusNode: focusNode,
            textCapitalization: TextCapitalization.words,
            onChanged: widget.onChanged,
            onSubmitted: (_) => onFieldSubmitted(),
            decoration: const InputDecoration(
              labelText: 'Labour work',
              hintText: 'Search painting, welding…',
              prefixIcon: Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
            ),
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(10),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: fieldWidth, maxHeight: 240),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final item = options.elementAt(index);
                    return ListTile(
                      dense: true,
                      title: Text(item.name),
                      trailing: Text(
                        formatAmount(item.defaultRate),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      onTap: () => onSelected(item),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class PartSearchField extends StatefulWidget {
  const PartSearchField({
    super.key,
    required this.controller,
    required this.items,
    required this.onSelected,
    this.onChanged,
    this.width = 260,
  });

  final TextEditingController controller;
  final List<StockItem> items;
  final ValueChanged<StockItem> onSelected;
  final ValueChanged<String>? onChanged;
  final double width;

  @override
  State<PartSearchField> createState() => _PartSearchFieldState();
}

class _PartSearchFieldState extends State<PartSearchField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fieldWidth = AppBreakpoints.fieldWidth(context, widget.width);
    return SizedBox(
      width: fieldWidth,
      child: RawAutocomplete<StockItem>(
        textEditingController: widget.controller,
        focusNode: _focusNode,
        optionsBuilder: (textEditingValue) {
          final query = textEditingValue.text.trim().toLowerCase();
          if (query.isEmpty) {
            return widget.items.take(10);
          }
          return widget.items
              .where(
                (item) =>
                    item.name.toLowerCase().contains(query) ||
                    item.sku.toLowerCase().contains(query),
              )
              .take(10);
        },
        onSelected: widget.onSelected,
        displayStringForOption: (item) => item.name,
        fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
          return TextField(
            controller: fieldController,
            focusNode: focusNode,
            textCapitalization: TextCapitalization.characters,
            onChanged: widget.onChanged,
            onSubmitted: (_) => onFieldSubmitted(),
            decoration: const InputDecoration(
              labelText: 'Part',
              hintText: 'Search part name or SKU…',
              prefixIcon: Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
            ),
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(10),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: fieldWidth, maxHeight: 240),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final item = options.elementAt(index);
                    return ListTile(
                      dense: true,
                      title: Text(item.name),
                      subtitle: Text('SKU ${item.sku} · Stock ${item.currentStock}'),
                      trailing: Text(
                        formatAmount(item.sellingPrice),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      onTap: () => onSelected(item),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class VehicleSearchField extends StatefulWidget {
  const VehicleSearchField({
    super.key,
    required this.controller,
    required this.optionsBuilder,
    required this.customerName,
    required this.customerMobile,
    required this.onSelected,
    this.onChanged,
    this.expand = false,
    this.width = 320,
    this.headerStyle = false,
    this.hint,
  });

  final TextEditingController controller;
  final Iterable<Vehicle> Function(String query) optionsBuilder;
  final String Function(String customerId) customerName;
  final String Function(String customerId) customerMobile;
  final ValueChanged<Vehicle> onSelected;
  final ValueChanged<String>? onChanged;
  final bool expand;
  final double width;
  final bool headerStyle;
  final String? hint;

  @override
  State<VehicleSearchField> createState() => _VehicleSearchFieldState();
}

class _VehicleSearchFieldState extends State<VehicleSearchField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final useFullWidth = widget.expand || AppBreakpoints.isMobile(context);
    final fieldWidth = useFullWidth
        ? double.infinity
        : AppBreakpoints.fieldWidth(context, widget.width);
    return SizedBox(
      width: fieldWidth,
      child: RawAutocomplete<Vehicle>(
        textEditingController: widget.controller,
        focusNode: _focusNode,
        optionsBuilder: (textEditingValue) {
          return widget.optionsBuilder(textEditingValue.text).take(10);
        },
        onSelected: widget.onSelected,
        displayStringForOption: (vehicle) => vehicle.regNumber,
        fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
          final hintText = widget.hint ??
              (widget.headerStyle
                  ? 'Search vehicle / mobile / name'
                  : 'Search KL60K3139, mobile, or name…');
          return TextField(
            controller: fieldController,
            focusNode: focusNode,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(fontSize: 14),
            onChanged: widget.onChanged,
            onSubmitted: (_) => onFieldSubmitted(),
            decoration: widget.headerStyle
                ? InputDecoration(
                    hintText: hintText,
                    filled: true,
                    fillColor: AppColors.background,
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.primary,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primaryLight,
                        width: 1.5,
                      ),
                    ),
                  )
                : InputDecoration(
                    labelText: 'Vehicle / mobile / owner',
                    hintText: hintText,
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                  ),
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          if (options.isEmpty) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(10),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: fieldWidth),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No matching vehicles. Add party under Party first.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ),
                ),
              ),
            );
          }
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(10),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: fieldWidth, maxHeight: 280),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final vehicle = options.elementAt(index);
                    final owner = widget.customerName(vehicle.customerId);
                    final mobile = widget.customerMobile(vehicle.customerId);
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: const Icon(
                          Icons.directions_car_filled_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                      title: Text(
                        vehicle.regNumber,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '$owner · $mobile\n'
                        '${vehicle.brand} ${vehicle.model}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      isThreeLine: true,
                      onTap: () => onSelected(vehicle),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class PartySearchField extends StatefulWidget {
  const PartySearchField({
    super.key,
    required this.controller,
    required this.optionsBuilder,
    required this.onSelected,
    this.onChanged,
    this.expand = false,
    this.width = 320,
  });

  final TextEditingController controller;
  final Iterable<Customer> Function(String query) optionsBuilder;
  final ValueChanged<Customer> onSelected;
  final ValueChanged<String>? onChanged;
  final bool expand;
  final double width;

  @override
  State<PartySearchField> createState() => _PartySearchFieldState();
}

class _PartySearchFieldState extends State<PartySearchField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final useFullWidth = widget.expand || AppBreakpoints.isMobile(context);
    final fieldWidth = useFullWidth
        ? double.infinity
        : AppBreakpoints.fieldWidth(context, widget.width);
    return SizedBox(
      width: fieldWidth,
      child: RawAutocomplete<Customer>(
        textEditingController: widget.controller,
        focusNode: _focusNode,
        optionsBuilder: (textEditingValue) {
          final query = textEditingValue.text;
          if (query.trim().isEmpty && !_focusNode.hasFocus) {
            return const Iterable<Customer>.empty();
          }
          return widget.optionsBuilder(query).take(10);
        },
        onSelected: widget.onSelected,
        displayStringForOption: (customer) => customer.name,
        fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
          return TextField(
            controller: fieldController,
            focusNode: focusNode,
            textCapitalization: TextCapitalization.words,
            onChanged: widget.onChanged,
            onSubmitted: (_) => onFieldSubmitted(),
            decoration: const InputDecoration(
              labelText: 'Party / owner name *',
              hintText: 'Search name or mobile…',
              prefixIcon: Icon(
                Icons.person_search_rounded,
                size: 20,
                color: AppColors.textMuted,
              ),
            ),
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          if (options.isEmpty) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(10),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: fieldWidth),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No matching parties. Add customer under Step 1 first.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ),
                ),
              ),
            );
          }
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(10),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: fieldWidth, maxHeight: 280),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final customer = options.elementAt(index);
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                      title: Text(
                        customer.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${customer.mobile}\n${customer.address}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      isThreeLine: true,
                      onTap: () => onSelected(customer),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
