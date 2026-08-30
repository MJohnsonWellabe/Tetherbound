# Gate F run 3 — findings about the RIG

**Rewritten:** 2026-08-30, from `ralph/reports/gate-f-run-20260828T183531Z`'s own
`INVENTORY.json`/`events.jsonl`/`notes/*.md` files, not from the prior draft.
**Branch:** `ralph/T2-GATEF` (operator lane; run itself was driven on
`ralph/GATE-F-RUN-3`). **Candidate (the game):** `main@26f0db4`, unchanged for
every segment. **Companions:** `GATE_F_RUN_3_FINDINGS.md` (the game).

Kept separate from the findings about the game deliberately, per protocol. This
version supersedes the previous draft's RIG-1 through RIG-11 (all still
accurate as history — verified against the run's own artefacts below) and adds
RIG-12 through RIG-18, which were found and mostly fixed *after* that draft was
written, plus one still-open question this operator did not chase further.

> **T2-GATEF-RUN4 update, 2026-08-30:** RIG-23 and RIG-24, appended below,
> are new — found chasing why a real S03 replay (T2-BUILDPLACE round 3's
> door/revive fix, plus this session's own GAME-0/T1 fixes) still does not
> produce a healthy exit save. Neither is fixed. See the companion GAME
> document's GAME-8/GAME-9 for the full mechanism and
> `ralph/reports/handover-T2-GATEF-RUN4-2026-08-30.md` for the evidence
> trail.

**If you read one thing here: RIG-13 explains why S05 through S10 are
dominated by a single repeated pattern (the South Bridge stranding) rather
than five segments' worth of independent band content**, and the open
question at the end of this file is the one thing standing between "rig
defect, now fixed" and "this might still be a real game defect."

**Correction to the coordinator's 2026-08-29T16:06 segment-exposure table,
found while X04 was already running against it — itself superseded a few
hours later, see the boxed update below.** The coordinator's table listed
X04's `S06-exit` entry save as pre-stranding ("S04, S06 (pre-stranding),
S09-exit"). It is not, *positionally*: this operator checked `S06`'s own
`route.csv`/`events.jsonl` directly and found `S06-exit`'s last recorded
player position is `(12.8, -5.53, 1324.5)`, region `corridor` — inside the
exact South Bridge stranding cluster (x∈[0,16], z∈[1314,1326]) named in
RIG-13 above. `S04-exit`'s last position, by contrast, genuinely is clear
of the corridor: `(18.67, 0.19, 12.71)` in `grandpas_village`.

> **This positional check was correct as far as it went, and still
> incomplete in a way that mattered more.** `ralph/reports/
> FINDING-T2-STRANDING-2026-08-30.md` (`origin/ralph/T2-STRANDING@08506512`)
> checked exit-save **party contents**, not just position, and found the
> real boundary is earlier and simpler: **every exit save from `S03-exit`
> onward — including `S04-exit`** — carries a party of one creature (Moss)
> permanently fainted (`hp: 0.0`), from a fair combat loss during S03's own
> catch loop that nothing in the run ever healed. A fainted-only party
> cannot be summoned (`encounter_director.gd::summon_active_creature()`
> correctly refuses), so `can_challenge()` correctly refuses every
> trainer/gate fight regardless of the player's *position* — which is also
> the root cause of the position-stranding itself: the South Bridge gate is
> a real, correctly-locked physical barrier that only opens on defeating
> `south_bridge_grunt`, that fight can never start with no usable creature,
> so every `move_to` past S04 is asking the harness to walk through a
> permanently locked gate, which is what drives it into the carve and the
> `severed_spokes` recovery loop. **One root cause explains both symptoms.**
> So: `S04-exit`'s position is genuinely clean, but its **party is not**,
> and X04 has no clean entry point by either measure. See RIG-21 below for
> the full finding, credited to the T2-STRANDING lane, and
> `X04/CONTAMINATED_ENTRY_SAVES.md` for how this changes X04's own results.

This does not change the fact that X04 was already in flight when this was
found, or that its telemetry is worth keeping (a real record of a fainted
party correctly failing to fight, which is itself a narrow positive result).
It does mean **none of X04's combat assertions may be read as evidence about
combat, camera, faint-recovery, or switching** — see RIG-19 and RIG-21 and
the GAME findings document's revised per-segment table.

---

## RIG-1 through RIG-11 — unchanged from the prior draft, verified still accurate

These were found and (mostly) fixed before S06 re-ran. Re-checking each
against this run's own artefacts:

- **RIG-1** (`objective_is` compared two id spaces) — fixed, commit `82fd6c9`. Not reproduced in this run's S01-S09 objective asserts.
- **RIG-2 / CD-7c** (cost gate divided wall time by a scene-standup's handful of physics frames) — fixed, commit `435fbb8`. `S03-superseded-1/` remains the primary evidence.
- **RIG-3** (no segment calls `await_load`/`await_save`) — still open. Confirmed again in this run: no segment's `INVENTORY.json` records a `duration_ms` for a load/save distinct from the fixed 180s settle wait.
- **RIG-4** (a missing `seed_save` source does not stop the segment) — still open, not exercised in this run (every seed source existed by the time this operator started).
- **RIG-5** (a modal that owns input produces a false navigation finding on `move_to`) — still open. This run's own S03 through S09 `move_to` FAILs never name the holding context (`(0 held)` on every one, see RIG-13 below) — consistent with this defect still being live, though in this run's case the actual cause of the stall is RIG-13's stranding, not an unclosed vendor panel. **Reproduced again directly in X01**: `X01-554` and `X01-996` both FAIL with `locomotion never came back: held 3601 frames by input_context 'narrative_modal'` — a full 60-second `move_to` budget spent motionless because a narrative modal opened mid-walk and the walker had no way to know it was held, exactly the mechanism this finding describes.
- **RIG-6** (the derail mechanism is never invoked by any journey/study segment) — still open. Confirmed by direct count over this run's own step-scripts: `assert{check: input_context}`-shaped FAILs still record and continue rather than derailing, in every segment checked (S02 through S09).
- **RIG-7** (round 2's primitives have zero callers) — partially addressed. `move_to_entity` and `interact_with` are now called by `S03.json` (RIG-16/17's fix) and appear in the RIG-11 fix commit for `X04.json`. Blind `press{control: interact}` for wild engagement is gone from `S03.json`; whether it persists elsewhere in S04-S10's own scripts was not re-audited step-by-step this pass.
- **RIG-8** (the instrument cannot see deployed-ally state or the live interaction prompt) — still open.
- **RIG-9** (a logic lane re-armed the §H recorder and marked itself INCOMPLETE) — fixed, commit `4e23c92`. S05 (kept) is `complete: true` with no continuous-frame debt outside its declared DELEGATED windows.
- **RIG-10** (`save_out` promotes whatever is already in the slot without checking it changed) — still open, not fixed. Still a live risk for every segment's handoff; `HANDOFF_PROVENANCE.md` is the mitigation in force, not a fix.
- **RIG-11** (no journey segment ever presses `creature_recall` after a load, so no journey segment past S02 can fight) — **fixed**, commit `3fbcca3a2d6d460d8a8239815a1c5ff7a68b2d26`. `S06.json` through `S10.json` and all three of `X04.json`'s load points now press it. **This is the load-bearing fact for reading everything below**: S06-S09 are re-run evidence, not salvage of pre-fix runs.

**But the fix did not produce the combat evidence it was fixed to enable.**
Direct count of `combat_start` events in this run, post-fix:

| segment | `combat_start` events |
|---|---:|
| S03 (pre-RIG-11-relevant; no load) | 3 |
| S04 | 0 |
| S05 | 0 |
| S06 | 0 |
| S07 | 0 |
| S08 | 0 |
| S09 | 0 |
| S10 (to its BLOCKER at step 27/121) | 0 |

**There is zero post-RIG-11 combat evidence in this entire run.** RIG-11 being
fixed was necessary but not sufficient — RIG-13 (below) explains why S04's own
tournament still never fought, and RIG-14/the stranding (below) explain why
S06-S10 never got the chance either. This is the single most important reason
X04 (the combat lab, seeded from already-complete `S04-exit`/`S06-exit`/
`S09-exit`) is this run's highest-value remaining segment: it is the first
opportunity in the whole run to observe combat with RIG-11 actually fixed.

---

## RIG-12 — `seed_save`'s `run://` fallback resolution picked the wrong superseded directory

**Severity: BLOCKER for evidence quality.** Fixed, same commit as RIG-11
(`3fbcca3a2d6d460d8a8239815a1c5ff7a68b2d26`).

A killed-mid-flight S06 attempt seeded its world from
`S05-superseded-2/saves/S05-exit.json` rather than the kept `S05/saves/
S05-exit.json` — `seed_save`'s directory-scan fallback took whichever
directory it visited last on disk, not the one `RESTARTS.md` names as kept.
`S05-superseded-2`'s exit save carried 1 progression flag against the kept
`S05`'s 4, so even had that attempt survived, its entry state would have been
wrong. Caught before any evidence was produced from it; the attempt is
preserved as `S06-superseded-1/` and unreadable.

---

## RIG-13 — RIG-11's own fix was only ever written into six of the nine segments it named

**Severity: BLOCKER.** Fixed for S03-S05 in the RIG-13/14 commit; this is the
finding that explains why the South Bridge gate, and the tournament before it,
never opened even after RIG-11 shipped.

RIG-11's fix ("press `creature_recall` after every load") was stated to cover
"S03-S10" but landed only in `S06.json` through `S10.json`. `S03.json`,
`S04.json` and `S05.json` never received it. Without a deployed ally,
`encounter_director.gd::can_challenge()` (`_ally == null or _ally.fainted or
_ally_body == null or ...`) returns false for every trainer, and
`trainer_npc.gd::_on_challenged` falls back to the NPC's `defeated` line
instead of `challenge` — not because the trainer was beaten, but because
there was nothing to challenge with.

Measured directly, pre-fix: the South Bridge grunt's dialogue at
`t=825.12`/`t=827.22` was `south_bridge_grunt_beaten`'s own text on the
**first-ever** approach, with `south_bridge_key` never in inventory and
`south_bridge_open` never set. S04's tournament showed the identical shape:
`input_context=narrative_modal (wanted combat)` three times, and every one of
`tournament_team_ready`/`tournament_training_ready`/`tournament_condition_
ready`/`tournament_entered`/`tournament_quarter_won`/`tournament_semi_won`/
`tournament_won` never set.

**Net effect, confirmed by this rewrite's own re-check of the kept run's
telemetry (not just carried forward from the prior draft):** every `move_to`
step in the kept S06 through S10 fails, each stopping 1.6-6.3 km short, and
**every single failure lands within a few metres of the same spot** —
x∈[0,16], y∈[-8,-2], z∈[1314,1326] — which is the South Bridge carve
corridor's own centre:

| segment | example FAIL | stopped at |
|---|---|---|
| S06 | did not reach (403,1794) in 6300 frames | (13,-3,1314), 618.2 m short |
| S07 | did not reach (150,3500) in 27900 frames | (8,-3,1318), 2186.2 m short |
| S08 | did not reach (-345,5060) in 45000 frames | (15,-4,1324), 3753.0 m short |
| S09 | did not reach (64,7400) in 49500 frames | (2,-3,1321), 6079.4 m short |
| S10 | did not reach (0,7560) in 9000 frames | (8,-3,1318), 6241.6 m short |

Every band-3/4/5 objective flag downstream (`relay_captain_defeated`,
`captive_rescued`, `relay_disabled`, `mill_crossing_restored`, all three
`defeated_captain_*` flags, `hall_approach_open`) is unset as a **direct,
mechanical consequence of the player never arriving**, not an independent
finding about that band's own content. Read S06-S09's FAIL counts (21, 22, 22,
12) as this one stranding, counted once per assertion that depends on it — not
as 77 independent defects.

`scripts/world/severed_spokes.gd`'s own recovery volume (a real system that
returns a player who falls off the world) is what deposits the player back at
this exact cluster every time; the prior session's handover reports it firing
"on the order of 600+ times per segment" from stdout it did not retain, which
this rewrite cannot independently re-verify (the harness does not emit a
telemetry event for that trigger — a `RIG-8`-shaped instrumentation gap in its
own right, not chased further here) but which is fully consistent with the
position clustering above, which this rewrite verified directly from
`events.jsonl`.

**One data point that separates this from "straight-line walking is always
this bad":** X02, seeded from `S03-exit` (before the stranding, and outside
S04-S10's chain), shows no such pattern — its two `move_to` FAILs (16.6 m and
657.3 m short) are ordinary short misses, nothing like the multi-kilometre
repeats above. Whatever this is, it is specific to state at or after the
South Bridge, not a general property of the walk primitive.

Separately, RIG-14 (below) was found in the same investigation.

---

## RIG-14 — a fixed-count tab-cycle assumes a Satchel start, but the shell reopens on the last tab used

**Severity: BLOCKER for evidence quality.** Fixed for S04/S05/S07/S10 in the
RIG-13/14 commit. **Not fixed in X02.json — this rewrite found a fresh
instance of the identical shape while re-checking X02's own FAILs.**

`game_menu.gd` reopens the pause shell on whichever tab was last open, not on
Satchel. `S04.json`/`S05.json`/`S07.json`/`S10.json`'s save step opened the
shell with a bare `open_menu` (no tab) and pressed `menu_tab_right` a fixed 5
times, assuming a Satchel(0) start; landing anywhere else made 5 presses
overshoot past Save(5) back to Backpack(0). `save_out` (RIG-10) then copied
out whatever was already in slot 4 under the new segment's name, reporting
PASS. Confirmed directly: `S03/S04/S05-exit.json` were byte-identical
(md5 `62344f09b811`) despite S04 and S05 each running for hundreds of
play-seconds. Fixed by opening via `{"tab": "map"}` (matching
`S06.json`/`S08.json`'s already-working pattern) and adjusting the press
count.

**This rewrite's own check of X02's telemetry found the same shape, unfixed,
in a file the RIG-13/14 fix never touched.** `X02.json`'s steps X02-156/157
open the shell with a bare `open_menu`, then press `menu_tab_right` a fixed 6
times assuming a Backpack(0) start to reach Settings(6). The segment's own
assert immediately after (X02-158) FAILs: `input_context=menu_backpack
(wanted menu_settings)`. The same shape recurs at X02-161/162
(`input_context=menu_save (wanted menu_build)`). Because X02 does not chain
into a save-corruption consequence (it does not call `save_out` at these
points, only reads/toggles Settings and Build tab state for the `free_build`
toggle check), the blast radius here is two false FAILs on an otherwise
working settings/banner check, not a corrupted handoff — but it is RIG-14's
exact mechanism, unfixed, discovered by this rewrite rather than carried
forward from the prior draft. **Recommend the same fix** (open via a named
tab, count presses from wherever that tab actually lands) be applied to
`X02.json`, and that every other segment's tab-cycle steps be swept for the
same fixed-count assumption rather than trusting the four files already
touched to be the only four affected.

---

## RIG-15 — a `party_size` assert required an exact count where every caller meant "at least"

**Severity: BLOCKER for evidence quality.** Fixed. `operator_harness.gd`'s
`party_size` check now accepts `min` (>=) alongside `equals`; every milestone
`party_size` assert from `S03.json` through `S10.json` was converted.
Additionally, S03's own third-catch step threw exactly one orb and asserted
team-of-three, with no `catch_result` event anywhere near the throw
(`catching.json`'s own words: "nothing is ever certain" — a throw can miss on
a fair roll, and this one did). S03 gained three more full engage/weaken/
aim/throw/wait cycles.

---

## RIG-16 — a blind `interact` press at a wandering cluster's centre is luck, not a repeatable primitive

**Severity: BLOCKER for evidence quality.** Fixed. `data/config/bands/
band1_lower_meadows/spawns.json` wanders 3 bramblebun in a 15 m radius; the
old step walked to the cluster's centre and pressed `interact` blind, so
whether a live individual was in range was chance. Fixed with
`move_to_entity {"entity": "bramblebun", "within": 3.0}` (re-resolves a live
individual every frame) followed by `interact_with` (presses only when the
arbiter has a live prompt, FAILs naming what it saw instead of pressing
blind).

---

## RIG-17 — `interact_with`'s relatedness check refuses a valid manager-owned prompt

**Severity: BLOCKER for evidence quality.** Fixed. `interact_with`'s
`check_provider` test requires the winning provider be the found node or an
ancestor/descendant of it — but the wild-engage prompt is owned by
`EncounterDirector`, not the bramblebun itself, so RIG-16's fix (correctly
finding a live bramblebun) still refused every one of five engage offers,
never starting combat once. Fixed by matching `expect_prompt: "Engage"` with
`check_provider: false`, since the prompt's own text is the only reliable
signal for a manager-owned offer. This also means the steps now correctly
refuse a stale fainted-ally prompt instead of misfiring into it. Separately,
`move_to_entity`'s `within: 3.0` was too tight against real 3D terrain
(0.03 m short on a mixed-vertical margin); widened to 4.5 m.

With RIG-16 and RIG-17 both fixed, S03 produced **3 real combat_start
events** — real engage/combat/throw cycles at attempts 1, 2 and 5 of ten.

---

## RIG-18 (open) — S03's team stayed at one creature; not a rig defect, left unresolved rather than re-rolled again

**Severity: recorded as GAME-relevant with a RIG coverage gap, not chased
further.** All three real S03 throws missed the team-of-three milestone.
Telemetry narrows why partway: attempt 1's throw came at a wild creature at
~5.6% HP (a fair, well-weakened attempt) and still missed; attempt 2
re-engaged the SAME creature and its own snapshots show `opponent_hp: [0.0]`
by the time its throw fired — the fixed `combat_quick x20` "weaken" pass does
not know the target's current HP and can finish off a creature a previous
attempt already brought low, wasting a throw on a target that can no longer
be caught. Separately, `throw_aim.gd` describes a real aim-and-reticle system
that the harness has no step primitive to drive (`press interact` / `press
interact` does not aim it the way `tests/smoke_catching.gd`'s own
`_aim_camera_along()` does) — whether any of the three throws had a
body-reaching trajectory at all is unmeasured.

**Left OPEN.** Diagnosing it needs either a new step primitive that aims a
throw at a resolved entity, or a per-attempt HP check the step-script does not
have a way to express. Guessing at `combat_quick` counts across three
different values (14, 14 again, 20) with zero catches was not converging.
Per protocol §0.6, a small sample of misses is not a verdict about the game's
catch odds, and this rewrite does not re-open the guessing.

**Consequence, confirmed again by this rewrite's own party-size query above:**
party size stayed at exactly 1 for the whole of S03 through S09. Every
tournament/team-size-gated FAIL from S04 forward is a direct, expected
consequence of RIG-18, compounded by RIG-13's stranding from S05 on, not an
independent finding about band 2-5 content.

---

## RIG-19 — X04's own `move_to` budgets are far too small for the distances between its entry saves and its own named combat sites, so the combat lab produced zero real fights

**Severity: BLOCKER for evidence quality.** Not fixed (out of this operator's
scope — `tools/gate_f/` rig primitives belong to a concurrent lane).

Found running X04 to completion in this pass: **every one of X04's seven
`move_to` steps FAILed, across all three of its entry saves, including the
one entry (`S04-exit`) that is genuinely clean of the South Bridge
stranding.** None of X04's steps specify an explicit `budget_frames`, so
each uses the harness's apparent default of 2400 frames (~40 s of game
time, roughly 150-500 m of ground at this run's measured walking speeds) —
nowhere near enough for the actual distances involved:

| step | target (combat site) | from | short by |
|---|---|---|---:|
| X04-019 | South Bridge grunt (14, 1314) | `S04-exit`, village | 1109.6 m |
| X04-030/058/066/078 | band 1 field (195, 905) | continuing from X04-019's stop | 530→402→283→110 m (4 hops, still short) |
| X04-094 | Warrens mouth (-420, 2470) | `S06-exit` (already at the stranding corridor per the correction above) | 1224.5 m |
| X04-111 | Hall threshold (150, 7595) | `S09-exit` (also stranded) | 6278.2 m |

The 195/905 target's four consecutive hops do show real cumulative
progress (1109→530→402→283→110 m short) — confirming `move_to` genuinely
resumes from the player's current position rather than resetting — but the
script only budgets four attempts, and four is not enough. **This means
X04's own `S04-exit` third, the one entry save this pass confirmed is
completely clear of the stranding, still never got a single fight to
start** — a defect independent of RIG-13, found for the first time in this
run because X04 had never been run before this pass.

**Consequence: `combat_start` count for the entirety of X04 is 0.** Every
one of X04's thirteen CB test cases (intentional loss, faint mid-fight,
switching under pressure, camera stress, arena-edge stress, size/range
spread, lighting variants) FAILed at the `input_context=world (wanted
combat)` assert that follows its unreached move_to, because no fight ever
started. **This run now has zero combat evidence anywhere past S03** — not
because of the stranding alone, but because the one segment purpose-built
to route around the stranding (partially, via `S04-exit`) has its own,
separate travel-budget defect.

**Recommended fix**, for whoever owns `tools/gate_f/segments/X04.json`:
either give each of these `move_to` steps an explicit `budget_frames` sized
to the real distance (matching the journey segments' own practice of
`args.budget_frames` scaled to distance), or use `debug_teleport` if X04 is
judged to be enough of a study/lab segment to permit it (protocol §0.1
allows teleport only in `DIAG-` prefixed segments; X04 is not one, so this
would need an explicit protocol exception, not a quiet workaround).

---

## RIG-20 — `region` containment reports `corridor` even at the Stronghold approach and the Hall, teleported to directly, far from the South Bridge

**Severity: recorded as context for the concurrent T2-STRANDING lane, not
chased further.** Found running X07 (DIAG world/regional audit, teleport
permitted, no stranding exposure — see the coordinator's exposure table).

X07-144 and X07-164 teleport directly to the named region centres of the
Stronghold approach `(-65, 7028)` and the Hall `(150, 7595)` and land exactly
on target (`0.0 m` off in both cases — the teleport primitive itself is
accurate). But `map_state.gd`'s own region-containment check reports
`region=corridor` at both, not `stronghold_approach` or `hall`
(X07-145/X07-165, both FAIL). These coordinates are **5.7-6.3 km from the
South Bridge carve** (z≈7028/7595 versus the stranding cluster's
z≈1314-1326) — nowhere near the corridor this run has been calling "the
South Bridge stranding."

**This raises a real question the T2-STRANDING lane should be aware of,
without this operator answering it**: is `corridor` a name specific to the
South Bridge carve, or is it the containment check's generic fallback for
"no defined named-region polygon contains this point" anywhere on the map?
If the latter, then the position clustering in RIG-13 (every stranded
`move_to` landing at `region=corridor`) is evidence the player is somewhere
outside every named region's polygon — consistent with, but not identical
to, being specifically stuck at the bridge geometry. If `stronghold_approach`
and `hall`'s own region polygons simply don't cover their own landmark
coordinates (a separate, plain data gap), that would explain this finding
without implying anything about the South Bridge at all. **Not
distinguished by this run** — flagged here because it directly bears on how
literally to read every `region=corridor` line in RIG-13's evidence table
above.

---

## RIG-21 — the South Bridge stranding's root cause, found and verdicted by the concurrent T2-STRANDING lane: RIG, not GAME

**Severity: BLOCKER, root cause of RIG-13.** Credit: this finding, its
live-engine verification, and its fix are entirely T2-STRANDING's work
(`ralph/reports/FINDING-T2-STRANDING-2026-08-30.md`,
`origin/ralph/T2-STRANDING@08506512`), summarized here because it resolves
the open question this document's RIG-13 section and the companion GAME
document both left open. **This operator did not do this diagnosis** — the
credit belongs with T2-STRANDING, and this summary should not be read as
independent confirmation beyond the exit-save table this operator can and
did check directly (see the boxed correction above).

**Verdict: RIG, confirmed live in the running engine, not a broken game
system.** T2-STRANDING's own probe (`tools/gate_f/probe_stranding_cause.gd`,
run against this run's real `S05-exit.json`) reproduces the exact block and
its exact cure in one script: loading the save shows `active creature: Moss
fainted=true`; `can_challenge(south_bridge_grunt)` is `false`; healing the
one creature the way a creature bed does (`heal_fully()`) — nothing else
touched — flips `can_challenge()` to `true`. The chain, each link verified
against source:

1. S03's own catch loop fainted the player's only creature on a fair,
   non-buggy roll (`S03/telemetry/events.jsonl`, `t=256.0`, "Moss fainted",
   `hp: 0.0/1.18`) — RIG-18 checked the catch odds were fair but never
   checked the player's own creature's HP during those same fights.
2. `encounter_director.gd::summon_active_creature()` correctly refuses to
   deploy a fainted creature (line 864).
3. `can_challenge()` correctly refuses every trainer/gate fight with no
   deployed ally (line 1568) — this is why "Old Bram" in S05 (S05-34..38)
   and the South Bridge grunt three minutes later both show only `dialogue`
   events, never `combat_start`, despite the step-script's presses landing.
4. `trainer_npc.gd::_on_challenged()` cannot distinguish "no usable
   creature" from "already beaten" and shows the `defeated` line for both —
   which is why the grunt's post-victory dialogue appeared on a completely
   fresh approach in `RESTARTS.md`'s own open finding. **A real, minor,
   player-facing UX gap** (flagged for Track 3, not the stranding's cause):
   `autoload/party.gd::all_fainted()` has zero callers anywhere in the
   codebase, so nothing auto-heals or explains the state to a real player
   either — though a real player is never physically stuck (creature beds,
   built during S03's own tutorial, are an always-available recovery path;
   human movement is never gated on creature state, by hard rule), just
   confused by a trainer falsely claiming a win that never happened.
5. The South Bridge gate is a real, correctly-locked physical collision
   barrier; `south_bridge_key` is exclusively the grunt's combat reward. The
   fight never starting means the gate never opens — the intended design,
   working correctly.
6. Every `move_to` from S05 onward targeting a point past the bridge is
   asking the harness to walk through a permanently, legitimately locked
   gate. `severed_spokes.gd`'s carve failsafe is a real, correctly-
   functioning recovery system, firing on a genuine loop the walker cannot
   break out of on its own — not malfunctioning, just triggered relentlessly.

**The fix** (pushed alongside the finding, to `tools/gate_f/segments/
S03.json` only — no game code, data, or content path touched): five new
steps immediately after S03's three creature beds are confirmed built and
before its existing sleep sequence, walking to a bed and assigning the
fainted creature to it before sleeping, so the existing sleep step's heal
actually has something to heal. **Rig-only, per this lane's own file
ownership rules T2-STRANDING is not exempt from either** — confirmed by
this operator's own read of the pushed diff, touching only the segment
step-script.

**Independent discovery, found validating the fix, not itself resolved:**
a full S03 re-run under the fix still produced a fainted exit save, because
`S03-205` — pre-existing, unmodified by the fix — FAILs
(`creature_bed_built_3 NOT set`) **in both the original run and the
fix-validation run identically**: the tutorial's analog-stick-driven ghost
placement does not register with `home_progress.gd` in this environment, so
no bed ever actually gets built for the new steps to use. T2-STRANDING
validated the new steps' own correctness in isolation instead
(`tools/gate_f/probe_bed_rest_sequence.gd`, building a real `creature_bed.gd`
the way `build_placer.gd` does): PASS end to end, HP restored, `fainted`
cleared. **This build-placement registration gap is a separate, pre-existing
defect, not introduced by and not fixed by this pass** — flagged by
T2-STRANDING as worth its own ticket, and worth naming here because it is
very likely inflating S03's own already-recorded FAIL count for reasons
that have nothing to do with the stranding, and blocks the S03 re-run this
whole chain needs before S04 onward can be re-run clean.

**Status at the time of this rewrite: the unblock is NOT complete.** A
healthy S03 exit save does not yet exist. **X03 and X06 remain correctly
held** (per the coordinator's gate) until a real healthy chain exists — do
not run them against the currently-stranded saves, and do not treat a
future run against saves produced before this fix as current evidence.
**S05 through S10's existing evidence in this run describes the stranding
itself, not bands 2-5**, and does not become valid retroactively; a real
re-run from a healthy S03 onward is still needed for band 2-5 content
evidence.

**Update, 2026-08-30, after T2-BUILDPLACE's own handover landed
(`origin/ralph/T2-BUILDPLACE`, `ralph/reports/handover-T2-BUILDPLACE-2026-08-30.md`):
still not complete, and the remaining gap has changed shape.** T2-BUILDPLACE
fixed the S03 build-placement RIG defect this section already named
(confirmed live: `S03.json`'s gathering loop never equipped a tool before
harvesting tool-gated resources) and independently re-derived GAME-0 while
proving it out. **But ten full-segment replays did not converge on a
100%-reliable walk to Mira** — the catch loop's own upstream RNG varies the
player's exact position entering that leg enough that the same walk target
lands anywhere from 0-120 held frames and 2.27-4.9m short, run to run.
**No healthy `S03-exit.json` exists yet.** This operator is explicitly NOT
starting the S03-S10 re-run on this basis, per the coordinator's own
stated fallback: "if the build-placement fix does not land, say so plainly
rather than running the re-run against a party you know is fainted."
T2-BUILDPLACE's own handover names the exact next diagnostic (replicate
`interactable.gd::_has_line_of_sight`'s clearance-trimmed raycast in a
probe, or add temporary logging inside `interaction_offer()` itself, rather
than continuing to guess at `move_to`/`move_to_entity` tolerances) for
whoever picks this up next.

---

## RIG-22 — the RIG-14 fixed-tab-cycle defect also lives in X05's own save-verification steps, and was never fixed

**Severity: BLOCKER for evidence quality.** Not fixed. Found by this
operator directly, stopping X05 partway through (see
`X05/INCOMPLETE.md`).

X05's own repeated "verify a normal save" steps (one per `S0n-exit` block,
e.g. `X05-015`) open the pause shell with a bare `open_menu` and press
`menu_tab_right` a fixed 5 times, assuming a Backpack(0) start — the exact
RIG-14 shape, unfixed in this file, same as the fresh instance this rewrite
already found in `X02.json` (see RIG-14 above). Confirmed directly in the
telemetry of the 8 `S0n-exit` blocks that completed before this segment was
stopped: **at least 7 of them** land on the wrong tab
(`input_context=menu_backpack`/`menu_quest_log`/`menu_creatures`/
`menu_settings` — wanted `menu_save`) and the following save-write assert
correctly reports `FAIL slot N has no file ... did the Save tab actually
write?` — because the Save tab was never actually reached, not because
saving itself failed.

**Consequence: this run has no confirmed evidence that the production Save
tab actually writes a file, across any of the 8 `S0n-exit` blocks X05
completed.** Every one of its "does save actually write" checks is reading
the same tab-navigation miss RIG-14 already named, not the save system.
This is the single most direct instance yet of RIG-7's thesis: the
underlying save mechanism may well work (S07-S09's own `save_out` steps in
the journey segments successfully wrote real files, per `HANDOFF_
PROVENANCE.md`, once RIG-14 was fixed there) — X05 simply never asked the
question correctly. **Recommend the same fix as RIG-14**: open the shell via
a named tab and adjust the press count from wherever that tab actually
lands, applied here and swept across every other tab-cycle step in every
segment rather than patched file-by-file as each one is discovered.

---

## RESOLVED — does the South Bridge gate ever actually open? (formerly an open finding, closed by RIG-21)

**This was open in the previous draft and in this rewrite's own first pass.
It is resolved now: see RIG-21 above.** The prior text asked whether
`trainer_npc.gd::_on_challenged` showing the `defeated` line meant a
residual ally-deployment gap or something about the encounter's own state.
It was neither, precisely — it was `can_challenge()`'s fourth reason
(`_ally.fainted`), not the third (`_ally == null`) the RIG-11/RIG-13
`creature_recall` fix addressed. The ally *was* deployed; it was fainted,
and had been since S03. T2-STRANDING's probe isolated exactly the
`can_challenge()` booleans this document's prior draft said would need a
live probe to distinguish, and found the fainted-ally branch, not the
no-ally branch.

---

## RIG-23 — the S03 exit leg from Mira's shop was pointed at a target behind a wall (FIXED, T2-GATEF-RUN5)

> **RESOLVED by `ralph/T2-GATEF-RUN5`, 2026-08-30.** The diagnosis below was
> right about where the walker ended up and wrong about why, and the
> difference is the whole reason four sessions of waypoint guesses all
> reproduced the same wedge.
>
> `S03-59a` already asked for the correct point — cottage_a's own door
> staging point at building-local (1.0, 4.0), the one `S03-52` uses on the
> way in — and still left the player INSIDE the shop, because its
> `close_enough` was 2.0 m and the doorway is only 1.9 m from that point.
> The leg returned true standing at local (0.78, 2.15), a step short of the
> front wall. `S03-60` then set off from inside the room toward Oskar, who
> is at building-local **(-5.66, 0)**: due west, straight through the wall
> the stock crates are stacked against, 180 degrees from the only way out.
> No obstacle-avoidance heuristic can route a leg whose target is behind a
> wall. The walker was not choosing the wrong side of the counter; it was
> being asked to walk through plaster and doing the only thing it could.
>
> Fix: `close_enough` 2.0 -> 0.8 on `S03-59a`, so the leg cannot terminate
> until the body is genuinely outside the building, with the budget raised
> from 400 to 1500 to match. Live-proved by
> `tools/gate_f/probe_shop_exit_clearance.gd`: from behind Mira's counter,
> out to the staging point ARRIVES in **38 walking frames** and Oskar then
> ARRIVES in **79 more**, against a full 3000-frame budget exhaustion for
> the direct line.
>
> **`stick_navigator.gd` was separately fixed, and needed it.** Its
> clearance probe was one hairline ray at hip height (`PROBE_HEIGHT := 1.0`)
> — blind to anything shorter than a metre (the stock crates top out at
> 0.50 m and 0.945 m; the counter at exactly 1.00 m) and blind to width (a
> ray has none, the player capsule is 0.8 m across, and the gap between the
> west wall and the crates is 0.14 m). Measured live at the wedge point, the
> old probe reported **1.50 m** of clearance on the side where the body
> actually has **0.25 m**. It now sweeps the volume the body occupies —
> three heights by three lateral offsets, nine rays, nearest hit wins, with
> the lowest height above `player_controller.gd::STEP_HEIGHT` so a kerb the
> body steps over does not read as a wall — refuses to commit a detour to a
> side narrower than the body, backs out of a pocket when both sides are
> pinched, and abandons a detour that has stopped carrying the body
> anywhere instead of grinding out its frame count. On the unsolvable direct
> leg the walker now ends up free in the middle of the room rather than
> jammed at local x=-1.37.
>
> **A real player was never trapped there.** Asked directly, from four
> starts inside the wall/crate pocket, with a plain held stick and no
> detour logic at all: all four escape to the door lane
> (`probe_shop_exit_clearance.gd`, question 3). The 0.14 m gap the harness
> wedged in is one no 0.8 m-wide body can enter in the first place. No
> `shop_interior.gd` geometry change was made or is needed.

**Severity: BLOCKER for S03 evidence quality.** *(Original entry, kept for
the record.)* Not fixed at the time. Found by
`ralph/T2-GATEF-RUN4` re-running S03 with T2-BUILDPLACE round 3's door +
revive fix and this session's own GAME-0/T1 fixes all in place — a real
replay still ends with `home_built`/`creature_bed_built_3` unset and the
party permanently fainted. Full mechanism and two new committed live
probes (`tools/gate_f/probe_oskar_walk_trace.gd`,
`tools/gate_f/probe_oskar_stuck_geometry.gd`) are in the companion GAME
document's new **GAME-8** entry — recorded there rather than duplicated
here because the underlying geometry (`shop_interior.gd`'s counter/shelf
placement) is a real GAME-content question, not purely a harness one, even
though the immediate symptom is `stick_navigator.gd`'s detour logic
getting wedged in a ~0.3-0.4m gap between a shelf and the west wall.

Worth recording here specifically: this is the SAME shape as RIG-13
through RIG-22 above — a real, working fix (the door) that closed one gap
and let the walk reach a NEW one immediately behind it, invisible until
the first gap closed. A new staging step (`S03-59a`) that routes the exit
leg through the same point the entry leg already uses cleanly did **not**
converge, which rules out "the entry-leg staging point just needs
reusing" as the fix — whoever picks this up next should read GAME-8's own
account of what was tried (four different waypoints, all trapping at the
same or a near-identical point) before spending more replay cycles on
coordinate tuning.

## RIG-24 — the tool-equip sequence's own isolated-probe PASS did not predict its behaviour inside a full segment replay (FIXED, T2-GATEF-RUN5)

> **RESOLVED by `ralph/T2-GATEF-RUN5`, 2026-08-30, and the two probes were
> never running the same recipe.** `probe_tool_equip_sequence.gd` calls
> `inventory.find_slot("knife")` and drives the cursor to the slot the knife
> is ACTUALLY in. `S03.json` pressed `ui_right` a hardcoded four times,
> counting cells along the order a fresh `S02-exit.json` happens to fill the
> bag in. The probe's PASS was never evidence about the segment's scheme.
>
> Two independent things then broke the count, and the second is decisive:
> the bag is not fresh (run 4's own telemetry shows both Revive draughts
> spent and potions down from three to one before a tool is bound), and
> **`ui_left` does not wrap up a grid row** — so from the knife's cell the
> three left presses walked backwards along row 0 instead of reaching the
> pickaxe on row 1. `S03-56f`'s own note claimed the wrap ("wrapping up a
> grid row"); it does not happen.
>
> Reproduced exactly by `tools/gate_f/probe_tool_equip_depleted_bag.gd`,
> which rebuilds run 4's own depleted bag and runs both schemes against it.
> The shipped counts leave the hotbar `["", "", "potion_small", "knife",
> ""]` — which is precisely the `{hotbar_slot: 3, item: "knife"}` every one
> of run 4's six real gathers reported, bit for bit. Slot-addressed, the
> same bag yields `["", "axe", "pickaxe", "knife", ""]`.
>
> Fix: a new harness action, **`focus_item`** (`operator_harness.gd::
> _step_focus_item`, documented in `tools/gate_f/SEGMENT_SCHEMA.md`), backed
> by `gate_f_probe.gd::satchel_slot_of()`, `satchel_focus()` and
> `satchel_columns()`. It sends the same real `ui_*` events `focus_move`
> sends and simply reads the cursor between them, navigating column-then-row
> the way `probe_tool_equip_sequence.gd` already did. `S03-56d/f/h` now name
> the item instead of a press count. A cell count that cannot be reached, or
> an item the bag does not hold, now FAILs loudly instead of binding the
> wrong thing in silence.
>
> **The standing caution below still stands and is if anything sharpened**:
> the isolated probe did not merely fail to predict the replay, it was not
> testing the same mechanism at all. When a probe and a segment disagree,
> check that they are running the same gesture before theorising about
> state.

**Severity: SHIP candidate, not root-caused.** *(Original entry, kept for the
record.)* Not fixed at the time. Also found by
`ralph/T2-GATEF-RUN4` in the same replay as RIG-23. `tools/gate_f/
probe_tool_equip_sequence.gd` (T2-BUILDPLACE) proves the hotbar-assign
sequence correct from a fresh `S02-exit.json` — but a real S03 replay
after ~450 seconds of prior segment state (two fights, two revives, a
third unhealed faint, the door detour) shows every one of six real
`gather` attempts equipped with the identical `{hotbar_slot: 3, item:
"knife"}`, never switching tools despite the segment's own
`hotbar_2`/`hotbar_3`/`hotbar_4` presses between nodes. See GAME-9 in the
companion document for the full account. Named here as the same general
caution T2-BUILDPLACE's own handover already recorded once this run
(a probe that exercises a mechanism from a clean/isolated start can pass
while the same mechanism fails inside a long, stateful replay) — worth
treating as a standing rule for this repo's own rig-validation practice,
not just this one instance of it.


## RIG-25 — a segment step that opens a pausing panel needs a matching close AND a context assert (T2-GATEF-RUN5)

**Severity: RIG, fixed in S03, unaudited elsewhere.** The full account is
GAME-10 in the companion document. Named here because it is a rule about
how these segments are written, not a fact about Oskar.

Mira's shop is opened by her greeting, closed by `S03-56`, and the world
re-asserted by `S03-56a`. Oskar's creature swap is opened the same way by
the same machinery (`sequence_director.gd::_maybe_open_shop()`) and had
**neither** step. It went unnoticed for four sessions only because RIG-23
meant the walk to Oskar never arrived and his dialogue never ran.

Two things worth carrying forward:

1. **The assert is the half that pays.** Without `S03-62b`, one stuck panel
   reported as 71 unrelated-looking failures spread across the rest of the
   segment — walks that "did not reach", hotbar presses that equipped
   nothing, menu opens that found the wrong context. With it, the segment
   stops at the real cause. Every `shop:` / `battle:` / picker effect a
   segment triggers should be followed by a close and an
   `assert input_context`.
2. **`0 held` does not mean the body was free to move.** The walker reported
   `0 held` for every failed leg while never leaving `(19,-6)`, because
   `stick_navigator.gd::can_walk()` reads `locomotion_enabled` — and a panel
   owning input leaves locomotion nominally enabled while swallowing the
   stick. Prior write-ups (including BUILDPLACE round 3's, already corrected
   once by RUN4 on a related point) have read `0 held` as evidence that
   nothing was blocking the player. It is not that evidence.

**Unaudited:** every other segment that triggers a shop, battle or picker
effect. This one was found by tripping over it, not by looking.
## RIG-26 — S02 engaged a coordinate, not a creature, and the margin was one centimetre (FIXED, T2-GATEF-RUN6)

**Severity: RIG, fixed. This is the defect that produced "zero combat
events" and it had been read as a possible game blocker since check-in 17
of the lane log (2026-08-27), through six runs.** The lane log's own
wording was *"the chapter's first fight never stages, and the first catch
never happens,"* recorded with `severity_candidate: BLOCKER`.

**The game was never at fault.** `tools/gate_f/diag/probe_s02_encounter.gd`
pass 4, run live on this candidate, stands the player at S02's own recorded
press point `(26.78, -38.32)` with a creature deployed and samples the
offer once a play-second for thirty seconds:

```
[s02] engage_range                         = 6.00 m
[s02] nearest wild creature, over 30 s     = 5.99 m min, 5.99 m max
[s02] samples where the game offered Engage = 30 of 30
[s02]    director.interaction_offer = {"actionable":true,"distance":5.99,"label":"Engage Bramblebun","priority":0}
[s02]    pressed interact: is_fighting false -> true   >>> A FIGHT STARTED
```

**5.99 m against a 6.00 m `flow.engage_range`.** The run that recorded the
blocker stood one centimetre inside the reach, and which side of that line
a given boot lands on is decided by `_rng.randomize()` in
`wild_creature.gd` — the same call `encounter_director.gd:549`'s own
comment already warns *"means every boot rolls a different wander path with
no way to predict where a resident ends up."*

The step could not have been reliable. `S02-30` was
`move_to {"at": [30,-40], "close_enough": 4.0}` — a hardcoded coordinate,
with a four-metre arrival tolerance, aimed at a creature that roams a seven
metre radius, to be engaged at six metres, followed by `S02-32` pressing
`interact` **once**. And `S02-32` was a bare `press`, which asserts that
input was injected and not that anything received it, so it PASSed into an
unengaged world every time and pushed the visible failure four steps
downstream where it read as "combat never took input ownership."

**Fix**, and it is the pattern this protocol already had: `S02-31a` is a
`move_to_entity` that resolves the live creature and re-reads its position
every frame, and `S02-32` is now an `interact_with` asserting the `Engage`
prompt before pressing. `S03-32a..j2` has engaged the same species this way
for several runs. S02 was never updated.

**Result:** S02 emits `combat_start`, `combat_hit`, `combat_end`,
`catch_throw` and `catch_result` for the first time in this effort.

**The general rule, and it is the same one RIG-25 states from the other
side:** a bare `press` proves an injection, not an interaction. Any step
whose whole point is that something received the press should be
`interact_with`, which refuses with a reason instead of passing into
nothing. This is the third distinct defect this run's segment set has hidden
behind a step that PASSed while doing nothing.

## RIG-27 — S02's attack script was tuned against damage numbers that no longer exist, and asserted the catch before the game owed it (FIXED, T2-GATEF-RUN6)

**Severity: RIG, fixed.** Two separate staleness defects behind the same
step block, both found by running it.

**1. The damage note was stale by a factor of 2.3.** `S02-36` carried an
authored observation reading *"MEASURED, not guessed: the bramblebun at
opponent_hp 124.2 full, 43.1 after these 14 quick attacks (~5.8 damage
each)"*. Measured on this candidate, a quick attack lands **~13.4** and the
charged attack **~56**. Damage was rebalanced after that note was written
and the note was never re-measured. Running the script as authored — six
quick attacks then the charged — produced this:

```
104.3 -> 91.3 -> 78.0 -> 63.8 -> 49.4 -> 0.0
combat_end at t=226.45
```

The charged attack **fainted the creature**, and the catch sequence that
follows had nothing left to throw at. The segment then reported "party size
1 (wanted 2)" — a catch failure — for a creature that was already dead.
The charged attack is now taken first, at full health where it cannot faint
anything, with quick attacks trimming afterwards.

Check-in 17 already warned that this note *"must NOT be misread as this
run's data"*. It was right, and the deeper problem is that an `observation`
field carrying a measurement from a superseded build is indistinguishable
from one carrying this run's. **Every tuning note of this shape in the
segment set is suspect until re-measured.**

**2. The catch was asserted one throw too early.** `S02-45`
(`party_size == 2`) sat immediately after the first throw. But
`data/config/opening.json` sets `max_catch_failures: 1`, and
`combat_manager.gd:1273` applies that bound to **landed** throws, so the
game's "cannot fail twice" promise is kept on the **second** throw. The
assert was reading a legitimate, designed first failure as a defect. Moved
to after the retry blocks.

That correction is what exposed GAME-12: the retries re-enter the aim and
never throw, so the guarantee cannot currently be reached at all.

## RIG-25 audit — the open-without-close sweep RUN5 asked for (DONE, T2-GATEF-RUN6)

RIG-25 recorded that *"every other segment that triggers a shop, battle or
picker effect"* was unaudited for the missing close-and-assert pair, and
that it had been found by tripping over it rather than by looking. Looked.

Ten conversations open a pausing panel, all through
`sequence_director.gd::_maybe_open_shop()`:

| effect | conversations |
|---|---|
| `shop:goods:mira` | `village_mira_shop_intro`, `village_mira_shop`, `village_mira_beaten`, `village_mira_freed` |
| `shop:goods:bram` | `village_bram_shop_intro`, `village_bram_shop` |
| `shop:creatures:oskar` | `village_oskar_trade_intro`, `village_oskar_trade`, `village_oskar_beaten`, `village_oskar_freed` |

Cross-referenced against every step in the segment set that greets one of
those three. **One real gap, now closed:**

- **`S03C-61` (Oskar) had neither the close nor the assert.** `S03.json`
  received `S03-62a`/`S03-62b` from RUN5's GAME-10 fix; its capture-mode
  twin `S03C.json` never did, so a capture run of S03C would have
  reproduced GAME-10 in full — the same seventy-one-failure cascade, in the
  lane whose whole purpose is the frames. Added both steps.

**Cleared, with the evidence rather than by inspection:**

- **S04's Mira and Oskar steps (`S04-26`, `S04-41`) are not a gap.** They
  are tournament conversations, not the shop greetings. RUN5's own S04
  telemetry settles it: the segment's entire `input_context` census is
  `world` 77, `menu_map` 2, `menu_quest_log` 1, `menu_build` 1,
  `menu_save` 8, and it returns to `world` at `menu_close`. No panel was
  ever left holding input.
- **X01's fourteen Bram/Oskar steps are not a gap.** X01 is the menu-cell
  probe segment; its `probe_cell` steps drive and restore the panel
  deliberately, and it carries 105 `input_context` asserts of its own.

**And the `beaten`/`freed` conversations are an unrun risk, not a cleared
one.** `village_mira_beaten` and `village_oskar_beaten` open the same
panels after the tournament, and `village_*_freed` after the finale.
Nothing in the segment set has reached them yet — S04 has never been won
(GAME-11 starves it, see the per-segment notes) and the finale is S10. When
a future run first wins the tournament, those two greetings will open a
panel for the first time, and **the close-and-assert pair must be in place
before that run, not after it.** That is the same order-of-discovery trap
GAME-10 sprang on RUN5.


---

## What these twenty-two have in common

Read together, RIG-1 through RIG-12 are mostly *instrument* defects: they
would be misread as findings about the game if taken at face value (26
objectives that never advance, a chapter too expensive to play, a village
with a spot you cannot walk out of, an opening whose first fight never
happens). RIG-13 through RIG-22 are a different shape: real fixes that
**worked exactly as intended and still did not produce the evidence they were
fixed to produce**, because each fix closed one gap and the next segment hit
a different one — no ally deployed (RIG-11), only some segments fixed
(RIG-13), a corrupted handoff hiding the first two (RIG-14), an assert too
strict to read a real outcome (RIG-15), a blind press at the wrong target
(RIG-16), a relatedness check refusing a valid prompt (RIG-17) — six fixes
deep before a single real combat_start event appeared anywhere in this run,
and even then, only in S03.

**X04 was this run's attempt to cash that fix in, and it did not work
either — for a seventh reason.** RIG-19 (above) found that X04's own
`move_to` steps carry no `budget_frames` and default to a value nowhere
near sufficient for the real distances between its entry saves and its own
named combat sites, so every one of its seven `move_to` steps FAILed,
across all three entry saves including the one (`S04-exit`) confirmed clean
of the stranding. **`combat_start` is now confirmed at zero for every
segment in this run from S04 through X04** — the entirety of the run past
S03's ten catch attempts. Seven fixes deep, and the chapter's actual combat
— difficulty, fairness, camera behavior, faint/recovery, switching — remains
completely unevidenced.

The corollary from the prior draft still holds and sharpens further: fixing
the instrument one gap at a time, verified only by the next re-run finding
the *next* gap, is expensive (this run alone: RIG-9 through RIG-19 across
several 30-90 minute re-run cycles) and still has not produced the thing all
of it was for. Getting real combat evidence now needs either a budget fix to
`X04.json` (RIG-19, out of this operator's scope) or a re-run of X04 once
that lands — not another journey segment against the same stranded chain.
