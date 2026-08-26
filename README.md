# ACIDBLOOD

**3D Tower Defense + Roguelite Card Draft Foundation**
*Godot 4.7.1 • GDScript • Vendored GdUnit4 behavioral pilot*

**ACIDBLOOD** is a playable Phase 1 foundation validating a tower-defense loop
enhanced by deterministic roguelite card drafts.

ACIDBLOOD is an alternate late-1980s industrial contamination game: analog
machines, chemical infrastructure, CRT-era systems, biological corruption, and
a city that rotted while still standing. Naming, visual direction, and future
player-facing work should follow
[`docs/ACIDBLOOD_DIRECTION.md`](docs/ACIDBLOOD_DIRECTION.md).

---

## 🎮 Gameplay Overview

**Core Loop:** `Command` → `Operations` → `Battle` → `Report` → `Operations`

- **Guardian**: Player-controlled character with auto-attack weapon
- **Defensive line**: Guardian starts active with four empty T1–T4 slots; the
  Stage 1 NEW TURRET draft can install the existing Impact Cannon
- **Deterministic Waves**: Enemy spawns follow pre-authored `StageData` with reproducible timing
- **Card Draft**: On level-up, pause and choose 1 of 3 deterministic eligible
  cards, within a 20-choice run budget
- **Persistent Progression**: Earn salvage to buy persistent upgrades between runs

---

## 📋 Requirements & Running

| Requirement | Version |
|-------------|---------|
| Godot Engine | **4.7.1** |
| Platform | Windows, Linux, macOS (desktop tested) |
| Main Scene | `res://shell/home.tscn` |

**Run the game:**
```bash
godot --path .
# Or open project.godot in Godot editor and press F5
```

---

## ✅ Tests (Headless)

Canonical local validation runs the 94-check suite, the 44-case GdUnit4
behavioral pilot, and runtime smoke stages:

```bash
bash tools/validate.sh
```

The shared 94-check suite lives in [`tests/run_tests.gd`](tests/run_tests.gd) and
[`tests/acidblood_suite_runner.tscn`](tests/acidblood_suite_runner.tscn).

---

## 🛠️ Tools

### Generate Stage Data
Regenerates all 30 `StageData` resources (stages 1–2 hand-authored, 3–30 procedural):
```bash
godot --headless --path . --script res://tools/gen_stages.gd
```

### Balance Report
Prints all balance-relevant numbers (guardian stats, enemies, turrets, cards, stages):
```bash
godot --headless --path . --script res://tools/balance_report.gd
```

---

## 🏗️ Architecture

| Layer | Path | Description |
|-------|------|-------------|
| **Autoload** | `autoload/game.gd` | Singleton for scene flow (`start_stage()`, `end_run()`, `change_scene()`) |
| **Core Rules** | `core/*.gd` | Pure logic, `RefCounted`, no `Node` dependency (e.g., `draft.gd`, `targeting.gd`, `det_rng.gd`) |
| **Data Types** | `data/types/*.gd` | Resource classes (`EnemyData`, `TurretData`, `CardData`, `StageData`, etc.) |
| **Runtime** | `game/*.gd` | `Node3D` actors (`battle.gd`, `enemy.gd`, `turret.gd`, `guardian.gd`) |
| **Shell UI** | `shell/*.gd` | Screens (`home.gd`, `campaign.gd`, `result.gd`) |
| **Tests** | `tests/acidblood_suite_runner.tscn`, `tests/run_tests.gd`, `tests/gdunit/` | 94-check core suite + 44-case GdUnit4 behavioral pilot |
| **Tools** | `tools/*.gd` | Data pipeline scripts |

**Data-Driven Content:** 72 `.tres` files managed via [`core/catalog.gd`](core/catalog.gd):
- 5 enemies, 3 turrets, 20 cards, 30 stages, 6 branches, 3 perm upgrades, 1 guardian

---

## 🔢 Determinism

- **RNG**: [`core/det_rng.gd`](core/det_rng.gd) provides seeded RNG with derived salts per purpose (`"waves"`, `"draft"`)
- **Physics**: Fixed 60 Hz (`engine.physics_ticks_per_second = 60`)
- **Reproducibility**: Same seed → identical wave spawns and card offers

---

## 📊 Status

Core loop, deterministic waves, draft, progression, and tests are in place.
The current backlog lives in [`docs/ROADMAP.md`](docs/ROADMAP.md).

---

## 📝 Conventions

- **Scripts**: `snake_case.gd` (e.g., `wave_director.gd`, `modifier_set.gd`)
- **Scenes**: `PascalCase.tscn` (e.g., `BattleHUD.tscn`, `SpawnGroup.tscn`)
- **Stats**: String paths validated by `stat_registry.gd`:
  - `"guardian.damage"`, `"guardian.move_speed"`
  - `"turret.bolt.range"`, `"turret.cannon.damage"`
  - `"fortress.max_hp"`
- **Signals**: Used for UI updates (e.g., `BattleHUD` listens to battle events)
- **No coupling**: Core layer has zero `Node` dependencies; runtime layer depends on core + data

---

## 📄 Documentation

- [`AGENTS.md`](AGENTS.md) — mandatory operating rules for future sessions
- [`docs/ACIDBLOOD_DIRECTION.md`](docs/ACIDBLOOD_DIRECTION.md) — product identity, world, visual language, and naming direction
- [`docs/ASSET_CONTRACT.md`](docs/ASSET_CONTRACT.md) — GLB production specs for future asset replacement
- [`docs/SYSTEM_BLUEPRINT.md`](docs/SYSTEM_BLUEPRINT.md) — technical design overview
- [`docs/HANDOFF.md`](docs/HANDOFF.md) — developer handoff notes
- [`docs/ROADMAP.md`](docs/ROADMAP.md) — single living backlog for future work

---

**License:** All code and data in this repository are proprietary. Vendored tooling is kept under `addons/` when needed for the project.
