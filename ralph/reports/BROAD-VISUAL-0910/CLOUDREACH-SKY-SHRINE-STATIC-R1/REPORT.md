# Cloudreach Sky Shrine static recovery R1

## Disposition

**Static candidate: expected POLISH, pending production capture and independent image judgment.**

The canonical FAIL is an invalid catalogue arrival, not evidence that the shrine is
missing. The old point `[1110, 2940]` is the heartstone/pedestal centre. Its third-person
camera is consequently trapped under the wind armature and behind a stone drum. The
production builder already authors a 26 x 20 m dais, stepped approach, paired carved
20 m pillars, an installed sanctuary arch, lintel carvings, finials, heartstone and
wind armatures, retaining wings, planting, rocks, flowers and benches.

## Bounded recovery

- The Sky Shrine catalogue row now uses the south crown-edge stand `[1110, 2885]`
  and faces north into the complete sanctuary. Physical shrine/objective positions,
  Fly landing, wind vanes, windlass, route unlock and terrain are unchanged.
- The heartstone now owns one restrained 24 m cool focal light. This is local dais
  readability at night, not a Cloudreach exposure change and not added geometry.
- `tools/capture_cloudreach_sky_shrine.gd` captures two real crown-edge views at day
  and night, freezes player locomotion, hides overlays, retains the trainer as scale,
  and rejects evidence that loses the heartstone/pillar/lintel/approach hierarchy.

## Static acceptance boundary

The candidate should convert the invalid evidence pair to at least POLISH because the
complete authored destination and a player-scale approach can now share the frame.
It is not called PASS without production pixels. The capture must still reject a
cropped armature, pedestal-dominated composition, missing trainer scale, non-finite
ground, or a night frame where the local sanctuary does not separate from the sky.

## Validation receipts

- Focused test: **3 tests, 18 assertions, 0 failed**.
- Godot 4.7 `--check-only`: production world builder, focused test and dedicated
  capture harness each exit 0 with no script errors. The dummy headless renderer
  prints its known shutdown RID-allocation diagnostics.
- Catalogue JSON parse: passed.
- Scoped `git diff --check`: passed.

No renderer, bake, import, staging, commit or push was performed in this lane.
