# F10#4 — Forest, rod line, restored-sky views pass Bars A/B

- Commit under test: 826d273c3
- Renderer: software renderer (Compatibility), Xvfb + llvmpipe, opengl3, 1920x1080
- Command: `xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 --audio-driver Dummy --resolution 1920x1080 --script tools/capture_stormwood_f10_matrix.gd -- --out=<dir> --label=reproof` → `DONE 15 frames, 0 failures`, exit 0 (default stands forest, giant, glass, rod_line, stormheart × calm, break, aftermath_calm; frames_reproof.json)
- Scope: visual stills only; audio and device profile not covered by this lane.
- Replaces: ralph/reports/STORMWOOD/f10_4/ (r5–r7)

## Code-blind judge (fresh agent; 15 frames, criterion, Stormwood §4/§4.1 bar, Stormheart boards A/B, palworld-01): FAIL

Forest/giant trunks: YES partly. Glass scars: NO. Rod line as growing destination: NO. Aftermath: partial → NO. Calm vs Break legible: NO. Bar A: NO. Bar B: NO.

Defects (verbatim summary):
- stormheart_* (all three): "The split tree is two flat, untextured, extruded mauve slabs with simple ring platforms. It has no bark, roots, canopy mass, banners or core glow, so it reads as a placeholder silhouette (a blocking defect)." Small foliage clumps float detached at the slab tops (floating objects, blocking). Orange-red roofed cottage beside it clashes with the oxblood-reserve rule. Dotted cyan guide line hangs mid-air in the split.
- glass_*: "five plain cyan cones on a flat dark slab sitting on a grassy slope" — placeholder primitives, nothing scars trees or terrain; far lamps float in the bare tree.
- rod_line_*: good receding pylon line with copper cable, but it ends at the horizon with no Dynamo/Stormheart; pylons ~1.5× trainer height; glowing ground cracks saturated yellow (reads as UI guide paint); in rod_line_aftermath the cracks simply disappear.
- giant_*: gameplay camera behind a foreground bush, trainer hidden; oversized faceted violet flower near camera.
- forest_break, giant_break: crushed to near-black; bear in forest_break looks semi-transparent/ghosted.
- Break phase: global darkening plus heavier rain only — "no white-violet lightning or flash in any _break frame, and no light around the split or core."
- glass, rod_line, stormheart stands are ordinary meadow-tree parkland with open sky (breaks "little direct sky until the aftermath").
- All frames: no black reflective pools, wet roots, copper vines, ground mist or Stormglass arches; trunk material flat near-black; moss not lit cool blue-green from below; sky is the same flat purple skybox in calm and break; no cloud-filtered shafts in aftermath.
- Aftermath positives: purple sky stays, rain lighter, colour returns.

Biggest gaps: (1) Stormheart landmark is a placeholder slab pair — needs new art; (2) no lightning/storm lighting in any phase — scene-fixable (bolt VFX, localized flash at the split, emissive core, fog); (3) biome identity reads as a Meadows reskin — mostly scene-fixable from installed families (fog volumes, pool planes, copper vine/lantern kitbash, trunk tint, moss underlight, camera/bush fix); true glass scars and Stormglass arches likely need new meshes.

## Verdict: FAIL
