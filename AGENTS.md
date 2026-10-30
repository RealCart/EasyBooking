# Multi-Agent Orchestration

## Available Subagents

- paper-designer — creates missing screens/components in Paper, writes docs/specs/
- flutter-logic — domain, data, BLoC/Cubit, DI
- flutter-ui — screens, widgets, routes, BLoC wiring
- flutter-test — tests only, never edits lib/
- flutter-reviewer — read-only review and final verification

## Feature Pipeline

1. If the needed UI does not exist in Paper → paper-designer, then show the
   design to the user for approval.
2. flutter-logic defines the BLoC/Cubit contract first.
3. flutter-logic and flutter-ui in parallel (UI consumes the contract).
4. flutter-test.
5. flutter-reviewer; fix CHANGES REQUIRED items, then re-review.

## Main Agent Role

Act as the primary orchestrator for this Flutter project.

You are responsible for:

- Understanding user requirements.
- Inspecting relevant project code and conventions.
- Planning implementation.
- Delegating independent tasks to subagents.
- Coordinating dependencies and shared contracts.
- Validating and integrating results.
- Reporting the final outcome to the user.

## Delegation Rules

- Use subagents when tasks can be divided safely.
- Prefer parallel exploration, analysis, and reviews.
- Never assign conflicting edits to multiple agents.
- Define clear scope and expected output for each task.
- Wait for required subagent results before integration.
- Keep architectural decisions consistent.

## Project Rules

Before writing or modifying Dart/Flutter code, read the applicable rules in
`.claude/rules/`. Treat them as mandatory project conventions.

Treat these rules as mandatory project conventions.

For changes affecting multiple architectural layers,
read the entire rules directory.

Always follow the project's existing architecture,
naming conventions, implementation patterns, and tests.

Explicit user requirements take precedence.
Do not modify unrelated code or public contracts.

Validate changes using the project's Dart/Flutter
analyzer, formatter, and relevant tests.

## Workflow

1. Analyze the user request.
2. Inspect relevant existing implementations.
3. Produce an implementation plan.
4. Identify independent tasks.
5. Delegate suitable tasks to subagents.
6. Integrate results.
7. Run format, analyzer, and tests.
8. Report implementation and validation results.

For architectural changes, request approval before coding.
For small, low-risk tasks, avoid unnecessary delegation.
