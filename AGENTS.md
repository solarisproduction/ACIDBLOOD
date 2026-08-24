# Project Operating Rules

This repository is worked through the Godot AI MCP workflow for Godot-related
inspection, edit, run, and validation tasks.

## QUIET EXECUTION

- Do not narrate routine progress, restate the task or plan after starting, or
  announce ordinary tool calls.
- Speak during execution only for a blocker, an unexpected conflict, or a
  decision requiring human input.
- Otherwise execute silently and return one concise final report.

## TOOL OUTPUT DISCIPLINE

- Do not dump large files, full repository diffs, or long validation logs into
  context unless required to diagnose a failure.
- Prefer targeted inspection: `git status --short`, `git diff --stat`,
  `git diff --name-only`, `rg`, and bounded `sed` ranges.
- Capture verbose validation output to a temporary file; on pass, inspect and
  report only the relevant summary. On failure, inspect the failure region
  first and expand only as needed.
- Do not repeatedly read content already inspected in the same session.

## SESSION BOOTSTRAP

Every new agent/session must begin by reading, in this order:

1. `AGENTS.md`
2. `PROJECT_RULES.md`
3. `docs/HANDOFF.md`

For efficient bootstrap, always read `AGENTS.md`, `PROJECT_RULES.md`, and
`docs/HANDOFF.md`. Read `docs/SYSTEM_BLUEPRINT.md` for implementation/runtime
work, `docs/ACIDBLOOD_DIRECTION.md` for gameplay/product/art work, and
`docs/ROADMAP.md` for planning/tooling work. Use targeted search in an
authority document whenever the task may depend on a decision stored there.

Before modifying anything, inspect:

- `git status --short`
- `git log -5 --oneline`
- `git remote -v`

Implementation and Git state are the factual authority if documentation
conflicts with reality. Documentation drift must be reported and corrected.

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
- Canonical behavioral CLI: `./tools/run_gdunit.sh --godot_binary "$GODOT" --headless --ignoreHeadlessMode -a res://tests/gdunit/`

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
- Keep writes inside the repository or `/private/tmp` unless the user
  explicitly requests another location.
- Preserve unrelated dirty files. Do not normalize the worktree by discarding
  unknown changes.

## AUTO-CHECKPOINT POLICY

- Normal infrastructure and maintenance tasks may commit and push automatically
  only after all objective validation gates pass.
- Gameplay, product, large-architecture, or ambiguous changes use REVIEW MODE:
  stop before commit and return the implementation for human review.
- Never force-push, run `git reset --hard`, use destructive rebase/checkout,
  delete unknown source files, commit failing validation, or amend an unrelated
  commit.
- After an automatic push, inspect the resulting GitHub Actions run.
- If CI fails unexpectedly, report the failure before speculative repair unless
  the task explicitly authorizes remediation.

## DECISION CAPTURE GATE

- Important approved, rejected, or deferred tools; engineering decisions;
  workflow rules; product principles; known limitations; and future
  capabilities must be preserved in the appropriate authoritative repository
  document. Do not rely on chat history as the durable record.

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
