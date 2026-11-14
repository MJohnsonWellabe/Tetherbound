# LAND-MT-VEILREBUILD (F39#31, 5.78, the lowest Tidewake row): HELD until a GPU slot frees

**Ask** (coordinator, from the judges' ceiling note): "Veilfall landmark rebuild": a blocky tiled fall, faceted rock, no plunge pool. Rebuild at scene level from what is installed: layered fall ribbons, a churned plunge pool, wet dark rock framing, and base mist joined to the pool. No Meshy.

**What is new versus the parked approaches.** TIERA (removing cascade tiers) and BASEMIST (camera-facing puffs) are parked. This arm keeps the tiers and draws no puffs.

**Built** (flag-off `falls.rebuild` in `water_veilfall.json`, scope `client_presentation`; code in `scripts/world/water_veilfall_falls.gd` and four shaders):
1. **Streaked water** (`column_shader` `streak_x` 2.4, `streak_y` 4.0 in `water_veilfall_fall.gdshader`). The flow pattern's cells were about 7 m wide and 9 m tall, which reads as stacked squares. They become long thin vertical streaks. At 1 and 1 the shipped pattern is exact.
2. **Layered strands.** Three narrower ribbons are offset across each fall, each with its own speed (from UV2.x, which is 0 on the shipped ribbons) and opacity.
3. **Wet rock apron** (`water_veilfall_wet.gdshader`). A ribbon 2.3x the fall's width under it, multiply-darkened with ragged runnel edges, so the stone on both sides reads wet.
4. **Plunge pool and mist shell** (`water_veilfall_pool.gdshader`, `water_veilfall_mist_shell.gdshader`): a churned disc with lobed, broken foam rings, and a flaring lit mist cone that clears near the camera. Both are **built but OFF in this arm**; see below.

**CPU looks** (two judged views, `veilfall-vista` and `veilfall-near`; four rounds).
- With the pool and mist on, the near stand (387, 5, 3799) is about 40 m from the cascade foot. That foot sits 35 m up the gully at (364, 40, 3831), where the live candidate ends the cascade. So the shell read as a glassy dome over the fall and the pool was hidden. They need the cascade to reach its real plunge (the `veilfall_plunge` rock ring is about 25 m lower) before they can help.
- The final look (`_sheet_veilrebuild_cpu.jpg`, left main, right arm: streaks, strands and apron):
  - The near view's fall reads as long thin vertical streaks instead of blotchy cells.
  - Dark wet stone frames both sides.
  - The vista changes little at that distance.
- **Risk:** the apron is near-black at the fall's left edge in the near view.

**By-eye line:** veilfall-near. Streaky falling water with dark wet rock either side, against blotchy white cells on pale rock.

**Next, if this gains:** extend the cascade to its plunge ring and turn the pool and mist on there, for the "plunge pool" part of the ask.
