# M2 card: one fresh save from Meadows to Tidewake (tb/ev-fights): BLOCKED at the Warrens approach
US Central, Tue 13 Oct 2026. The F49 path (new order) from a new game, `TB_WORLD_SEED=15`:
`godot --headless --script tests/smoke_four_biome_continuous.gd -- --through-tidewake-entry --rechallenge-aid`

## Harness aids added (disclosed, opt-in)
- `--rechallenge-aid` (`meadows_earned_hall_segment.gd::_fight_named`, inherited by the Warden and finale segments): after an actual named-fight loss, the lost attempt is kept as a receipt. The party heals at the ordinary camp bed (outside the Hall) or by a disclosed direct restore (inside it), then re-challenges, at most 3 times. Any other failure stays a failure. The campaign result reports `rechallenge_aid`.
- `--through-tidewake-entry` (F49 journey): stops once the earned save arrives in Tidewake. A prefix pass, never F49 proof.

## Runs
| Run | Reached | Result |
|---|---|---|
| 1 (12:35–3:15 AM) | opening, team, camp, rest, tournament, **South Bridge guardian won and crossed**, Quarry | FAIL at the Warrens approach |
| 2 (3:20–5:25 AM, after a harness tolerance change, since reverted) | same | FAIL at the same point |
| seed 7 (probe) | title/opening | FAIL: the tutorial Bramblebun was not engaged (seed-specific opening; not pursued) |

- The South Bridge regression from `BRIDGE_GUARDIAN_REGRESSION.md` no longer blocks: the lateral seat is now limited to named ranks in `combat.json`.
- **Blocker: the Warrens outside-staging point is unreachable on seed 15.**
  - `outside_approach(entrance, mouth, site.apron_run_m)` puts the non-interactive staging pose at (-355.6, 2608.6). The heightfield gives 9.19 m there: the earth bank over the mouth, not the carved apron (~5.0 m).
  - Run 1 stopped 4.73 m away in plan (6.3 m in 3D) against the bank. Measuring that one check flat with a 5.5 m tolerance was tried. Run 2 then stopped 9.15 m away in plan at a different spot, so the point itself is the problem.
  - Logs: `run1_warrens_tail.txt`, `run2_warrens_tail.txt`.
- Parked after two attempts. The fix belongs to the Warrens site/route owner: either the authored apron run/markers, or `outside_approach` sampling the walkable apron instead of the heightfield. Then one run reaches the Relay, the Sigils, the Hall, the Warden and Tidewake, where `--rechallenge-aid` covers the known Field and Hald losses.

**Verdict: M2 not met.**
