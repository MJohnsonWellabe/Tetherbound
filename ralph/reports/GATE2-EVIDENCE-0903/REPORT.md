# Gate 2 evidence run — ROADMAP 2.8

**Lane:** `ralph/GATE2-EVIDENCE-0903`, branched from `main` `3c73aab5` (the merge carrying
Gate 2 tasks 2.2 / 2.3 / 2.6, CI truth and grass culling).
**Route:** tournament victory → explore Lower Meadows → detour → earn/open South Bridge.
**Harness:** Gate F `S04` (tournament) and `S05` (Lower Meadows → Pond → detour → South
Bridge) played through `tools/gate_f/operator_harness.gd`, logic lane, headless, plus a
capture lane (`G2C`) whose stands are taken from the played route's own 2 Hz trace.
**Run directory:** `ralph/reports/GATE2-EVIDENCE-0903/run/` (telemetry and frames are
git-ignored payload; the verdicts in this file are what the tree carries).

---

## 0. Verdict

**(b) — the gate FAILS, with named, scoped follow-up work.**

The route is now genuinely playable end to end, and that is new: this is the first time
the chapter has been walked continuously from the tournament board to the far bank of the
South Bridge. But it fails Gate 2's acceptance on the bar the gate itself sets, and the
failure is not the vegetation, creature and night work that 2.2–2.7 delivered. The
specific misses are in §5, and the scoped tasks that would close them are in §7.

A qualification on the gate's own wording is in §6: as written, the acceptance asks a
blind judge to answer yes on frames that the gate's own task list can never fix, because
every named residual gap belongs to props, lighting and terrain — none of which is in any
2.2–2.7 scope. That is a real defect in the gate definition, not an excuse for the tasks,
and §6 proposes the correction. The verdict above stands **without** relying on it.

---

## 1. What was played, and what was granted

Played for real, on real input through the live InputMap: the tournament sign-up, all
three bracket rounds, the champion conversation, the walk out of the village, the whole
band 1 spine, the Pond, the Old Bram detour and its fight, the Trail Camp, the bridge
approach, the South Bridge gatekeeper fight, the gate opening and the crossing.

Granted, and recorded rather than hidden (`tools/gate_f/build_gate2_seed.gd`): the entry
state. The freshest *played* S03 exit save
(`gate-f-run-20260902T200321Z-s03fablefix11`, a real walked opening — orb floor, road
gate, Tam's tools, the practice trainer, Mira, Oskar, twenty harvest nodes, tent,
campfire, bedroll, one creature bed) ends below `tournament.json`'s entry bar, because
S03 still has failures outside this lane's scope. The seed builder levels that real
party to the entry floor through the real level arithmetic
(`creature_instance.set_level` + the real progression config) and sets the sleep/bed/feed
rung flags. That is the same allowance `tests/smoke_gate_b_continuous.gd` already makes
in CI, applied to the same beat. Everything from the sign-up onward is played.

| | at S04 start | at S04 end | at S05 end |
|---|---|---|---|
| party | 5 × L5, all rested and fed | Moss L7, 3 × Bramblebun L6–L7, Mudsnout L7 | Moss L7, Bramblebun L7/L7/L8, Mudsnout L8 |
| condition | full HP | **3 of 5 on 0 HP** | 4 of 5 on 0 HP, one on 30/142 |
| day | 2 | 2 | 3 |
| coin | 135 | 135 | 220 |

Play clock: **S04 406 s, S05 763 s, 1,169 s total (0.32 h)**. Distance walked: S04 99 m,
S05 2,261 m. Step verdicts: **S04 82 P / 1 F, S05 106 P / 1 F** (both remaining failures
are the same stale instrument threshold — see §4).

---

## 2. Dead-travel intervals (the explicit deliverable)

Computed by `tools/gate_f/dead_travel_intervals.py`, written for this task because
`chain_pacing.py` reports only the single worst gap per segment and the gate asks for the
intervals themselves. Definition matches `operator_harness.gd::_is_meaningful` and
`chain_pacing.py`: the stretch between two meaningful events (dialogue, fight start/end,
catch, gather, craft, build, rest, feed, objective change, landmark, level-up) or a POI
coming within 30 m, clocked in play seconds from the moment the player actually moved, and
counted only where the player walked ≥ 5 m through it.

**S04 (tournament): none over 60 s.** 245 marks over 406 s.

**S05 (village → Pond → detour → South Bridge): two, both marginal.**

| # | play clock | length | walked | from | to | opened by | closed by |
|---|---|---|---|---|---|---|---|
| 1 | t = 192–255 s | **63 s** | 346 m | (19, 13) `grandpas_village` | (−161, 246) `corridor` | feeding the team | POI within 28 m |
| 2 | t = 579–650 s | **71 s** | 427 m | (329, 920) `corridor` | (65, 1198) `corridor` | discovering the Trail Camp | POI within 30 m |

Both are the two long open-corridor legs — the walk south out of the village onto the
band 1 spine, and the leg from the Trail Camp to the bridge approach. Both are ~15 % over
the gate's "~60 s" bar rather than multiples of it, both end on a point of interest rather
than on nothing, and the harness's own meter reset fires ten times across the segment, so
the route between them is populated. **My classification: intentional breathing room, at
the top of its acceptable range** — the second one is the weaker of the two, because it is
the approach to the chapter's first physical gate and is the stretch most likely to read as
long on a controller. Phase-B classification of an interval is Fable's call under the
protocol, and this is that call.

No interval over 75 s exists anywhere on the route. **This clause of the acceptance
passes.**

---

## 3. Perf proxy

`tools/perf_render_stats.gd` at `band1_open`, xvfb + opengl3 (Compatibility), llvmpipe,
1280×720, the historical 240/180/30 frame series so the number stays comparable:

| | draw calls | primitives | objects |
|---|---|---|---|
| **measured, this run** | **6,891** | **10,788,459** | 5,922 |
| GRASS-CULL-0903 (the number being confirmed) | 6,897 | 10,803,803 | — |
| provisional budget | ≤ 7,500 | ≤ 12.0 M | — |

**Holds, and confirms GRASS-CULL's figure to within noise** (−6 draws, −15 k primitives).
`scatter_lod_ranges=false`. **This clause of the acceptance passes**, with the standing
caveat that no container can measure the Ally's frame rate and the owner's hardware check
remains open.

---

## 4. Defects found by playing the route

Four blockers stood between "the tasks landed" and "the route can be played". None was
visible from any test that was green on `main`; every one was found by walking the route.

### 4.1 The tournament could not be signed into (harness) — FIXED

`S04.json` walked to `(20, 12)` for the marshal with `close_enough: 3.0`, a stop already
satisfied from the bracket board at `(20, 15)` without moving. Halda actually stands at
`(23.5, 11.5)` (`village_npcs.json`, whose own `_why_here` says "5.0 m from the bracket
board"). The player therefore stood ~4.6 m away, outside interact range, and fourteen
blind `interact` presses opened no dialogue: no `dialogue` event, `tournament_entered`
never set. **This had been failing every S04 since `gate-f-run5-chain` on 2026-08-30** —
the same "walked 0.0 m to (20, 12) in 0 walking frames" line appears in that run's notes.
Fixed by reaching the thing rather than the coordinate (`move_to_entity` + `interact_with`,
which press only on a live prompt).

### 4.2 The three rounds could not be started (harness) — FIXED

TOURNAMENT-FLOW-0903 (owner playtest 2026-09-03 item 3, "you enter then you choose to
start the battle") split every round into two greetings: ring-entrance banter that sets
`*_at_ring` and starts nothing, then a second, deliberate greeting whose only line carries
the `battle:` effect. `S04.json` still drove each round with one greeting and a fixed
press count. Rewritten as greet → advance by predicate → greet again → advance, with
`fight_until_resolved` driving the round on the real action machine.

### 4.3 The tournament segment could not hand off (harness) — FIXED

The bracket board's read-out is a `DialoguePanel` and nothing closed it, so the Save-tab
steps found `narrative_modal (owner=DialoguePanel)` still holding input and the segment
ended with **no exit save at all** — invisible until 4.1 and 4.2 were fixed and a run
first got that far.

### 4.4 The route could not be walked past the Pond (harness, world exonerated) — WORKED AROUND

Walking straight at the Old Bram detour from the Pond shore, `stick_navigator.gd` freezes
the body at **(−328.7, −14.2, 505.3)** — to a centimetre, on three independent runs — for
**543 play seconds**, with locomotion enabled the whole time ("0 held"). On the first run
it never recovered: the leg spent its full 29,250-frame budget and reported "stopped
658.8 m short".

This looks exactly like a world hole, and it is not one.
`tools/gate_f/probe_pond_stranding.gd` (written for this, committed) stands the real
player body at that exact coordinate and at eight points on a 6 m ring around it, injects
a real full-deflection left stick through the live InputMap, and measures:

- **0 of 10 stands wedged**; every stand walks 12–17 m in five or more of eight bearings;
- the body rests exactly on the authored heightfield at every stand (worst delta 0.09 m),
  `on_floor`, **touching nothing but `Terrain3D`**.

A person walks out of the Pond basin at once. The harness walker sits in it. The Pond is a
real 14 m basin (its water surface is authored at −17.0 m), and the prior successful
`gate-f-leg-s05` run left it by climbing its north-east shoulder. The leg is now authored
through that shoulder (`S05-32x`, waypoint `(−280, 550)`), which is the RIG-F6 precedent —
legs checked against a route that was actually walked — and **not** a teleport past
geometry. With it, the same walk takes 23 s instead of 543.

**This one is not closed.** The workaround gets the evidence run through; the walker
defect is real and is scoped as a follow-up in §7.

### 4.5 Neither fight would start (game-adjacent, found only by playing) — FIXED

With a **fully healthy five-creature party** — nobody fainted, 38–113 HP each, all fed —
both fights on the route refused to begin. Old Bram at (195, 905) and the South Bridge
gatekeeper at (14, 1314) each answered with `no_usable_ally()`'s line, *"Your creature
can't fight like this… a bed will do it, or something to eat"* / *"Come find me again once
you've got something to send out."* `combat_running=false`, and **`south_bridge_open` was
never set — the chapter's own physical gate could not be earned.**

Cause: `encounter_director.gd::can_challenge()` requires
`_ally_body != null and is_instance_valid(_ally_body)`. `S05-09a` deploys the active
creature immediately after the load, and at that moment the active creature is Moss,
brought out of the tournament final on **0 / 142.8 HP**. A fainted creature cannot be sent
out, so no ally body was ever created; reviving Moss afterwards restores the creature but
nothing re-deploys it. One `creature_recall` press after the revives fixes it.

This is filed as harness-fixed, but it carries a real design question for the owner, in
§7: the state that produced it is the ordinary post-tournament state, and the game's own
refusal line points the player at a bed or food rather than at the thing that was actually
wrong.

### 4.6 Post-tournament recovery, per the owner instruction — ADDED

Owner instruction, 2026-09-03: *"give revives after the tournament."* Measured: the
tournament's three rounds leave **three of five creatures on 0 HP**, a fourth on 38/120,
and the satchel holding **ten Revives and five potions the whole time**. Nothing in the
chapter's script ever picks the team up, so the Lower Meadows leg was being played on a
broken team carrying the cure in its pocket. `S05-11r*` now spends three Revives through
the production Satchel menu, by item identity, exactly as `S03.json`'s own nine recovery
blocks do — asserted live by the satchel dropping 10 → 7, so a press sequence that looked
right but spent nothing fails there rather than at the bridge.

### 4.7 Stale instrument thresholds (both remaining step failures)

S04 and S05 each fail exactly one step, and it is the same one:
`route_rows_at_least` (Section C.2's 2 Hz trace-length check) wanting 1,200 rows of S04
(690 written, for a 406 s segment) and 3,000 rows of S05 (1,349 written, for a 763 s
segment). At 2 Hz those thresholds describe a 600 s and a 1,500 s segment. S05's was
written when the segment took far longer — the Pond stall alone was 543 s of it. The trace
ran correctly throughout both segments; the thresholds describe the old durations. Scoped
in §7 as a one-line correction, not carried as a defect against the game.

---

## 5. The evidence template

**Player purpose.** Win the village tournament, then take the team south to the first
physical gate on the chapter's spine. The visible challenge being prepared for is Team
Tether holding the South Bridge — the tracked objective reads "Reach South Bridge — Team
Tether holds the crossing," and it is the gatekeeper's own fight that yields the key. The
player is never told a level requirement, which is what `GAME_VISION.md` §Lower Meadows
asks for.

**Team progression.** Entered the tournament as five level-5 creatures, all rested and
fed. Left it as L7/L6/L7/L6/L7 with **eight level-ups across the three rounds** and three
of five on 0 HP. Crossed the South Bridge as L7/L7/L7/L8/L8. A real roster decision was
in play at both fights — `combat_switch` fired during the Bram fight and again at the
bridge — but **no catch and no roster replacement occurred on this route**, so the
five-creature pressure the gate's own 2.5 acceptance asks for ("at least one roster
decision in play") is present only as mid-fight rotation, not as a keep-or-release choice.

**World interaction.** Four fights (Old Bram's two creatures, the South Bridge grunt's
two), five resource stops, three landmark discoveries (Trail Camp twice, plus the
crossing), two objective transitions, one optional detour taken and won, one care action
(the Revive block), one build. Ten harness POI-proximity resets across the 2.26 km walk,
i.e. the route passes within 30 m of something worth looking at roughly every 220 m.

**Empty travel.** Two intervals over 60 s (63 s and 71 s), both classified intentional
breathing room at the top of their range. See §2. Nothing over 75 s.

**Reliability.** No freezes, no input loss, no save/load failures, no bad collision on the
played route (the Pond stall is the harness walker, disproved as a world defect by the
committed probe). Both segments wrote and reloaded their exit saves through the production
Save tab. Four blockers were fixed to get here and all four were in the harness or the
handoff, not in shipped game code — but **three of them had been silently failing since
2026-08-30**, which is itself a finding about how much of this route had never been walked.

**Presentation.** Deferred to the blind judge — see §8. The route's own composition is the
question the gate turns on and it is not mine to answer.

**Decision.** **FAIL**, on presentation and on the roster-pressure clause; PASS on
dead travel, on perf, and on reliability of the played path.

---

## 6. The gate's acceptance bar is partly mis-specified

Recorded because 2.8 was explicitly given the authority to say so, and because leaving it
unsaid would make the next lane repeat this.

Gate 2's acceptance asks for "Bar A yes; Bar B 'trying to be the same kind of game' on
composition and density, with remaining gaps named as art-not-in-build," and its task list
is 2.2 mid-layer vegetation, 2.3 tree silhouettes, 2.4 creature legibility, 2.5 ecology
and trainers, 2.6 points of interest, 2.7 night legibility. Every blind judge run against
that task list — MID-LAYER's, TREE-SILHOUETTE's, and TREE-SILHOUETTE's own after-fix pass
— has answered **no / no**, and each has named the same residual causes: props and set
dressing, the disconnected fence segments, signposts, the mill's missing windmill sails,
flat water shading, lighting and global illumination, and terrain form (the smooth
primitive dome hill).

**Not one of those is inside any of 2.2–2.7's scope.** The gate can therefore complete
every task it names and still be unable to move the verdict it is graded on. That is a
mis-specified bar, not a failure of the tasks.

**Proposed correction**, for the coordinator to accept or reject:

> Gate 2's blind-judge clause should be split. The half the vegetation, creature and night
> tasks *can* move — silhouette variety, mid-layer presence, scatter regularity, creature
> separation from ground, night midground legibility — is judged against those tasks and
> is where 2.2–2.7 are accountable. The half that needs props, lighting, water and terrain
> work is named as its own tasks with their own gate, and Bar A / Bar B are answered
> **after** those land, not before. A gate whose acceptance no task in it can satisfy will
> always read as a failure of the people who did the work.

This does not change this run's verdict: §5 fails on grounds inside the gate's reach.

---

## 7. Scoped follow-up tasks (ROADMAP form)

| # | Task | Tier | Owns | Evidence |
|---|---|---|---|---|
| 2.9 | **The walker cannot leave the Pond basin.** `stick_navigator.gd` freezes a real body at (−328.7, −14.2, 505.3) for 543 s with locomotion enabled, driving straight at a target across the basin's shoulder; `probe_pond_stranding.gd` proves the world is passable there (0/10 stands wedged, 12–17 m per push). Root-cause the walker's slope/detour behaviour on a long uphill bearing. Do **not** fix it by teleporting past geometry, and do not remove `S05-32x` until it is fixed. | Sonnet | `tests/helpers/stick_navigator.gd`, `tools/gate_f/probe_pond_stranding.gd` | the probe's ring passes unchanged, and S05 with `S05-32x` removed reaches Old Bram inside its budget |
| 2.10 | **Post-tournament recovery is not a designed beat.** The tournament reliably leaves 3 of 5 creatures on 0 HP; the game offers no recovery between the arena and the South Bridge gatekeeper, and its own refusal line ("a bed will do it, or something to eat") misdescribes the actual block when the real cause is an undeployed ally. Decide whether the champion beat restores the team, whether Halda/Mira sell or hand over recovery, or whether the Trail Camp becomes the authored recovery stop — then make the refusal line name the real reason. | **Fable contract, Sonnet implements** | `data/dialogue/bands/band1_lower_meadows.json`, `scripts/world/tournament.gd`, `scripts/combat/encounter_director.gd` (`no_usable_ally` messaging only) | a played route from tournament victory to the bridge with no menu recovery block reaches a startable fight |
| 2.11 | **Re-deploying a revived creature.** A creature revived from the Satchel is not sent back out, so `can_challenge()` stays false with a healthy party. Confirm whether the shipped game re-deploys on revive; if it does not, that is a real player-facing trap, not a harness one. | Sonnet | `scripts/creatures/`, `scripts/combat/encounter_director.gd`, `tab_backpack.gd` | a probe that faints the active creature, revives it through the real menu, and gets a startable trainer fight without pressing recall |
| 2.12 | **One roster decision on the Band 1 route.** Gate 2.5's own acceptance asks for a roster decision in play; the played route produces mid-fight rotation but no catch and no keep-or-release moment between the tournament and the bridge. Site the "temptation" creature so the direct route actually meets it. | Sonnet from a Fable contract | `data/config/bands/band1_lower_meadows/spawns.json` | the evidence template records a catch or a considered refusal on the direct route |
| 2.13 | **Props, fence, signposts, water and terrain form** — the residual half of the blind-judge gap, per §6. Connect or remove the orphan fence segments at the bridge approach; give the mill visible sails or stop calling it a mill; signposts as set dressing; the smooth dome hill at the village approach; water shading. | Sonnet slices from a Fable composition contract | `data/config/village.json`, `building_prefabs.json`, `terrain_playground.json`, water material | blind judge names each addressed item as improved, on the same stands |
| 2.14 | **Stale trace-length thresholds.** `S04-61` wants 1,200 route rows of a 406 s segment and `S05-61` 3,000 of a 763 s one; at 2 Hz those describe durations neither segment has any more. Re-derive both from the segments' real play clocks. | Haiku | `tools/gate_f/segments/S04.json`, `S05.json` | both segments green with the trace still asserted |

---

## 8. Blind judge

See `JUDGE.md` beside this file: a code-blind pass over 16 frames taken from the played
route — the gameplay camera, HUD on, at positions, headings and clock hours read out of
the run's own 2 Hz trace, not posed at ideal stands
(`tools/gate_f/derive_gate2_route_captures.py`, `run/G2C.json`).
