# Continuous coverage gaps — 2026-09-08

The green PR #80 CI run `34197701347` is regression evidence, not proof of
the playable-first fresh-save milestone. Root inspected the following source
boundaries after the independent acceptance audit identified them.

| Existing witness | Boundary that prevents a fresh-save completion claim |
|---|---|
| `tests/smoke_gate_b_continuous.gd` | `_through_the_road_gate()` directly sets `road_gate_open`; `_ready_a_tournament_team()` manufactures party members and raises their levels. These do not prove earning either gate. |
| `tests/smoke_cloudreach_continuous.gd` | Resets the game, seeds Meadows completion flags/Heart, five level-25 creatures and tools, and instantiates Cloudreach directly. This can establish a chapter diagnostic, not the earned Meadows handoff. |
| Stormwood | No `tests/smoke_stormwood_continuous.gd` existed when inspected. Prefix, combat and transition slices cannot establish their composition. |
| `tests/smoke_water_continuous.gd` (working diagnostic) | Begins with a synthetic level-60 Aquaryn, resolved Alpha, Swim Stone and saddle at Tidal Cradle. No post-departure grants are permitted, but this cannot prove the opening through Alpha or the ordinary surviving-party handoff. |

These are blocking evidence gaps, not deferred polish and not proof that the
gameplay itself is broken. Do not remove useful regression fixtures simply to
make their names appear continuous. Add earned-path witnesses and repair actual
failures they expose.

Next bounded work: implement a Stormwood chapter diagnostic from a disclosed
chapter-entry fixture with no Stormwood completion flags. Earn its progression,
fights, Spark and Waterward gate through the production path. Preserve an explicit
boundary between that result and an eventual single fresh-save four-chapter run.
Tidewake's live diagnostic and creature-footing repairs continue in parallel.
