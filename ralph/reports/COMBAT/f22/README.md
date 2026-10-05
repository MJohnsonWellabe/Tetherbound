# F22 lane evidence (tb/f22)

All runs in-container: Godot 4.7 headless, `--fixed-fps 60`, flat C2 fixture, production manager/bodies/AI with the F22 pattern consumer on. Footage: xvfb + opengl3 (Compatibility, llvmpipe).

| Criterion | Verdict | Evidence |
|---|---|---|
| F22#0 | PASS (engine) | `proof/f22_0_contract_and_mount.txt`; `proof/f22_0_wild_reactions.json` (`tests/smoke_f22_wild_reactions.gd`). Every role telegraphs ≥2 authored shapes at or above its floor, and 70–100% of recoveries reposition ≥0.75 m. 11 dodges and 2 punishes are observed in aggregate. Dodge and punish are not proven per role: DIVER 0/0; ACE and CURRENT 0 punishes. In CI (meadows group). |
| F22#1 | FAIL / needs ruling | `proof/f22_1_baseline_bands.json` (pre-change pilot); `proof/f22_1_2_bands_r5.json` (new pilots, commit a31ab858, before the review's switch-back fix; all four chapters). The switching reader wins ≥0.9 in Meadows and Tidewake. It falls below 0.9 at Cloudreach Summit (0.83) and in 6 Stormwood band/starter rows (0.58–0.83). Each shortfall equals that row's SWITCH_READER error count (4 at Cloudreach, 22 at Stormwood): stalls past the 240 s cap, or fixture errors. The one stall diagnosed by hand (Terrapup vs Sirenseal, Tidewake Veilfall) was 212 s of escaping a kiting CURRENT. The plain reader is still below 0.9 in 11 bands (18 band/starter rows). Reader cost is often above the masher's. A re-run on the current pilot is owed. But a masher wins ≥0.92 and loses its lead in at most 1 of 12 runs (median lead cost 15–43%, median party cost 1–11%): wild lead faint ends the fight (D32), and COMBAT §7's ordinary-wild floor (masher ≥90% win) caps the masher's lead-faint rate at ≤0.10. So the ≥0.25 gap cannot be reached on a wild-only sweep. Coordinator ruling (2026-10-04): run the band sweep on each band's ordinary trainer fights (`--trainers`, commit 638769ec), with three pass conditions: reader win ≥0.9, the lead-faint gap, and reader median lead cost ≤0.55× masher. First result, Meadows band 2: the reader's lead takes more HP than the masher's (0.62–0.85 plain reader, 0.28–0.71 switching, vs masher 0.34–0.35). Only Galewisp passes. |
| F22#2 | MOVED TO F24 (owner ruling 2026-10-05) | F22 closes without it. The tag-combo/switch-value proof belongs to F24 (`tether_commands.json` runtime). The earlier partial switch-value receipt stays in `f22_1_2_bands_r5.json` as context only. |
| F22#3 | PASS (fixture) | `proof/f22_3_roles/`: code-blind judge 5/5 (VERDICT.md, JUDGE_RAW.md). Limits: flat fixture, not in-world; the ACE is a role override; the brief uses shape vocabulary. |
| F22#4 | FAIL (C2), C3 capture not done | `proof/f22_4_named_c2.txt`. Meadows Relay Captain PASSES all three starters with the new reader. Warden fails the party ratio (0.87/0.83 > 0.55). Water Venn/Nerissa: both pilots win and lose the lead every run, with reader party cost above masher. C3 measurable half: Warden with Galewisp FAILS single-hit (masher max hit 0.503 ≥ 0.50); the other measured rows stay below 0.50 (water ≤0.164) with tells ≥0.9 s. Not run: Veyra and Marrow have no C2 smoke yet. C3 in-world code-blind captures are pending. F04#1/#2/#6/#7, F10#6 and F14#1 therefore stay open under F22#4. |

Root causes measured, so F22#1/#4 are not pilot artefacts:
1. Mashing quick hits drains poise and staggers the opponent, cancelling its tell.
2. Starter body radii are 1.23–1.46 m. With 0.45–0.55 s left after a shape locks, most locked shapes can only be left with a well-timed burst, and the burst spends the Wind the reader needs to punish.
3. CORRECTED: the masher's ordinary-wild median lead cost is 15–31% in every band except Cloudreach High Roost (43%), so it already meets COMBAT §7. The earlier 1–11% figure was party cost. A trial ×2.5 wild power overshot (masher win 0.53–1.00) and was reverted to 1.0 everywhere: `proof/f22_wild_power.md`.

Proposed next steps (none built here):
- COMBAT §4 target per-role poise pools and the 0.8 s post-stagger resistance. Coordinate with F21.
- Raise ordinary-wild pattern power toward the declared 15–30% masher cost (PROGRESSION/F19).
- A ruling on the F22#1 metric.

## Locked-shape escapability (game change, 6ba5e132+)

Starter body radii are terrapup 1.46, ripplet 1.37 and galewisp 1.23 m. The hit test widens every shape by the target's body radius.

A tracking marker/field locks onto where the creature stands. With tracking for half the tell, a 1.1 s leap marker or zone leaves 0.55 s after lock to cover the marker radius plus the body radius:
- diver_leap 2.0 + 1.37 = 3.37 m
- current_zone 2.5 + 1.37 = 3.87 m

At 5.6 m/s that cannot be walked, and the burst is the only exit.

Fix in geometry: `marker_tracks_fraction` 0.5 → 0.3 on every marker/field row (diver_leap, current_zone, vess_flank). The marker now locks with ~0.77 s left, so a walk covers ~4.3 m. Radii, shapes and tell lengths are unchanged, and no creature is resized. Cones, lanes and rings already leave a walkable exit, since heading lock does not pin the target at the centre.
