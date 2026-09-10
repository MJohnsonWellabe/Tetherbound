# Shared procedural grass — retained clump 02

Owner feedback reopened the grass: the existing thin blades and first Water
profile did not read as adequate procedural grass. This change broadens and
varies the shared tuft geometry, preserves per-blade height through the vertex
shader, and mounts the shared field in Water with its own copied profile.

Water uses a 56 m ring, grass-texture placement, a 0.35 m minimum ground height,
and small arrival/camp clearances. Shore, rock, submerged terrain and built
floors remain excluded. The lattice produced 57,836 tuft instances in the
opening run; this is allocation, not a claim that every instance survives the
shader masks or is visible. Cover has no collision or harvest interaction.
Meadows and Stormwood use the same improved tuft with their existing profiles.
Cloudreach has a different ground-cover implementation and is not covered by
this change.

## Evidence and disposition

- Grass profile/lattice tests: 22 tests, 87,832 assertions passed for retained
  clump 02. Current physical-grounding unit separately passed 3 tests / 1,819
  assertions; the earlier combined run's grounding tolerance failure is
  preserved and does not represent a grass failure.
- Native Water: `shots/catalogue/water/broad-clump-candidate02/`, 12 frames,
  guarded 64 s capture, no script/engine errors.
- Native Meadows: `shots/catalogue/meadows/broad-clump-candidate02/`, 20 frames,
  guarded 125 s capture, no script/engine errors. Compact empty HUD and shared
  village grounding are also present, so HUD preferences are not grass wins.
- Native Stormwood: `shots/catalogue/stormwood/broad-pads-clump02-parse-fixed/`,
  24 frames, guarded 96 s capture, no script/engine errors. This also contains
  settlement terrain pads and the Voltarach alpha palette. The preceding
  capture's unrelated camera parse failure was stopped and preserved.
- `JUDGE-FIRSTSHORE-GRASS02.md` prefers the increased visible grass volume,
  narrowly; stiff, pale reed-like blades remain a defect.
- `JUDGE-MEADOWS-GRASS02.md` prefers the fuller grass. Key-art A passes for this
  one location, broad-genre B passes, commercial quality does not.
- `grass02-water-opening-first`: 2026-09-10 02:54:48–02:56:04 UTC, 76 s, exit 0,
  no script/engine errors. Production arrival → Pell dialogue → physical swim
  lesson, 64.488 m swimming, no post-arrival fixture writes. This begins at
  Water arrival and does not prove an earned Stormwood-to-Water transition.
- `broad-wave-art-first`: 59 s, exit 0, no script/engine errors; installed model
  loading, dimensions and shared Meadows vegetation passed.

Clump 03 changed blade bend/height and Water tip tint. Its matched First Shore
judge found no meaningful grass improvement. Those exact changes were
withdrawn; patches and frames remain in `.artifacts/broad-visual-0910/` and
`shots/catalogue/water/broad-clump-candidate03/`. The smaller empty HUD was the
only preference in that comparison. Do not label the withdrawn shape as a win.

This is a visible coverage improvement, not four-biome visual acceptance or an
Ally performance result. Native captures used the NVIDIA OpenGL Compatibility
renderer on this laptop. Thin/stiff blade appearance, uneven coastal scene
dressing and Cloudreach ground cover remain open.
