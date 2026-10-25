# Tidewake close-1024 round vv1: the re-seated Veilfall vista, shipping vs t1e vs t1e + Meshy hero pieces, CPU pre-judge (25 Oct 2026, CT)

**Views:** `veilfall-vista` and `veilfall-vista-rain` (F39-look.json, T3). The camera sits 200 m offshore, looking back at the mountain, the falls and the sea.

**Arms:**
- shipping;
- `current_flow` (t1e);
- t1e + `veilfall_hero_candidate` + `veilfall_facade_candidate`: the Meshy cascade tiers, plunge rocks and cliff facade from tb/meshy-1024, already integrated OFF.

## Mapped Bar A

- **Yardstick:** standard prompt verbatim, three fresh code-blind judges, 3 anchor pairs (seed 8853).
- **Calibration:** `calibrate.py` slope 1.04, r 0.88, anchor RMSE 0.66.

| Arm | Mapped | Judges |
|---|---|---|
| Shipping | 3.92 | |
| t1e currents | **5.06** | higher x3 (4.6 vs 3.4-3.6) |
| t1e + hero pieces | 4.82 | lower than t1e x3 |

## Findings

- **Road markings:** at this distance the foreground current lane's white chevrons and yellow dashes are "the worst artefact in the batch" (PRESENT x3 on shipping). t1e removes them (FIXED x3).
- **Hero pieces:** at 200 m they read as "small pale blocky ruin pieces, pasted on or floating in the gully". They stay OFF, as on the close-up (vf2 parked, vf3 lost).
- **Unchanged x3:**
  - the mountain is "a heap of faceted boulder chunks on a dark cone";
  - the small upper fall is "a flat white quad with a cross-shaped mist puff";
  - rain fog flattens the island to one grey mid-tone.
- **The mountain is new art:** Meshy request 10 (`veilfall_terraced_mountain`) is posted.

## GPU capture

`F39-look.json --views=veilfall-vista,veilfall-vista-rain`, without and with `--tidewake-look-sections=current_flow`.
