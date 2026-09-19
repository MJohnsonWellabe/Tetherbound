# Tetherbound — State

**Read this first, every session.** What is true right now, what is next, what
is broken, and what the owner last said.

**Updated in place.** Do not create a dated status file beside it. Keep this
file under **25 KB** — when it grows past that, move everything older than the
current campaign to `archive/docs/state-history/<date>.md` and leave a one-line
pointer here.

**Last updated:** 2026-09-19 · **`main` at** `9ff367d5`

---

# 1. Where the project is, in one paragraph

The Meadows is close to a complete first chapter and the other three biomes are
partially built. The owner's own verdict after a full Meadows playtest was
"about 70 % of the way there," and the two things they named as biggest were
**not knowing where to go** and **the visuals, then the amount of content that
draws you off the beaten path**. Since then the 43-item playtest list has been
worked to completion on source and the Meadows named-location visual ledger
reads 23/23. What remains for the Meadows is not a feature list — it is the
A1–A11 experience proof, off-trail content density, and the visual bar holding
across the whole chapter rather than location by location.

Four lanes are live: **combat depth**, **Meadows look**, **Cloudreach look**,
**content density**.

---

# 2. Verified status

## 2.1 The Meadows

| Ledger | Current | Evidence |
|---|---|---|
| Owner playtest, 43 items across 5 tiers | **43 / 43 accepted** | strict row-by-row audit at `44056970`, on `main`; per-row evidence in `ralph/reports/MEADOWS-0912/STRICT-43-ROW-AUDIT-2026-09-15.md` |
| Named-location visual ledger | **23 / 23** | per-location captures and code-blind verdicts under `ralph/reports/MEADOWS-0912/` |
| A1–A11 continuous-run proof | **open** | no clean no-intervention campaign run has completed |

**Neither ledger by itself closes the Meadows.** Regression and export
verification plus a continuous non-Quick campaign must still prove A1–A11.

The 23 named locations are 20 unique places in `map_landmarks.json` (22 rows;
the Tether Relay and Old Mill Crossing appear in both arrays) plus The Inn,
Practice Meadow and Stronghold Approach. The last promotions to PASS were The
Highfield, The Ridgeline Watch and Stronghold Approach.

**Content density is the weakest verified area.** The acceptance target is 6–10
optional activities per major region. The last recorded count was **1 of 6** on
2026-08-30 with five more "in flight," and **that number has not been
re-verified since** — treat it as unknown, not as 1/6. Recounting from real game
data is the content lane's first task.

## 2.2 Combat

COMBAT rungs 1–3 (poise/stagger, wind-up telegraphs, the burst step) are
**substantially built and unit-covered** — `test_combat_stagger.gd`,
`test_combat_wind.gd`, `test_combat_burst.gd`, source checkpoints `dfb28289`,
`9c77c1e6`, `b92d2e5f`, camera repair `e570daaf`, all on `main`. The dodge
question is settled: **Option B, the burst step** — a short committed
cost-bearing reposition, no shield, no block, no held button.

Rungs 4–7 (fight identity, type legibility in the moment, camera under every
size pairing, the boss as an exam) remain open. See `ACCEPTANCE.md` §6.

> **This was nearly missed.** A goal document asserted "no combat code has
> changed"; auditing `combat_manager.gd`, `wild_creature.gd` and `combat.json`
> directly proved three rungs already existed. Audit source before assuming a
> gap.

## 2.3 Cloudreach Cliffs

Named-location ledger, rebuilt from real captures rather than inherited
numbers: **0 PASS / 9 POLISH / 3 FAIL**. An earlier "0/10/2" reading was wrong,
and the Broken Skyroad Arch row was unsupported by evidence. Cliff silhouette
work and the corrected-camera capture fix are the two highest-value items;
several prior high-perch verdicts were taken with a below-floor survey camera
and need re-shooting before the content they judged is re-judged.

## 2.4 Stormwood and Tidewake

Designed in full, partially implemented, **not currently worked**. Stormwood has
five merged PRs; the Dynamo, the legendary release, the Spark and aftermath are
unbuilt and its visual bars failed. Water/Tidewake was built ahead of sequence
on its own branch and held there; its own contract records the run as
incomplete — do not infer completion from any partial subpath score.

## 2.5 Multiplayer

The implementation scope is complete and on `main`. Fresh two-peer proofs cover
remote map presence, compact chosen-name tags, per-player character bodies,
fresh joins starting in Grandpa's Village, and a fresh join receiving exactly
one starter. Two owner-only items remain open: an outside-tester session and the
owner's own LAN session.

---

# 3. What is next

Four lanes, each anchored to written acceptance criteria rather than a task
list. All four are co-equal — none blocks another.

**1. Combat depth.** Rungs 4–7 in `ACCEPTANCE.md` §6. Start by auditing what
rungs 1–3 actually shipped before adding anything.

**2. Meadows look.** `ACCEPTANCE.md` §4.3, worked top to bottom by domain
impact. Re-verify the 23/23 ledger's still-open residuals against the real build
first; several rows were promoted on captures that predate later landings.
Out of scope: content density (lane 4), combat, other biomes.

**3. Cloudreach look.** Same domain list, applied to Cloudreach's ledger. Fix
the below-floor survey camera before re-judging any high-perch content. Out of
scope: Cloudreach *content* and story completion, Stormwood, Water.

**4. Content density.** `ACCEPTANCE.md` §5. **First task: recount actual density
per Meadows region from real game data.** Then prioritise by the measured gap,
not by what's easiest — a region with zero optional activities is a bigger
problem than one with 4 of 6. Favour the off-trail delivery mechanisms (a
distant glimpse, something glowing far off, a visible cluster of creatures, an
NPC who names a place and reveals it on the map, the wayfinding beacon) over
adding more things directly on the critical path. Verify each addition is
actually **discoverable**, not just present in the data.

**Deliberately demoted: the automated campaign proof (Gate F).** It is a
measurement instrument, run rarely, at milestones. Finish a specific mid-flight
check if one is about to answer something real; do not start a fresh full
attempt. Two weeks and 15+ attempts went mostly into fixing the walker rather
than the game. See `ACCEPTANCE.md` §10.1.

**Not currently worked:** Stormwood, Tidewake, new biomes.

---

# 4. Known issues

Ranked by player impact. A row here is a live defect, not history.

| # | Issue | Notes |
|---|---|---|
| 1 | **The player does not reliably know where to go.** | The owner's own top complaint. The wayfinding beacon landed (`6ad66637`) and passed its views; whether it actually solves the problem in a full run is unproven. |
| 2 | **Off-trail content density is unverified and probably short.** | See §2.1. The spec target is 6–10 optional activities per major region. |
| 3 | **The Meadows reads as a run down a path, not a true open world.** | Owner: "vs. how Valheim or Palworld read as true open world." Structural, not a bug — loops, reconnecting routes, overlooks and optional pockets are the answer. |
| 4 | **The visual bar is not yet answered yes.** | Bar A and Bar B have both historically read **no** on whole-chapter surveys, even while individual locations pass. Cohesion across the chapter is the open item, not any single location. |
| 5 | **Cloudreach has no PASS locations.** | 0/9/3 (PASS/POLISH/FAIL). |
| 6 | **The clock has no memory.** | Every world starts at 08:00; nothing saves or restores it, so night is often never reached in normal play. Fix is in `save_game.gd` / `game_state.gd`. See `TECHNICAL.md` §7.1. |
| 7 | **Creature aspect variants read as one hue-swapped decal.** | Four variants sharing one mask. Blind-judge finding; needs per-variant treatment. |
| 8 | **Burrowback habitat contrast is 1.18–1.19:1 against a 1.5:1 bar.** | Dark by design (grey-olive rock-nodule armour). Brightening it trades away its identity — this is a **design question**, not a fix to apply. |
| 9 | **Creatures embedded on slopes.** | The contact-shadow half of this closed; the ground-contact-on-slope half has not been re-judged. |
| 10 | **The guardian's silhouette does not read at gameplay distance.** | Reads in a close crop only. |
| 11 | **The river reads as an engineered canal**, and the stream is not visible from its own bank. | |
| 12 | **Trunk-to-canopy ratio is ~1:3 against a real broadleaf's ~1:9.** | Blocked on trunk geometry, not on scatter rules. |
| 13 | **Night crushes the trainer's legs and lower body to black.** | Independent of the already-rejected exposure-slider attempt. |
| 14 | **Mipmaps are not generated on species albedos.** | Root-caused, not yet shipped. |

---

# 5. Open questions nobody has answered

Record here rather than stalling. Take the conservative option and keep going.

- **Grass blade-shape redesign (clump cards).** Density stays at 75k tufts / 4
  blades / 3 segments until the owner answers. Do not change blade shape
  speculatively.
- **Burrowback's contrast vs. its identity** (issue 8 above) — brightening it to
  clear 1.5:1 is a look change the owner has not asked for.
- **Whether the smallest creatures (0.60–1.00 m) read well in the combat
  camera.** Flagged when the band widened from the bottom; a playtest finding,
  not resolved.

---

# 6. Owner feedback

Newest first. **This section outranks every other document for what it
covers**, and a fresh owner reproduction reopens any item a ledger says is
fixed. Verbatim originals are under `archive/docs/owner/`.

## 2026-09-19 — priorities

> Systems play well. Focus primarily on **content throughout the map and how the
> game looks** — and **continue the combat depth too**.

Four lanes by acceptance criteria: combat, Meadows look, Cloudreach look,
content density. The scripted playthrough proof is demoted — "I already know I
can play the game through. It's just lacking visually and content wise
especially off the trail."

Run as **one persistent session**, self-paced, no plan-approval gate.
Coordinate with a senior tier and delegate the lower-level coding.

## 2026-09-12 — full Meadows playtest

> "The game is close to playable at this point in the meadows. I'd call it 70 %
> of the way there."

The three headline findings, in the owner's order of importance:

1. **"The biggest issue is still not knowing where to go. We should light up the
   next place with a beam like in Fortnite."**
2. **"The next biggest issue is probably still the visuals. Then the amount to
   do that draws you off the beaten path."**
3. **"The whole Meadows reads as a straight run down a path vs. how Valheim or
   Palworld read as true open world."**

Also settled in this playtest: **"There really needs to be a step back and a
dodge button in fighting"** → resolved as the burst step (§2.2).

43 specific items followed, from the village shape and a gate that didn't open
through creatures walking behind and blocking the camera, message spam,
wild respawn, a creature-free south trail, nothing glowing off-path, HUD
ordering, red flags reading as paper cutouts, small potions, NPCs revealing map
locations, riding and saddle fit, tree density "like Valheim Black Forest," a
backwards map arrow, Valheim-style map markers, and multiplayer name / character
/ spawn / creature handling. All 43 are accepted on source (§2.1).

## Standing owner corrections that keep coming back

- **Grow, never shrink.** A relative-scale complaint (alpha vs. legendary, cub
  vs. adult, starter vs. player) is fixed by raising the smaller side. Two lanes
  have made this mistake in the opposite direction.
- **"These big beautiful fantastical creatures"** — almost all creatures should
  stand taller than the 1.80 m character.
- **No more villagers.** The population was already cut on complaint.
- **The Pond's density is the approved lush reference — do not spread it.**
- **"Some of those renders are just a bad shot, not actual game."** Evidence
  that does not show the shipping build is worse than no evidence.
- **"Having one hour CIs is unacceptable."**
- **The Burrow Warrens interior** was approved, then failed on hardware
  ("burrow warrens doesn't look good"), then reworked and re-judged. It now
  passes. Do not cite the old "protect it, don't touch it" line.

---

# 7. Process traps currently in force

Short list; the full reasoning is in `WORKFLOW.md`.

- **A CI run under five minutes verified nothing.** Check that code jobs ran.
- **A retry that turns 0-for-1 into green is a finding, not a pass.**
- **A self-report is not evidence.** Check the branch and the run.
- **A document is a report and goes stale.** Audit source before assuming a gap.
- **A written finding is not a checkpoint.** Two report-only turns is a
  stop-and-escalate signal.
- **Never `--headless` together with a rendering driver.** It hangs forever.
- **Address inventory by item identity, never by slot number.**
- **Grep world boots for `^ERROR:`, not just `SCRIPT ERROR`**, and read the
  distinct set rather than counting lines.
- **A delegated subagent reads its brief, not the whole directive stack.**

---

# 8. History

This file was consolidated on 2026-09-19 from `CURRENT_STATE.md` (94 KB),
`ROADMAP.md`, `DEVELOPMENT_ROADMAP.md`, eleven dated handoffs, five lane goal
documents and `SECOND_PASS_BACKLOG.md`. All of those are under `archive/docs/`.
Per-round evidence — contact sheets and written verdicts — stays in
`ralph/reports/<LANE>/`.
