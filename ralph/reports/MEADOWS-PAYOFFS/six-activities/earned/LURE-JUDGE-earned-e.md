# F03#0 lure judge, set E (code-blind; all six)

**Input:** the 23 frames in `lure-judge-e/`. Each filename caption gives only distance, road/glance or prompt. The judge was a fresh agent told to open nothing but those images.
- Bram, herd and Juno are set D's frames (CI runs below), unchanged.
- Doss, vault and Hall are new local renders (`lure0/{doss,vault,hall}-e/`, `lure0/RENDER.txt`).

| activity | run | verdict |
|---|---|---|
| bram | 36324730837 (S04, `--via=372,957`) | PASS (marginal): column over the hilltop from the road at 75-80 m; campfire and figure on approach; the prompt frame is thin |
| doss | local, S07-band3 (`lure0/doss-e`) | **PASS**: column clear from 60 m; the camp (campfire, broken plank perch, fence rail, Doss) reads as a specific place |
| hall | local, earned `seed4_hall` (`lure0/hall-e`) | PASS (marginal): alpha label over the trees from the road; the Galecrest pack at 30 m; foliage, a Duskhush and a Chop prompt compete |
| herd | 36314439928 (S04, road-bound) | PASS (marginal): two pale deer on a boulder at 63 m; thin at the prompt, night |
| juno | 36320553577 (S07-band4) | **PASS**: column at 160 m; oxblood banners and a patrol figure at 57 m; reads as a Tether camp |
| vault | local, derived pre-guardian S06 (`lure0/vault-e`) | **PASS**: from the den, a warm-lit arched doorway beyond the guardian; up close, a slab in a bone arch with a light seam and a fire-pot either side |

**Result: 6 of 6. F03#0 met** (three marginal).

**Earlier pass this session (disclosed):**
- A first code-blind judge on a pre-fix set scored 4 of 6. It failed vault (door unlit from the den; seam blown to white) and Hall (on set D's old frames).
- Its Doss and vault frames were also rendered from a stale local import (untextured props: white perch planks, white crate). A clean re-import fixed that before this set.
- The vault fire-pots, lintel light and warmer seam, and the Hall re-render, answer that pass.

**Judge concerns, not blocking F03#0:**
- Bram, Doss and Juno share one black smoke column.
- The Doss and herd "first seen" captions (148 m, 127 m) show nothing identifiable; the real pickup is about 60 m.
- Companions and wild creatures sometimes crowd the frame.
- The Doss prompt frame has smoke across its left edge.
