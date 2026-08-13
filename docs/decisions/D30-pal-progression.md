# D30 — Pals gain levels, named moves and a bond stat

**Date:** 2026-08-13 · **Decided by:** the owner, as one of four canon
changes approved in the follow-up session that produced `D29`, `D31` and
`D32`.

## The decision

Pals stop being fixed stat blocks and gain a real progression layer:

1. **Level and XP.** XP is earned from combat victories; wild pals spawn
   inside a level band rather than at one fixed level.
2. **Named moves per species**, replacing the flat "quick attack, charged
   attack" every pal currently shares. Moves map onto the existing
   `player_quick` / `player_charged` combat verbs from `combat.json` — this
   is not a new attack system, it is names and per-species flavour laid over
   the one that already exists.
3. **A bond stat**, growing from battles won, catches made and days spent in
   the active party. Five bond nodes each grant a small stat scale, matching
   the "5-node tether line" the UI spec's §8.4 already calls for on the Team
   screen.

Traits stay deliberately out of scope. `data/traits/` stays an empty
placeholder — nothing here fills it.

## Why

The UI spec's §8 Team screen assumes all of this exists — moves with
power/energy numbers (§8.3), a 5-node bond meter (§8.4), a level-and-name
header (§8.2) — and building the screen honestly means the data underneath
it has to be real, not decorative. The owner confirmed the mechanic
directly, the same session `D29`/`D31`/`D32` came out of.

## What changes on disk

- `data/moves/moves.json` — new, replacing the empty `data/moves/.gitkeep`
  placeholder. Each move: a `display_name`, a `pal_type` for its type icon
  (spec §8.3), which existing verb it maps onto (`quick` or `charged`), and
  a `power` field. **`power` is a multiplier on the damage
  `combat_math.base_damage()` already computes** from `combat.json`'s
  `player_quick.power` / `player_charged.power` — it does not replace that
  formula, it scales it. Every move ships at `1.0`, so **balance is
  unchanged the day this lands**; tuning a species' signature move to hit
  harder or softer than the shared baseline is a one-number edit after that.
- `scripts/pals/pal_instance.gd` — gains `level`, `xp`, `bond`, and the
  moves resolved from its species, alongside the existing `hp`, `energy`,
  `attack`, `defence`, `fainted` fields `from_species()` already sets.
- `data/config/progression.json` — new. XP-to-level curve, XP awarded per
  victory, the wild spawn level band, bond gain per battle/catch/day, and
  the five bond-node stat-scale amounts. `ALL TUNABLE`, same house style as
  `combat.json` and `catching.json`.
- `data/pals/species.json` — each species entry gains a move list (ids into
  `moves.json`) alongside its existing `base_hp` / `base_attack` /
  `base_defence`.
- Save format — level, XP and bond join the party fields `D27` already
  round-trips per pal, and ride the save-format v2 bump alongside `D32`'s
  `yaw_deg` and `D33`'s fog grid (see `D27`).

## What was deliberately not built

- **Traits.** `data/traits/` stays empty. The spec's §8.2 lists traits in
  the Pal detail hierarchy, but nothing in this decision or the follow-up
  session asked for the trait system itself — the screen can show "none yet"
  where traits would go, the same way it will show real data everywhere
  else.
- **A four-move-slot system.** Moves map onto the two existing verbs
  (quick/charged); this is not Pokémon's four-slot moveset. A species can
  still carry more than one move per verb as future scope, but nothing here
  builds move selection UI for it.
- **Rebalancing anything.** Power multipliers start at parity on purpose —
  this decision adds the scaffolding, not a difficulty pass.

## What it supersedes

Nothing structural — this is new scope, not a reversal. It does commit
`data/moves/` to a real shape for the first time since `D02`/`D07` left it as
a placeholder, and it is the reason `D27`'s save format needs its v2 bump.
