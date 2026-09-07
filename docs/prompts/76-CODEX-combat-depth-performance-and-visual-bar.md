# /goal — MAKE THE EARLY GAME FUN: COMBAT DEPTH, THE ALLY FRAME RATE, AND THE VISUAL BAR

Written 2026-09-07 by the orchestrator session, rolling up one owner report, one
owner hardware run and one blind visual verdict into a single contract. Nothing
in it has been implemented — every section below is work, not a record of work.

Read `CLAUDE.md`, `docs/00_START_HERE.md`, `docs/CURRENT_STATE.md` and
`docs/GAME_VISION.md` before changing anything. Then read the three evidence
documents this contract is built on, all on branch
`claude/early-game-combat-design-fp3tua`:

| Document | What it is |
|---|---|
| `docs/specs/COMBAT_DEPTH_PLAN.md` | Why fights are a button mash, read from the shipped code, and the seven-lane ladder out. The design detail behind §3 below. |
| `docs/PERF_ALLY_FIRST_MEASUREMENT_2026-09-07.md` | The first frame times ever measured on the owner's ROG Ally. The evidence behind §2. |
| `ralph/reports/JUDGE-OWNER-RUN-20260907/VERDICT.md` | A blind visual verdict on GPU frames from that same run. The evidence behind §4. |

Raw evidence: `ralph/reports/OWNER-KICKOFF-20260907T023802Z/` and
`ralph/reports/gate-f-run-20260907T023802Z-owner/` on branch
`owner-run/20260907T023802Z`.

---

## 0. The owner report this all answers

> "Still feels not that fun but I think because combat isn't good and that's most
> of what you're going to be doing early game is leveling up by doing combat.
> Right now it's just button mash."

Three separate causes were found for that one sentence. They are ordered below by
what has to be true first, **not** by how interesting they are.

## Scope, and what this contract may not do

- **No new creature meshes and no Meshy generations for the Meadows.** This
  collides head-on with §4's creature finding and the collision is deliberate —
  see §4.3. Differentiate with materials, textures, modest scale, animation, VFX,
  habitat and encounter context, per `CLAUDE.md`.
- **No Biome 2 work.** The Meadows exit gate is unchanged.
- Do not redesign progression, Meadows geography, the five-creature rule, or the
  story. Preserve working behaviour outside scope. Tunables go in `data/config`.
- **Do not invent the answers in §5.** Those are owner decisions. Implement the
  work that does not depend on them, and stop at the ones that do.

---

## 1. First, and it is cheap: stop corrupting your own evidence

The blind judge found four camera stands that are broken as *captures*, not as
art. They will poison every future visual round until fixed.

- Camera inside the trainer's legs, both hands floating detached at frame top
  (`locations` sheet, ~row 13 col 1).
- Camera inside an untextured grey box (`route_day_001`, row 3 col 2).
- Two tiles that are solid dark-green fill — camera inside a canopy.
- A robed NPC clipping the near plane in `survey.png` tiles **1 and 5**. Both are
  framed survey stands, so this is systematic, not one bad shot.

**Fails if** a re-run of the same stands reproduces any of these.

Note that `tools/_capture_route_strip.gd` already has a refusal mechanism
(`capture_check.readable_problems` faults empty, behind, cropped, occluded
frames). These got through it. Either the survey path does not use it or its
rules do not cover these cases; find out which before adding a fifth rule.

---

## 2. The frame rate, which is upstream of everything else

**Six of nine authored camera stands render under 8 fps on the owner's Ally.**
Best is 11.3. This is the first time the game has been profiled on the target
device; every performance number the project has optimised against until now was
a structural proxy measured in a container, and
`docs/specs/PERFORMANCE_BUDGET.md` says so itself, twice.

### 2.1 Do this measurement before anything else in this section

Re-run `tools/_owner_fps_probe.gd` on the Ally with `grass_field.enabled`
**false**, then **true**, at the same nine sites, changing nothing else.
`KICKOFF.cmd -Only perf`, roughly twenty minutes. This needs the owner's
hardware; it is the one step in this contract that cannot be done in a container.

- If the six slow sites jump and the three fast ones barely move, the cost is
  grass fill rate and overdraw. Work the grass: LOD, density falloff, overdraw,
  the 640 m far-cover reach.
- If they barely move, the grass is exonerated and the next step is a real GPU
  capture, **not** more counter-reading.

**Do not fund optimisation work before this runs.** Everything else is guessing.

### 2.2 What the data already rules out

Draw calls do not predict frame rate in this data. The fastest stand carries the
second-most draw calls; the slowest nearly the fewest; the same place from two
heights differs 3.3x in draw calls for 1 fps. Two gated levers exist —
`structure_visibility_ranges` and `scatter_lod_ranges`, both `false` in
`data/config/performance.json`, both written and reasoned — and **both target
draw calls**, which is why they are still off. `scatter_lod_ranges` may deserve a
re-test against *frame time*, since its original "not where the frames are"
verdict was also reached against draw calls.

### 2.3 One inconsistency to reconcile while you are in there

`data/config/vegetation.json` lines 527 and 739 assert "`scatter_lod_ranges` is
now TRUE in performance.json ... so these ranges are LIVE" and size the canopy and
ground-layer ranges on that basis. It is `false`. Every `lod_*` key in that file
is inert — which the same file states correctly elsewhere
(`_comment_lod_range_t1_hall_4`), after an earlier lane spent a re-bake and a
render round discovering it. Fix the two wrong comments so the next lane does not
lose the same afternoon.

### 2.4 Why this section is first

At 6–7 fps a 0.55-second telegraph is three or four frames. `D07` chose movement
over a dodge button on the reasoning that "movement is the dodge"; movement
cannot be the dodge at seven frames a second. **Mashing is the rational response
to a fight you cannot read.** Until the frame rate moves, nobody — owner, judge or
harness — can tell how much of "it's just button mash" is the design and how much
is the frame rate. Section 3 is still worth doing and its diagnosis stands on its
own (it was read from the code, not from feel), but its *acceptance* is not
trustworthy until this section lands.

---

## 3. Combat depth

Full design detail, with the code reading behind each claim, is in
`docs/specs/COMBAT_DEPTH_PLAN.md`. Summary of why the fight is a mash today:
nothing interrupts anything, so there is never a reason to stop attacking;
stepping off a telegraph costs more than eating it; the quick attack has a 100°
cone with facing that auto-corrects during wind-up, so aim is not a skill;
charged is the fifth press of a mash because energy comes only from landed
quicks; the creature has no resource; species differ in numbers, not in play; and
no move is learned by level, so the early loop the owner named — levelling by
fighting — makes the same fight bigger.

Ship in this order. Each is one lane, one PR.

**COMBAT-1 — poise, stagger, the player wind-up interrupt, hitstop, flinch.**
Both sides get a poise pool that drains on damage and refills after ~2 s; empty
staggers, cancelling the current action and opening a crit window. **Being hit
during your own wind-up cancels it** — this is the single change that ends
"hold RT", because a mashed swing into a telegraph now loses the swing. A charged
that lands during the opponent's TELEGRAPH interrupts it regardless of poise:
that is the parry substitute, needing no shield and no held button. WALL and ACE
get deep poise, DIVER and CURRENT shallow, through the existing G-2 merge. Files:
`combat_manager.gd` strike resolve and `_tick_action`, `wild_creature.gd`,
`data/config/combat.json`, the combat HUD.

**COMBAT-2 — creature stamina ("wind").** A shared pool every attack spends, that
regenerates only while not attacking. Out of wind means slow, weak attacks — never
helplessness that reads as a bug. Per-species caps in `species.json`; satiety and
bond move the cap, which is what finally makes camping matter (OP-0904-6). This is
the rhythm, and it is the Valheim lesson.

**COMBAT-3 — telegraph retune and the get-out-of-the-way verb.** Baseline
`telegraph` 0.55 → 0.8. **Blocked on owner decision §5.1.**

**COMBAT-4 — the third move slot and level learnsets.** A `slot: "skill"` move on
Y (free in a fight — the pause shell refuses to open mid-combat), on a cooldown,
whose job is to change the geometry of the fight rather than deal damage:
knockback cone, slow field, snare, dash-strike, mist. Learned at level 4 so
levelling gives something before the tournament; evolution swaps it; a TM can
replace it. Largest lane, and the one that makes species play differently.
**Blocked on owner decisions §5.2 and §5.3.**

**COMBAT-5 — the opponent answers back.** `combat_ai.gd::decide()` stays pure and
stays four beats; it gains inputs, not states. It uses its charged move; trainer
bodies and CHARGER/DIVER react to the player's wind-up past 3 m; low-health
behaviour per profile; officer-rank trainers use their own skill move.

**COMBAT-6 — loud types.** Chart 1.25/0.8 → 1.5/0.67, VFX scaled by
effectiveness. **Blocked on owner decision §5.4** — this moves the tournament and
Warden numbers that D77 and W-1 pinned, so both smokes must be re-run.

**COMBAT-7 — the early fight ladder.** Content, no code: each of the first seven
fights teaches one thing and rewards the thing it taught. The table is in the
plan's §6.

### 3.1 How "not a button mash" is proven

Extend `tests/smoke_combat_baseline.gd` with a second scripted pilot beside the
existing MASHER: a **READER** that steps out of the cone during TELEGRAPH, attacks
during RECOVER, spends charged into a telegraph when it can reach, uses the skill
on cooldown, and keeps wind above 25 %. Assert in `chapter_curve.json`
`difficulty`, per band entry:

- READER pays ≤ 55 % of what MASHER pays against the floor trainer.
- MASHER loses the lead to the band's top trainer every run, and loses the five
  ≥ 25 % of runs from Band 3 up.
- READER wins ≥ 75 % against the band's top trainer.
- MASHER still beats an ordinary wild — a wild must never wall a beginner — but
  pays ≥ 25 % of the lead.
- No single hit takes ≥ 50 % of a full-health entry-level creature (G-3, unchanged).

**Fails if** both pilots produce the same numbers. That means the change added no
decision and the lane did nothing.

D77's rule still holds: a *floor* trainer may hurt but may not wall the five. The
wall moves up to the band's top trainer, and applies to the masher only.

---

## 4. The visual bar

Full verdict, with the frame and tile of every defect, is in
`ralph/reports/JUDGE-OWNER-RUN-20260907/VERDICT.md`. The judge was blind: no
history, no frame-rate data, no budget (D06), and these were GPU frames from the
owner's own machine rather than the usual software-rendered survey.

**Bar A (the project's own key art): partially yes.** The village, the Team Tether
courtyard and the dusk stand match the board. The wilderness between them does
not. **Bar B (the Palworld bar the owner set): no.**

### 4.1 The two fixes with the best ratio, and no conflict with §2

**Reallocate the chroma budget.** Palworld holds a muted sage-and-tan ground so
creatures and the player carry all the saturation and pop at any size. Tetherbound
is inverted: acid yellow-green grass and orange-brown path are the most saturated
things in frame and creatures the least, so the deer in `route_day_020` r4c1
vanish entirely at thumbnail. Desaturate and de-yellow the ground; give the chroma
to creatures and the player. This is a colour-allocation decision, not a modelling
one, it is the single highest-value change in the verdict, and it costs nothing at
runtime.

**Give the route landmarks.** 23 of 24 route stages contain nothing a player could
navigate by, name, or return to. The exception is `route_day_024` — Team Tether
pylons with the cyan cable, and the fort on the ridge — the only genuine landmark
language in the set. **That exception is also the sanctioned path:** `CLAUDE.md`
reserves Meshy for Team Tether hero objects (pylons, relay apparatus, the tether
machine), so the one stage that works is built from exactly the asset category the
rules already allow. Extend that vocabulary along the corridor, plus terrain
massing and the existing nature/village/prop families. Do not solve this by
inventing new asset families.

### 4.2 Scene fixes, all gated behind §2.1

Everything here is real, and everything here touches density, scatter or draw
distance — which is precisely what §2 suspects of costing the frame rate. **The
judge wants the scatter pushed further out and made denser; the perf measurement
suspects grass fill rate. These pull against each other.** Settle §2.1 first, then
work this list against the answer:

- Recover the dark end of the day value range — deeper canopy shadow, darker
  trunks — so silhouettes separate (`route_day_008`, `_012`).
- Add aerial perspective; `survey.png` tile 3 is a flat texture-free green wash
  meeting the sky at a hard line.
- Fix the hard shadow-distance band with no caster across `survey` tiles 1 and 5.
- Push and fade the grass/detail scatter radius; it currently stops dead in a ~4 m
  bubble around the camera.
- Author the scatter rather than distributing it: cluster, cut clearings, vary prop
  scale. ~80 of 84 route tiles share one composition — path down the middle, even
  bushes, trees banded at the horizon.
- Fix the tree scale ladder: `composition` r1c1 holds a ~1.8 m diameter trunk
  (implying a 25–35 m tree) in the same frame as ~4 m mid-band trees, with nothing
  between.
- Relight night. `route_night_002` r1c2 is a near-black rectangle; clouds stay
  brighter than the ground, inverting real night contrast. `route_night_012` works
  only because the pylons emit their own light.
- Take oxblood off friendly props — the wayfinding arrow in `route_day_016` r2c1
  uses the faction danger colour in friendly meadow and is untextured. This breaks
  the reserved-palette rule D87 exists to protect.
- Water depth gradient and shoreline blend (`places` r1c3); path material detail
  (largest area in most frames, carries none); sky variation across the route.

### 4.3 The finding that a hard rule forbids you to fix — route it, do not act

The judge's verdict is that the creature art is **three incompatible languages**:
the rock-shelled tortoise is stylised, chunky and matches the world; the blue
raptor (`route_day_024` r2c3) is a recoloured photoreal eagle; the deer
(`route_day_020` r4c1) are generic photo-fur; and a badger head is grafted onto a
stylised rock shell inside one silhouette. The trainer and the villager beside him
are in two different character styles. Its conclusion is that this **cannot** be
fixed by lighting, placement, retexturing or rescaling, because the silhouettes
were never designed as a set.

`CLAUDE.md` forbids new creature meshes and Meshy generations for the Meadows, and
forbids spending a Meshy generation without owner-supplied reference art.

**These are in direct conflict, and resolving it is the owner's call, not this
contract's.** Do not commission meshes. Do not quietly re-texture and declare it
addressed. Put the conflict to the owner with the verdict attached, and record the
answer in `docs/decisions/`. In the meantime, do the parts that *are* allowed and
that measurably help: the chroma reallocation in §4.1 (which raises creature
contrast without touching a mesh), and giving the Team Tether grunt a readable
silhouette value — he is currently grey-on-grey against grey stone and is the
least readable character in any frame.

---

## 5. Owner decisions — do not invent these

1. **The get-out-of-the-way verb.** Movement only, retuned / a burst step on A
   with no invulnerability / a dodge roll with i-frames. The plan recommends the
   burst step: it keeps D07's spatial reading and the cone-test hit model intact
   and is one flag away from becoming a roll. A is currently inert in a fight.
   Blocks COMBAT-3.
2. **Y as a third move slot in combat.** Free today, since the pause shell refuses
   to open mid-fight. Blocks COMBAT-4.
3. **Moves learned by level** (a species skill at 4, swapped by evolution), or
   TM-only. Blocks COMBAT-4.
4. **Type chart 1.25/0.8 → 1.5/0.67.** Blocks COMBAT-6 and re-opens D77 and W-1
   numbers.
5. **A wild creature can exhaust your creature** (the out-of-wind slowdown) — is
   that the right kind of cost? Blocks COMBAT-2's tuning, not its structure.
6. **The creature-coherence conflict in §4.3.**

---

## 6. What is already done — do not redo it

The evidence pipeline was repaired on 2026-09-07 and is not part of this
contract's work. Knowing this saves a re-diagnosis:

- `tools/owner/kickoff.ps1` now probes push access in `prepare` and fails loudly
  in the first minute instead of after an eight-hour run; cannot hang on a
  credential prompt; commits the written record rather than a 170 MB payload; and
  its `chain` phase now reports what its segments actually did. `RUN_SUMMARY.md`
  opens with a Verdict section.
- `-Resume` was broken twice over — it skipped `prepare` (nulling the repo and
  Godot paths) and skipped *failed* segments (because a blocked segment still
  writes `INVENTORY.json`). Both fixed. `-Resume <stamp>` now genuinely continues
  a run and retries what failed.
- `tools/owner/DELIVER.cmd` packs the text evidence and pushes the run branch in
  one double-click.

**One live constraint this exposes.** In run `20260907T023802Z` the chain ran only
S01 and S02; S03–S10e and all twelve capture lanes were refused by the harness's
own budget guard, which priced S03 at 4.2 h against a 4 h ceiling — it missed by
about 5 %. The harness's own message names the fix: *"A GPU or a split evidence
lane — not a shorter wait; the waits exist so fights resolve."* Do not raise
`segment_cost_ceiling_s` to paper over it: at 0.049 s/frame the full chain does not
fit in a night whatever the ceiling says. **If §2 lands and the frame rate
doubles, the chain fits.** That is a second reason performance comes first.

---

## 7. Definition of done

Per `docs/00_START_HERE.md`: code existing is not done. For this contract:

- §1 holds when a re-run of the same stands produces no broken frames.
- §2 holds when the grass A/B has run on the Ally and its answer is recorded in
  `docs/decisions/`, with any optimisation work justified by it rather than by a
  counter.
- §3 holds when the two-pilot harness shows a reader materially outperforming a
  masher at every band entry, on a build whose frame rate makes the telegraph
  readable.
- §4 holds when a fresh blind judge, given new GPU frames and told nothing, no
  longer leads with the inverted chroma budget or the absent landmarks.
- The chapter's own acceptance is unchanged and still governs
  (`docs/acceptance/MEADOWS_EXIT_CRITERION.md`).

The owner's sentence is the real bar. The work is done when a played first hour
is fun, not when these sections are ticked.
