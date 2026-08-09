# Backlog

Ordered. Work top-down. **This file is the state of the project.**

Legend — `▶` owner play gate, stop the loop. `🔒` needs Meshy credits.
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

### R0.8.5 — Full blind visual review pass — REQUEUED against the new build
`model: sonnet` · `tests: none` · **Owner-requested, 2026-08-09.**

Still owed, and the overhaul makes it *more* valuable, not less: nothing in
the new build — boar-sized creatures (D19), the farmhouse interior, the
village, the paths — has ever been blind-reviewed, and most of the roster
never passed a blind gate on its final installed form (only Terrapup did).
Use the harness that exists: `.claude/skills/visual-judge`, per `D06` and the
reports in `docs/reviews/`. Scope: every creature (all sixteen plus Grandpa,
the Warden, the Veridian legendary), the trainer, **the village and farmhouse
interior** (buildings exist now — the old "nothing to review" note is dead),
and the meadow with its new paths.

Two operational notes that keep being relearned:
- `apt-get install -y libegl1 libegl-mesa0` fixes `libEGL.so.1` and makes
  `turntable.py` genuinely render. Ephemeral container — re-run it each
  firing, it is not a standing blocker.
- Known standing defects the review will re-find (not news):
  Ripplet/Galewisp's ungraded eyes, the Veridian Stag's failed gate, the
  Warden's painted face, Brooktail's missing paddle tail, Tuskroot still
  wearing `ollie-the-songbird.glb`, and the per-species "flag for a pass"
  notes in `DONE.md`. The point is one complete current-state record.

A partial pass already ran on 2026-08-09 against the five download-page
frames (`docs/reviews/2026-08-09-site-frames-blind-critique.md`) and failed
both bar questions; treat it as input. Its largest finding is squarely this
task's remit and is a **flag-for-the-owner, not a silent fix**: the three
starters do not share a style with each other or with the trainer ("three
assets from three different store packs"), and unifying them — rework vs
replace — is an art-direction decision to be made on this review's evidence.

### R0.11 ▶ Play gate — the owner plays the NEW first day, end to end
Wake in bed upstairs → downstairs to Grandpa, the belt, orbs and potions →
out the door to the three starters → choose and name → the village square and
the paths → harvest along the tutorial route → a fight and a catch → make
camp before dark → rest to morning, day counter ticks. `GAME_DESIGN.md` §33
criteria 1, 3, 6 and 11 — plus the two things D19 flagged for exactly this
playtest: does the combat camera crowd at the new sizes, and does the arena
still feel roomy.

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

### R4.5 — Tuskroot's REAL model 🔒
`model: sonnet` · `tests: smoke_art`
The last stand-in — still `ollie-the-songbird.glb`. Since D20 it never spawns
wild, so the only place it will ever be seen is the evolution ceremony: the
single most emotionally loaded reveal a creature model gets. `CLAUDE.md`'s
prototyping rule applies with full force — the ceremony may not be judged
with a songbird wearing a boar's name. Needs its own call first: fresh
generation from the sheet, or a graft off Mudsnout's finished model ("must
read as Mudsnout grown up" argues for the graft; try it first, it costs no
credits). Height 2.15 per D19; strictly larger than Mudsnout per D17.

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

### R5.1 — Day/night cycle · `model: sonnet` · `tests: test_day_cycle` (new)
The day *counter* already advances via camp rest; this makes time visible —
sun, sky, "before dark" meaning something. `grandpa_road`'s "make camp before
dark" line is currently a promise the world doesn't keep.

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

### R7.1 — Wayfinding polish
`model: sonnet` · `tests: smoke_traversal`
The path network shipped as the wayfinding spine (square → house, pond,
practice meadow, ridge); finish the language: signposts at the junctions, and
the **stronghold silhouette on the ridge** — the M7 "distant landmark" that
makes the far edge of the map a destination instead of a fence.

Three additions from the 2026-08-09 blind critique of the site frames
(`docs/reviews/2026-08-09-site-frames-blind-critique.md`), all "the meadow
reads" work:
- **The world ends 40m out.** Nothing stands on any hill or horizon in any
  frame; put trees and the landmark into the middle and far distance bands.
- **The olive/lime ground seam.** The detailed ground texture fades to flat
  pale terrain colour at distance, splitting every frame in two at a hard
  line; push the fade distance out or blend the far colour toward the near
  material's tone.
- **Continuous ground cover.** Isolated same-size tufts at even density read
  as confetti; the references stand on continuous grass with clustered
  variety and real clearings.

### R7.2 — NPC villagers and interior polish
`model: sonnet` · `tests: smoke_opening`
The village square has barns, a well and a windmill and nobody in it. A few
villagers on `npc_body.gd` with a line or two each, and the farmhouse
interior dressed past the minimum the opening needed. No quest system — that
is a design decision to flag, not invent.

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
### R9.4 — Visual cohesion pass · `model: sonnet` ▶
Use the `visual-judge` skill against `docs/reference/` — the world target,
not the character target.
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
- **`smoke_traversal` and `smoke_combat` are both intermittent.** Traversal:
  every failure has the player at y = −0.4 m, never falling through — "the
  ground is not continuous" was a misdiagnosis; done when 20 consecutive
  headless passes. Combat: a docs-only commit failed on the *last* swing
  checked ("did no damage 95.0 -> 95.0") after the fight had already resolved
  normally; confirmed a flake by re-running the identical commit clean.
  Both read as timing races; both reject healthy work at random under
  auto-merge, which makes them real defects, not noise. A recorded
  fight/run log, the way R4.11 prescribes, beats more CI-output reasoning.
  `model: sonnet`
