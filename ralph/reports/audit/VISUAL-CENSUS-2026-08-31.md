# Visual census — 2026-08-31

**Lane:** `ralph/VISUAL-CENSUS-2026-08-31`, branched from `origin/main`.
**Scope rule this lane ran under:** *diagnosis and cataloguing only.* No game
code, data, shader, asset or config was changed. The only files this branch
touches are this report, `BACKLOG-FROM-AUDIT-2026-08-31.md`, and the committed
contact sheets under `VISUAL-CENSUS-2026-08-31-shots/`.

## Method

`ralph/conventions.md` — *"Visual-affecting work needs a blind pass, not a
look"* — plus `.claude/skills/visual-judge`. The skill is normally pointed at
one change; here its machinery is pointed at the whole game, one subject area
at a time.

Per subject area:

1. Real frames rendered from the actual build with the existing `tools/`
   capture library (no new capture scripts were written except where noted).
2. Frames assembled into one contact sheet with `tools/contact_sheet.gd`.
3. A **fresh sub-agent per round**, given only the sheet, the individual
   frames, `docs/reference/` and the `visual-judge` rubric. Told nothing about
   what the frames depict beyond what is in them, nothing about what changed,
   nothing about what answer was hoped for, and explicitly forbidden from
   reading any other file in the repo.
4. Convergence per the convention's own stopping rule, not a fixed count.

**Capture invocation** (`ralph/conventions.md`'s art-pipeline trap — never
`--headless` with a real rendering driver):

    xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
      --rendering-driver opengl3 --resolution 1280x720 --script tools/<capture>.gd

Godot 4.7.stable, Compatibility renderer, llvmpipe software rendering, in a
fresh container with the import cache built from scratch
(`godot --headless --path . --import`, ~30 min).

**Honest limits, which belong in every judgement below.** Compatibility is
what the game ships (D01), so this is the same pipeline players see, but it is
software-rendered here: no SSAO, no volumetric fog, shadows implemented
differently, and frame times meaningless. Composition, silhouette, colour
relationships, scale and material read are trustworthy. Fine lighting
judgements and anything about performance are not, and are not made.

_(findings follow)_
