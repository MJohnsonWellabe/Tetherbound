# F22 lane evidence (tb/f22)

All runs in-container: Godot 4.7 headless, `--fixed-fps 60`, flat C2 fixture, production manager/bodies/AI with the F22 pattern consumer on. Footage: xvfb + opengl3 (Compatibility, llvmpipe).

| Criterion | Verdict | Evidence |
|---|---|---|
| F22#0 | PASS (engine) | `proof/f22_0_contract_and_mount.txt`; `proof/f22_0_wild_reactions.json` (`tests/smoke_f22_wild_reactions.gd`). Every role telegraphs ≥2 authored shapes at or above its floor, and 70–98% of recoveries reposition ≥0.75 m. 11 dodges and 2 punishes are observed in aggregate. Dodge and punish are not proven per role: DIVER 0/0; ACE and CURRENT 0 punishes. In CI (meadows group). |
| F22#1 | FAIL / needs ruling | `proof/f22_1_baseline_bands.json` (pre-change pilot); `proof/f22_1_2_bands_r5.json` (new pilots). The switching reader wins ≥0.9 in nearly every band, at or below masher cost. But a masher never loses its lead to an ordinary wild (100% win, 1–11% cost): wild lead faint ends the fight (D32), and COMBAT §7's ordinary-wild floor (masher ≥90% win) caps the masher's lead-faint rate at ≤0.10. So the ≥0.25 gap cannot be reached on a wild-only sweep. Ruling asked of the coordinator: trainer fights per band, lead HP cost, or both. |
| F22#2 | PARTIAL (F24 tag combo OFF) | Same receipts, `switch_value`. The switching reader (D32 switch on visible matchup plus spent-lead rescue) beats the non-switching reader on the same seeds. The tag-combo half cannot be measured until F24 `tether_commands.json` runtime is on. |
| F22#3 | PASS (fixture) | `proof/f22_3_roles/`: code-blind judge 5/5 (VERDICT.md, JUDGE_RAW.md). Limits: flat fixture, not in-world; the ACE is a role override; the brief uses shape vocabulary. |
| F22#4 | FAIL (C2), C3 capture not done | `proof/f22_4_named_c2.txt`. Meadows Relay Captain PASSES all three starters with the new reader. Warden fails the party ratio (0.87/0.83 > 0.55). Water Venn/Nerissa: both pilots win and lose the lead every run, with reader party cost above masher. The C3 measurable half passes (max hit ≤0.45 Meadows, ≤0.164 water; tells ≥0.9 s). Not run: Veyra and Marrow have no C2 smoke yet. C3 in-world code-blind captures are pending. F04#1/#2/#6/#7, F10#6 and F14#1 therefore stay open under F22#4. |

Root causes measured, so F22#1/#4 are not pilot artefacts:
1. Mashing quick hits drains poise and staggers the opponent, cancelling its tell.
2. Starter body radii are 1.23–1.46 m. With 0.45–0.55 s left after a shape locks, most locked shapes can only be left with a well-timed burst, and the burst spends the Wind the reader needs to punish.
3. Ordinary wild damage leaves masher lead cost at 1–11%, below COMBAT §7's 15–30% ordinary-wild target.

Proposed next steps (none built here):
- COMBAT §4 target per-role poise pools and the 0.8 s post-stagger resistance. Coordinate with F21.
- Raise ordinary-wild pattern power toward the declared 15–30% masher cost (PROGRESSION/F19).
- A ruling on the F22#1 metric.
