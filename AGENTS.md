# CampusConnect agent instructions

These instructions apply to the entire repository.

## Product and architecture safety

- Preserve the existing Flutter feature boundaries, Riverpod state ownership,
  GoRouter authorization, Supabase repositories, RLS policies, migrations,
  encrypted attendance drafts, idempotency rules, and Student/Faculty flows.
- Use the real repository and use-case data. Do not replace functional screens
  with disconnected mock data or silently create production-looking records.
- Treat backend-returned identity, tenant, permissions, dates, rosters, and
  attendance confirmations as authoritative. Visual state must not imply that
  a local draft is server-confirmed.
- Do not change database, authentication, permission, tenant, or offline
  contracts for visual convenience. Any necessary contract change requires a
  migration, positive and negative tests, and a documented security rationale.
- Never commit secrets, privileged Supabase keys, signing material, local
  environment files, real student data, or generated release credentials.
- Treat `docs/FEATURE_ARCHITECTURE.md` as the canonical Student/Faculty product
  hierarchy. A production destination is exposed only when its complete
  vertical slice exists, the institution enables the module, and the active
  server-derived grant permits the resource. A delivery label or client flag
  never grants authority.
- Keep unfinished modules absent from production navigation. Do not ship
  disabled coming-soon controls, fake counters, or production-looking demo
  records. The development-only gallery may show an explicitly labelled
  blueprint.
- Implement shared Feed, Chat, Calendar, Courses, and Attendance domains with
  role-specific server projections rather than duplicate Student and Faculty
  silos. Career uses Student-owned Skills plus one typed Opportunities domain
  for internships, jobs, and part-time work.

## Git and recovery

- The canonical remote is
  `https://github.com/gmanisandeep/Campus-Connect.git`.
- Preserve user work. Never use `git reset --hard`, `git clean -fd`,
  force-push, or force-with-lease unless the user explicitly authorizes the
  exact operation.
- Develop Purple Universe work on `codex/purple-universe` or a later scoped
  feature branch. Keep `main` as the recoverable validated baseline.
- Before editing, inspect branch, status, recent log, and remotes. Before every
  commit, inspect the full intended diff and ensure no unrelated user work is
  staged.
- Commit and push each coherent, validated checkpoint with an accurate
  conventional commit. Do not claim a commit or push until the local and remote
  SHAs have been verified.
- Do not accumulate a large uncommitted redesign. Foundations, shell,
  authentication, Student Home, attendance, and later modules are separate
  checkpoints.

## Required validation

- Run `dart format --output=none --set-exit-if-changed lib test`,
  `flutter analyze`, relevant focused tests, the full Flutter suite, and
  `git diff --check` in proportion to each checkpoint.
- Run database/security contracts when backend code changes. A UI-only change
  must still preserve the most recent passing backend evidence and must not
  claim a fresh backend run that did not occur.
- Build and signature-check an Android APK for integration checkpoints. Run
  physical-device visual, offline, resume, and performance checks when a device
  is available.
- Keep tests for semantics, reduced motion, large text, narrow phones, and
  tablets with major component or screen migrations. Add goldens only with a
  deterministic rendering setup and reviewed baselines.
- If a gate fails, fix and rerun it before committing. Record tool or
  environment blockers separately from product failures.

## Campus Sky design discipline

- Follow root `DESIGN.md`, `docs/MOTION_SYSTEM.md`, and
  `docs/VISUAL_PERFORMANCE_BUDGET.md`. The legacy
  `purple_universe` source namespace remains compatibility-only.
- Use semantic tokens and reusable CampusConnect components; do not scatter
  literal colors, gradients, radii, durations, or shadows through features.
- Keep the visual language bright, social, original, and useful: pale sky
  atmosphere, floating white surfaces, decisive black typography, a single
  `#498ACA` ownership accent, and image-led content.
- Do not turn every surface into glass, every control into a gradient, or every
  transition into a spectacle. Reserve the glossy orbit treatment for the
  five-item mobile creation action.
- Pause or remove continuous visual work when offscreen. Respect reduced motion
  and quality fallbacks. Expensive blur, shaders, and painters require measured
  evidence on the Galaxy A35 before broad use.
- Maintain both dark and light themes. Light mode is the primary Campus Sky
  expression; dark mode maps the same roles to deep navy without returning to
  purple wallpaper.

## Accessibility and performance

- Preserve semantic labels, logical focus order, keyboard behavior, status
  text/icons, text scaling, and minimum 44 logical-pixel touch targets.
- Never communicate status by color alone. Maintain readable contrast and
  avoid neon colors for body text.
- Respect `MediaQuery.disableAnimations`; reduced motion must remove parallax,
  ambient loops, large transforms, and spring overshoot while retaining
  essential state feedback.
- Target smooth 60 fps on the Galaxy A35 and adapt naturally to higher refresh
  rates. Bound blur regions, repaint areas, shader work, image memory, and
  overdraw.

## Documentation and reporting

- Update `docs/IMPLEMENTATION_STATUS.md` and the visual audit/design documents
  when a checkpoint changes verified behavior or evidence.
- Report unverified claims honestly. Do not call a debug-signed APK a release,
  a local draft submitted, a prior test fresh, or an unpushed file backed up.
- Every checkpoint report must include current branch, latest commit SHA,
  remote/push status, validation results, and uncommitted file count.
