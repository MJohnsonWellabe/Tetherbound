# Tidewake close-1024 round fc3: softer Veilfall terraces, CPU pre-judge (25 Oct 2026, CT)

## What changed from fc2 (OFF in play, same sections)

- **Terraces:** `water_world` `terrain.veilfall_summit_cap` went from 22 m tiers with 0.3 risers to 28 m tiers with 0.65 risers, then rebaked. The same six regions differ from shipping.
- **Ledges:** `rock_ledges` went from #4d6638 at 0.85 (only tops flatter than 0.80) to darker #3d5030 at 0.7, flatter than 0.85.
- **Unchanged from fc2:** crown, falls and rain veil.
- **Tests:** relief-walk and geometry tests re-run and passing (5 tests, 627 assertions).
- **Comparison:** fc2 against fc3, head to head on the 750 m stand. The fc2 round already measured fc2 against shipping at +0.71.

## Mapped Bar A

- **Yardstick:** standard prompt, three code-blind judges, 3 anchor pairs (seed 19077).
- **Calibration:** slope 1.16, r 0.99, anchor RMSE 0.17.

| Set | fc2 | fc3 | Δ | Judges |
|---|---|---|---|---|
| Veilfall vista, clear and rain | 4.41 | **5.34** | +0.93 | higher x3 |

**Defect changes:**
- **Procedural zigzag/sawtooth terraces:** PRESENT x3 → PARTIAL x3.
- **Blocky heap / smooth cone:** PRESENT in both sides, all judges. Read head to head, both are a cone with a cap.
- **Flat-sheet falls:** PRESENT in both sides.
- **Rain fog flattens:** PRESENT in both sides.

## Disposition

The config stays at fc3, still OFF in play. Its head-to-head gain over fc2 stacks on fc2's +0.71 over shipping, so fc3 is the Veilfall candidate queued for the GPU.

## Remaining (all three)

1. **Silhouette:** a smooth cone with a crown on top. It needs secondary cliff masses or buttresses on the flanks.
2. **Falls:** thin white sheets with no mist or plunge pools, and no falls on the lower mass.
3. **Rain:** the landmark still greys to one mid-tone. The darker cliff value needs to survive the fog.

All three name a new hero mesh as the next big gain.
