STATUS: prepared, third in line (two arms on the GPU at most: Voltarach and Ribbonray go first)
ROWS: F36#30 Abyssal Guardian poses (5.54), F36#88 Water Abyssal Guardian poses (5.85)
BRANCH: tb/below6 (needs the branch: new texture, import once)
OVERLAY: ralph/reports/LANES/BELOW6-ABYSSAL/overlay.json
FRAMES: CAPTURE.json (capture_f36_poses.gd --species=abyssal_guardian,water_abyssal_guardian --whole-body --context, base and arm)

# ARM: Abyssal Guardian, matte slate hide (LANE-REMAKES, 11 Nov)

## Cause
- **Land form (1 Nov remake):** roughness map mean 0.52 over one flat, saturated navy with a pure-white belly, so on GPU it takes a broad plastic highlight ("glossy vinyl, toy-like", 3/3).
- **Water form:** a different model (`candidate_installed_retex` r6). Its recorded defects are "spindly" and "neck up in faint", which are mesh and pose, not material.

## The arm (`creature_coat_flags.json remakes_floor_abyssal_guardian`, OFF)
- Land form: albedo `..._Image_0_floor1.png` (navy loses 40% saturation toward slate sea-blue, fine value mottling from its own detail inside the navy, belly from pure white to grey-cream), roughness 0.86, specular 0.3. Cyan markings and eyes keep their pixels. Script: `tools/art_pipeline/grade_remakes_floor.py abyssal_guardian`.
- Water form: the same roughness and specular over its existing 1 Nov `_vis1` grade (cyan dots muted, self-lit emission x0.6).

## CPU check (`_sheet_cpu.jpg`: base left, arm right; land form top, water form bottom)
- Land form: the hide is visibly less saturated and the belly is cream instead of white. The gloss itself does not show on Low/Compatibility, so the main effect can only be judged on GPU.
- Water form: almost no visible change on CPU.
- No CPU judge batch was run.

## Expected
- Land form: probably more than 0.5 if the vinyl highlight is what the judges see on GPU; I can't confirm that on CPU.
- Water form: under 0.5 on its own. It rides inside this arm. Its spindly build needs a mesh change (LANE-MESHY) and its faint belongs to LANE-FLOOR2.
