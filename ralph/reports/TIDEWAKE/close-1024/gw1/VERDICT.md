# Tidewake close-1024 round gw1: beach-grass keep and shore water, each against t1e + surf + vary, CPU pre-judge (25 Oct 2026, CT): LEVEL, both stay OFF

## Arms (OFF in play)

- **`dune_grass_candidate`:**
  - **Finding behind it:** a toggle-off probe (`water_ground_cover` disabled) proved the even tufts and pebbles are the ground-cover grass field.
  - **Cause:** inside colonies the shader keeps every lattice point (density 1.1), so tufts stand on the lattice.
  - **Change:** density 0.6 and wider bare gaps (dune_gap 0.36/0.50).
- **`shore_water_candidate`:** the shipping colours, a mid stop at 3 m, falloff 5 → 11 m, band break 1.0, wave_strength 0.30.

## Result

- **Yardstick:** standard prompt verbatim, three fresh code-blind judges, 3 anchor pairs (seed 12283).
- **Scores:** every judge scored both arms the same as the base on Deep Watch and on the shore, within 0.1 or 0.2.
- **One judge:** "I could not see any difference."
- **Grass:** the change is visible in a direct crop (sparser, randomly kept tufts). It does not move the read at contact-sheet size.
- **Water:** the softer step is too subtle to register.
- **Both stay OFF.**

## What the judges keep naming, all three, every shore batch

1. A depth gradient with no hard navy band.
2. A foam body and wet-sand band at the surf.
3. Grass in dune-edge clumps, and pebbles in wrack lines.
4. Driftwood and rock groups as anchors.

- Items 3 and 4 need authored placement, not a density setting.
- The hard band has now resisted three water tries.
