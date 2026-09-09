# Retained second-bed diagnostic — 2026-09-09

This was one copied-state diagnostic, not fresh continuity or acceptance evidence. `tools/diagnose_retained_second_bed.gd` passed `--check-only`, then loaded preserved day-2 state into a new isolated user directory. It validated the exact paid tent, campfire, bedroll and creature-bed records, party index 2 `rested=true`, and the single creature bed unoccupied before movement.

The diagnostic directly attempted party-index-0 assignment to creature bed 1. It walked from reconstructed save pose `(29.80001, 0.137814, -40.29507)` to the prompt target `(26.0, 1.388717, -39.3)` in frames 128–218, ending 1.362 m away inside the unchanged 1.4 m tolerance. It used no teleport, fixture mutation, sleep, or retry and exited 0.

This does not reproduce the fresh failure's direction. The fresh required leg began at the paid-bedroll side `(34.98708, -0.849575, -42.66916)` and ended after 3,600 frames at `(29.48413, 0.1243, -37.99322)`, 3.721 m short. The copied save restored a materially shorter, different approach. Its pass therefore says only that the bed prompt is reachable from the saved pose.

Artifacts: `.artifacts/opening-prefix-c3e-0909/bed2-diagnostic/engine.log` SHA-256 `797389807fa65d270538be9bd511dbc2cc9f0f12dbd02879bb34fb50f30a9abe`, `result.json` `4c00cd5643626c1170da52d48f2ef7d34e5d904cf6185ca5930cfb211eb625a9`, probe source `19248ddc202396ff18a7346fd147b6d57a6c325cb00d094cd7d2aa70ef7cbc11`. Terminal Godot census was empty.

Observer limitation: it sampled a supplemental center ray every ten frames and navigator state. It did not intercept the navigator's actual twelve `_free_space` rays, so its null hits cannot identify what the base navigator saw. The deferred sampler also printed a few records after walk arrival while assignment UI completed. Those records changed no state or movement.

## Proposed directional probe

Keep the same preserved copy and state validation. First use the same `BedInput`/`StickNavigator` controller path to walk to the actual paid bedroll prompt/stance, then immediately call the unchanged `_assign_to_bed(0)` so the required return uses `_walk_to_prompt(..., "creature bed 1")`, its 1.4 m tolerance and 3,600-frame budget. Stop after that arrival/failure.

Replace supplemental queries with a diagnostic-only `StickNavigator` subclass injected into `BedInput._nav`. Override `_free_space` and `_drops_away` by copying their current bodies exactly, preserving constants, masks, exclusions, ray order, `hit_from_inside`, and return values. Add observation only at the points where those exact queries already receive results: aggregate first-hit path/layer/distance by forward/side direction, log changes immediately and one snapshot every ten frames, record ground-hit path/height/drop verdict changes, and cap output per leg. Override `walk_to` only to open/close a leg record; call `super.walk_to` unchanged. This observes the decisions used by movement without extra physics queries. Source hashes and a mechanical diff against current navigator bodies should be recorded before parse-check. No native run should start until root reviews that equivalence diff.
