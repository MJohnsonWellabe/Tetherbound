# Bounded input driver repair

Reviewer: combat, independent read-only source review; static PASS.

The only behavior change in `tests/helpers/gate_b_tail_segment.gd` is the approach-versus-input-attack threshold. Both production APIs match the supplied Node3D/float arguments: `CombatManager.floor_reach_for_bodies` returns a cloned move with range covering `ContactSpacing.pair_reach_need` plus 0.5 m. All rounds, budgets, damage progress checks, victory flags and objective assertions remain intact. This adapts the pilot to shipped physical spacing; it changes no combat mechanic.

Actual scoped command: Godot 4.7 `--headless --path . --script tests/smoke_gate_b_tail.gd`, isolated APPDATA `.tmp/f16-ci-tail-profile`, primary checkout at 5d44f94ad with the committed helper delta described here. Native exit 0, 339.63 s, `ci-full-tail-fixed.txt`. Actual paid house, camp, three creature beds, sleep/condition, marshal entry, all three fought rounds (1267/2232/4009 action frames) and South Bridge objective pass. Existing disclosed synthesized post-village stock/team and support healing remain; no claim of an earned full continuous run from this targeted witness. The original full-chain CI stall is retained in `ci-full-chain-stall-initial.txt`.

RD-36/RD-37: no whole local unit suite replay for this input helper change. The selected same-PR full-CI continuous job must exercise the actual opening and complete chain. Unit membership and production source are unchanged.
