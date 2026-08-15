# Contexto para IA - Bastion Vale

## Sistemas Críticos (NÃO QUEBRAR)

### Determinismo
- RNG via `core/det_rng.gd` com seeds derivadas
- Mesma seed = mesmas waves, mesmos card drafts
- NUNCA usar `randi()` ou `randf()` direto, sempre via `det_rng`
- Spawn X deve passar por `Battle.roll_spawn_x()`, nunca por acesso solto a RNG

### Targeting
- `core/targeting.gd` escolhe inimigo mais avançado (maior Z)
- Tiebreak: menor `spawn_index`
- NUNCA mudar essa lógica sem discutir

### Wave Director
- `game/wave_director.gd` consome `StageData.waves`
- Spawn X vem de `battle.roll_spawn_x()`
- Timing determinístico via `_physics_process(delta)`
- NUNCA adicionar aleatoriedade não-seeded

## Padrões de Código

### Nomenclatura
- Scripts: `snake_case.gd`
- Cenas: `PascalCase.tscn`
- Variáveis: `snake_case`
- Constantes: `UPPER_CASE`

### Arquitetura
- `core/` = RefCounted, sem Nodes, lógica pura
- `game/` = Node3D, atores do jogo
- `data/types/` = Resource classes
- `data/*.tres` = instâncias de dados

### Signals
- UI escuta events via signals
- NUNCA acoplar UI diretamente a lógica de jogo

## Testes
- Sempre rodar após mudanças: `godot --headless --path . --script res://tests/run_tests.gd`
- Suite atual: 69 checks cobrindo script loads, RNG, draft, combat, save/load,
  campaign traversal, data references e convenções de conteúdo
- Validação completa padrão: `./tools/validate.sh`
- Para tuning: `godot --headless --path . --script res://tools/balance_report.gd`
