# CURRENT_STATE history — moved 2026-09-07

Moved verbatim from `docs/CURRENT_STATE.md` when that file was slimmed to the live
status. History only; nothing here routes current work. See `docs/CURRENT_STATE.md`.

## Stage B (multiplayer) Wave 0 — 2026-09-05, branch `claude/tetherbound-roadmap-next-jrcjs8`

Stage A closed with PR #54 (`main` `55c64aaa`, no open PRs). Stage B's plan is
`docs/specs/STAGE_B_MULTIPLAYER_EXECUTION_PLAN.md`. **Wave 0 (instruments and decisions) landed
on `main` as PR #58, merge `d72580b5`, 2026-09-06**, on CI run 34002009384 with all 19 executed
jobs green on first attempt (the run also fixed the documented `smoke_gate_e_finale`/`smoke_boss`
race: both now read the Warden's victory conversation before asking whether exploration came
back). Landed in it, each verified by Fable against the lane's claims: the assumption inventory, the net-harness contract, the state seam spec, decision
records D95–D107, the conversion map with both spikes' numbers, the ENet spike (two headless
processes, RPC median 6.9 ms, spawner and synchronizer working), the host-cost spike (four
concurrent Meadows boots in 12.85 GB; Terrain3D FULL_GAME collision +16 MB in 3 s; a
`.call()` heightfield loop is +11 ms over physics, so D96 is amended to full collision), and
the solo regression fence (62 characterization tests seen red first, `tools/run_all_smokes.sh`,
the `verify-solo-regression` CI job), and the net harness (lane 0.F, Opus-reviewed, thirteen
findings fixed; `verify-multiplayer-shard` runs two real Meadows peers on every PR). Wave 1's
state split (lane 1.B, Opus) is in flight in a worktree; its full unit suite is green (2,441
tests) and its smoke sequence is mid-run. Pre-existing and routed, not the seam's:
`smoke_progression_feedback` fails identically on the Wave 0 base and is in no CI shard.

**`main` shipped with Cloudreach unbuildable, and CI could not see it.** `cloudreach_world.gd`
iterated `art.json`'s `times` with a typed `for preset: Dictionary` loop; N13's
`_comment_night_end_n13` string aborted `_ready()` before any region, route or the chapter node
existed, and the player fell through an empty scene. No Cloudreach smoke ran in CI. Fixed on
the branch (`merge_sky_profile_into_times`, `tests/test_cloudreach_world_presets.gd` red 2/4 on
the old loop), `smoke_cloudreach_arrival_walk` passes (exit 0) and now runs in the regions shard.
Every Cloudreach "continuous acceptance" claim below predates N13 and was true when written;
none of it could have been reproduced on `main` between N13's landing and this fix.
