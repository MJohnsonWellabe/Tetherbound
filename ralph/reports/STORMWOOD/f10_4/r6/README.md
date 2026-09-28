# F10#4 round 6: forest readability re-judged on the ordinary Deepwood road

**Why this round.** The r5 strict re-check returned NOT MET on the forest clause. The r5 stand, off-road in the Deepwood heart and looking north, showed open plain through a ring of trunks, so it read as "edge of a wood". Rod line (YES) and restored sky (YES where sky shows; under the canopy, lighter rain and no lightning as the owner ruling specifies) were accepted at r5.

**New stands.** Both are rendered from committed game code 29edb0cd (`RENDER.txt`, `frames_r6.json`):
- `forest_road` stands on deepwood_road inside the deepwood_heart/deepwood_west dense stands. This is the view a player walking the chapter route has.
- `forest_heart_west` stands off-road in deepwood_heart.

**Code-blind forest judge.** `JUDGE_forest.md`; three shuffled views, key in `forest_blind_key.json`.

| View | Verdict |
|---|---|
| forest_road (Q) | **INSIDE DEEP FOREST (marginal)**: trunk walls both sides, canopy about 90% closed; the only opening is the road's far exit |
| forest_heart_west (P) | EDGE OF WOOD: purple sky band through the gaps at eye level; the stand is about two trunks deep |
| r5 forest heart, north (R) | EDGE OF WOOD: open field and a pale plain under the crowns |

**Storm states at forest_road.**
- Break is easily told from Calm (heavy slanted rain, darker; no bolt visible under the canopy).
- The aftermath reads as the same place, with the purple sky, lighter rain and no lightning. The judge notes it is brighter and greener than Calm, and that the pylon crystals go dark. Those are the existing aftermath values (`stormwood_surge.json` `_why_f10_4_restored_sky`) and the rod line's authored aftermath.
- The trainer is findable in all three views.

**Claim.** The forest reads as deep forest from the ordinary route.
- Off-road, the dense stands are too shallow at eye level: about two trunks deep, with plain or sky showing through. This is set-dressing density (`stormwood_vegetation.json` `dense_stands` spacing and depth, which needs a scatter re-bake). It is recorded as a Phase 2 catalog item.
- Also routed to Phase 2: understory, materials, the Glass Field scorch, the Stormheart hero tree, the giant stand, the cottage's red roof and the road-current look.

**Shortcuts disclosed:** one debug teleport per stand, the hour pinned, the surge clock pinned to phase start plus 2 s, the aftermath set by flag, the HUD hidden, and software GL.
