# Project Operating Rules

This repository is worked through the Godot AI MCP workflow for Godot-related
inspection, edit, run, and validation tasks.

## Required reading order

Before changing Godot scenes, scripts, resources, runtime behavior, or
validation:

1. `README.md`
2. `AGENTS.md`
3. `PROJECT_RULES.md`
4. `docs/ACIDBLOOD_DIRECTION.md`
5. `docs/SYSTEM_BLUEPRINT.md`
6. `docs/HANDOFF.md`
7. `docs/ROADMAP.md`
8. `docs/ASSET_CONTRACT.md` when working on art/imports

If a task is only about code or text outside Godot, still read the project docs
when project state, parse state, runtime behavior, or validation matter.

## Authority map

- `README.md` — human entry point
- `AGENTS.md` — operational contract for agents
- `PROJECT_RULES.md` — engineering and product invariants plus approved tooling
- `docs/ACIDBLOOD_DIRECTION.md` — product, design, and art north star
- `docs/SYSTEM_BLUEPRINT.md` — current implemented technical truth
- `docs/ROADMAP.md` — only unfinished NOW / NEXT / LATER / DEFERRED work
- `docs/HANDOFF.md` — compact current-state bridge between sessions
- `docs/ASSET_CONTRACT.md` — 3D asset and import contract

## Canonical tooling

- Canonical MCP: Godot AI MCP
- Canonical local validation: `bash tools/validate.sh`
- Canonical behavioral CLI: `./addons/gdUnit4/runtest.sh --godot_binary "$GODOT" --headless --ignoreHeadlessMode -a res://tests/gdunit/`

Use the MCP for scene inspection, runtime checks, and project runs whenever it
is available. Use the local validator for the authoritative headless pass.

## Editing rules

- Inspect before editing.
- Do not invent product names, product-facing vocabulary, enemy types, tower
  families, status families, or progression systems.
- If a workaround is necessary, prefer the official documented path first.
  Label any workaround clearly in code or docs, and remove it once the
  supported path works.
- Do not change gameplay just to satisfy tooling.
- Do not refactor outside the requested scope.
- Keep changes small, legible, and reversible.

## Git and workspace rules

- Do not run destructive git operations such as `git reset --hard`,
  `git checkout --`, or blind file deletion outside an explicitly requested
  cleanup.
- Do not commit or push automatically unless the user asks for it.
- Keep writes inside the repository or `/private/tmp` unless the user
  explicitly requests another location.
- Preserve unrelated dirty files. Do not normalize the worktree by discarding
  unknown changes.

## Validation contract

- Validate gameplay and parse/runtime state in-engine before declaring a
  change complete.
- When scenes, nodes, or runtime behavior are involved, validate through the
  editor/runtime path through Godot AI MCP as part of the task.
- End each task with the actual validation results that were run, the files
  changed, and any remaining gaps or risks.
- If docs or tooling changed, note the documentation impact explicitly.

## Product and workaround policy

- Product decisions are out of scope unless the user explicitly requests them.
- Official documentation and supported tooling come before custom workarounds.
- Workarounds are temporary. Keep them visible, local, and easy to remove.
- If a workaround becomes unnecessary, remove it in the same slice or explain
  why it must remain.
