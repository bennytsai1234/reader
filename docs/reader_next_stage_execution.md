# Reader Next-Stage Execution

## Goal

This round focuses on stabilizing the basic reader after the previous UI and runtime cleanup. The implementation scope is intentionally limited to two items that still create avoidable regressions:

1. Make `ReaderPrefsRepository` the single source of truth for reader-specific settings.
2. Unify chapter switching behind one pending-aware navigation path.

The larger `ReadBookController` split is still necessary, but it is treated as a follow-up after these two sources of instability are removed.

## Scope In This Round

### 1. Reader preference source unification

Problems in the current code:

- `ReaderPrefsRepository` already owns active reader prefs used by runtime and reader UI.
- `SettingsProvider` still loads and stores overlapping reader prefs, which leaves a second state source alive.
- `OtherSettingsPage` still reads `showAddToShelfAlert` from `SettingsProvider`, while the reader runtime already reads it from `ReaderPrefsRepository`.

Implementation plan:

- Keep reader-specific persistence inside `ReaderPrefsRepository`.
- Remove duplicated reader-pref state from `SettingsProvider` when the app no longer reads it directly.
- Update settings pages that still depend on duplicated reader-pref fields to read/write `ReaderPrefsRepository` directly.
- Preserve preference-key fallback in `ReaderPrefsRepository.load()` so existing installs keep their settings.

Reader-pref fields covered in this round:

- `textFullJustify`
- `selectText`
- `showReadTitleAddition`
- `readBarStyleFollowPage`
- `showAddToShelfAlert`

Out of scope for this round:

- Reworking every global setting around the reader.
- Removing legacy preference keys.
- Removing `AppConfig.readerPageAnim` usage everywhere.

### 2. Unified chapter navigation pending flow

Problems in the current code:

- Drawer chapter taps have a local pending state.
- Bottom slider scrub, previous/next chapter buttons, and tap-zone chapter actions do not share that same pending flow.
- `onScrubEnd()` goes straight to `jumpToChapter()` with no explicit reentry lock.

Implementation plan:

- Add an explicit pending chapter-navigation state to `ReadBookController`.
- Route `jumpToChapter()`, `nextChapter()`, `prevChapter()`, and scrub-end chapter changes through one internal navigation helper.
- Make chapter-navigation UI respect the same pending state:
  - drawer item taps
  - bottom chapter slider
  - previous/next chapter buttons
  - tap-zone chapter actions
- Show the target chapter as pending while the transition is in flight and block reentry.

Out of scope for this round:

- Full controller extraction into a dedicated navigation coordinator.
- Non-UI chapter transitions unrelated to the explicit chapter-navigation path.

## Acceptance Criteria

### Preference source

- Reader-specific settings listed above are no longer owned by `SettingsProvider`.
- `ReadingSettingsPage` and `OtherSettingsPage` both read/write the same reader-pref source.
- Reopening the app restores the same reader-pref values as before.

### Chapter navigation

- Drawer, slider, and prev/next buttons all share one pending chapter-navigation state.
- While a chapter change is pending, duplicate chapter-navigation submissions are ignored.
- Pending chapter target is visible in chapter-navigation UI.

### Regression coverage

- Add settings-page coverage for `showAddToShelfAlert`.
- Add controller/widget regression coverage for the pending chapter-navigation path.
