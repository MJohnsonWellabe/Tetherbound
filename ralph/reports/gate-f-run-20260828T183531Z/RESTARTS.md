# RESTARTS — gate-f-run-20260828T183531Z

Section A's blocker rule: "only the affected segment restarts, from its entry
save. Pre-fix and post-fix evidence are never combined: the run directory gains
a RESTARTS.md naming segment, old SHA, new SHA, and reason, and the superseded
segment directory is renamed `<segment>-superseded-<n>`, never deleted."

| segment | old rig SHA | new rig SHA | reason |
|---|---|---|---|
| S03 | `0bd8781` | `435fbb8da3b085cbf4fc5c3710a2a969371c2ec0` | BLOCKED by the CD-7 cost gate at step 9 of 274, 91 s in. The gate priced the segment at 0.351 s/frame because its in-play recheck divided the 42.8 s the Load press spent building the Meadows by the 122 physics frames that had ticked, then projected that across 119,472 remaining frames — 11.6 h predicted for a segment that costs about half an hour. Fixed outside the run as CD-7c. |
| S04 | `0bd8781` | `435fbb8da3b085cbf4fc5c3710a2a969371c2ec0` | Not a segment failure. S04 was 100 s into its run when the operator stopped the driver to fix CD-7c; its process was killed mid-step. The partial directory is preserved rather than deleted, but it is **not evidence of anything** and no verdict in it may be read. |
| S05 | `fe39fbf` | `be4e986` | Not a segment failure, and the same shape as S04-superseded-1. S05 was 45 s of play time into its run (17 events, 90 route rows, still finishing the load-in at the village) when the operator session that launched it was reclaimed; its Godot process died with it, mid-step. No `INVENTORY.json`, no notes and no verdict were ever written. The partial directory is preserved rather than deleted, but it is **not evidence of anything** and nothing in it may be read as a result. Re-run from the same entry save, `S04-exit`. The two rig SHAs differ only by report commits: `tools/gate_f/` is unchanged between them (`git diff fe39fbf be4e986 -- tools/gate_f/` is empty by construction — no rig commit lands after CD-7c). |
| S05 | `be4e986` | `4e23c92` | RIG-9. The re-run at `be4e986` completed all 76 steps cleanly — 60 PASS, 7 FAIL, 9 DELEGATED, no derail, no harness error — and was then written out **INCOMPLETE** for 46 continuous frames "planned and not written", on a lane that had undertaken to take none. `record_hz` is zeroed for a logic lane at segment load, but `record_start` re-armed the recorder from its own args, so the two windows S05 declares spent themselves asking a headless process for frames. That is the outcome §H.1 forbids in its own words. The windows are now DELEGATED to `S05C` on the same terms as a prescribed §G frame. The fix cannot alter a step verdict — no step reads the recorder — but it changes what `INVENTORY.json` says about the segment, so the segment is re-run rather than have its own inventory corrected by hand. `S05-superseded-2/` is that clean-but-misfiled attempt and its 76 verdicts are readable; what may not be read from it is its `complete: false`. |
| S06 | `4e23c92` | `3fbcca3a2d6d460d8a8239815a1c5ff7a68b2d26` | Two independent reasons, neither a segment failure. (1) The session driving this attempt was reclaimed by the weekly rate limit mid-S06 (last event `t=1788.317`, no `INVENTORY.json`/notes ever written) — the same shape as S04-superseded-1 and S05-superseded-1. (2) Separately and worse: RIG-12 (see the fix commit above) — this attempt's own `load` event says `"seeded slot 4 from ralph/reports/gate-f-run-20260828T183531Z/S05-superseded-2/saves/S05-exit.json"`, not the kept `S05/saves/S05-exit.json`. `seed_save`'s `run://` fallback scan took whichever directory it visited last; `S05-superseded-2`'s exit save carries 1 progression flag against the kept `S05`'s 4. So even had the process survived, its entry state would have been the wrong one. The partial directory is preserved as `S06-superseded-1/` rather than deleted, but it is **not evidence of anything** and no verdict in it may be read. Re-run from the correct entry save, `S05/saves/S05-exit.json`, at the RIG-11-fixed rig SHA so the re-run's fights can actually start (see `RESUMED_RUN_20260829.md`). |
| S08 | `e24c28d9` | (unchanged — re-run only) | Not a segment failure. The session driving this attempt was reclaimed between S07's close and S08's own first assertion: the last three telemetry events are `catch_result`/`faint`/`gather` from the SAME load-restore instant (`t=1.05`, all sharing one timestamp), no `flag_set`/`objective_is` step or `creature_recall` press was ever issued, and no `INVENTORY.json` or `notes/S08.md` was written — the same shape as S04-superseded-1, S05-superseded-1 and S06-superseded-1. The partial directory is preserved as `S08-superseded-1/` rather than deleted, but it is **not evidence of anything** and no verdict in it may be read (its lone `faint` event describes the load restoring a fainted party from S07's exit save, not a fight that happened in S08). Re-run from the same entry save, `S07/saves/S07-exit.json`, at the same rig SHA — the RIG-11/RIG-12 fixes already cover S08's step-script, so no rig change is needed, only the re-run. |
| S08 | `f99985d2` | (unchanged — re-run only) | Not a segment failure; an operator-side wall-clock budget mistake. This attempt was run under `timeout 3000` (50 minutes real time) as a batch-launcher precaution, without accounting for `S08.json`'s own step budgets: `S08-97`'s `move_to` step alone declares `budget_frames: 99000` (≈27 minutes at this container's measured ≈0.0166 s/physics-frame Meadows cost), and the segment had already spent ~48 minutes of real time reaching step 96 of 135 before that step even began. `timeout` sent SIGTERM mid-step; Godot does not flush `INVENTORY.json` or `notes/S08.md` on that signal, so neither exists, and per this file's own rule **nothing in the partial may be read as a verdict** — including its last recorded `defect` line, which is preserved on disk but not cited here. What IS worth recording as an operator observation, not a finding: stdout shows `scripts/world/severed_spokes.gd`'s carve failsafe (`"[severed_spokes] player went over the edge ... back to the road"`) firing 851 times before the kill, consistent with `S08-97`'s straight-line `move_to` toward `captain_ridge` (-280,6460) repeatedly failing to clear a collapsed-spoke gorge and being reset by the world's own recovery volume each time. Because the walk loop's `walked` counter increments on every non-held frame regardless of an in-flight reposition (`_walk_loop` does not treat the failsafe's teleport as "held"), this is bounded (it will FAIL at 99000 frames, not hang forever) but was never going to finish inside a 50-minute wall clock. Re-run with a wall-clock budget sized to the step-script's own declared frame budgets, not a round number picked without reading them. |

| S03 | (varies — see below) | pending re-run | RIG-13 + RIG-14, discovered while resuming S08 for a third time. Two compounding rig defects, neither a finding about the game: **RIG-13** — RIG-11's own fix ("press `creature_recall` after every load so a deployed ally exists before any combat/gate assertion") was stated to cover "S03-S10" but was only ever WRITTEN into `S06.json` through `S10.json`; `S03.json`, `S04.json` and `S05.json` never got it. Without a deployed ally, `encounter_director.gd::can_challenge()` (line 1552: `_ally == null or _ally.fainted or _ally_body == null or ...`) returns false for every trainer, and `trainer_npc.gd::_on_challenged` (line 172) falls back to the NPC's `defeated` conversation line instead of `challenge` — not because the trainer was beaten, but because there was nothing to challenge with. Measured directly in S05's own telemetry: the South Bridge grunt's dialogue line at t=825.12 and t=827.22 is `south_bridge_grunt_beaten`'s own text ("Straight over and don't stop on the span...") on the FIRST-EVER approach, with `south_bridge_key` never once appearing in inventory and `south_bridge_open` never set. The same shape is independently visible in S04's tournament: `input_context=narrative_modal (wanted combat)` three separate times and every one of `tournament_team_ready`/`tournament_training_ready`/`tournament_condition_ready`/`tournament_entered`/`tournament_quarter_won`/`tournament_semi_won`/`tournament_won` NOT set. **RIG-14** — independently, `S04.json`/`S05.json`/`S07.json`/`S10.json`'s own end-of-segment save step opened the pause shell with a bare `open_menu` (no tab) and pressed `menu_tab_right` a fixed 5 times, assuming a Satchel start; but every journey segment's own Section E.5 map-navigation opens the Map tab earlier, and the shell (per `game_menu.gd`) reopens on the LAST TAB USED — so 5 presses from Map(index 2) wraps past Save(5) and lands on Backpack(0) again. The Save button was never focused, `ui_accept` did nothing, and `save_out` (RIG-10, already named in the `8463dadc` commit and never fixed) copied out whatever was already sitting in slot 4 — the segment's own SEEDED entry save — under the new segment's name, reporting PASS throughout. Confirmed directly: `S03/S04/S05-exit.json` are byte-identical (md5 `62344f09b811`, see `HANDOFF_PROVENANCE.md`) and `S06/S07-exit.json` are ALSO byte-identical (md5 `c69e42631f40`) despite S07 running for 2318 play-seconds and reporting 93 PASS/FAIL verdicts of its own. `S03.json`/`S06.json`/`S08.json` already had the correct fix (open via the `map` shortcut, then 3 presses, not 5) — S03's own S06-31 observation names the general defect but it was never propagated to the segments that actually needed it. **Net effect**: because S05 never opened the South Bridge gate, the player has been physically stranded at the band 1/2 boundary (stuck oscillating near (8,-3,~1317), the bridge's own carve centre) since partway through S05 — every `region=corridor`, `flag ... NOT set`, and enormous `move_to` FAIL from S05's tail through S06, S07 and S08 (three-plus segments) is a downstream symptom of this one gate, not an independent finding about band 2/3/4's own content. Fix: `creature_recall` added after the post-load settle in `S03.json`/`S04.json`/`S05.json` (mirroring `S06.json`'s own `S06-09a`); the save step in `S04.json`/`S05.json`/`S07.json`/`S10.json` changed to open via `{"tab": "map"}` and press `menu_tab_right` 3 times, mirroring `S06.json`/`S08.json`'s own working save steps. Per section A's rule, the earliest affected segment restarts and the chain rebuilds forward from it: `S03-superseded-2`, `S04-superseded-2`, `S05-superseded-3`, `S06-superseded-2`, `S07-superseded-1`, `S08-superseded-3` are the pre-fix attempts, preserved and **not readable as verdicts about the game** for any check downstream of a trainer/gate fight or a save handoff (map/UI/gather/build/travel-distance checks that do not depend on either are unaffected and may still be read). S03 through S08 all re-run in sequence from S02-exit forward. |

| S03 | (RIG-13/14-fixed rig) | pending re-run | RIG-15, found immediately on the RIG-13/14 re-run: `S03.json`'s third-catch step-script threw exactly ONE orb at the practice meadow's wild creature and then asserted the team had reached three. `data/config/catching.json`'s own words are "catch_chance ... nothing is ever certain" — a throw can miss on a real, non-buggy roll, and this one did: the re-run's telemetry has no `catch_result` event anywhere near the throw (t=203-209; the run's only `catch_result` is the load-time bootstrap "party grew 0 -> 1" at t=1.05, an artefact of `_prev_party_size` initialising at -1, not a second catch), and `S03-39`'s own party-size check confirmed the team stayed at 1. Compounding this, `party_size`'s `equals` check meant a script that (correctly) tried again after a miss, or a player who simply caught one extra creature along the way, would FAIL a check that a healthier team should PASS — the assertion was checking for an exact roster count where every caller actually meant "at least". Two fixes, both rig: (1) `operator_harness.gd`'s `party_size` check now accepts `min` (>=) alongside `equals`; every milestone `party_size` assertion in `S03.json` through `S10.json` (`S03-11/39`, `S04-10`, `S05-10`, `S06-10`, `S07-10`, `S08-10/34/45`, `S09-10`, `S10-10/77/87/107`) changed from `equals` to `min`. (2) `S03.json` gained three more full engage/weaken/aim/throw/wait cycles (`S03-32a` through `S03-38c`) after the original throw, so a single miss no longer caps the whole run's team at one creature for its remainder — this does not touch the game's catch odds, only how many times the script tries before giving up. `S03-superseded-3` and `S04-superseded-3` are the RIG-13/14-fixed-but-pre-RIG-15 attempts: S03's own verdicts up to and including `S03-39` are readable (real combat, real dialogue, a real throw that missed), but nothing from `S03-39` onward assumed a team of three, and none of S04's tournament verdicts can be read as anything but "the team was undersized," which was already true before RIG-13/14 and is not itself a new finding. S03 and S04 re-run again; S05-S08 (already superseded for RIG-13/14) follow once S04 produces a real team-of-three exit save. |

| S03 | (RIG-15-fixed rig) | pending re-run | RIG-16, found immediately on the RIG-15 re-run: all four throws (the original plus the three RIG-15 retries) missed the team-of-three assertion, and this time the FIRST engage's own `input_context` assert caught why -- `input_context=world (wanted combat)` at t=200.02, i.e. the fight never staged at all. The bramblebun cluster the segment walks to (`data/config/bands/band1_lower_meadows/spawns.json`: 3 bramblebun wandering a 15 m radius around (30,-40)) is not a fixed point a creature stands on; the old step walked to the cluster's CENTRE with plain `move_to` and pressed `interact` blind, so whether a live individual was actually in interact range at that moment was luck, not design, and RIG-15's retries repeated the same blind press from the same standing spot rather than re-approaching a live target. Fix: `S03.json`'s five catch attempts now each use `move_to_entity {"entity": "bramblebun", "within": 3.0}` (tracks a live individual's own position every frame, the primitive `selfcheck_reach.json`'s own CD-5 coverage already exercises) followed by `interact_with {"entity": "bramblebun"}` (presses only when `interaction_arbiter.gd` actually has this creature's prompt live, and FAILs naming what it saw instead of pressing blind) rather than a fixed-coordinate `move_to` plus an unconditional `press`. The weaken pass is also raised from 14 to 20 taps for a lower HP fraction and a better `catch_chance`. `S03-superseded-4` is the RIG-15-fixed-but-pre-RIG-16 attempt: none of its four throw cycles has a confirmed live fight behind it, so nothing from `S03-32` onward is readable, same as the run before it. |

| S03 | (RIG-16-fixed rig) | pending re-run | RIG-17, found immediately on the RIG-16 re-run: `interact_with {"entity": "bramblebun"}`'s own `check_provider` relatedness test (the winning provider must be the found node or an ancestor/descendant of it) can never pass for the wild-engage prompt, because `EncounterDirector` -- not the bramblebun -- owns it: attempt 1's own FAIL line names the live prompt as `"[img=...]xbox_button_x.png[/img]   Engage Bramblebun"` belonging to `'EncounterDirector'`, correctly refused as unrelated to `'bramblebun'`, even though it was exactly the offer the step meant to take. So RIG-16's fix, while correctly finding a live bramblebun (`move_to_entity` PASSed on 4 of 5 attempts), still refused to press ANY of the five engage offers, and combat never started even once -- the four throw cycles' `combat_quick`/`interact` presses all landed with nothing engaged, which is also why attempts 2-5 saw a stranger prompt still: `"Ripplet is out of the fight."`, `EncounterDirector`'s own message once the deployed ally is down and the (one-creature) party has no one to swap to, from whatever separately caused Moss's own HP to fall during the segment's earlier, already-working Bryn/wild fights. Fix: the five `interact_with` steps now match `expect_prompt: \"Engage\"` with `check_provider: false` instead of `entity`, since the prompt's own text -- not its owning node -- is the only reliable signal for a manager-owned offer; this also means the steps now correctly REFUSE when the live prompt is the fainted-ally message instead of a fresh engage offer, rather than misfiring into it. Separately, attempt 1's own `move_to_entity` FAILed on a 0.03 m 3D margin (2.98 m x/z, 3.01 m actual, 0.42 m of that vertical, on the meadow's uneven ground) against `within: 3.0`; widened to 4.5 m for the same five steps. `S03-superseded-5` is the RIG-16-fixed-but-pre-RIG-17 attempt: no engage press ever actually fired in it, so nothing from `S03-32a` onward is readable. |

| S03 | (RIG-17-fixed rig) | pending re-run | RIG-17's fix worked -- real combat happened twice (attempts 1 and 5 both PASSed their engage and their walk) -- but both real throws missed (`Moss fainted` at t=282.42, and attempts 2-4 all correctly refused on a live "Put Moss away"/fainted-ally prompt rather than a fresh engage offer, confirming a solo, unswappable party spends several attempts unable to re-engage after every real fight while its one creature recovers). This is not a new rig defect: catching two-for-two misses at whatever this species/orb combination's real chance is is ordinary variance, not a bug, and section 0.6 forbids reading anything into a small sample as if it were a verdict about the odds themselves. What IS a legitimate methodology gap, recorded rather than silently retried again: five attempts only ever produced two REAL throws, because a solo party recovers slowly between fights and most attempts in the run above were spent refusing a stale prompt rather than throwing. `S03.json`'s ten attempts (`a` through `j`) replace the five; nothing else changes. `S03-superseded-6` is this attempt: its two real engage/combat/throw cycles are genuine evidence (a missed catch is not itself a finding), but nothing from `S03-39` onward may be read since the team-of-three milestone was not reached. |

## RIG-18 (open, not fixed) -- why S03's team stayed at one, and why this run stops trying to fix it

The ten-attempt re-run (kept as `S03/`, not superseded) got three real
engage/combat/throw cycles (attempts 1, 2 and 5) and every other attempt
correctly refused a stale fainted-ally prompt rather than misfiring (RIG-17
working as intended). All three real throws still missed the team-of-three
milestone. Telemetry narrows *why* further than "bad luck": attempt 1's own
`combat` snapshots show the wild bramblebun at 6.98/124.2 HP (~5.6%, close to
`catching.json`'s `hp_factor_empty` ideal) at the moment of the throw --
a fair, well-weakened attempt that still missed -- but attempt 2 re-engaged
the SAME already-weakened survivor and its own snapshots show `opponent_hp:
[0.0]` by the time its throw fired, i.e. the fixed `combat_quick x20` "weaken"
pass does not know the target's current HP and can finish off a creature
its own previous attempt already brought low, wasting that throw on a
target that can no longer be caught at all. Separately, `throw_aim.gd`'s own
comment describes a real aim-and-reticle system ("orb.gd's own miss case for
throws that never reach the body at all") that this segment's `press
interact` / `press interact` pair does not drive at all -- the operator
harness has no step primitive that aims a throw the way `tests/
smoke_catching.gd`'s test-only `_aim_camera_along()` does, so whether any of
these three throws had a body-reaching trajectory at all is unmeasured.

**This is recorded as RIG-18 and left OPEN.** Diagnosing and fixing it
properly needs either a new step primitive that aims a throw at a resolved
entity (mirroring `move_to_entity`'s live tracking, for the reticle rather
than the feet) or a per-attempt HP check the step-script does not have a
way to express, and further guessing at combat_quick counts across another
several 30-45 minute re-runs was not converging (RIG-15 at 14, RIG-15's
own retry unchanged, RIG-16 unchanged, RIG-17 fixed the engage but not the
throw, this pass at 20 -- three different tap counts, zero catches). Per
section 0.6, a small sample of misses is not itself a verdict about the
game's odds, and this run stops re-rolling it.

**Consequence, stated plainly:** `S03/` is kept as this run's final S03 --
real combat, real dialogue, three real weaken/aim/throw cycles, an honest
miss each time -- and its exit save carries a team of ONE into S04 onward.
Every tournament/team-size-gated assertion from S04 forward that FAILs on
team size is a **direct, expected consequence of RIG-18, not a new finding
about band 2-5 content**, in exactly the same way S05's stranded-at-the-
bridge FAILs were a consequence of RIG-13/14 rather than independent findings
about bands 2-4. GAME findings from S04 onward are readable ONLY where they
do not depend on a team size the run never reached -- combat mechanics
against whatever DOES engage, UI/menu/map/build/gather behaviour, save
handoff, and travel/pacing measurements stay legitimate; anything gated on
`tournament_entered`/`tournament_won`/party size 3+ is not.

## Open finding, not chased further this run: the South Bridge gate still never opens even with RIG-13/14 fixed

S05 re-ran clean under RIG-13/14/18's understanding (real creature deployment
confirmed by `S05-09a`, a distinct exit save) and the South Bridge grunt
fight STILL never starts: `S05-48`'s `input_context` stays `narrative_modal`,
`south_bridge_open` stays unset, and the dialogue lines the encounter plays
are `south_bridge_grunt_beaten`'s own text ("Take it, I'll tell them you had
a key already" / "Straight over and don't stop on the span...") on a
completely fresh approach -- `defeated_south_bridge_grunt` does not appear
anywhere in `S04-exit.json` or anywhere in S05's own telemetry before this
point. `trainer_npc.gd::_on_challenged` (line 172) picks `defeated` text
whenever `can_challenge()` is false for ANY of its four reasons -- already
beaten, mid-fight, no ally, or a fainted ally -- so seeing that text is not
proof the grunt is (incorrectly) marked beaten; it is equally consistent
with `can_challenge()` failing on the ally check again despite RIG-13's
`creature_recall` press at segment start, for a reason not yet isolated
(the deployed-ally state living for a whole segment rather than surviving a
single load, an intervening region transition un-deploying it, or something
else `can_challenge()` checks). The telemetry also shows the same
world<->narrative_modal auto-flicker (several transitions with no button
press between them) first seen and left unanswered in earlier segments'
`BLOCKER.md` notes, which is consistent with either explanation and does not
settle it.

**Not chased further in this run.** RIG-13 through RIG-18 already cost several
re-run cycles each; isolating this one needs either a live probe of
`can_challenge()`'s own four booleans at the moment of the press (a harness
capability that does not exist yet) or reading `EncounterDirector`'s full
region-transition handling end to end, and section 0.6 is clear that another
guess-and-re-run cycle without a way to observe the actual boolean is not
converging evidence, it is more of the same trial the last six RIG numbers
already were. Recorded here as an **open, unresolved question** for the next
pass, with the concrete probe it needs named rather than guessed at again:
whether `_ally`/`_ally.fainted`/`_ally_body`/`is_instance_valid(_ally_body)`
are true or false at the exact frame `S05-45`'s `interact` press lands.
Until that is answered, `south_bridge_open` and everything gated behind it
in S05 onward is undetermined between a residual RIG gap and a real GAME
defect -- neither may be claimed from this run's evidence alone.

## What is NOT superseded

S01 and S02 ran to completion against `0bd8781` and are **kept**. CD-7c changes
when the cost gate refuses a segment and nothing else — it cannot alter a step
verdict in a segment that was never refused. Neither of them was: S01's
INVENTORY records no block, and S02's records none either. Their evidence
stands at the old rig SHA and this file is where a reader finds out that two
rig SHAs are present in one run directory.

The candidate SHA — the GAME — is unchanged at `main@26f0db4` for every segment
in this run. Only the rig moved.

## The superseded evidence is the finding

`S03-superseded-1/` is not a failed attempt to be ignored. It is the primary
evidence for CD-7c: `INVENTORY.json` there carries the two re-prices, the
0.351 s/frame measurement, and the refusal text, and `BLOCKER.md` carries the
gate's own words. The fix commit cites those numbers.
