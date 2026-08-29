# State of the three tracks — 2026-08-29

Written at the end of the 2026-08-29 production day, after every lane was
stopped and all work integrated. This is the **current, evidence-backed state
of the game** against the owner's own three production tracks
(`docs/owner-direction/README.md`).

It exists because this repo has repeatedly accumulated "confirmed fixed" prose
while the game stayed broken. Every claim below is tied to evidence produced
today — a CI job, a probe reading, or a rendered frame judged blind. Where
something is unverified or stale, it says so.

**Baseline:** everything described here is on `ralph/LAND-0829B`, which carries
every lane branch in the repo. `main` was at `961a8c02` when this was written.

---

## How to read this against the owner's documents

| Track | Owner document | The question it answers |
|---|---|---|
| 1 — Aesthetics | `docs/owner-direction/TETHERBOUND_VISUAL_STUNNING_PASS.md` | How should this place look and feel? |
| 2 — Reliability | `ralph/GATE_F_MASTER_PROTOCOL.md` | Does the integrated production game actually work? |
| 3 — Content / Fun | `docs/owner-direction/TETHERBOUND_MEADOWS_MIDGAME_FUN_REBUILD.md` | What makes this place and this gameplay fun? |

The owner's priority order is **fun first, then art-directed, then reliable —
all three required**. Do not trade one for another.

---

## TRACK 1 — AESTHETICS

### The independent verdict

`ralph/reports/JUDGE-VISUAL-2026-08-29.md` is the first blind visual review
this project has ever run. A Fable judge rendered the shipped pipeline's own
frames, judged them **before** reading any lane report or commit message, and
independently reproduced the owner's prior verdicts. Frames are in
`ralph/reports/judge-visual-2026-08-29/`.

| # | Subject | Verdict |
|---|---|---|
| 1 | Castle exterior / approach | **BAD** |
| 2 | Stronghold exterior / approach | **BAD** — "the worst-reading structure in the world" |
| 3 | Burrow Warrens mound / exterior | **BAD** |
| 4 | Burrow Warrens interior | **GOOD — protect it** |
| 5 | Open Meadows ground and grass | **ACCEPTABLE** |
| 6 | Water and shorelines | pond GOOD, river ACCEPTABLE, stream BAD → **ACCEPTABLE** |
| 7 | Sky and sun across the day cycle | **BAD** |
| 8 | Terrain macro composition / landmarks | **ACCEPTABLE as a skeleton, dragged down by what stands on it** |

**The review is complete — all eight subjects.** Two headlines:

**A full day of castle and stronghold visual work moved neither verdict.** Both
were BAD before the work and BAD after, judged blind.

**The macro skeleton points the player at the two worst surfaces in the game.**
Band 5's approach axis is the best composition in the set — a forked path, the
pylon line marching toward the stronghold, cyan cables, crystal flanking; a
player reads "that way is the endgame" from one frame. And what it aims at is
untextured grey boxes on the skyline and a stronghold that reads as a black
slab from every angle. The composition is doing its job; the surfaces are not.

### The judge's own bar questions, answered

- **Do these frames read as belonging to the keyart's world?** **No — but for
  the first time it is a near miss in places.** The band-1/band-2 meadows, the
  pond and the trainer in blade grass are recognisably reaching for the keyart
  and getting close. What breaks belonging is *everything built* plus the
  night/golden failures — the keyart's two signature moods.
- **Beside the Palworld references, same kind of game?** **Yes for the
  open-field frames, no overall.** Open meadow and pond read as the same genre.
  "The moment a structure enters frame the answer flips to no." Since the
  chapter's climax is architecture, the overall answer is no.

### The judge's split of what is fixable, and what needs new art

**Fixable by changing the scene** (materials on existing meshes, lighting,
composition, scatter): crimson night and the missing golden blend; sky/ground
weather disagreement; dashed ground seams; floating pebbles and the floating
castle plinth; the black-rendering NPC; the invisible stream; river bank
texture scale; a second grass species; re-tinting the Warrens' mint rocks;
real materials on the stronghold shell and the horizon boxes; the sun halo.

**Needs art not in the build:** a weathered stone material set with
gate/hoarding-scale detail modules for the castle kit, and an exterior facade
language for the stronghold (banners, scaffolds, apparatus). Both are
material/kit work on existing meshes — **no new hero mesh required**, so this
stays inside the reuse and no-new-mesh rules — but neither is achievable by
re-scattering what is already placed.

Two further macro defects worth naming: **no aerial perspective** (distant
hills render at near-field saturation, so depth flattens and the horizon reads
like a backdrop), and **regional differentiation is prop-deep** — bands 1, 3, 4
and 5 share one grass carpet, one tree family, one palette, differing only by
what is parked on them. Only band 2's grove has its own light identity.
"Increasingly demanding regions" is not yet something the terrain itself says.

### The most serious open visual defect: the day cycle

Subject 7 is the one that most damages the game as a whole, because it affects
every location at once:

- **Deep night renders crimson.** From ~20:30 through at least 02:00 the entire
  world renders in a blood-red wash — red sky, red-orange ground *brighter*
  than the 20:30 dusk, golden-hour-length shadows at midnight. This also breaks
  the project's own palette rule: oxblood is reserved for Team Tether danger,
  and the passive clock paints the whole safe world with it for a third of
  every day.
- **Golden hour never happens on the driven clock.** Frames bracketing the
  18:00 keyframe are flat grey-blue overcast.
- **But both looks exist and are good** via the snap presets:
  `apply_time("night")` is blue, moonlit and navigable; `apply_time("golden")`
  is genuinely lovely. So the keyframes are right and the **continuous blend
  path is what is broken**.

That last point matters and is new. A standing rule has said "do not fix the
golden-hour frame blind — settled: a Terrain3D streaming defect, not lighting."
The judge's evidence is narrower and points elsewhere: snap presets produce the
correct look, the driven clock does not, at the same viewpoint. **That reopens
the question in a specific, testable direction** — compare the blend path
against the snap path — rather than reopening it blind.

### Other named Track 1 defects, none yet fixed

- Castle: unweathered kit albedo with AO blotches at the wrong scale; the
  plinth **floats** (open shadow gap) on sloping ground; mid-wall turrets a
  third the girth of corner towers, reading as sandcastle decoration.
- Stronghold: crushes to a featureless near-black box from the flank; approach
  cobble and wall cobble collide at 2–3× scale; the gate is a plain rectangular
  hole with no frame or depth.
- Warrens exterior: three unrelated rock languages in one frame; boulders read
  as chamfered cubes; granite noise aliases into checkerboard at distance.
- Ground: one grass species everywhere at uniform density; a mid-distance smear
  tier whose boundary tracks the camera; **dashed seam lines on the terrain**
  visible enough to steer by; path pebbles hovering above the dirt.
- **A villager NPC renders as a 100% black silhouette in full daylight** in band
  2 — whatever material path lights the trainer correctly is not reaching it.
- Water: the river channel reads as engineered riprap, not a natural bank; the
  **stream is invisible from its own bank** — a player led there would not find
  it.
- `tools/capture_water.gd` does not pin the clock, so its frames come back in a
  dusk wash and are unusable for colour judgement. Tool defect, not a scene
  defect.

### What genuinely works — protect these

The Warrens interior (material, value structure and story agree). The pond.
The Team Tether pylon line — distinct silhouette, correctly grounded, reads as
faction tech at meadow scale. The trainer model itself. Band 2's grove. The
19:00–20:50 dusk slide.

---

## TRACK 2 — RELIABILITY (GATE F)

### Gate F run 3 is incomplete and was stood down mid-run

Authoritative: `ralph/reports/handover-GATE-F-RUN-3-2026-08-29.md`.
Run directory: `ralph/reports/gate-f-run-20260828T183531Z`.

| Segment | State |
|---|---|
| S01–S09 | **Complete**, `INVENTORY.json` `"complete": true` |
| S10 (finale) | **BLOCKED** at step 27/121 — real combat cost makes it infeasible on this host. `BLOCKER.md` written. No `S10-exit` save exists. |
| X02 | **Complete** (170/170 steps) |
| X03 | **Killed mid-run** by the stand-down — telemetry only, not evidence. Re-run from scratch. |
| X01, X04, X05, X06, X07, X08 | **Never started** |

X04 can start immediately (its three prerequisite saves all exist). X07 and X08
are teleport-permitted and cheap. X05 is blocked in shape by the missing
`S10-exit` and needs a judgement call. X06 is likely to hit S10's cost problem.

### Recurring defect found across three segments

S07, S08 and S09 all reinforce a **corridor stranding at South Bridge**, and
`party size 1` throughout the run is attributable to that stranding — *not* to
RIG-11, which was fixed and re-verified after S06. This is the single most
repeated reliability finding in the run.

### Two findings documents are stale and now carry warnings

`ralph/reports/GATE_F_RUN_3_FINDINGS.md` and `GATE_F_RUN_3_RIG_FINDINGS.md`
were left in the state a *third* session wrote them and narrate RIG-11 as still
open. Both now carry a prominent staleness banner. **Rewrite them from the run
directory's own `INVENTORY.json` files before trusting a sentence.**

### Integration reliability — what today actually proved

Two integration landings, both verified at CI **job** level across all 55 jobs:

- `ralph/LAND-0829A` → `main` at `961a8c02`. Carried seven lanes.
- `ralph/LAND-0829B` — carries every remaining branch; state at time of writing
  in the handover.

Three real defects were found *by integration itself*, none by any lane in
isolation:

1. **The Burrow Warrens vault was unreachable** — a nondeterministic hazard,
   not a lane conflict. The vault's own Elder Trailpup spawns inside the
   doorway clearance disc and can wander into the passage under ordinary idle
   AI, where it is frozen collider-and-all. Fixed with a per-spawn wander leash.
2. **The scatter bake went stale on merge.** Two lanes each re-baked correctly
   against their own branch; the merged config fingerprinted as neither.
3. **A trainer undershot its region's level band** (`pasture_drover_juno`,
   12 → 13).

All three are the same shape: correct in isolation, broken in combination.
That is the argument for one integration branch over parallel sweeps.

---

## TRACK 3 — CONTENT / FUN

### Landed today

- **§7 Tether Relay** — verified already built and correct; two authored-content
  gaps closed in band 3 (641m → 323/318m, 679m → 239/214/226m, measured with
  `tools/_probe_gate_f_corridor.gd`).
- **Band 4 seam gaps** — the two largest in the chapter, 674m and 475m, closed.
- **§11 roster temptation** — audited and pinned across bands 1, 2, 3, 5.
- **§14 reward ladder** — mapped onto the three regional captains' existing
  ordinal identity. Found **three orphaned item classes with zero acquisition
  path anywhere in the game** despite complete item data: three stat elixirs
  and five armour pieces. `items.json`'s own comment said the elixirs "belong
  in the world — a dungeon, a captain, a stronghold"; nobody had ever placed
  them.
- **§8 captain differentiation** — each of the three captains now signals its
  own axis; a false encounter-order claim was corrected.
- **§10 readiness signals** — South Bridge, Warrens, Vance and the Hall.
- **A chapter-ending soft-lock fixed.** `stronghold_climax.gd::_place_legendary()`
  rebuilt a caged legendary on *every* post-finale load, and an autosave landing
  between `legendary_freed` and `legendary_settled` permanently refused the
  machine prompt — that save's chapter ending could never resolve. Now covered
  by `tests/smoke_stronghold_reload.gd`, which reaches a case the single-session
  finale test structurally cannot.
- **Three Creek Hollow water creatures were spawning under the lakebed** —
  3.3m/2.9m/1.8m below the surface, never breaking it, reading from the bank as
  pale smudges. Moved within the same hollow to grid-searched positions.

### Still open

- The §12 dead-Meadows cadence work is measured but not finished everywhere.
- Whether the orphaned elixirs and armour are now actually reachable end-to-end
  in play is **pinned by tests, not by a playthrough**.
- No continuous player-path evidence run has confirmed the chapter is *fun*.
  That is Gate F's job and Gate F is incomplete.

---

## CROSS-TRACK: the live owner directive

**The Stronghold and Meadows Hall are to become ONE location, redesigned from
scratch, with Fable doing the design.** Issued by the owner 2026-08-29. This
supersedes all prior stronghold plans and the dressing work on
`ralph/T1-ARCH-STRONGHOLD`.

Measured facts behind it:

- Castle (`scripts/world/landmark.gd`, `const SITE`) at **(150.0, 7595.0)**.
- Stronghold works (`data/config/stronghold.json`, `site.at`) at **(0.0, 7560.0)**.
- **~154m apart** — two unrelated structures sharing a vista.
- `stronghold.json`'s own `_comment_where` still calls the works "the WORKS
  BEHIND the castle", which stopped being true at the OW5D relocation, and its
  `_comment_ow5d_relocation` flags that `yaw_deg` was never re-derived for the
  new approach and is "very likely WRONG". Nobody ever did.

**Reference art:** `docs/art/reference/15_Legendary_Tether_Machine.png` is headed
**"WARDEN STRONGHOLD"** and carries the full material key (dark stone, dark
metal, brass/gold, tether energy, runic glow, chain/mechanical) plus a 20m scale
bar. Boards 13 and 14 complete the Team Tether family, with orthos under
`assets/creatures/tetherbound/*/reference/`. **There is no architectural
elevation or massing board anywhere in the repo** — verified across
`docs/art/reference/`, `REFERENCE_CANON.md`, and every non-creature image in
`docs/` and `assets/`.

**Two questions the owner has not yet answered:** whether board 15 is the
reference meant, and whether one Fable owns design end-to-end or the
design/judge separation holds (the owner's own routing forbids Fable judging
what it authored).

---

## Documentation cleanup performed today

- **~2.26 GB of superseded Gate F evidence frames deleted** from three runs
  (`20260825T201354Z`, `20260827T025303Z`, `20260827T223957Z`) — 1,286 image
  files. **All metadata, logs and markdown were kept**, so every citation in
  `GATE_F_MASTER_PROTOCOL.md` and the lane/rig/defect logs still resolves. Each
  run carries a `FRAMES_REMOVED.md` explaining what went and how to recover it.
  `ralph/` dropped from 2.5 GB to ~210 MB in the working tree. **This does not
  shrink git history** — the blobs remain reachable in earlier commits, and
  changing that would mean rewriting shared history, which was deliberately not
  done.
- **9 orphaned top-level `ralph/` documents removed** — superseded coordinator
  handovers and one-off coordination/plan notes with **zero inbound references**
  from anywhere in the repo.

  An initial pass removed 31 documents. A reference census then showed that 22
  of them are still actively cited — `ASSESSMENT_2026-08-23.md` 27 times,
  `GATE_D_LANE_CONTRACT.md` 25, `PROMPT.md` 42, `STATUS.md` 20 — so deleting
  them would have left roughly 200 dangling links across the repo. **Those 22
  were restored.** Only genuine orphans were removed, and a re-run of the census
  confirms **zero dangling references remain**.

  The lesson for the next cleanup: this repo's docs are densely
  cross-referenced and load-bearing. Count inbound citations before deleting;
  a superseded document that is still cited wants a staleness banner, not a
  delete.
- **Deliberately kept**: everything owner-authored (`OWNER_PLAYTEST_*`,
  `OWNER_DIRECTIVES_*`, `OWNER_FEEDBACK_*`), all canon
  (`docs/decisions/`, `conventions.md`), all live routing (`START_HERE.md`,
  `ACTIVE_GAME_PLAN.md`, `ACTIVE_TASKS.md`, `PROMPT_COMPATIBILITY_MAP.md`),
  the backlog and its history per `CLAUDE.md`'s explicit instruction, and
  `GATE_D_REMAINDERS.md` (cited by the band-split fixture policy).
- Every removed file remains in git history.

---

## What the next coordinator should do, in order

1. **Land `ralph/LAND-0829B`** once CI is green at job level across both result
   pages. It contains every branch in the repo.
2. **Delete the merged branches** (owner action — sessions get 403 on ref
   delete). After landing, everything except `CONTENT-0828B` is fully merged;
   `CONTENT-0828B` was independently verified to carry nothing unique.
3. **Resolve the two open questions** on the stronghold/Hall rebuild, then set
   it up. It is the owner's live directive and the highest-value work on the
   board.
4. **Fix the day cycle.** It is the single visual defect that degrades every
   location simultaneously, and the judge's evidence points at a specific,
   testable cause.
5. **Finish Gate F run 3** — X04, X07 and X08 are cheap and can start
   immediately. Rewrite the two stale findings documents from the run's own
   inventories.
6. Do **not** restart eight lanes. The owner asked to slim down.
