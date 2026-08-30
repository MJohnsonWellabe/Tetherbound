# T1-WORLD evidence

`/shots/` is gitignored (`.gitignore:45`), so the frames this verdict rests on
would otherwise not survive the branch. These are the load-bearing ones,
exported as JPEG at 1800px — the same format the project's own reference boards
use (`docs/reference/palworld-0*.jpg`), for the same reason: the full set is
316MB of PNG and nothing here is being judged at the pixel level.

The full 75-frame round-1 set is reproducible from this branch with:

```
xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
  --rendering-driver opengl3 --resolution 1280x800 \
  --script tools/_capture_ground_and_sky.gd -- --vista --landmarks --elevated=24
tools/stage_world_board_sheets.sh
```

Roughly 75 minutes on a 4-core container under llvmpipe — the per-shot cost is
dominated by viewport readback and PNG encode, not by rendering.

| file | what it is |
|---|---|
| `board-vista-day.jpg` | the whole board, eye level, all seven stands under one sun — the frame set section J's question is actually asked of |
| `board-vista-night.jpg` | the same seven at night |
| `board-high-day.jpg` | the same seven elevated; this is the sheet the aerial-perspective finding came from |
| `fix-before.jpg` / `fix-after.jpg` | three stands, nine matched frames, before and after. NOTE: the "after" here is the **intermediate** round the blind re-judge measured, not the final state — its scatter settings were reverted and its night floor was corrected afterwards. Kept because the re-judge's numbers refer to exactly these two sheets. |
| `warrens-day.jpg` | the Warrens mound, lit — shows the material is fine |
| `warrens-golden.jpg` | the same mound as near-pure silhouette, which is the frame that proves the remaining defect is shape and not texture |
| `npc-night-before.jpg` | the trainer NPC self-lit at night beside a correctly dark player |
| `npc-night-after.jpg` | the same frame after the emission floor was put on the clock, at its final 0.5 night value (the first attempt, 0.25, clipped 59% of the coat to literal black and was corrected) |

Every frame here passed `tools/capture_check.gd` at the shutter. One frame of
the original 75 did not (`water-02-river-grazing`, shot from below the terrain);
it was fixed and re-rendered and is not among these.
