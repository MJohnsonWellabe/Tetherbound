# Tidewake close-1024 round fc2: Veilfall terraced face, CPU pre-judge (25 Oct 2026, CT)

## What changed (all OFF in play, under `veilfall_mountain_candidate` plus `rain_veil_candidate`)

- **Crown:** narrowed to 400 m tall, stretched 1.15 x 1.2, lift 70, so its stepped falls show.
- **Terraces:** re-enabled on the capped flanks (`terrace_m` 22, riser 0.3) and rebaked.
  - Six regions now differ from shipping: the cap's four plus `01_07` and `01_08`. The 400 m shore radius reaches x 600.
  - Walk bands, anchors and the gate are unchanged. The relief-walk, geometry, look-profile and trimesh tests pass (13 tests, 873 assertions).
- **Mossy ledges:** flat tier tops above 25 m are tinted mossy green (new `vf_ledge_*` uniforms on the Veilfall rock pass), so the tiers stop reading as sand stripes.
- **Rain veil:** a new far rain layer on the active camera (`rain_veil_candidate`): 0.12 x 5 m streaks in a 25-140 m ring. The shared rain ring only falls 6.5-20 m around the player, so the vista showed no rain at all.
- **Stand:** the 750 m F39-look stand (`veilfall-vista`, `veilfall-vista-rain`).
- **Sections captured:** `current_flow,veilfall_falls_candidate,rain_fog_candidate,rain_veil_candidate,veilfall_mountain_candidate`. The comparison is shipping (`nv_base`).

## Mapped Bar A

- **Yardstick:** standard prompt, three code-blind judges, 3 anchor pairs (seed 18213).
- **Calibration:** slope 1.13, r 0.94, anchor RMSE 0.31.

| Set | Shipping | fc2 | Δ | Judges |
|---|---|---|---|---|
| Veilfall vista, clear and rain | 5.27 | **5.98** | +0.71 | higher x3 |

**Defect changes, shipping → fc2:**
- **Blocky heap / smooth cone:** PRESENT x3 → PARTIAL x3.
- **Rain fog flattens:** PRESENT x3 → PARTIAL x3.
- **No visible rain:** PRESENT x3 → FIXED x3.
- **Falls read as flat sheets:** PARTIAL x3 → PARTIAL x1, PRESENT x2.

## Remaining (all three)

1. **Terraces:** they read as a regular zigzag sawtooth band, which looks like generator output. This is aliasing of the sharp 0.3 risers at distance. fc3 (28 m tiers, 0.65 risers, darker ledges) is next.
2. **Falls:** the crown falls are thin flat strips with no base mist.
3. **Silhouette:** a smooth cone wearing a hat, with no secondary cliff faces.

GPU-queued: at the CPU floor this is a gain, not a pass.
