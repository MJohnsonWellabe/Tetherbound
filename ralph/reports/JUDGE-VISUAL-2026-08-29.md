# VISUAL JUDGE — 2026-08-29

Blind verdict pass over the visual work that landed on `ralph/LAND-0829A`
(judged at `1656a71`). Frames were rendered and judged **before** reading any
lane report, handover, or fix-describing commit message; the reconciliation
section at the end was written after. Frames live beside this file in
`ralph/reports/judge-visual-2026-08-29/`.

Renderer caveat (per `tools/survey.sh` and D06): Compatibility renderer under
llvmpipe software GL — trustworthy for composition, silhouette, colour, scale
and texture read; not for fine lighting/post quality. Since RB4/D01 the game
ships Compatibility, so these are the shipped pipeline's frames.

Capture note: the castle approach frame here uses a **corrected** stand.
`tools/capture_t1arch_all.gd`'s `C-01-approach-gate` offset
`Vector3(2.0, 1.8, 24.0)` sits *inside* the plinth footprint (local z runs
−10..+34, gate/ramp exit toward −z, ramp foot ≈ z −21 — see
`scripts/world/landmark.gd`). My variant `tools/_judge_capture_arch_0829.gd`
stands at local z −40, south of the ramp foot, and also hands Terrain3D the
capture camera so each site renders streamed ground rather than parked-rig LOD.

Commands used:

```
godot --headless --path . --import
xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
  --rendering-driver opengl3 --resolution 1280x800 \
  --script tools/_judge_capture_arch_0829.gd          # frames 1–4
# (world subjects follow the same invocation with the named tool)
```

---

## 1. Castle — exterior, approach, near the walls

Frames: `C-01-approach-gate-FIXED.png`, `C-02-silhouette-far.png`,
`C-03-corner-close.png`, `C-04-wall-close-ground.png`.

**Verdict: BAD.** The owner called the castle BAD before this round; from
these frames that verdict stands. It has a complete, symmetric silhouette —
towers, keep, crenellations, flags, a real ramp with lit torch posts and camp
props at the foot — but it reads as a white toy fort on a concrete display
base, not as the "grounded, military, believable" castle on the owner's own
board.

What specifically reads wrong:

- **Maquette walls.** The curtain walls are large identical near-white
  modules with visible vertical seams and bevelled edges (loudest in
  `C-03`/`C-04`). No stone coursing at any distance, no arrow slits or
  windows along entire wall runs, no weathering gradient from base to
  parapet. The only surface variation is metre-scale blotchy stain noise
  that reads as smudged plaster, not masonry.
- **The plinth.** A featureless mid-grey box with one trim line — poured
  concrete. Its base is a dead-straight line meeting undulating grass with
  no transition (no footing, rubble, or grade change), and in `C-02` and
  under the near corner in `C-03` the plinth visibly **floats** — open
  shadow gap between its underside and the ground.
- **Scale disagreement on the wall walk.** The mid-wall turrets are
  miniature — roughly a third the girth of the corner towers with their own
  full crenellation sets, so they read as sandcastle decorations
  (`C-03`). The witch-hat roofs are small and cartoonish against the wall
  mass.
- **Placeholder masses in the hero vista.** Directly beside the castle,
  giant untextured boxes intrude into every exterior frame: a light-grey
  blank slab on the right of `C-01`/`C-04`, and the stronghold's near-black
  mega-box with a flat untextured tan top on the left of `C-02`. The hero
  landmark shares every composition with what looks like unfinished
  blockout.
- **Value structure.** Walls are one bright value top to bottom; the frame
  splits into white shape / green smear / blue sky with nothing tying the
  building to the ground plane.

Guess at cause (flagged as guess): the kit modules share a single
unweathered albedo with baked AO blotches at the wrong scale; the plinth is
a box ground-snapped at one probe point so sloping terrain opens a gap on
the far side; the neighbouring boxes are the stronghold shell's unmaterialed
upper masses.

## 2. Stronghold — exterior and approach

Frames: `S-ext-01-approach-ramp-foot.png`, `S-ext-02-flank-wide.png`.

**Verdict: BAD.** Owner said BAD; still BAD, and from the flank it is the
worst-reading structure in the world right now.

- **From the flank it is a featureless near-black box.** Under a full day
  sky the wall texture crushes to void — no roofline articulation beyond one
  step, no openings, no banners, no machinery, no propaganda, nothing that
  says "occupied military works" (`S-ext-02`). It reads as an unlit
  warehouse dropped on the meadow.
- **The approach is one texture swatch.** The entire lower half of
  `S-ext-01` is a single cobble material — puffy, clay-like cobbles with
  strong bevel highlights — and the wall ahead is a flat slab of the *same
  kind* of cobble texture at 2–3× the scale, so wall stones read 1–2 m
  wide. The two scales collide at the junction. The gate is a plain
  rectangular hole with no gatehouse, frame, reveal or depth.
- **What genuinely works:** the Team Tether pylon line (`S-ext-02` left) —
  distinct silhouette, cyan crystal accent, correctly grounded, reads as
  danger-faction tech at meadow scale. The keyart's stronghold language
  (stone facade, banners, scaffolds, apparatus) is exactly what the pylons
  have and the building lacks.

Guess at cause (guess): the exterior is probe-built structural volume with
a single dark tiling material and no exterior dressing/articulation pass;
albedo dark enough that llvmpipe's flat sky term leaves no legible shading.

## 3. Burrow Warrens — the mound / exterior

Frames: `W-ext-01-knoll-from-outside.png`, `W-ext-02-knoll-from-outside.png`,
`W-ext-03-mouth-door.png`.

**Verdict: BAD.** Owner said BAD; still BAD. The re-sited knoll *composition*
is defensible — a rock outcrop with a built mouth could read as intended —
but the materials sink it.

- **Three unrelated rock languages in one frame** (`W-ext-03`): noisy
  speckled-granite mega-boulders; smooth mint-green faceted low-poly rocks
  that read as a different game's asset pack; and a plain grey concrete
  walk slab. Nothing shares hue, roughness or detail frequency.
- **Boulders read as chamfered cubes.** The upper courses of the knoll are
  visibly box-shaped with bevelled corners (`W-ext-02` top row), stacked at
  similar sizes; and every face carries the same high-frequency granite
  noise with no macro variation, so the mass reads as static rather than
  stone. On distant faces the noise aliases into literal checkerboard pixel
  patches (top-left and right cube face of `W-ext-02`).
- **The mouth facade** is a flat wall with a rectangular hole; the facade
  texture streaks/stretches vertically near the top (`W-ext-03`), and the
  concrete slab path sits on the grass with no edge blend.
- **Vegetation confetti fights the rock.** Hyper-saturated lime aloe-blade
  grass clumps, plastic-bright ferns and an oversized purple flower prop
  (petals ~40 cm against the 1.8 m-trainer ruler) clash with the muted
  ground smear under them.

Guess at cause (guess): knoll assembled from generic boulder meshes at
different scales sharing one granite material (so UV density varies per
boulder); mossy rocks and ferns come from a stylised low-poly pack and were
never re-tinted toward the knoll's palette.

## 4. Burrow Warrens — interior

Frames: `W-int-01-den-wide.png`, `W-int-02-hall.png`.

**Verdict: GOOD — the owner's positive verdict holds; protect it.** The
interior reads as one coherent authored place: stained dirt floor, dark
timber beams, pilaster rhythm on the walls, warm doorway light against cool
dark, resident creatures inhabiting the space, dressing (crate, grain sack,
barrel) at believable scale. This is the only architecture subject where
material, value structure and story agree.

Watch items (not failures):

- The guardian's dark shell merges into the shadowed back wall
  (`W-int-01`) — its silhouette is nearly lost at the exact moment the room
  wants you to see it. A rim of warmer bounce or a lighter back wall behind
  the den would protect the read.
- In `W-int-02` a resident creature bisects the camera frustum
  (bottom-right camo blob) and another crowds the right edge; residents
  wander close enough to swallow the camera in doorways.
- Walls and ceiling share the same granite-noise material, so surfaces
  separate by geometry only; it holds at this light level but is the same
  noise-texture economy that fails outside.

## 5. Open Meadows ground and grass, near to far — PENDING RENDER
## 6. Water and shorelines — PENDING RENDER
## 7. Sky and sun across the day cycle — PENDING RENDER
## 8. Terrain macro composition / landmarks — PENDING RENDER

(Verdicts land in this file as each capture completes; the render queue is
`_capture_ground_and_sky.gd`, `capture_water.gd`,
`_capture_day_night_transition.gd`, `_capture_far_panels.gd`, `survey.sh`.)

---

## Lane-report reconciliation — WRITTEN LAST, after all verdicts

(Deliberately empty until every verdict above is final.)
