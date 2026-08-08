# The character art pipeline

Turns the reference sheets in `docs/art/reference/` into game-ready creatures.
Implements `TETHERBOUND_3D_ART_PIPELINE.md`; see `docs/decisions/D11` for why it
is scripts rather than MCP servers.

## Once per machine

```bash
tools/art_pipeline/setup.sh
```

Fetches Blender 4.2.9 LTS and Godot 4.7-stable into `~/.cache/tetherbound-art/`.
No root, nothing installed, nothing committed. Idempotent.

Rendering also needs a framebuffer and GL, which does need root:

```bash
sudo apt-get install -y xvfb libegl1 libgl1
```

## The loop, in order

### 1. Reference inputs — once, or after a sheet is redrawn

```bash
tools/art_pipeline/crop_views.py --check
```

Cuts the four-view turnaround out of each production sheet into
`assets/pals/tetherbound/<species>/reference/{front,side,back,three_quarter}.png`,
one figure per image at a shared scale. Check `docs/art/reference_views.png`
before trusting the output. Bands and centres are in `views.json`; `--grid`
writes coordinate overlays for retuning them.

### 2. Generate candidates — needs `MESHY_API_KEY`

Multi-image-to-3D from the crops above. **Three candidates, cheap tier first**
(§25). Downloads land in `assets_raw/`, which is gitignored.

### 3. Inspect every candidate

```bash
BLENDER=~/.cache/tetherbound-art/blender-4.2.9-linux-x64/blender
$BLENDER --background --python tools/art_pipeline/blender/inspect_glb.py \
    -- assets_raw/terrapup/a/model.glb --out shots/candidates/a.json
```

The §11 checklist as numbers: triangles, non-manifold edges, duplicate vertices,
loose geometry, debris islands, flipped normals, UV stretch, quad fraction,
world-space bounds, armature and clips. **It can only reject, never approve** —
a clean report on the wrong animal is still the wrong animal.

### 4. Render every candidate from the same camera

```bash
$BLENDER --background --python tools/art_pipeline/blender/turntable.py \
    -- assets_raw/terrapup/a/model.glb --out shots/candidates/terrapup-a
```

Orthographic, flat-lit, on a ground plane, four angles matching the crops. The
shared camera is the whole point: two candidates shot from slightly different
angles cannot be compared on proportion.

### 5. Compare and score

```bash
tools/art_pipeline/compare_sheet.py terrapup \
    --candidate a=shots/candidates/terrapup-a \
    --candidate b=shots/candidates/terrapup-b \
    --candidate c=shots/candidates/terrapup-c
```

Concept row on top, candidates below, plus a Markdown scorecard with a **hard
fail column**. §9: do not hide failures behind a total.

### 6. Clean up, material, rig, animate

Blender, on the winner only (§25 — do not rig three bad candidates). Re-run
step 3 afterwards and keep both reports for the production record.

### 7. Wire it into the game

Point `data/pals/species.json` at the exported GLB and map the clip names.
`pal_body._fit()` scales it to the gameplay collider; watch for the
footprint-allowance warning.

### 8. Validate in the engine, not in Blender

```bash
xvfb-run -a -s "-screen 0 1280x720x24" ~/.cache/tetherbound-art/godot \
    --path . --rendering-driver opengl3 --resolution 1280x720 \
    --script tools/validate_asset.gd -- terrapup
```

Eight frames: two lighting conditions × four gameplay distances, with a 1.8 m
scale post beside the creature. §16's questions — do the eyes read, do the limbs
separate, is an attack legible, is the signature feature visible at combat
distance — are asked of these frames, not of the Blender renders.

### 9. Then the blind critic

`tools/survey.sh` and the `visual-judge` skill, unchanged. D10 forbids it going
soft on a sourced or generated asset.

## What is not here

Generation itself, until `MESHY_API_KEY` exists. Everything above runs without
it, and step 3 onward can be proved against any existing model —
`assets/pals/plumberry/bruno-the-bear.glb` is what the harness was built against.
