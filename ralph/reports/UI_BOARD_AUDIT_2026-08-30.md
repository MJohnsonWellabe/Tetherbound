# UI / System Fixes Checklist — audit against live `main` (a97f3e84)

Source: `docs/reference/owner-board-2026-08-15-systems-and-castle.png`, panel
**"UI / SYSTEM FIXES CHECKLIST"**, owner-authored 2026-08-15. Read directly
from the image (transcription below), not from any prior paraphrase.

**Correction to the routing brief: the panel lists TEN items, not eleven.**
Transcribed in full:

1. Hotbar: consumables + tools only (no wood/stone/etc.)
2. Workbench: build orbs, craft tools, repair
3. Blacksmith: provides orb recipes
4. Tools: axes can chop trees, rocks give extra materials
5. Gatherables: use downed trees and rock piles (not icons)
6. Map: M = full map (KB), dedicated button on ROG
7. Minimap: fix orientation and player arrow
8. Movement: fix stairs and traversable slopes/routes
9. TMs: better than base moves (1.1x – 2.0x)
10. More ranged moves with unique VFX/animations

Every checkbox on the panel is a green check glyph used as a bullet style
(same glyph style the board uses elsewhere for plain list bullets) — it is a
checklist of asks, not a report of what is already done. Treated accordingly:
audited against the current tree, not assumed complete or incomplete either
way from the glyph.

Board date 2026-08-15 predates two weeks of shipped UI/HUD/gathering work
(`ralph/reports/VISUAL_UI_2026-08-23*`, RG9/RG10/D60/HARVEST-ALL). Several
items are already fully met by that work. Per `CLAUDE.md`: evidence-backed
"already fixed" is valid, and rewriting a working system to produce a diff is
wrong.

---

## Audit table

| # | Item | Verdict | Evidence |
|---|---|---|---|
| 1 | Hotbar: consumables + tools only | **UNMET — real gap, in scope, fixing** | `autoload/game_state.gd:217` `HOTBAR_KINDS_REFUSED := ["resource", "currency"]` only excludes wood/stone/fiber/coin. Every other kind — `gear` (orbs, saddle), `key`, `material` (saddle_frame), `tm`, `elixir`, `armor` — passes `hotbar_can_hold()` and can be assigned from the backpack grid (`scripts/ui/tab_backpack.gd:1090,1492,2039` all gate on the same permissive `hotbar_can_hold`). None of those kinds has a use-path in `playground_hud.gd::_use_hotbar_slot()` — pressing one prints `"%s is not something you can use here."` (`playground_hud.gd:3000`). TMs and elixirs already have their own correct flow (a backpack target-picker onto a chosen creature, `tab_backpack.gd:1256,1575,1838`); orbs are thrown through combat's own `throw_aim.gd`/`combat_manager.gd`, never the hotbar. So the bar can currently be loaded with five dead-end buttons. |
| 2 | Workbench: build orbs, craft tools, repair | **MOSTLY MET — one documented, deliberate decision, not treating as a gap** | `data/recipes/recipes.json` crafts `orb_basic` (build orbs ✓) and `axe`/`pickaxe`/`knife`/`hoe` (craft tools ✓) at the workbench station (`build_placer.gd:586` routes `workbench` interaction to `craft_panel.gd`). Repair exists and is free (`tab_backpack.gd:1215` `inventory.call("repair_tool", ...)`) but is reachable from the backpack **anywhere**, not gated to standing at the workbench. This is a named, deliberate design decision, not an oversight: `data/items/buildables.json`'s own `_comment_r2.7`/`_comment_sd18_workbench_storage` record that station-gating crafting was evaluated (SD18) and explicitly NOT built — it would be new location-check machinery bolted onto otherwise-pure inventory arithmetic, and `GAME_DESIGN.md` 32 bans a large crafting tree. Not re-litigating that decision inside a UI audit; flagging it here so the coordinator can decide if it's worth reopening as a design question rather than a UI fix. |
| 3 | Blacksmith: provides orb recipes | **MET** | `docs/decisions/D39-the-village-economy.md` §5: "Tam — the blacksmith... Tools and the orb recipe." Tam's dialogue hands over `recipe_orb_basic` (see `data/recipes/recipes.json`'s own `_comment_unlock_orb`), which is what makes the `orb_basic` row appear on the craft screen at all. |
| 4 | Tools: axes chop trees, rocks give extra materials | **MET** | `scripts/world/vegetation.gd` (RG9, owner directive, quoted in the file's own header): "You shouldn't be able to gather a standing tree. You should have to chop it. Then it becomes downed wood. Then you gather that." Chopping is tool-gated: `harvest_logic.gd::gather()` requires the equipped tool to match `items.gathered_with(id)` (axe for wood, pickaxe for stone) or pays a reduced bare-handed amount (`item_db.gd::harvest_yield`, `BAREHANDED_FRACTION = 0.5`) — i.e. the right tool yields strictly more material than bare hands, on both wood and stone. No evidence of a rock-specific bonus beyond that shared right-tool-vs-bare-hands multiplier; read the board line as describing that mechanic rather than a second, stone-only bonus. |
| 5 | Gatherables: downed trees/rock piles, not icons | **MET** | Same RG9/RG10 work. `vegetation_harvest_point.gd`'s header traces the exact history: an early "gold glowing orb" marker was tried and explicitly killed by a later owner directive quoted verbatim in the file — "Items to harvest shouldn't be gold lit up orbs. They shouldn't light up at all." What marks a gatherable now is the object itself: a chopped tree stands a real woodpile prop (`_build_resource_prop`), a mined stone point sits on the rock itself — no icon anywhere in the live gather path. |
| 6 | Map: M = full map (KB), dedicated button on ROG | **MET** | `project.godot`'s `map` action binds `physical_keycode 77` (M) and `JoyButton 4` (`JOY_BUTTON_BACK`, the ROG Ally's physical View button) — confirmed distinct from the LB/RB tab-cycle bindings used elsewhere in the same menu. `data/config/menu.json`'s `shortcuts.map = "map"` wires that action straight to the map tab via `game_menu.gd::_shortcuts()`. Not a keyboard-only binding needing an ROG button added — it already has one, and it isn't a shared/overloaded button. |
| 7 | Minimap: fix orientation and player arrow | **MET** | `scripts/ui/minimap.gd`'s header carries a derived (not guessed) proof of the rotation math for player-up orientation, and `_draw_player_marker()` (line 575) draws a rotating triangle, not a static dot. This is the exact defect `ralph/reports/VISUAL_UI_2026-08-23-round2.md` recorded fixing ("the minimap draws a needle instead of a capital N", the null-`current_scene` orientation bug). Matches this board item closely enough that it looks like the same finding, already closed. |
| 8 | Movement: stairs / traversable slopes | **NOT MINE — overlaps T2-STRANDING, audited only** | `scripts/world/grandpa_house.gd:262` carries a live comment acknowledging the general shape of this problem: "a CharacterBody3D cannot step UP a ledge: run it across the stair head" — a workaround for one specific staircase, not a general fix. `ralph/STATE_OF_THE_THREE_TRACKS_2026-08-29.md` independently names "a corridor stranding at South Bridge" as the single most-repeated Gate F reliability finding across three run segments. Same shape of defect (a CharacterBody3D that can get stuck on geometry it should be able to traverse), which is exactly what the brief says T2-STRANDING is chasing. Not touched. |
| 9 | TMs better than base moves (1.1x–2.0x) | **NOT MINE — overlaps T3-TYPECHART, audited only, genuinely unmet** | `data/moves/tms.json` links each TM to a `move_id` in `data/moves/moves.json` with no multiplier field anywhere in either file — a TM currently teaches a move with exactly the same `power`/`range`/etc. as if it were a base move. This is a real, unimplemented item, but it is `scripts/combat/**`/move-data territory the brief explicitly reserves for T3-TYPECHART. Flagging so it doesn't fall through a gap between lanes. |
| 10 | More ranged moves, unique VFX/animations | **NOT MINE — overlaps T3-TYPECHART, audited only** | `data/moves/moves.json`: 38 moves total, `vfx.kind` breaks down as 20 melee / 7 projectile / 7 cone / 4 area, each with its own `vfx.colour` (and `speed` on projectiles). Whether that count/mix satisfies "more ranged moves" is a content-design judgement call for the lane that owns the move data, not something this audit can settle from file counts alone. Not touched. |

---

## What this means for the lane

**Only item 1 is a genuine, in-scope, unimplemented gap.** Items 3–7 are
already met by work that landed after the board was authored — re-touching
them would be exactly the "rewrite a working system to produce a diff"
`CLAUDE.md` warns against. Item 2 has one open sub-question (repair not
gated to the workbench) that is a named, deliberate design decision from
SD18, not an omission; not reopening it without owner direction. Items 8–10
are out of this lane's file ownership per the brief and are reported, not
touched.

Proceeding to implement item 1 (narrow `HOTBAR_KINDS_REFUSED` to an
allow-list of `tool`/`consumable`/`food` — the kinds that actually have a
use-path in `_use_hotbar_slot()`), then moving to the §20 bounded visual
polish pass.
