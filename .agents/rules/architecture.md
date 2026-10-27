# Architecture — Layers, Usecases, Repositories, Storage, GetIt

> **Scope:** Mandatory project conventions derived from the provided Musium rule set. Follow existing contracts and user requirements. Do not refactor unrelated code merely to enforce these rules.
> **Source fidelity:** The “Existing project conventions” sections reproduce the user's original rules. “Added safeguards” sections are additional recommendations and must be applied only when compatible with the real repository.

## Existing project conventions

### Preparation

- Read `pubspec.yaml`, `analysis_options.yaml`, project instructions, and the files in the affected module.
- Locate the existing `Usecase`, `Either`, `Failure`, storage abstractions, HTTP clients, and DI registrations. Reuse them; do not create duplicates.
- Use installed dependencies and supported Dart syntax. Do not add libraries or code generation unless required by the task.
- Change only code related to the task. Preserve the user's existing changes.

### Directory structure and dependency direction

- Place each feature in `lib/features/<feature>/` with the necessary `data`, `domain`, and `presentation` layers.
- Place shared components in `lib/core`. Do not import from `features` into `core`.
- Use `domain/repository` for contracts, `data/repository` for implementations, `domain/usecases` for use cases, and `domain/entity` for entities.
- Use `data/models`, `data/parsers`, `data/sources/remote`, and `data/sources/local` for their respective responsibilities.
- Place screens in `presentation/screens`, widgets in `presentation/widgets`, and UI controllers in `presentation/controllers`.
- Place each BLoC in `presentation/bloc/<name>_bloc/` alongside its events and state.
- Do not create empty layers or directories. Reuse the directories of an existing module; do not introduce parallel `screen/screens` or `widget/widgets` directories.
- For data operations, follow this flow: UI → BLoC/Cubit → Usecase → Repository → Data source.
- The domain layer must not depend on data, presentation, Dio, GetIt, or Flutter UI.
- Do not expose JSON, `Response`, data models, or external SDK objects in UI state.
- Handle local visual state in presentation without introducing unnecessary repositories or use cases.

### Usecase pattern

- Use the shared contract `abstract interface class Usecase<Result, Params>` with the method `Result call(Params params)`.
- The first generic parameter must specify the complete return type, including `Future` and `Either`; the second specifies the input parameters.
- Name each concrete class `<Action>Usecase` and declare it with `implements Usecase<...>`.
- Do not create a separate interface and `Impl` for every use case unless required by the task or an existing contract.
- Each use case must perform one operation.
- Inject the repository through the constructor. For a single dependency, use a positional parameter and a `const` constructor.
- Return `Future<Either<Failure, Result>>` for operations with expected failures.
- Use `NoParams` when there is no input. For multiple related inputs, define an immutable `<Action>Params` class alongside the use case.
- Do not pass parameters through untyped Maps or Lists.
- Perform shared business validation and input transformations in the use case; do not duplicate them across screens.
- Return the Future directly for simple delegation. Add `async/await` when processing results, sequencing operations, or catching exceptions.
- Do not access GetIt, Dio, storage implementations, UI, or navigation from a use case.

### Repository pattern

- Declare the contract as `abstract interface class <Feature>Repository` and the implementation as `<Feature>RepositoryImpl implements <Feature>Repository`.
- Inject data sources through named `required` constructor parameters and store them in private `final` fields.
- Return entities and primitives wrapped in `Either`; do not return data models or transport responses.
- Perform model-to-entity mapping and local/remote coordination in the repository implementation.
- Return success through `Either.right` and expected failures through `Either.left`.
- Preserve the type of an existing `Failure`; do not wrap it again in `UnexpectedFailure`.
- Check the type of a transport error's payload. Do not use an unchecked `error as Failure` cast.
- Do not turn request or parsing failures into successful empty lists.
- Do not place `BuildContext`, `emit`, navigation, or UI callbacks in repositories.

### Data sources and HTTP

- Use interface/implementation pairs: `ItemsRemote` / `ItemsRemoteImpl`, `ItemsLocal` / `ItemsLocalImpl`.
- Keep a source contract and its small implementation in the same file.
- Inject HTTP clients, SDKs, and storage through constructors. Reuse the existing shared client abstraction.
- Limit a source to external service calls, reads/writes, and parsing external formats.
- Return models or primitives. Construct `Either` at the repository boundary.
- Centralize URL settings, headers, timeouts, and transport error handling.
- Forward every parameter declared by the API: query, body, options, cancellation, and callbacks. Do not silently ignore arguments.
- Validate JSON structure before accessing fields, indexing collections, or casting types.
- Move complex response parsing into a parser within the relevant feature.
- Do not add `try/catch` blocks that only rethrow an exception without doing anything else.
- Place test fakes and mocks in `test/`, not in production sources.

### Entities, models, mapping

- Name domain entities `<Name>Entity` and data models `<Name>Model`.
- Use `const` constructors, named parameters, and `final` fields.
- Use `Equatable` for entity value equality; include all meaningful fields in `props`.
- Do not add UI controllers, context, callbacks, or external SDK objects to entities.
- Preserve semantic types: `Duration`, `DateTime`, and numbers. Handle display formatting separately.
- Keep JSON serialization in the data layer.
- Implement model-to-entity conversion as a `toEntity()` method on the model. Convert nested models through their own `toEntity()` methods.
- Convert model lists in the repository using `map(...).toList()`.
- Add `fromJson`, `toJson`, `fromEntity`, and `copyWith` only when required by actual operations.
- Follow the project's existing serialization approach. Do not introduce a second generation mechanism or parallel DTOs for the same task.

### Failure and Either

- Reuse the shared `Failure` hierarchy and the project's `Either` type.
- When creating the hierarchy, declare the base `Failure` as `sealed` and concrete failures as `final`.
- Distinguish connection, timeout, server, validation, storage, and unexpected failures when the distinction affects handling.
- Preserve meaningful error codes and data.
- Do not display `exception.toString()` or stack traces to users. Send technical details to logs.
- Do not use a null payload to identify the branch of a custom `Either`.
- Do not assume that `fold` awaits asynchronous callbacks. Follow its contract and explicitly await asynchronous work.
- Do not continue the success path after handling a failure.

### Local storage

- Use a storage interface and an implementation with the `Impl` suffix.
- Obtain the storage library through a constructor or an asynchronous creation factory.
- Declare keys centrally in `StorageKeys`.
- Do not hide asynchronous writes behind `void`. Return a Future and await completion when the write affects subsequent actions.
- If the library returns a boolean indicating write success, preserve and handle that result.
- Define missing-key behavior explicitly. Use a nullable result when absence must be distinguished from false, zero, or an empty string.
- Serialize feature models in the feature's local source, not in the shared preferences wrapper.
- Do not access the storage library directly from UI or use cases.

### GetIt and dependency injection

- Use `AppDependencies` as the single composition root.
- Split registration into private methods for storage, clients, sources, repositories, use cases, BLoCs, and the router.
- Register repositories, sources, and storage under their interfaces; register use cases under their concrete classes when no separate contract exists.
- Use `registerLazySingleton` for shared services, sources, repositories, and stateless use cases when their lifetime matches the application.
- Use `registerFactory` for screen BLoCs/Cubits.
- Use `registerSingletonAsync` for asynchronous dependencies; declare registration dependencies through `dependsOn`.
- Await `allReady()` before using asynchronous dependencies.
- Initialize DI once per application launch. In tests, use isolated registrations and clean them up afterward.
- Allow GetIt lookups only in the composition root and at BLoC/Cubit creation sites. Pass dependencies to all other objects through constructors.
- Assign resource disposal to a single owner. In a GetIt dispose callback, dispose the supplied instance; do not perform another lookup.
- Do not duplicate a GetIt singleton with a static singleton inside its implementation.

### Navigation and shared resources

- Reuse shared colors, typography, themes, and asset paths. Follow the existing localization approach.
- Centralize routes and their names. Do not navigate from domain or data layers.

## Added safeguards

### Layer dependency invariants

- Imports must respect `presentation → domain ← data`: `presentation` uses domain abstractions; `data` implements domain contracts; `domain` has no dependency on either outer layer.
- Shared `lib/core` code must not depend on feature implementations. Avoid direct imports of another feature's `data/` or `presentation/` internals. If features must communicate, use an explicit domain-facing contract or application-level coordinator rather than reaching across layers.
- Add a Usecase when the operation belongs to application/business logic. Keep purely local widget toggles or animations in presentation, as required by the original rules.
- Search for existing classes and registrations before adding a new interface, model, or abstraction. New abstractions need a real use, not hypothetical future consumers.

### Usecase contract details

- Honor the shared project's generic signature exactly: `Usecase<Result, Params>` and `Result call(Params params)`. `Result` is the *full* declared type (for example, `Future<Either<Failure, List<ItemEntity>>>`).
- For a no-argument operation, use the existing `NoParams` type and pass its project-defined instance/value; do not invent a second `NoParams`.
- Params should be immutable value carriers; validate required business invariants at the correct use-case/domain boundary, without duplicating the same validation in multiple screens.
- Preserve typed failures returned by the repository. A simple delegation should not wrap or reinterpret `Either` unnecessarily.
- Business side effects involving multiple steps should have an intentional order and explicitly defined failure behavior. Do not silently perform only some requested writes when the operation implies atomicity.

### Repository consistency

- Specify for each repository method whether it reads remote, reads local, caches a response, or coordinates local and remote. Preserve the established source-of-truth and freshness strategy.
- Do not silently convert network, parsing, permission, or cache failures into success. If a fallback is intentional, document the fallback policy and return semantics.
- Catch external exceptions at the established boundary and convert them to the shared `Failure` hierarchy only there, preserving existing failures and useful error metadata.
- Avoid catch-all exception wrappers that make cancellation or expected failures indistinguishable from programming defects.
- Keep transport-specific types (`Response`, SDK payloads, JSON, `Model`) out of domain contracts and UI state.

### Remote sources and parsing

- Validate response shape before casts or indexing: nullability, collection type, required keys, enum values, and numeric conversions.
- Apply API-provided pagination/query/filter/cancellation parameters consistently at each boundary. Do not drop `CancelToken`, options, headers, callbacks, or body values when forwarding.
- Use the existing shared HTTP client for headers, auth, base URLs, transport errors, and timeouts; do not create an independent client without necessity.
- Keep parsers deterministic and free of UI and navigation effects.

### Local storage and caching

- Declare keys in `StorageKeys` and preserve existing keys; key renames require a migration or intentional data-loss decision.
- Define missing-key semantics, default values, expiry/freshness, and failure propagation for each stored value where relevant.
- Keep sensitive credentials in the storage mechanism already approved for sensitive data, not automatically in ordinary shared preferences. Do not change storage products without a specific requirement.
- On async writes, await completion when following actions assume persisted data. Preserve `bool` write status if exposed by the underlying API.
- Feature serialization lives in its `data/sources/local` implementation or associated parser/model—not in generic storage wrappers.

### GetIt and lifecycle

- `AppDependencies` is the single app-level composition root. Keep its registrations arranged by dependency order: primitives/storage/clients → sources → repositories → usecases → presentation factories/router.
- Register each contract once in a scope; duplicate registrations and hidden static singletons require explicit justification.
- Await asynchronous registrations' `allReady()` before the corresponding dependency is accessed, and model required initialization dependencies with the project's supported GetIt APIs.
- Factories create independent BLoCs/Cubits. Their owners (typically `BlocProvider(create:)`) are responsible for closing them. Do not dispose global services or externally owned BLoCs from a screen.
- Use explicit dependency injection in domain/data constructors. A GetIt lookup is allowed only in the composition root and at designated BLoC/Cubit creation sites.
- In tests, use isolated GetIt scopes/instances or reliably reset registrations; always release resources.

### Architectural acceptance check

For each cross-layer change, verify: public contract preserved; parameter forwarding complete; `Model.toEntity()` performed at repository boundary; `Either` branches mapped correctly; DI registration and lifecycle correct; local and remote failure semantics preserved.
