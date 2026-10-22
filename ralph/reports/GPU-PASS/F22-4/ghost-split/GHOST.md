# F22#4 Riverwatch r13: the Medium "ghost" Brooktail, split (GPU, 22 Oct 2026, evening)

**Cause:** the boss-aura cue that `scripts/combat/enemy_pattern_telegraph.gd::_add_boss_aura()` applies to the captain during a telegraph. Row `cue_boss_aura: true` is on two Oreth rows in r13's combat.json. It adds two things:
1. **A rim overlay:** a `material_overlay` on every visible mesh of the boss's art. It is a runtime `ShaderMaterial` with `render_mode unshaded, blend_add, cull_back, depth_draw_never;`, an additive fresnel rim with `rim_colour` #5fd8ff, `rim_power` 2.6 and `strength` 1.2.
2. **A light:** an `OmniLight3D` with colour #6fdcff, `light_energy` 3.0 and `omni_range` 4.5 m, at the boss.

**Why only on Medium:**
- On Forward+ the additive rim draws at full strength and the 3.0-energy cyan light dominates the boss's shading. The surface reads as a pale cyan-grey "hologram".
- On Compatibility the same additive blend renders at a fraction of its strength, as the code's own comments in `telegraph_glow.gd` and `impact_flash.gd` note. Low's otter stays solid.

**Correction (metallic is not a factor):** the captain's material reports `metallic` 1.00 and `roughness` 1.00, the glTF defaults because the factors are absent. But the glTF binds a `metallicRoughnessTexture` whose blue (metallic) channel averages 0.01, and glTF multiplies the factor by that texture. So the effective metallic is about 0.01: the otter is not metal. That fits the result of forcing `metallic` to 0, which changed almost nothing. An earlier version of this note called metallic a contributing factor; that was wrong, because my runtime dump did not record the bound metallic texture. See `ralph/reports/GPU-PASS/meshy-metallic-audit.txt`.

The rest of that material was opaque: transparency DISABLED, depth draw opaque-only, cull disabled, blend mix, albedo alpha 1.0. The alpha-scissor value (0.5) is unused because transparency is off. It had no refraction, SSS, backlight, rim or clearcoat, and emission was additive at energy 0.08.
**What did not cause it:**
- The line-of-sight fade (with its r13 change reverted, still ghostly);
- the water wall, fan and spray cues (opacities set to 0, still ghostly);
- depth fog, volumetric fog, glow and SSAO. The apparent fog result was a confound: the fight timeline varies between runs, and the fog-off run's i06 happened to fall outside a tell.

## Arms (all Medium, 765bf9d92 + r13 overlay, the same capture, matched frames i03, i05 and tell1 mid)

| Arm | During OVERFLOW tell (i03) | Outside a tell (i05) |
|---|---|---|
| r13 as is | ghost: pale cyan veil, bright cyan rim | solid brown |
| `cue_boss_aura` false | **solid brown, no rim** | solid brown |
| captain `metallic` → 0 | nearly unchanged, still veiled | – |
| water wall/fan/spray opacity 0 | ghost | – |
| line-of-sight fade reverted | ghost | – |
| Low (Compatibility), r13 as is | solid | solid |

## Suggested fix (Fights lane)

1. Make the aura Forward+-aware: drop the OmniLight3D's energy, or drop the light, and cut the rim `strength` on Forward+. Alternatively, use the renderer check `graphics_prefs.forward_plus()` from tb/fplus-grade so both renderers show the same rim weight.

## Files

- `_sheet_ghost_split.png`: matched i03 crops of each arm, plus i05 outside the tell.
- `material_dump.txt`: the runtime material dump of the captain's meshes, including the metallic-0 arm's confirmation line.
- `f22_ghost_probe.gd.txt`: the local probe wrapper. It dumps materials and can force opaque, force metallic 0 or apply grade variants.
- Per-frame captures stay local.
