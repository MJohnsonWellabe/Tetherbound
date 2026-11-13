STATUS: ready for GPU (High first); queue after BELOW6-HEARTWOOD
ROW: F36#80 Thundertunnel poses (GPU High 5.92, G-things-t4-rescore)
BRANCH: tb/below6 (needs the branch: two new textures, import once)
OVERLAY: ralph/reports/LANES/BELOW6-THUNDERTUNNEL/overlay.json (`creature_coat_flags.json below6_floor_thundertunnel`)
FRAMES: CAPTURE.json (capture_f36_poses.gd --species=thundertunnel --whole-body --context, base and arm)

# ARM: Thundertunnel, mole velvet with storm lines (LANE-BELOW6, 11 Nov 2026)

## Judges (3/3)
"A flat pinkish-tan flesh material"; "white cracks read as mud fissures or decals, not lightning"; a single cartoon disc eye; the faint ends as a "faceless ball".

## The arm (flag OFF)
- Albedo `..._value_lift_floor1.png`, graded from the value-lift coat that ships: the tan loses about half its saturation and a third of its value toward a cool brown-grey, with its fur strokes kept and sharpened a little.
- The thin pale cracks become blue-white lines, and `..._value_lift_floor1_glow.png` lights them at energy 1.6: the one storm trait, in place of dried-mud cracks.
- Roughness 0.88, specular 0.25. Reserved-red texels 0.8% -> 0.01%.
- Script: `tools/art_pipeline/grade_remakes_floor.py thundertunnel`.

## CPU check (`_sheet_cpu.jpg`: base above, arm below; standing and faint 050)
- The body reads as a grey-brown furred animal instead of bare skin; the lines read cooler and stand out against the darker coat.
- Not visible on CPU: the line glow.
- Not addressed: the disc eye and the faceless-ball faint (mesh and pose).
- No CPU judge batch was run.

## Expected
More than 0.5: the two material defects are the first two things all three judges name. The same kind of grade moved Voltarach +1.35 and Ribbonray +1.88.
