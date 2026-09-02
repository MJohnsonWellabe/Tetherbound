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
| 3 | Interact works ~half the time — **game breaker** | `OWNER-0901-INTERACT-RELIABILITY-V2` | not covered by this pass, still just "believed fixed" |
| 4 | No way for the player to sleep | `OWNER-0901-PLAYER-SLEEP` | **confirmed still broken** — "player sleep was impossible still." Reopened; needs a real fix, not another investigation. Note: the campsite was split into three pieces the same day (`OWNER-0902-CAMP-SPLIT`) and player rest now runs through the new `bedroll` piece (`scripts/build/player_bed.gd`) — check whether this complaint is about that path specifically, or a separate player-only sleep action (distinct from creature-bed rest) that was never built at all. |
| 7 | Unclear how to train a team | `OWNER-0901-TRAIN-CLARITY` | not covered by this pass, still just "believed fixed" |
| 8 | Bond system illegible, wants discrete milestones | `OWNER-0901-BOND-MILESTONES` | **closed, confirmed implemented by code inspection** (owner: "I didn't test bond but if it's coded remove it"). `docs/decisions/D70-bond-is-a-milestone-ladder-not-a-meter.md` records the real redesign: the old 0-100 point meter is gone, replaced by an ordered five-task ladder (`data/config/bond_milestones.json`, `scripts/creatures/bond_milestones.gd`) matching the owner's own example almost verbatim ("defeat 50 wild creatures together" is milestone 1, unmodified owner input). `scripts/ui/bond_meter.gd` (the display widget, name notwithstanding) draws the milestone tier and its progress sentence, not a raw percentage — no leftover old-meter UI. `tests/test_bond.gd` pins the ladder's sequential behavior. Real, not a stub. |
| 9 | Creatures don't lie in bed except galecrest | `OWNER-0901-CREATURE-BED-POSE` (bed roster-fit landed separately, §3) | not re-covered by this pass |
| 12 | Tournament `min_level` 6→5, Halda's guidance made concrete | `OWNER-0901-TOURNAMENT-LEVEL5` | not covered by this pass, still just "believed fixed" |
| — | Small creatures disappear into grass | `OWNER-0901-CREATURE-GRASS-VISIBILITY` | **confirmed still broken, and now live again** — "small creatures in grass still want fixed. they're not super visible." Now more urgent than when this was filed: grass is back on as of today (`OWNER-0902-GRASS-ON`), so this is an active, current defect, not a dormant one. Needs a real fix. |

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
