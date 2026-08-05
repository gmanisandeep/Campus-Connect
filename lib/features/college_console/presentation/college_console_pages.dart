import 'dart:async';

import 'package:campus_connect/core/auth/session_controller.dart';
import 'package:campus_connect/core/theme/purple_universe/cc_spacing.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_ambient_background.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_button.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_data_display.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_feedback.dart';
import 'package:campus_connect/core/widgets/purple_universe/cc_surface.dart';
import 'package:campus_connect/features/affiliation/presentation/pages/affiliation_review_page.dart';
import 'package:campus_connect/features/social/data/supabase_social_repository.dart';
import 'package:campus_connect/features/social/domain/social.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CollegeRegistrationPage extends ConsumerStatefulWidget {
  const CollegeRegistrationPage({super.key});

  @override
  ConsumerState<CollegeRegistrationPage> createState() =>
      _CollegeRegistrationPageState();
}

class _CollegeRegistrationPageState
    extends ConsumerState<CollegeRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _collegeSearch = TextEditingController();
  final _name = TextEditingController();
  final _designation = TextEditingController();
  final _employeeId = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _notes = TextEditingController();
  List<InstitutionDirectoryEntry> _institutions = const [];
  InstitutionDirectoryEntry? _institution;
  SocialUpload? _document;
  bool _busy = false;
  String? _error;
  bool _submitted = false;

  @override
  void dispose() {
    for (final controller in [
      _collegeSearch,
      _name,
      _designation,
      _employeeId,
      _email,
      _phone,
      _notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final items = await ref
          .read(socialRepositoryProvider)
          .searchInstitutions(_collegeSearch.text);
      if (mounted) setState(() => _institutions = items);
    } on Object catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickDocument() async {
    const acceptedTypes = XTypeGroup(
      label: 'Authorization document',
      extensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    final file = await openFile(acceptedTypeGroups: const [acceptedTypes]);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (bytes.length > 10 * 1024 * 1024) {
      setState(
        () => _error = 'Authorization documents must be smaller than 10 MB.',
      );
      return;
    }
    setState(() => _document = _documentUpload(file.name, bytes));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_institution == null || _document == null) {
      setState(
        () =>
            _error = 'Select the college and attach an authorization document.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final path = await ref
          .read(socialRepositoryProvider)
          .uploadPrivateDocument(_document!);
      await ref
          .read(socialRepositoryProvider)
          .submitInstitutionClaim(
            InstitutionClaimInput(
              institutionId: _institution!.id,
              applicantName: _name.text,
              designation: _designation.text,
              employeeId: _employeeId.text,
              officialEmail: _email.text,
              officialPhone: _phone.text,
              authorizationDocumentPath: path,
              notes: _notes.text,
            ),
          );
      if (mounted) setState(() => _submitted = true);
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _DesktopConsoleGate(
    child: _ConsoleScaffold(
      title: 'Register your college',
      supportingText:
          'Claim an existing directory record. CampusConnect independently verifies the first authority before granting administration access.',
      child: _submitted
          ? _SubmittedState(
              title: 'Registration submitted',
              message:
                  'CampusConnect will verify the authorization document and contact the college through independently sourced official details. The applicant cannot approve this claim.',
              onDone: () => context.go('/social'),
            )
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CcSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '1. Select the official college record',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: CcSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _collegeSearch,
                                decoration: const InputDecoration(
                                  labelText: 'College name',
                                ),
                                onSubmitted: (_) => _search(),
                              ),
                            ),
                            const SizedBox(width: CcSpacing.sm),
                            CcSecondaryButton(
                              label: 'Search',
                              icon: Icons.search_rounded,
                              onPressed: _busy ? null : _search,
                            ),
                          ],
                        ),
                        if (_institutions.isNotEmpty) ...[
                          const SizedBox(height: CcSpacing.md),
                          DropdownButtonFormField<InstitutionDirectoryEntry>(
                            initialValue: _institution,
                            decoration: const InputDecoration(
                              labelText: 'Matching directory records',
                            ),
                            items: [
                              for (final item in _institutions)
                                DropdownMenuItem(
                                  value: item,
                                  child: Text(
                                    item.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: (value) =>
                                setState(() => _institution = value),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: CcSpacing.md),
                  CcSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '2. Authority details',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: CcSpacing.md),
                        _ConsoleFields(
                          children: [
                            TextFormField(
                              controller: _name,
                              decoration: const InputDecoration(
                                labelText: 'Full official name',
                              ),
                              validator: _required,
                            ),
                            TextFormField(
                              controller: _designation,
                              decoration: const InputDecoration(
                                labelText: 'Designation',
                              ),
                              validator: _required,
                            ),
                            TextFormField(
                              controller: _employeeId,
                              decoration: const InputDecoration(
                                labelText: 'Employee ID',
                              ),
                              validator: _required,
                            ),
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Official college email',
                              ),
                              validator: _emailValidator,
                            ),
                            TextFormField(
                              controller: _phone,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Official phone',
                              ),
                              validator: _required,
                            ),
                          ],
                        ),
                        const SizedBox(height: CcSpacing.md),
                        TextFormField(
                          controller: _notes,
                          maxLines: 4,
                          maxLength: 2000,
                          decoration: const InputDecoration(
                            labelText: 'Verification notes (optional)',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: CcSpacing.md),
                  CcSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '3. Authorization evidence',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: CcSpacing.xs),
                        const Text(
                          'Upload a signed authorization letter or appointment evidence. It is stored privately and visible only to the applicant and CampusConnect reviewers.',
                        ),
                        const SizedBox(height: CcSpacing.md),
                        CcSecondaryButton(
                          label: _document?.name ?? 'Attach document',
                          icon: Icons.attach_file_rounded,
                          onPressed: _busy ? null : _pickDocument,
                        ),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: CcSpacing.md),
                    CcInlineMessage(
                      message: _error!,
                      tone: CcMessageTone.danger,
                      liveRegion: true,
                    ),
                  ],
                  const SizedBox(height: CcSpacing.md),
                  CcPrimaryButton(
                    label: 'Submit college registration',
                    icon: Icons.verified_user_outlined,
                    isLoading: _busy,
                    onPressed: _busy ? null : _submit,
                  ),
                ],
              ),
            ),
    ),
  );
}

class FacultyRegistrationPage extends ConsumerStatefulWidget {
  const FacultyRegistrationPage({super.key});

  @override
  ConsumerState<FacultyRegistrationPage> createState() =>
      _FacultyRegistrationPageState();
}

class _FacultyRegistrationPageState
    extends ConsumerState<FacultyRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _search = TextEditingController();
  final _employeeId = TextEditingController();
  final _department = TextEditingController();
  final _designation = TextEditingController();
  final _email = TextEditingController();
  List<InstitutionDirectoryEntry> _institutions = const [];
  InstitutionDirectoryEntry? _institution;
  bool _busy = false;
  bool _submitted = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in [
      _search,
      _employeeId,
      _department,
      _designation,
      _email,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _find() async {
    setState(() => _busy = true);
    try {
      final items = await ref
          .read(socialRepositoryProvider)
          .searchInstitutions(_search.text);
      if (mounted) {
        setState(
          () => _institutions = items.where((item) => item.isVerified).toList(),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _institution == null) {
      setState(
        () => _error = 'Select a verified college and complete every field.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(socialRepositoryProvider)
          .submitFacultyRegistration(
            FacultyRegistrationInput(
              institutionId: _institution!.id,
              employeeId: _employeeId.text,
              department: _department.text,
              designation: _designation.text,
              officialEmail: _email.text,
            ),
          );
      if (mounted) setState(() => _submitted = true);
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _DesktopConsoleGate(
    child: _ConsoleScaffold(
      title: 'Faculty registration',
      supportingText:
          'Faculty authority starts only after a verified college administrator matches the request against official staff records.',
      child: _submitted
          ? _SubmittedState(
              title: 'Faculty request submitted',
              message:
                  'The verified college administration will review the employee ID, department, designation, and institutional email.',
              onDone: () => context.go('/social'),
            )
          : Form(
              key: _formKey,
              child: CcSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _search,
                            decoration: const InputDecoration(
                              labelText: 'Verified college name',
                            ),
                            onSubmitted: (_) => _find(),
                          ),
                        ),
                        const SizedBox(width: CcSpacing.sm),
                        CcSecondaryButton(
                          label: 'Search',
                          icon: Icons.search_rounded,
                          onPressed: _busy ? null : _find,
                        ),
                      ],
                    ),
                    if (_institutions.isNotEmpty) ...[
                      const SizedBox(height: CcSpacing.md),
                      DropdownButtonFormField<InstitutionDirectoryEntry>(
                        decoration: const InputDecoration(
                          labelText: 'Verified college',
                        ),
                        items: [
                          for (final item in _institutions)
                            DropdownMenuItem(
                              value: item,
                              child: Text(item.name),
                            ),
                        ],
                        onChanged: (value) =>
                            setState(() => _institution = value),
                      ),
                    ],
                    const SizedBox(height: CcSpacing.md),
                    _ConsoleFields(
                      children: [
                        TextFormField(
                          controller: _employeeId,
                          decoration: const InputDecoration(
                            labelText: 'Employee ID',
                          ),
                          validator: _required,
                        ),
                        TextFormField(
                          controller: _department,
                          decoration: const InputDecoration(
                            labelText: 'Department',
                          ),
                          validator: _required,
                        ),
                        TextFormField(
                          controller: _designation,
                          decoration: const InputDecoration(
                            labelText: 'Designation',
                          ),
                          validator: _required,
                        ),
                        TextFormField(
                          controller: _email,
                          decoration: const InputDecoration(
                            labelText: 'Official college email',
                          ),
                          validator: _emailValidator,
                        ),
                      ],
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: CcSpacing.md),
                      CcInlineMessage(
                        message: _error!,
                        tone: CcMessageTone.danger,
                        liveRegion: true,
                      ),
                    ],
                    const SizedBox(height: CcSpacing.md),
                    CcPrimaryButton(
                      label: 'Submit Faculty registration',
                      icon: Icons.badge_outlined,
                      isLoading: _busy,
                      onPressed: _busy ? null : _submit,
                    ),
                  ],
                ),
              ),
            ),
    ),
  );
}

class CollegeAdminConsolePage extends ConsumerStatefulWidget {
  const CollegeAdminConsolePage({super.key});

  @override
  ConsumerState<CollegeAdminConsolePage> createState() =>
      _CollegeAdminConsolePageState();
}

class _CollegeAdminConsolePageState
    extends ConsumerState<CollegeAdminConsolePage> {
  int _section = 0;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final institutionId = session.institutionId;
    return _DesktopConsoleGate(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CcAmbientBackground(
          tone: CcAmbientTone.quiet,
          child: SafeArea(
            child: Row(
              children: [
                NavigationRail(
                  extended: MediaQuery.sizeOf(context).width >= 1180,
                  selectedIndex: _section,
                  onDestinationSelected: (value) =>
                      setState(() => _section = value),
                  leading: const Padding(
                    padding: EdgeInsets.all(CcSpacing.md),
                    child: CcBrandLockup(compact: true),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.how_to_reg_outlined),
                      selectedIcon: Icon(Icons.how_to_reg_rounded),
                      label: Text('Students'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.badge_outlined),
                      selectedIcon: Icon(Icons.badge_rounded),
                      label: Text('Faculty'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.campaign_outlined),
                      selectedIcon: Icon(Icons.campaign_rounded),
                      label: Text('Publishing'),
                    ),
                  ],
                ),
                Expanded(
                  child: switch (_section) {
                    0 => const AffiliationReviewPage(),
                    1 =>
                      institutionId == null
                          ? const Center(child: Text('Select an institution.'))
                          : _FacultyReviewQueue(institutionId: institutionId),
                    _ => const _OfficialPublishingInfo(),
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PlatformReviewConsolePage extends ConsumerStatefulWidget {
  const PlatformReviewConsolePage({super.key});

  @override
  ConsumerState<PlatformReviewConsolePage> createState() =>
      _PlatformReviewConsolePageState();
}

class _PlatformReviewConsolePageState
    extends ConsumerState<PlatformReviewConsolePage> {
  late Future<List<InstitutionClaimReview>> _claims = _load();
  Future<List<InstitutionClaimReview>> _load() =>
      ref.read(socialRepositoryProvider).loadInstitutionClaimsForReview();

  @override
  Widget build(BuildContext context) => _DesktopConsoleGate(
    child: _ConsoleScaffold(
      title: 'College claim review',
      supportingText:
          'Verify identity and authorization through independently sourced institutional contacts. Never rely only on submitted information.',
      child: FutureBuilder<List<InstitutionClaimReview>>(
        future: _claims,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.isEmpty) {
            return const _SubmittedState(
              title: 'No claims waiting',
              message:
                  'New college registrations will appear here after submission.',
            );
          }
          return Column(
            children: [
              for (final claim in snapshot.data!)
                _ClaimReviewCard(
                  claim: claim,
                  onReviewed: () => setState(() => _claims = _load()),
                ),
            ],
          );
        },
      ),
    ),
  );
}

class _FacultyReviewQueue extends ConsumerStatefulWidget {
  const _FacultyReviewQueue({required this.institutionId});
  final String institutionId;

  @override
  ConsumerState<_FacultyReviewQueue> createState() =>
      _FacultyReviewQueueState();
}

class _FacultyReviewQueueState extends ConsumerState<_FacultyReviewQueue> {
  late Future<List<FacultyRegistrationReview>> _items = _load();
  Future<List<FacultyRegistrationReview>> _load() => ref
      .read(socialRepositoryProvider)
      .loadFacultyRegistrationsForReview(widget.institutionId);

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<List<FacultyRegistrationReview>>(
    future: _items,
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      return ListView(
        padding: const EdgeInsets.all(CcSpacing.lg),
        children: [
          const CcSectionHeader(
            title: 'Faculty verification',
            supportingText:
                'Match each request against official employee records before granting Faculty authority.',
          ),
          const SizedBox(height: CcSpacing.md),
          if (snapshot.data!.isEmpty)
            const _SubmittedState(
              title: 'No Faculty requests',
              message: 'Pending Faculty registrations will appear here.',
            )
          else
            for (final item in snapshot.data!)
              _FacultyReviewCard(
                item: item,
                onReviewed: () => setState(() => _items = _load()),
              ),
        ],
      );
    },
  );
}

class _FacultyReviewCard extends ConsumerWidget {
  const _FacultyReviewCard({required this.item, required this.onReviewed});
  final FacultyRegistrationReview item;
  final VoidCallback onReviewed;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.only(bottom: CcSpacing.sm),
    child: CcSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            item.applicantName,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: CcSpacing.xs),
          Text(
            '${item.designation} · ${item.department}\nEmployee ID: ${item.employeeId}\n${item.officialEmail}',
          ),
          const SizedBox(height: CcSpacing.md),
          Row(
            children: [
              Expanded(
                child: CcSecondaryButton(
                  label: 'Reject',
                  onPressed: () => _review(ref, 'rejected'),
                ),
              ),
              const SizedBox(width: CcSpacing.sm),
              Expanded(
                child: CcPrimaryButton(
                  label: 'Approve Faculty',
                  onPressed: () => _review(ref, 'approved'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Future<void> _review(WidgetRef ref, String decision) async {
    await ref
        .read(socialRepositoryProvider)
        .reviewFacultyRegistration(item.id, decision);
    onReviewed();
  }
}

class _ClaimReviewCard extends ConsumerWidget {
  const _ClaimReviewCard({required this.claim, required this.onReviewed});
  final InstitutionClaimReview claim;
  final VoidCallback onReviewed;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.only(bottom: CcSpacing.md),
    child: CcSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            claim.institutionName,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: CcSpacing.xs),
          Text(
            '${claim.applicantName} · ${claim.designation}\nEmployee ID: ${claim.employeeId}\n${claim.officialEmail} · ${claim.officialPhone}',
          ),
          if (claim.notes != null) ...[
            const SizedBox(height: CcSpacing.xs),
            Text(claim.notes!),
          ],
          const SizedBox(height: CcSpacing.md),
          Row(
            children: [
              Expanded(
                child: CcSecondaryButton(
                  label: 'Reject',
                  onPressed: () => _review(ref, 'rejected'),
                ),
              ),
              const SizedBox(width: CcSpacing.sm),
              Expanded(
                child: CcSecondaryButton(
                  label: 'Request information',
                  onPressed: () => _review(ref, 'needs_information'),
                ),
              ),
              const SizedBox(width: CcSpacing.sm),
              Expanded(
                child: CcPrimaryButton(
                  label: 'Approve authority',
                  onPressed: () => _review(ref, 'approved'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Future<void> _review(WidgetRef ref, String decision) async {
    await ref
        .read(socialRepositoryProvider)
        .reviewInstitutionClaim(claim.id, decision);
    onReviewed();
  }
}

class _OfficialPublishingInfo extends StatelessWidget {
  const _OfficialPublishingInfo();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(CcSpacing.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: const CcInlineMessage(
          message:
              'Verified institution administrators can publish official posts from the Create surface. Official posts are visibly attributed and never mixed with personal authority.',
          tone: CcMessageTone.info,
        ),
      ),
    ),
  );
}

class _ConsoleScaffold extends StatelessWidget {
  const _ConsoleScaffold({
    required this.title,
    required this.supportingText,
    required this.child,
  });
  final String title;
  final String supportingText;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    body: CcAmbientBackground(
      tone: CcAmbientTone.quiet,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: ListView(
              padding: const EdgeInsets.all(CcSpacing.xl),
              children: [
                Row(
                  children: [
                    const CcBrandLockup(),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => context.go('/social'),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Back to CampusConnect'),
                    ),
                  ],
                ),
                const SizedBox(height: CcSpacing.xl),
                CcSectionHeader(title: title, supportingText: supportingText),
                const SizedBox(height: CcSpacing.lg),
                child,
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _DesktopConsoleGate extends StatelessWidget {
  const _DesktopConsoleGate({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb && MediaQuery.sizeOf(context).width >= 900) return child;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(CcSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: const CcInlineMessage(
              message:
                  'College and Faculty registration is available only in the CampusConnect desktop website. Open this page on a computer with a window at least 900 pixels wide.',
              tone: CcMessageTone.info,
            ),
          ),
        ),
      ),
    );
  }
}

class _ConsoleFields extends StatelessWidget {
  const _ConsoleFields({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 720) {
        return Column(
          children: [
            for (final child in children)
              Padding(
                padding: const EdgeInsets.only(bottom: CcSpacing.sm),
                child: child,
              ),
          ],
        );
      }
      return Wrap(
        spacing: CcSpacing.md,
        runSpacing: CcSpacing.md,
        children: [
          for (final child in children)
            SizedBox(
              width: (constraints.maxWidth - CcSpacing.md) / 2,
              child: child,
            ),
        ],
      );
    },
  );
}

class _SubmittedState extends StatelessWidget {
  const _SubmittedState({
    required this.title,
    required this.message,
    this.onDone,
  });
  final String title;
  final String message;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) => CcSurface(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CcIconTile(icon: Icons.task_alt_rounded, semanticLabel: title),
        const SizedBox(height: CcSpacing.md),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: CcSpacing.xs),
        Text(message, textAlign: TextAlign.center),
        if (onDone != null) ...[
          const SizedBox(height: CcSpacing.md),
          CcPrimaryButton(label: 'Continue', onPressed: onDone),
        ],
      ],
    ),
  );
}

SocialUpload _documentUpload(String name, Uint8List bytes) {
  final extension = name.split('.').last.toLowerCase();
  final mime = switch (extension) {
    'pdf' => 'application/pdf',
    'png' => 'image/png',
    _ => 'image/jpeg',
  };
  return SocialUpload(
    name: name,
    bytes: bytes,
    kind: extension == 'pdf' ? SocialMediaKind.document : SocialMediaKind.image,
    mimeType: mime,
  );
}

String? _required(String? value) =>
    value == null || value.trim().length < 2 ? 'Required' : null;
String? _emailValidator(String? value) =>
    value != null &&
        RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())
    ? null
    : 'Enter a valid official email';
