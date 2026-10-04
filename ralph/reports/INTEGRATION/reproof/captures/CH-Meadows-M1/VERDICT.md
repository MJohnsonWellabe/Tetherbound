# CH-Meadows#M1 — Fresh controller run: starter, naming, catch, camp, tournament for three starters, plus village walks

- Commit under test: 826d273c3
- Renderer: software renderer (Compatibility), Xvfb + llvmpipe, opengl3, 1280x720
- Scope of this lane: the village-walk part only, reusing ../F01-2 (day) and ../F01-3 (night): same tool, `tests/capture_village_walk.gd --route=visits --from-title`, which plays the production title's Start New Game and the opening with parsed joypad input, then walks to every opening NPC, camp and gate.
- **Gate-B chains (starter, naming, practice fight/catch, camp, three-bed readiness, three played tournament rounds, for each of the three starters; save/reload; two-peer layout) are run by the retest lane, not here.**

## Walk results

| Walk | Harness | Code-blind judge |
|---|---|---|
| Day (F01-2) | FAIL: ended 9.29 m from Mira; reached Grandpa, Tam only | FAIL: 10 of 12 targets never reached; stall by lamppost/cottage (frames 022–024) |
| Night (F01-3) | FAIL: ended 9.32 m from Mira; reached Grandpa, Tam only | FAIL: same; interiors lit as daytime at 23:00 (002–005, 013–014) |

The opening-from-title part completed in both runs (both walks start after the played opening at Grandpa's door).

## Verdict: FAIL (village-walk part). Gate-B chains: retest lane.
Top defects: the visits route cannot reach Mira from Tam on current village geometry (reproduced day and night); start camera blocked by the farmhouse wall (frame 001); interiors day-lit at night.
