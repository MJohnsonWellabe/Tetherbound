# Tidewake NPC ghosting: cause (read-only, main d9d79ff93)

## What the frames show

I inspected these GPU High frames at pixel level:
- `G-occlusion-fade-off` live: Bex and Iona.

**The speakers are opaque.** No background shows through them:
- The sand ripples behind Iona do not continue across her body.
- The water behind Bex stops at his outline.

Three things make them read as ghosts:
- **A uniform cream/sand-tone lift** over the whole body. Bex's black shirt reads as warm grey, and Iona's olive jacket and skin go toward the dune colour.
- **A bright pale outline** on every silhouette edge (arms, hair, jaw).
- **Flattened shading.**

The body takes on the colour of the sand behind it, so it reads as see-through.

This rules out every transparency path, consistent with what was already tested:
- `camera.json` occlusion_fade
- camfx `fight_fade`, which also runs in conversations and skips skinned bodies
- material alpha
- visibility-range fade

The only `GeometryInstance3D.transparency` writer in `scripts/` is `camera_rig.gd` `_fade_occluders`. It skips meshes with a skeleton and the speaker's own subtree.

## Likeliest term: `data/config/water_character_rim.json` (Tidewake-only, ON)

- **Where it applies:** `scripts/world/water_scene_npcs.gd` (every named NPC) and `scripts/combat/water_encounter_director.gd` (every trainer) call `water_character_rim.gd apply(body)`. That puts `shaders/character_rim_overlay.gdshader` on every shadow-casting mesh of the body as `material_overlay`.
- **The shader:** `render_mode blend_add, unshaded, depth_draw_never, fog_disabled`; `ALBEDO = rim_colour * (rim_energy * pow(1 - N·V, rim_power) + fill_energy * N·V)`.
- **Tidewake's values:**

  | Setting | Value |
  |---|---|
  | `colour` | `#fff0d8` (cream, almost the dune colour) |
  | `energy` | 0.8 |
  | `power` | 2.2 (a wide rim) |
  | `fill_energy` | 0.14 (added across every front-facing pixel) |

  At power 2.2 the rim term is already about 0.2 at N·V = 0.5, so most of a stylised body gets a cream add on top of its lit colour. That matches what the frames show:
  - The add is **unshaded** and **additive**, so dark costumes lift toward cream.
  - It is **fog_disabled**, so a mid-distance speaker keeps the full add while the scene behind takes aerial fog. That widens the mismatch.
- **Tidewake only:** the only other user of the overlay is `stormwood_character_rim.json`. It is cool `#b8c8ff`, energy 0.75, power 2.4, with fill OFF. Meadows and Cloudreach people have no character overlay. This is the one character-material term that is Tidewake-specific, and it matches "only Tidewake speakers ghost strongly".
- **History:** it shipped ON on 4 Nov (NEAR6-TW, F39#27 P2-057) from a **CPU / Compatibility** judgement only: 6.03 → 6.23, with an anchor RMSE 0.79 caveat, and no GPU judgement. Under Forward+ High the additive overlay is written to the HDR buffer before tonemap, so it can land brighter than on the CPU frames it was judged on. This last point is an inference; it is untested.

## Other Tidewake terms checked and ruled out

| Term | Live value (`tidewake_look.json` `lighting`) | Why it is not the cause |
|---|---|---|
| Fog density | 0.00018 | Lower than Meadows' 0.0004 candidate and 0.001 base |
| Aerial perspective | 0.45 | Moderate; it would also wash the dunes and props, which judges call pleasant |
| Ambient | 1.05 `#91aebf`, sky contribution 0.3 | Similar to Meadows 0.92 |
| Exposure / white | 0.72 / 6.0 | Scene-wide; does not single out characters |
| `forward_plus_candidate` (day ambient 1.9) | In `sections_off`, so not live | — |
| `watersky_light_candidate` (adds a character rim 0.35) | `watersky_sections_on: false`, so not live | — |
| `tidewake_material_family.gd` | Called only by environment builders, never by actors | — |
| Water surface material | Iona stands on a dune with no water plane in front, and still ghosts | — |
| `water_npc_posts_candidate.json` | OFF; post positions only | — |

## One-overlay arm

Primary arm, which tests the cause cleanly:
`ralph/reports/LANES/ITEM-NPC-ALBEDO/overlays/water_character_rim_off.json`

```json
{"data/config/water_character_rim.json": {"enabled": false}}
```

- **Capture:** the same three Tidewake dialogue rows, F39#18, #26 and #29, live vs arm at High.
- **Add:** F39#27, the row the rim was made for (it carries the "backlit near-black figures" risk).
- **Expected:** speakers return to their own albedo and shading.
- **Risk:** the F39#27 backlit-dark complaint returns on dune-backlit frames. That is why F39#27 must be in the same batch.

Fallback arm, if the off arm wins on F39#18/#26/#29 but loses on F39#27:
`overlays/water_character_rim_soft.json` keeps only a narrow edge (energy 0.3, power 3.5, fill 0).

```json
{"data/config/water_character_rim.json": {"energy": 0.3, "power": 3.5, "fill_energy": 0.0}}
```

## Note on the occlusion-fade-off arm

camfx.json `fight_fade` is `enabled: true`. Its `_why` says it "turns the same fade on for fight and conversation cameras even if occlusion_fade is off". So an overlay that flips only `camera.json` `occlusion_fade.enabled` still fades occluders along the speaker's chest-to-lens line in dialogue.

The `G-occlusion-fade-off` gains (F39#26 +0.34, F39#29 +0.39) therefore came from a partial change. The `G-occlusion-fade-off-nerissa` manifest note confirms the overlay sets only `occlusion_fade.enabled false`, so `fight_fade` stayed on in every arm frame.
