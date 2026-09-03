# HANDOVER — T1-HALL-BUILD, 2026-08-30

Branch: `ralph/T1-HALL-BUILD`, off `origin/main` @ `a97f3e84`, pushed
(`2ca9b48b`). Working tree clean, nothing uncommitted.

## 1. What I was asked, and where I got to

Build the owner's merged Meadows Hall (castle + stronghold become one
location) per `ralph/reports/HALL_DESIGN_2026-08-30.md`, a design a separate
Sonnet/Fable pass already produced. The brief was explicit and non-skippable:
**prove the design's §5 material/palette scheme on real rendered pixels
before touching any geometry**, because the owner had just said "geometry is
probably fine but the coloring is not good" and this exact class of mistake
(reasoning from numbers instead of looking) had already burned two prior
lanes.

**I completed exactly that first step and stopped where the brief told me
to stop** — before any massing/geometry work. Nothing beyond the palette
proof was started.

## 2. What I did

- Read, in full, everything the brief listed as required reading: CLAUDE.md,
  `docs/owner-direction/README.md` + `TETHERBOUND_VISUAL_STUNNING_PASS.md`
  §§12/16/18/21, `HALL_DESIGN_2026-08-30.md` (all 13 sections),
  its handover, `JUDGE-VISUAL-2026-08-29.md` subjects 1/2/8,
  `OWNER_FEEDBACK_2026-08-29_BUILDINGS.md`, and
  `handover-T1-ARCH-STRONGHOLD-2026-08-29.md` §5.
- Created `ralph/T1-HALL-BUILD` off `origin/main`.
- Applied the design's §5 material scheme to the EXISTING castle/works
  geometry, changing nothing else:
  - `landmark.gd::_weather_castle` — castle kit's `LightRock*`/`DarkRock*`
    slots now carry the works' own real `T_UnevenBrick` photo texture
    (triplanar @ 0.28, matching `stronghold.gd`'s own measured tiling)
    instead of a generated 96px noise multiply. `Black*` stays flat (no
    texture), per the design's own table.
  - `building_prefabs.json`'s `castle` retint re-tuned against that
    texture: `LightRock`→`#f2e9da`, `DarkRock`→`#c4b39e`, `Black`→`#332c24`,
    `Celing`/`LightWood`→`#6f4f33`, `Banner` unchanged.
  - `stronghold.json` gained `site.stone_light = "#9c9083"` (the works'
    exterior wall tone).
- Installed Godot 4.7, ran the project import, rendered the judge's own
  stands (`tools/_judge_capture_arch_0829.gd`, unmodified) under
  `xvfb-run` + `opengl3`.
- Wrote `tools/_sample_hall_palette.py` — tiles a by-eye-verified clean-
  stone region per frame into non-overlapping 64px cells (the design's own
  patch size) and reports every cell, not one hand-picked box.
- Measured, and reported the actual numbers whether or not they passed
  (full writeup: `ralph/reports/T1-HALL-BUILD-PALETTE-PROOF-2026-08-30.md`;
  frames in `ralph/reports/T1-HALL-BUILD/shots/` since repo-root `/shots/`
  is gitignored).
- Committed (`068bee0d` the code, `2ca9b48b` the proof + frames) and pushed.

## 3. The palette verdict (short form — full numbers in the proof doc)

**Value: fixed.** Every lit castle-wall cell measured lands at luma 151–174,
RGB ≈(165–188,150–173,120–147) — inside the design's own [150,185] target
band, replacing the judge's measured off-white (212,203,185). Confirmed by
eye in the rendered frames (`C-03-corner-close.png`,
`C-04-wall-close-ground.png`), not just by number.

**Std-dev (coursing contrast): misses the design's own bar at its own patch
size.** Four independent 64px lit-wall cells (every cell in each clean
region reported, none cherry-picked) measure 26.6–34.5 — under the design's
≥35 kill criterion, and in the SAME range as the design doc's own quoted
prior FAILING state (28.1). Widening the same wall to 128px cells measures
41–43, so the texture carries real low-frequency variation; a 64px cell is
apparently sometimes smaller than one stone's own highlight/shadow period in
these frames. Flagged as a **disagreement with the design's own kill-
criteria cell size** (§5), not silently tuned past.

**Two findings not concluded as palette failures**, both traced to a
confirmed, pre-existing confound: `art.json`'s `sun.yaw_deg` is 140 (south
sky, exactly what design §12.1 already flags) and the CURRENT castle/works
geometry has not been re-sited yet, so some faces in the current stands are
backlit for reasons unrelated to this pass's colour work. One castle flank
(C-04) and the works exterior tone both read darker than the design's own
targets in these specific stands; both need re-measuring once the re-site
(design §9 step 1) and the new H-03 stand exist.

## 4. Done vs open

**Done, verified:**
- Palette proof rendered, measured, reported, committed, pushed.
- Both code changes (castle texture swap, castle retint, works
  `stone_light`) are live and produced the frames the numbers above
  describe.

**Explicitly NOT started** (per the brief's own gate — "Stop there and
report before starting geometry. The palette verdict may change the
design."):
- Re-siting (`stronghold.json` `site.at`/`yaw_deg`/`ramp_run`).
- The `meadows_hall` massing prefab, openings, elevations/walkways, turret
  girth, gate frame.
- Retiring the castle landmark.
- The occupation layer (cable landing, banners, hardware variation, relay
  hub, brazier port).
- The horizon boxes, the approach-bearing re-derivation beyond what the
  design already worked out on paper.
- Performance before/after measurement (`tools/perf_render_stats.gd`) —
  only the design doc's own baseline exists so far, not an after-number,
  because nothing structural has been built yet.
- New capture stands (`tools/_judge_capture_hall.gd`, design §10) — not
  authored; the design explicitly assigns that to "the evidence lane, not
  this lane."

## 5. What I learned that is NOT visible in the diff

1. **The design's 64px kill-criteria cell may be miscalibrated, not just
   the palette.** This is a genuinely new finding, not a restatement of
   the design's own §12 corrections: the design assumed a 64px patch would
   reliably separate "real coursing" from "flat colour with noise" (its
   own quoted failure number, 28.1 std-dev, came from the OLD generated-
   noise texture). But the REAL photographic texture, at the correct
   tiling scale the design itself specifies (0.28, matching the works),
   ALSO lands in the high-20s/low-30s at 64px — statistically close to
   the number the design was trying to beat. It is not that the texture
   failed; it is that a stone's own highlight/shadow period in these
   frames is wider than 64px, so a cell can land mostly on one stone
   face. This only shows up if someone actually measures per-cell rather
   than trusting the design's arithmetic (which is itself a good example
   of the exact "arithmetic instead of eyes" failure mode the brief
   warned about, this time in the design's own acceptance test rather
   than in an implementer's retint choice).
2. **The sun-move confound is real and already touches the CURRENT
   (unmoved) geometry, not just the future re-sited Hall.** I did not
   expect this — I assumed the sun-move issue (§12.1) was purely a
   forward-looking cost of the yaw re-derivation. It turned out the
   EXISTING castle and works, at their EXISTING orientation, already have
   faces reading unexpectedly dark in these renders, for the same
   sun-yaw-140 reason. That means some of the "still dark/still bad"
   reads in the judge's ORIGINAL frames may be partly attributable to the
   sun move rather than purely to material/geometry defects the design
   diagnosed — worth keeping in mind when re-reading old judge verdicts
   against frames rendered before vs after `art.json`'s sun moved.
3. **The render/measure loop is fast once the environment is warm.** Godot
   install (~2 min this session, a fast connection), import (~4 min this
   run, faster than the brief's quoted 6–8), and the judge's own 11-frame
   capture (~6 min, faster than the brief's quoted 12–25) all came in
   under the brief's own estimates. A future lane doing several
   iterate/re-render cycles on this branch should budget less idle time
   than the brief implies, at least on this environment.
4. **`_apply_retint` (building_prefabs.gd) still has no `uv1_scale`/
   `normal_texture` override path** — it only swaps `albedo_texture`,
   `emission`, and `metallic` per the existing dict shape. I did not need
   it for this pass (the texture/tiling change went directly into
   `landmark.gd::_weather_castle`, which already owned that surface), but
   whoever builds the `meadows_hall` prefab's occupation layer (design §6,
   brass fittings etc.) should check whether any of those retints need a
   texture-scale override `_apply_retint` cannot express yet.

## 6. Disagreements with the design, stated loudly

- **§5's 64px kill-criteria cell size does not reliably clear its own
  ≥35 std-dev bar even with the correct texture and correct tiling
  scale**, measured across four independent non-cherry-picked cells
  (26.6–34.5, vs the design's own quoted prior-failure number of 28.1).
  128px cells on the identical wall clear it (41–43). This is the single
  most load-bearing finding in this handover: the acceptance test itself,
  not just the material choice, may need adjusting before anyone declares
  the coursing "passed." I did not change the acceptance criteria myself
  — that is not this lane's call — I measured, reported both cell sizes,
  and flagged the disagreement per the brief's own instruction to do so
  "with evidence."
- No other disagreement with the design's §5 mechanism. The value-ladder
  logic, the texture-reuse argument, and the "flat colour cannot produce
  coursing" diagnosis all held up under direct measurement.

## 7. File footprint

Changed, all committed:
- `scripts/world/landmark.gd` — `_weather_castle` now sets a real
  `T_UnevenBrick` albedo/normal/roughness texture (triplanar @ 0.28)
  instead of generating one; dead generated-texture code
  (`_weather_texture`, its consts, `_weather_texture_cache`) removed since
  nothing calls it any more.
- `data/config/building_prefabs.json` — `castle` prefab's `retint` block
  re-tuned (6 colour values) with a new `_why_retint_hall_design` comment
  recording the reasoning and the kill criteria.
- `data/config/stronghold.json` — added `site.stone_light` with a new
  `_comment_stone_light`.
- `tools/_sample_hall_palette.py` — new, the pixel-sampling tool (kept,
  not throwaway — it's how any future palette re-check on this branch
  should be run).
- `ralph/reports/T1-HALL-BUILD-PALETTE-PROOF-2026-08-30.md` — the proof
  writeup.
- `ralph/reports/T1-HALL-BUILD/shots/` — the six rendered evidence frames
  (C-01..C-04, S-ext-01/02) plus the raw measurement output.
- `ralph/reports/handover-T1-HALL-BUILD-2026-08-30.md` — this file.

Not touched: `scripts/world/stronghold.gd`, `scripts/world/interior_structure.gd`,
`data/config/stronghold.json`'s `site.at`/`yaw_deg`/`ramp_run`, any castle
`modules`/`colliders` list, `map_landmarks.json`, `stronghold_occupation.gd`.
No geometry anywhere changed.

## 8. What I would do next

1. **Get a call on the 64px-vs-128px cell-size disagreement** (§6 above)
   before anyone treats §5 as fully passed — five minutes for whoever owns
   the design next.
2. Proceed to design §9's implementation order: re-site (step 1) first,
   since the design itself says the castle retirement must never precede
   the massing and the corridor must never aim at nothing — re-siting
   first is what makes the NEXT palette check (works exterior tone, the
   real shaded gate face) actually measurable instead of confounded by
   the current arbitrary orientation.
3. Once re-sited, re-render and re-measure the works `stone_light` tone
   and the (now-real) shaded gate face specifically, since this pass
   could not cleanly separate "wrong colour" from "wrong orientation
   against the moved sun" for those two readings.
4. Author the `H-01`..`H-08` capture stands (design §10) once there is a
   `meadows_hall` massing to point them at — not this lane's job per the
   design's own separation, but worth flagging to whoever picks that up
   next that the sun-move confound found here is relevant to how those
   stands should be interpreted, especially `H-03` (the design already
   calls out its own night/golden variants as load-bearing).
