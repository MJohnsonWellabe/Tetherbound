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

So Gate 3 has two kinds of evidence running at once, and they answer different
questions. Conflating them is exactly what made run 3 unreadable.

- **Does this band play?** Owned by the band lane, answered by running *its own*
  segment against a **synthetic entry save** built the way `tools/gate_f/seed_s09_exit.gd`
  and `build_s10b_synthetic_seed.gd` already do it. Each lane writes
  `tools/gate_f/build_s0N_entry_synthetic.gd`, sourcing party, levels and flags from
  `data/config/chapter_curve.json`'s own band row, then runs S06 / S07 / S08 / S09 and
  fills in `docs/ROADMAP.md`'s evidence template. This parallelises; it is why the
  lanes exist.
- **Does the chapter play?** Owned by the coordinator, answered by the continuous
  S01→S10e chain. Only it can say whether the party actually arriving at Band 4 is the
  party the curve assumes, whether the bands connect, and whether travel between them
  is dead.

`seed_s09_exit.gd`'s header already states the rule that keeps the first honest: every
claim from a constructed entry takes the form *"S0N, given a clean entry, does X"* —
never *"the chapter does X"*. A synthetic seed asserts the state a lane believes the
player arrives in. Whether they actually arrive in it is the chain's question, not the
lane's, and a lane that blurs the two is re-creating run 3's error in miniature.

**This was missing from the first round of lane briefs and was added by addendum on
2026-09-03.** G3-BAND2 had already returned a config-verified "already satisfied"
verdict without a played S06 and was reopened for it. Verification against data and
against a system smoke is real work and its findings stand — but `smoke_warrens.gd`
walking the cave is not the same instrument as S06 walking the band, and only the
second one can answer prompt 63's actual question.

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
- **Does the relay escalate?** ~~Hess (8/8), Orrin (9/9), Officer Dell (10/10/10) and
  Captain Vance (11/11/12) stand within ~30 m of each other.~~ **ANSWERED on the table,
  2026-09-04 (CL-D6) — still unplayed.** The clustering is gone: V-1 spread the picket
  line down the spine road (Hess at z=3680, Orrin at 3710, Dell at 3771 — a ~90 m gradient,
  not a ~30 m huddle), and V-2 re-cut Vance to galecrest 11 / duskhush 11 / tuskroot 12
  with the Tuskroot on CHARGER, so the milestone is a shape change and not only a +1. Both
  are live in `data/config/bands/band3_the_river_lock/trainers.json`. What remains open is
  narrower than the question as written: whether the escalation *reads* on a played run.
  Nobody has played it.
- **Does the Warden read as the hardest fight?** ~~He fields five at 16/17/17/18/20~~
  **ANSWERED, 2026-09-04 (CL-D6).** He was measured, the measurement said his front was
  soft against Keeper Hald's three at 18/19/19, and W-1 acted on it with the owner's
  explicit **yes** (`docs/owner/OWNER_DIRECTIVES_2026-09-04.md`, question 2): the team is
  now burrowback 18 / galecrest 18 / brooktail 19 / meadowhart 19 / tuskroot 20, live in
  `data/config/bands/band5_stronghold_approach/trainers.json`. The front no longer dips
  below the Keeper's. This is a table answer; how the fight plays is Gate F's.
- **Is Band 5 an empty corridor?** ~~23 spawns, 8 harvest nodes and 3 prop clusters~~
  **ANSWERED: no, 2026-09-04 (CL-D6).** The cluster count was the wrong instrument — a
  cluster is not a creature. G3-BAND5 counted live bodies at three eyes on the approach and
  got **26, 30 and 22**, with a worst gap of **63 m** of dead travel over a 651 m leg
  (`tools/_probe_band5_approach.gd`). D70 also made the approach deliberately thinner than
  Band 3's 54 clusters as the chapter's crescendo, so the low cluster number is authored
  shape. The corridor is populated; what is still unmeasured is whether the *escalation*
  reads, which is P-5.2's question, not this one.

## 4b. The trap that blocks a logic-lane Gate F run before step 1

Cost the coordinator one launch and, on the same evening, sat under three lanes at once.
Written down because nothing in `docs/acceptance/` says it and the symptom looks like a
failed run rather than a refused one.

`tools/gate_f/operator_harness.gd`'s capture pre-flight compares the running process
against a freeze record. It looks in two places, nearest first: the run directory's own
`RUN_METADATA.json`, then the tracked candidate record at
`ralph/reports/gate-f-candidate/RUN_METADATA.json`. That tracked record is **from
2026-08-27** and says `"display_server": "X11 under xvfb-run"`.

A logic-lane run is `--headless` with no rendering driver, so it has no display server.
The claim contradicts the process, and **every segment refuses to start** — writing a
`BLOCKER.md`, an `INCOMPLETE.md` and an `INVENTORY.json` of `0 pass / 0 fail / 0 skipped`
having executed no step. `run_chain.sh` then correctly stops the whole chain at S01
because no exit save was written. Read too fast, that looks like the chain died; it did
not run.

The fix is the coordinator step, and the harness's own `_freeze_display_claim()` comment
spells it out: a run that wants a logic lane **must say so in a freeze record written
before the run**. Put a `RUN_METADATA.json` in the run directory carrying a `lanes` block:

```json
"lanes": { "logic": {
  "display_server": "headless (--headless, no rendering driver)",
  "renderer": "none -- no rendering driver is loaded"
} }
```

The check passes when the claim contains `headless`. Two things not to do: do not edit
the tracked candidate record (it is the 2026-08-27 run's record and scoping a new claim
into it rewrites that run's history), and do not reach for
`--gatef-allow-no-capture`, which records a BLOCKER severity note and degrades the
segment rather than declaring the lane honestly.

While writing that record, fill in `suite_state_at_freeze` and
`known_open_defects_at_freeze` truthfully. The field exists, in the protocol's own
words, "so Phase B reads the actual state rather than an implied green."

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

---

## 6. Round two — the open items, and who owns them

Written 2026-09-04 after a pass over all seven Gate 3 lane reports and Gate 2's
2.8 evidence. Round one's lanes finished their own scope and left named residue;
this is that residue, grouped so the six lanes do not collide.

The pattern in what was left is worth naming, because it will recur: **lanes
stopped honestly at their file-ownership boundary.** G3-FINALE flagged W-4 as
"not done" rather than faking a visual pass it had no pipeline for; G3-BAND5
wrote the row it would have written for P-5.2 and stopped; G3-BAND4 called its
own S08 a FAIL because the harness never gave the player a fair captain fight.
None of that is a lane underperforming. It is the ownership split working, and
the cost of the split is that someone has to pick the residue up. That is this
round.

| Lane | Scope | Source |
|---|---|---|
| `G3-OPENING-FIX` | the second orb throw that never leaves the hand (GAME-11/RIG-26); a revived creature not re-deployed (2.11); post-tournament recovery as a designed beat, and a refusal line that names the real reason (2.10) | chain S02, 2.8 §4/§7 |
| `G3-HARNESS` | the walker cannot leave the Pond basin (2.9); S08 has no post-faint switch or revive; stale trace-length thresholds (2.14) | 2.8 §7, G3-BAND4 |
| `G3-BAND1-FINISH` | the South Bridge is visually unbuilt; the oxblood reservation is broken; fence, mill sails, signposts, dome hill, water (2.13); one roster decision on the route (2.12) | 2.8 §7/§8 |
| `G3-HUD` | food bar outside the 5% safe area; objective/action/interact hierarchy; health-text contrast; the interact pill covering its own object | 2.8 §8 |
| `G3-CREATURE-COLOUR` | Bramblebun candy pink in daylight AND glowing at night; time-of-day scaling for `field_emission`; the rest of the roster unreviewed against the 1.5:1 bar | `CURRENT_STATE` §3 + 2.8's judge |
| `G3-WARDEN-ARENA` | W-4 arena dressing and the Warden's silhouette measured at 16 m; R-2 the waystop duty board | G3-FINALE, G3-BAND5 |

### Two findings that only exist because the instrument changed

Both come from 2.8 judging **sixteen stands taken from the played route's own
2 Hz trace** — gameplay camera, HUD on, where the player actually stood — rather
than posed survey viewpoints. Four previous blind judges could not have found
either:

- **The HUD had never been judged at all.** The earlier survey reports say
  "interface (n/a — no HUD present)". Four defects surfaced the first time a
  judge saw one.
- **The South Bridge had never been framed.** A posed stand named
  `place5-bridge-approach` reported "no clear bridge structure is visible despite
  the filename"; standing on the crossing confirms it is a bare plank frame with
  no gate, banner or guard — the chapter's first physical gate, and the thing
  Team Tether is supposed to be holding.

Worth carrying forward as a method note: **where the camera stands decides what
the judge can find.** Posed stands flatter a build.

### Still open, owned by the coordinator, not a lane

- **The single re-bake.** Every lane was forbidden `vegetation.json` and
  `terrain_playground.json` and told to propose diffs instead. Those proposals
  (Band 2's two Warrens clearings already waiting from `BAND2-63-WARRENS`, Band
  5's P-5.2 scorched-pocket sightline, Band 1's dome hill and tree layout) are
  collected and applied in one pass, then both bakes run once, after the merge —
  never before, which is what made PR #29 red.
- **The chapter chain.** S01 13/13, S02 77/5, S03 475/38 with an exit save —
  past the point where run 3 died. S04 onward is running.
- **`chapter_curve.json`'s stale "no trainers" comment** for band 2, reported by
  G3-BAND2 as outside its ownership.
- **The `material_get_instance_shader_parameters` null-material warning** during
  guardian dressing (`burrow_warrens.gd`), seen by two lanes, chased by neither,
  non-fatal in both.
