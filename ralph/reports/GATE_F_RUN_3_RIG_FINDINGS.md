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
- **RIG-5** (a modal that owns input produces a false navigation finding on `move_to`) — still open. This run's own S03 through S09 `move_to` FAILs never name the holding context (`(0 held)` on every one, see RIG-13 below) — consistent with this defect still being live, though in this run's case the actual cause of the stall is RIG-13's stranding, not an unclosed vendor panel.
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

## What these twenty-one have in common

Read together, RIG-1 through RIG-12 are mostly *instrument* defects: they
would be misread as findings about the game if taken at face value (26
objectives that never advance, a chapter too expensive to play, a village
with a spot you cannot walk out of, an opening whose first fight never
happens). RIG-13 through RIG-21 are a different shape: real fixes that
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
