# Run Upgrade Structure

Fonte atual:
- `data/cards/*.tres`
- `core/draft.gd`
- `game/battle.gd`
- `game/battle_hud.gd`

Na UI de draft, cada botao mostra exatamente:
- linha 1: `card.title`
- linha 2: `card.description`

## Estrutura recomendada para leitura

Em vez de uma arvore global unica, a estrutura atual fica mais clara quando separada em:
- `Permanent Unlocks`
- `Run Upgrades`
- dentro de `Run Upgrades`: `Guardian`, `Fortress`, `Bolt Line`, `Cannon Line`, `Frost Line`

## Diagrama claro

```text
PERMANENT UNLOCKS
- Unlock Frost Turret
  -> Unlocks Build: Frost Turret in future runs

RUN UPGRADES

Guardian
- Fast Fire
- Damage Up
- Multi Shot
- Piercing Shots
- Range Up
- Damage Boost
  note: choose 1 with Fortress Boost

Fortress
- Repair
- Fortress Boost
  note: choose 1 with Damage Boost

Bolt Turret Line
- Build: Bolt Turret
  -> Bolt Damage
  -> Choose one:
     - Branch: Fast Bolt
     - Branch: Long Bolt

Cannon Turret Line
- Build: Cannon Turret
  -> Bigger Blast

Frost Turret Line
- Build: Frost Turret
  -> Stronger Slow
```

## Permanent Unlocks

| Upgrade | Efeito no sistema |
|---|---|
| `Unlock Frost Turret` | Libera `Build: Frost Turret` para runs futuras |

## Run Upgrades

### Guardian

| Carta | Texto da UI | Regras atuais |
|---|---|---|
| `Fast Fire` | `Guardian fires 15% faster.` | `max_stacks=3` |
| `Damage Up` | `Guardian damage +2.` | `max_stacks=3` |
| `Multi Shot` | `Guardian fires +1 projectile per attack.` | `max_stacks=2` |
| `Piercing Shots` | `Guardian shots pierce +1 enemy.` | `max_stacks=2` |
| `Range Up` | `Guardian attack range +1.5.` | `max_stacks=2` |
| `Damage Boost` | `Guardian damage +50%. Choose 1 with Fortress Boost.` | `max_stacks=1`, exclui `Fortress Boost` |

### Fortress

| Carta | Texto da UI | Regras atuais |
|---|---|---|
| `Repair` | `Restore 20 fortress HP.` | `max_stacks=3` |
| `Fortress Boost` | `Fortress max HP +30. Restore 30 HP. Choose 1 with Damage Boost.` | `max_stacks=1`, exclui `Damage Boost` |

### Bolt Turret Line

| Etapa | Carta | Texto da UI | Regras atuais |
|---|---|---|---|
| Base | `Build: Bolt Turret` | `Build a fast single-target turret in the next free slot.` | `max_stacks=2`; bloqueada se nao houver slot livre |
| Upgrade | `Bolt Damage` | `Bolt Turrets deal 60% more damage.` | requer `Build: Bolt Turret`; `max_stacks=2` |
| Branch Choice | `Branch: Fast Bolt` | `Bolt Turrets fire faster, but with shorter range. Choose 1 branch.` | requer `Build: Bolt Turret`; `max_stacks=1`; exclui `Branch: Long Bolt` |
| Branch Choice | `Branch: Long Bolt` | `Bolt Turrets hit harder and farther, but fire slower. Choose 1 branch.` | requer `Build: Bolt Turret`; `max_stacks=1`; exclui `Branch: Fast Bolt` |

### Cannon Turret Line

| Etapa | Carta | Texto da UI | Regras atuais |
|---|---|---|---|
| Base | `Build: Cannon Turret` | `Build a slow splash-damage turret in the next free slot.` | `max_stacks=2`; bloqueada se nao houver slot livre |
| Upgrade | `Bigger Blast` | `Cannon splash radius +0.8 and damage +25%.` | requer `Build: Cannon Turret`; `max_stacks=1` |

### Frost Turret Line

| Etapa | Carta | Texto da UI | Regras atuais |
|---|---|---|---|
| Base | `Build: Frost Turret` | `Build a slowing turret in the next free slot. Requires Unlock Frost Turret.` | exige unlock permanente `frost_turret`; `max_stacks=1`; bloqueada se nao houver slot livre |
| Upgrade | `Stronger Slow` | `Frost slow lasts +1s and slows more.` | requer `Build: Frost Turret`; `max_stacks=1` |

## Regras que importam para a UX

- O draft da run agora tem `16` cartas.
- Cada level up oferece ate `3` cartas.
- Cartas de `Build` somem temporariamente quando todos os slots de torre estao ocupados.
- `Fortress Boost` e `Damage Boost` funcionam melhor apresentados como `Choose 1`.
- `Fast Bolt` e `Long Bolt` funcionam melhor apresentados como `Choose 1`.
- `Unlock Frost Turret` deve aparecer fora da arvore da run, como unlock meta.
- O texto mostrado no HUD vem de `game/battle_hud.gd` como `"%s\n%s" % [card.title, card.description]`.

## Recomendacao de cores e diagramacao

Padrao mais eficiente para game UI deste tipo:
- categoria por cor
- estrutura em colunas
- exclusao mostrada como `Choose 1`
- dependencia mostrada como `Base -> Upgrade`
- unlock meta separado visualmente da run

### Paleta sugerida

| Categoria | Cor sugerida | Uso |
|---|---|---|
| `Guardian` | vermelho queimado `#A64B3C` | dano, ataque, projeteis, alcance |
| `Fortress` | dourado/bronze `#B08A45` | defesa, cura, HP da base |
| `Bolt` | azul eletrico `#3D7FE3` | shock, branch de bolt |
| `Cannon` | laranja ferrugem `#C96A2B` | splash, impacto, shell |
| `Frost` | ciano gelo `#56A7B8` | slow, chill, controle |
| `Permanent Unlock` | roxo acinzentado `#6C5A8E` | meta progression |
| `Choose 1` | neutro claro `#D8D1C5` + borda dupla | exclusao mutua |

### Diagramacao recomendada

Use `5` colunas na leitura principal:

```text
[ Permanent Unlocks ]
[ Guardian ] [ Fortress ] [ Bolt Line ] [ Cannon Line ] [ Frost Line ]
```

Regras de layout:
- `Permanent Unlocks` no topo, separado por uma faixa menor.
- `Guardian` e `Fortress` como listas verticais simples, sem conectar tudo por linhas.
- cada linha de torre como mini-arvore local:
  - carta base grande
  - upgrades abaixo
  - branch choice lado a lado
- cartas exclusivas com moldura especial e conector curto entre elas.
- evitar linhas cruzadas entre categorias.

### Padroes de mercado que valem seguir

- `Slay the Spire`: clareza por tipo e leitura imediata do texto.
- `Vampire Survivors`: arma base separada de evolucoes e passivos.
- `Brotato`: categorias legiveis primeiro, sinergia depois.
- `Monster Train`: escolhas exclusivas mostradas como blocos fechados, nao como grafo amplo.

### Regra pratica para este projeto

Se a carta altera:
- `guardian.*` => badge `Guardian`
- `fortress.*` ou heal de base => badge `Fortress`
- build/upgrade de bolt => badge `Bolt`
- build/upgrade de cannon => badge `Cannon`
- build/upgrade de frost => badge `Frost`
- depende de unlock meta => badge `Permanent Unlock Required`
- exclui outra carta => selo `Choose 1`
