import 'package:flutter/material.dart';
import 'package:garage_management_system/src/models/garage_models.dart';
import 'package:garage_management_system/src/store/garage_store.dart';
import 'package:garage_management_system/src/theme/app_theme.dart';
import 'package:garage_management_system/src/utils/garage_utils.dart';
import 'package:garage_management_system/src/pages/estimate_editor_page.dart';
import 'package:garage_management_system/src/pages/job_card_editor_page.dart';
import 'package:garage_management_system/src/utils/job_card_pdf.dart';
import 'package:garage_management_system/src/widgets/ui_components.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

class JobCardsPage extends StatefulWidget {
  const JobCardsPage({super.key, this.onEstimateSaved});

  final VoidCallback? onEstimateSaved;

  @override
  State<JobCardsPage> createState() => _JobCardsPageState();
}

class _JobCardsPageState extends State<JobCardsPage> {
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  List<JobCard> _liveJobCards(GarageStore store) {
    final query = search.text.trim().toLowerCase();
    final cards = store.jobCards
        .where((jobCard) => jobCard.status != JobStatus.delivered)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (query.isEmpty) {
      return cards;
    }

    return cards.where((jobCard) {
      final vehicle = store.vehicleNumber(jobCard.vehicleId).toLowerCase();
      final customer = store.customerName(jobCard.customerId).toLowerCase();
      final mobile = store.customerMobile(jobCard.customerId);
      return vehicle.contains(query) ||
          customer.contains(query) ||
          mobile.contains(query) ||
          jobCard.jobCardNumber.toString().contains(query) ||
          jobCard.mechanicName.toLowerCase().contains(query) ||
          jobCard.customerComplaints.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _openEstimateEditor(
    BuildContext context,
    GarageStore store,
    JobCard jobCard,
  ) async {
    final saved = await EstimateEditorPage.show(
      context,
      jobCard: jobCard,
      existingEstimate: store.estimateForJobCard(jobCard.id),
    );
    if (!context.mounted) {
      return;
    }
    if (saved == true) {
      showAppSnackBar(
        context,
        'Estimate saved — opening Estimates',
        backgroundColor: AppColors.success,
      );
      widget.onEstimateSaved?.call();
    }
  }

  Future<void> _openJobCardEditor(BuildContext context, JobCard jobCard) async {
    final saved = await JobCardEditorPage.show(context, jobCard: jobCard);
    if (!context.mounted) {
      return;
    }
    if (saved == true) {
      showAppSnackBar(
        context,
        'Job card updated',
        backgroundColor: AppColors.success,
      );
    }
  }

  Future<void> _markWorkDone(GarageStore store, JobCard jobCard) async {
    await store.updateJobCardStatus(jobCard.id, JobStatus.completed);
    if (!mounted) {
      return;
    }
    showAppSnackBar(
      context,
      'Job card #${jobCard.jobCardNumber} marked as done',
      backgroundColor: AppColors.success,
    );
  }

  Color _statusColor(JobStatus status) {
    return switch (status) {
      JobStatus.pending => AppColors.warning,
      JobStatus.inProgress => AppColors.primary,
      JobStatus.completed => AppColors.success,
      JobStatus.delivered => AppColors.textMuted,
    };
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GarageStore>();
    final liveCards = _liveJobCards(store);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Job Cards',
            subtitle: 'Live vehicles in workshop — tap to add estimate',
            icon: Icons.build_circle_rounded,
          ),
          SectionCard(
            title: 'Live Job Cards',
            icon: Icons.list_alt_rounded,
            subtitle: '${liveCards.length} open · newest first',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSearchField(
                  controller: search,
                  hint: 'Search vehicle, owner, mobile, job #…',
                  expand: true,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                if (liveCards.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No open job cards. Use Dashboard → Quick Job Card to start.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                else
                  ...liveCards.map((jobCard) {
                    final estimate = store.estimateForJobCard(jobCard.id);
                    final hasEstimate = estimate != null;
                    final estimateTotal = estimate?.grandTotal;
                    final isDone = jobCard.status == JobStatus.completed;
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
                                CircleAvatar(
                                  backgroundColor:
                                      AppColors.primary.withValues(alpha: 0.1),
                                  child: Text(
                                    '#${jobCard.jobCardNumber}',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        store.vehicleNumber(jobCard.vehicleId),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${store.customerName(jobCard.customerId)} · '
                                        '${jobCard.mechanicName.isEmpty ? "No mechanic" : jobCard.mechanicName}',
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('dd MMM yyyy, hh:mm a')
                                            .format(jobCard.createdAt),
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (jobCard.customerComplaints
                                          .isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          jobCard.customerComplaints,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Chip(
                                  label: Text(jobCard.status.label),
                                  backgroundColor:
                                      _statusColor(jobCard.status)
                                          .withValues(alpha: 0.12),
                                  labelStyle: TextStyle(
                                    color: _statusColor(jobCard.status),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      _openJobCardEditor(context, jobCard),
                                  icon: const Icon(Icons.edit_rounded, size: 18),
                                  label: const Text('Edit'),
                                ),
                                FilledButton.icon(
                                  onPressed: () =>
                                      _openEstimateEditor(context, store, jobCard),
                                  icon: Icon(
                                    hasEstimate
                                        ? Icons.edit_note_rounded
                                        : Icons.request_quote_rounded,
                                    size: 18,
                                  ),
                                  label: Text(
                                    hasEstimate
                                        ? 'Edit Estimate · ${formatAmount(estimateTotal ?? 0)}'
                                        : 'Create Estimate',
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    await Printing.layoutPdf(
                                      onLayout: (format) => buildJobCardPdf(
                                        jobCard: jobCard,
                                        store: store,
                                        format: format,
                                        estimate: estimate,
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.picture_as_pdf_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('Print'),
                                ),
                                if (!isDone)
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        _markWorkDone(store, jobCard),
                                    icon: const Icon(
                                      Icons.check_circle_outline_rounded,
                                      size: 18,
                                    ),
                                    label: const Text('Mark Work Done'),
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
