# F22 lane evidence (tb/f22)

All runs in-container: Godot 4.7 headless, `--fixed-fps 60`, flat C2 fixture, production manager/bodies/AI with the F22 pattern consumer on. Footage: xvfb + opengl3 (Compatibility, llvmpipe).

| Criterion | Verdict | Evidence |
|---|---|---|
| F22#0 | PASS (engine) | `proof/f22_0_contract_and_mount.txt`; `proof/f22_0_wild_reactions.json` (`tests/smoke_f22_wild_reactions.gd`). Every role telegraphs ≥2 authored shapes at or above its floor, and 70–100% of recoveries reposition ≥0.75 m. 11 dodges and 2 punishes are observed in aggregate. Dodge and punish are not proven per role: DIVER 0/0; ACE and CURRENT 0 punishes. In CI (meadows group). |
| F22#1 | FAIL / needs ruling | `proof/f22_1_baseline_bands.json` (pre-change pilot); `proof/f22_1_2_bands_r5.json` (new pilots, commit a31ab858, before the review's switch-back fix; all four chapters). The switching reader wins ≥0.9 in Meadows and Tidewake. It falls below 0.9 at Cloudreach Summit (0.83) and in 6 Stormwood band/starter rows (0.58–0.83). Each shortfall is a stall past the 240 s cap: 4 at Cloudreach, 22 at Stormwood, all against kiting CURRENT/DIVER wilds. The plain reader is still below 0.9 in 9 bands. Reader cost is often above the masher's. A re-run on the current pilot is owed. But a masher never loses its lead to an ordinary wild (100% win, 1–11% cost): wild lead faint ends the fight (D32), and COMBAT §7's ordinary-wild floor (masher ≥90% win) caps the masher's lead-faint rate at ≤0.10. So the ≥0.25 gap cannot be reached on a wild-only sweep. Ruling asked of the coordinator: trainer fights per band, lead HP cost, or both. |
| F22#2 | PARTIAL (F24 tag combo OFF) | Same receipt, `switch_value` per chapter. On the same seeds the switching reader (D32 switch on visible matchup plus spent-lead rescue) beats the non-switching reader: win/median cost 1.00/0.017 vs 0.99/0.033 Meadows, 0.995/0.000 vs 0.97/0.051 Tidewake, 0.98/0.035 vs 0.78/0.098 Cloudreach, 0.90/0.046 vs 0.875/0.101 Stormwood. Each chapter's smoke `pass` is false: stalls count as errors, and the masher lead-loss gap fails. The tag-combo half cannot be measured until F24 `tether_commands.json` runtime is on. |
| F22#3 | PASS (fixture) | `proof/f22_3_roles/`: code-blind judge 5/5 (VERDICT.md, JUDGE_RAW.md). Limits: flat fixture, not in-world; the ACE is a role override; the brief uses shape vocabulary. |
| F22#4 | FAIL (C2), C3 capture not done | `proof/f22_4_named_c2.txt`. Meadows Relay Captain PASSES all three starters with the new reader. Warden fails the party ratio (0.87/0.83 > 0.55). Water Venn/Nerissa: both pilots win and lose the lead every run, with reader party cost above masher. C3 measurable half: Warden with Galewisp FAILS single-hit (masher max hit 0.503 ≥ 0.50); the other measured rows stay below 0.50 (water ≤0.164) with tells ≥0.9 s. Not run: Veyra and Marrow have no C2 smoke yet. C3 in-world code-blind captures are pending. F04#1/#2/#6/#7, F10#6 and F14#1 therefore stay open under F22#4. |

Root causes measured, so F22#1/#4 are not pilot artefacts:
1. Mashing quick hits drains poise and staggers the opponent, cancelling its tell.
2. Starter body radii are 1.23–1.46 m. With 0.45–0.55 s left after a shape locks, most locked shapes can only be left with a well-timed burst, and the burst spends the Wind the reader needs to punish.
3. Ordinary wild damage leaves masher lead cost at 1–11%, below COMBAT §7's 15–30% ordinary-wild target.

Proposed next steps (none built here):
- COMBAT §4 target per-role poise pools and the 0.8 s post-stagger resistance. Coordinate with F21.
- Raise ordinary-wild pattern power toward the declared 15–30% masher cost (PROGRESSION/F19).
- A ruling on the F22#1 metric.
