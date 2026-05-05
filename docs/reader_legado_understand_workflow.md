# Reader x Legado Understand Workflow

## Purpose

Use this workflow for introductions, explanations, ownership questions, feasibility questions, and investigations.

Do not rerun Codebase Atlas for ordinary understanding work. Use the existing atlas unless the user explicitly asks for a full rebuild.

## Workflow

1. Preserve the user's question or symptom.
1. Open `docs/reader_legado_index.md`.
1. Choose the likely owning module and any boundary modules before inspecting code.
1. Read only the relevant module docs.
1. Inspect code, tests, docs, logs, config, or the Legado counterpart only when atlas context is not enough to answer accurately.
1. Treat `reader` as the source of truth. Use Legado only for the reference notes named in the selected module docs; feature parity is disabled unless the user explicitly asks for it.
1. Separate confirmed facts, hypotheses, unknowns, covered paths, and excluded paths.
1. If follow-up implementation is needed, recommend the change workflow.
1. Finish according to this delivery policy when files changed; otherwise state that no commit is needed: commit and push.
1. Update affected atlas docs if ownership, APIs, flows, risks, or module boundaries changed.

## Summary Format

- **Question**: What are we trying to understand?
- **Map**: Which modules and boundaries were inspected?
- **Facts**: What is confirmed?
- **Hypotheses**: What is plausible but not proven?
- **Unknowns**: What remains unclear?
- **Next Step**: No change needed, validate next, or use the change workflow.

If the next step edits files, provide a plain Before / After summary and wait for explicit user confirmation before editing.
