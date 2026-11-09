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

## What the b5a5aabb crash skipped: why the broken Marrow looked dark and natural (9 Nov ~06:50 UTC)

**The crash.**
- `character_model.gd:651` is `var day_rim: Dictionary = _cfg.get("day_rim", {}) if body else {}`.
- With `day_rim: null` in the flag overlay, `_cfg.get` returns null rather than `{}`, because the key exists. Assigning Nil to a typed Dictionary is a runtime error.
- GDScript aborts `_shared_variant_material` at that line and the call returns `null`.
- The caller, `_palette_node` (line 586), then runs `instance.set_surface_override_material(surface, null)`. That clears the override, so **the body renders its imported `.glb` material untouched.**

**Steps that never ran**, in source order after line 651:

| # | Step (lines ~652–720) | Effect on captain_a when it runs | Skipped by the crash? |
|---|---|---|---|
| 1 | Cache key and `source.duplicate()` | — | yes |
| 2 | `body_albedo_override` (vis1 texture) | brighter albedo (+7 luma) | yes |
| 3 | `body_emission_override` | none set | n/a |
| 4 | `body_emission_enabled` opt-out | **not set for captain_a or captain_b**, so the imported emission stays | n/a |
| 5 | `albedo_color *= palette colour` | captain palette `*` is `#ffffff`: no-op | yes (no effect) |
| 6 | **Metallic fix** (GF-B-010): `metallic > 0 and no metallic texture` sets metallic to 0 | The `.glb` has no `metallicFactor`. glTF's default is **1.0**, so the imported material is fully metallic. The fix makes it fully diffuse, which is **much brighter** under the GPU key light. | **yes**: imported metallic 1.0 kept |
| 7 | `finish.roughness` | no finish on bodies | n/a |
| 8 | **Rank emission floor**: `if body and emission_floor > 0: emission_enabled = true; emission_operator = ADD; emission = colour * emission_floor; energy = _emission_floor_scale` | `npc_ranks.json` `ranks/captain` has `emission_floor: 0.18` with palette `#ffffff`. That is an **additive white self-lit glow of 0.18 over the whole body**, scaled by the look's `character_emission_floor` (1.0 by day). It re-enables emission even when `body_emission_enabled` is false. | **yes** |
| 9 | MULTIPLY emission tint, when there is no floor | — | yes |
| 10 | Night rim (player profiles only) or `day_rim` (`rim_enabled`, rim 0.25, tint 0.3) | the npc_vis_look day rim, when its flag is on | yes |

- **Result:** the broken frames showed the imported material, which is metallic 1.0, has no additive floor and has no rim. It reads dark and natural on Forward+ because a fully metallic surface takes its colour from reflections rather than diffuse light. Its own imported emission was evidently weak on that surface.

**Remaining cause of the pale, glowing head under emission-off.**
- Emission-off sets `body_emission_enabled: false` at step 4. Step 8 then turns emission straight back on as a **white additive floor** (captain rank, 0.18, `#ffffff`, full strength by day). This holds even with the ghost-glow threshold 1.6: the glow threshold only limits bloom, while the floor lifts the shading itself.
- Step 6 (metallic 0) also makes the body brighter than the imported look, but that is the deliberate GF-B-010 fix against black silhouettes and should stay.
- **The same floor reaches Team Tether grunts and officers.** In `npc_ranks.json`, grunt and officer both have `emission_floor: 0.18`, with near-white palettes `#dcdcdc` and `#eeeeee`. That fits Bex and Irva (grunt_c) reading ghosted although their emission is already off.
- The comment in this block says the floor is skipped for tints with luminance ≥ 0.95. The code shown has no such gate: `colour * emission_floor` applies for white too. That is worth checking.

**Smallest change that reproduces the dark look without the crash:**

1. **Config arm (no code, recommended first).** Run it on top of ghost-glow and judge F41#7, F41#15 and F39#29, plus F39#18 for the grunts.
   ```json
   {"data/config/npc_ranks.json": {"ranks": {"captain": {"emission_floor": 0.0}}},
    "data/config/art.json": {"captain_a": {"body_emission_enabled": false}, "captain_b": {"body_emission_enabled": false}}}
   ```
   - Add `"grunt": {"emission_floor": 0.0}` and `"officer": {"emission_floor": 0.0}` in a second arm to test the grunt ghosting.
   - Caveat: the floor exists for Compatibility (Low) legibility, where rank bodies read as black smears at a distance. A shipped version should not zero it on Low.
2. **Code version if the config arm wins.** About three lines, mirroring the existing creature path:
   - Add `character_emission_floor_forward_plus_scale` to `art.json` looks (default 1.0, arm 0.0).
   - In `world_look.gd:1188`, multiply `character_emission_floor` by it when `RenderingServer.get_current_rendering_method() == "forward_plus"`. This is the same pattern as `creature_emission_floor_forward_plus_scale` (F22#4, GPU-PASS 24 Oct).
   - Separately, make step 8 respect the documented ≥ 0.95-luminance skip if that gate was intended.
3. **Do not reproduce the metallic 1.0 look.** It is the GF-B-010 black-silhouette bug, and it only looked natural on this one stand.
4. **Crash guard (tiny, independent):** `var day_rim: Dictionary = _cfg.get("day_rim", {}) if body and _cfg.get("day_rim") is Dictionary else {}`, and the same for `night_rim`. A null in an overlay then means "off" instead of a broken material.
