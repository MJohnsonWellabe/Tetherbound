# Gate 3 execution plan — bands 2–5 and the finale

**Status:** the live Gate 3 control document, opened 2026-09-03 by the Gate 3
coordinator. It sits under `docs/ROADMAP.md`'s "Gate 3" section, which remains the
acceptance authority, and under `docs/GATE3_COORDINATOR_BRIEF.md` (written by the
Gate 2 coordinator), which remains the authority on the traps. This file records
what is actually being executed, by whom, and on which files.

---

## 1. What Gate 3 is, and where it actually starts

`docs/ROADMAP.md` states Gate 3's objective as *"each band passes the Gate 2 standard
and its Gate F segment (S04–S10)"*. The S-range is looser than the work: **S04 is the
village tournament (Gate 1) and S05 is Band 1 (Gate 2)**. Gate 3's own segments are:

| Segment | Band | Content |
|---|---|---|
| S06 | Band 2 | bridge → Old Quarry → rootstone → Burrow Warrens → guardian → exit toward river |
| S07 | Band 3 | river arrival → relay pickets → officer → Captain Vance → captive → Old Mill Crossing restored |
| S08 | Band 4 | crossing → ironwood → saddle and riding → three captains → three Sigils |
| S09 | Band 5 | Sigil gate → outer watch → checkpoint → final camp decision → Hall threshold |
| S10a–S10e | finale | Hall gauntlet → elite → Warden → legendary → release ceremony → world healing |

**None of them has ever produced usable evidence about its own content.** Gate F run 3
(2026-08-27/28) ran S06–S09 and recorded 21/22/22/12 failures, but
`archive/reports/GATE_F_RUN_3_FINDINGS.md` is explicit that those are *one* defect
counted many times: the player was stranded at the South Bridge from partway through
S05, so every downstream `move_to` failed 0.6–6.2 km short and every band-3/4/5
objective flag was unset as a mechanical consequence of never arriving. That run's own
words: *"this run cannot speak to whether Stone & Root, River & Relay, Upper Meadows, or
the Stronghold approach are fun, fair, or well-paced, because the player was not there."*

The stranding was later root-caused to the rig, not the world (S03's catch loop fainted
the only creature and no step-script assigned it to a bed). S03 has since been patched
extensively with revive steps. **Whether a healthy S03→S09 chain now exists is unknown,
and establishing it is the coordinator's own task**, not a lane's.

So Gate 3 has two halves running at once:

- **Evidence** (coordinator): get the Gate F chain healthy enough that bands 2–5 are
  actually reached, then read what it says about them.
- **Content** (six lanes): bring each band and the finale up to its prompt's standard
  on the parts that do not need the chain to be healthy first.

## 2. Why this parallelises, against the brief's advice

`docs/GATE3_COORDINATOR_BRIEF.md` §3 argues Gate 3 is serial by design and warns that
"spawning five band lanes at once contradicts the method." That reasoning is sound for
the *convergence* step and is being honoured there: segments are still fixed and
re-converged one at a time, in order, against the chain.

It does not hold for *authoring*, and the reason it looked like it did is worth stating.
The brief's own §5 names the real coupling — one global scatter bake reads
`data/config/vegetation.json` **and every** `data/config/bands/*/vegetation.json`, so any
band's vegetation edit invalidates the bake for the whole world, and even a `_comment`
string change fails `verify-scatter-bake-freshness`. That is a genuine chokepoint, and it
is the only file-level coupling between the bands.

It is removed by rule rather than by serialising: **no lane may touch any
`vegetation.json` or `terrain_playground.json`.** Lanes propose vegetation diffs in their
reports and the coordinator applies them and runs one bake, once, after the merge —
which is what the brief says must happen anyway. With bake inputs off the table, bands
2–5 are disjoint directories, disjoint scripts and disjoint tests.

The second coupling — `tests/fixtures/band_split_baseline/`, the tracked mirror of the
pre-split band files — is handled the same way: **append, never rewrite.**
`tests/test_band_content.gd` only compares the leading N entries against the mirror, so
new content appended past that count needs no mirror edit at all. An edit to a pre-split
entry requires a same-commit mirror edit with `_why_*` text matching exactly, and lanes
are told to avoid needing one.

## 3. Lanes in flight

All branch from `main` (`3c73aab5`), push `ralph/G3-*-0903`, and open **no** pull
request; the coordinator lands them.

| Lane | Scope | Contract |
|---|---|---|
| `G3-BAND2` | Stone & Root: quarry, rootstone purpose, Warrens, guardian, staging camp | `docs/prompts/63` |
| `G3-BAND3` | River Lock: river as landmark, relay escalation, Vance, captive, crossing restored | `docs/prompts/64` |
| `G3-BAND4` | Upper Meadows: ironwood, riding payoff, three Sigil captains, route loops | `docs/prompts/65`, `67` |
| `G3-BAND5` | Stronghold approach: density with purpose, escalating occupation, final prep point | `docs/prompts/66` |
| `G3-FINALE` | Hall, elite gate, Warden, legendary, release ceremony, world healing, persistence | `docs/prompts/69`, `46` |
| `G3-ECONOMY` | Curve re-measurement, reward economy, rest rhythm, roster pressure, the tests that pin them | `docs/prompts/57`, `58`, `61`, `67` |
| `G3-ENCOUNTERS` | **Fable, read-only on code.** Encounter identity, per-band pacing, the roster-pressure moment | `docs/ROADMAP.md` Gate 3 |
| *(coordinator)* | Gate F chain S01→S10e, landing, the bake, integration | this file |

### File ownership

Exclusive. Anything not listed is the coordinator's to route.

| Owner | Files |
|---|---|
| G3-BAND2 | `data/config/bands/band2_stone_and_root/{spawns,trainers,harvest,props}.json`; `data/config/{old_quarry,burrow_warrens}.json`; `scripts/world/{old_quarry,burrow_warrens}.gd` |
| G3-BAND3 | `data/config/bands/band3_the_river_lock/{spawns,trainers,harvest,props}.json`; `data/config/{relay_site,tether_relay,water,water_hazard}.json`; `scripts/world/{river,mill_crossing,tether_relay}.gd` |
| G3-BAND4 | `data/config/bands/band4_upper_meadows_ironwood/{spawns,trainers,harvest,props}.json`; `scripts/world/{tether_sigil,riding_controller,watchtower_landmark}.gd` |
| G3-BAND5 | `data/config/bands/band5_stronghold_approach/{spawns,harvest,props}.json` and all `trainers.json` rows **except** the three Hall rows; `data/config/stronghold_occupation.json`; `scripts/world/{stronghold_occupation,approach_drain_skin,severed_spokes}.gd` |
| G3-FINALE | `data/config/{stronghold,stronghold_climax,meadow_healing,rift_collapse}.json`; `scripts/world/{stronghold,stronghold_climax,meadow_healing,rift_collapse}.gd`; `data/dialogue/stronghold.json`; the `warden_aldis` / `stronghold_elite` / `stronghold_courtyard` rows only |
| G3-ECONOMY | `data/config/{chapter_curve,progression,chapter_rewards,bond_milestones,creature_condition,vitals,trade}.json`; `tests/test_chapter_curve.gd`; `tools/_probe_pacing.py` |
| G3-ENCOUNTERS | `docs/specs/GATE3_ENCOUNTER_CONTRACTS.md` only |
| **nobody** | every `vegetation.json`, `data/config/terrain_playground.json`, `data/scatter/`, `data/terrain/` — coordinator bakes once, after the merge |

`data/config/bands/band5_stronghold_approach/trainers.json` is the one shared file, split
by row between G3-BAND5 and G3-FINALE. It is shared because the approach's pacing and the
Hall's cast genuinely argue with each other; both lanes are told to name the rows they
touched in their commits.

## 4. Open questions being answered by evidence, not assertion

Recorded here so they are not rediscovered a fourth time.

- **Is there a healthy S03→S09 chain on current `main`?** Unknown. The coordinator's run
  answers it. Everything the previous Gate F run said about bands 2–5 is void until it does.
- **Captain Oreth's band.** `captain_riverwatch` sits at z=4350, inside Band 3, while
  `docs/specs/MEADOWS_PROGRESSION_SPEC.md` and `docs/prompts/65` treat the Riverwatch
  Captain as one of Band 4's three Sigil captains. G3-BAND3 reports from the played route,
  G3-ENCOUNTERS gives the design verdict, the coordinator decides. No lane moves him.
- **Does the relay escalate?** Hess (8/8), Orrin (9/9), Officer Dell (10/10/10) and Captain
  Vance (11/11/12) stand within ~30 m of each other. Vance is +1/+2 over the officer
  before him and is meant to be a chapter milestone.
- **Does the Warden read as the hardest fight?** He fields five at 16/17/17/18/20 — larger
  in aggregate than Keeper Hald's three at 18/19/19, and softer at the front, against the
  one opponent the player cannot walk around. A play question, not a table question.
- **Is Band 5 an empty corridor?** 23 spawns, 8 harvest nodes and 3 prop clusters over the
  chapter's largest extent, against Band 1's 69 / 48 / 15. Measured; the player-facing
  consequence is not.

## 5. Standing rules for this gate

From `CLAUDE.md`, `docs/AGENT_WORKFLOW.md` and `docs/GATE3_COORDINATOR_BRIEF.md` §6,
each already paid for once:

- A region is not done because code and data exist. It is done when the complete player
  path produces the intended experience.
- **An honest fail with a scoped task list is worth more than a manufactured pass.**
- A CI run under five minutes verified nothing; a healthy full run is 35–45 minutes.
- A retry that turns 0-for-1 into green is a finding, not a pass.
- A self-report is not evidence. Check the branch and the run.
- Verify what changed, not what you changed — PR #29 went red by re-baking scatter, seeing
  it green, and never asking what else the edited config fed.
- Never `--headless` together with a rendering driver. It hangs forever.
- Commit evidence verdicts, not payloads.
- Merge `main` in; do not rebase. The tree carries committed bake binaries.
- Evidence-backed "already satisfied" is a valid outcome. Do not rewrite a working system
  to produce a diff.
