# F13#5 Veilfall read: after_r2, code-blind judge

- **Frames:** the 10 JPGs in `after_r2/`, captured at c22a959 (the r2 iteration). They predate the fall-lateral and live-foam fixes in PR #309.
- **Judge:** a code-blind sub-agent. It was given only the frames, `docs/reference/tetherbound-meadows-keyart.png` and `docs/reference/palworld-0*.jpg`. It was not told what changed. It ran the rubric from `.claude/skills/visual-judge`.
- **Verdict:** A (key-art world): **No**. B (same kind of game as Palworld): **partly yes**.
- **F13#5 stays PARTIAL.**
  - Only one stand reads as a waterfall-veiled landmark: near-arrival at night.
  - In every still, the currents are not visible as lanes.

The critique follows. It is the judge's findings, lightly condensed; every frame-specific defect is kept.

---

## Ranked gaps against the references
1. **The landmark is a smooth, untextured primitive** (veilfall-mid-salt-crown-day, current-sluice-veilfall-day). It is a symmetric bell with painted stripes. It has no dark wet rock, no lip where water drops, no mist and no plunge pool. The references use craggy, layered silhouettes with a clear summit.
2. **Large empty ground planes with no set-dressing** (veilfall-far-first-shore-day, veilfall-mid-salt-crown-day). Saturated orange sand with noise fills 35–45% of each frame and is the loudest thing on screen.
3. **Placeholder geometry and flat midday light**:
   - the untextured tan box in current-sluice-veilfall-day/night;
   - the light concrete-grey gorge in veilfall-near-arrival-day;
   - the "08:00" frames have no warm, low morning sun.

## Per stand: does the mountain read as a waterfall-veiled landmark?
| Stand | Reads? |
|---|---|
| Far (First Shore), day | No: a small pale dome, read as a snowcap or igloo; the fall columns can't be resolved |
| Far (First Shore), night | No: a glowing pale dome |
| Far (current-first-shore-reedhaven), day | Barely: faint white marks on a small grey cone |
| Far (current-first-shore-reedhaven), night | No |
| Mid (Salt Crown), day | Weakly: the stripes read as snow gullies or ski runs, not falling water |
| Mid (Salt Crown), night | No: a luminous ice-blue bell, like a glacier |
| Sluice, day | Partly: one stepped white drop reads as a fall; the rest read as painted stripes |
| Sluice, night | No: an ice-blue mass |
| Near (arrival), day | Weakly: a thin sheet between light-grey concrete walls |
| Near (arrival), night | **Yes, the best in the set:** a lit sheet in a dark gorge, with the camp |

**Currents:** no frame shows a foam lane with visible direction or length (current-first-shore-reedhaven day/night, current-sluice-veilfall day/night). The faint dashes read as specular glints or moonglint.

## Other defects by frame
- **Night, all frames:** Veilfall is the brightest large object, lit a luminous ice-blue, and the blue streaks vanish. The clouds are soot-black on a lighter sky.
- **veilfall-mid-salt-crown-\*:**
  - the mountain base cuts off in a hard line on the sea;
  - there is little aerial perspective, so the 4 km mountain has the same contrast as a 200 m island;
  - glowing white orbs float on the water;
  - pale switchback bands on the green island look like texture seams;
  - the jade monolith matches the grass hue.
- **current-sluice-veilfall-\*:**
  - the foreground grass ribbons are as tall as the trainer and clip through the creatures and the player;
  - the rock stacks on the mountain face are uniform cylinders with green tufts;
  - the tan box is present;
  - the cream creature drifts toward salmon under the night grade (a minor red-range note).
- **veilfall-near-arrival-\*:**
  - the grass is a hard-edged rectangle on the sand;
  - a floating rock block with a hard shadow slab;
  - tree shadows fall on the cliffs with no trees visible;
  - the cliff texture is banded or stretched;
  - a creature is half-sunk into the ground (night);
  - the quest panel still says "Meet Pell at First Shore".
- **First Shore frames:**
  - the fence rails cross each other and the posts, with stretched wood;
  - the doorway opening is a flat teal plane;
  - the paving slabs are flat quads;
  - the distant island trees are evenly spaced singles.
- **HUD:**
  - "FOOD" is gold on tan over sand, and the time readout is grey on cloud: both have low contrast;
  - the location title is lost on a light cliff;
  - the minimap is a blank tan square.
- **Scale:** creatures are slightly taller than the trainer (within the rule); the sluice grass reads giant.

## Bar answers
- **A: No.** The trainer, the sky, the teal water and the night camp fit the key art. Sand, grey primitives, flat light and the ice-lit night mountain sink it.
- **B: Partly yes.** The camera, the HUD layout and creatures beside the trainer signal the genre. The density and materials read as an early prototype.

## Fixable by changing the scene (Tidewake-lane work)
- Darken the mountain rock to near-black with a wet sheen, brighten the fall columns, and stop it outshining the foreground at night.
- Add a mist or spray skirt and a foam ring or plunge pool at the base, plus aerial haze that scales with distance.
- Desaturate and tone the sand, and scatter tufts, stones, driftwood and shells.
- Re-frame the far stand.
- Give "08:00" a warm, low key light, and make night clouds lighter or rim-lit.
- **Cleanup:**
  - texture or remove the tan box (X04 dock dressing);
  - fix the half-buried creature, the fence rail overlaps and the floating block;
  - lower the sluice grass near the camera.
- HUD contrast plates (X03).
- Make the current lanes oriented white streak bands with more contrast.

## Needs art not in the build
- A sculpted, craggy Veilfall mesh with lips and a summit (already recorded in JUDGE.md).
- A waterfall sheet mesh with a flow texture, plus spray particles for mid and far range.
- A wet dark rock and cliff material family with moss variation.
- Coastal grove clusters, reeds and driftwood for the island rims.
