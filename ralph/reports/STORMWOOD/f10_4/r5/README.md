# F10#4 round 5: forest, rod line and restored-sky readability (Phase 1)

F10#4 (ACCEPTANCE §6.1 F10, card S2): the forest, rod line and aftermath views pass the normal-camera matrix: lighter rain, no lightning, scars. Under the Phase 1 owner ruling (2026-09-28) this criterion closes on its functional and readability clauses. The Bars A/B clause moves to the Phase 2 catalog. So do the scorched Glass Field (flag off) and the Stormheart hero tree (giant-trunk views), per CLAUDE_START_HERE §4.

**Frames:** `*_calm.jpg`, `*_break.jpg` and `*_aftermath_calm.jpg` for the forest, giant, glass, rod_line and stormheart stands. Render details are in `RENDER.txt` and staging per frame in `frames_r5.json`.

**Judge:** `JUDGE.md` is a fresh code-blind judge, reading readability only.

| Readability read | Result | Frames |
|---|---|---|
| Forest reads as deep old storm forest | Split verdicts, below | forest_* |
| Rod line reads as a line that leads somewhere | **YES** | rod_line_*: three pylons joined by cable recede along the road |
| Aftermath: same place, lighter rain, no lightning, scars and structures remain, distinct from the storm | **YES** where sky shows; lighter rain and no lightning under the canopy | glass, rod_line and stormheart aftermath pass outright |
| Break distinguishable from Calm | **YES** in all five rows | all |
| Trainer findable | **YES** in every frame at full size | the giant row is poor behind a foreground shrub |

**Forest.**
- Both judges who read the forest stand agree the big trunks and closed canopy work:
  - r3 (`../r3/JUDGE.md`) said YES: "a genuinely closed canopy … reads as enclosed woodland, not a lawn".
  - r5 said NO. Its reasons are a missing understory (ferns, roots, fungi, deadfall), the Stormwood materials (moss uplight, copper, black pools) and the open plain seen between trunks.
- Those are Bars A/B set-dressing and material gaps. They go to the Phase 2 catalog, not to a Phase 1 blocker.

**Aftermath under the canopy.**
- The owner ruling (WO-F10-08, recorded in `data/config/stormwood_surge.json` `_comment_aftermath`) says: "Stormwood stays purple after the Long Storm is broken; the aftermath shows only through lighter rain, no lightning and the scars".
- The judge confirms that forest_aftermath_calm and giant_aftermath_calm show much less rain and no lightning. It found them close to their Calm frames at sheet size, which is what that ruling specifies under a closed canopy.
- One round this pass tried to lift the aftermath forest floor, with a stronger key and a different shadow floor:
  - A hard shadow floor darkened the shaded stand.
  - A soft one made it read as a brighter, greener day, which contradicts the ruling.
  - Both were reverted. Frames are not kept, and no change ships.

**Recorded for Phase 2 (Codex catalog).**
- Forest understory and materials.
- The giant-trunk subject and the foreground shrub at the giant stand.
- Glass-scar ground treatment.
- The Stormheart hero form.
- The red roof on the cottage at the Stormheart base.
- The road-current squiggles reading as a UI guide line.
- A flower stem that renders as two white lines in giant_aftermath_calm.

**Shortcuts disclosed:** one debug teleport per stand, the hour pinned, the surge clock pinned to the phase start plus 2 s, the aftermath set by the `stormwood:long_storm_ended` flag, the HUD hidden, and software GL (llvmpipe).
