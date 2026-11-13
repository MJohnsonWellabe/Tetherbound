# LANE-LAND-MT: Meadows and Tidewake world look

Branch `tb/land-mt` (from `tb/coord-wrapup-1113` c673d528). Goal: every row above 7 on GPU High.

## State (13 Nov)
- **Tan mountain backdrop: cause found and fixed (correctness, not flagged).**
  - `horizon_ranges.gd` copied the scene fog into the ridge on a 0.5 s poll.
  - The route tool pins the hour, waits 12 physics ticks (0.2 s) and 4 drawn frames, then shoots. On a GPU that is under 0.5 s, so a day frame taken right after a golden-hour frame (stronghold `route_day` follows warrens `vista_dusk` in one boot) could keep the tan dusk haze. Which boot got it depended on the poll phase. On CPU a drawn frame takes longer than the poll, so it never showed.
  - Fix: the fog is compared every frame and copied the frame it changes. Pin test: `test_meadows_ridge_vl.gd::test_ridge_fog_follows_the_environment_without_delay`.
  - Expected board effect: F38#24's `route_day` reads 7.73 every boot (row about 6.49), with no arm needed.
- **Built, flag-off, waiting on a CPU look:**
  - `bank.hill_shell.broken` (F38#30 Burrow Warrens hillside): relief, rock faces, base-line rocks and bushes.
  - Ridge shader `warm_haze_*` (dusk vistas: "flat tan haze swallows the mountains").

## Waiting on the GPU
None yet.

## Next
1. CPU before/after of the broken hillside; write the arm folder; send it.
2. Tidewake shore arm: one cause across F39#1, F39#15, F39#13 and F39#27 ("bare smooth sand with no layered ecology": wet-sand band, wrack line, driftwood, rock clusters, grass in groves).
3. Tidewake water: the hard navy-to-cyan depth edge and rimmed shallows discs (F39#15, F13#5, F39#16).

## Runbook
TECHNICAL §8.1. First import in this container: about 45 min.
