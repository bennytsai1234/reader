# Reader x Legado Validate Workflow

## Purpose

Use this workflow for checks, reviews, reproductions, verification, and risk assessment when the user is not asking for immediate implementation.

Do not edit files unless the user explicitly asks for a fix or implementation.

## Workflow

1. Preserve the validation question, expected behavior, or risk.
1. Open `docs/reader_legado_index.md`.
1. Choose the affected module and any boundary modules before inspecting code.
1. Read relevant module docs for scope, dependencies, downstream impact, key flows, and known risks.
1. Treat `reader` as the source of truth. Use Legado only for the reference notes named in the selected module docs; feature parity is disabled unless the user explicitly asks for it.
1. Calibrate validation scope: contracts, generated artifacts, tests, downstream users, and uncertain surfaces.
1. Run or inspect evidence needed for the user's validation question.
1. Report only what the evidence shows and what remains unresolved.
1. If a fix is needed, recommend the change workflow instead of silently editing files.
1. Finish according to this delivery policy when files changed; otherwise state that no commit is needed: commit and push.
1. Update affected atlas docs if ownership, APIs, flows, risks, or module boundaries changed.

## Summary Format

- **Before**: What was being checked, and what was uncertain or risky before validation?
- **After**: What the validation shows now, or what remains unresolved?

If validation recommends edits, provide a plain Before / After summary and wait for explicit user confirmation before editing.
