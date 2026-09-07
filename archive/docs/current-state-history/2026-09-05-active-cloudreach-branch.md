# CURRENT_STATE history — moved 2026-09-07

Moved verbatim from `docs/CURRENT_STATE.md` when that file was slimmed to the live
status. History only; nothing here routes current work. See `docs/CURRENT_STATE.md`.

## Active Cloudreach branch — 2026-09-05

Owner resumed the full Cloudreach chapter goal, excluding final creature art.
Work is in `D:\Tetherbound-source` on `codex/cloudreach-cliffs`, draft PR #44.
Environment checkpoint `ca7d87113`, five-member HUD checkpoint `aaee9f064` and
merge `97de9bbf7` are pushed, preserving the earlier route fixes and reference
import sidecars. Latest integrated main is `590741fe6`; its forward merge was
documentation-only and discarded no compatible behavior from either lane.
This is **not** a merge to main or a claim of chapter completion.

Main's single progression feed/unordered bonds, pickups, portraits, companion,
VFX and difficulty updates are retained. Cloudreach keeps realm-safe pickup keys,
owned-only Fly credit, reward receipts and the five-creature limit. Import is
clean. Of 352 selected tests, three stale shrine fixtures initially failed;
their corrected chapter suite passes 8/8. Merged smokes pass HUD lifecycle 34/34,
production finale 64/64, feed lifecycle 14/14 and physical Fly 36/36. Meadows
world boot passes, retaining its known headless alpha material-null error.
Windows CRLF hashing incorrectly marked unchanged bakes stale; canonical LF
hashing now preserves both shipped bake identities (2/2 freshness guards pass)
without rebaking. Full regression completed: 2,093 tests / 3,768,872 assertions,
16 failures from the then-loaded portability/freshness checks, plus five shiny
fixtures that aborted despite nominal passes. Corrected follow-ups pass 95 tests /
41,908 assertions with no errors. No clean second full-suite pass is claimed;
the initial native-error/leak set remains disclosed in `MAIN-MERGE-REGRESSION.md`.

Continuous gameplay acceptance is closed by checkpoint `aa818b282`: one clean,
zero-Cloudreach-seed `--accelerated --live-combat` replay covered **19,040.43m /
3,795.33 simulated seconds** through four real-input battles, three actual camp
recoveries, loaner Fly, grounded upper route, captain/relays, aftermath/reward,
Waterward non-entry and the same five members across disk reload. The
uninterrupted run's sole red was a millisecond-scale live condition tick during
observation; the immediately following five-member persistence tail passes with
zero field differences after the JSON writer is explicitly closed.

The early deployed-companion cadence is also measured on a forward-only natural
route. Real recall input deploys Sparkit before arrival travel; 37 actual
Engage/resource/NPC/rest/other offers and seven matched interaction choices are
recorded across **3,135.1m / 651.75 travel seconds**, excluding dialogue,
interaction/gather waits, diagnostics and backtracking. One genuine 94.0s
causeway gap was fixed by relocating—not adding—the redundant same-region route
Good Candy to the supported midpoint. The resulting gaps are 44.5s and 48.0s;
the remaining maximum is 76.5s with none over 90s. Exact 100-candy / 75-recovery
totals, item/region matrix, persistent ids and detour balance pass, as do **24
tests / 7,477 assertions** and **215/215** production placements.

Visual acceptance remains separate and open. Round 5's twelve real environment
frames received **art direction Yes / Palworld presentation No**. Quiet static
p95 was 8.37–10.33ms on GTX 1060 at 1280×800, not Ally acceptance. Subsequent
environment/HUD correction evidence remains in its own reports and is not made a
gameplay or hardware claim here. See `ralph/reports/CLOUDREACH-HUD-0905/REPORT.md`.

Combat has been remeasured against main's 1.6 damage multiplier: 28/28 real-input
trainer-ladder wins and real wipe/rest/retry. A separate actual-world finale
probe now wins all nine rounds across three input policies, observes live wind/
arc/lee and real movement drift, and walks to all relays. Remaining party HP is
23.21–51.96%; maximum individual hit is 40.58%. No further balance tuning.
The separate balance fixture used an explicit rested summit start, while the
accepted continuous route now supplies the missing attrition/context evidence.
Root also fixed freed-body glow cleanup and empty level-up VFX surface errors;
focused VFX checks pass.
See `docs/biomes/cloudreach/CONTINUOUS_ACCEPTANCE_0905.md`,
`COMBAT_BALANCE_EVIDENCE_0905.md`, `LIVE_FINALE_EVIDENCE_0905.md`,
`SHRINE_SIGHTLINE_0905.md` and the round-5 `JUDGE-ASTRA.md`.

The older exit note and main snapshot below are dated history, not current
Cloudreach routing. Wild footprint admission/roaming/recovery passes 73 production
checks, including actual Engage at all three early sites and identity/fight/faint/
respawn guards. Two separate quiet 12-phase profiles measure each actual resident
pair at roughly 0.35–0.60ms of inclusive instrumented support work per physics
tick. This is not a scene/device pass: rendered causeway roaming reached 19.30ms
p95 / 28.10ms max, and separate zero-query headless controls stalled to 430–596ms.
The forward deployed-companion evidence observes four actual pre-Senn Engage
offers; the earlier undeployed-fixture absence is superseded.

Controlled Fly permits the authored 425m High Roost-to-aerie descent while
exhausted flight still returns to its physically verified anchor; the complete
continuous route now proves that return and all downstream gameplay. Next work
is the still-separate visual gate and device/hardware evidence. Do not merge
without the branch's normal review/CI process.

**Status:** the live status document. Replaces `ralph/BACKLOG.md`, `ralph/STATUS.md` and
the coordinator handovers (all under `archive/ralph/`). Update it when evidence changes;
do not let it accrete layers — rewrite the section.

Every claim here was verified in this session on `main` at `cf535cce` (2026-09-02
22:05 UTC) with Godot 4.7-stable headless in a clean container, unless marked
*(reported)*.
