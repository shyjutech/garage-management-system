import 'package:flutter/material.dart';
import 'package:garage_management_system/src/theme/app_theme.dart';
import 'package:garage_management_system/src/widgets/ui_components.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'How to Use Sarathi Garage',
            subtitle: 'Simple step-by-step guide for daily workshop work',
            icon: Icons.help_outline_rounded,
          ),
          SectionCard(
            title: 'Daily workflow at a glance',
            icon: Icons.route_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _flowStep(
                  number: '1',
                  title: 'Add Party + Vehicle',
                  body:
                      'When a customer comes for the first time, register their name, mobile, and address. '
                      'Then add their vehicle number, brand, model, year, and KM.',
                  menu: 'Party',
                ),
                _flowArrow(),
                _flowStep(
                  number: '2',
                  title: 'Create Job Card',
                  body:
                      'Open a job card when work starts. Select party and vehicle, enter KM, fuel level, '
                      'complaints, observations, mechanic name, and requested works.',
                  menu: 'Job Cards',
                ),
                _flowArrow(),
                _flowStep(
                  number: '3',
                  title: 'Give Estimate (optional)',
                  body:
                      'If the customer wants a price before work, create an estimate with labour and parts. '
                      'Print PDF and share. Update status to Sent or Approved when customer agrees.',
                  menu: 'Estimates',
                ),
                _flowArrow(),
                _flowStep(
                  number: '4',
                  title: 'Do the work',
                  body:
                      'Mechanic completes the job. Update job card status: Pending → In Progress → Completed.',
                  menu: 'Job Cards',
                ),
                _flowArrow(),
                _flowStep(
                  number: '5',
                  title: 'Convert to Invoice & collect payment',
                  body:
                      'When work is done, convert the estimate or job card into an invoice. '
                      'Parts stock is reduced automatically. Print the bill from Invoices.',
                  menu: 'Invoices',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Step 1 — New customer (Party) and vehicle',
            icon: Icons.people_rounded,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HelpParagraph(
                  'Go to **Party** in the side menu.',
                ),
                _HelpParagraph(
                  '**Add Party:** Enter customer name, 10-digit mobile number, and address. Click **Add Party**.',
                ),
                _HelpParagraph(
                  '**Add Vehicle:** Select the party, enter vehicle number (example: KL60K3139), brand, model, year, and current KM. Click **Add Vehicle**.',
                ),
                _HelpParagraph(
                  'Returning customer? Search by vehicle number, mobile, or name using the search bar at the top.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Step 2 — Job card (work order)',
            icon: Icons.build_circle_rounded,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HelpParagraph(
                  'Go to **Job Cards** → **New Job Card**.',
                ),
                _HelpParagraph(
                  'Select party and vehicle. Fill KM reading, fuel level, and mechanic name.',
                ),
                _HelpParagraph(
                  'Write complaints in **Customer Voice**, mechanic findings in **Observations**, and planned work in **Requested Works**.',
                ),
                _HelpParagraph(
                  'Click **Create Job Card**. The system assigns a job card number automatically.',
                ),
                _HelpParagraph(
                  '**Job card status:**',
                ),
                _HelpBullet('Pending — just opened'),
                _HelpBullet('In Progress — mechanic is working'),
                _HelpBullet('Completed — work finished, ready to bill'),
                _HelpBullet('Delivered — vehicle handed over / billed'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Step 3 — Estimate (quotation)',
            icon: Icons.request_quote_rounded,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HelpParagraph(
                  'Go to **Estimates**. You can create an estimate from a job card or directly for a vehicle.',
                ),
                _HelpParagraph(
                  'Add labour lines (description + amount) and parts from stock (name + quantity). Click **Save Estimate**.',
                ),
                _HelpParagraph(
                  'Use the PDF button to print or share the estimate with the customer.',
                ),
                _HelpParagraph(
                  '**Estimate status — what each means:**',
                ),
                _HelpBullet('Draft — still preparing'),
                _HelpBullet('Sent — shared with customer'),
                _HelpBullet('Approved — customer agreed to the price'),
                _HelpBullet('Rejected — customer declined'),
                _HelpBullet(
                  'Converted — already billed (set automatically, do not pick manually)',
                ),
                _HelpTip(
                  'Do not change status to Converted yourself. Use the **Convert to Invoice** button instead.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Step 4 — Stock (spare parts)',
            icon: Icons.inventory_2_rounded,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HelpParagraph(
                  'Go to **Stock** to add parts with name, SKU, selling price, and quantity on hand.',
                ),
                _HelpParagraph(
                  'When an invoice is created, parts quantities are reduced automatically. '
                  'If stock is too low, conversion will fail — add stock first.',
                ),
                _HelpParagraph(
                  'Dashboard shows low-stock alerts when quantity falls below the minimum level.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Step 5 — Invoice (final bill)',
            icon: Icons.receipt_long_rounded,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HelpParagraph(
                  'There are two ways to create an invoice:',
                ),
                _HelpBullet(
                  '**From estimate:** Estimates → Saved Estimates → **Convert to Invoice**',
                ),
                _HelpBullet(
                  '**From job card:** Invoices → select job card → add labour/parts → create invoice',
                ),
                _HelpParagraph(
                  'The bill splits **Labour** and **Parts** like your printed Sarathi format. Print PDF from the Invoices list.',
                ),
                _HelpParagraph(
                  'After conversion, the estimate status becomes **Converted** and the job card moves to **Delivered**.',
                ),
                _HelpParagraph(
                  'If you marked Converted by mistake without billing, click **Reopen** on that estimate and use **Convert to Invoice** again.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Other useful screens',
            icon: Icons.dashboard_rounded,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HelpBullet(
                  '**Dashboard** — today\'s job cards, open estimates, low stock, and recent invoices',
                ),
                _HelpBullet(
                  '**History** — full service history for one vehicle (past estimates and invoices)',
                ),
                _HelpBullet(
                  '**Settings** — business name, address, phone, and bill number counters (admin only)',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Quick tips',
            icon: Icons.lightbulb_outline_rounded,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HelpTip('Always search by vehicle number first — that is the fastest way in a busy workshop.'),
                _HelpTip('Create the job card as soon as the vehicle enters the bay.'),
                _HelpTip('Give an estimate before major work if the customer asks for a price.'),
                _HelpTip('Mark job card Completed when work is done, then convert to invoice at delivery.'),
                _HelpTip('Data is saved online after sign-in — refresh will not erase your records.'),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _flowStep extends StatelessWidget {
  const _flowStep({
    required this.number,
    required this.title,
    required this.body,
    required this.menu,
  });

  final String number;
  final String title;
  final String body;
  final String menu;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.primary,
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(menu),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                    labelStyle: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _flowArrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 15, top: 4, bottom: 4),
      child: Icon(Icons.arrow_downward_rounded, size: 18, color: AppColors.textMuted),
    );
  }
}

class _HelpParagraph extends StatelessWidget {
  const _HelpParagraph(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text.rich(
        TextSpan(
          style: const TextStyle(
            color: AppColors.textPrimary,
            height: 1.5,
            fontSize: 14,
          ),
          children: _parseBold(text),
        ),
      ),
    );
  }

  static List<TextSpan> _parseBold(String input) {
    final spans = <TextSpan>[];
    final parts = input.split('**');
    for (var i = 0; i < parts.length; i++) {
      spans.add(
        TextSpan(
          text: parts[i],
          style: i.isOdd
              ? const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)
              : null,
        ),
      );
    }
    return spans;
  }
}

class _HelpBullet extends StatelessWidget {
  const _HelpBullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
          Expanded(child: _HelpParagraph(text)),
        ],
      ),
    );
  }
}

class _HelpTip extends StatelessWidget {
  const _HelpTip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.tips_and_updates_outlined, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.textPrimary, height: 1.45, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
