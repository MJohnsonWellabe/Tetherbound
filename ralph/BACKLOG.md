# Backlog

Ordered. Work top-down. **This file is the state of the project.**

Legend — `▶` owner play gate, stop the loop. `🔒` needs Meshy credits.
`model:` the cheapest tier that can do the job. `tests:` exactly what to run.

---

## Phase 0 — finish the roster

### R0.5 — 🔒 Retexture the winners
`model: sonnet` · `tests: none`

`tools/art_pipeline/meshy.py texture <species> <winning glb>`, 30 credits each.
Balance was **375** at last check; ten costs ~300. Work down the roster in
backlog order and **stop when credits run out**, recording the exact balance and
the species reached in `BLOCKED.md`. The owner tops up; do not re-roll to make
a poor candidate better, iterate on what exists.

### R0.6 — Finish each creature, one task per species
`model: sonnet` · `tests: smoke_art`

Per species, in backlog order: cleanup/remesh → rig (`rig_quadruped.py` for
Tuskroot, Meadowhart, Burrowback, Paddlenewt, Mosshell, Brooktail;
`rig_bird.py` for Galecrest, Duskhush, Pipwing, Reedwing) → six procedural clips
→ grade with the shared `grade.py` → install under
`assets/creatures/tetherbound/<species>/models/`.

Every species needs an eye guard declared in `grade.py`'s `SPECIES` table.
Grading without one is an error, deliberately — it is how Ripplet's and
Galewisp's eyes were destroyed.

Done when: the model loads at its declared height and `_fit()`'s footprint clamp
is not tripped.

### R0.7 — Add the ten `species.json` entries
`model: haiku` · `tests: smoke_art, test_catch_math, test_evolution_links`

Heights are fixed by `D13` and must keep the sheets' relative ordering:
Meadowhart 1.95, Galecrest 2.00, Burrowback 1.70, Reedwing 1.65, Mosshell 1.62,
Duskhush 1.55, Paddlenewt 1.50, Brooktail 1.45, Pipwing 1.20. Tuskroot stays
2.00 and must remain larger than Mudsnout's 1.40 (`D17`).

Stats come from each sheet's own ROLE and STRENGTHS lines and nothing else — a
shell is defence, a raptor is not, a tracker hits harder than it takes. All
tunable. `aggressive` only where the sheet's role supports it. Reedwing is
canonically Water/Air but the schema takes one type: file it `water` and say so
in a comment.

**A species cannot be added before its model exists** — `smoke_art.gd` fails the
build otherwise. Add each entry as its model lands, never ahead.

### R0.8 — Production report and ledger rows
`model: haiku` · `tests: none`

`species.json` references `docs/art/MEADOWS_WILD_PRODUCTION_REPORT.md` three
times and it does not exist. Write it. Add a provenance row per creature to
`docs/ASSET_LEDGER.md` in the existing style.

### R0.9 — Assemble the opening into the real scene
`model: sonnet` · `tests: smoke_opening`

`scripts/story/sequence_director.gd` is written and merged and **nothing
instantiates it**, so the opening still does not run.

Add to `scenes/world/meadows_playground.tscn`, as children of the world root
(the node offering `ground_height_at`): a `SequenceDirector` node, a node with
`scripts/world/interaction_arbiter.gd`, `scenes/ui/dialogue_panel.tscn` and
`scenes/ui/name_prompt.tscn`. Wire the director's NodePath exports:
`player_path`, `arbiter_path`, `encounter_path`, `manager_path`,
`camera_rig_path`, `dialogue_path`, `name_prompt_path`.

Do **not** set the arbiter's `player_path` — the director calls `set_player()`.
Do **not** place Grandpa or the starters in the scene; the director spawns them
from `opening.json`, and a second Grandpa offers a second prompt. Leave
`default_starter` alone — the director suspends it.

Note `EncounterDirector.WILD_SPAWNS` also spawns an aggressive Tuskroot, which
can charge the player mid-opening. Decide whether that is acceptable and say so.

Done when: `tests/smoke_opening.gd` goes green. It is currently red by design and
names exactly what is missing.

### R0.10 ▶ Play gate — the first fifteen minutes
Wake, walk to Grandpa, talk, choose a starter, name it, fight, catch.
`GAME_DESIGN.md` §33 criteria 1, 3 and 11.

---

## Phase 1 — vocabulary, before the codebase grows

### R1.1 — Rename `pal` → `creature` everywhere
`model: haiku` · `tests: FULL SUITE`

446 occurrences across 52 code files, plus `scripts/pals/` → `scripts/creatures/`,
`assets/pals/` → `assets/creatures/`, `data/pals/` → `data/creatures/`, scene
node names, class names, signals, UI strings, dialogue, and every doc including
`CLAUDE.md` and `GAME_DESIGN.md`.

Mechanical but wide. Godot resource paths (`res://`) live in `.tscn`, `.tres`
and `.import` files as well as `.gd` — a rename that misses those breaks the
project silently at load. Do it in one commit so no intermediate state is half
renamed.

Leave `docs/decisions/D01`–`D17` on the old vocabulary: they are a historical
record of decisions made when the word was "pal", and rewriting history to match
present vocabulary is how a decision log stops being trustworthy. Add one line
to each affected decision noting the rename instead.

Done when: no `\bpals?\b` outside `docs/decisions/`, full suite green, Windows
export succeeds.

### R1.2 — Vocabulary sweep of the handoff and decision index
`model: haiku` · `tests: none`

---

## Phase 2 — the first day

### R2.1 — Gathering
`model: sonnet` · `tests: test_harvest` (new)
Harvest interactables for wood, stone, fiber, berries. Reuse
`scripts/world/interactable.gd` and the nearest-wins `prompt_arbiter`.
Done when: walking up to a tree and holding a button puts wood in the satchel.

### R2.2 — Tools
`model: sonnet` · `tests: test_inventory`
Axe, pickaxe, hammer, knife, fishing rod as items. Gathering gated on the right
tool: bare hands get less, the wrong tool gets nothing.

### R2.3 — Tool durability and free repair
`model: sonnet` · `tests: test_durability` (new)
`GAME_DESIGN.md` §19. Repair is free at the workbench — no repair-material economy.

### R2.4 — Build placement
`model: opus` · `tests: test_build_placement` (new), smoke_free_build
Ghost preview, snap, rotate, confirm, **and spend the materials**. The Build tab
currently sets `GameState.pending_build`, which **nothing in the project reads**,
and no `inventory.remove` call exists anywhere in the UI layer.
Must go through `GameState.build_cost_for(id)` so the free-build toggle keeps
working (`D16`). Done when: a placed piece exists in the world and the cost left
the satchel.

### R2.5 — Build pieces: floor, wall, doorway/door, roof, fence
`model: sonnet` · `tests: test_build_catalogue` (new)

### R2.6 — Campfire, bed, creature bed
`model: sonnet` · `tests: test_build_catalogue`

### R2.7 — Workbench and storage container
`model: sonnet` · `tests: test_storage` (new)
Storage holds **items**. It is never creature storage. Five, ever.

### R2.8 — Sleep and rest
`model: sonnet` · `tests: test_day_cycle` (new)
Pass the night, restore, advance the day. `GameState.advance_day()` has **zero
callers** today and the menu's "Day N" is decorative.

### R2.9 ▶ Play gate — does building a small home feel useful and enjoyable?
§33 criteria 6 and 7.

---

## Phase 3 — persistence

### R3.1 — Save and load
`model: opus` · `tests: test_save_format` (new), FULL SUITE
3–5 slots, frequent autosave, versioned from the first write. **There is
currently not one write to `user://` outside settings.** Follow the precedent in
`scripts/ui/key_bindings.gd`: versioned, never fatal on load.
Done when: quit mid-Meadows, reload, and party, satchel, day counter and placed
buildings are all intact.

### R3.2 — Death satchels persist across save/load
`model: sonnet` · `tests: test_satchel` (new)

### R3.3 — Player death and respawn
`model: sonnet` · `tests: test_player_death` (new) · §22

---

## Phase 4 — combat, progression, the team

### R4.1 — Levels and XP · `model: sonnet` · `tests: test_progression` (new) · §11
### R4.2 — Core stats and per-instance individuality · `model: sonnet` · `tests: test_progression` · §11
### R4.3 — Moves · `model: sonnet` · `tests: test_moves` (new) · §13. `data/moves/` is **empty**.
### R4.4 — TMs and teaching moves · `model: sonnet` · `tests: test_moves` · §13
### R4.5 — Evolution mechanic · `model: sonnet` · `tests: test_evolution_links`
Mudsnout → Tuskroot is recorded in data with nothing pulling the rope. Must
honour `D17` — the evolved form is always larger.
### R4.6 — Bond and best creature · `model: sonnet` · `tests: test_bond` (new) · §12
### R4.7 — Fainting and home recovery · `model: sonnet` · `tests: test_fainting` (new) · M6
### R4.8 — Orb economy and tiers · `model: sonnet` · `tests: test_catch_math` · §15
### R4.9 — Rework orb aiming · `model: sonnet` · `tests: smoke_catching`
Trajectory preview, aim cone, catch sequence. §33 criterion 3 is "throwing and
catching feels satisfying", so this one is judged by play, not by green tests.
### R4.10 — The release ceremony · `model: opus` · `tests: test_party, smoke_release` (new)
`party.add()` refuses a sixth creature and there is no ritual. The slice warns it
must not be "a generic delete dialog" — it is the emotional payload of the
five-creature rule and the reason the rule exists.
### R4.11 — Combat animation bug · `model: sonnet` · `tests: smoke_combat`
Owner-reported: creatures "static posed and sliding around". Ruled out by
measurement — clips exist, drive real bone motion, the animator is ticked every
physics frame with real velocity, loops are set at runtime. Best remaining lead:
Terrapup's idle moves bones by 0.088 against 1.53 for walk, and a creature in
combat is in idle almost always, so an idle that subtle is indistinguishable
from a freeze. **Next step is a recorded fight logging the clip playing against
the body's speed — not more reasoning.**

### R4.12 ▶ Play gate — is repeated combat enjoyable, not merely functional? §33 criterion 2.

---

## Phase 5 — the world

### R5.1 — Authored Meadows exploration space · `model: opus` · `tests: smoke_traversal` · M7, §30
Size it to the 4–8 hour arc. §30 is explicit: dense rather than empty, and do not
pick a kilometre count before movement is fun.
### R5.2 — Fix the intermittent `smoke_traversal` · `model: sonnet` · `tests: smoke_traversal ×20`
Same commit passes and fails. Every failure has the player at y = −0.4 m, never
falling through, so "the ground is not continuous" was a misdiagnosis. Done when:
20 consecutive headless passes.
### R5.3 — Day/night cycle · `model: sonnet` · `tests: test_day_cycle`
### R5.4 — Rain, fog and cloud variants · `model: sonnet` · `tests: none`
### R5.5 — Spawn conditions · `model: sonnet` · `tests: test_spawns` (new)
At least one nocturnal (Duskhush) and one weather-gated, per M10.
### R5.6 — Map and minimap · `model: sonnet` · `tests: smoke_menu` · §23
The `map` action is bound, labelled and rebindable, and **read by nobody**.
### R5.7 — Food buffs · `model: sonnet` · `tests: test_food` (new)
Buffs only. No starvation meter, ever.
### R5.8 — Berry plot and simple fishing · `model: sonnet` · `tests: test_farming` (new)
Deliberately shallow — §32 excludes deep farming.
### R5.9 — Player HP and armour slot architecture · `model: sonnet` · `tests: test_player_hp` (new)

---

## Phase 6 — riding

### R6.1 — Riding · `model: opus` · `tests: smoke_riding` (new) · M12
Mount/dismount, generic saddle, riding stamina, a clear advantage over running,
and no species-specific saddle clutter.
### R6.2 — Meadowhart as the rideable creature; craftable generic saddle · `model: sonnet` · `tests: test_build_catalogue`
### R6.3 ▶ Play gate — does riding make exploring better?

---

## Phase 7 — Team Tether and the culmination

### R7.1 — World trainer encounter and team combat · `model: sonnet` · `tests: smoke_trainer_battle` (new)
Trainer-owned creatures **cannot** be caught.
### R7.2 — Authored stronghold route · `model: sonnet` · `tests: smoke_traversal`
Visual language: a sacred natural site industrialised by Tether.
### R7.3 — The Warden boss fight · `model: sonnet` · `tests: smoke_boss` (new) · M14
### R7.4 — Free the legendary; it offers to join; triggers the release ceremony if full · `model: sonnet` · `tests: smoke_boss`
### R7.5 — The legendary's superior ride ability · `model: sonnet` · `tests: smoke_riding`
### R7.6 — The larger mystery and future-biome hook · `model: sonnet` · `tests: test_dialogue_runner`

---

## Phase 8 — polish gate (M15)

### R8.1 — Input feel, combat cadence, catch feel, camera · `model: sonnet` ▶
### R8.2 — Controller UI readability on the Ally · `model: sonnet` ▶
### R8.3 — Performance on target hardware · `model: sonnet` ▶
### R8.4 — Visual cohesion pass · `model: sonnet` ▶
Use the `visual-judge` skill against `docs/reference/` — the world target, not
the character target.
### R8.5 ▶ **The exit gate.** All twelve of `GAME_DESIGN.md` §33. Only the owner can call it.

---

## Found along the way — small, unscheduled

- `docs/ASSET_LEDGER.md` claims "everything currently in the build is CC0 1.0".
  False, and was before this backlog existed: the Meshy creatures and the
  Plumberry pack are not CC0. **Blocked on the owner** for the correct wording.
- `data/config/menu.json` twice cites `tests/test_menu_config.gd`, which does not
  exist. The file is `tests/test_menu_data.gd`. `model: haiku`
- `menu.json` documents `hotbar_columns`, which is absent from the backpack block
  and read by nobody. Either build the hotbar (§19 wants quick tool select) or
  delete the comment. `model: haiku`
- Opening the menu mid-fight is silently refused with no on-screen explanation.
  `model: haiku`
- `scripts/world/` has two arbiters: `prompt_arbiter.gd` (used) and
  `interaction_arbiter.gd` (used by nothing until R0.9). Confirm both are wanted
  after R0.9 lands, or fold one into the other. `model: sonnet`
- `scripts/combat/encounter_director.gd:186` does `_ally.display_name = nickname`,
  clobbering the species name — the same bug already fixed in `party_seam.gd`.
  `model: haiku`
- Backpack has no use/consume/equip/drop/split verb; the only action is moving an
  item. Needed before food buffs (R5.7) mean anything. `model: sonnet`
