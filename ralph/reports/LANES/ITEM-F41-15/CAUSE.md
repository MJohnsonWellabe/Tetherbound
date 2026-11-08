# F41#15: Captain Marrow's head blowing out to white on GPU (cause note, read-only)

LANE-SCOUT, 8 Nov 2026, coordinator request. No game change; LANE-MESHY builds the fix.

## What the frames show
- GPU High (`tb/gpu-frames-1108` F41-15/live/High): in both Marrow dialogue frames (`character__captain_marrow__dialogue`, `trainer__captain_marrow_dynamo_core__dialogue`) Marrow's white hair and face render as a white glowing blob with a soft halo around the head; the body and armour shade normally.
- **Officer Nysa, same `captain_a`-family armour body but dark hair (Deepwood frame): no blowout.** The trainer's orange hair at the left edge of the Nysa frame also glows warm-white.
- CPU Compatibility (this lane's batch 2 frames, same stands): Marrow's hair and face read pale but not blown out.
- GPU judges (section A, 3/3): "Captain Marrow's head is blown out to a white glow; face unreadable."

## Cause
1. **The dialogue speaker key light sits at head height, close.** `data/config/camera.json` `speaker_light_candidate` (enabled): `conversation_camera.gd` places a warm key at offset [1.0 toward the lens, 1.4 right, 0.9 up] m from the speaker's chest with energy 0.9, range 3.0, attenuation 2.0, plus a cool rim (energy 1.5, range 3.4). The key lands roughly level with the face, 1–1.5 m away, so near-white surfaces in its short range (Marrow's white hair and pale skin; the trainer's hair when within 3 m) are pushed well above 1.0.
2. **Glow is on for Medium and High and off for Low.** `data/config/art.json` presets: Low `glow: false`, Medium and High `glow: true`. The over-bright white hair then blooms into the halo on Forward+ High; Low/Compatibility has no glow, which is why the CPU frames never showed it.
3. Marrow's model: `stormwood_npcs.json` `captain_marrow` uses `body_profile: captain_a` (`art.json` `captain_a`, `assets/characters/captain_a/captain_a_lod0.glb`), whose hair and face are near-white albedo. `character_body_flags.json npc_vis_look_captain_a` (day rim 0.25, albedo grade) is **OFF**, so it is not the cause. No emission is involved (Nysa's body, same armour, is fine).

## Likely fix
- **Config, smallest:** lower `speaker_light_candidate.key.energy` (0.9 to about 0.4–0.5) or move the key down to chest level (offset up 0.9 to about 0.3) so the face sits at the soft edge of its falloff, and/or drop the rim energy (1.5). Check that Nalia, Nerissa and Fenn (who motivated the light) still read on their dim stands.
- Alternative: give the speaker lights a light cull mask or a lower `light_specular` so hair and skin do not clip, or raise the glow HDR threshold on High so only emissive surfaces bloom.
- Judge on the GPU (High): the defect is invisible on CPU, so a CPU round cannot see it.
