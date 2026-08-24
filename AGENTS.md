# Project Operating Rules

This repository must be worked through the Godot AI MCP workflow for any
Godot-related inspection, edit, run, or validation task.

Required behavior:

- inspect the project in the Godot editor when the task touches scenes, nodes,
  runtime behavior, or parse/runtime validation
- use the Godot AI MCP tools for file reads, script inspection, scene changes,
  and project runs whenever they are available
- do not rely on raw code edits alone for Godot work when the engine can
  validate the change directly
- validate gameplay and parse state in-engine before declaring a change done

If a task can be done entirely outside Godot, still prefer the engine when the
project state, parse state, or runtime behavior matters.
