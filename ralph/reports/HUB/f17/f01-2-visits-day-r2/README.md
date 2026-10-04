# F01#2 normal-controller DAY walk — re-proof R2 (tb/f17)

Reproof FAIL (tb/reproof-captures, 826d273c3): "ended 9.29m from Mira (needs 3.0m)", stalled at
(17.32, 3.92) next to a lamppost and a cottage; 10 of 12 targets not reached.

Root cause: `tests/capture_village_walk.gd` hard-coded `INDOOR_APPROACH` for Mira and Bram at the
pre-redesign shop and inn interiors (Mira via (13.87, 4.8) → (17.5, 4.0)). After F17 re-planned the
village as one straight road, the walk headed for empty ground behind the new houses. Fix (64801247):
the approach is derived at run time from the actual `mira_shop`/`bram_inn` Door and facing (1.4 m
out on the frontage, 1.0 m in through the doorway, then a stand 1.9 m from the NPC). No tolerance
changed.

Run: render.yml 37222378954 on 64801247, xvfb + Compatibility, 1280x720, same command as the
reproof (`--route=visits --time=day --from-title`). Exit 0 after 4140 s.

    [village-walk] PASS route=visits time=day captures=98 max_off_road_m=0.00 visited=12

All 12 targets were reached: Grandpa 1.45 m, Tam 0.78, Mira 1.92, Bram 1.65, Nessa 0.80, Maren 1.18,
Oskar 1.10, the old key 1.08 (taken), RoadGate 0.51 (opened with the key), Practice Meadow camp 2.70,
TrailGate 0.14, PondGate 0.12. Files: `walk_log.txt` and 15 key frames in `frames/`.

Code-blind check (`codeblind-review.md`): PASS. Non-blocking follow-ups it noted: the arch the
log calls TrailGate is signed "South Bridge"; the camp and the two gates have no interaction prompt
(the criterion is reach); minor clipping (RoadGate leaf through its post, legs in a bush at the
camp); a cyan quest beam in the inn.
