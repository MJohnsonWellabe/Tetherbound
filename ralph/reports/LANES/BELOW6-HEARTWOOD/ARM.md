STATUS: ready for GPU (High first); next in line when one of the two arms in flight returns
ROW: F41#1 Stormheart finale (P2-037), GPU High 5.78
BRANCH: tb/below6 (needs the branch: one new model, import once)
OVERLAY: ralph/reports/LANES/BELOW6-HEARTWOOD/overlay.json (`stormheart_presentation.json heartwood_1111`)
FRAMES: CAPTURE.json (phase2_capture_locations.gd, the row's three frames, base and arm)

# ARM: Stormheart heartwood on the hollow's axis (LANE-BELOW6, 11 Nov 2026)

## Why this is a new idea
Judges, 3/3 in every round: no core or crown in view, flat white lightning strokes. The row's ground stands look across the hollow's empty axis. Every earlier core was somewhere else or was not a thing:
- `core_column` (SW7): a bare light tube on the axis, "a rigid white tube". Off.
- `heart_cleft` crystal, `heart_cradle_1107` (−0.31 CPU), `heart_core_1109` (−0.13 GPU): all in the wall cleft at r 45 m and beyond, behind the deck slab.
This puts a physical, living core where the camera looks.

## The arm (flag OFF)
- `assets/props/blender-1111/stormheart_heartwood/stormheart_heartwood.glb`: Blender procedural (script `build_heartwood.py` here, provenance beside the model, no Meshy, no third-party mesh). A faceted crystal core 3.5 m across at the floor, rising to 96 m, with thin lightning filaments on it; six braided bark roots that flare 10–13 m over the floor and cage the core half-open; five counter-wound ties; from 30 m the roots open into an inner crown of limbs (max radius 14.5 m, inside the 18 m deck opening, clear of the ascent ramp at r 22–30 m).
- Materials at load (`stormheart_tree.gd _heartwood`): the trunk's own bark; a shaded blue crystal core with moderate glow (albedo #3566d6, emission #4f7dff at 0.7) that cools after the storm is released; vein lines at 2.6; three blue-white omni lights at 3, 14 and 34 m.
- The four flat arc strokes around the axis are removed while it is on.
- **One gameplay change:** a 4.6 m-radius, 14 m-tall static cylinder on the axis so nobody walks through the cage. It is built on simulation shells too, so every peer has the same floor. The hollow's centre had nothing on it (the ascent starts at r 26 m). No floor, route, deck or encounter change.

## CPU check (`_sheet_cpu_base_vs_arm.jpg`: base above, arm below; the two close frames)
- Base: banners and four crossing white strokes over an empty centre.
- Arm: a pale-blue faceted crystal standing in bark roots fills the centre of both frames; the strokes are gone. The roots meet the floor (first look had blunt floating tips and a kink; both fixed and re-captured).
- Not visible on CPU: bloom on the core and veins. The core emission is deliberately low (0.7) after the first look read as a flat white slab at 2.4; **if it washes out white on High, lower `core_glow_energy`, do not judge that frame**.
- The crown limbs start at 30 m and are above these frames (the 6 m deck hides everything overhead), so this arm answers "core" and "flat strokes", not "crown".
- On CPU the two `approach` stands seat outside the trunk and show no change. The GPU's 8 Nov `approach` frame stood under the deck looking in; if it does again, the heartwood is in it at about 40 m.
- No CPU judge batch was run.

## Expected
More than 0.5: the two asks that all three judges repeat (a visible core, no flat strokes) are answered in the middle of the judged frames. Risk: bloom, and whether a crystal in roots reads as "core" or as a prop.

## Checks
- `tests/test_stormheart_heartwood.gd`: flag OFF, 3 tests ok (inside the 56-test landing run). With the flag ON the axis-body test passes; only the "ships OFF" assertion fails, as it should.
