# Lantern Hollow inhabitants — separated playable positions

The authored Maud, Sable, Bram and Mira rows previously shared XZ (-450,3960)
with the existing shrine. Production mounts all four; overlapping capsules and
providers obscured the required Sable contact. This is an observed authored
collision, not a claim that every possible jump or camera stance was impossible.

The shrine, road junction, 48 m safe zone and nearby buildings remain unchanged.
Four NPCs now occupy distinct positions 12 m from that centre:

| NPC | X | Authored Y (ground + 0.15) | Z |
|---|---:|---:|---:|
| Sable | -450 | 55.8394 | 3948 |
| Elder Maud | -438 | 57.5725 | 3960 |
| Bram | -462 | 57.4894 | 3960 |
| Mira | -450 | 57.9932 | 3972 |

Production heightfield grades at these points range from 1.21 to 8.98 degrees.
This preserves the settlement's required/optional cast and gives each contact
space around the shrine. Buildings at (-473,3980), (-428,3974), (-476,3945),
and the well at (-449,3985) were considered before the physical check.

## Actual scene proof

`.artifacts/wave6_lantern_approach.gd` is an unshipped synthetic diagnostic.
It prepared only Rootgate-released and Act-II-complete chapter prerequisites
and one south-approach player pose. No party or material grants were used.
The actual scene, bodies, terrain, buildings, arbiter and dialogue remained
production. Existing stick navigation and physical input helpers drove seven
legs with the unchanged 1800-frame bound each and a five-minute total watchdog.

Run session 49498 exited 0. All legs completed in 88–151 frames with zero
navigator resets; every final stance was grounded. Exact offers were:

- Sable: Greet Sable, distance 3.1797 m. Physical Interact opened the actual
  dialogue; ordinary advance inputs closed it and set captive_truth_learned.
- Maud: Greet Elder Maud, 2.6929 m.
- Mira: Challenge Mira, 2.7165 m.
- Bram: Challenge Bram, 2.6125 m.

Logs: `.artifacts/wave6-lantern-approach-{console,engine}.log`.
No ERROR/SCRIPT ERROR occurred. Existing terrain texture/deprecation warnings
remain disclosed. Owner save hashes matched before/after records at
`.artifacts/wave6-lantern-owner-{before,after}.json`; no Godot processes remained
at RAM release. This proves local approaches and Sable dialogue, not trainer
fight completion, rendered presentation or a fresh campaign traversal.

Existing NPC/trainer/dialogue checks passed 8 tests / 936 assertions, exit 0,
logs `.artifacts/wave6-lantern-data-final-*`. Initial focused checks caught the
catalogue's ground+0.15 convention; all four stored Ys were corrected. Runtime
already derives actual ground independently, so the local input proof uses
those same production-grounded positions. The old exact Sable anchor assertion
was updated to the new authored position; no tolerance was widened.
