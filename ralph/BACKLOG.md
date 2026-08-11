# Backlog

Ordered. Work top-down. **This file is the state of the project.**

Legend — `▶` owner play checkpoint. **Gates no longer stop the loop** (owner
directive 2026-08-09, D21): the loop lists them in `BLOCKED.md`'s play-gate
section for the owner and keeps building past them. `🔒` needs Meshy credits.
`model:` the cheapest tier that can do the job. `tests:` exactly what to run.

**Standing task, every visual milestone:** re-shoot the website's screenshots
after any milestone that changes how the game looks (this rewrite, D18/D19's
overhaul, is the precedent — the site had claimed "sourced stand-ins" months
after the roster was real). `model: haiku` when it is just screenshots.

---

## Phase 0 — the owner played. This is the response.

**R0.10's play gate fired on 2026-08-09: the owner played the first build,
and the overhaul session that followed absorbed the entire feedback loop.**
What shipped (see `docs/HANDOFF.md` §3 and `docs/decisions/D18`–`D20` for the
full record): the giant-player fix with render-space measurement
(`render_bounds.gd`, `smoke_art`'s new [0.1,10] fit-factor trip), the combat
feel pass (auto-face on windup, lunge at windup start, 0.3s input buffer, new
speeds), orbs and potions as real items granted by Grandpa's `give:` dialogue
effects, the throw trajectory preview and the finally-wired aim profile, the
D19 roster resize, `spawns.json` replacing `WILD_SPAWNS` (D20), the indoor
opening in Grandpa's farmhouse (D18), the village and baked dirt paths, and
the website redesign.

**It also absorbed much of Phase 2's first-day scope**: ~10 authored harvest
nodes for wood/stone/fiber/berries (part of old R2.1), camp placement with
ghost preview and real material costs (old R2.4's core, proving the
`build_cost_for` path D16 demanded), campfire + bedroll (part of old R2.6),
and rest-until-morning advancing the day counter and healing (old R2.8's
core). What those items still owe is listed under Phase 2 below.

### R0.11 ▶ Play gate — the owner plays the NEW first day, end to end
Wake in bed upstairs → downstairs to Grandpa, the belt, orbs and potions →
out the door to the three starters → choose and name → the village square and
the paths → harvest along the tutorial route → a fight and a catch → make
camp before dark → rest to morning, day counter ticks. `GAME_DESIGN.md` §33
criteria 1, 3, 6 and 11 — plus the two things D19 flagged for exactly this
playtest: does the combat camera crowd at the new sizes, and does the arena
still feel roomy.

---

## Phase -1 — urgent PC bugs (owner-reported, 2026-08-10)

The owner played the published Windows build. One bug left, ahead of
everything else in this file — **do this first, then Phase -0.5, then
Phase 1 onward.**

**RB1 (mouse look) shipped — see `DONE.md`.** Real on-device confirmation
by the owner is still the open item; see that entry for what is and is not
provable from CI.

**RB2 (walk/run animation) fixed — see `DONE.md`.** Real bug, found after
the owner corrected an earlier wrong "already fixed" pass this same firing:
every baked humanoid clip shipped `Animation.loop_mode = LOOP_NONE`, so
`character_model.play()` played walk/sprint once and froze for as long as
the state held — creatures already avoided this (`pal_animator.gd`), humans
never did. Fixed in `character_model.gd`/`trainer_model.gd`, verified by
`tests/smoke_input.gd` reading `loop_mode` directly and by real rendered
screenshots. Real on-device confirmation by the owner is still worth having,
same as RB1, but this one no longer needs it to know the bug was real.

---

**RB3 (smoke_aggression flake) fixed — see `DONE.md`.**

**RB4-diagnostics (startup boot log) shipped — see `DONE.md`.** **RB4
(Ally freeze root cause + fix: switched to the Compatibility renderer)
shipped — see `DONE.md`.** Real on-device confirmation that the freeze is
actually gone on the Ally is still worth having, same as RB1/RB2, but the
diagnosis and fix no longer need it to know the bug was real.

---

## Phase -0.75 — the owner's Meadows spec, P0 (owner directive, 2026-08-11)

`docs/MEADOWS_PROGRESSION_SPEC.md` §1 and §38 Phase A, made canon by
`docs/decisions/D23-the-meadows-is-the-first-game.md`. Owner-reported from a
real playtest of the published build, the same way Phase -1 was — **above the
rest of Phase -0.5**, because three of the five change what a survey frame
contains and judging a build that is about to change wastes a render pass.

Step 1 of the spec's Phase A — the PC mouse-capture lifecycle (spec §1C) —
**already shipped as `RB1`; do not rebuild it.** `playground_world.gd`
re-asserts capture on `Window.focus_entered` and backs off through
`_mouse_wanted_elsewhere()` for menu, dialogue and the name prompt, which is
the same mechanism §1C's Escape / menu-restore / Alt-Tab clauses describe. The
spec's ten-minute acceptance test is on-device work and is tracked as `SH53`,
not as a reopening of RB1.

### SA2 — Grandpa's door cannot be crossed until the opening beat is done
`model: sonnet` · `tests: smoke_opening`
Spec §1D. The owner walked straight out of the farmhouse and skipped the man
who gives you the belt, the orbs and the potions — the whole of
`OPENING_SEQUENCE.md` beat 3. Canon rule: **the player cannot leave the house
until the required Grandpa interaction is complete.** Not a "Talk to Grandpa
first" toast — §1D asks for the in-world form: crossing is stopped, Grandpa
calls out ("Hold on. You're not walking out there empty-handed."), attention
redirects, and the conversation starts itself. The gate reads
`sequence_director.gd`'s current beat against `opening.json`'s beat order and
lifts for good once the briefing is done; `grandpa_house.gd` owns the doorway.
Once lifted it never re-arms. Done when: `smoke_opening` walks the player at
the exterior doorway *before* talking to Grandpa, is stopped, and the briefing
conversation is running without the test having pressed interact.

### SA3 — A believable physical perimeter, and a failsafe under it
`model: sonnet` · `tests: smoke_traversal`
Spec §1E. `terrain_playground.json`'s `world_size` is 512 m and everything past
the bake is Terrain3D's `world_background` — drawn, never collided. The Meadows
currently ends in the one way §1E says it must not: like a floating level.
Build the edge out of things you can see — fieldstone walls, ranch fencing,
hedgerows, terrain ridges, rock formations, dense impassable growth. Invisible
collision *supports* a visible boundary and is never the boundary by itself. A
kill/respawn volume below the world is a failsafe, not the design. Done when: a
headless walk on eight compass bearings from spawn is stopped by something the
player can see at every bearing, and a teleport below the terrain returns the
player to safety instead of falling forever.

### SA4 — Seven outward spokes, each believably severed
`model: sonnet` · `tests: smoke_traversal`
Spec §1E and §29. Seven routes leave the perimeter — river gorge (Water), old
storm road (Electric), mountain trail (Fire), high pass (Ice), cliff road
(Air), ancient stone gate (Psychic), sealed blighted road (Dark) — each blocked
by something physical: collapsed bridge, rockslide, flood, damaged lift, Tether
blockade, sealed gate. **No "Biome Locked" messaging, ever** (spec §19, and
`GAME_DESIGN.md`'s traversal pillar). §29 is what gives them meaning: these are
severed old roads, not seven dead ends someone built — broken roadbed, old
signage, abandoned trade infrastructure, land visible on the far side. This is
the seed `R8.6` pays off and the geometry `SF33` later dresses. Done when: all
seven are reachable on foot from the village, each is visibly and physically
impassable, and none of them explains itself with UI text.

### SA5 — Recolour Burrowback away from Terrapup
`model: sonnet` · `tests: smoke_art`
Spec §1A and §20. The owner cannot tell the Ground starter from the wild
badger, and they are genuinely close: `HANDOFF.md` §2 has Terrapup as
"badger/canine cub, warm brown fur, cream face stripe" and Burrowback as a
"broad low badger". D13 already carries distinction rules for Trailpup and
Galecrest; this is the fourth and it was missed. **Geometry is frozen (§20) —
no Meshy spend, no regeneration.** The lever is `grade.py`'s repair path
(`python3 tools/art_pipeline/blender/grade.py --species burrowback --textures
assets/pals/tetherbound/burrowback/models` — plain numpy and Pillow, no
Blender): `SPECIES["burrowback"]` today carries structural fixes and no
`palette` block. Add one, toward charcoal/near-black coat, cool pale-grey face
stripe, slate nodules, restrained rust-brown belly, minimal green. Terrapup is
not touched. Visual-affecting, so `conventions.md`'s blind pass binds — and ask
the critic the silhouette question specifically. Done when: a blind critic
given both turntables side by side, told nothing, does not call them the same
creature.

### SA6 — Separate the five birds by palette
`model: sonnet` · `tests: smoke_art`
Spec §1B and §20. Pipwing, Duskhush, Galecrest, Reedwing and Galewisp must not
read as palette swaps of one another. Same constraint and same mechanism as
`SA5` — `grade.py` `palette` blocks, no regeneration — with the palettes §20
names: Pipwing ochre/gold + cream + charcoal; Duskhush slate/lavender-grey +
muted cream + amber eyes; Galecrest rust/chestnut + charcoal + pale sand;
Reedwing deep teal + cream + copper/tan + orange bill and feet. **Galewisp
keeps its established palette and is not touched.** §20 says to push the
separation harder than would normally be necessary, because the meshes overlap
more than ideal and colour is the only lever left. Two traps already paid for
in `conventions.md`: `grade.py`'s eye guard is mandatory, and Ripplet's eyes
were destroyed once by a hue-band guard on a body of the same hue. Done when: a
blind critic shown all five as black silhouettes *and* as colour turntables can
name five distinct creatures.

---

## Phase -0.5 — Visual pass (owner directive: finish this before R1–R8)

Everything the two 2026-08-09 blind reviews (`docs/reviews/2026-08-09-site-
frames-blind-critique.md`, `docs/reviews/2026-08-09-r0.8.5-full-blind-
review.md`) found that is fixable by changing the scene, gathered here and
worked in this order. The one finding that is NOT here on purpose: the
creature/human art-pipeline style mismatch is a design decision (rework vs.
replace assets) parked in `BLOCKED.md` for the owner — `CLAUDE.md` forbids
inventing that call, gate or no gate.

**VP2 (preview_creatures.gd rendering zero creatures) fixed — see `DONE.md`.**

**R5.1 (day/night cycle) shipped — see `DONE.md`.**

**R7.1's signposts and stronghold silhouette shipped — see `DONE.md`.** Three
bullets of the original five are still open:

**R7.1-visual (blind-reviewed the signposts and stronghold silhouette, three
rounds) shipped — see `DONE.md`.** One remainder opened below.

**R7.1-visual-remainder (new wall/roofline/crenellation geometry, blind-
reviewed over three rounds) shipped — see `DONE.md`.** Close and mid range
now genuinely read as fortified architecture; a narrower long-range
remainder is opened below.

### R7.1-visual-remainder-2 — Long-range silhouette still doesn't confidently read as fortified
`model: sonnet` · `tests: none`
R7.1-visual-remainder's third and final blind-critic round, verbatim, on
`silhouette-from-square.png` (the long-range wayfinding distance the
landmark exists for): stripped to that scale it is "two uneven dark spikes
with a shallow notch on top of a mound... reads just as plausibly as twin
standing stones, dead trees, or a broken obelisk pair... does not clinch
'fortress' specifically." Close and mid range both pass clearly now — the
wall/collar/crenellation work genuinely fixed those (see `DONE.md`) — so
this is narrower than the original ask: the shape needs to hold its
fortified read specifically at the distance where per-tower detail (merlons,
roofline) has shrunk below what a silhouette can resolve, which the current
geometry does not yet do. The round-3 fix (taller connecting wall, height
16m) measurably improved this over round 2 without fully passing it — likely
needs either a wider silhouette element that survives to that scale, or
accepting that a placeholder-primitive fortress cannot clinch this distance
and revisiting once real art replaces the primitives (`CLAUDE.md`'s
prototyping rule cuts both ways: placeholder is fine to prove composition,
but is also allowed to genuinely not be good enough yet). Two smaller,
addressable findings from the same round, not chased further to stay inside
the three-round cap: the north tower's stepped-mass cap reads as a chimney/
smokestack rather than a turret in the mid/long frames (a reshape of the
existing primitive, not new geometry); and the ridge's hard-edged tan/brown
mound cap under the structure (clearest in `silhouette-from-square.png`) is
terrain material, not landmark geometry — the same territory `R7.1-remainder`
below already tracks, not a new bug from this task.

**The olive/lime ground seam is fixed — see `DONE.md`.**

**R7.1-remainder (ridge-bias clump placement + ground-cover clustering, three
rounds) shipped — see `DONE.md`.** Genuine, visible improvement over the
pre-fix state, but neither bullet fully passes the blind critic yet; a
narrower remainder is opened below.

### R7.1-remainder-2 — Ground cover still reads procedural, horizon mid-ground still sparse
`model: sonnet` · `tests: none`
R7.1-remainder's third and final blind-critic round, on the post-fix survey
(owner-directed interactive session, 2026-08-10/11): the field still "reads
underpopulated" against both references (its #2 ranked gap, right behind
sky/fog consistency), and names both original bullets specifically —

- **Continuous ground cover, still not clearing.** Despite three rounds of
  tuning (bigger tufts, per-instance colour jitter, cut `strays` grass
  2000→500 / drygrass 700→200 for tighter clumping — see `DONE.md`), the
  critic still calls the scatter "roughly even spacing and uniform scale in
  02, 03, and the open ground of 01 and 05... no clearings, no clustering
  around features, and no scale variety within a prop type." The clump
  structure that IS there (visible in 03, 04) isn't enough density to read
  as continuous cover rather than isolated groups. Next attempt should try
  a genuine density lever inside the clumps themselves (more `per_clump`,
  smaller `clump_radius` for tighter packing) rather than further
  redistributing the same instance count, and re-judge against Palworld's
  own field shots specifically for how many blades are actually on screen
  at once.
- **Horizon/mid-ground, partly the known unfixable limit, partly not.**
  "No middle-distance layering anywhere in the set (no tree lines,
  ridgelines, or water)... the single biggest reason these frames feel
  empty." Some of this is `world_background = NOISE` (Terrain3D's
  procedural continuation past the 512m bake, genuinely can't hold props —
  see the original `R7.1-remainder` entry in `DONE.md`), but the finding
  reads as broader than just the unreachable far band — the near/mid
  ground inside the bake is also thin. Worth investigating whether a
  water feature (a pond/stream, named as a biome pillar in `GAME_DESIGN.md`
  but absent from every survey frame) would do more for depth-reading than
  further vegetation tuning.

Two smaller findings from the same round, not chased further to stay
inside the three-round cap: sky/fog treatment is inconsistent between
frames (01/05 show a blue gradient sky, 02 a dark navy sky with hard-edged
cloud shapes, 03/04 a flat cream band) — likely a lighting/environment
config difference between survey viewpoints rather than a scatter issue,
worth its own investigation; and a small aliased red-maroon shape in 03
that the critic couldn't resolve into a legible object, possibly a
retint/LOD edge case on a single tree instance.

**R7.1-found (rise-overlook eye moved off the tower cluster) fixed — see `DONE.md`.**

**R7.1-found-2 (near-vertical bank near spawn, root-caused to overlapping
building-pad flattening, not a path or texture bug) fixed — see `DONE.md`.**

### R7.1-found-3 — a flat texture-splat stripe on the hillside behind the spawn crate
`model: haiku` · `tests: none`
Found running the confirmation visual-judge pass for R7.1-found-2 (frames
01, 05): a diagonal tan/khaki stripe on the hillside behind the wooden
crate, "crisp and uniform-width rather than irregular or grass-feathered,"
and not picking up raking-light shading in the low-sun frame the way real
terrain relief would — reads as an unintentional texture-blend artefact,
not an authored dirt trail or any part of R7.1-found-2's fix (that fix
touched height/geometry only, not the colour/blend map). Needs its own
look at whatever paints dirt/soil blends onto slope near the spawn pad in
`build_playground_terrain.gd`. Not chased here — out of scope for the
near-vertical-bank defect this pass was confirming.

**R7.2 (NPC villagers and interior polish) shipped — see `DONE.md`.** The
sub-agent that built it disclosed a real process gap (no way to spawn a
genuinely blind critic and read back its verdict from its own toolset) and
self-graded instead. The owning interactive session had that capability and
used it afterward — a real blind critique ran against a confirmed-on-`main`
render; see `DONE.md` for the verdict and why none of its findings needed
an R7.2-specific fix.

### R9.4 — Visual cohesion pass, the checkpoint for this phase (relocated from Phase 9)
`model: sonnet` ▶ · `tests: none`
Re-run `.claude/skills/visual-judge` against `docs/reference/` (the world
target) once VP1/VP2/R5.1/R7.1/R7.2 above have landed, on a fresh survey
and a fresh R0.8.5-style full roster pass. Confirm the top findings from
both 2026-08-09 reviews actually moved, the way `docs/reviews/2026-08-09-
site-frames-blind-critique.md`'s own "after judging" section requires —
re-running and comparing sheets, not just asserting the fix landed. This
being genuinely green (or a documented remainder handed back to the
owner as still-open) is what "the visual pass work is done" means before
moving on to Phase 1.

---

## Phase 1 — vocabulary, before the codebase grows

### R1.1 — Rename `pal` → `creature` everywhere
`model: haiku` · `tests: FULL SUITE`

~446 occurrences across 52 code files at last count (the overhaul will have
moved it — recount, don't trust it), plus `scripts/pals/` →
`scripts/creatures/`, `assets/pals/` → `assets/creatures/`, `data/pals/` →
`data/creatures/`, scene node names, class names, signals, UI strings,
dialogue, and every doc including `CLAUDE.md` and `GAME_DESIGN.md`.

Mechanical but wide. Godot resource paths (`res://`) live in `.tscn`, `.tres`
and `.import` files as well as `.gd` — a rename that misses those breaks the
project silently at load. Do it in one commit so no intermediate state is half
renamed.

Leave `docs/decisions/D01`–`D20` on the old vocabulary: they are a historical
record of decisions made when the word was "pal", and rewriting history to
match present vocabulary is how a decision log stops being trustworthy. Add
one line to each affected decision noting the rename instead.

Done when: no `\bpals?\b` outside `docs/decisions/`, full suite green, Windows
export succeeds.

### R1.2 — Vocabulary sweep of the handoff and decision index
`model: haiku` · `tests: none`

---

## Phase 2 — the first day, remainder

The session shipped harvest nodes, camp placement, campfire/bedroll and rest
(see Phase 0's note). What is left is the part that makes them an *economy*
rather than a scripted route.

### R2.1 — Tools
`model: sonnet` · `tests: test_inventory`
Axe, pickaxe, hammer, knife, fishing rod as items in `data/items.json`.
Gathering gated on the right tool: bare hands get less, the wrong tool gets
nothing. Done when: the same harvest node yields differently by held tool.
Spec §10: a Rootstone-tier tool (`SD18`) is the ladder's second rung — build
the rung here, not a second tool system there.

### R2.2 — Tool durability and free repair
`model: sonnet` · `tests: test_durability` (new)
`GAME_DESIGN.md` §19. Repair is free at the workbench — no repair-material
economy.

### R2.3 — Real tree/rock harvesting on the vegetation
`model: sonnet` · `tests: test_harvest`
The ~10 authored nodes were the tutorial route; this makes the *world*
harvestable — the scattered Terrain3D trees and rock outcrops themselves,
reusing `interactable.gd` and the nearest-wins arbitration, respecting the
path keep-clear. Done when: walking up to any ordinary tree and holding the
button puts wood in the satchel.

### R2.4 — Orb and potion crafting
`model: sonnet` · `tests: test_recipes` (new)
Recipes for `orb_basic` and `potion_small` from gathered materials, at the
campfire or workbench. Grandpa's `give:` gift (D18) stops being the only
source — which matters because `throw_aim` now genuinely spends orbs. Costs
in `data/recipes/`, tunable, labelled. These are the **base** tier; `SD18` adds
the Rootstone tier above them (spec §10). Baseline materials are wood, stone,
fiber and berries and nothing else — §10 is a short list on purpose.

### R2.5 — REMOVE the post-fight auto-heal
`model: sonnet` · `tests: smoke_combat, smoke_catching`
`encounter_director.gd` still calls `_ally.heal_fully()` after every fight —
an M2 crutch ("no healing system, no camp" said the comment, and both now
exist). Deliberately sequenced *after* R2.4: taking the crutch away before
potions are craftable would make the first day punishing for the wrong
reason. Needs the backpack to grow a **use/consume verb** so `potion_small`
can actually be drunk (the found-along list has carried this gap since before
the overhaul). Done when: HP persists after a fight and is restored only by
potion or camp rest.

### R2.6 — Build pieces: floor, wall, doorway/door, roof, fence
`model: sonnet` · `tests: test_build_catalogue` (new)
Placement itself shipped with the camp (ghost → snap → confirm → spend
through `GameState.build_cost_for`, D16 intact); this is catalogue content.

### R2.7 — Workbench and storage container
`model: sonnet` · `tests: test_storage` (new)
Storage holds **items**. It is never creature storage. Five, ever.
The workbench upgrade is a Rootstone sink (spec §3 Band 2, `SD18`).

### R2.8 — Creature bed
`model: sonnet` · `tests: test_build_catalogue`

### R2.9 ▶ Play gate — does building a small home feel useful and enjoyable?
§33 criteria 6 and 7.

---

## Phase 3 — art debt and persistence

### R3.0 — Regenerate the three humanoid GLBs through the fixed pipeline
`model: sonnet` · `tests: smoke_art`
The trainer, Grandpa and the Warden still carry cm-unit skeletons under a
0.01 Armature with ×100 inverse binds — the malformed source of the giant-
player bug. The runtime now compensates (render-space fit via
`render_bounds.gd`), but compensating for broken files is a debt, not a fix.
Re-run each through the fixed `animate_humanoid.py` (it now applies scale the
way the creature pipeline always did) and **verify with `smoke_art`'s
render-space check** — all three humans measured in render space, fit factors
inside [0.1, 10]. If the trainer's undersized backpack (HANDOFF §6) is cheap
to fix in the same pass, take it; do not let it grow the task.

### R3.1 — Save and load
`model: opus` · `tests: test_save_format` (new), FULL SUITE
3–5 slots, frequent autosave, versioned from the first write. **There is
still not one write to `user://` outside settings.** Follow the precedent in
`scripts/ui/key_bindings.gd`: versioned, never fatal on load.
**Carry `SB9`'s progression flags in version 1** — Phase 3.5 is sequenced right
after this item precisely so the chapter's state does not cost a format bump
later.
Done when: quit mid-Meadows, reload, and party, satchel, day counter and
placed buildings are all intact.

### R3.2 — Death satchels persist across save/load
`model: sonnet` · `tests: test_satchel` (new)

### R3.3 — Player death and respawn
`model: sonnet` · `tests: test_player_death` (new) · §22

---

## Phase 3.5 — reusable progression infrastructure (spec Phase B)

`docs/MEADOWS_PROGRESSION_SPEC.md` §15, §16, §21, §35, §36. Everything in the
Meadows chapter (Phase 8) stands on these four items.

Placed *after* Phase 3 on purpose: `R3.1` writes the first save format and it
is "versioned from the first write". `SB9`'s flags belong in version 1, or
adding them later costs a format bump for nothing.

### SB7 — Per-material NPC variants, not one global tint
`model: sonnet` · `tests: smoke_art`
Spec §21. R7.2 already proved the idea — Mira, Oskar and Tam in the square are
Grandpa's and the trainer's rigs with a `tint` in `art.json` — but `tint` is a
single multiply over every surface (`character_model.gd::_apply_tint`), and §21
names that exact failure: "do not recolor everything with one global tint if it
destroys material separation." Grow the `art.json` block into per-material
overrides (hair, jacket, trousers, boots, belt, pack visibility) keyed by
surface or material name, with the existing single `tint` still honoured so
nothing already placed breaks. Done when: two NPCs on the same rig differ in
jacket and hair colour independently, and neither is a flat wash of one hue.

### SB8 — Team Tether rank palettes on the Warden rig
`model: sonnet` · `tests: smoke_art`
Spec §21, §35, §36. The Warden's rig is the faction's base body. Four rank
tiers as data on top of `SB7`: grunt (charcoal, muted forest green, minimal
gold), relay/field officer (deeper green, bronze trim), captain (dark green,
brass, one regional accent), Warden (richest materials, cream fur mantle,
strongest gold — unchanged). Rank has to be readable at gameplay distance
without a nameplate, because the geometry repeats. One caution the spec hedges
on and this item should not: §21 offers the **main-character** base for "junior
Team Tether personnel", but that rig is the player's own body and enemies
wearing it will read as clones of the player. Prefer the Warden base for every
faction NPC; keep the main-character base for civilians until §22's optional
grunt base exists. Done when: the relay captain, a regional captain and the
Warden stand in one frame and a blind critic ranks them correctly by seniority.

### SB9 — The smallest progression-state system that survives the chapter
`model: opus` · `tests: test_progression_state` (new), FULL SUITE
Spec §15. Objective flags, completion flags, trainer-defeated state, keys and
tokens, bridge-unlocked, dungeon-cleared, captive-rescued, Sigils 0/3,
stronghold-unlocked, Warden-defeated, post-Warden world state. Lives on the
`Game` autoload beside the party and the satchel — D14 is explicit that one
autoload is the design and a second is not. Objectives are data
(`data/progression/`); the code is a flag store plus a has/set/completed API.
**Spec §19 bans a "giant generic quest engine" and §15 says the same thing
twice; this is the item on the whole backlog most likely to become one.** If it
starts wanting branching, timers, prerequisites-of-prerequisites or a scripting
language, stop and split it. Done when: a flag set in one scene is readable in
another, survives save/load (R3.1), and no gameplay script hardcodes a story
boolean.

### SB10 — Physical keys, gears and Sigils that open real things
`model: sonnet` · `tests: test_progression_state`
Spec §3 Gate 1, §15, §19. A gate is a mechanism in the world that a carried
item operates — the South Bridge Key, the Mill Bridge Gear, three Sigils —
never a level check and never a UI lock. The player may walk to a closed gate
at any level and be refused by the gate, not by a dialog. Done when: holding
the right item and interacting opens the crossing, and not holding it produces
an in-world response.

### SB11 — One tracked objective, and a two-list quest log
`model: sonnet` · `tests: smoke_menu`
Spec §16. One concise line on the HUD ("Earn access to the South Bridge",
"Defeat the Upper Meadows captains. 2/3") and a log with exactly two lists,
Main Story and Local Requests. `playground_hud.gd` owns the line, `game_menu.gd`
gains the tab. Reads `SB9` and invents no state of its own. Done when:
completing an objective changes the HUD line without a scene reload.

---

## Phase 4 — combat, progression, the team

### R4.1 — Levels and XP · `model: sonnet` · `tests: test_progression` (new) · §11
### R4.2 — Core stats and per-instance individuality · `model: sonnet` · `tests: test_progression` · §11
### R4.3 — Moves · `model: sonnet` · `tests: test_moves` (new) · §13. `data/moves/` is **empty**.
### R4.4 — TMs and teaching moves · `model: sonnet` · `tests: test_moves` · §13

### R4.5 — Tuskroot's REAL model 🔒 — LIKELY ALREADY DONE, needs verification
`model: sonnet` · `tests: smoke_art`
**R0.8.5's full blind review (2026-08-09) found this is probably no longer
true.** `assets/pals/tetherbound/tuskroot/models/pal_tuskroot_lod0.glb` has
a different file hash from `ollie-the-songbird.glb`, and a fresh turntable
render (`docs/reviews/2026-08-09-r0.8.5-full-blind-review.md`) shows a real
tusked boar carrying the same moss-and-stone material language as Mudsnout —
exactly the "must read as Mudsnout grown up" brief below. `species.json`
already has it at height 2.15 against Mudsnout's 1.55, matching D17/D19's
numbers. What that review did NOT do: run `smoke_art` or check the rig/clip
wiring, which is what this item's own `tests:` field names. Next firing on
this item: run `smoke_art`, confirm the model is properly rigged and
animated (not just present), and if it passes, close this as done instead
of doing the generation work described below — do not silently invent a
replacement model over a real one already installed.

**Constraint change, spec §20 / D23: the "fresh generation from the sheet"
fallback below is now illegal.** No new creature Meshy generations for the
Meadows, at all. The remaining paths are (1) verify the installed model, which
R0.8.5's review suggests will pass, or (2) graft off Mudsnout's finished model,
which costs no credits either way. If both fail this becomes a `BLOCKED.md`
question for the owner — **not** a credit spend. The `🔒` marker above is
therefore misleading and should go when this item is next touched.

Original brief, kept for whoever verifies: the last stand-in was
`ollie-the-songbird.glb`. Since D20 it never spawns wild, so the only place
it will ever be seen is the evolution ceremony: the single most emotionally
loaded reveal a creature model gets. `CLAUDE.md`'s prototyping rule applies
with full force — the ceremony may not be judged with a songbird wearing a
boar's name. If verification finds it's NOT actually done: needs its own
call first, fresh generation from the sheet, or a graft off Mudsnout's
finished model (try the graft first, it costs no credits). Height 2.15 per
D19; strictly larger than Mudsnout per D17.

### R4.6 — Evolution mechanic and ceremony
`model: opus` · `tests: test_evolution_links, smoke_evolution` (new)
Mudsnout → Tuskroot gets a rope pulled at last. D20 fixed the intent: the
first evolution the owner sees will be a creature they caught as a piglet and
have carried since — build the ceremony knowing that. Honour D17 (the evolved
form is always larger — at D19 scale that is 1.55 → 2.15). Blocked on R4.5:
no ceremony with the stand-in.

**Spec §4 (D23) fixes the shape.** Mudsnout → Tuskroot is **the** Meadows
evolution line and no other normal species evolves — it exists to teach the
limited evolution system. Recommended: a level requirement (~15), a bond
requirement, and one Heartstone-type item from the Burrow Warrens' optional
deep branch (`SD17`). All three numbers and the item name are tunable per
`CLAUDE.md`; do not let a working name become a permanent mechanic.

### R4.7 — Bond and best creature · `model: sonnet` · `tests: test_bond` (new) · §12
### R4.8 — Fainting and home recovery · `model: sonnet` · `tests: test_fainting` (new) · M6

### R4.9 — Orb economy and tiers · `model: sonnet` · `tests: test_catch_math` · §15
Spec §3 Band 2: the improved orb tier is the **first** thing Rootstone
(`SD18`) buys. Build the tier ladder here; `SD18` supplies the material.
Note: the old "rework orb aiming" item that sat beside this was **absorbed by
the overhaul** — trajectory preview sharing `_release()`'s math, wired
sensitivity, fine-aim exponent, piecewise snap assist, cancel during windup.
Whether it now *feels* satisfying (§33 criterion 3) is R0.11's and R4.12's
question, not a build task.

### R4.10 — The release ceremony · `model: opus` · `tests: test_party, smoke_release` (new)
`party.add()` refuses a sixth creature and there is no ritual. The slice
warns it must not be "a generic delete dialog" — it is the emotional payload
of the five-creature rule, and since D18 the five-cap has a physical body in
the world: the belt Grandpa gave you has five holders.

**Spec §5 states the precondition, and it is not work on this item.** The
ceremony only lands if the Meadows has already produced more creatures worth
keeping than five slots — a Ground tank, a Water counter, an Air attacker, a
rideable Meadowhart, a rare-trait catch, the Mudsnout line, a favourite first
catch. That is a content requirement on Phase 8's bands, not on R4.10, and the
first biome must not be allowed to dodge the tension.

### R4.11 — Combat animation bug · `model: sonnet` · `tests: smoke_combat`
Owner-reported: creatures "static posed and sliding around". Ruled out by
measurement — clips exist, drive real bone motion, the animator is ticked
every physics frame with real velocity, loops are set at runtime. Best
remaining lead: Terrapup's idle moves bones by 0.088 against 1.53 for walk,
and a creature in combat is in idle almost always. **Next step is a recorded
fight logging the clip playing against the body's speed — not more
reasoning.** Re-check against the owner's R0.11 impressions first; the feel
pass (auto-face, lunge timing) may have changed the report.

### R4.12 ▶ Play gate — is repeated combat enjoyable, not merely functional? §33 criterion 2.

---

## Phase 5 — the living world

**R5.1 (day/night cycle) relocated to Phase -0.5** — owner directive,
2026-08-10: visual-pass work runs before Phase 1 onward.

### R5.2 — Rain, fog and cloud variants · `model: sonnet` · `tests: none`

### R5.3 — Spawn conditions · `model: sonnet` · `tests: test_spawns`
At least one nocturnal (Duskhush) and one weather-gated, per M10. Extend
`spawns.json`'s schema per D20 — this is the task that decision deliberately
deferred the fields for. Tests keep addressing species through the `roles`
block, never ids.

**Spec §13 supplies the area table**, which is what makes deeper regions change
the team you can build: lower fields Bramblebun / Mudsnout / Pipwing; grove
Trailpup / Duskhush at night / Burrowback; quarry and warrens Burrowback /
Mudsnout / strong Ground spawns; river Paddlenewt / Mosshell / Brooktail /
Reedwing; upper ridge Galecrest / Meadowhart / stronger Trailpup. Duskhush is
already the nocturnal example above. No random battle screens, ever (§13).

---

## Phase 6 — riding

**R6.1 and R6.2 are worked inside Phase 8's section 8d** — spec §3 Band 4 (D23)
makes riding a Band 3 / early Band 4 unlock gated on a Riding Saddle whose
components cost Rootstone and Ironwood, which is a progression step rather than
a free-standing milestone. Their briefs are kept here; the ordering is there.
R6.3's play gate stays where it is.

### R6.1 — Riding · `model: opus` · `tests: smoke_riding` (new) · M12
Mount/dismount, generic saddle, riding stamina, a clear advantage over
running, and no species-specific saddle clutter.

### R6.2 — Meadowhart as the rideable creature; craftable generic saddle
`model: sonnet` · `tests: test_build_catalogue`
Spec §3 Band 4 confirms Meadowhart as the rideable Meadows creature and prices
the saddle in Rootstone/Ironwood components (`SD18`, `SF31`). Riding should
dramatically improve *revisiting* known areas — that is the value it is being
sold on, not raw speed.

### R6.3 ▶ Play gate — does riding make exploring better?

---

## Phase 7 — the village lives, the meadow reads

**R7.1 (wayfinding polish) and R7.2 (villagers and interior polish)
relocated to Phase -0.5** — owner directive, 2026-08-10: visual-pass work
runs before Phase 1 onward.

### R7.3 — Grow the authored space toward the 4–8 hour arc · `model: opus` · `tests: smoke_traversal` · M7, §30
The village and paths were the seed; §30 is explicit — dense rather than
empty, and do not pick a kilometre count before movement is fun (R0.11 and
R6.3 answer that).

**This is now the chapter's capacity item, and the single largest unpriced
piece of D23.** `terrain_playground.json`'s own first line says it is *a test
area, not the Meadows*, and 512 m on a side cannot hold spec §3's five bands, a
quarry, a dungeon, a major river, a mini-stronghold, an upper region and seven
perimeter spokes. Growing it costs a terrain rebake, more Terrain3D regions and
a real performance question on the Ally — none of which is budgeted anywhere.
R7.3 owns the *space and the bake*; the individual areas belong to `SD16`,
`SD17`, `SE21`, `SE23` and `SF31`. §30's rule still governs the number: prove
movement and riding are fun first, then size it.

### R7.4 — Map and minimap · `model: sonnet` · `tests: smoke_menu` · §23
The `map` action is bound, labelled and rebindable, and **read by nobody**.
Spec §16 adds the rule: the map reveals explored areas and landmarks and never
reveals everything automatically. The tracked-objective line and the two-list
quest log are `SB11`, not this item — R7.4 owns the map itself.

### R7.5 — Food buffs · `model: sonnet` · `tests: test_food` (new)
Buffs only. No starvation meter, ever.

### R7.6 — Berry plot and simple fishing · `model: sonnet` · `tests: test_farming` (new)
Deliberately shallow — §32 excludes deep farming.

### R7.7 — Player HP and armour slot architecture · `model: sonnet` · `tests: test_player_hp` (new)

---

## Phase 8 — the Meadows chapter (spec Phases C–G)

This was five items called "Team Tether and the culmination". `D23` turns it
into the chapter: five bands, two material tiers, physical gates, roughly
12–17 trainer battles, a dungeon, a mini-stronghold, a rescue, and a world
event. The `S<letter><number>` ids trace straight back to a numbered step in
`docs/MEADOWS_PROGRESSION_SPEC.md` §38, so a branch name carries its own
provenance.

**Why the whole chapter sits this late:** it consumes levels and XP (R4.1),
moves (R4.3), riding (R6.1) and trainer combat (R8.1). That is build order, not
play order. The honest cost is that the owner will not play a Band 1 trainer
battle for a long time — if that is the wrong trade, the cheap thing to hoist
is `R8.1` + `SC12` + `SC13` once R4.1/R4.3 exist. **That is an owner call, not
a firing's.**

### 8a — Lower Meadows (spec Phase C)

### R8.1 — World trainer encounter and team combat · `model: sonnet` · `tests: smoke_trainer_battle` (new)
Trainer-owned creatures **cannot** be caught. Spec §12 sizes what this has to
carry: 12–17 battles across the chapter, spread over meaningful locations
rather than one long trainer tunnel. It is the substrate for everything in 8a
through 8e, not a single encounter.

### SC12 — Mira, Oskar and Tam become the three Band 1 trainers
`model: sonnet` · `tests: test_dialogue_runner`
Spec §3 Band 1 and §35. **These three already exist** —
`data/config/village_npcs.json` places Mira, Oskar and Tam around the well with
greetings in `data/dialogue/village.json`, and the spec names the same three
("possible existing village NPCs can fill these roles if their existing
characterization fits"). Do not add three more people to the square. Mira
becomes the Meadow Keeper, Oskar the Bridgehand who holds the South Bridge
mechanism (he is already `villager_keeper`), Tam the Field Scout. Repalette
through `SB7`, extend their conversations, give each a battle offer. Done when:
all three are challengeable and none of them is a newly-placed body.

### SC13 — The three Band 1 trainer battles, each with a distinct lesson
`model: sonnet` · `tests: smoke_trainer_battle`
Spec §3 Band 1, §12. Mira is the introduction, Oskar is the gate, Tam teaches
switching and type awareness. Uses R8.1's system, `SB9`'s defeated flags and
`SC15`'s rewards. Recommended natural team level by the time the bridge opens
is roughly 5–8 — **guidance for tuning, never a check the game performs**
(§3, §19). Done when: each can be beaten once, sets its flag, and cannot be
re-fought into an XP faucet.

### SC14 — The South Bridge, and the key that opens it
`model: sonnet` · `tests: smoke_traversal`
Spec §3 Gate 1. The deeper Meadows is visible across an old bridge the player
can walk to at any level and cannot cross. Beating Oskar yields the South
Bridge Key (`SB10`); the bridge is a mechanism, not a message. Done when: the
crossing is visible from the village, blocked without the key, open with it,
and never explains itself with UI text.

### SC15 — Trainer battles pay out
`model: sonnet` · `tests: test_progression_state`
Spec §17 P1 step 9. A defeated trainer grants XP plus one authored reward — an
item, a TM, a recipe or a key — recorded against `SB9`'s flag so it cannot be
farmed. Done when: beating a trainer twice pays once.

### 8b — Rootstone (spec Phase D)

### SD16 — The Old Quarry
`model: sonnet` · `tests: smoke_traversal`
Spec §3 Band 2, §32. Rootstone deposits, old foundations, and the first
physical evidence Team Tether is routing something beneath the region —
conduits, excavation, energy-routing hardware, material moving toward the
stronghold. Evidence, not an explanation: §32's reveal ladder is explicit that
nobody here knows about the legendary. Done when: the quarry is reachable past
the South Bridge and yields Rootstone.

### SD17 — Burrow Warrens, the required dungeon
`model: opus` · `tests: smoke_traversal, smoke_combat`
Spec §3 Band 2. A compact cave: aggressive Ground creatures, Rootstone
deposits, chamber navigation, a guardian fight, one rare side branch. **The
guardian is a strong normal species — the spec says outright not to invent
another legendary**, and §20 forbids the model anyway. The optional deep branch
is where the Mudsnout evolution item lives (R4.6). Done when: it can be
entered, cleared, and cleared only once for its story reward.

### SD18 — Rootstone, the first progression tier material
`model: sonnet` · `tests: test_recipes`
Spec §10. Two tier materials in the entire biome — Rootstone then Ironwood — on
top of wood, stone, fiber and berries. Rootstone **upgrades what already
exists** rather than opening ten new systems: better orb tier (R4.9), workbench
upgrade (R2.7), better gathering tool (R2.1), the saddle component (R6.2), a TM
component, a modest camp/storage improvement. §32's ban on a large crafting
tree is the boundary. Done when: every recipe that consumes Rootstone improves
something the player already owns.

### 8c — the river and the relay (spec Phase E)

### SE21 — A real river divides the deeper Meadows
`model: opus` · `tests: smoke_traversal`
Spec §3 Band 3. Also closes a question the visual pass left open:
`R7.1-remainder-2`'s second bullet found "no middle-distance layering anywhere
in the set (no tree lines, ridgelines, or water)" and asked outright whether a
water feature would do more for depth-reading than more vegetation tuning. This
is that feature, and it is load-bearing for the story too. Done when: the river
reads as a landmark from the ridge and cannot be crossed except at authored
points.

### SE22 — Old Mill Crossing, seized and then restored
`model: sonnet` · `tests: smoke_traversal`
Spec §3 Band 3. Team Tether has disabled the crossing and taken the person who
knows the mechanism. Freeing them (`SE27`) yields the Mill Bridge Gear
(`SB10`) and the crossing opens for good. Done when: the same bridge is
impassable before the rescue and passable after, with no menu in between.

### SE23 — The Tether Relay Station
`model: opus` · `tests: smoke_traversal`
Spec §3 Band 3. The first mini-stronghold: a natural site partly
industrialised, a compact traversal and environment challenge, and the moment
Team Tether stops being something Grandpa described and becomes a threat the
player has personally confronted. R8.2's visual-language brief is used here
first, at small scale. Done when: it can be entered, fought through, and its
local tether/control equipment disabled.

### SE25 — Relay trainers and the relay captain
`model: sonnet` · `tests: smoke_trainer_battle`
Spec §3 Band 3, §12: two or three Team Tether trainers and a relay captain, all
on `SB8`'s rank palettes — the captain visibly outranking the trainers and
visibly below the Warden. Done when: the captain's defeat sets the flag `SE27`
waits on.

### SE27 — Free the captive
`model: sonnet` · `tests: test_dialogue_runner`
Spec §3 Band 3, §35. The captive ranger/researcher is built on the civilian or
main-character base — **not a new model** (§20/§21 apply to the whole cast).
Rescue scene, the Gear, and the first testimony that the region's isolation is
made rather than natural. They return to the settlement afterward (`SG46`,
§14). Done when: rescued, the NPC exists in the village and their dialogue has
changed.

### SE30 — The reveal ladder, laid in
`model: sonnet` · `tests: test_dialogue_runner`
Spec §32. Villagers know travel is controlled and trade restricted, and no
more. The quarry shows conduits. The relay shows energy routing and a captured
investigator. The captive knows the separation is artificial but **not** that a
legendary is the source. Grandpa's opening must not spoil any of it — §32 and
§1's "do not dump the entire plot in one speech" are the same instruction.
Done when: no line of dialogue before the stronghold names the legendary as the
power source.

### 8d — Upper Meadows (spec Phase F)

**R6.1 and R6.2 (riding, Meadowhart, the generic saddle) are worked here** —
spec §3 makes riding a Band 3 / early Band 4 unlock priced in Rootstone and
Ironwood. Their briefs stay in Phase 6; the ordering is this.

### SF31 — Ironwood, the second preparation tier
`model: sonnet` · `tests: test_recipes`
Spec §3 Band 4, §10. Supports stronger crafting, riding equipment, better
utility and final-stronghold preparation. It does not need to literally be
iron. Keep the economy small and readable. Done when: nothing needed for the
stronghold requires a third new material.

### SF33 — Standing at a Rift and seeing the next region
`model: sonnet` · `tests: none`
Spec §29, §34 Act V. `SA4` built the seven spokes; this makes the Upper Meadows
ones legible as **severed roads**: major conduits and pylons, roadbed
continuing on the far side of an unnatural seam, land visible across it, old
trade infrastructure abandoned mid-use. **The far side is a view, never a
place** — `CLAUDE.md`'s Biome 2 rule stands, and D23 says so explicitly.
Visual-affecting: blind pass required. Done when: a blind critic looking at the
seam says the two sides used to be joined.

### SF34 — Three regional captains, three Sigils
`model: sonnet` · `tests: smoke_trainer_battle`
Spec §3 Band 4. Field Captain (Ground team, Field Sigil), Ridge Captain (Air,
Ridge Sigil), Riverwatch Captain (Water/balanced, River Sigil), all on `SB8`'s
captain palette with one regional accent each. The three physical Sigils open
the Hall approach through `SB10`. This is what gives trainer battles direct
progression meaning. Natural team expectation entering this band is roughly
10–16 — **tunable, and never player-scaled** (§3). Done when: the approach is
sealed at 2/3 and open at 3/3, and the count is visible on `SB11`'s tracker.

### 8e — the stronghold and the first reconnection (spec Phase G)

### R8.2 — Authored stronghold route · `model: sonnet` · `tests: smoke_traversal`
Visual language: a sacred natural site industrialised by Tether. R7.1's ridge
silhouette is the promise this pays off. Spec §8 gives the interior: Outer
Works → Courtyard / Hall Approach → Tether Chamber Approach → Warden Arena →
Legendary Chamber, target first clear 30–60 minutes. **Not a giant puzzle
dungeon** — §8 rules that out unless separately decided. Note the same
industrialised-sacred-site language is used twice: first at `SE23`, then here at
full scale.

### SG38 — The stronghold trainer gauntlet
`model: sonnet` · `tests: smoke_trainer_battle`
Spec §8, §12: a patrol trainer at the Outer Works, a courtyard fight, an elite
before the Tether Chamber, and a recovery opportunity before the Warden. Two to
four battles across the five named spaces. Done when: a prepared team clears it
inside an hour and an unprepared one does not.

### R8.3 — The Warden boss fight · `model: sonnet` · `tests: smoke_boss` (new) · M14
His face is still painted, not modelled — needs a real sheet before this is
judged (HANDOFF §6). Note §20 covers *creatures*; a Warden face pass is still
legal under §22's budget. Spec §33 gives the character: he sincerely believes
separation prevents chaos and that ordinary people do not understand the risks.
Not a moustache-twirler. His line is closer to "You don't understand what these
barriers are holding apart" than "You cannot stop me."

### SG40 — The reveal: the legendary is the power source
`model: sonnet` · `tests: test_dialogue_runner`
Spec §28, §32, §33. Inside the stronghold and nowhere earlier — `SE30` holds
the rest of the ladder. The Warden warns rather than gloats, and genuinely
believes freeing it is reckless. Done when: the reveal happens in the
stronghold and the player makes the choice knowing what it costs.

### R8.4 — Free the legendary; it offers to join; triggers the release ceremony if full · `model: sonnet` · `tests: smoke_boss`
Spec §28's order, which is not optional: reach the chamber → the legendary is
freed → it **voluntarily** offers to join → the five-creature decision if the
roster is full (R4.10) → the tether machinery fails → `SG44`'s world event.

### SG44 — The first Tether Rift collapses and the world gets bigger
`model: opus` · `tests: smoke_boss`
Spec §27, §28, §30. The machinery fails, the exterior event runs, and one
severed spoke visibly reconnects — a distant landmass moving closer, a ravine
contracting, roots bridging a gap, a storm wall dissipating. **The carve-out is
not negotiable: this is a distant, non-enterable view.** `CLAUDE.md` forbids
Biome 2 work until the Meadows exit gate and D23 holds that rule over this
step; the spec's own §19 non-goals ("all seven future biomes") agree. No second
biome's terrain, spawns or species — the reconnected road still ends at a
believable barrier. If that reads as an unsatisfying payoff, it is a
`BLOCKED.md` question for the owner, not a licence. Done when: standing where
`SF33` put the seam, before and after the Warden, gives two visibly different
horizons — and the player still cannot walk into the next region.

### SG46 — The Meadows answers
`model: sonnet` · `tests: test_progression_state`
Spec §9. Barriers deactivate, patrol density drops, the rescued NPC is back in
the settlement, villagers acknowledge the victory, stronghold effects change,
the legendary is no longer tethered, and at least one outward spoke gains new
dialogue. Done when: no part of the region is visually or conversationally
identical to how it was before the Warden.

### R8.5 — The legendary's superior ride ability · `model: sonnet` · `tests: smoke_riding`
The tier above Meadowhart's (R6.2), not a parallel system.

### R8.6 — The larger mystery and future-biome hook · `model: sonnet` · `tests: test_dialogue_runner`
No longer open-ended: the mystery is spec §23–§31, and `SA4`'s seven spokes are
its physical hook. `GAME_DESIGN.md` §3's "the exact endgame motive remains
intentionally open" is false as of D23 and is amended there.

---

## Phase 8.5 — pacing and the chapter's own gate (spec Phase H)

### SH47 — Tune the chapter to 4–7 hours
`model: sonnet` · `tests: none`
Spec §17 P7, §38 Phase H. XP curve, trainer levels, material costs, travel
time, spawn density, and the specific instruction to **remove dead walking**.
Distinct from R9.1 (input feel and combat cadence) and R9.3 (performance on
hardware): this is arc pacing, and it can only be judged once 8a–8e exist.
§11's test of a good grind is the standard — "I know a harder challenge is
ahead, so I am deliberately improving my five", never walking in circles
killing identical weak enemies to inflate a number. Done when: a full run is
timed end to end and lands inside 4–7 hours.

### SH53 ▶ Play gate — the P0 fixes are actually gone on real hardware
`model: haiku`
Spec §38 step 53, §18. Ten minutes of a fresh Windows launch with mouse and
keyboard, never once having to think about cursor capture — through a menu
open and close, the name-entry screen, and an Alt-Tab. Then: the door cannot be
crossed before Grandpa, and no bearing walked from spawn falls off the world.
**This is the on-device confirmation `RB1`, `RB2` and `RB4` all still owe** —
each is closed on diagnosis and a real fix, none on the owner's own hands.

### SH54 — Audit: nothing in the chapter assumed new creature credits
`model: haiku` · `tests: none`
Spec §38 step 54, §20. Walk every item shipped for this chapter and confirm
none of them installed, requested or planned a new creature mesh. Cheap, and
worth doing once at the end, because the constraint is a budget the owner holds
and a single quiet violation spends it.

---

## Phase 9 — polish gate (M15)

### R9.1 — Input feel, combat cadence, catch feel, camera · `model: sonnet` ▶
### R9.2 — Controller UI readability on the Ally · `model: sonnet` ▶
### R9.3 — Performance on target hardware · `model: sonnet` ▶

**R9.4 (visual cohesion pass) relocated to Phase -0.5** — owner directive,
2026-08-10: it now serves as that phase's own checkpoint, run before
Phase 1 onward rather than at the end.

### R9.5 ▶ **The exit gate.** All twelve of `GAME_DESIGN.md` §33. Only the owner can call it.

---

## Found along the way — small, unscheduled

- `docs/ASSET_LEDGER.md` claims "everything currently in the build is CC0
  1.0". False (Meshy creatures, Plumberry pack). **Blocked on the owner** for
  the correct wording. The website's parallel stale claim was fixed in the
  overhaul; the ledger's was not.
- Backpack has no use/consume/equip/drop/split verb; the only action is
  moving an item. **Promoted in practice: R2.5 depends on "use" for
  `potion_small`, and food buffs (R7.5) need it after that.** `model: sonnet`
- `data/config/menu.json` twice cites `tests/test_menu_config.gd`, which does
  not exist. The file is `tests/test_menu_data.gd`. `model: haiku`
- `menu.json` documents `hotbar_columns`, absent from the backpack block and
  read by nobody. Either build the hotbar (§19 wants quick tool select — R2.1
  makes this real) or delete the comment. `model: haiku`
- Opening the menu mid-fight is silently refused with no on-screen
  explanation. `model: haiku`
- **`smoke_traversal` and `smoke_combat` are still intermittent** (aggression's
  own flake is fixed — RB3, see `DONE.md`). Traversal: every failure has the
  player at y = −0.4 m, never falling through — "the ground is not
  continuous" was a misdiagnosis; done when 20 consecutive headless passes.
  Combat: a docs-only commit failed on the *last* swing checked ("did no
  damage 95.0 -> 95.0") after the fight had already resolved normally;
  confirmed a flake by re-running the identical commit clean. Both read as
  timing races on their surface, the same way aggression's did before RB3
  found the trainer's own follower pal was physically walling them in —
  worth checking whether either of these has a similarly mundane, non-AI
  cause hiding under a plausible-sounding guess, rather than assuming they
  are the same kind of flake as each other. A recorded run log, the way
  R4.11 prescribes and RB3 confirmed, beats more CI-output reasoning.
  `model: sonnet`
- **Spec §6 — 6–10 optional activities, not forty shallow quests.** Lost Pal,
  Broken Cart, Night Watch, The Old Champion, Deep Warren, River Nest, Team
  Tether patrols, Meadowhart Herd. Each wants a home in Phase 8's bands rather
  than a list of its own; promote individually when the band it belongs to is
  built. `model: sonnet`
- **Spec §14 — home must stay relevant.** Grandpa's dialogue evolves per band,
  creature beds and recovery, storage and crafting, villagers updating what
  they know, the rescued NPC returning, story check-ins. The farmhouse should
  not become a room you never re-enter after the first twenty minutes.
  `model: sonnet`
- **`tools/survey.gd` and `tools/preview_creatures.gd`, both found broken by
  R0.8.5, relocated to Phase -0.5 as VP1/VP2** — owner directive,
  2026-08-10: visual-pass work runs before Phase 1 onward, and both tools
  are needed to verify that phase's own work.
