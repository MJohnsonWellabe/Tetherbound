# F19 authored curve checkpoint

Source: `a778658659`, based on main `ddeadbc1eb9cc2f81693d69eded98ee9183579a1`.
Windows source authoring only. No Godot, gameplay, save, co-op or earned-route
proof has run for this checkpoint. No F19/F20 criterion is claimed MET.

| Runtime realm | Team | Ordinary wild | Boss send-out levels |
|---|---|---|---|
| meadows | 3→22 | 2–20 | 21/21/21/22/22 |
| water (Tidewake) | 20→33 | 18–32 | 32/32/33/33 |
| cloudreach | 31→44 | 29–43 | 43/43/44 |
| stormwood | 42→55 | 40–54 | 54/54/54/55/55 |

`biome_order.json` remains the sole order authority. `chapter_curve.json`
adds chapter targets keyed by existing runtime realm ids and explicitly calls
them unmeasured authored targets. Its Meadows split is
3→9→12→15→18→22, with wild 2–6 / 7–10 / 10–13 / 13–17 / 16–20.
BOSSES §0's half-down formulas rederive named teams; its explicit boss arrays
override the formulas. The three Sigil captains and Band 4–5 teams gain +2.
The Warrens residents/guardian gain +2, preserving weakest resident > Band 2
field ceiling. Solmane volunteers at 44, Aquaryn is 26, and Stormheart uses
existing Fulgocobra at 55, with its offer catalogue marked non-catchable.

Band 5 retains its authored geometry, species, order ids, density, three road
supplies and recovery placement. No pickup, harvest, route, heal, combat AI,
team species, reward amount or gate was retuned. Authored alpha bonuses stay;
the separately reviewed combat helper (`dc558ee04d`, from `1bc651be72`) honors
an optional `level_ceiling`, and only leaders whose bonus could exceed 20
receive that field. Missing ceilings preserve prior behavior.

`derive_curve.py` reproduces the data edits from the recorded baseline and
preserves JSON formatting except the expanded chapter curve. The existing
band-split trainer fixture mirrors matching level edits without changing row
identities. This is a content mirror, **not an earned save**. Every earned
checkpoint fixture remains untouched and must be regenerated from the real
new-order route with provenance after runtime integration.

The required curve pin is authored at `tests/test_redesign_chapter_curve.gd`
and has not run. Required subsequent proofs remain: the curve pin, gate scan,
ordinary portal signs with no hidden level gate, per-participant key/relic
transactions with reconnect/reload, all four legendary offer branches, and
earned saves. Dependency landing holds remain F16+F18 for F19 and F18+F19 for
F20. F16 is landed; F18 is not. No PR has been opened.

Current real-path gaps: boss payouts still use legacy world key/relic flags;
chapter entry/reward clauses still reference physical-crossing entitlements;
Tidewake still invites the old ending. Those require owned runtime handoff
changes and F18's portal transactions before this data can be accepted.
