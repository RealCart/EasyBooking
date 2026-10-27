# Testing and Quality Gates — Flutter / Dart

> **Scope:** Mandatory project conventions derived from the provided Musium rule set. Follow existing contracts and user requirements. Do not refactor unrelated code merely to enforce these rules.
> **Source fidelity:** The “Existing project conventions” sections reproduce the user's original rules. “Added safeguards” sections are additional recommendations and must be applied only when compatible with the real repository.

## Existing project conventions

### Tests

- Place tests in `test/`, mirroring the module structure, and use the `_test.dart` suffix.
- Use existing testing tools. Inject fakes/mocks through constructors.
- Do not use real network services or user storage in unit tests.
- Name tests after the subject, condition, and expected result.
- Test public behavior, failures, and meaningful boundaries rather than implementation internals.
- For modified asynchronous logic, test result ordering, repeated requests, and closure while awaiting a result.
- In widget tests, prepare dependencies and test a real screen scenario.
- Release resources created by tests and clean up DI registrations.

### Task completion

- Remove unfinished stubs, unused imports, and accidental unrelated changes.
- Check dependency injection, DI registrations, mapping, error handling, and nullable-field resets.
- Check asynchronous operation ordering and resource ownership.
- Format modified Dart files, run the analyzer, and run the tests required for the change.
- Report actual verification results. Identify existing failures and checks that were not run separately.

## Added safeguards

### Test locations and isolation

- Mirror production feature structure under `test/features/<feature>/` without reproducing irrelevant empty directories.
- Use the test frameworks and fake/mock libraries already present in `pubspec.yaml`. Do not add a new mocking or BLoC test package without a concrete need.
- Keep unit tests deterministic and independent of real internet, production credentials, user storage, device-dependent state, and actual clock time. Inject fakes or controllable implementations.
- Reset GetIt test registrations/scopes and cancel controllers, streams, timers, and subscriptions in teardown. Avoid test order dependencies.

### Coverage by layer

- **Usecases:** success and `Failure` branches, parameter forwarding, boundary validation, and sequence of business operations where relevant.
- **Repositories:** data source selection, `Model.toEntity()` mapping including nested and list values, local/remote coordination, preservation of typed failures, malformed responses, and intentional fallback policies.
- **Remote/local sources:** endpoint parameters, request body/options/cancellation forwarding, JSON shape validation, missing keys, storage read/write/absence semantics, and any returned write-success flag.
- **BLoC/Cubit:** initial state, loading/success/failure, exact event-to-state sequences, independent operation statuses, retries, clearing nullable errors, immutable collections, stale-result protection, and closure during an awaited operation.
- **DI:** factory vs singleton lifetimes, async readiness when applicable, and disposal ownership.
- **Widgets:** real interactions and visible loading/empty/error/success states; navigation and notifications using the existing router/localization setup.
- **Integration tests:** focus on a small set of critical end-to-end scenarios, using test environments and deterministic service doubles where practical.

### Async and race-condition tests

- For overlapping requests, control completion order in the test: complete request B before A and verify A does not replace B when latest-result-wins is required.
- Test an operation that completes after BLoC/Cubit closure and verify no invalid emission or unhandled exception occurs.
- Verify that an async storage write is awaited when a subsequent action relies on it.
- Use fake clocks or controllable timers for debounce/retry where supported; avoid fragile real-time sleeps.

### Quality gates

- Before work, inspect `pubspec.yaml` and `analysis_options.yaml`, relevant test utilities, and existing tests for the affected feature.
- Format only changed Dart files using `dart format <changed paths>`; avoid unrelated formatting diffs.
- Run `flutter analyze` and relevant `flutter test` scopes; run the complete suite when change scope and environment warrant it. Use `dart analyze` if that is the project's established workflow.
- Consider `dart format --output=none --set-exit-if-changed <paths>` as a non-mutating formatting check.
- Do not remove, skip, or suppress failing tests to force green CI. Distinguish new failures from pre-existing failures based on actual evidence.
- Report the exact verification commands and their observed outcomes. If SDK, dependencies, device, or credentials are unavailable, state which checks could not run; do not claim success.

### Delivery checklist

- No unfinished placeholders, dead code, unused imports, accidental unrelated changes, or untracked API/serialization key changes.
- DI registrations are valid; repository methods map models/failures correctly; nullable resets and concurrency rules are correct.
- Documentation and tests reflect changed behavior.
- The completion report identifies changed files, what was tested, failing/pre-existing checks, limitations, and any compatibility or migration risks.
