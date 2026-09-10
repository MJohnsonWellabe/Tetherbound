# Stormheart ascent wayfinding — 2026-09-10 continuation

## Result

The Stormheart's southern approach now has an authored, pointed timber threshold
and the four-turn ascent carries a repeated warm-lantern and cross-plank rhythm.
This is a retained local improvement to entrance recognition, route scale, and
construction language. It is not commercial Stormheart or Stormwood acceptance.

The change uses the installed `Lantern_Wall.gltf` prop and the landmark's existing
wood material. No mesh was generated or purchased, no creature was added, and no
route, collision, encounter, progression, or simulation-shell geometry changed.

## Evidence-led scope

The prior material-only candidate was correctly withdrawn. Its matched verdict
found that surface treatment did not solve the dominant problem: the four-turn
ascent read as continuous black ribbons inside giant bark planes, with no clear
entry, landing rhythm, or human construction scale. The approved boards instead
show a shaped base entrance, timber platform articulation, and warm lamps stepping
up around the cold electric core.

The retained pass therefore changes the authored composition rather than trying
another texture or global colour knob:

- two 6.8 m timber posts, a narrow tie, and two sloped crown beams frame the
  existing ten-metre southern route without closing it;
- two authored wall lanterns mark the threshold;
- eight more authored lanterns mark the southern reveal of all four turns;
- 48 shallow visual cross-planks—twelve per turn—break the huge continuous ramp
  into a repeated construction scale;
- all ten lights are local, warm, non-shadow-casting 22 m omnis rather than a
  global interior fill.

The first diagnostic candidate used solid box cages. Fresh rendering showed they
read as new debug blocks, so that mechanism was rejected before retention. The
installed authored lantern replaced it. The final comparison is:

- baseline: `.artifacts/visual-audit-0910/stormheart-gameplay-approach-current/`
- retained: `.artifacts/broad-visual-0910/stormheart-wayfinding04/`
- matched production-camera frames: `stormheart_approach_80m`,
  `stormheart_approach_deck_edge`, and `stormheart_approach_40m`

The final native run completed 3/3 frames. The 80 m frame remains intentionally
subtle; at the deck edge and 40 m views, the pointed portal and paired real-lantern
silhouettes give the ascent a clear start, while the cross-plank breaks are visible
on successive ramp turns. The remaining giant bark scale, sparse upper platforms,
flat core energy, creature-free composition, and broader local-lighting gap remain
open and prevent a commercial claim.

## Verification

- `test_stormheart_wayfinding.gd,test_stormheart_presentation.gd`:
  **3 tests, 147 assertions, 0 failed**.
- `smoke_stormheart_ascent.gd`: **exit 0**. Downward floor rays and inner/outer
  rail checks passed at 0%, 25%, 50%, 75%, and 100%; a real `CharacterBody3D`
  continuously reached the core in both rendered-world and simulation-shell
  builds, each at fraction 1.000 and 3.08 m from the core target.
- Production OpenGL capture: **3/3 frames, exit 0**.

The focused test also proves that `AscentWayfinding` is absent from
`simulation_only` builds while `HollowTrunkAscent` remains present. Visual dressing
therefore cannot silently become an alternate physical route.
