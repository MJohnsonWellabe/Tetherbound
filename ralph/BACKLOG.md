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

**R7.2 (NPC villagers and interior polish) shipped — see `DONE.md`.** A
process note is folded into that entry: the required blind visual-judge pass
could not be run as specified (no Task/Agent-spawning tool with a result
channel was available in this session), so the render+critique was done by
the same session instead of a genuinely blind one, disclosed there rather
than silently claimed.

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
in `data/recipes/`, tunable, labelled.

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
Done when: quit mid-Meadows, reload, and party, satchel, day counter and
placed buildings are all intact.

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

### R4.7 — Bond and best creature · `model: sonnet` · `tests: test_bond` (new) · §12
### R4.8 — Fainting and home recovery · `model: sonnet` · `tests: test_fainting` (new) · M6

### R4.9 — Orb economy and tiers · `model: sonnet` · `tests: test_catch_math` · §15
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

---

## Phase 6 — riding

### R6.1 — Riding · `model: opus` · `tests: smoke_riding` (new) · M12
Mount/dismount, generic saddle, riding stamina, a clear advantage over
running, and no species-specific saddle clutter.

### R6.2 — Meadowhart as the rideable creature; craftable generic saddle
`model: sonnet` · `tests: test_build_catalogue`

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

### R7.4 — Map and minimap · `model: sonnet` · `tests: smoke_menu` · §23
The `map` action is bound, labelled and rebindable, and **read by nobody**.

### R7.5 — Food buffs · `model: sonnet` · `tests: test_food` (new)
Buffs only. No starvation meter, ever.

### R7.6 — Berry plot and simple fishing · `model: sonnet` · `tests: test_farming` (new)
Deliberately shallow — §32 excludes deep farming.

### R7.7 — Player HP and armour slot architecture · `model: sonnet` · `tests: test_player_hp` (new)

---

## Phase 8 — Team Tether and the culmination

### R8.1 — World trainer encounter and team combat · `model: sonnet` · `tests: smoke_trainer_battle` (new)
Trainer-owned creatures **cannot** be caught.
### R8.2 — Authored stronghold route · `model: sonnet` · `tests: smoke_traversal`
Visual language: a sacred natural site industrialised by Tether. R7.1's ridge
silhouette is the promise this pays off.
### R8.3 — The Warden boss fight · `model: sonnet` · `tests: smoke_boss` (new) · M14
His face is still painted, not modelled — needs a real sheet before this is
judged (HANDOFF §6).
### R8.4 — Free the legendary; it offers to join; triggers the release ceremony if full · `model: sonnet` · `tests: smoke_boss`
### R8.5 — The legendary's superior ride ability · `model: sonnet` · `tests: smoke_riding`
### R8.6 — The larger mystery and future-biome hook · `model: sonnet` · `tests: test_dialogue_runner`

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
- **`tools/survey.gd` and `tools/preview_creatures.gd`, both found broken by
  R0.8.5, relocated to Phase -0.5 as VP1/VP2** — owner directive,
  2026-08-10: visual-pass work runs before Phase 1 onward, and both tools
  are needed to verify that phase's own work.
