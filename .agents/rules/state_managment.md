# State Management — BLoC, Cubit, Events, States, UI Lifecycle

> **Scope:** Mandatory project conventions derived from the provided Musium rule set. Follow existing contracts and user requirements. Do not refactor unrelated code merely to enforce these rules.
> **Source fidelity:** The “Existing project conventions” sections reproduce the user's original rules. “Added safeguards” sections are additional recommendations and must be applied only when compatible with the real repository.

## Existing project conventions

### BLoC / Cubit

- Use BLoC for event-based workflows and Cubit for simple state with direct commands. Preserve the approach already used by an existing module.
- Inject use cases through named `required` parameters. Do not call GetIt inside a BLoC/Cubit.
- Initialize state through `super(const ...State())`.
- Register BLoC events in the constructor through `on<Event>(_onAction)`.
- Declare asynchronous handlers as `Future<void>` and synchronous handlers as `void`. Do not use `void async`.
- Update state through `emit(state.copyWith(...))`.
- Use separate statuses for requests that run independently.
- Do not immediately reset success/failure to initial. Keep the result until the next meaningful action.
- Implement the required processing order for concurrent requests. A stale response must not overwrite the current result.
- For search, handle empty queries and BLoC closure while awaiting a result.
- Use debounce to delay execution; implement request cancellation and stale-response protection separately.
- After `await`, verify that the emitter and result are still valid before calling `emit`.
- In Cubit, expose public action methods. Do not create event classes or an event file.

### Events and states

- For each BLoC, create `<name>_bloc.dart`, `<name>_event.dart`, and `<name>_state.dart`.
- Include event/state files through `part` in the main file and use `part of` in the included files.
- Declare the base event as `sealed class ...Event extends Equatable` and concrete events as `final class`.
- Use `const` event constructors, `final` fields, and include the entire meaningful payload in `props`.
- Do not pass context, widgets, repositories, or UI callbacks in events.
- Declare state as `final class ...State extends Equatable`; use a `const` constructor and `final` fields.
- For a typical screen, use one state containing data, status, and an error. Do not replace an existing union-state approach outside the task scope.
- Use the statuses `initial`, `loading`, `success`, and `failure` if an equivalent enum does not already exist.
- Set initial values in the constructor. Use `const []` for empty collections.
- Include all fields that determine state equality in `props`.
- In `copyWith`, preserve unspecified fields through `value ?? this.value`.
- To clear a nullable field, add `reset<Field> = false`; the reset flag must take precedence over a supplied value.
- Clear an error through `resetError: true`, not `error: null`, when using this `copyWith` contract.
- When adding a field, update the constructor, `copyWith`, and `props` together.
- Do not mutate collections in an emitted state. Create a new list; use `List.unmodifiable` when publishing an externally supplied collection.

### UI, navigation and lifecycle

- Create BLoCs through `BlocProvider(create: ...)`; pass existing instances through `BlocProvider.value`.
- Use `BlocBuilder`/`BlocSelector` for rendering and `BlocListener` for navigation and notifications.
- In `buildWhen`/`listenWhen`, account for every field required by the corresponding UI or action.
- Do not initiate requests from `build`.
- Create owned controllers in lifecycle methods and release them in `dispose`/`close`.
- Retain subscriptions and cancel them when their owner is closed or disposed.
- Remove the same callback instance that was passed to `addListener`.
- After `await`, check `mounted` before accessing UI/context.
- Cancel timers and account for deferred callbacks when closing a screen.
- Do not close an externally supplied BLoC or dispose a shared singleton when one screen closes.

## Added safeguards

### Choosing and owning a controller

- Preserve the existing module's BLoC or Cubit approach. Introduce a new state manager only when a feature's requirements justify it.
- Do not put domain decisions in widgets, and do not put `BuildContext`, navigation, snack bars, dialogs, or concrete widget references in a BLoC/Cubit.
- Keep transient UI-only details (for example, whether a local panel is expanded) at the smallest appropriate presentation scope; do not create a domain use case for them.
- Keep controller ownership explicit: `BlocProvider(create:)` owns and closes what it creates; `BlocProvider.value` provides an existing instance and does not take ownership.

### Event design and async ordering

- Each event represents a meaningful user/system intent; use descriptive action names and typed, immutable payloads.
- If concurrent requests can overlap, explicitly choose a policy: latest-result-wins, sequential, droppable, or concurrent. Do not rely on incidental completion order.
- For latest-result-wins searches, track an active request/query/version (or use an already installed appropriate event transformer) so an older result cannot overwrite a newer result. Debounce only reduces event frequency; it does not guarantee result ordering or cancel in-flight work.
- Check `emit.isDone` in asynchronous Bloc event handlers after an `await` before emitting, where supported by the installed BLoC version. For Cubit, check `isClosed` before emitting after an `await`. Still guard against stale responses separately.
- Propagate meaningful cancellation, failure, and retry outcomes. Do not accidentally send a failure state from a cancelled obsolete request.
- Keep loading/error/data fields independent when requests can run independently (for example, search versus favorites) instead of one global status hiding other work.

### State immutability and copyWith

- `Equatable.props` must include all values that affect visible state, effects, or comparisons.
- Do not mutate a list/set/map owned by an emitted state. Publish a new collection (and `List.unmodifiable` where an external caller might still hold a reference).
- `copyWith` must preserve omitted fields. For intentionally clearing nullable fields, use the project's explicit `reset<Field>` contract; `reset<Field>` wins when both reset and value are provided.
- `state.copyWith(error: null)` does _not_ clear `error` under a `value ?? this.value` implementation. Use `resetError: true`.
- When introducing a state field, update its default, constructor, `copyWith`, `props`, UI selectors/buildWhen/listenWhen, and tests together.

### Effects and widget lifecycle

- Use `BlocBuilder`/`BlocSelector` only for rendering; use `BlocListener` for one-off UI effects such as navigation and notifications. Avoid triggering side effects from builders.
- Do not start fetches inside `build()`. Trigger them from BLoC creation, `initState`, or an intentional user action according to existing project patterns.
- Guard accesses to widget `context` after `await` with `mounted`. Cancel subscriptions/timers, release owned controllers, and unregister the exact listener callback instance.
- UI should render `initial`, `loading`, `success`, and `failure` states appropriately, including an empty-success result distinct from a failure.
- If `buildWhen` or `listenWhen` is customized, ensure every dependent state field is considered; an optimization must not make behavior stale.

### State management completion check

Check event registration, expected state transitions, `props`, nullable clearing, stale responses, closure after `await`, subscription cleanup, and controller ownership.
