# Owner playtest reconciliation — 2026-08-22

Every distinct finding in `ralph/OWNER_PLAYTEST_2026-08-18.md` and
`ralph/OWNER_PLAYTEST_2026-08-21.md`, reproduced against the **running build**
on `claude/gates-abc-verification-ne0rwx` (branched from `main` at `a22534ff`).

## The rule this file was written under

A commit message saying "fixed X" is a claim, not evidence. Every CONFIRMED
FIXED below means *this* pass drove the scenario in a booted game through real
`InputEventJoypadButton` events on the live InputMap and watched it behave.
Where the only thing available was a unit assertion over data, the row says so
rather than borrowing a smoke test's credibility.

## What reconciling actually turned up

The merge landed the **game** correctly. It did not land the **tests**.

Nine harnesses were still asserting the pre-CONTROLLER-MAP pad map, and **46 of
the 64 files in `tests/` are named by no CI job at all** — including, almost
exactly, the set written to prove these owner bugs fixed. So the green badge on
`a22534ff` never ran one of them, and two of the nine were emitting output that
reads exactly like the owner's own reports reproducing on a build where the
feature works. That is the single most important finding here: **a regression
nobody runs is a comment.**

Two shipped defects were found by doing this properly, both of which the owner
had already reported and both of which were still real:

* **OP21-24** — on a controller the axe never swung. `use_tool` was the only
  input that ever called `tool_hold.gd::swing()`, and CONTROLLER-MAP correctly
  took its pad button away, so X gathered through the prompt and the tool never
  moved. The swing was not removed; it was made unreachable by the device the
  game is played on.
* **OP1 / OP21-06** — pressing Menu with anything in the satchel opened the
  pause screen straight into a **"Drop it?" confirmation** on the focused slot,
  because gamepad Start is `game_menu` and `backpack_drop` at once. That
  confirmation holds the shell's input, so the next B cancelled a drop the
  player never asked for instead of closing the menu. One stray A from
  destroying an item they never selected.

## Legend

| Status | Meaning |
|---|---|
| **CONFIRMED FIXED** | The old scenario was driven in the running game and now behaves correctly. |
| **STILL BROKEN → FIXED** | Reproduced the original defect in the running game this pass, then fixed it. |
| **STILL BROKEN** | Reproduced, not fixed. |
| **CANNOT REPRODUCE** | Says why. |
| **REMAINDER** | Behaves, but measurably short of what the report asked for. Recorded, not closed. |

---

## `OWNER_PLAYTEST_2026-08-18.md`

| # | The report's claim | Status | Evidence in the running game |
|---|---|---|---|
| OP1 | Modal lifecycle freeze; innkeeper/bed/Build; "the main menu could no longer be opened" | **STILL BROKEN → FIXED** | The pause round trip itself is sound: `tools/_probe_pause.gd` drove Menu then B as physical joypad events and got `open=true/paused=true` → `open=false/paused=false`, twice. But on a **stocked satchel** it read `deaf=true confirming=0` — the drop confirmation. Fixed; `tests/smoke_menu_open_does_not_offer_to_drop.gd` pins it. |
| OP2 | Roof will not snap to walls; floors/walls half a square off | **CONFIRMED FIXED** | `smoke_gate_a_build_house.gd` PASS — a coherent 2x2 house with door and roof, built through the controller path. |
| OP3 | Chop needs the axe equipped and a visible swing; `+3 Wood` feedback | **STILL BROKEN → FIXED** | The swing half was dead on a pad (see OP21-24). Fixed. The `+N Wood` half is asserted by `tests/helpers/gate_a_npc_gather_segment.gd`, which compares the exact HUD string. |
| OP4 | Torch upright in hand; relights after stow/redraw | **CONFIRMED FIXED** | `smoke_gate_a_rest_torch.gd` PASS across repeated draw/stow cycles: prop visible, flame anchor above the prop origin, both light nodes active, no duplicates. |
| OP5 | Front door / title screen missing | **CONFIRMED FIXED** | `smoke_title_new_game.gd` PASS — physical pad activation resets live state and enters the Meadows. |
| OP6 | Placement must keep the piece selected (Valheim-style repeat) | **CONFIRMED FIXED** | `smoke_free_build.gd` PASS. |
| OP7 | Dismantle with full refund | **CONFIRMED FIXED** | `smoke_free_build.gd` PASS. |
| OP8 | Creature bed: visible body, gradual HP, unavailable while resting, overnight | **CONFIRMED FIXED** | `smoke_gate_a_rest_torch.gd` PASS — "visible body, gradual HP a -> b, active selection refused". |
| OP9 | Over-the-shoulder aim/throw feels bad | **REMAINDER** | Catching works: 3/3 clean runs after the aim fix (caught on launch 3, 7, 1). But the strike rate is **~36%** (4 strikes / 11 launches). It no longer blocks the chapter — the tutorial failure bound guarantees the catch on the second landed throw — but two thirds of throws missing is the owner's complaint expressed as a number. Prompt 45's to close. |
| OP10 | Release ceremony, not just a cleared slot | **CONFIRMED FIXED** | `smoke_release.gd` PASS — "the ceremony ends on the new belt and gives the menu back", and releasing the newcomer instead leaves the belt untouched. `smoke_boss.gd` PASS reaches the same ceremony from the finale: "the belt is full; R4.10's release ceremony has the decision". |
| OP11 | Level-up must announce identity, level, unlock | **NOT VERIFIED THIS PASS** | No harness drove a level-up to read its on-screen text. Do not treat as closed. |
| OP12 | Cycle creatures in exploration without the menu | **CONFIRMED FIXED** | `smoke_build_owns_creature_cycle.gd` PASS — "no menu: LB cycled the active creature (0 -> 1)". `smoke_creature_control.gd` PASS adds the rest of the verb: "dismissed, recalled, swapped, and refused mid-fight", and the swapped creature is the one standing beside the trainer. |
| OP13 | The pond needs real water | **CONFIRMED FIXED** | `smoke_pond_water.gd` PASS — 2538 rendered quads with a layered shore: 152 reeds, 32 marginals, 72 bank flowers, 40 rocks, 5 driftwood, 49 lilypads, an 18-piece jetty, plus 390 river quads. Real water, not terrain with a blue tint. |
| OP14 | Doors that look usable must open | **CONFIRMED FIXED** | `smoke_gate_a_build_house.gd` PASS includes the doorway; `R7.8` shipped village doors. |
| OP15 | Map/minimap missing authored trails | **CONFIRMED FIXED** | `smoke_gate_a_map_cycle.gd` PASS — "real pad cycling, movement-up minimap, full-map zoom/pan, recovery". Movement-up, which the owner had already reported as improved, holds. |
| OP16 | Meadows core-loop density | **CONFIRMED FIXED** (data) | `test_chapter_content_map.gd` and `test_chapter_curve.gd` PASS in the 1301-test suite. Data-level only — pacing is Gate F's to judge by play. |

---

## `OWNER_PLAYTEST_2026-08-21.md` (ROG Ally)

| # | The report's claim | Status | Evidence in the running game |
|---|---|---|---|
| OP21-01 | ROG Ally is "super laggy" | **CANNOT REPRODUCE** | No ROG Ally in this environment, and `ralph/OWNER_DIRECTIVES_2026-08-22.md` §5 accepts that: "No ROG Ally is available to this environment." Headless software rendering cannot measure frame time — `capture_hud_op21.gd` says so itself. Needs target hardware; not closable here. |
| OP21-02 | Satchel input leaks into the hotbar | **CONFIRMED FIXED** | `smoke_satchel_owns_hotbar.gd` PASS — "Satchel open: hotbar_2 fired nothing", "the d-pad moved focus to slot 0". |
| OP21-03 | Build shortcut leaves the controller cycling creatures | **CONFIRMED FIXED** | `smoke_build_owns_creature_cycle.gd` PASS, 4/4: LB cycles with no menu; with Build open neither the d-pad nor LB cycles, and the d-pad moves grid focus. |
| OP21-04 | Settings and the teleport list will not scroll by controller | **CONFIRMED FIXED** | `smoke_settings.gd` PASS. `SETTINGS-SCROLL` in `DONE.md` names this item by number; this pass confirms it on the running build rather than taking that record's word. |
| OP21-05 | First village trainer battle loses camera control | **CONFIRMED FIXED** | `smoke_trainer_battle_camera.gd` PASS — orbit holds during the fight and the exploration camera is restored on exit. |
| OP21-06 | Controller binding collisions remain | **STILL BROKEN → FIXED** | The unit-level audits pass (`test_input_context_collisions.gd`, `test_world_verb_input_owner_enforcement.gd`). They did not catch the live one: Start = `game_menu` + `backpack_drop`. See OP1. |
| OP21-07 | Building rotate does not work | **CONFIRMED FIXED** | `smoke_free_build.gd` PASS. |
| OP21-08 | Doors not openable; modular scale wrong | **CONFIRMED FIXED** | `smoke_gate_a_build_house.gd` PASS. |
| OP21-09 | Roof pieces the wrong size | **CONFIRMED FIXED** | `smoke_gate_a_build_house.gd` PASS. |
| OP21-10 | Free building implies free crafting | **CONFIRMED FIXED** (controller path) | `smoke_craft_panel_controller.gd` PASS — "navigate, craft, refresh focus, and close use physical pad input". Whether the free-build/free-craft *economy rule* is coherent is a design question the report also raises; the panel itself works by pad. |
| OP21-11 | Major hotkeys under the hotbar, legible at handheld size | **CONFIRMED FIXED** | `smoke_prompt_hotbar_dock.gd` PASS (prompt and hotbar share one dock, measured at 1920x1080) and `smoke_hud_handheld_legibility.gd` PASS — "HUD hotbar/legend/prompt stack is legible and non-overlapping at **1280x800**", which is the Ally's own panel resolution rather than a desktop canvas. `shots/_diag/hud_hotbar_legend.png` captured for the blind judge on top of that. |
| OP21-12 | Party-cycle presentation is confusing | **CONFIRMED FIXED** (mechanics) / **PENDING** (presentation) | `smoke_creature_control.gd` PASS proves the verb behaves. Whether the *feedback* still "looks strange" is a visual question: `shots/_diag/hud_party_cycle.png` is captured for the blind judge and that half is not closed here. |
| OP21-13 | UI still says "Change Pal" | **CONFIRMED FIXED** | No player-facing "Pal" string survives in `scripts/`, `data/` or `scenes/`. |
| OP21-14 | Team shows 2/5 after three catches | **CONFIRMED FIXED** | `smoke_party_count_after_catches.gd` PASS — three real catches through the real minigame read `TEAM 3 / 5`, portraits agree, and it survives save/reload. |
| OP21-15 | The map is unusable | **STILL BROKEN → PARTLY FIXED** (zoom/readability half: **CONFIRMED FIXED**, `smoke_gate_a_map_cycle.gd` proves zoom stays pinned to the player and pan/clamp/recovery work) | The owner's own §3 ruling (village and roads start revealed) was recorded in `BLOCKED.md` as "RESOLVED by owner ruling" while **both commits that closed it touched only `BLOCKED.md`** — no code shipped, so a fresh save still built a zero-reveal grid and opened black. Seed reveal now authored in `map_landmarks.json` and pinned by `test_map_fog.gd` from both sides. The **landmarks-through-fog** half is NOT built and is filed, not half-done: it needs a "an NPC told me" state distinct from "I stood next to it". |
| OP21-16 | Opening direction still unclear | **ADDRESSED, with the caveat below** | Answered by the blind cold playtest rather than by the harness, which was the right instrument: an agent with no knowledge of this work **walked all 25 objective steps**, every one resolving, and reached the climax. It did not report losing the thread. Two direction defects it *did* find are fixed here — BP3 (the chapter ends on an empty objective panel) and BP5 (Grandpa narrates the gate from inside his house). Caveat kept honest: an agent reading an objective string is not a person reading a world, so this is evidence the chain is followable, not proof the opening *teaches*. A human pass could still reopen it. |
| OP21-17 | Village layout makes no sense | **PENDING** | Visual; needs the blind judge. |
| OP21-18 | Signs sit in the road | **PENDING** | Visual; needs the blind judge. |
| OP21-19 | Props submerged in the pond | **PENDING** | `smoke_pond_water.gd` PASS proves the water and its shore layers exist, but it does not assert that no tree or house intersects the surface — that is the owner's actual complaint and it is a visual check. Left open for the blind judge rather than claimed on a passing water test. |
| OP21-20 | Submerging the trainer has no consequence | **CONFIRMED FIXED** (unit) | `test_water_hazard.gd` — 11 assertions PASS covering grace, damage tick, wading, surfacing reset. Logic-level; the feel of it is unjudged. |
| OP21-21 | Washed-out grey state after a few minutes | **CONFIRMED FIXED, with a named remainder** | `test_world_weather.gd` PASS: saturation floors on every preset, fog density below the whiteout ceiling, `clear` weighted highest, `max_consecutive_non_clear` bounded. `BACKLOG.md`'s `WEATHER-2` records the honest leftovers from an independent critic (cloudy is crushed and cloudless; one shadow rig across all four states; weather never touches the ground). Four frames captured this pass for re-judging. |
| OP21-22 | Website should sell the actual story | **CONFIRMED FIXED** | `site/index.html` rewritten; `SITE-SHOTS` tracks the four frames it still wants. |
| OP21-23 | Load Game never enters the world | **CONFIRMED FIXED** | `smoke_title_load_game.gd` PASS — "physical pad activation loaded a real save and entered Meadows". |
| OP21-24 | Axe hold and swing still wrong | **STILL BROKEN → FIXED** | Reproduced: on a pad, X gathered via the interact prompt, credited the satchel, printed `+3 Wood`, and the axe never moved. `use_tool` was the only caller of `swing()` and CONTROLLER-MAP took its pad button. The prompt press now starts an aimed swing and the yield lands on the impact. |
| OP21-25 | Stronghold/Warrens fights phase outside the arena | **CONFIRMED FIXED** | `smoke_arena_contain.gd` PASS, and it reproduces the original defect explicitly before showing the fix: "with the flat 11.0m default, hold_inside() corrects a displaced ally to 11.0m from centre, OUTSIDE the room (OP21-25 reproduced); the fix is what prevents it". |
| OP21-26 | Pond-to-village route is dead travel | **CONFIRMED — STILL BROKEN, now measured** | Reproduced with numbers (Addendum, BP6): the village → South Bridge leg is **1295 m, 215 s, with a 189-second stretch with nothing authored within 35 m**. Corroborated in the spawn data — last on-corridor cluster before the bridge at z=80, next at z=1400, and `trainers.json` empty between z=12 and z=1314. The pond group sits 350 m off-road and never comes within 160 m. The *next* leg is fine, so the emptiness is specific to the leg the tournament sends the player on. Remains Gate B/C/D1 route-content work by the report's own wording — **not this branch's to fix**, but it is no longer an impression. |

---

## Open after this pass

1. **OP9** — catch strike rate ~22% over 27 launches, not the ~36% an earlier
   11-launch sample suggested. Measured, not fixed. Prompt 45. The *dead-end*
   this used to imply is closed (see Addendum 3); the *feel* is not.
2. **OP21-01** — target-hardware performance. Needs a ROG Ally.
3. **OP21-15 (half)** — landmarks visible through fog once an NPC names them.
4. **OP11** — level-up feedback never driven on screen this pass.
5. **OP21-17/18/19** — composition; the blind visual judge owns these.
6. **OP21-26** — measured (1295 m / 189 s dead stretch), owned by Gate B/C/D1
   route content, not by this branch.
7. **WEATHER-2** — the remainder an independent critic already named.

## Method note, for whoever reads this next

The reason this reconciliation was worth doing is not the table. It is that
**six of these rows could not have been answered from the repository's own
records.** `DONE.md` and the commit log said things were fixed that were fixed;
they also said the map fog ruling was resolved when no code had shipped, and
they were silent about the axe never swinging on the device the game ships on.
The only way to tell those apart was to boot the game and press the buttons.

---

## Addendum — findings from the blind cold playtest

A separate agent, given no knowledge of this session's work and told not to
read the status docs, played the same route through the real harnesses and its
own probes. It found five things this reconciliation had not, three of which
are live defects in shipped code. Recorded here because they are the same
*kind* of finding as the owner's own reports — things only playing turns up.

### BP1 — the South Bridge gully is a trap (SEVERE)

Falling into the 11 m trench in front of the closed bridge leaves the player
unable to move forward or back. Observed: **52 seconds of full forward stick,
zero displacement**, at `(0.0, -12.1, 1333.7)`. Escape exists only by walking
~50 m sideways along the trench to where the carve fades.

There *is* a recovery volume. It is in the wrong place:

```
GullyFailsafe  area at (-1322.0, -17.6, 1338.0)  recover_to=(8.0, -1.9, 1317.0)
```

The gully is at **x ≈ 0, z = 1330**; its guard sits 1.3 km west in open meadow.
The `recover_to` point is correct — it is only the trigger box that is lost.

Cause, read in `scripts/world/gated_crossing.gd`: the crossing sets its own
`position` AND `rotation.y` to the carve (line ~149), then `_hang_failsafe()`
parents the volume under `self` while `severed_spokes.gd::_add_carve_failsafe()`
places it in **world** coordinates. The volume is therefore transformed twice.
`severed_spokes.gd`'s own failsafes are fine — their holder sits at the origin,
which is why this only bites the crossings.

Consequence the playtest also observed: a run that fell in ended with the
player teleported to world spawn and a death satchel at the bottom of a trench
1.3 km from home.

### BP2 — your own creature and trainer intercept your orbs, and the orb is spent

Three of eight tutorial throws logged `first_hit=AllyCreature` or
`first_hit=Body`. The orb is consumed (`throw_aim.gd::_spend_orb()` runs before
flight resolves) and the only feedback is the generic `"the orb went wide"`
from `combat_manager.gd::_on_orb_missed()`. Nothing says the player's own
creature was in the way, so the mechanic reads as random.

This is independent of the aim defect fixed in this branch and is still live.
It compounds OP9: at the observed hit rate Grandpa's opening gift of 15 orbs
(`data/dialogue/opening.json`, `give:orb_basic:15`) is about two tutorial
attempts, and nothing on the route restocks orbs before Tam unlocks the recipe.

### BP3 — the chapter ends on an empty objective panel

After the legendary choice the tracked line correctly becomes `""` — but
`playground_hud.gd` builds `ObjectiveBlock` in `_ready()` and never changes its
visibility; `_update_objective()` only writes `.text`. So the finished game
leaves the eyebrow **"M A I N   S T O R Y"** on screen above a blank line,
permanently. The objective chain itself is healthy: 25 steps walked, every one
a distinct sensible line, including SF34's `n/3` counters.

### BP4 — `backpack_assign` draws a keyboard key on a pad

With `using_gamepad()` true, the quick-bar verb renders `J / [J]` while its two
neighbours on the same line render correct pad glyphs. It is really bound to
**L3**; its `GLYPHS` entry in `input_glyph.gd` is `{}`, so `icon()` falls
through to the bound-key fallback. On the one screen a controller player must
use to reach the hammer and the torch, the verb that puts an item on the bar
reads as having no controller binding at all.

### BP5 — Grandpa narrates the village gate from inside his house

`data/dialogue/village.json` gives `road_gate_locked`/`road_gate_unlocked` the
speaker `Grandpa Elias` with `grandpa.png`, fired by `road_gate.gd::_on_tried()`
at the village edge while Grandpa is spawned at his house. **Data-read, not
observed on screen** — the playtest was explicit that it did not capture the
panel, so the on-screen severity is unverified.

### BP6 — OP21-26 measured

The village → South Bridge leg is **1295 m, 215 s, with a 189-second stretch
with nothing authored within 35 m**. Corroborated by the spawn tables: the last
on-corridor wild cluster before the bridge is at z = 80 and the next is at
z = 1400, and `trainers.json` has nothing between the tournament trainers at
z = 12 and `south_bridge_grunt` at z = 1314. The pond group at z ≈ 507–552
sits 350 m off the road and never comes within 160 m.

This is the owner's OP21-26 with numbers on it. It also notes the *next* leg is
fine (clusters at 1400/1550/1700/2010/2440 plus two pickets), so the emptiness
is specific to the leg the tournament sends the player on.

### BP7 — what held up

The tournament (specific entry refusal, losable and re-offerable, board tracks
through to champion), the Warrens (gated branch, first-clear reward once), the
Relay (captain → captive → gear, and she is later in the village with a changed
greeting), and the Stronghold/Warden/climax (five rooms, shutter gating, the
machine refusing before the Warden falls, 95 plants back and the storm horizon
flipping to land). `[village_npcs] placed 6 of 8` is correct, not a bug — the
two absent are `place_when`-gated.

---

## Addendum 2 — the blind visual judge

Six real in-game frames — the HUD pair at 1280x800 (the Ally's own panel
resolution) and all four weather states — handed to a Fable critic with no
knowledge of what changed, per `ralph/conventions.md` and
`ralph/OWNER_DIRECTIVES_2026-08-22.md` §5's "blind visual review stays
Fable-only".

**Both bar questions were answered, and they differed**, which is the useful
case: **A (key art) — no. B (Palworld genre) — yes, narrowly, and only because
of the HUD frames.**

### It independently reproduced WEATHER-2

Without being told that entry exists, it named the same three defects
`ralph/BACKLOG.md`'s `WEATHER-2` already records: `cloudy` reads as "my
brightness setting broke" (same scene, same shadows, 30% darker, and no actual
clouds — a grey gradient sky), the sun's shadow rig is identical in all four
states, and nothing on the ground responds to weather (`rain.png` has no wet
darkening, no specular, and streaks faint enough to read as sensor noise).
A second independent critic reaching the same conclusions is the strongest
evidence available that WEATHER-2 is real and correctly scoped.

### UI defects, which are this merge's to answer

The HUD lineage (HUD-EMPHASIS, HUD-LAYOUT, HUD-POPUP) all landed in
integration-ABC, so these are in scope:

1. **Two labels for one button.** "RB Call out Biscuit" floats directly above a
   legend that also says "RB Call Out" — "same button, two labels, ten pixels
   apart". The legend's own comment claims RB is "the one world verb with no
   other on-screen home", which is precisely false in the moment the contextual
   prompt is naming it. **FIXED**: the legend entry stands down while the prompt
   owns that verb.
2. **The party panel is too transparent over dark scenery.** "Ripplet Lv 1" loses
   contrast where the dark hilltop shows through the translucent rows in
   `hud_hotbar_legend.png`, while the same rows over sky in `hud_party_cycle.png`
   read fine. Open.
3. **The objective text wraps raggedly** — "creature." alone on its own line,
   right-aligned, in both HUD frames. Reads as broken wrapping, not typography.
   Open.
4. **The satiety block is clipped by its own panel** — "FOOD" and "100%" run to
   the panel edge with no padding, amber on amber. Open.
5. **Four near-identical white-cross icons** sit in hotbar slots that appear to
   be empty. "If four slots are empty they should look empty, not each hold a
   phantom icon." Open.
6. **An unexplained underline strip** beneath the bottom legend, which the critic
   read as "a progress bar at 0% or a leftover debug element". Open.

It also praised what works, which is worth recording so a later pass does not
"fix" it: the trainer's silhouette and ground contact in every frame, and the
party panel's information hierarchy — "the KO state (red badge, greyed row) is
genuinely clear at a glance... already better than 'programmer UI'".

### World defects — Gate D/F, not this branch

Mid-ground emptiness ("~60m of bare single-tone green with two rocks"), the
hilltop landmark rendering as an unlit black mass with stair-stepped foliage in
every frame, uniform grass-tuft scatter at even intervals, and garden-bed
timbers at bridge scale. These belong to the regional packages and to prompt 70,
not to a merge verification, and are recorded rather than actioned here. The
landmark reading pitch-black in `clear.png` while the grass beside it is fully
lit is the one that may be a real bug rather than composition, and is worth a
look by whoever owns D1.

### The caveat the critic carried, correctly

These frames come from Godot's **Compatibility** renderer under software
rasterisation, not the shipping Forward+. Trustworthy for composition, terrain
shape, silhouette, colour relationships, framing and UI layout; NOT for shadow
softness, ambient occlusion, bloom or post-processing. The critic confined its
lighting remarks to direction, value structure and shadow placement, which
survive the downgrade, and said so.


---

## Addendum 3 — the opening could dead-end on an empty satchel

Found while trying to get Step 2's continuous Gate A run past the tutorial
catch, which had failed three times running. The failures were not the harness.

### What is wrong

`docs/OPENING_SEQUENCE.md` promises the practice catch cannot fail twice.
`combat_manager.gd::configure_tutorial_catch_assist()` keeps half of that:
`catch_math.apply_failure_bound()` converts the second failed ROLL. It counts
**landed** throws deliberately — a throw that never reached the creature is not
a failed catch — and that leaves the other half open. A player who **misses** is
bounded by nothing except how many orbs they are carrying.

That would be harmless if orbs were replaceable at that point. They are not:

| Orb source | Where it is |
| --- | --- |
| Grandpa's `give:orb_basic:15` | the opening — fifteen, once |
| Tam's `recipe_orb_basic` | the village, **past the road gate** |
| the village trader | the village, **past the road gate** |

And the road gate is past this catch. So an opening that runs dry is a hard
dead-end: `throw_aim.gd::try_begin_aim()` refuses every further press with
`"no orbs left"` while `sequence_director.gd` holds the beat waiting for a catch
that can no longer be attempted. There is no exit but a new game.

At the ~22% strike rate measured above, this is not a corner case.

### Reproduced, then fixed, then reproduced fixed

Not reasoned about — **observed**, by draining the satchel to its last orb on
the real path and pressing on:

```
+95.04s — satchel drained to 1 orb(s) so the empty case is on the real path
ERROR: launch 1 left the satchel empty during the tutorial catch;
       the opening is now a dead end (opening.json catch_orb_floor did not apply)
```

The fix is `opening.json`'s `catch_orb_floor: 5`, held per frame by
`sequence_director.gd::_hold_the_tutorial_orb_floor()` behind the same
beat-and-species predicate as the failure bound. The first attempt hung it off
the `catch_refused` signal alone and **was wrong**: the refusal only fires once
the player presses throw with nothing to throw, so the restock landed after a
press that visibly did nothing. A dead button is the exact failure the opening
is supposed not to have. The refusal handler survives as the between-frames
backstop; both paths go through one function.

After:

```
+91.26s — satchel drained to 1 orb(s) so the empty case is on the real path
+95.50s — running dry restocked the tutorial satchel to 5 orb(s)
+124.40s — physical landed throw caught Bramblebun on launch 2 (2 strike(s), 0 miss(es))
+128.66s — catch complete; exploration resumed with two-creature party
gate A opening segment: OK — title through natural catch passed continuously
```

### Why it went unseen

A fifteen-orb run almost never reaches zero inside a harness budget, so nothing
ever walked the path. `smoke_gate_a_opening_segment.gd` now drains to one orb
before the catch loop and asserts the satchel never empties — so every future
run exercises the dead-end instead of hoping to stumble onto it, and a harness
that simply kept throwing cannot report a healthy opening.

That also retired the harness's arbitrary 8-launch cap. With the floor in place
the opening never refuses a throw, so the only honest reason to stop is that
catching is broken.

---

## Addendum 4 — two shards this branch added came back red

Both surfaced by CI shards that did not exist before this branch, on code this
branch did not write. Recorded here because the *pattern* is the finding.

### `smoke_party_count_after_catches.gd` — never once run by CI (FIXED)

`could not engage the real wild body at Wild_bramblebun_2`, with seven further
failures cascading from that one. The file has **one commit, from the
integration-ABC era, and this session has never touched it.** It fails on
current `main`, and nothing said so, because it sat in no CI shard until this
branch added one.

This is the same finding as the twelve stale harnesses, arriving from the other
direction: there, tests were merged broken; here, a test was merged working and
rotted with nothing watching. Both have the same root — **46 of 64 smoke tests
were in no CI shard.**

**The game is right and the harness was wrong.** Diagnosed: "stopped 3.3m away
(engage range 6.0m); the winning prompt is Interactable, not the target". In
range, target alive and visible — but a nearer prop held the line. With ~22,000
harvestable props and a distance-ranked arbiter, that is correct behaviour: a
player reads "Gather" instead of "Engage" and takes a step. The harness now does
the same, closing in until the arbiter is actually offering the target before it
presses — which is what its own header already claimed it did.

Verified: `PASS: three real catches through the real minigame land in
Game.party, the on-screen TEAM counter and party strip agree, and the count
survives a save/reload`. All eight failures gone.

Recording the asymmetry deliberately: of the two reds this branch's new shards
found, **one was the game's fault and one was the test's**, and neither could be
told from the other without booting the thing and printing what was actually
winning.

### `smoke_post_modal_control.gd` — the hammer route loses the button (FIXED)

`the hammer + interact opened nothing`, all three stress cycles. Root cause
named by instrumenting the refusal rather than guessing: **a prompt provider is
winning the interact button**, so `playground_hud.gd::_hammer_opens_the_catalogue()`
declines.

This may well be a real controller-only defect rather than a harness artifact.
Under CONTROLLER-MAP, `build_open` has no pad button — hammer + `interact` is the
**only** pad route into build mode — and the Meadows carries ~22,000 harvestable
prompt sources. "Stand somewhere with nothing interactable in reach" is not a
reasonable thing to ask of a player who wants to build.

**Instrumenting the refusal named the provider, and it changed the answer.** The
winner is `EncounterDirector`, and what it wins with is
`_creature_control_offer()` — a **non-actionable** status line, "[RB] Call out
\<creature\>", advertising an entirely different button. It is the fallback
returned for any player who has a creature and is standing near nothing else,
which is most players most of the time.

So the gate was not losing a contest. `interaction_arbiter.gd::activate()`
already refuses to fire a non-actionable winner, so the interact press was
**free** — the hammer was standing down for a line that was never going to
consume it. The design question that made this look risky evaporated: the fix is
not "let the hammer suppress prompts" (which would indeed have stopped the
player talking to Bram while holding one). It is to ask the question the arbiter
already asks — *is the button spoken for* — via `PROMPTS.is_actionable(winner())`.

Worth noting as method: the repair I would have guessed at was the wrong one,
and the only thing separating them was printing the provider's name.

Verified: `post-modal control smoke passed: 3 mixed real-joypad cycles`, from
three of three cycles failing. `test_hammer_keeps_the_interact_button.gd` pins
the contract, including the premise it rests on — if the creature-control line
ever became actionable the hammer *should* stand down, so that is asserted
rather than assumed.

### A correction to this file's own method

The first diagnostic written for the hammer failure read `equipped_tool` *after*
the harness had put the hammer away, so every report would have opened by
blaming the harness's own cleanup instead of the failure. Fixed to capture
before. Worth recording because this file's whole argument is that a failure
message should say where to look, and that one pointed the wrong way.


---

## Addendum 5 — the second blind visual judge, and what triage did to it

Run Fable-only per `ralph/OWNER_DIRECTIVES_2026-08-22.md` §5, blind: twelve
frames (seven UI/HUD, three weather, both tournament board views), the art
board, and the rubric. It was told nothing about what changed. It returned
nineteen defects.

**Two of its top findings are artefacts of what it was shown, not defects.**
This is the part worth recording, because a critic that only sees pixels cannot
tell a bad frame from a bad game, and taking its ranking at face value would
have meant "fixing" two things that are not broken.

| # | Judge's finding | Verdict |
| --- | --- | --- |
| 1 | *"Text collides with text in `combat-prompt.png`"* — called the single most severe defect in the set | **Capture artefact.** `playground_hud.gd::_exploration_legend_should_show()` already returns false while `_combat_is_running()`, so a player never sees the legend and the combat prompt together. `capture_ui_glyphs.gd` fakes the fight (`combat.visible = true`, no fight running) and hid only the exploration PROMPT, not its sibling legend in the same dock. Fixed in the tool. |
| 9 (part) | *"`hud_hotbar_legend.png` names RB twice at once… stacked"* | **Stale frames.** Those `_diag` captures are from **19:31**; `f6fe2932` fixed exactly that duplication at **20:11**. The judge was shown the bug forty minutes after it was fixed. |

The rest of #9 — `[C]` bracket-text sitting beside boxed key glyphs, two visual
grammars in one legend — is read off the 20:13 frames and **stands**.

### Genuine, and this branch's

- **#11** the persistent legend out-shouts the contextual prompt. Its own
  question answered honestly: legible, yes; competing, yes, and currently
  winning a fight it should lose.
- **#12** the hotbar leaks past the dialogue panel, leaving a stray slot 5.
- **#15** `"Catch your first wild / creature."` orphans its last word, right-
  aligned, in all seven UI frames.
- **#13** four of five hotbar slots draw near-identical icons.
- **#6** the tournament bracket's connector lines do not join; the final dangles
  unlabelled. The board's *names* are legible and read as real, which was the
  owner directive's actual ask.
- **#7** the board face is a flat UI texture in a carpentry frame.
- **#8** two of three starter portraits face away from the camera — in the one
  moment the game asks the player to choose by appearance.

**Not fixed here, deliberately.** These are HUD-EMPHASIS lineage work that has
already been through its own blind-judge rounds, and re-tuning widths and
z-order at the end of a verification pass risks regressing what those rounds
bought. They are backlog entries, named above, not silent omissions.

### Genuine, and not this branch's

Weather lighting (#3 sun shadows during rain, #4 fog that skips the ground, #5 a
crest cluster that stays crushed-black in all three states), world density
(#19), blown-out interiors (#14), and two identical villager meshes in one frame
(#2). **The judge independently re-found `WEATHER-2` for the second time,
without being shown that entry or the previous critique.** That is worth more
than the finding itself: two blind critics converging on the same three defects
is evidence they are real and not one critic's taste.

### What it said was working, unprompted

The creatures. *"Terrapup especially has real appeal: readable silhouettes,
coherent stylization, and they look like they belong to one family."* The
trainer reads at thumbnail size at correct 1.8 m scale. The HUD's teal-on-dark
identity is consistent across all seven frames. `tournament-ground.png` is the
best landscape in the set — a genuine landmark hill in the art board's language.

On the bar question it was direct: someone shown these beside the reference
would correctly identify the same genre and ambition, and would immediately add
that this one is *"years earlier in dressing"* — density, weather response and
prop finish, most of it scene work rather than new art.
