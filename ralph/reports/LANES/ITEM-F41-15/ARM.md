# ARM: F41#15 Captain Marrow's face and hair blow out white on GPU (LANE-MESHY, 9 Nov)

- Row: F41#15 (GPU 5.71; section A 3/3: "Captain Marrow's head is blown out to a white glow; face unreadable").
- Branch: tb/item-f41-15. Head: see git log.
- Cause: LANE-SCOUT's ralph/reports/LANES/ITEM-F41-15/CAUSE.md (tb/item-scout-1108): the dialogue speaker key sits at face height (camera.json conversation.speaker_light_candidate, key energy 0.9, rim 1.5), and Medium/High glow blooms Marrow's near-white captain_a hair and skin. CPU finding (this lane): on CPU the head is already near-white without glow (head region mean about 210/255), and arm A changes no CPU pixel there (identical means), so the speaker light may not be the dominant term, or the dialogue capture path does not use it. Only the GPU can tell; hence two arms.
- Frames to capture (High, then Medium if High gains): the F41#15 job frames, `stormwood__inventory__character__captain_marrow__dialogue`, `stormwood__inventory__trainer__captain_marrow_dynamo_core__dialogue`, `stormwood__inventory__trainer__officer_nysa_deepwood_rod__dialogue`; plus a check that Nalia, Nerissa and Fenn (who motivated the speaker light) still read on their dim stands.

## Arm A (as briefed): softer, lower speaker key
- Overlay: ralph/reports/LANES/ITEM-F41-15/overlay_speaker_light.json (config only, no import). Key up offset 0.9 -> 0.35 (chest height), key energy 0.9 -> 0.45, rim energy 1.5 -> 1.0.

## Arm B: captain_a albedo grade only
- Overlay: ralph/reports/LANES/ITEM-F41-15/overlay_albedo_grade.json (config only, no import). Turns on the existing character_body_flags.json `npc_vis_look_captain_a` body albedo (captain_a_lod0_texture_0_vis1.png: chalk skin evened, features crisped) with its day rim and idle relax removed, so only the texture changes.

- Visibility sheet (CPU, arm A): `_sheet_preview.jpg` (base left, arm A right): no visible difference on CPU, as expected for a glow defect.
