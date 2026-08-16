# Backlog

Ordered. Work top-down. **This file is the state of the project.**

Legend — `🔒` needs Meshy credits. `model:` the cheapest tier that can do the
job. `tests:` exactly what to run.

**Owner play gates were retired 2026-08-16.** Every `▶` gate (`R2.9`, `R4.12`,
`R6.3`, `MQ1-gate`, `SH53`, and the `R9.5` exit gate) is gone by owner
directive, along with the pointer to the owner-only blind-playtest protocol.
`docs/decisions/D21` stays as history and reads as superseded, not violated.
The loop no longer parks on a gate — see `ralph/PROMPT.md` for what it does at
the end of the backlog.

**`model: fable` (owner directive, 2026-08-12) is not "the cheapest tier that
can do the job" — it is a hard floor.** These items are ceiling-setting
narrative or aesthetic authorship (world-building, story beats, dialogue, or
"does this actually look right" visual-direction judgment calls) where a
weaker first pass becomes the ceiling a later pass can't rescue. **Any firing
that reaches a `model: fable` item must not do the creative work in its own
session, regardless of which lane it is** — see `ralph/PROMPT.md`'s
"Fable-tagged items" section for the dispatch rule.

**Standing task, every visual milestone:** re-shoot the website's screenshots
after any milestone that changes how the game looks. `model: haiku` when it is
just screenshots.

---

## Phase -1.4 — the blind playtest's open findings (2026-08-15/16)

Full record in `docs/reviews/2026-08-15-full-blind-playtest/`. The six repairs
that pass already shipped; these are §7's leftovers. `PT-03` is the one the
report calls the highest-value remaining fix for a first-time player.

### PT-03 — Make the opening staircase readable
`model: fable` · `tests: smoke_opening` · `area: village`
Two testers (one of them the owner, twice) could not find the way out of the
opening loft. The flight is a narrow slot behind a parapet in the room's NW
corner, entered from the north, descending south; from every vantage a player
naturally occupies it reads as more parapet. `grandpa_house.gd::_build_stairs()`
(272-282) builds it; the `stairs_top`/`stairs_bottom` markers already exist
(132-133) and `_build_lights()` (438-447) puts no light near either. The loft
beam deliberately stops short of the opening (252-258), so nothing frames it.
**Owner picks the affordance** — a warm light at the stair head, geometry that
frames rather than avoids the opening, or a look-toward bias on the interior
camera profile the house already swaps to on entry (57, 464-470). Done when a
player who has never seen the room finds the stairs without being told.

### PT-15 — Unfocused starter portraits render ghost-white
`model: sonnet` · `tests: smoke_starter_picker` · `area: ui`
On `7547f386` all three portraits rendered in full colour; on `9e4a90a1` the two
unfocused ones are pale silhouettes. Suspected regression from the shiny repaint
(`OF27`/`OF28`). Verify against both builds before changing anything.

### PT-17 — No way to rename a creature
`model: sonnet` · `tests: test_party` · `area: ui`
A name is settable exactly once, in the opening. `name_prompt.gd`'s only caller
is `sequence_director.gd`; `tab_creatures.gd` only ever reads `nickname`. One
mis-navigated press in the opening names a creature forever.

### PT-23 — Autosave only ever fires at camp rest
`model: sonnet` · `tests: test_save_format` · `area: ui`
`camp.gd:184-187` is the sole caller of `autosave_slot()` in the whole codebase.
Building a camp is a mid-session action, so a new player has no autosave at all
for their entire first session. Add a fallback cadence (day rollover, or a
timer) that does not depend on having built anything.

### PT-04 — Naming field reportedly ignored typing
`model: haiku` · `tests: none` · `area: ui`
**Unconfirmed.** `name_prompt.gd:232-247` does call `grab_focus()`, and headless
verification shows the field focused. The playtest saw a caret and a focus ring
in a field that received nothing — consistent with the test container's X input
focus rather than a game bug. Needs one check in a real window; close it if it
does not reproduce.

### PT-18 — Boot cost rose sharply across the mid-test build change
`model: sonnet` · `tests: none` · `area: perf`
Scene load went from ~2 minutes to materially longer across 20 commits, measured
under software rendering (which exaggerates absolutes, not the relative jump).
Suspects include the 17 shiny colourway textures. Measure on target hardware
before optimising anything.

### PT-19 — One silent engine death at boot
`model: haiku` · `tests: none` · `area: perf`
One of two launches on `7547f386` died at boot with no error output. Insufficient
evidence to characterise. Watch for recurrence; close if it does not return.

---

## Phase 7 — the village lives, the meadow reads

### R7.6 — The berry farm beside Grandpa's house, and the hoe
`model: opus` · `tests: test_farming (new), test_inventory, smoke_playground` · `area: village`
Owner-requested, 2026-08-16: a berry farm next to Grandpa's house, and a hoe
that preps ground for berry seeds. Replaces this item's old two-line stub
(which also mentioned fishing — the rod exists as an item and gates nothing;
leave it).

In bounds, not a design invention: `GAME_DESIGN.md` lists "berry farming" and
"simple farm plots" as **expected** build categories, and §32 excludes only
*deep* farming. Keep it shallow — till, sow, wait, harvest. No irrigation,
fertiliser, soil quality or crop varieties.

Build on what exists rather than inventing:
- `scripts/world/harvest_logic.gd` is the shared tool/yield/durability body and
  gained a public `gather()` so a swing and a prompt-press run one path. A crop
  is its **fourth caller**, alongside `harvest_node.gd` and
  `vegetation_harvest_point.gd` — do not copy it.
- The hoe follows the five existing tools in `data/items/items.json`
  (axe/pickaxe/knife/hammer/fishing_rod) plus `scripts/player/tool_hold.gd`.
  Which mesh a tool uses and how it sits in the hand is **data on the item**, so
  a hoe is an items.json entry and a swing target, not new player code.
  Craftable at the workbench station, or handed over by Tam (the OF30
  precedent).
- Berries are already a real item (`items.json:59`, with `satiety` and the
  `berry_verve` buff), already harvested from two nodes in
  `data/config/harvest.json`, already sold to Mira, and
  `recipes_ironwood.json:58` already keeps them in the Ridge Tonic cost "so the
  berry plots stay worth walking to at Band 4" — a forward reference to a plot
  that does not exist yet. This item is what that line was waiting for.

One genuinely new shape, worth naming: `items.json:9` records that berries are
the one resource with no `gathered_with`, i.e. never tool-gated. A hoe would be
the first tool gating a **planting** verb rather than a gathering one — decide
that deliberately rather than by accident.

Placement: Grandpa's house is at `[-22,-16]` (`village.json:3`); the plot must
clear the square flat at `[10,-10]` r18 and the fence run at `[3,-18]`. Answers
"Found along the way"'s spec §14 bullet directly — the farmhouse should not
become a room you never re-enter.

**Done when** a player can craft or receive a hoe, till a patch beside the
farmhouse, sow berry seeds, and harvest berries from it on a later day.

### R7.8 — Doors that open on interact, and houses you can walk into
`model: opus` · `tests: smoke_traversal, test_prompt_arbiter` · `area: village`
Owner-requested, 2026-08-16: every house enterable, doors opening on interact.
**Owner-scoped: build the door verb once, plus one or two reusable interior
templates every house draws from — not a bespoke interior per building.**

No door-open mechanic exists today, and the codebase already admits the gap:
`building_prefabs.json:567` poses `cottage_a`'s leaf statically open at -100°
with the reasoning that "a visibly closed door standing in an opening the player
walks straight through would be village.gd's hologram warning from the other
side." That is exactly the tension this item resolves. Grandpa's door is not a
precedent — it is an invisible story gate (`set_door_open()`, polled by
`sequence_director.gd`), not a player verb.

Three pieces of work:
1. **The verb.** A new provider on the existing `interactable.gd` /
   `prompt_arbiter.gd` arbiter — the same route `riding_controller.gd` took.
   One door script, animating the existing leaf, reused by every prefab.
2. **The openings.** `building_prefabs.json:4`: a prefab with no `colliders`
   gets one combined-AABB brick. Only `workshop` and `cottage_a` have authored
   openings; `cottage_b`, `ranger_station`, `mill` and the rest are solid bricks
   with painted-on doors. Each needs a doorway hole and lintel — this is the
   bulk of the cost.
3. **The interiors.** One or two reusable templates following
   `grandpa_house.gd`'s documented split (the kit owns the exterior; the script
   owns floor, furniture, lights, markers and all collision).
   `scripts/world/shop_interior.gd` already states it copies that worked example
   rather than inventing, so it is the second data point for the pattern.
   Register each in `village.gd:135`'s `INTERIORS` whitelist — deliberately a
   whitelist, because "naming a res:// script is data that can load code".
   Reuse the interior camera profile seam (`grandpa_house.gd:57`, an `Area3D`
   plus `set_target`).

**Done when** every house in the village has a door that opens on interact and
a room behind it the player can stand in, and none of them is a solid brick.

### R7.9 — An inn in the village
`model: opus` · `tests: smoke_traversal` · `area: village`
Owner-requested, 2026-08-16: an inn in the main village where the villagers can
stay.

There is no inn or tavern prefab — it must be composed from the same Medieval
Village MegaKit family per D24. `village.json:3` records why the TowerWindmill
was **removed rather than replaced** ("a mismatched second-family landmark is
exactly the split-the-difference failure D24 closed"); an off-family inn repeats
that mistake. `farmhouse_shell` (two storeys) is the closest existing massing to
work from. Data goes in `data/config/village.json`'s `structures[]` with its
`_why`, built by `village.gd`, grounded via D09 ("ask the world, never
raycast"). Its interior comes from R7.8's templates.

An innkeeper follows D39's dual-role pattern (a vendor branch and a later
trainer branch coexisting through ordered `greeting_when`), with `SE30`'s
`place_when` available if presence should be conditional. If the inn carries
rest or quest-board function, reconcile against spec §6 ("6–10 optional
activities, not forty shallow quests") rather than inventing a quest list.

### R7.3 — Grow the authored space toward the arc · `model: opus` · `tests: smoke_traversal` · M7, §30
**Re-scoped 2026-08-16.** This item used to gate on `MQ1A`/`MQ1B` and claim the
individual areas belonged to `SD16`, `SD17`, `SE21`, `SE23` and `SF31` — all
five have since shipped, along with SC14, SE22, SE25/SE27, SF34, R8.2 and the
stronghold. The world this was going to authorise has already been built.

What is left is the part that was never done: `terrain_playground.json`'s own
first line still says it is *a test area, not the Meadows*, and the bake, the
Terrain3D region count and the performance question on the Ally were never
budgeted. So this is now an audit and a bake, not a construction item: measure
what the built chapter actually costs, decide whether the footprint needs to
grow underneath it, and rebake. §30's rule still governs any number.

### R7.4 — Map reveal rule · `model: sonnet` · `tests: smoke_menu` · §23
**Re-scoped 2026-08-16.** The old text said the `map` action was "read by
nobody" — false since the map button was wired. The map, the minimap and the
player's heading arrow all exist and work.

What survives is only spec §16's rule: the map reveals explored areas and
landmarks and **never reveals everything automatically**. Check
`scripts/world/map_baker.gd` before writing anything — if the fog already
behaves, close this item.

### OF15 — Geometry snags: player can get stuck in places
`model: sonnet` · `tests: smoke_traversal (extend)`
Owner-reported, 2026-08-15. Movement getting wedged/blocked rather than passing
through. Needs locations logged from a fresh playthrough before a fix can be
scoped.

### OF18 — Re-shoot the website's screenshots
`model: haiku` · `tests: none`
`site/img/*.jpg` predates the roster repaint (`OF28`), the carried torch
(`OF24`), the shiny work and the playtest repairs. More overdue than when it was
filed, not less.

### R7.7 — Player HP and armour slot architecture · `model: sonnet` · `tests: test_player_hp` (new)

---

## Phase 6.5 — locomotion quality rebuild (owner's quality plan)

### MQ1B — Terrain adaptation and foot placement · `model: fable` · `tests: none` · quality plan §3
**START WITH FABLE.** `MQ1A` is closed — the base cycles are key-pose authored
on render-verified axes, with planted-skate numbers a foot-IK pass can
regression-check against. Don't build terrain IK on top of a base cycle that
hasn't passed its own blind critique.

Evaluate and implement the minimum robust solution for uphill, downhill,
cross-slope and uneven-ground walking, small terrain height variation, and idle
stance on slopes (foot planting/IK, orientation to ground normal, pelvis
compensation, stance-phase locking as needed — don't add complexity for its own
sake).

**Done when** blind rendered/play inspection on flat and sloped test terrain
shows no gross foot penetration, no obvious hovering, no sustained slope
skating, no knee inversion, no broken pelvis motion, no visible IK snapping, and
walk/run still reads as natural.

---

## Phase -0.6 remainder — the look

### EV9 — Rebuild the HUD, remainder
`model: opus` · `tests: smoke_menu` · `area: ui`
Bible §16–§18. Most of this item shipped across four slices. **Tested at
physical 7-inch scale, not on a desktop monitor** — §17 is explicit.

Genuinely still open:
- `orb_capture` icon has no mount point — there is no orb-count panel anywhere
  in the current HUD to hang it on. Needs a panel first, or the owner naming a
  different place it belongs.
- A branded display font matching the "TETHERBOUND" key-art logotype, and
  gradient/beveled bar fills. The owner supplied a style board
  (`ev9_display_lettering_style_guide.png`) but there is nowhere to apply it:
  the game boots straight into the world (D18) and renders no wordmark
  anywhere. Needs a title screen to exist first, or a different mount point.
- Compass — the bible says "if it exists"; it doesn't, and inventing one is not
  this item's job.

### EV10 — Cohesion pass
`model: fable` · `tests: none` · `area: visual`
Bible §22 Phase G and §23's metrics. Re-shoot the same viewpoints, blind-judge
against both reference sets, fix the three biggest gaps, repeat until further
improvement is asset-quality-limited rather than composition-limited. Record
plainly that EV9's remainder above is out of reach for documented reasons rather
than treating it as a failure to converge.

---

## Phase 8.5 — the chapter's own audit

### SH54 — Audit: nothing in the chapter assumed new creature credits
`model: haiku` · `tests: none`
Spec §38 step 54, §20. Walk every item shipped for this chapter and confirm none
of them installed, requested or planned a new creature mesh. Cheap, and worth
doing once at the end, because the constraint is a budget the owner holds and a
single quiet violation spends it.

---

## Phase 9 — polish

### R9.1 — Input feel, combat cadence, catch feel, camera · `model: sonnet`
### R9.2 — Controller UI readability on the Ally · `model: sonnet`
### R9.3 — Performance on target hardware · `model: sonnet`

---

## Ops

### OPS1 — Backfill `DONE.md`, and fix what let it drift
`model: haiku` · `tests: none`
`DONE.md`'s newest entry is `SG44+SG46+R8.5+R8.6`, and it has **no entries** for
OF19–OF33, SC12–SC15, SD16–SD18, SE21–SE30, SF31/SF34, SG38/SG40, R8.1–R8.4,
SH47 or the playtest repairs — roughly 25 shipped items. The loop's
"move it to DONE.md when you ship" contract is broken, and that is the root
cause of the 2026-08-16 prune that produced this file. Backfill from `git log`,
then state in `PROMPT.md` what a firing owes when it ships.

Also record the work that shipped with **no backlog item at all**, so it is not
re-done: elixirs (D45), tonics (D47), moves becoming non-interchangeable, the
workbench becoming a real crafting station with craftable tools, and
tool-in-hand + assignable hotbar + the map button (save format 6→7).

---

## Found along the way — small, unscheduled

- **Spec §6 — 6–10 optional activities, not forty shallow quests.** Lost Pal,
  Broken Cart, Night Watch, The Old Champion, Deep Warren, River Nest, Team
  Tether patrols, Meadowhart Herd. Each wants a home in Phase 8's bands rather
  than a list of its own; promote individually when the band it belongs to is
  built. `model: sonnet`
- **Spec §14 — home must stay relevant.** Grandpa's dialogue evolves per band,
  creature beds and recovery, storage and crafting, villagers updating what they
  know, the rescued NPC returning, story check-ins. The farmhouse should not
  become a room you never re-enter after the first twenty minutes. `R7.6`'s
  berry farm is the first answer to this. `model: sonnet`

---

## Done

Ids only. `git log` and `DONE.md` are the record; this list exists so a firing
can tell at a glance that an id is spent.

- BG1 — done
- BG2 — done
- CO1 — done
- EV1-remainder — done
- EV2 — done
- EV2-trunk-colour — done
- EV3 — done
- EV3-remainder — done
- EV3-remainder-2 — done
- EV3-remainder-3 — done
- EV3-remainder-4 — done
- EV3-remainder-5 — done
- EV4 — done
- EV4-hillside-seam — done
- EV4-hillside-seam-remainder-2 — done
- EV4-hillside-seam-remainder-3 — done
- EV4-hillside-seam-remainder-4 — done
- EV4-textures — done
- EV4-textures-lighting — done
- EV4-textures-remainder — done
- EV5 — done
- EV5-remainder-2 — done
- EV6 — done
- EV6-remainder — done
- EV6-remainder-well-rocktrim-shadow — done
- EV7 — done
- EV7-remainder — done
- EV8 — done
- EV9-double-prompt — done
- HD1 — done
- HD1-remainder — done
- HD2 — done
- HD2-remainder — done
- LP1 — done
- LP4 — done
- LP7 — done
- LP8 — done
- LP9 — done
- MQ1A — done
- NP1 — done
- NP2 — done
- NP3 — done
- NP4 — done
- NP4-rig — done
- NP4-uv-split — done
- NP6 — done
- NP7 — done
- OF1 — done
- OF2 — done
- OF3 — done
- OF4 — done
- OF4-rebuild — done
- OF4-remainder-mound — done
- OF5 — done
- OF6 — done
- OF7 — done
- OF8 — done
- OF9 — done
- OF10 — done
- OF10-remainder — done
- OF11-remainder — done
- OF12-remainder — done
- OF13 — done
- OF16 — done
- OF19 — done
- OF20 — done
- OF21 — done
- OF22 — done
- OF23 — done
- OF24 — done
- OF25 — done
- OF26 — done
- OF27 — done
- OF28 — done
- OF29 — done
- OF30 — done
- OF31 — done
- OF32 — done
- OF33 — done
- R0.11 — done
- R1.1 — done
- R2.1 — done
- R2.2 — done
- R2.3 — done
- R2.4 — done
- R2.5 — done
- R2.7 — done
- R2.8 — done
- R3.1 — done
- R3.1-remainder — done
- R3.2 — done
- R3.3 — done
- R4.1 — done
- R4.1-remainder — done
- R4.2 — done
- R4.3 — done
- R4.4 — done
- R4.5 — done
- R4.6 — done
- R4.7 — done
- R4.8 — done
- R4.9 — done
- R4.10 — done
- R4.11 — done
- R5.2 — done
- R5.3 — done
- R6-village-notification-freed-instance — done
- R6.1 — done
- R6.2 — done
- R7.5 — done
- R8.1 — done
- R8.2 — done
- R8.3 — done
- R8.4 — done
- R8.5 — done
- R8.6 — done
- R9.4-remainder-2 — done
- R9.4-remainder-6 — done
- R9.4-remainder-8-rocks-repeat — done
- R9.4-remainder-9 — done
- R9.4-remainder-9-combat — done
- RB1 — done
- SA0 — done
- SA0-orbs — done
- SA1 — done
- SA1-lod — done
- SA2 — done
- SA2-flake — done
- SA3 — done
- SA4 — done
- SA5 — done
- SA6 — done
- SA7 — done
- SA8 — done
- SB9 — done
- SB10 — done
- SB11 — done
- SC12 — done
- SC13 — done
- SC14 — done
- SC15 — done
- SD16 — done
- SD17 — done
- SD18 — done
- SE21 — done
- SE22 — done
- SE23 — done
- SE25 — done
- SE27 — done
- SE30 — done
- SF31 — done
- SF33 — done
- SF33-remainder — done
- SF34 — done
- SG38 — done
- SG40 — done
- SG44 — done
- SG46 — done
- SH47 — done
