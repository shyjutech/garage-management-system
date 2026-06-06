import 'package:flutter/material.dart';

abstract final class AppBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobile;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < tablet;

  static EdgeInsets pagePadding(BuildContext context) {
    final mobileLayout = isMobile(context);
    return EdgeInsets.fromLTRB(
      mobileLayout ? 12 : 28,
      mobileLayout ? 12 : 20,
      mobileLayout ? 12 : 28,
      mobileLayout ? 16 : 28,
    );
  }

  static double fieldWidth(BuildContext context, double preferred) {
    if (isMobile(context)) {
      return MediaQuery.sizeOf(context).width - 48;
    }
    return preferred;
  }
}

/// Stacks children vertically on narrow screens, horizontally on wide screens.
class ResponsiveRowColumn extends StatelessWidget {
  const ResponsiveRowColumn({
    super.key,
    required this.children,
    this.breakpoint = AppBreakpoints.tablet,
    this.spacing = 12,
    this.rowCrossAxisAlignment = CrossAxisAlignment.center,
    this.columnCrossAxisAlignment = CrossAxisAlignment.stretch,
  });

  final List<Widget> children;
  final double breakpoint;
  final double spacing;
  final CrossAxisAlignment rowCrossAxisAlignment;
  final CrossAxisAlignment columnCrossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useColumn = constraints.maxWidth < breakpoint;
        if (useColumn) {
          return Column(
            crossAxisAlignment: columnCrossAxisAlignment,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: spacing),
                children[i],
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: rowCrossAxisAlignment,
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

/// Summary totals bar that wraps on mobile.
class ResponsiveTotalsBar extends StatelessWidget {
  const ResponsiveTotalsBar({
    super.key,
    required this.items,
    required this.grandTotalLabel,
  });

  final List<(String label, String value)> items;
  final String grandTotalLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1565C0).withValues(alpha: 0.08),
            const Color(0xFF42A5F5).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD6E4F0)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          final pills = items
              .map(
                (item) => _pill(item.$1, item.$2),
              )
              .toList();

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...pills,
                const SizedBox(height: 8),
                Text(
                  grandTotalLabel,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D47A1),
                  ),
                ),
              ],
            );
          }

          return Row(
            children: [
              ...pills,
              Expanded(
                child: Text(
                  grandTotalLabel,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D47A1),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _pill(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 20, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF5C6F82)),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A2B3C),
            ),
          ),
        ],
      ),
    );
  }
}
