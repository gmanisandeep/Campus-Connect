import 'dart:async';

import 'package:campus_connect/core/auth/session_controller.dart';
import 'package:campus_connect/core/errors/app_failure.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_spacing.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_theme_extension.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_button.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_data_display.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_feedback.dart';
import 'package:campus_connect/features/affiliation/domain/affiliation.dart';
import 'package:campus_connect/features/affiliation/presentation/controllers/affiliation_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StudentAffiliationPanel extends ConsumerWidget {
  const StudentAffiliationPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(studentAffiliationControllerProvider);
    return overview.when(
      loading: () => const _LoadingState(),
      error: (error, _) => _LoadError(error: error),
      data: (data) {
        final request = data.request;
        if (request == null) {
          return _AffiliationForm(
            institutions: data.institutions,
            programmes: data.programmes,
            initialName: ref.read(sessionControllerProvider).displayName,
          );
        }
        return switch (request.status) {
          AffiliationRequestStatus.pending => _PendingState(request: request),
          AffiliationRequestStatus.approved => _ApprovedState(request: request),
          AffiliationRequestStatus.rejected => _RejectedState(
            request: request,
            institutions: data.institutions,
            programmes: data.programmes,
          ),
          AffiliationRequestStatus.cancelled ||
          AffiliationRequestStatus.unknown => _AffiliationForm(
            institutions: data.institutions,
            programmes: data.programmes,
            initialName: request.officialName,
          ),
        };
      },
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: CcSpacing.xl),
      child: CircularProgressIndicator(
        semanticsLabel: 'Loading college verification',
      ),
    ),
  );
}

class _LoadError extends ConsumerWidget {
  const _LoadError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = error is AppFailure
        ? (error as AppFailure).message
        : 'Unable to load college verification right now.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CcInlineMessage(
          message: message,
          tone: CcMessageTone.danger,
          liveRegion: true,
        ),
        const SizedBox(height: CcSpacing.md),
        CcPrimaryButton(
          label: 'Try again',
          icon: Icons.refresh_rounded,
          onPressed: () => unawaited(
            ref.read(studentAffiliationControllerProvider.notifier).refresh(),
          ),
        ),
      ],
    );
  }
}

class _AffiliationForm extends ConsumerStatefulWidget {
  const _AffiliationForm({
    required this.institutions,
    required this.programmes,
    this.initialRequest,
    this.initialName,
  });

  final List<InstitutionChoice> institutions;
  final List<ProgrammeChoice> programmes;
  final StudentAffiliationRequest? initialRequest;
  final String? initialName;

  @override
  ConsumerState<_AffiliationForm> createState() => _AffiliationFormState();
}

class _AffiliationFormState extends ConsumerState<_AffiliationForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _rollController;
  String? _institutionId;
  String? _programmeId;
  late int _batchStartYear;
  late int _expectedCompletionYear;
  StudentProgressionStatus _progressionStatus =
      StudentProgressionStatus.regular;

  List<ProgrammeChoice> get _programmesForInstitution => widget.programmes
      .where((programme) => programme.institutionId == _institutionId)
      .toList(growable: false);

  ProgrammeChoice? get _selectedProgramme => widget.programmes
      .where((programme) => programme.id == _programmeId)
      .firstOrNull;

  bool get _isGraduated =>
      _progressionStatus == StudentProgressionStatus.graduated;

  @override
  void initState() {
    super.initState();
    final request = widget.initialRequest;
    _nameController = TextEditingController(
      text: request?.officialName ?? widget.initialName,
    );
    _rollController = TextEditingController(text: request?.rollNumber);
    final currentYear = DateTime.now().year;
    _batchStartYear = request?.batchStartYear ?? currentYear;
    _expectedCompletionYear =
        request?.expectedCompletionYear ?? currentYear + 3;
    _progressionStatus =
        request?.progressionStatus == null ||
            request!.progressionStatus == StudentProgressionStatus.unknown
        ? StudentProgressionStatus.regular
        : request.progressionStatus;
    final requestedInstitution = request?.institutionId;
    _institutionId =
        widget.institutions.any(
          (institution) => institution.id == requestedInstitution,
        )
        ? requestedInstitution
        : widget.institutions.firstOrNull?.id;
    final requestedProgramme = request?.programmeId;
    _programmeId =
        widget.programmes.any(
          (programme) =>
              programme.id == requestedProgramme &&
              programme.institutionId == _institutionId,
        )
        ? requestedProgramme
        : _programmesForInstitution.firstOrNull?.id;
    _syncExpectedCompletion(force: request?.expectedCompletionYear == null);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(studentAffiliationControllerProvider);
    final errorMessage = action.whenOrNull(
      error: (error, _) => error is AppFailure
          ? error.message
          : 'Unable to submit this verification request.',
    );

    if (widget.institutions.isEmpty) {
      return const CcInlineMessage(
        message:
            'No colleges are accepting verification requests yet. Ask your '
            'college administrator to register the institution.',
        tone: CcMessageTone.info,
      );
    }
    if (widget.programmes.isEmpty) {
      return const CcInlineMessage(
        message:
            'No programmes are configured yet. Ask the college administrator '
            'to publish programme durations before submitting.',
        tone: CcMessageTone.info,
      );
    }

    return FocusTraversalGroup(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CcInlineMessage(
              message:
                  'Submit details exactly as they appear in your college '
                  'records. Access stays locked until the college approves.',
              tone: CcMessageTone.info,
            ),
            const SizedBox(height: CcSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _institutionId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'College',
                prefixIcon: Icon(Icons.account_balance_outlined),
              ),
              items: [
                for (final institution in widget.institutions)
                  DropdownMenuItem(
                    value: institution.id,
                    child: Text(
                      institution.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: action.isLoading
                  ? null
                  : (value) => setState(() {
                      _institutionId = value;
                      _programmeId = _programmesForInstitution.firstOrNull?.id;
                      _syncBatchForStatus();
                    }),
              validator: (value) => value == null
                  ? 'Choose the college that holds your records.'
                  : null,
            ),
            const SizedBox(height: CcSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _programmeId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Programme',
                helperText: 'Duration is configured by the college.',
                prefixIcon: Icon(Icons.school_outlined),
              ),
              items: [
                for (final programme in _programmesForInstitution)
                  DropdownMenuItem(
                    value: programme.id,
                    child: Text(
                      '${programme.name} · ${programme.durationLabel}',
                    ),
                  ),
              ],
              onChanged: action.isLoading
                  ? null
                  : (value) => setState(() {
                      _programmeId = value;
                      _syncBatchForStatus();
                    }),
              validator: (value) => value == null
                  ? 'Choose a programme offered by this college.'
                  : null,
            ),
            const SizedBox(height: CcSpacing.md),
            TextFormField(
              controller: _rollController,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Roll number — primary college ID',
                helperText:
                    'Enter it exactly, including letters and leading zeroes.',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (value) => _validateLength(
                value,
                label: 'roll number',
                minimum: 2,
                maximum: 64,
              ),
            ),
            const SizedBox(height: CcSpacing.md),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Official name',
                helperText: 'Use the name printed on your college record.',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (value) => _validateLength(
                value,
                label: 'official name',
                minimum: 2,
                maximum: 120,
              ),
            ),
            const SizedBox(height: CcSpacing.md),
            DropdownButtonFormField<int>(
              key: ValueKey(
                'batch-${_progressionStatus.databaseValue}-$_batchStartYear',
              ),
              initialValue: _batchStartYear,
              decoration: const InputDecoration(
                labelText: 'Batch start year',
                helperText: 'The first year of your programme batch.',
                prefixIcon: Icon(Icons.calendar_month_outlined),
              ),
              items: [
                for (
                  var year = 2000;
                  year <= DateTime.now().year + 1;
                  year += 1
                )
                  DropdownMenuItem(value: year, child: Text('$year')),
              ],
              onChanged: action.isLoading
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() {
                        _batchStartYear = value;
                        _syncExpectedCompletion(force: true);
                      });
                    },
            ),
            const SizedBox(height: CcSpacing.md),
            DropdownButtonFormField<int>(
              key: ValueKey(
                'completion-$_batchStartYear-$_expectedCompletionYear',
              ),
              initialValue: _expectedCompletionYear,
              decoration: InputDecoration(
                labelText: _isGraduated
                    ? 'Completion year'
                    : 'Expected completion year',
                helperText: _isGraduated
                    ? 'Use the graduation year shown in your college record.'
                    : 'Extend this if a gap or repeat changed your batch end.',
                prefixIcon: const Icon(Icons.event_available_outlined),
              ),
              items: [
                for (
                  var year = _batchStartYear + 1;
                  year <= _batchStartYear + 12;
                  year += 1
                )
                  DropdownMenuItem(value: year, child: Text('$year')),
              ],
              onChanged: action.isLoading
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _expectedCompletionYear = value);
                      }
                    },
            ),
            const SizedBox(height: CcSpacing.md),
            DropdownButtonFormField<StudentProgressionStatus>(
              initialValue: _progressionStatus,
              decoration: const InputDecoration(
                labelText: 'Progression status',
                helperText: 'No private reason is required.',
                prefixIcon: Icon(Icons.route_outlined),
              ),
              items: [
                for (final status in StudentProgressionStatus.values)
                  if (status != StudentProgressionStatus.unknown)
                    DropdownMenuItem(value: status, child: Text(status.label)),
              ],
              onChanged: action.isLoading
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() {
                          _progressionStatus = value;
                          if (_isGraduated) {
                            _suggestGraduatedBatch();
                          } else {
                            _syncExpectedCompletion(force: true);
                          }
                        });
                      }
                    },
            ),
            const SizedBox(height: CcSpacing.md),
            CcInlineMessage(
              message: _isGraduated
                  ? 'Graduated requests receive Alumni access after college '
                        'approval. A current academic year is not requested.'
                  : 'CampusConnect may estimate progress from your batch, but '
                        'only the college can verify your current academic year.',
              tone: CcMessageTone.info,
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: CcSpacing.md),
              CcInlineMessage(
                message: errorMessage,
                tone: CcMessageTone.danger,
                liveRegion: true,
              ),
            ],
            const SizedBox(height: CcSpacing.lg),
            CcPrimaryButton(
              label: 'Send for college approval',
              icon: Icons.verified_user_outlined,
              isLoading: action.isLoading,
              onPressed: action.isLoading ? null : _submit,
            ),
            const SizedBox(height: CcSpacing.sm),
            Text(
              'Only authorized administrators at the selected college can '
              'review this request.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.ccTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final institutionId = _institutionId;
    final programmeId = _programmeId;
    if (institutionId == null || programmeId == null) return;
    unawaited(
      ref
          .read(studentAffiliationControllerProvider.notifier)
          .submit(
            StudentAffiliationSubmission(
              institutionId: institutionId,
              programmeId: programmeId,
              officialName: _nameController.text,
              rollNumber: _rollController.text,
              batchStartYear: _batchStartYear,
              expectedCompletionYear: _expectedCompletionYear,
              progressionStatus: _progressionStatus,
            ),
          ),
    );
  }

  void _syncExpectedCompletion({required bool force}) {
    final programme = _selectedProgramme;
    if (programme == null) return;
    final suggested = _batchStartYear + programme.maximumAcademicYear;
    if (force ||
        _expectedCompletionYear <= _batchStartYear ||
        _expectedCompletionYear > _batchStartYear + 12) {
      _expectedCompletionYear = suggested;
    }
  }

  void _syncBatchForStatus() {
    if (_isGraduated) {
      _suggestGraduatedBatch();
    } else {
      _syncExpectedCompletion(force: true);
    }
  }

  void _suggestGraduatedBatch() {
    final programme = _selectedProgramme;
    if (programme == null) return;
    final completionYear = DateTime.now().year;
    _expectedCompletionYear = completionYear;
    _batchStartYear = completionYear - programme.maximumAcademicYear;
  }
}

class _PendingState extends ConsumerWidget {
  const _PendingState({required this.request});

  final StudentAffiliationRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Align(
        alignment: Alignment.centerLeft,
        child: CcIconTile(
          icon: Icons.hourglass_top_rounded,
          semanticLabel: 'College approval pending',
        ),
      ),
      const SizedBox(height: CcSpacing.md),
      Text(
        'Approval pending',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: CcSpacing.xs),
      Text(
        '${request.institutionName} needs to match your roll number and '
        'academic details with its records.',
      ),
      const SizedBox(height: CcSpacing.lg),
      _RequestDetails(request: request),
      const SizedBox(height: CcSpacing.lg),
      CcPrimaryButton(
        label: 'Check approval status',
        icon: Icons.refresh_rounded,
        onPressed: () => unawaited(
          ref.read(studentAffiliationControllerProvider.notifier).refresh(),
        ),
      ),
      const SizedBox(height: CcSpacing.xs),
      TextButton(
        onPressed: () => unawaited(
          ref
              .read(studentAffiliationControllerProvider.notifier)
              .cancel(request.id),
        ),
        child: const Text('Cancel request'),
      ),
    ],
  );
}

class _ApprovedState extends ConsumerWidget {
  const _ApprovedState({required this.request});

  final StudentAffiliationRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const CcInlineMessage(
        message:
            'Your college approved this request. Refresh access to open your '
            'verified Student experience.',
        tone: CcMessageTone.success,
        liveRegion: true,
      ),
      const SizedBox(height: CcSpacing.md),
      _RequestDetails(request: request),
      const SizedBox(height: CcSpacing.lg),
      CcPrimaryButton(
        label: 'Open campus access',
        icon: Icons.arrow_forward_rounded,
        onPressed: () => unawaited(
          ref.read(studentAffiliationControllerProvider.notifier).refresh(),
        ),
      ),
    ],
  );
}

class _RejectedState extends StatelessWidget {
  const _RejectedState({
    required this.request,
    required this.institutions,
    required this.programmes,
  });

  final StudentAffiliationRequest request;
  final List<InstitutionChoice> institutions;
  final List<ProgrammeChoice> programmes;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      CcInlineMessage(
        message:
            'The college could not verify this request. '
            '${request.decisionNote ?? 'Check the details and submit again.'}',
        tone: CcMessageTone.warning,
        liveRegion: true,
      ),
      const SizedBox(height: CcSpacing.lg),
      _AffiliationForm(
        institutions: institutions,
        programmes: programmes,
        initialRequest: request,
      ),
    ],
  );
}

class _RequestDetails extends StatelessWidget {
  const _RequestDetails({required this.request});

  final StudentAffiliationRequest request;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _DetailRow(label: 'College', value: request.institutionName),
      _DetailRow(label: 'Primary roll ID', value: request.rollNumber),
      _DetailRow(label: 'Official name', value: request.officialName),
      _DetailRow(label: 'Programme', value: request.programme),
      _DetailRow(
        label: 'Batch',
        value:
            request.batchStartYear == null ||
                request.expectedCompletionYear == null
            ? 'Not provided'
            : '${request.batchStartYear}–${request.expectedCompletionYear}',
      ),
      _DetailRow(label: 'Status', value: request.progressionStatus.label),
      if (request.verifiedCurrentYear != null)
        _DetailRow(
          label: 'Verified year',
          value: 'Year ${request.verifiedCurrentYear}',
        ),
    ],
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: CcSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 112,
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

String? _validateLength(
  String? value, {
  required String label,
  required int minimum,
  required int maximum,
}) {
  final normalized = value?.trim() ?? '';
  if (normalized.isEmpty) return 'Enter your $label.';
  if (normalized.length < minimum) {
    return 'Use at least $minimum characters.';
  }
  if (normalized.length > maximum) {
    return 'Use $maximum characters or fewer.';
  }
  return null;
}
