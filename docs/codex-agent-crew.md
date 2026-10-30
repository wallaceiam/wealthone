# WealthOne Codex agent crew

This repository has four project-scoped Codex agents in `.codex/agents/`:

- `wealthone_legacy_auditor`: read-only map of the React Native behavior and stored data.
- `wealthone_swiftui_builder`: implements native SwiftUI views from an approved design and plan.
- `wealthone_data_migration`: owns native data models, persistence, legacy iCloud migration, and JSON import/export.
- `wealthone_reviewer`: read-only review for data loss, calculation regressions, migration safety, and feature gaps.

The project configuration allows up to three spawned agents at once. They inherit the parent session's model, tools, sandbox, and approval settings. Set the parent session's permissions before asking agents to work; role instructions alone do not create a separate security boundary.

Example request:

> Use `wealthone_legacy_auditor` to map the old history and goal calculation behavior. Then have `wealthone_data_migration` propose a migration design from that map. Keep both tasks read-only and summarize conflicts before editing anything.

For implementation, give agents non-overlapping file ownership and a shared interface before running them in parallel. Keep dependent work in sequence, and use `wealthone_reviewer` after changes are ready.
