# F04 round-2 code-blind judge (local xvfb renders at 03b7a17b)

**Judge.** A code-blind subagent that saw only the 25 key frames here (agent `a4d1a98261242fdb5`, sonnet).

**Render.** `tools/art_pipeline/capture_named_fight.gd --live-member=... --attack --dodge --tell-frames --keep-alive --resolve=won` under `xvfb-run` with `--rendering-driver opengl3` at 1280×720 (llvmpipe). The head is 03b7a17b: fight glades, the fight-open camera fix, the HEAVY banner, and the traveling DIVER.

**Letters:**
- A: Oreth (captain_riverwatch, Mosshell WALL, member 0)
- B: Halder (captain_field, Tuskroot CHARGER, member 1)
- C: Vess (captain_ridge, Galecrest DIVER, member 2; no tell fell in the window, so in-fight frames are used)
- D: the Warden (warden_aldis, Tuskroot ACE, member 4)
- F: Hald (stronghold_elite, Galecrest DIVER, member 0)

| Fight | Q1 readable + question | Q2 tell | Q3 framing | Q4 aftermath | Verdict |
|---|---|---|---|---|---|
| A | PASS | PARTLY (ring static start→mid) | PASS (Mosshell reads smaller than the player's creature) | FAIL (a02 is a generic "Greet Captain Oreth") | **PASS** |
| B | PARTLY (the lane reads as a blob) | PARTLY | PARTLY (a third creature clutters the frame) | FAIL | FAIL |
| C | FAIL (no reposition or lane in the sampled frames) | FAIL | PASS | FAIL | FAIL |
| D | PASS (HEAVY banner and ring) | PARTLY (a distinct impact VFX) | PASS | PASS ("You won. Take the Realm Key") | **PASS** |
| F | PARTLY (a clean lane in 01) | FAIL | FAIL (camera clipped in t01-start and a02) | FAIL | FAIL |

**Ranked defects:**
1. F's indoor camera clips through geometry.
2. C's DIVER reposition and lane are not in the sampled frames. The headless witness does show the dive travelling from 7 m to 3 m.
3. The aftermath frames for A, B, C and F show generic exploration, not a win state.
4. The ring and lane are static between start and mid.
5. B's lane reads as a blob, with a third creature in frame.

Rows #2, #3 and #6 (captains, the Warden, aftermath) moved to the Meadows F04 bosses lane at 21:05. This verdict and these frames are handed over as-is.
