# Code Style — Dart / Flutter

> **Scope:** Mandatory project conventions derived from the provided Musium rule set. Follow existing contracts and user requirements. Do not refactor unrelated code merely to enforce these rules.
> **Source fidelity:** The “Existing project conventions” sections reproduce the user's original rules. “Added safeguards” sections are additional recommendations and must be applied only when compatible with the real repository.

## Existing project conventions

### Naming and formatting

- Use `snake_case` for files, `UpperCamelCase` for types, and `lowerCamelCase` for methods, fields, and constants.
- Prefix private members with `_`. Name UI callbacks with `on`: `onPressed`, `onSelected`.
- Use role-specific suffixes: `Usecase`, `Repository`, `RepositoryImpl`, `Remote`, `RemoteImpl`, `Local`, `LocalImpl`, `Model`, `Entity`, `Bloc`, `Cubit`, `Event`, `State`.
- Do not prefix interfaces with `I`. Do not mix `Usecase` and `UseCase`.
- Name operations after their actions: `LoadItemsUsecase`, `LoadItemsEvent`, `_onLoadItems`.
- Explicitly declare field, parameter, and return types. Use type inference for obvious local values.
- Use `final` for values that are not reassigned and `const` for constant objects and constructors.
- Store dependencies in private, explicitly typed `final` fields.
- Place required named parameters before optional named parameters, including `super.key`.
- Use `@override` for overrides and single quotes unless another quote style avoids escaping.
- Group imports in this order: `dart:`, external packages, application package. Sort imports alphabetically within each group.
- Use `package:` imports for application code and relative filenames for `part` / `part of`.
- Format modified Dart files with `dart format` using the project configuration. Do not reformat the entire project as an unrelated change.
- Do not suppress fixable analyzer diagnostics with `ignore`.

### UI code organization

- Screens must compose UI, render state, and dispatch events. Reusable widgets receive data and callbacks through constructors.
- Use `StatelessWidget` when local state and lifecycle management are unnecessary.

### Logging and comments

- Use the project's logger or `dart:developer.log`, not `print`.
- For unexpected errors, retain the error object and stack trace. Do not log secrets or sensitive payloads.
- Restrict detailed network logging to the mode intended for it.
- Comment on reasons and constraints. Do not leave old implementations commented out.

## Added safeguards

### Naming and API clarity

- Preserve established spellings exactly: `Usecase` is not interchangeable with `UseCase`.
- Prefer `is`, `has`, `can`, `should` for boolean names when that makes semantics clearer.
- Public names should describe domain meaning; avoid generic `Manager`, `Helper`, `Utils`, `Data` unless the code genuinely has that responsibility.
- Name asynchronous methods after the operation (for example, `loadItems`), not merely the fact that they return a Future.
- Do not rename a public class, API method, file, serialization key, or persisted storage key just to conform to a naming preference. Treat migrations and compatibility as separate tasks.

### Types and null safety

- Model absence explicitly with nullable types only when absence is a valid domain state. Do not use arbitrary empty strings, zeros, or empty lists as failure sentinels.
- Prefer typed arguments/results over `dynamic`, unchecked casts, untyped maps, and `late` variables whose initialization is not guaranteed.
- Use `!` only when non-nullability is guaranteed by a documented invariant. Otherwise validate or branch explicitly.
- Use `required` named parameters for mandatory public API inputs, except for the existing single-dependency positional `Usecase` constructor convention.
- Avoid unnecessary `async` wrappers when an existing Future can be returned directly.

### Formatting and generated code

- Follow `analysis_options.yaml` as the formatter and lint source of truth. Do not invent a separate line-width configuration in prose.
- Let `dart format` decide whitespace, wrapping, and trailing commas; do not hand-fight formatter output.
- Never manually modify generated `*.g.dart`, `*.freezed.dart`, or other generated sources when their generator owns them; modify source annotations/configuration and regenerate only if the project already uses that generator.
- Keep lint suppressions narrowly scoped and explained when unavoidable; do not hide an actual runtime issue using analyzer ignores.

### Readability and documentation

- Prefer guard clauses when they reduce branching. Do not split simple, cohesive code solely to meet an arbitrary line-count limit.
- Write comments explaining non-obvious constraints, side effects, or decisions—not a literal restatement of the code.
- When changing externally visible behavior or a public API, update relevant Dart documentation and tests.
- Keep formatting changes restricted to touched files unless a formatting-only task is explicitly requested.

### Example names (illustrative, not a new project API)

```text
load_items_usecase.dart      LoadItemsUsecase
items_repository.dart        ItemsRepository
items_repository_impl.dart   ItemsRepositoryImpl
items_remote.dart            ItemsRemote / ItemsRemoteImpl
items_local.dart             ItemsLocal / ItemsLocalImpl
items_bloc.dart              ItemsBloc
items_event.dart             ItemsEvent / LoadItemsEvent
items_state.dart             ItemsState
item_model.dart              ItemModel
item_entity.dart             ItemEntity
```
