# Backlog

**Rewritten from scratch, 2026-09-01, on owner directive: "all these backlogs
are wrong... the Ralph ones should be gone. they're not relevant anymore."**
**Reordered 2026-09-02 after a fresh owner playtest reopened three same-day
"landed" fixes and added new findings.**

The previous `BACKLOG.md` (4,069 lines back to 2026-08-15) and `BLOCKED.md`
(1,228 lines of parked decisions) are deleted, not archived elsewhere — their
substance either shipped, was superseded, or wasn't worth carrying forward.
`ralph/DONE.md` still holds the shipped-work archive if a specific old item's
history is ever needed; git history holds the rest.

**What belongs in this file:** the most recent owner playtests, Gate F's
current state, and the small number of visual-review items an independent
check actually confirmed matter — not a re-derivation of the 168-item visual
census, which stays a historical report
(`ralph/reports/audit/VISUAL-CENSUS-2026-08-31.md`) rather than a backlog.

---

## 0. Coordinator session, 2026-09-02 afternoon — read this first

A backlog/Gate-F coordinator picked up from `ralph/COORDINATOR_HANDOVER_2026-09-02.md`
at 11:50 UTC and dispatched six lanes. This section is the record of what landed,
what was decided, and what is still open. A separate visual coordinator ran the
Visual Parity program in parallel; its PR #20 merged at `b03cdb94`.

### Landed on `main` (each proven with `git merge-base --is-ancestor`, not a CI badge)

| commit | what |
|---|---|
| `e97baa30` | Re-bake the playground scatter + a dedicated `verify-scatter-bake-freshness` CI job |
| `c98998fa` | Rest cycle proven end to end + a rest-progress indicator (09-02 findings 15 and 7) |
| `8bf4f0bd` | Interact reliability: real-input **evidence only** — the game-breaker is NOT closed |
| `0f1b2661` | Training guidance legible on real handheld frames (09-01 findings 7 and 12) |

### Three ways CI reported green over a real failure, all confirmed today

This is the single most valuable thing this session learned, and all three are
still live traps for the next coordinator:

1. **Docs-only commits hide a red one.** `main` sat red on the stale-bake test
   while the two commits after it were documentation, so every code job skipped
   and the badge read `success`. Check job-by-job on the last commit that
   actually touched code.
2. **`[skip ci]` on WIP + the `changes` job.** A branch whose final commit is a
   report gets judged documentation-only, skipping every code job, while the
   earlier `[skip ci]` commits carried the real production code. Seen on two
   branches: an ~80-second `success` is twelve skipped jobs.
3. **`RETRIES: 3` is a bug-hider.** `smoke_traversal.gd` failed on attempt 1 of
   four separate runs today — identical coordinates to the centimetre, on both
   sides of the VP merge — and the retry loop rescued it every time. A retry that
   turns 0-for-1 into a green tick is not a pass.

### Findings worth carrying forward

- **The scatter bake goes stale silently, and it is worse than the owner's own
  report.** Measured 492.6s to first settled frame on `main` (the owner's
  original "takes forever to load" was 302s), fixed to 70.3s. Root cause is
  unchanged from `OWNER-0902-LOAD-TIME`: nothing re-bakes when vegetation/grass
  config changes. `e97baa30` adds a named CI guard for the *playground* bake —
  but **`data/terrain/playground` has no freshness check at all**, and
  `terrain_playground.json`'s `routes` moved 2026-09-02 with no re-bake since.
  Same shape, still open.
- **The owner may be playtesting stale release builds.** Proven for the sleep
  item: the handover recording "player sleep was impossible still" was pushed at
  10:29:48 UTC, seven minutes *before* camp-split's release build finished at
  10:36:55, and no release fired between 05:47:38 and 10:36:55. So the Bedroll
  did not exist in any build he could have played. `ralph/conventions.md` already
  warns a Ralph ship does not reliably publish a Windows build — this is that
  warning coming true, and it means some "still broken" reports may be against
  code that was already fixed. Worth its own process fix.
- **The Ralph sweep workflow failed at 13:27** (run 33635811838 on `38147fca`).
  The VP program reached `main` via a pull request instead. The sweep is the
  documented path to `main`, so it should not stay broken quietly.
- **A test that exists but does not test the thing.** `_probe_camp_split.gd`
  proved the bedroll heals the *trainer* and never once assigned a creature to
  the creature bed — the actual subject of the owner's complaint. Separately,
  `smoke_gate_b_continuous.gd`, the only automated gather → build camp → sleep
  path, had been failing at its first village check since Mira's gifts moved off
  Tam, so it never reached the sleep segment at all. Both now fixed; the pattern
  is worth suspecting elsewhere.

### Decisions

- **Grass density: keep 75,000 tufts / 4 blades / 3 segments. No change.**
  The owner noticed the field had thinned (`5b2ce125` cut every lever ~5x, 1.8M
  blades → 300k, staged with `enabled: false`; `OWNER-0902-GRASS-ON` then flipped
  the flag onto the thinned numbers — so the switch was approved, the thinning
  rode along). A rendered ladder was put to two independent judges, one blind to
  which frame was which config. Both picked the shipped density: the 150k step is
  denser only within ~5m, marginal at mid-distance, nil at the horizon, and
  invisible at thumbnail scale.
  **The more useful finding: neither step reads as the key art's meadow, and the
  gap is blade SHAPE, not count.** The grass draws as isolated 1–2px spikes on a
  blurry ground — "hair on a lawn" — where `docs/reference/moong-01-mounted-in-tall-grass.jpg`
  shows overlapping blades with mass, varied height and a dark root zone. The
  recommended change is a **clump card** (3–5 blades per instance, wider base,
  root-to-tip gradient, ±30% height variation) at the *current* instance count,
  so coverage rises without geometry cost. Put to the owner; not yet decided.
  `grass_field.gd` is VP-owned since PR #20, so this is likely their work.

### Still open

- **Interact reliability (09-01 item 3) — the owner's own game-breaker.** Does
  not reproduce in-container: 0 misses / 324 real-input attempts across five
  situations including a simulated frame hitch. But the probe cannot run on the
  ROG Ally, which is where he hit it. **Needs an owner hardware pass.** Same
  bucket as the ~10 FPS lag item, which is equally unclosable from here.
- **Player sleep (09-01 item 4).** Both paths verified working under real
  interact input — Grandpa's loft bed ("Sleep") and the placed Bedroll ("Rest
  until morning"). The Bedroll provably did not exist in the build the owner
  tested. **Unresolved: whether he ever tried Grandpa's loft bed**, which landed
  09-01 and should have been present. Asked; awaiting his answer.
- **Small creatures in grass (09-01).** Fix sent back, twice-reviewed. Density is
  not the cause; the causes are value/hue camouflage, silhouettes broken by
  creatures spawning *inside* flowering shrubs, and no ground contact shadow.
- **`smoke_traversal.gd` breadcrumb/teleport race.** The test teleports the player,
  no breadcrumb is dropped (`_drop_breadcrumb` returns early when not
  `is_on_floor()`), the entombment failsafe rewinds to a 6.3km-stale breadcrumb,
  and the test scores that as walking around a locked gate. Harness cascade,
  impossible for a real player. In flight on
  `ralph/TRAVERSAL-BREADCRUMB-TELEPORT-RACE`.
- **Bram-exit navigation defect.** Leaving Bram's shop, `_exit_through()` walks a
  straight line from wherever the movement probe left the player, clipping the
  shop furniture. Partially fixed, still failing, needs its own session.
- **MAIN STORY objective label truncates at 1280x800** — "Train with your team
  before the …". The hint card carrying the full "how" is timed (~10s, once per
  rung change), so a player who misses it sees a cut sentence until they open the
  quest log. Small, real, found while closing train-clarity.

---

## 1. Owner playtest, 2026-09-02 — the current priority

`ralph/OWNER_PLAYTEST_2026-09-02.md` is the full verbatim record. Real,
current, and — per `CLAUDE.md`'s precedence rules — outranks everything else
in this file. Not yet triaged into fix sessions.

**Three same-day "landed" fixes from the 09-01 playtest are now confirmed
still broken by direct play** — treat these as the standing lesson that
"landed" and "confirmed" are different states, not as three isolated misses:

| finding | landed as | now |
|---|---|---|
| Village gate on every exit | `OWNER-0901-VILLAGE-GATE-ROADS-V2` (`5b934766`) | **landed for real, third attempt** — see below |
| Village population too high | `OWNER-0901-VILLAGE-POPULATION` | **reopened** |
| Day/night cycle | `OWNER-0901-DAYNIGHT-CYCLE` | **investigated, not reproducible** — see below |

**New findings, roughly by severity:**

- **Day/night cycle — investigated, real-execution evidence, does not reproduce on `main`.** `ralph/OWNER-0902-DAYNIGHT-REGRESSION` built and ran three independent real-engine reproductions (not a code read — this project has been burned by that before): synthetic-delta drive, real-frame drive at real wall-clock speed with a shortened day length, and real-frame drive through the actual rest-completion path. All three PASS — day advances correctly across many boundaries, night genuinely bottoms at the authored dark value (not stuck at dusk), and a real rest doesn't desync the clock. Landed (probes only, no production code changed). If the owner hits this again, the most useful next report is which specific action immediately preceded the day getting stuck (after closing a menu, after combat, after a failed camp placement) — that's exactly what a headless run can't synthesize.
- **"Creatures never get out of bed" is the tent/campfire bug, not the day/night bug.** Same investigation traced it: a resting creature only wakes via a real completed rest; if the camp/bed build is failing (item 10 below), rest never completes and the creature never appears rested, regardless of what day it is. One root cause, not two.
- **Catching — landed.** `ralph/OWNER-0902-CATCH-SLOWMO` (`c789bb57`): the creature being aimed at now moves at 35% speed while catch/aim is open, scoped to that one creature (not a global slow-mo). Verified by measuring actual distance covered with aim open vs. closed.
- **Village population — landed.** `ralph/OWNER-0902-VILLAGE-POPULATION-REGRESSION` (`34bb6e3f`): the 09-01 fix only repositioned NPCs within the same boundary (15 always-present civilians before and after, proven by a point-in-polygon count) — this pass actually cut two genuine duplicates (Nessa/Wilhelm, Fenn/Oskar), 15 → 13.
- **Village layout — partially landed.** Same merge: the Grandpa's-house path endpoint, which sat a metre inside the house's own east wall (a kit rebuild widened the house and nobody re-derived the path), is fixed; Mira's shop got an exterior sign so a player knows a merchant is behind that door before entering.
- **Village gate on every exit — landed, third attempt, root cause finally correct.** `ralph/OWNER-0902-VILLAGE-GATE-REGRESSION`. Every road that actually crosses the boundary already had a gate — that was never the bug. The real gap: the fence is built as independent straight panels, and where two meet at one of the outline's 22 polygon corners, a panel's flat perpendicular end never sweeps the wedge to the next edge's angle — nothing before this fix built collision at a vertex or ever tested one. (The prior "fixed" landing's own escape probe sampled 8 of ~45 panels by index and never checked a corner, despite claiming a full ring sweep — that's the structural reason it looked green and still failed under real play.) Fixed in three measured rounds — a corner guard post at every vertex, widened after an exhaustive re-test caught one corner still escaping by ~0.3m, then given extra height after that same corner turned out to be a character-controller edge/step interaction, not a lateral gap. Final exhaustive run: 47/47 panels, 22/22 corners, both gates, all 16 bearings, all 7 jump timings — zero escapes anywhere.
- **"Characters read too small" — landed as a finding, needs an owner call.** `ralph/OWNER-0902-VILLAGE-SCALE-VS-TRAINER` — the second explanation (villagers vs. bigger creatures) was wrong and the owner rejected it directly. This third pass built a real capture tool and measured actual rendered pixel heights under three controlled camera setups (coordinator independently re-viewed all three rendered frames, not just the numbers). **Verdict: no code/config bug** — at equal camera distance a villager's on-screen height matches its declared `art.json` height to ~1%. The real cause is the trailing third-person camera: standing where a player actually stands to face and talk to a villager puts them measurably farther from the camera than the player's own body, which alone shrinks them to ~73% of the trainer's on-screen height — reproduced and visually confirmed, not just measured. This is a camera-framing design question (should a close-approach/dialogue camera close that depth gap?), correctly left unfixed for an owner decision rather than guessed at a third time. Also reconfirms the still-open, independently-flagged question: are villager rigs meant to read as adults or youths, since they visibly read stockier/more head-heavy even at a matched height.
- **Load time — landed.** `ralph/OWNER-0902-LOAD-TIME`: root cause was a stale scatter bake — `VISUAL-FLOWER-SCALE` edited `vegetation.json` on 09-01 after the committed bake, so every New Game/load silently fell back to recomputing all 812,433 scatter placements live (256.6s of a 302.5s world stand-up) instead of reading the disk cache. Re-baked; world stand-up now 47.3s, matching the known GF-B-001 baseline. No landing-pipeline step re-bakes automatically when vegetation/terrain config changes, so this can recur — flagged, not fixed, out of this lane's scope.
- **Grass — landed, on.** `ralph/OWNER-0902-GRASS-ON` flipped `grass_field.enabled` to `true` on the ~5x-cheaper config `ralph/OWNER-0902-GRASS-RENDER` already measured and prepared for exactly this, per direct owner instruction ("grass needs to be on"). No density numbers changed. Verified: 10 grass_field tests (63 assertions) green including the `enabled=true` suppression-agreement branch exercised for the first time, a full `smoke_playground` world stand-up, and a primitive count (13.6M at `band1_open`) matching the prior measurement to within run-to-run noise. Coordinator independently viewed the render before landing — real, legible grass. `PERF-ROG-GPU` still holds: no container in this project can measure real Ally GPU frame time, so this ships the owner's instruction on the best numbers available rather than waiting on hardware nothing here can test.
- **Tent/campfire/bed — landed, split for real.** `ralph/OWNER-0902-TENT-CAMPFIRE-PLACEMENT` found the placement mechanism was never broken and fixed the Build menu to say what "Camp" bundled. The owner then directly rejected leaving it bundled — "split the fucking campsite pieces for building." `ralph/OWNER-0902-CAMP-SPLIT` did that: three independently placeable buildables (tent 6 wood/4 fiber, campfire 2 wood/8 stone, bedroll 4 wood/6 fiber — same 12/8/10 total as the old bundle), reusing the existing meshes/rest-craft logic split across three real scripts rather than rewritten. `progression.json`'s `required_pieces` and every test pinning the old single `camp` id (11 files) updated to the real shape. Verified: 110 tests across 7 suites + 5 smoke tests green, plus a new real headless placement probe (arm → ghost → build_place for all three pieces) confirming the Craft and Rest prompts both work end to end.
- **UI — landed.** `ralph/OWNER-0902-HUD-TEAM-MENU`: the duplicate team-menu was a fight-end race — combat's own party strip only faded (2.5s) while leaving combat almost always changes `Party.active_index`, so the exploration strip revealed fresh on top of it, in a different position, reading from a fight-only roster that excludes fainted members (hence "doesn't show the full team"). Fixed with an instant-cut path on the real fight-just-ended edge only. The food-bar overrun was a shared-column layout collision; satiety now sits beside the health bar instead. Verified against a real headless render: full unit suite + 6 targeted HUD smoke tests, all green.
- **No rest-progress indicator** — nothing tells the player how long a resting creature has left. Not yet started.
- **Interact reliability ("works about half the time," game breaker) — investigated further, real-input evidence, does not reproduce on `main`.** `ralph/OWNER-0901-INTERACT-RELIABILITY-V3` (branch, not merged): V2 closed one real staleness window in `interaction_arbiter.gd` but its own commit message said plainly it never confirmed a root cause, and all four of its probes only ever pressed the button near one NPC's dialogue. Code reading found the one real architectural asymmetry V2 never tested: `interaction_arbiter.gd` and `dialogue_panel.gd` both read `interact` from `_physics_process()` (fixed 60Hz) by explicit design, but `playground_hud.gd::_hammer_opens_the_catalogue()` (the button that opens the build catalogue when the hammer is equipped) is read from `PlaygroundHUD._process()` — the idle/render-frame clock — the one `interact` consumer on the other clock and the strongest remaining suspect for a real cross-clock miss. `tools/probe_interact_reliability_v3.gd` measures single real `InputEventJoypadButton` presses (never `Input.action_press`, per `conventions.md`) across five real situations: NPC dialogue, world pickups (tool-free berries bushes, so a miss can't be confused with a correct wrong-tool refusal), a station panel (creature bed Rest UI), the build catalogue via the hammer (both native speed and under an artificial physics-tick stall that forces several physics ticks to batch inside one process frame, the same shape as a real frame hitch), and the post-modal-close race named directly in the task brief (close a conversation, press interact again 0-4 frames later to reopen one — exercising `sequence_director.gd::_refresh_lockout()`, which recomputes the arbiter's `_enabled` flag on the idle clock while the arbiter reads it on the physics clock, the same class of staleness V2 closed for `_winner` but never touched for `_enabled`). Two independent full runs: 0 misses / 162 attempts each (324 total). V2's own four probes (`probe_interact_flake`/`probe_interact_approach`/`probe_interact_lag`/`probe_arbiter_race`) and `smoke_post_modal_control.gd` re-run clean on this branch too (0 misses across 277 further attempts). Not covered by any of this: real hardware (ROG Ally input latency/polling), and any interact target this probe didn't construct (e.g. the road/castle gate, vendor/shop panels beyond Bram's already-covered one, farm plots). If the owner hits this again, the single most useful thing to capture is which of these five categories the miss was in and what was on screen in the second before it, since headless simulation cannot manufacture whatever condition real hardware is hitting.

---

## 2. Owner playtest, 2026-09-01 — remaining items

`ralph/OWNER_PLAYTEST_2026-09-01.md` is the full record. Of twelve dispatched
same-day fixes, three are now confirmed broken again (§1 above). A second
real-play confirmation pass, 2026-09-02 (owner, verbatim, going through this
exact list): *"the knife looks fine, player sleep was impossible still, lag
was gone but so was grass so it's not a good test. I didn't test bond but
if it's coded remove it. small creatures in grass still want fixed. they're
not super visible."*

| # | finding | landed as | now |
|---|---|---|---|
| 1 | Knife not visible in hand | `OWNER-0901-KNIFE-VISIBILITY-V2` | **confirmed fixed by real play** |
| 2 | Severe lag, ~10 FPS — **game breaker** | `OWNER-0901-PERFORMANCE-LAG-V2` | **inconclusive** — the owner's retest happened while grass was off (it's back on as of today, `OWNER-0902-GRASS-ON`), which was the original fix's own mechanism, so this run couldn't actually test whether the fix still holds. Needs a fresh real-hardware playtest with grass in its current on state before this can be called fixed or broken. |
| 3 | Interact works ~half the time — **game breaker** | `OWNER-0901-INTERACT-RELIABILITY-V2` | **investigated further, real-input evidence, does not reproduce on `main`** — see §1's new entry below |
| 4 | No way for the player to sleep | `OWNER-0901-PLAYER-SLEEP` | **confirmed still broken** — "player sleep was impossible still." Reopened; needs a real fix, not another investigation. Note: the campsite was split into three pieces the same day (`OWNER-0902-CAMP-SPLIT`) and player rest now runs through the new `bedroll` piece (`scripts/build/player_bed.gd`) — check whether this complaint is about that path specifically, or a separate player-only sleep action (distinct from creature-bed rest) that was never built at all. |
| 7 | Unclear how to train a team | `OWNER-0901-TRAIN-CLARITY` | **confirmed fixed by real headless execution, 2026-09-02 re-verification** (`ralph/OWNER-0901-TRAIN-CLARITY-V2`) — see below |
| 8 | Bond system illegible, wants discrete milestones | `OWNER-0901-BOND-MILESTONES` | **closed, confirmed implemented by code inspection** (owner: "I didn't test bond but if it's coded remove it"). `docs/decisions/D70-bond-is-a-milestone-ladder-not-a-meter.md` records the real redesign: the old 0-100 point meter is gone, replaced by an ordered five-task ladder (`data/config/bond_milestones.json`, `scripts/creatures/bond_milestones.gd`) matching the owner's own example almost verbatim ("defeat 50 wild creatures together" is milestone 1, unmodified owner input). `scripts/ui/bond_meter.gd` (the display widget, name notwithstanding) draws the milestone tier and its progress sentence, not a raw percentage — no leftover old-meter UI. `tests/test_bond.gd` pins the ladder's sequential behavior. Real, not a stub. |
| 9 | Creatures don't lie in bed except galecrest | `OWNER-0901-CREATURE-BED-POSE` (bed roster-fit landed separately, §3) | not re-covered by this pass |
| 12 | Tournament `min_level` 6→5, Halda's guidance made concrete | `OWNER-0901-TOURNAMENT-LEVEL5` | **confirmed fixed by real headless execution, 2026-09-02 re-verification** (`ralph/OWNER-0901-TRAIN-CLARITY-V2`) — see below |
| — | Small creatures disappear into grass | `OWNER-0901-CREATURE-GRASS-VISIBILITY` | **confirmed still broken, and now live again** — "small creatures in grass still want fixed. they're not super visible." Now more urgent than when this was filed: grass is back on as of today (`OWNER-0902-GRASS-ON`), so this is an active, current defect, not a dormant one. Needs a real fix. |

**Items 7 and 12 re-verified 2026-09-02, real execution not a code read.** A
local Godot 4.7-stable headless binary (the same version CI pins) was
downloaded and used to actually import and run this checkout, because no
Godot binary exists by default in this container and a code read alone has
burned this project before (village gate, thrice). Findings:

- `data/config/tournament.json`'s `min_level` is `5`, and nothing else
  overrides it: `scripts/world/tournament.gd::required_level()`'s `6` is
  only a never-triggered missing-config fallback. `tests/test_tournament.gd`
  (85 tests, 1070 assertions, all green on this run) exercises the real
  threshold dynamically via `TOURNAMENT.required_level()`, including
  `test_a_party_at_the_authored_level_is_trained` and
  `test_one_level_below_the_threshold_is_not_trained` — a level-4 party
  fails, a level-5 party passes.
- Halda's `tournament_halda_train` line (`data/dialogue/bands/band1_lower_meadows.json`)
  already reads: *"Feed them. Rest them — a Creature Bed or your own
  bedroll, either does it. Get them to level five, then we'll talk."* — the
  vague-"train" complaint item 12 named is gone from her actual voice line,
  not just from a comment.
- `tests/smoke_tournament_bracket.gd` (a real simulated playthrough, run
  directly, not through a code read) drove an actual party from too-small
  through every one of Halda's branches — `tournament_halda_closed` →
  `tournament_halda_train` → `tournament_halda_condition` → fed/rested →
  `tournament_halda_signup` → all three rounds **actually fought** (real
  combat simulation, not stubbed) → champion → saddle pattern granted.
  Output: `smoke: OK — the tournament can be entered, lost, retried, fought
  through all three rounds and won, once.` This is the closest thing to
  "playing it" available without an interactive session, and it exercises
  the real game code, not a mock.
- Item 7's own root cause was broader than item 12's dialogue fix alone:
  `data/progression/objectives.json`'s `tournament_train_team` rung already
  carries the concrete `how` text (*"Villagers who offer a fight are the
  training -- Bryn at the practice ring first. Wins are levels. Get your
  whole team to level 5."*, landed same-day as item 12's fix, `e202559b`)
  — but that text lives in `quest_log.gd::tracked_hint()`, which for months
  had "been written and tested... with nothing rendering it" (the code's
  own words, `scripts/ui/playground_hud.gd`'s `_build_objective_hint_card`
  comment). **That gap is already closed too** — `HIST-036` wired a real
  timed HUD card that draws `tracked_hint()` on screen whenever the tracked
  objective changes. Ran `tests/smoke_objective_hint_card.gd` for real
  (not read): PASS, "the objective hint reaches the screen and its card
  fits its band" — measured at 1920×1080, all 27 authored hints (including
  this one) fit their card, and `Game.objective_hint reaches the card's own
  label` is confirmed live-wired, not dead data.
- Bryn (the practice-fight trainer the hint names) is real and placed
  (`data/config/bands/band1_lower_meadows/trainers.json`), fields a
  level-2 team, and his own challenge line frames the fight as training
  ("no idea what it can do yet... beat them both and you'll know something
  you can't be told") — so the guidance's claim is mechanically true, not
  just narratively plausible.
- Bond milestones (item 8, closed separately) do not carry any of this
  load — `docs/decisions/D70` confirms it is a companionship/attachment
  ladder (battles fought together, landmarks, distance, rest, feeding
  *together*), unrelated to a creature's own combat level. It neither
  duplicates nor substitutes for the training guidance above.

No code change was needed for either item — both were already correctly
implemented, and item 7's landing (`e202559b`) undersold its own fix by
citing only the objectives-data text without knowing at the time that the
HUD surface for it had also already shipped (`HIST-036`, an unrelated
lane). What was missing until now was real-execution proof, which this
pass supplies. Branch: `ralph/OWNER-0901-TRAIN-CLARITY-V2`.

**The village-gate lesson stands as recorded history:** the first dispatch on
that finding claimed "nothing to fix" from a config read with no pushed
branch or run probe — wrong, as the owner found by playing, and as §1 above
now shows again from a second angle. A "nothing to fix" conclusion needs
evidence behind it every time, not just once.

---

## 3. Gate F — the chapter's own measure of done

The standing protocol chain (`ralph/GATE_F_PROTOCOL.md` →
`ralph/GATE_F_MASTER_PROTOCOL.md` → `ralph/GATE_F_INSTRUMENTATION_REQUEST.md`)
governs how a full capstone run works. Current state:

- **CAP-1/CAP-2** — confirmed fixed across independent fresh runs. Do not
  reopen without new evidence.
- **S03's catch-retry harness loop** — root-caused and fixed across several
  real sub-bugs (wait-budget, a team-cap lockout, a revive/cycle ordering
  bug), each found by actually re-running the segment, not guessed. Once
  real aiming replaced a harness-only `force_aim` shortcut, the segment hit
  a real revive-economy wall (2 starting Revives insufficient to build a
  full five-creature team with no mid-chapter restock) — **landed on `main`**
  (`1c152d93`): the grant is raised 2 → 10, confirmed working by real
  execution (attempt 9, 406P/32F/6SKIP, revive wall gone). **Process note:**
  the lane that found this labelled its own change "owner directive" without
  one having been given — caught before landing; the real decision went to
  the owner directly and is recorded accurately in `D40`'s amendment.
  Two more real, separate findings remain open in the same segment (catch-rate
  variance not landing enough throws, and a pre-existing move-to-entity/engage
  targeting gap) — not blocking, but not yet fixed either. In progress: full
  S03 convergence, then S04 through S10 one segment at a time — run, fix every
  real failure, reconverge that segment alone, advance, never skip ahead. Only
  after all ten pass individually does one continuous S01-S10 run happen. This
  is a many-hour, unattended effort; frequent "still running" status with real
  new commits is expected, not a problem.
- Bands 1-5, the tournament semi-final, the finale, and real pacing are all
  still unverified by this project's own evidence process.

---

## 4. Visual — six items an independent check confirmed matter

The 2026-08-31 whole-game visual census produced 168 numbered findings. An
Opus review against the actual images found most of the list wasn't worth
acting on. **The census stays a historical report, not a backlog.** Six items
were confirmed real:

| item | status |
|---|---|
| Boss nameplate shown for a creature not on screen | **landed** |
| Combat camera never frames both combatants readably | **landed** |
| Controller glyphs — corrected: the live game already renders them correctly, the census's evidence was a capture-tool artifact | **closed, no game defect** |
| Creature roster generally too small next to the player | **landed** — see `ralph/OWNER_DIRECTIVES_2026-09-01.md` |
| Creature bed too small for the (now bigger) roster | **landed** — bed grown, real lying poses for terrapup/trailpup; bramblebun (broken idle animation, filed separately) and veridian (any roll worsens footprint) knowingly still imperfect |
| One world site renders almost totally black | not started |
| Signpost text is an unreadable smear | not started |

---

## Sources

- `ralph/OWNER_PLAYTEST_2026-09-02.md`, `ralph/OWNER_PLAYTEST_2026-09-01.md` — playtest records
- `ralph/OWNER_DIRECTIVES_2026-09-01.md` — same-day owner corrections (creature scale)
- `ralph/reports/gate-f-capstone-3/CAPSTONE_3_REPORT.md`, `ralph/reports/FINDING-CAPSTONE3-S03-CATCH-LOOP-STALL-2026-09-01.md`
- `ralph/reports/audit/VISUAL-CENSUS-2026-08-31.md` (historical, not a backlog)
