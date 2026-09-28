# Doss lure, set E (F03#0)

- **Placement change:** Doss, his bank perch and his signal fire moved about 15 m south-west to the ridge crest's road-facing edge. Doss is at (-22,4166), facing -74, with the perch at (-26,4163) and the fire at (-23.5,4160.5). The camp is 56 m off the river loop. At the old site (-19,4180), on the plateau behind the crest, the crest hid the camp until the prompt (judge D).
- **Probe:**
  - `tests/probe_lure_road_visibility.gd --camp-grid=doss:-22,4166,0,1 --camp-margin=0.25`: 5 loop samples, nearest 56 m, see both the ground (+0.3 m) and body height.
  - `--six`: the figure is clear from the loop at 56-141 m (was 64-154 m); the column at 53-157 m.
- **Run:** local render (see `../RENDER.txt`) at the lane's working tree before commit, `--activity=doss --off-road-cost=10`, from the disclosed Gate F fixture `S07-exit-band3`. PASS: the prompt was offered.
- **Frames:**
  - `doss_05` and `doss_06` are road glances at 60 m and 57 m: the column rises over the crest, with fire, perch and figure at its base.
  - `doss_07` is first readable at 36 m.
  - `doss_09` is the prompt.
