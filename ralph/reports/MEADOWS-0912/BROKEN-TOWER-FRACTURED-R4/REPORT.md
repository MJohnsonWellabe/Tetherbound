# Broken Tower fractured R4 independent review (2026-09-12)

## Verdict

**POLISH — retain R4's fractured silhouette work, but do not promote the Broken
Tower to PASS.** The route, arch, unequal standing leaves, stepped crown, and
east-side collapse make an unmistakable ruined watchtower at all three player
distances. R4 adds useful small asymmetries to the crown and fallen section, but
the native close view still exposes a broad smooth pale cut on the tall leaf and
the same leaf becomes a near-featureless black blade at night. These are the
specific R3 blockers and they remain too prominent for location closure.

## Evidence integrity and disclosure

- `manifest.json` is internally complete: `complete` is `true`, the expected and
  recorded frame counts are both six, `failures` is empty, and all six listed
  1280x720 PNGs are present as three day/night pairs.
- The three stands progress coherently from 47.20 m to 21.40 m to 10.00 m from
  `RuinedWatchtower`. Matched day/night camera-to-player distances agree, and
  every frame visibly retains the ordinary player at credible third-person scale.
- The disclosure is consistent with the capture source: production
  `res://scenes/world/meadows_playground.tscn`, production player and landmark,
  authored clear day/night, hidden HUD/submersion overlays, and an added 70-degree
  evidence camera. No terrain, vegetation, light, landmark, progress, or encounter
  content is injected.
- This harness does not require a fresh output directory and has no mechanical
  camera collision/occlusion check. The directory contains exactly the six
  current manifest frames plus the receipt, all written in one capture window,
  and native inspection shows no stale mismatch or camera inside a solid. The
  limitation lowers proof strength but does not invalidate this set.

## Native-frame review

- `01-route-arrival-day`: **PASS for distant identity and navigation.** The dirt
  route leads directly to an asymmetrical crenellated ruin; arch, upright leaf,
  broken continuation, player scale, and surrounding countryside read cleanly
  at 47.20 m.
- `01-route-arrival-night`: the moonlit silhouette and cyan threshold keep the
  destination findable, but most of the standing tower compresses into a single
  black rectangle. The route-facing mass does not retain the daylight masonry
  hierarchy.
- `02-arched-threshold-day`: the open arch and stepped crown are strong, and R4's
  broken eastern continuation no longer reads as one untouched wall bar. The
  tall left leaf nevertheless terminates in a broad, pale, perfectly planar side
  face that looks like the exposed side of a thin kit slab rather than fractured
  masonry.
- `02-arched-threshold-night`: the arch practical provides a usable entrance and
  restrained ground cue. The front/left blade remains almost completely black,
  preserving only sparse teal edge highlights while the pale side remnant and
  arch receive much stronger fill.
- `03-watch-remnants-day`: the 10 m view proves installed stone texture, unequal
  standing leaves, open interior, foundation, steps, and a multi-piece fallen
  section. It also makes the unresolved construction defect unavoidable: the
  tall facade is visibly paper-thin along its smooth light side, and several top
  breaks still end in square rectangular blocks rather than a convincingly torn
  wall section.
- `03-watch-remnants-night`: the arch, rear remnant, steps, and bounded practical
  remain legible, but the tallest and closest facade is a dominant black plane.
  The added grazing treatment does not reveal enough surface course or fracture
  depth to match the daylight structure.

## R3 blocker accounting

1. **Fractured collapse:** improved. The east fallen section has multiple unequal
   beats and the crown silhouette is less mechanically continuous. Retain it.
2. **Planar cut and rectangular termination:** not resolved at the strict visual
   bar. The pale side cut on the tallest surviving leaf is conspicuous in all
   daylight distances and strongest at 10 m.
3. **Black night face:** not resolved. Navigation remains usable, but the major
   route-facing blade still loses almost all masonry depth and value.

The location therefore remains **POLISH**, not FAIL: its identity, route, arch,
scale, and broken massing are strong, and R4 is a bounded improvement. PASS needs
the exposed tall-leaf edge to read as thick, irregular broken masonry and a
restrained source-backed night value that reveals that same facade without
flattening the ruin.

## Review-only scope

This review adds only `REPORT.md`. It does not modify the manifest, PNG evidence,
production/config/source/test/capture files, generated terrain/scatter, or
staging state.
