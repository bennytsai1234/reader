# ReadBookController Decomposition Track

## Goal

Turn `ReadBookController` from a large all-in-one runtime into a composition of smaller reader-specific slices that can be iterated independently for a long time without breaking the reader.

This is intentionally a multi-phase task. Each phase must leave the reader shippable and fully covered by regression tests before the next phase begins.

## Why This Track Exists

Current pain points in the codebase:

- `ReadBookController` still owns too many responsibilities at once.
- Reader UI wiring, chapter navigation, viewport commands, TTS, source switch, settings, and session persistence all converge in one file.
- Small UI changes still require editing the main controller directly, which makes long-term iteration expensive.

## Phases

### Phase 1: Extract Chapter Navigation And Shell Interaction

Scope:

- Move chapter-navigation state and behavior out of `ReadBookController`.
- Move shell interaction state and behavior out of `ReadBookController`.

Target responsibilities:

- chapter pending state
- scrub preview state
- `jumpToChapter()`
- `nextChapter()`
- `prevChapter()`
- scrub handlers
- `toggleControls()`
- shell visual state that does not belong to content/session logic

Acceptance criteria:

- `ReadBookController` delegates chapter navigation and shell interaction instead of owning those implementations inline.
- Existing reader UI keeps using the same public controller API.
- Reader and settings regression tests still pass.

### Phase 2: Extract Reader Actions And Menu Wiring

Scope:

- Normalize tap-zone actions and shell-triggered reader actions.
- Reduce direct action dispatch logic inside `ReaderPage`.

Target responsibilities:

- tap-zone action execution
- menu-triggered reader commands
- shell command policy for pending navigation and transient viewport guards

Acceptance criteria:

- `ReaderPage` becomes thinner and mostly composes runtime/UI pieces.
- Reader interaction behavior remains unchanged.

### Phase 3: Extract Source-Switch / Bookmark / Exit Flow

Scope:

- Move non-core reading flows away from the main controller.

Target responsibilities:

- bookmark creation flow
- source switch orchestration
- exit/add-to-bookshelf flow

Acceptance criteria:

- Controller keeps only top-level orchestration and stable facade methods.
- Non-reading auxiliary flows become independently testable.

### Phase 4: Add Full ReaderPage Interaction Coverage

Scope:

- Add higher-level widget coverage around the composed reader page.

Target scenarios:

- shell toggle through content tap
- chapter drawer pending state
- slider pending lock
- selection interaction vs tap zones
- scroll/slide restore consistency after refactors

Acceptance criteria:

- UI wiring regressions are caught at page level instead of only controller level.

## Current Execution Slice

The current execution has completed **Phase 1**, completed the `ReaderPage`
action-dispatch and shell-composition portions of **Phase 2**, completed the
current controller-side slice of **Phase 3**, and has started adding targeted
coverage from **Phase 4**.

The current Phase 3 slice is intentionally limited to non-core auxiliary flows
that still lived inline in `ReadBookController`.

Current Phase 3 targets:

- extract bookmark creation flow out of `ReadBookController`
- extract add-to-bookshelf flow out of `ReadBookController`
- extract source-switch orchestration wrappers out of `ReadBookController`
- extract `ReaderPage` exit handling into a dedicated coordinator

Recent page-layer progress:

- `ReaderPage` now delegates tap-zone/menu action dispatch to a dedicated dispatcher
- `ReaderPage` now delegates exit/add-to-bookshelf flow to a dedicated coordinator
- `ReaderPage` now delegates shell scaffolding (`Scaffold`, menus, permanent info, dismiss scrim, drawer host) to a dedicated shell widget
- `ReaderPageShell` now pins the reader content with `Positioned.fill` so the content runtime owns the full reading viewport inside the shell stack
- `ReaderChaptersDrawer` now tracks provider updates directly so it can auto-scroll to the current or pending chapter even when the provider instance stays the same
- page-level widget coverage now includes shell wiring, exit flow through the real top-back shell entry, permanent info visibility, controls dismiss overlay, drawer auto-location, drawer pending-state lock, real content taps for shell toggle, `selectText` vs tap-zone interaction, bottom-slider driven chapter navigation, drawer-open to chapter-select end-to-end flow, and slide/scroll restore consistency

This keeps the public controller API stable while shrinking the main runtime
file and preserving existing regression coverage.
