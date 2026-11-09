# ITEM-NPC-ALBEDO: ghost-white and translucent named NPCs on GPU High (read-only cause note)

LANE-SCOUT, 9 Nov 2026, from main ba6778f45 configs and assets. No game files were changed.

## Who the GPU judges called ghost-white or translucent
- **Sources:** `GPU-PASS/1108/F-tidewake.md`, `G-ghost-glow.md`, `G-f41-15.md` and `F-stormwood.md`.
- **F-meadows:** its judges called creatures translucent, which the ghost-glow creature rim fixes. They named no NPC.

| NPC | Rows / where | body_profile | `npc_vis_look_<profile>` (albedo override) | art.json `body_emission_enabled` | Base albedo mean luma | vis1 grade mean luma |
|---|---|---|---|---|---|---|
| Captain Marrow | F41#15, F41#7 (blown-out white head) | captain_a | exists, **OFF** | **not set (imported emission kept)** | 37.6 | 44.9 |
| Captain Nerissa | F39#29 (pale, does not match her portrait) | captain_b | exists, **OFF** | **not set (imported emission kept)** | 30.5 | 37.2 |
| Surveyor Adair, Researcher Iona | F39#26 (semi-transparent, ghosted) | field_researcher | exists, **ON** (with day_rim 0.25 and idle_relax) | false | 60.5 | 65.2 |
| Pierwright Rowan | F39#26 | trader | exists, OFF | false | 45.3 | 55.2 |
| Fenn | F41#20 (face blooms near-white) | trader | exists, OFF | false | 45.3 | 55.2 |
| Daro | F39#18 (ghosted, washed out) | young_trainer | exists, OFF | false | 56.8 | 62.9 |
| Bex, Irva | F39#18 (ghosted) | grunt_c | exists, **ON** (with day_rim 0.25 and idle_relax) | false | 40.6 | 45.8 |
| Resident Nalia | F39#29, F39#27 (pale, washed out) | courier | exists, OFF | false | 57.6 | 62.6 |
| Campkeepers Elin and Halen (camp NPC) | F39#13 (ghost-white NPC by the bench) | innkeeper | exists, OFF | false | 64.2 | 68.7 |

- **Luma:** the mean over the whole texture (0–255), downsampled to 512 px. I did not isolate face and hair regions; the atlases have no documented UV layout. No texture has any pixel above 200, and every alpha channel is fully opaque (min 255).
- **F39#22 (Aquaryn dismount):** the "companion NPC" there is not named in the capture, so it is left out.

## What the data says
1. **Marrow and Nerissa keep a full-surface self-lit emission.**
   - Every Meshy NPC `.glb` material has `emissiveTexture` (the same image as base colour) with `emissiveFactor [1, 1, 1]`. The Warden's has none.
   - `art.json` turns the imported emission off (`body_emission_enabled: false`, handled in `character_model.gd` `_shared_variant_material`) for every NPC profile above except captain_a and captain_b.
   - A body that emits its full albedo at factor 1 will bloom under Forward+ High glow. That is the most likely cause of Marrow's white head and Nerissa's pale look. This is an inference: no isolated arm has been run yet.
2. **The graded vis1 albedos are brighter than the base, not darker**, by 4.5 to 10 luma.
   - Arm B's win on captain_a (+0.91/+0.95, `G-f41-15.md`) did not come from darkening the albedo.
   - **Update (GPU lane, ~06:20 UTC):** those arm-B frames were a broken material. Literal nulls made `character_model.gd:651` throw, which likely dropped the imported emission. So that result supports point 1, not the albedo grade. The re-shoot is `G-f41-15-arm-b-fix`.
   - The original note continued: the mechanism is unconfirmed. The override builds a separate cached material (the albedo path is part of the cache key), so check whether that material reaches the emission opt-out or the `emission_floor` path differently from the default one.
   - The `CAUSE.md` correction in ITEM-F41-15, "bright albedo is the cause", should be read with this in mind.
3. **The other ghosted NPCs already have emission off.**
   - Two of them, field_researcher (Adair, Iona) and grunt_c (Bex, Irva), already have their vis1 grade ON, together with `day_rim` 0.25.
   - Their ghost look must come from something else. Candidates:
     - `day_rim` (a constant lit edge, much like the creature fresnel rim that ghosted creatures until ghost-glow toned it);
     - the dialogue `occlusion_fade` (`camera.json`, `fade_transparency` 0.8; it should skip skinned bodies, but check that NPC stand meshes are skinned);
     - the glow threshold itself.
   - Two judges thought the occlusion fade was hitting the speaker.

## Proposed GPU arm: one overlay (config only, no import)
The build lane should capture it on top of the ghost-glow overlay, since ghost-glow ships. Frames:
- the F39#26, F39#18 and F39#29 dialogue stands;
- F41#20 Fenn;
- F41#7 and F41#15 Marrow;
- the F39#13 camp frames.

```json
{
 "data/config/character_body_flags.json": {"flags": {
  "npc_vis_look_captain_a": {"enabled": true, "characters": {"captain_a": {"day_rim": null, "idle_relax": null}}},
  "npc_vis_look_captain_b": {"enabled": true, "characters": {"captain_b": {"day_rim": null, "idle_relax": null}}},
  "npc_vis_look_trader": {"enabled": true, "characters": {"trader": {"day_rim": null, "idle_relax": null}}},
  "npc_vis_look_young_trainer": {"enabled": true, "characters": {"young_trainer": {"day_rim": null, "idle_relax": null}}},
  "npc_vis_look_courier": {"enabled": true, "characters": {"courier": {"day_rim": null, "idle_relax": null}}},
  "npc_vis_look_innkeeper": {"enabled": true, "characters": {"innkeeper": {"day_rim": null, "idle_relax": null}}},
  "npc_vis_look_field_researcher": {"characters": {"field_researcher": {"day_rim": null, "idle_relax": null}}},
  "npc_vis_look_grunt_c": {"characters": {"grunt_c": {"day_rim": null, "idle_relax": null}}}
 }}
}
```

- **What it does:**
  - Turns on the albedo-only grade (the `captain_a` arm-B recipe) for every ghosted profile whose flag is OFF.
  - Strips `day_rim` and `idle_relax` from the two profiles that are already ON. That isolates the rim as a suspect for Adair, Iona, Bex and Irva.
- **Merge rule:** `null` means "remove the key". Use the same merge the arm-B overlay used (`ITEM-F41-15/overlay_albedo_grade.json`).
- **Second arm, worth capturing in the same run:** `data/config/art.json` `captain_a.body_emission_enabled: false` and `captain_b.body_emission_enabled: false`, without the albedo grade. It tests point 1 directly, and if it wins it is the smaller, cleaner change.
- **Profiles with no grade yet** (no `body_albedo_override` in their flag): `craftsperson` (Keeper Ondra). Every other profile in the table has a vis1 texture.
