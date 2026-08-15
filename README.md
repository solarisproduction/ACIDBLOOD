# Bastion Vale

**3D Tower Defense + Roguelite Card Draft Prototype**  
*Godot 4.7.1 • GDScript • Zero external plugins*

This repository (`TD-Game-System`) contains **Bastion Vale**, a vertical slice prototype validating a tower defense core loop enhanced by roguelite card draft mechanics.

---

## 🎮 Gameplay Overview

**Core Loop:** `Home` → `Campaign` → `Battle` → `Result` → `Campaign`

- **Guardian**: Player-controlled character with auto-attack weapon
- **4 Tower Slots**: Place and upgrade 3 archetypes (bolt, cannon, frost)
- **Deterministic Waves**: Enemy spawns follow pre-authored `StageData` with reproducible timing
- **Card Draft**: On level-up, pause game and choose 1 of 3 random cards (16-card pool)
- **Permanent Progression**: Earn "cores" (currency) to buy persistent upgrades between runs

---

## 📋 Requirements & Running

| Requirement | Version |
|-------------|---------|
| Godot Engine | **4.7.1** (config/features = "4.6" compatible) |
| Platform | Windows, Linux, macOS (desktop tested) |
| Main Scene | `res://shell/home.tscn` |

**Run the game:**
```bash
godot --path .
# Or open project.godot in Godot editor and press F5
```

---

## ✅ Tests (Headless)

Automated test suite with **44 checks** covering script loads, RNG determinism, draft rules, combat math, save/load, and data integrity.

```bash
godot --headless --path . --script res://tests/run_tests.gd
```

Exits with code `1` on any failure, `0` if all pass. See [`tests/run_tests.gd`](tests/run_tests.gd).

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
| **Tests** | `tests/run_tests.gd` | Headless validation suite |
| **Tools** | `tools/*.gd` | Data pipeline scripts |

**Data-Driven Content:** 54 `.tres` files managed via [`core/catalog.gd`](core/catalog.gd):
- 5 enemies, 3 turrets, 16 cards, 30 stages, 3 perm upgrades, 1 guardian

---

## 🔢 Determinism

- **RNG**: [`core/det_rng.gd`](core/det_rng.gd) provides seeded RNG with derived salts per purpose (`"waves"`, `"draft"`)
- **Physics**: Fixed 60 Hz (`engine.physics_ticks_per_second = 60`)
- **Reproducibility**: Same seed → identical wave spawns and card offers

---

## 📊 Status: Done vs Roadmap

| ✅ Done | 📅 Roadmap |
|---------|-----------|
| Core loop (Home → Battle → Result) | Audio system (SFX, music) |
| Wave director with deterministic spawns | VFX / particle systems |
| Targeting (most-advanced enemy, tiebreak by spawn_index) | GLB assets (see [`docs/ASSET_CONTRACT.md`](docs/ASSET_CONTRACT.md)) |
| Card draft with prerequisites/excludes/unlocks | Larger card pool (30–50 cards) |
| Permanent progression (save/load via `progression.gd`) | Elite enemy variants |
| 44 automated tests (headless) | Mobile touch input |
| Balance report tool | Tutorial / onboarding |
| Sequential stage unlock (complete N-1 to unlock N) | Tooltips, richer UI feedback |

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

- [`docs/ASSET_CONTRACT.md`](docs/ASSET_CONTRACT.md) — GLB production specs for future asset replacement
- [`docs/SYSTEM_BLUEPRINT.md`](docs/SYSTEM_BLUEPRINT.md) — Technical design overview
- [`docs/DECISIONS.md`](docs/DECISIONS.md) — Architecture decisions log
- [`docs/HANDOFF.md`](docs/HANDOFF.md) — Developer handoff notes

---

**License:** All code and data in this repository are proprietary. No external plugins or assets used.
