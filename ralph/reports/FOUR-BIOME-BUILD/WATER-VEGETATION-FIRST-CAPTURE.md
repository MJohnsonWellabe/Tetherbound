# Water vegetation first production capture

Run: `.artifacts/water-vegetation-candidate-0909/run-20260909T233259230Z`.
Evidence paths below are relative to `.artifacts/water-vegetation-candidate-0909/`.
This checkpoint is held for further visual work and independent assessment.

## Technical result

- Guarded parser checks and production capture exited cleanly.
- Renderer: Windows Compatibility / OpenGL on NVIDIA GeForce RTX 3050.
- Capture manifest is complete with exactly two requested day frames and no failures.
- Final Godot process census was empty.
- Runtime vegetation: 10,437 instances total. Reedhaven received 1,273. Veilfall received only seven shrubs and no trees, groundcover, or rocks.
- Runtime placement used 96 m local visibility cells. Receipts list 400 exclusion points and 70 route segments.
- Rendered tree leaves use `derived/Leaves_NormalTree_C_desat55.png`; rendered bushes use `derived/Leaves_NormalTree_C_desat55_b100.png`.

Source hashes frozen for the run:

- `scripts/world/water_world.gd`: `E62A52DD00D7EEF9F34FAABD02F5B285C6928FAE1958F7C62007BAB72C186DD1`
- `scripts/world/water_vegetation.gd`: `3086D2F270A077F6C3BBE84F45184F1E368FB44EC09E224FF8AABCEAE92F85A8`
- `data/config/water_vegetation.json`: `1F3D412A0BEED66EB3F27B55A4A469053A7FC04790547BA4FC7FA9D2C6D6D40A`
- capture probe: `8EF41FE3C1EA8A06A553EAC059BCDD1A762B6777B06428AE838D530B359FF260`

Evidence:

- `run-20260909T233259230Z/result.json`
- `run-20260909T233259230Z/captures/manifest.json`
- `run-20260909T233259230Z/captures/vegetation-receipt.json`
- `run-20260909T233259230Z/captures/water__reedhaven__03__reedhaven_woven_hall__day.png`
- `run-20260909T233259230Z/captures/water__veilfall__15__the_veilfall_cascade__day.png`

## Visual result

Reedhaven gains readable green tree and shrub framing while keeping the route and actors clear, but its immediate foreground remains sparse and the broad terrain texture still reads mottled. This is an improvement candidate, not visual acceptance.

Veilfall visibly fails. The seven shrubs do not read in the frame. Bare repeated canyon walls and the broad curtain dominate the background, while the close creature party blocks much of the foreground. The steep 620 m radial terrain rejects the random vegetation strategy here. The next pass must use supported authored geological shelves and camera-visible groves around the gate rather than raising global density.
