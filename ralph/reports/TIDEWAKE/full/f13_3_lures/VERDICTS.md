# F13#3 lures on tb/tidewake-full: four fresh code-blind judges, two rounds

Protocol:
- Prompt: `JUDGE_PROMPT.txt`, the same as Tidewake-B round 3.
- Each judge was a fresh subagent that could read only its frame folder: 12 frames, a
  contact sheet and the key art.
- Frame map: `FRAME_MAP.txt`. Frames 01–02 Lantern, 03–04 Gull, 05–06 Cradle, 07–08 Garden,
  09–10 Deep Watch, 11–12 Lastlight.
- Captures: local xvfb + opengl3 at 1280x720 with `tools/capture_water_chain_lures.gd`.

## Round 1 (`r1/`)
Data: the Deep Watch lamp moved 2.5 m aside, and the Lantern rise group was moved to 16 m
from the landing in the Garden crest pattern.

| Place | Judge A | Judge B |
|---|---|---|
| Lantern | WEAK | WEAK |
| Gull | YES | YES |
| Cradle | WEAK | YES |
| Garden | YES | YES |
| Deep Watch | WEAK | YES |
| Lastlight | YES | YES |

Both judges independently called the opaque #2e2a27 signal column (Lantern nook, Garden
saddle and vault) "a black spike / tornado / rendering error".

## Round 2 (`r2/`)
Data changes, affecting Lantern and Garden frames only; the other frames are unchanged
from r1:
- The three black columns became soft grey long-range plumes (the Gull/Cradle look).
- Lantern's rise banner now faces the landing, and the group gets a gull-size plume.

| Place | Judge C | Judge D |
|---|---|---|
| Lantern | WEAK | WEAK |
| Gull | WEAK | WEAK–YES |
| Cradle | WEAK | WEAK |
| Garden | WEAK | YES as a landmark, WEAK as a destination |
| Deep Watch | WEAK | WEAK |
| Lastlight | WEAK | WEAK |

## Reading
- Judge variance is large. On byte-identical Gull, Cradle, Deep Watch and Lastlight frames,
  round 1 gave YES to three or four of them, and round 2 gave WEAK to all of them.
- Lantern is WEAK from all four judges. **Lantern's lure is not closed.**
- The asks the judges repeat are asset or lighting level: a distinct silhouette per place, a
  warm light that visibly lights its surroundings, a readable object at the end rather than
  plank or slab props, and no second identical banner in view.
- Grey smoke instead of the black column removes the one defect all four judges saw as a bug.
