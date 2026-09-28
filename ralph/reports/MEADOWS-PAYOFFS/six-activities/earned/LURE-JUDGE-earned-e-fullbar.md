# F03#0 lure set E: full-bar visual judge (code-blind, visual-judge skill)

**Input:** the same 23 frames in `lure-judge-e/`. The judge was a fresh sonnet agent following `.claude/skills/visual-judge/SKILL.md`. It opened only those frames and the references the skill names.

**Setup gap:** the skill's primary palette reference, `docs/reference/tetherbound-meadows-keyart.png`, is missing from this checkout. Bar A is therefore partial; the judge used the GAME_BIBLE §4.1 quote in SKILL.md and the `palworld-0*` references instead.

| activity | visible-lure read | judge's reason |
|---|---|---|
| bram | PASS (marginal) | readable at 75-80 m, but a flat field; nothing marks it as a site |
| doss | FAIL | only the shared smoke column from 148 m to 36 m; the camp reads only at the prompt |
| herd | FAIL | two small, dim deer at night; a large unrelated creature near the road competes |
| juno | PASS (marginal) | oxblood pylons and fire at 44-57 m; foreground creatures compete |
| hall | FAIL | the alpha label is cut by tree trunks at 81 m and 58 m; readable only at 30 m |
| vault | PASS | lit arched door with flanking fire-pots; the guardian is visible from the den threshold |

**Bar A:** NO (partial). **Bar B:** NO.

**Top 3 addressable issues:**
1. Herd: move the incidental creature off the sightline and brighten the deer at night.
2. Doss: make the camp's glow and silhouette break the horizon earlier.
3. Hall: raise the alpha label above the canopy and give the alpha a distinct tint.

**Disagreement with judge E:** judge E (`LURE-JUDGE-earned-e.md`, fresh agent, same frames) passed all six, with Doss and vault as full PASS. This full-bar pass is stricter on the same frames: it fails Doss, herd and Hall. Neither verdict is hidden; the coordinator decides which bar F03#0 is held to.
