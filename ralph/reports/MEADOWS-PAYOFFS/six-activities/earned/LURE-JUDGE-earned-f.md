# F03#0 lure judge, set F (full bar; code-blind; visual-judge skill)

**Input:**
- The 22 frames in `lure-judge-f/`.
- The judge was a fresh sonnet agent following `.claude/skills/visual-judge/SKILL.md`, with the key art (now present in the checkout) and the Palworld references. It opened no code or reports.
- Bram and Juno are set D's CI frames, unchanged. Doss, Hall, herd and vault are new local renders (`lure0/{doss,hall,herd}-f`, `lure0/vault-f2` + `vault-f3`, `lure0/RENDER.txt`).

**What changed since VERIFIER's fail (#356 5859347449), with existing assets only:**
- **Herd (the named subject must be the focus at the prompt):** the walker puts the companion away for lure frames.
  - `herd_04` (prompt) now frames the two Meadowharts alone.
  - At `herd_02` (55 m) the recall did not take, and the companion is still in shot.
- **Doss (a legible lure of its own at 60 m and beyond):** a tall river-blue pennant stands on the crest at (-31,4171). It is the installed family's Banner_2; Banner_1 is Team Tether's oxblood roadside standard, locked by `test_meadows_banner_standards_0912.gd`.
- **Vault door (not a flat, pale, unlit slab):**
  - darker cut stone (#4d3f31);
  - the seam is a thin deep-amber line (0.12 m, #dc6f24) instead of the 0.28 m pale strip;
  - two fire-pots flank the door (set E), with a den-side pool and lintel light.
- **Hall (the nameplate clipped into the canopy):** the alpha's label is opt-in `no_depth_test` (`alpha_pins.gd`), so it reads whole from the road at 81 m.

| activity | visible-lure read (set F) |
|---|---|
| vault | **PASS**: guardian in the foreground and the shut arched door legible beyond it with fire-pots; the door confirmed up close |
| bram | PASS (marginal); set D frames |
| doss | PASS (marginal), re-judged on `doss-f` frames after the pennant fix: pennant and smoke at 60 m are noticeable though not striking; the site resolves at 42 m; at the prompt the fire and perch dominate and Doss is small |
| hall | PASS (marginal): label readable from the first sighting at 81 m; in two frames it hangs over grass or the player's own companion, where trees hide the alpha |
| herd | PASS (marginal): at the 123 m night glance nothing reads; the pair reads clearly from 29 m and at the prompt |
| juno | PASS (marginal); set D frames; the prompt figure is small beside a companion |

**Bar A: NO. Bar B: NO.** The judge's reasons are mostly chapter-wide rather than about the lures:
- Night frames crush to near-black (herd, Bram, the night halves of Doss and Juno).
- Prop density is sparse next to the Palworld references.
- One rock-plated creature model recurs across frames. That model is largely the player's own party member (Tup/Burrowback), which the judge took for set dressing.

**Top remaining issues** (the judge's, with this lane's note):
1. **Creature-model reuse across frames.** It is mostly the player's companion; the walker's stow does not always take.
2. **The night exposure floor at distance.** This is chapter lighting, outside the lure lane.
3. **The Hall label over grass when the alpha is occluded.** That follows from `no_depth_test`; the judge suggests culling the label when the alpha is hidden.

**Doss re-judges (the same judge method, Doss frames only):**
- **Banner_1 pennant beside the perch:** judged with the full set above; PASS (marginal).
- **Banner_2 at the same spot: FAIL.** The pennant sat behind the signal column from the loop, and the judge read the column as a rendering artifact over it.
- **Banner_2 moved about 14 m across the loop's line of sight to (-31,4171): PASS (marginal).** Bars A/B NO, for the global haze and saturation.
- The frames in `lure-judge-f/doss_*` are from this last render (`lure0/doss-f`).

**Walker note (two-strike rule, disclosed):** the companion recall before a lure frame does not always take. It failed at herd 55 m, the Doss 57 m glance and the vault door frame. After two harness strikes it is disclosed rather than chased.
