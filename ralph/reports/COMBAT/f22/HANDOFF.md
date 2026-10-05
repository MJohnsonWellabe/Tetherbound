# F22 lane handoff (wind-down, owner 2026-10-05)

- Branch: `tb/f22`. Head is the commit that adds this file (parent `3d6bdf8e`).
- Lane: C (combat). Feature: F22 enemy patterns + anti-mash (folds F04).
- Merged in: `origin/main` e2fa5e4e (#542).
- Evidence index: `ralph/reports/COMBAT/f22/README.md`.

## Done / landed

#542 merged (e2fa5e4e) with:

- forced break (charge must start after the tell, 0.1 s grace);
- the online host-tick fix and the two-peer smoke;
- the COMBAT.md:144 C3 gate;
- the pose-race smoke fixes.

The coordinator cherry-picks `52e345d3` (gate-A opening pilot reach fix) into the post-F18 PR. `59467547` and `cdc09193` net to zero; skip both.

## Ready to land (on tb/f22, not yet on main)

Each item is its own commit.

| SHA | What | Checks |
|---|---|---|
| fe819297 | peer_runner helper renamed `_encounter_refusal_history` (subclass collision) | parse of all peer_runner subclasses; water_local_chains PASS |
| c0171ebb | forced-break smoke waits for host readiness before the early charge | f22_forced_break PASS flag off and flag on (aa7468f2 + this) |
| 211ee733 | `--move-patch` A/B lever for the band sweep (in memory) | parse |
| abec8992 | evidence: Galewisp trial A/B | — |
| 3c6fcc6b (revert of d4ff1e9c) | REVERT Galewisp `sky_rend` range trial (coordinator ruling) | A/B: changes no verdict |
| 7b280a6f | trainer bands judge "materially more often" in the COMBAT §7 floor-trainer form (coordinator ruling; record in STATE) | parse |
| dc4acb65 | `CombatManager.burst_profile()` + `combat.json burst.species_distance` (none authored) + `--starters` / `--config-patch` band levers | test_combat_burst 9/70 |
| d30fc5c3 | pilot hit events record attack / shape / intent | parse |
| 52e345d3 | gate-A pilot taps within `combat_move_reach` (main-red root cause) | gate_a 3/3 local; fail 1/4 before |
| 75861f14 | unit: real quick strike lands at the floored stand-off (5.86 m, reach 6.36 m) | test_scale_sensitive_gameplay PASS |
| 5478b0b4 | f22 reader bursts in time when the exit is longer than one hop (pilot only) | full 12-seed table: no regressions, reader win 1.00 |
| 0fbc96b1, 8771fc9b, 3d6bdf8e | evidence: Terrapup lever trials and reader table | — |

Full list: `git log --oneline origin/main..origin/tb/f22`. b95f2098 is the merge of main.

Unit suites last run green:

- test_combat_stagger
- test_move_commit_runtime
- test_net_strike_transaction
- test_f23_live_moves
- test_combat_burst
- test_combat_ai
- test_scale_sensitive_gameplay

No independent review has been run on the commits after c0171ebb. Run one before landing.

## Not done

### 1. F22#1: Terrapup per-starter balance

Owner ruling 2026-10-05: Terrapup must be balanced like the other starters. It is not a mash-friendly tank.

Bar (coordinator ruling): in every chapter, reader median lead cost ≤ 0.55× masher, and reader win ≥ 0.9.

State: 23/39 rows pass on the shipped head.

- Terrapup fails 13: Meadows 5, Cloudreach 3, Stormwood 5. Its reader lead cost is 0.36–0.74 against masher 0.29–0.65.
- Galewisp fails 2 Tidewake rows (outer_reaches, veilfall).

What was tried. None of these changes a verdict. All are in `proof/f22_1_galewisp_trial_ab.md`.

- Burst 4 / 5 m.
- `current_zone` marker static.
- Field lifetime 0.3 s.
- Move speed +11%.
- The reader-pilot improvement (one approved attempt; that attempt is SPENT).

Attribution:

- The switching reader's lead cost is ~0 for Galewisp and Ripplet because it switches them out of visible mismatches. Terrapup's matchups look favourable in Cloudreach and Stormwood, so it stays in.
- Its reader fights run ~110 s against the masher's ~49 s.
- It is hit by `current_zone` strikes (~120 per 12 runs) and CHARGER rushes (~240) while READY at ~8.6 m, inside the 8 m pickets plus its body radius.

Next step: product tuning. PROPOSE TO THE COORDINATOR BEFORE ANY DATA CHANGE.

- Candidates measured in memory: `stone_rush.power` ×1.5 and `pebble_toss.range` 7.5.
- Those runs were killed by the wind-down with no result. Re-run each:

```
godot --headless --path . --fixed-fps 60 --script tests/smoke_f22_pattern_bands.gd -- --seeds=12 --band=cloudreach/ --trainers --starters=terrapup --move-patch=stone_rush.power=1.5 --json=...
```

Constraints:

- data/config only;
- no shrinking;
- Tidewake rows stay passing;
- reader win ≥ 0.9;
- the COMBAT §7 single-hit and wild bars hold;
- then the full 4-chapter, 3-starter table before and after.

Files: `data/moves/moves.json` or `data/creatures/species.json`, plus `tests/smoke_f22_pattern_bands.gd`.

### 2. F22#1 / item 4: Galewisp in Meadows against the ordinary-wild bar

The bar is masher win ≥ 0.9 and lead cost 15–30%.

- Galewisp's masher lead cost is 0.32–0.40 in 4 of 5 bands, over the cap.
- Ripplet and Terrapup are mostly under 15% (data in the A/B file, wild run).

The coordinator wants Galewisp brought down in the same tuning pass. Lever not chosen yet.

### 3. F22#4: named fights

Re-run on the final head, after tuning:

- `smoke_meadows_named_c2c3 --seeds=24`;
- `smoke_water_named_c2c3 --seeds=24`;
- `smoke_f22_pattern_bands --named=veyra,marrow`.

Report the top-trainer bar (reader win ≥ 0.75, masher lead faint 1.0, reader party cost ≤ 0.55× masher) and C3.

- The Warden C3 passes under the COMBAT.md:144 neutral gate (worst neutral hit 0.409).
- C3 in-world captures and code-blind judges stay BLOCKED-with-ask (Codex).
- The folded F04#1/#2/#6/#7, F10#6 and F14#1 close with #4.

### 4. Optional

Code-blind clip check of the improved reader (Terrapup plus one other starter), using `tests/capture_f22_roles.gd` style. Only if the coordinator still wants it.

### 5. STATE

Record the coordinator ruling on the floor-trainer form, and the owner ruling on Terrapup. This lane does not edit STATE.

## Known traps

- **Disk.** The container has about 1–2 GB free. The band JSON is 60–145 MB per chapter. gzip it after summarising, and delete logs.
- **No second worktree.** The tree is 15 GB, so a second worktree does not fit. Switching branches or merging while sweeps run contaminates them, because they read data lazily.
- **Seed minimum.** The band smoke refuses fewer than 12 seeds.
- **Killing processes.** `pkill -f` patterns that match your own shell kill it (exit 144). Kill by PID from `pgrep -x godot`.
- **Pushing.** Always push with `git push origin HEAD:refs/heads/tb/f22` and verify with `git ls-remote`. Quote SHAs only from that output; several messages carried wrong SHAs.
- **peer_runner subclasses.** Subclasses override base helper names. Check every `extends "res://tools/net/peer_runner.gd"` file before adding a helper.
- **Move commit.** `validate_strike` compares the move with the frozen start. Never add keys to `move` before that call.
- **Net smoke fixtures.** The shared wild's HP lives on `runtime._enemy`, `body.instance` AND the record. A guest charge needs Energy, earned from landed quick hits.
- **Pattern patches.** `--config-patch` into `patterns.*` applies (the pilot reads the cached `MATH.config()`). A lack of effect means the lever is irrelevant, not that the patch failed.
