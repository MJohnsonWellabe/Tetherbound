# Round 4 — environment correction, reference bar still open

Starting verdict: `../round3/JUDGE-ASTRA.md`, A No / B No. This pass does not
self-accept reference parity. Main `2cd711eb1` was integrated and pushed as
`1f1f23652` before this visual checkpoint.

## Physical presentation changes

- Distant flat-crowned `_mesa` ranges and noncolliding region spurs/satellites are
  replaced by overlapping installed Rock_Medium-family geometry with varied
  heights. Gameplay route polylines, gates, floors and existing collision recipes
  are unchanged.
- Warm cliff material removes doubled pale texture gain and repeated colour bands.
  A shared turf shader now joins crowns, trail boundaries and worn yards at the
  same world-space scale. Ground-cover clusters share world-space phases rather
  than visibly changing at every patch boundary. Existing rooted cliff shelves
  receive physical grass/flower cover.
- Upper watch moves from the front of its houses to rear-east and is shorter/wider;
  terrace edges, watch apron and planted domestic pockets form a connected precinct.
  Thin installed tile roofs render their undersides as well as their top shells.
- Shrine stair/retaining wings connect to localized planting and rest edges.
  Stronghold approach gains continuous retaining/work edges outside the open lane.
- The existing 36 m arena deck, relay coordinates, lee pockets and hazard geometry
  are unchanged. Decorative perimeter bays and service clusters beyond the fight
  deck define its occupied edge; finer, worn paving separates centre and perimeter
  without substituting for actual timed telegraphs.

## Evidence status

GDScript check-only passed, exit 0. First rendered launch failed before world
assembly with `alloc_static mem=null` / `alloc_exact mem_new=null`, followed by
signal 11 inside Game's initial map setup. Three headless tests were active;
resource contention is a hypothesis, not a confirmed cause. `capture.log` contains
the exact crash; that failed launch produced no valid image or measurement.
The second launch completed with fewer competing readers: `capture-retry.log`,
exit 0, twelve real production frames. The first failure remains in
`capture-first-attempt.log`. No pagefile or other global machine setting changed.

Prepared evidence: original ten route views, a clear stand on the tested causeway,
two supplementary eye-level ground-connection views, real-input Fly trace/frame,
payoff production-SpringArm views and live captain/relay controller HUD. New frames
are now in `shots/` and have been inspected. `contact-sheet.png` has twelve labeled,
unretouched environment frames; preserve its original F1–F12 numbering rather
than inserting the later Fly frame into this judged sheet. Initial
`shots/performance.json` counters are genuine, but concurrent
headless tests mean its frame timings are not a quiet baseline. Across twelve
views: 579–4,416 draws and 0.848–7.486 million primitives, below the structural
ceiling. These are GTX 1060 3 GB counters, not ROG Ally evidence. Sustained
performance still waits for quiet CPU/GPU conditions.

## Fresh blind review and actual interaction captures

`JUDGE-ASTRA.md` returns **A Yes / B No**. The palette/mood now belongs to the
project's art direction, but disconnected terrain, banded ground cover and
unfinished destination structures still fail the shipping-game reference bar.
Creatures are excluded by the owner. No final visual acceptance is claimed.

The new rear-east watch intrudes into the east arrival
view and hides houses: its local `(20,0,18)` should be reconsidered as rear-west
`(-20,0,18)`. No such further edit was applied after capture, so the current sheet
matches source exactly. The original lower view still sees a large bare mound;
warmer rock does not by itself resolve geological composition. Roof framing and
the broad shrine/summit/arena foregrounds also remain review concerns.

Additional real rendered evidence:

- `fly-capture.log`: exit 0, production double-jump and input-driven flight;
  `shots/10-real-fly-silhouette.png` shows the overhead carrier/hanging player.
  This uses an explicitly unlocked start fixture, not the continuous trial.
- `payoff-capture-recall.log`: 63/63 checks, exit 0. Five production camera
  views in `payoffs/`. The companion is recalled with the real input action,
  not hidden by a capture-only mesh toggle. Corrected board coordinates and
  camera settling repair the earlier fixture-only framing failures. Quest
  preconditions are explicit; this is not an uninterrupted chapter proof.
- `live-hud.log`: 64/64 checks, exit 0, real captain rounds/relay input,
  saved reward and duplicate-payout guards. Images remain in the integration
  report's `live/` folder.
- `live-full-party.log`: 65/65 checks, exit 0, explicit near-level five-member
  fixture. Real captain XP levels all five. Its `live-full-party/` image
  exposed a genuine MomentBanner/PartyStrip overlap; HUD correction and
  recapture are a separate pending regression, not an accepted layout.

These successful runs contain no `ERROR:` or `SCRIPT ERROR` lines. The earlier
failed attempts remain on disk. The full-party HUD retest is still pending.

## Sustained local measurements and regression checks

`sustained-capture.log` completed on the same geometry with twelve frames,
exit 0 and no error lines. Other long-running Godot tests had ended before
the static samples. Windows / GTX 1060 3 GB / Compatibility / 1280×800;
three independent ten-second static samples, not ROG Ally or continuous play:

| View | Mean ms | p50 ms | p95 ms | p99 ms | Maximum ms |
| --- | ---: | ---: | ---: | ---: | ---: |
| Lower Galefoot | 10.89 | 10.91 | 11.08 | 11.38 | 12.87 |
| Final arena | 8.20 | 8.19 | 8.34 | 8.37 | 10.08 |
| Arrival | 11.70 | 12.29 | 15.18 | 15.53 | 15.81 |

The arrival tail is worse than the round-3 static range (p95 8.74–11.47 ms);
do not describe this as a universal performance improvement. Across all twelve
views: maximum 4,416 draws and 7,485,710 primitives. Scene start/assembly is
excluded from these static samples and remains a separate performance concern.
The original judged sheet is retained; the sustained run does not silently
replace the evidence on which the blind verdict was based.

`foundation.log`: production foundation OK, all six regions, twelve landmarks,
five bridges and grounded player, exit 0. `world-unit.log`: 37 tests / 1,195
assertions / zero failures across world data, environment, chapter data,
production integration and world payoffs. Both contain no error lines.

Reproduction commands (prefix with installed Godot, `--path .
--rendering-driver opengl3 --resolution 1280x800`; use distinct log files):

- `--script tools/capture_cloudreach_fly_visual.gd -- --round4`
- `--script tests/smoke_cloudreach_world_payoffs.gd -- --capture --round4`
- `--script tests/smoke_cloudreach_production_integration.gd -- --capture`
  (writes the existing production-integration `live/` folder).
- `--script tools/capture_cloudreach_production_integration.gd --
  --round4 --sustained` (overwrites the round4 route set and includes separate
  ten-second static-view measurements).
- Do not rebuild this round's judged sheet from all PNGs: the extra Fly frame
  changes its numbering. `_sheet.png` preserves the original twelve-frame sheet.
