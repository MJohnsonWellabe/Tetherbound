# Tetherbound — where the project actually is

Written as a handoff: everything a fresh context needs to pick this up without
re-deriving it. Read `CLAUDE.md` first for the hard rules, then this.

**Last updated:** 2026-08-11 (second update that day — read both notes).

**The art direction is now settled, and two P0 bugs are fixed.** The owner
played the published build and reported that the opening soft-locks (you can
never talk to Grandpa, so you leave the house with no starter) and that the Ally
is choppy — high memory, ~25% GPU. Both were root-caused and shipped: `6dffa21`
and `28af489`. In the same message the owner supplied
`docs/ENVIRONMENT_AND_UI_BIBLE.md` and an NPC concept board, made canon by
`docs/decisions/D24-one-nature-family-one-village-family.md`: **one nature
family, one village family, one prop family**, Medieval Village as the Meadows
vernacular, keep Terrain3D, no return to Forward+, Meshy reserved for Team
Tether hero objects, and the HUD rebuilt. Two rules changed with it — **no
generation without an owner-supplied reference sheet**, and **D23 §20 stands
even at 5000 credits**, so creatures and humans are permanently rework-only.
`ralph/BACKLOG.md` gained Phase -0.9 (the P0 fixes), Phase -0.6 (`EV1`–`EV10`,
the look) and Phase -0.55 (`NP1`–`NP4`, the cast); most `R9.4-remainder-*` items
and `SB7`/`SB8` are collapsed into them rather than running in parallel.

Earlier that day: the owner delivered
`docs/MEADOWS_PROGRESSION_SPEC.md` — the Meadows stops being a vertical slice
and becomes the game's first chapter, 4–7 hours, with the Team Tether macro-
story settled. Read `docs/decisions/D23-the-meadows-is-the-first-game.md`
before anything else in this file: it changes what several older documents
mean, adds two hard production constraints, and names the two carve-outs where
an older rule still wins. `ralph/BACKLOG.md` grew four sections for it
(Phase -0.75, Phase 3.5, a restructured Phase 8, Phase 8.5).

Before that, the 2026-08-10/11 owner-directed interactive
session worked Phase -0.5's remainder through the start of Phase 1 —
two PC bugs found on the owner's own hardware (a walk/run animation freeze,
and the ROG Ally black-screen freeze — RB4, root-caused to a Forward+/
Vulkan render-thread stall and fixed by switching the shipped renderer to
Compatibility, `docs/decisions/D01`), the signposts and stronghold
silhouette, ridge-biased vegetation clumping and ground-cover clustering
(landed with an honest partial — see `ralph/BACKLOG.md`'s
`R7.1-remainder-2`), a path-trench terrain bug root-caused to two
overlapping building pads, and NPC villagers plus interior dressing.
`ralph/BACKLOG.md` is the ordered plan; this file is the state.

---

## 1. What the game is

A Godot 4 third-person survival/crafting creature-training game. Windows and
the ROG Ally, controller-first, solo. You own **five pals, ever** — carried on
the **creature belt** Grandpa gives you in the opening (D18) — no storage, no
boxes. Combat is real-time and **piloted**: you play as your creature while
your trainer stands behind it. The human never fights.

The current target is the **Meadows chapter** — the vertical slice as it was,
plus the 4–7 hour arc the owner specified on 2026-08-11 (D23). Nothing from
Biome 2 starts until Meadows passes its exit gate.

The story behind it, settled by D23: the eight biomes were one connected
landmass. Each of the eight legendaries is a living conduit for a natural
force, and Team Tether binds them to hold **Tether Rifts** open — physical
separations that keep the regions apart, because a divided world is one you can
control the movement of trade, resources and people through. Freeing a
legendary collapses its Rift and physically reconnects a region. The Meadows
ending demonstrates that for the first time.

---

## 2. The Meadows roster — every creature and what it is

Canon lives in `docs/art/wild/` (owner-supplied pack) with production sheets in
`docs/art/reference/wild/`. **That pack wins over any older board or note.**
See `docs/decisions/D13`. Heights below are the **D19 table** — the owner
resized the whole roster after playing; do not "restore" the older numbers.

### The three starters — DONE, in the game

| # | Name | Type | Height | What it is |
|---|---|---|---|---|
| 1 | **Terrapup** | Ground | 2.00 m | Badger/canine cub. Warm brown fur, cream face stripe, **grey stone mantle plates over shoulders and back**, oversized digging paws, teal eyes. The quality benchmark. |
| 2 | **Ripplet** | Water | 1.95 m | Otter/newt. Turquoise skin, cream belly, translucent ear frills with pink inner membrane, broad fan tail fin. |
| 3 | **Galewisp** | Air | 1.90 m | Fox-bird glider. Cream down over layered blue/teal feathers, **enormous feathered ear tufts**, wing-membrane forelimbs. |

### The twelve wild species + one evolution

Only **one** creature evolves in this biome: **Mudsnout → Tuskroot**. Tuskroot
**never spawns wild** (D20) — it is evolution-only, and the evolution mechanic
itself is still unbuilt (Ralph Phase 4).

| # | Name | Type | Height | What it is | Status |
|---|---|---|---|---|---|
| 4 | **Bramblebun** | Ground | 1.50 m | Meadow rabbit, living moss and purple flowers along its back. The tutorial creature — `roles.practice` in `spawns.json`, highest catch rate in the game. | DONE |
| 5 | **Mudsnout** | Ground | 1.55 m | Rooting piglet runt, small emerging tusks, not armoured. Pre-evolution of Tuskroot — and the only route to one. | DONE |
| 6 | **Trailpup** | Ground | 1.70 m | Lean prairie canine, coyote-like. **No stone plates** — the mantle is Terrapup's. | DONE |
| 7 | **Meadowhart** | Ground | 2.10 m | Rideable meadow deer with leaf-and-leather saddle. Must NOT read as the legendary. | DONE |
| 8 | **Burrowback** | Ground | 1.85 m | Broad low badger, enormous shovel claws, loose rock nodules in clusters — never one continuous shell. **Must NOT read as Terrapup** — recolour pending (`SA5`). | DONE, recolour pending |
| 9 | **Paddlenewt** | Water | 1.65 m | Amphibious newt, translucent orange fin frills, huge golden eyes. | DONE |
| 10 | **Mosshell** | Water | 1.77 m | Pond turtle, mossy stone-plate shell, very low centre of gravity. | DONE |
| 11 | **Brooktail** | Water | 1.60 m | River otter, broad flat paddle tail (missing on the model — see §6). | DONE |
| 12 | **Reedwing** | Water/Air | 1.80 m | Waterfowl, at home on water and in the air. `species.json` takes one type — filed `water`. | DONE |
| 13 | **Pipwing** | Air | 1.35 m | Tiny round songbird, oversized teal eyes. Smallest in the roster. | DONE |
| 14 | **Duskhush** | Air | 1.70 m | Owl, serene not spooky — no glowing eyes. | DONE |
| 15 | **Galecrest** | Air | 2.15 m | Large hawk, a serious predator — `roles.aggressor` in `spawns.json`. Must NOT read as Galewisp. | DONE |
| 16 | **Tuskroot** | Ground | 2.15 m | Armoured boar, **evolved from Mudsnout**. Must read as Mudsnout grown up. | **STAND-IN — still `ollie-the-songbird.glb`** |

### The named characters

| Name | Status | Notes |
|---|---|---|
| **The trainer** (player) | DONE, GLB regen queued | Sheet 04. Teal jacket, green scarf, belt orb-holder, backpack. See §6 on the cm-unit skeleton. |
| **Grandpa Elias** | DONE, GLB regen queued | Retired explorer. **Now a live NPC**: waits downstairs in his farmhouse in the opening, gives the belt, orbs and potions via `give:` dialogue effects (D18). |
| **Warden of the Meadows** | DONE-ish, GLB regen queued | Biome boss. **Face is painted, not modelled** — needs a real reference sheet before he can be finished. |
| **Veridian Stag** | DONE, but failed its gate | Ground legendary, 2.60 m — unchanged by D19, still above everything. See §6. |

**Deliberately NOT built: Sparkit** (Electric fox kit). Meadows has three
types only — recorded in `docs/art/REFERENCE_CANON.md` as future-biome.

### The four distinction rules — and the one lever left to enforce them

Three were already canon (D13): Trailpup has **no** stone plates, that mantle
is Terrapup's; Galecrest must not read as Galewisp; Meadowhart must not read as
the legendary. **D23 adds a fourth: Burrowback must not read as Terrapup**, and
the owner reported it from real play.

D23 also removes the option everyone reaches for first. **§20 forbids new
creature meshes and Meshy generations for the Meadows outright** — the
installed meshes are the meshes. Separation is done with
`tools/art_pipeline/blender/grade.py`'s repair path (plain numpy and Pillow, no
Blender, no credits), plus modest scale, animation, VFX, habitat and behaviour.
`SA5` and `SA6` in the backlog are that work: Burrowback toward charcoal and
slate, and the four birds pushed apart harder than would normally be necessary
because the silhouettes overlap more than ideal.

### Scale rule (D12, amended by D19) — do not "fix" this

Creatures are large on purpose, twice over: D12 made them peers of the 1.8 m
trainer; **D19 raised the starters to boar scale (1.90–2.00 m) and shifted the
wild band to 1.35–2.15 m** after the owner played and wanted his own creature
to dominate the frame. The concept sheets' centimetre figures are *biology*,
true on the page; game scale is a separate question the owner has now answered
three times, always upward. A blind reviewer will call this a 3–4× scale
error — it is not.

---

## 3. What is built and working

- Movement, camera, sprint, jump, stamina, fall damage; Terrain3D terrain and
  vegetation. Player walk 5.0 / sprint 8.6; piloted pal 5.6 (tunable, in
  `data/config/`).
- **The opening, restaged indoors and fully wired (D18).** Wake in bed
  upstairs in Grandpa's farmhouse (Quaternius Farm Buildings + Ultimate
  Furniture, CC0, in the ledger), talk to him downstairs, receive the
  creature belt plus starter orbs and potions through `give:item:count`
  dialogue effects, exit to the three starters by the door, choose, name,
  fight, catch. Interior camera profile via `camera_rig` `set_target`
  profiles. `smoke_opening` covers it end to end.
- **A village and paths.** Data-driven village (`village.json`: barns, well,
  windmill, fences around a square near Grandpa's house). Dirt paths are
  painted into the Terrain3D control map at bake time along authored
  polylines, vegetation keeps clear of them, and the path network is the
  wayfinding: square → house, pond, practice meadow, ridge. Terrain rebaked
  with flats under structures.
- **The first-day arc.** ~10 harvest nodes (wood/stone/fiber/berries) along
  the tutorial path; camp buildable placement (ghost preview → spend costs →
  campfire + bedroll geometry); rest-until-morning advances the day counter
  and heals; `grandpa_road` dialogue seeds "make camp before dark".
- **Piloted combat** (D07), with the playtest feel pass in: auto-face the
  target during attack windup, lunge impulse at windup start, 0.3 s attack
  input buffer, quick cooldown 0.40, enemy reposition 3.2 speed / 4.0 m
  distance. All tunable.
- **Aimed orb catching** (D08), with the throw feel pass in: world-space
  trajectory arc preview (`throw_preview.gd`, sharing `_release()`'s exact
  math), aim profile `sensitivity_scale` 0.55 **finally wired into
  `camera_rig`** (it was authored day one and read by nothing),
  `response_exponent` 2.0 fine-aim curve, `near_target_scale` 0.6, cancel
  works during release windup, piecewise snap assist (full lock inside half a
  body-width, smoothstep falloff to one body-width). **Throws spend
  `orb_basic` from the satchel** — orbs and potions are real items in
  `data/items.json`.
- **The wild table is data (D20).** `data/config/spawns.json`: ~12 clusters,
  ~22 creatures, a `roles` block ({practice: bramblebun, aggressor:
  galecrest}) that tests resolve instead of hardcoding ids, respawn delay in
  the file. Tuskroot removed from the wild; Mudsnout spawns.
- **Pause menu** (backpack, pals, build tabs), **settings** with full control
  remapping persisted to `user://settings.json`, **free-build toggle** (D16),
  the **`Game` autoload** (party of five, satchel, day counter), a follower
  pal.
- **A landmark stronghold silhouette and wayfinding signposts** (R7.1/
  R7.1-visual), blind-reviewed and iterated: real wall/roofline/crenellation
  geometry replaced three bare prisms, signpost arms/labels fixed for
  overlap and readability. Long-range silhouette legibility is a known,
  narrower open remainder (`R7.1-visual-remainder-2`) — placeholder-primitive
  architecture may not be able to fully clinch "fortress" at wayfinding
  distance; revisit once real art replaces the primitives.
- **Ridge-biased vegetation clumping and ground-cover clustering**
  (`R7.1-remainder`), three rounds of blind-critic iteration. Genuine,
  visible improvement — real clump/clearing structure where there was
  uniform scatter — but neither the horizon-population nor the
  continuous-ground-cover bullet fully passed the blind critic in three
  rounds; see `ralph/BACKLOG.md`'s `R7.1-remainder-2` for specifics and
  what a next pass should try.
- **Three NPC villagers** in the village square (`village_npcs.gd`), each
  with a short flavour greeting, and Grandpa's house interior dressed past
  "undressed grey box" (rugs, a second bed and bookcase, a gear table,
  surface clutter). Villager bodies reuse the existing Grandpa/trainer rigs
  through a real material-level tint rather than a stylistically
  incompatible free asset — the creature/human art-pipeline question stays
  parked in `ralph/BLOCKED.md`, not silently resolved.
- **The renderer is Compatibility (`gl_compatibility`), not Forward+**
  (`docs/decisions/D01`, reversed 2026-08-11). The owner reproduced a hard
  freeze on the shipped Windows build twice; on-device data (boot log +
  Task Manager) pointed at a Forward+/Vulkan render-thread stall specific to
  the Ally's iGPU driver. Switching sidesteps Vulkan entirely and also
  matches the renderer every headless CI render has used all along. Cost:
  no SDFGI/volumetric fog/Forward+ shadows. Real on-device confirmation
  that the freeze is actually gone is still worth having.
- 299 unit tests, smoke tests per feature. CI exports a Windows build and
  publishes it on every push to `main`.
- The website is redesigned around real screenshots; the stale "sourced
  stand-ins" claim is gone. Re-shoot it after each visual milestone.

---

## 4. What is NOT built

- **Tools and durability** — gathering is bare-handed; nothing gates it.
- **Real tree/rock harvesting on the vegetation** — the ~10 harvest nodes are
  authored interactables, not the scattered trees and rocks themselves.
- **Crafting** — no recipe produces `orb_basic` or `potion_small`; Grandpa's
  gift is currently the only source.
- **Potion use in the field** — and `encounter_director.gd` still
  **auto-heals the ally fully after every fight** (`_ally.heal_fully()`),
  which now actively undercuts potions and camp rest. Removing it is on the
  backlog, deliberately *after* crafting exists.
- **Save/load. Still not one write to `user://` outside settings.**
- **The release ceremony** (M5), **evolution** (Mudsnout → Tuskroot is data
  plus D20's intent, no mechanic), **riding**, **day/night visuals and
  weather** (the day *counter* advances via camp rest; nothing else changes),
  **map/minimap**, **food buffs**.
- **Build pieces beyond the camp** — floor/wall/roof/fence, workbench,
  storage have no placement content yet.

---

## 5. The open work

`ralph/BACKLOG.md` is the ordered plan, read it rather than trusting any
summary here.

**As of the owner's third feedback pass (2026-08-11) the top of the file moved
again.** The order is now:

```
Phase -0.95  LP1, LP2            the loop itself (D25)
Phase -0.9   SA0-orbs, SA1-lod   the tails of the two shipped P0 fixes
Phase -0.6   EV1..EV10           the look — acquire the packs, then use them
Phase -0.55  NP1..NP4            the cast — the modular system, then the bases
Phase -0.75  SA2..SA6            the spec's own P0 items
Phase -0.85  HD1, HD2, CO1,      HUD, item access, gate+key, Grandpa's
             SA7, SA8            urgency beat (owner's third pass)
Phase -0.5                       whatever EV/NP did not absorb
Phase 1 onward                   unchanged
```

Phase -0.85 sits below -0.75 in the file only because it landed after — read
order at the top of `BACKLOG.md` is what actually governs pick order, not this
list. It carries its own note on why: three of its reported gaps (follow-pal,
orb-throw visuals, potion use) turned out to already be built, checked against
code before anything was added, so it also corrects two stale claims elsewhere
in the file (`R2.5`, "Found along the way") rather than just adding new items.

Phase -0.6 sits above the older `SA` items deliberately: `EV1` acquires assets
that several of them are waiting on, and there is no sense retinting a
settlement `EV6` rebuilds. Phase -0.55 sits with it because `NP1` is built
against rigs that already exist, so it blocks on nothing and improves the three
villagers standing in the square today.

After those, the file runs Phase -0.75 → Phase -0.5 → Phase 1 → Phase 2 →
Phase 3 → **Phase 3.5** (the progression framework the whole chapter stands on:
flags, physical gates, the objective tracker — its two NPC items moved up to
Phase -0.55) → Phases 4–7 → **Phase 8, now the Meadows chapter itself** in five
lettered sections, 8a Lower Meadows through 8e the stronghold and the first
reconnection → **Phase 8.5** for pacing and the chapter's own gate → Phase 9.

The pre-D23 shape, still accurate for everything Phase -0.5 and earlier: Phase
-0.5's visual pass is
functionally done (signposts, stronghold silhouette, vegetation clumping/
ground cover, villagers, interior dressing — several with narrower honest
remainders recorded, not false "done"s). Next is **R9.4**, a full-game
visual pass covering everything already in the game (not just what this
session touched) — owner directive: no fixed round cap, iterate until the
blind critic is actually satisfied, buildings and terrain called out as
the current weak points. Then Phase 1's **pal→creature rename** (R1.1) and
a vocabulary sweep of this file (R1.2); then Phase 2's remainder (tools,
durability, real harvesting, orb/potion crafting, then killing the
auto-heal); then humanoid GLB regeneration; persistence; combat/progression
including Tuskroot's real model and the evolution ceremony.

---

## 6. Known defects, honestly

**The giant-player bug — fixed, with a debt outstanding.** The
trainer/grandpa/warden GLBs carry centimetre-unit skeletons under a 0.01
Armature node with ×100 inverse binds. `character_model._fit()` measured the
mesh AABB *through the node chain* (reading 0.018 m), applied ×100 — and the
skeleton-driven **render** became 180 m while every AABB-based test read
1.80 m. Fixed by measuring in render space:
`scripts/characters/render_bounds.gd` walks the skeleton chain × the
collapsed skin transform; `smoke_art` now measures all three humans in render
space and trips on fit factors outside [0.1, 10]; `animate_humanoid.py` now
applies scale the way the creature pipeline always did. **The debt:
regenerating the three humanoid GLBs through the fixed pipeline is queued for
Ralph** — until then the fix is compensating for malformed source files.

**Tuskroot's options narrowed (D23, spec §20).** Whatever the verification in
`R4.5` finds, "generate a fresh one from the sheet" is no longer available —
§20 forbids new creature generations for the Meadows. The remaining paths are
verify the installed model (which R0.8.5's review suggests will pass), or graft
off Mudsnout's finished model, which costs nothing either way. If both fail it
becomes a blocked question for the owner rather than a credit spend.

**Tuskroot is still `ollie-the-songbird.glb`.** The one stand-in left, and
since D20 it is unreachable in the wild — but the evolution ceremony will put
it on screen at the single most emotionally loaded moment it could possibly
appear. Real model before that mechanic, not after.

**Creatures "static posed and sliding around" in combat.** Owner-reported,
unexplained, still open (R4.11). Ruled out by measurement: clips exist and
drive bone motion, the animator ticks with real velocity. Best lead: idles so
subtle they read as a freeze. Next step is a recorded fight logging clip vs
body speed — not more reasoning.

**Ripplet/Galewisp eyes** were destroyed by ungraded eye regions (the grade
pipeline now mandates eye guards; these two predate that). **The Veridian
Stag failed its blind gate** (off-style saturation, hue-camouflaged,
faceless) — rebuild against a written spec, don't patch. **The Warden's face
is painted, not modelled** — needs a 01–04-quality sheet first.
**Brooktail's paddle tail is missing** on the model. Per-species "flag for a
pass" notes live in `DONE.md`/`ASSET_LEDGER.md`; R0.8.5's blind review pass
is the consolidated record when it runs.

**`smoke_traversal` and `smoke_combat` are intermittent.** Same commit passes
and fails; traversal failures always have the player at y = −0.4 m, never
falling through; the combat flake hits the *last* swing checked. Both look
like timing races. Recorded, not chased (see the backlog's found-along list).

**Trainer backpack** undersized vs sheet 04, ragged hood. Deferred: a volume
edit on a textured mesh costs a retexture — fold into the GLB regeneration if
cheap, otherwise leave.

**The ROG Ally freeze (RB4) is fixed by diagnosis, not yet by an on-device
replay.** Root-caused via boot-log + Task Manager data the owner supplied
directly from the frozen device (0% CPU/disk/network, never resolving —
ruled out a slow shader compile) to a Forward+/Vulkan render-thread stall.
Fixed by switching the shipped renderer to Compatibility (§3,
`docs/decisions/D01`). Real on-device confirmation that this actually
resolves it is still open, same pattern as RB1/RB2.

**A real MultiMesh bug silently broke vegetation colour jitter for most of
this session.** `vegetation.gd`'s per-instance colour jitter (added to fix
"ground cover reads as one flat hue") set `use_colors` *after*
`instance_count`, which `MultiMesh` requires the other way around — the
flag never took effect and jittered instances kept their default colour.
Found via a background agent's render log (11,317 repeated engine errors
in one render), fixed 2026-08-11. This means the `R7.1-remainder` visual
critiques that ran before the fix landed were judging a build where the
jitter fix was largely non-functional — worth keeping in mind if
`R7.1-remainder-2`'s ground-cover finding gets re-tested.

---

## 7. Corrections — things previously asserted that are false

Recorded because they were written into commit messages and reports:

- **"Every AABB-based test read 1.80 m" was true and worthless.** The giant
  player shipped because the tests measured the same broken code path the bug
  lived in (§6). The lesson joins the earlier ones: a test that shares its
  measurement with the thing it tests proves only that the code agrees with
  itself. `smoke_art`'s render-space check exists because of this.
- **There is no stray Icosphere in any model.** The sphere was invented by
  Blender's glTF importer on read; both downstream consequences were fixed at
  source. `strip_strays.py` is a container check, not a repair.
- **"10 species left" was wrong; it was 13.** A row in `species.json` is not
  art.
- **"Opening beats 1–6 built" was false when written.** Six components
  existed unwired. Since R0.9 and this session's D18 restaging the opening
  genuinely is built, wired and smoke-tested — but the shape of the original
  error is still worth naming: **a file that exists and passes its unit tests
  is not a feature until something in a scene instantiates it.**
- **The website claimed the creatures were "sourced stand-ins"** long after
  twelve wild species and three starters had real production art. Removed in
  the redesign; the standing backlog item is to re-shoot after each visual
  milestone so it cannot rot that far again.

---

## 8. How the work is being done

**The Ralph loop** (`ralph/PROMPT.md`) runs the backlog autonomously between
owner sessions: hourly firings, a lease on the `ralph-status` branch, work
shipped via `ralph/<task-id>` branches through CI auto-merge. `▶` play gates
park the loop until the owner plays. Big overhauls — like this session — are
done interactively and then **recorded into the backlog** so the loop's
picture stays true.

Earlier roster work ran as **parallel agents in isolated git worktrees**;
those boundary rules (one grade-script owner, creature agents don't touch
`scripts/**`, gameplay agents don't touch `assets/pals/**`) still apply
whenever that pattern is used.

**Godot's import cache does not travel between worktrees.** After merging any
branch that adds art, run an editor import pass, then `git checkout
project.godot` — that pass strips the file's documentation comments.

---

## 9. The art pipeline

`tools/art_pipeline/`. Governed by `docs/art/TETHERBOUND_3D_ART_PIPELINE.md`.

The loop, proven on the full roster: **crop the sheet → 3 cheap candidates →
blind critique → mesh fix → cleanup/remesh → retexture against the concept →
rig → procedural clips → grade → install → in-engine validate → blind gate.**

**The blind critique is the mechanism, not a formality.** A fresh subagent
gets only renders and concept art and is told nothing about what changed. It
has caught a real defect on every creature and repeatedly caught bugs in the
tooling itself.

Two hard-won rules: **state the signature feature in capitals and first**, or
the generator drops it; and **generate heads separately** — a whole-figure
pass at 30k polys cannot resolve an eye socket.

Session additions: `animate_humanoid.py` now applies scale like the creature
pipeline (the humanoid GLBs need regenerating through it — §6);
`scripts/characters/render_bounds.gd` is the render-space measurement every
character fit and `smoke_art` check now goes through. Birds rig with
`finish.py rig --kind bird` (a first-class path since Galecrest).

Meshy credits: **~175** at last check (`meshy.py check`). Roughly 90 per
species. The key lives in `MESHY_API_KEY` and **must never be written to any
file**.

---

## 10. Testing and shipping

- `godot --headless --path . --script tests/run_tests.gd` — 299 unit tests.
- `tests/smoke_*.gd` — one per feature, boots the real scene, injects input.
- **Address spawn-dependent tests through `spawns.json`'s `roles` block**,
  never a species id (D20).
- **UI focus navigation cannot be tested with `Input.action_press`** — it
  needs `Input.parse_input_event`.
- **Run `smoke_traversal` headless.** Under xvfb + software GL it takes 25×
  longer and flakes under CPU load.
- Headless rendering (`turntable.py`) needs `apt-get install -y libegl1
  libegl-mesa0` in a fresh container — one line, not a wall.
- Every push to `main` builds a Windows `.exe` and publishes it. The download
  link is `/releases/download/latest/Tetherbound-windows.zip` — **by tag**.
  The `/releases/latest/download/` form 404s because the release is a
  prerelease.
