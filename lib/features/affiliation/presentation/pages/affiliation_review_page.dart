import 'dart:async';

import 'package:campus_connect/core/errors/app_failure.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_spacing.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_theme_extension.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_button.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_data_display.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_feedback.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_surface.dart';
import 'package:campus_connect/features/affiliation/domain/affiliation.dart';
import 'package:campus_connect/features/affiliation/presentation/controllers/affiliation_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AffiliationReviewPage extends ConsumerWidget {
  const AffiliationReviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(affiliationReviewControllerProvider);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            CcSpacing.md,
            CcSpacing.xl,
            CcSpacing.md,
            CcSpacing.md,
          ),
          sliver: SliverToBoxAdapter(
            child: CcSectionHeader(
              title: 'Student verification',
              supportingText:
                  'Match each request against official college records before '
                  'granting Student access.',
              action: IconButton.filledTonal(
                tooltip: 'Refresh verification requests',
                onPressed: requests.isLoading
                    ? null
                    : () => unawaited(
                        ref
                            .read(affiliationReviewControllerProvider.notifier)
                            .refresh(),
                      ),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ),
          ),
        ),
        requests.when(
          loading: () => const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Loading student verification requests',
              ),
            ),
          ),
          error: (error, _) => SliverFillRemaining(
            hasScrollBody: false,
            child: _ReviewLoadError(error: error),
          ),
          data: (items) => items.isEmpty
              ? const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyReviewQueue(),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    CcSpacing.md,
                    0,
                    CcSpacing.md,
                    CcSpacing.xl,
                  ),
                  sliver: SliverList.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: CcSpacing.md),
                    itemBuilder: (context, index) =>
                        _AffiliationRequestCard(request: items[index]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _ReviewLoadError extends ConsumerWidget {
  const _ReviewLoadError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.all(CcSpacing.md),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CcInlineMessage(
          message: error is AppFailure
              ? (error as AppFailure).message
              : 'Unable to load student verification requests.',
          tone: CcMessageTone.danger,
          liveRegion: true,
        ),
        const SizedBox(height: CcSpacing.md),
        CcPrimaryButton(
          label: 'Try again',
          icon: Icons.refresh_rounded,
          onPressed: () => unawaited(
            ref.read(affiliationReviewControllerProvider.notifier).refresh(),
          ),
        ),
      ],
    ),
  );
}

class _EmptyReviewQueue extends StatelessWidget {
  const _EmptyReviewQueue();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(CcSpacing.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CcIconTile(
              icon: Icons.fact_check_outlined,
              semanticLabel: 'No pending student requests',
            ),
            const SizedBox(height: CcSpacing.md),
            Text(
              'Verification queue is clear',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: CcSpacing.xs),
            Text(
              'New student affiliation requests will appear here after they '
              'select this college.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.ccTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AffiliationRequestCard extends ConsumerWidget {
  const _AffiliationRequestCard({required this.request});

  final StudentAffiliationRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submitted = MaterialLocalizations.of(
      context,
    ).formatMediumDate(request.createdAt.toLocal());
    final canApprove =
        request.programmeId != null &&
        request.durationMonths != null &&
        request.batchStartYear != null &&
        request.expectedCompletionYear != null &&
        request.progressionStatus != StudentProgressionStatus.unknown;
    return CcSurface(
      variant: CcSurfaceVariant.raised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CcIconTile(
                icon: Icons.person_search_outlined,
                semanticLabel: 'Student verification request',
              ),
              const SizedBox(width: CcSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.rollNumber,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: CcSpacing.xxs),
                    Text(
                      request.officialName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.ccTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: CcSpacing.lg),
          _AdminDetail(label: 'Primary roll ID', value: request.rollNumber),
          _AdminDetail(label: 'Account email', value: request.email ?? '—'),
          _AdminDetail(label: 'Programme', value: request.programme),
          _AdminDetail(
            label: 'Duration',
            value: request.durationMonths == null
                ? 'Not configured'
                : ProgrammeChoice(
                    id: request.programmeId ?? '',
                    institutionId: request.institutionId,
                    name: request.programme,
                    durationMonths: request.durationMonths!,
                  ).durationLabel,
          ),
          _AdminDetail(
            label: 'Batch',
            value:
                request.batchStartYear == null ||
                    request.expectedCompletionYear == null
                ? 'Not provided'
                : '${request.batchStartYear}–${request.expectedCompletionYear}',
          ),
          _AdminDetail(
            label: 'Progression',
            value: request.progressionStatus.label,
          ),
          _AdminDetail(label: 'Submitted', value: submitted),
          const SizedBox(height: CcSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final stack =
                  constraints.maxWidth < 420 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.3;
              final approve = CcPrimaryButton(
                label: 'Approve student',
                icon: Icons.check_rounded,
                expand: stack,
                onPressed: canApprove
                    ? () => _review(context, ref, approve: true)
                    : null,
              );
              final reject = CcSecondaryButton(
                label: 'Reject request',
                icon: Icons.close_rounded,
                expand: stack,
                onPressed: () => _review(context, ref, approve: false),
              );
              if (stack) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    approve,
                    const SizedBox(height: CcSpacing.sm),
                    reject,
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  reject,
                  const SizedBox(width: CcSpacing.sm),
                  approve,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _review(
    BuildContext context,
    WidgetRef ref, {
    required bool approve,
  }) async {
    final decision = await showDialog<_ReviewDecision>(
      context: context,
      builder: (context) =>
          _ReviewDecisionDialog(request: request, approve: approve),
    );
    if (decision == null || !context.mounted) return;
    await ref
        .read(affiliationReviewControllerProvider.notifier)
        .review(
          requestId: request.id,
          approve: approve,
          verifiedCurrentYear: decision.verifiedCurrentYear,
          decisionNote: decision.note,
        );
  }
}

class _AdminDetail extends StatelessWidget {
  const _AdminDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: CcSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 104,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: context.ccTheme.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: CcSpacing.sm),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

class _ReviewDecisionDialog extends StatefulWidget {
  const _ReviewDecisionDialog({required this.request, required this.approve});

  final StudentAffiliationRequest request;
  final bool approve;

  @override
  State<_ReviewDecisionDialog> createState() => _ReviewDecisionDialogState();
}

class _ReviewDecisionDialogState extends State<_ReviewDecisionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  int _verifiedCurrentYear = 1;

  bool get _isGraduated =>
      widget.request.progressionStatus == StudentProgressionStatus.graduated;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.approve
          ? _isGraduated
                ? 'Approve Alumni access?'
                : 'Approve Student access?'
          : 'Reject request?',
    ),
    content: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.approve
                ? 'Confirm ${widget.request.officialName}, roll number, '
                      'programme, and batch against official college records.'
                : 'Explain what ${widget.request.officialName} needs to correct before '
                      'submitting again.',
          ),
          if (widget.approve && _isGraduated) ...[
            const SizedBox(height: CcSpacing.md),
            const CcInlineMessage(
              message:
                  'This completed batch will receive Alumni access. No current '
                  'academic year is recorded.',
              tone: CcMessageTone.info,
            ),
          ],
          if (widget.approve && !_isGraduated) ...[
            const SizedBox(height: CcSpacing.md),
            DropdownButtonFormField<int>(
              initialValue: _verifiedCurrentYear,
              decoration: const InputDecoration(
                labelText: 'College-verified current year',
                helperText:
                    'Use the academic year in college records, not an estimate.',
              ),
              items: [
                for (
                  var year = 1;
                  year <= ((widget.request.durationMonths ?? 12) / 12).ceil();
                  year += 1
                )
                  DropdownMenuItem(value: year, child: Text('Year $year')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _verifiedCurrentYear = value);
                }
              },
            ),
          ],
          if (!widget.approve) ...[
            const SizedBox(height: CcSpacing.md),
            TextFormField(
              controller: _reasonController,
              autofocus: true,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection',
                hintText: 'Example: Roll number does not match our records.',
              ),
              validator: (value) {
                final reason = value?.trim() ?? '';
                if (reason.length < 2) {
                  return 'Enter a clear reason for the student.';
                }
                return null;
              },
            ),
          ],
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _submit,
        child: Text(widget.approve ? 'Approve access' : 'Reject request'),
      ),
    ],
  );

  void _submit() {
    if (!widget.approve && !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    Navigator.of(context).pop(
      _ReviewDecision(
        verifiedCurrentYear: widget.approve && !_isGraduated
            ? _verifiedCurrentYear
            : null,
        note: widget.approve ? null : _reasonController.text.trim(),
      ),
    );
  }
}

class _ReviewDecision {
  const _ReviewDecision({required this.verifiedCurrentYear, this.note});

  final int? verifiedCurrentYear;
  final String? note;
}
