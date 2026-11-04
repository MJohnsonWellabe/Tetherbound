# Visual lane v1/b10 and b11: remaining Stormwood items, sw_base vs sw_cand (3 Nov 2026, ~17:25 UTC)

**Arm:** the Stormwood overlay (`/tmp/claude-0/work/sw_overlay.txt`). It contains the character rim, role accessories, dialogue lens, fight fade, the Crown Arch and Glass Sink landmarks, the Glass Sink dark pool, road puddles, harvest round 2, pickup tiers, the Stormheart hollow floor and deck light, and lantern arrival pools. The arm is ON vs this branch as shipped. Base and candidate come from the same CPU run (Stormwood items, 10 boots each, `job.json` repro commands), on CPU llvmpipe in Compatibility mode.

**Yardstick:** JUDGE_PROMPT verbatim, 3 anchor pairs per batch, three fresh code-blind judges per batch, `calibrate.py`:
- **b10:** linear, slope 1.29, r 0.97, anchor RMSE 0.20. Warning: some candidates are extrapolated more than 0.5 outside the anchors' range.
- **b11:** linear, slope 1.10, r 0.85, anchor RMSE 0.61, no warnings.

| Row | Item | CPU base (mapped) | Overlay ON (mapped) | Decision |
|---|---|---|---|---|
| F41#11 | portrait identity | **6.90** | 6.86 | **at or above 6.0 as shipped**; no change |
| F41#12 | charged road | **6.08** | 5.70 | **at or above 6.0 as shipped**; road puddles stay OFF (3/3 call them flat lavender slabs) |
| F41#14 | candy pickup tiers | **6.13** | 5.61 | **at or above 6.0 as shipped**; the puddles in the candidate cost it |
| F41#9 | harvest node material | 5.87 | 6.00 (+0.13) | held: the gain is within noise, so `stormwood_harvest_hero2` alone gets its own capture |
| F41#18 | uniform readability | 5.58 | 5.98 (+0.40) | held at 0.02 short: the rim lifts the officer (A "pale grey separates", B "blends"); next arm is a stronger rim or a pale trim |
| F41#10 | Glass Sink | 4.45 | 4.92 (+0.47) | held; still a terrain edge over a tiled plane. Next is a Blender basin (new art) |
| F41#8 | named silhouettes | 5.52 | 5.35 | OFF; the puddles return in the candidate |
| F41#19 | Glass Field spike bases | 5.58 | 5.58 | no change from the overlay; needs a slab and base fix |
| F41#20 | named dialogue | 5.25 | 6.42 | **not trusted**: base frame 1 (Fenn) rendered a fully black world (3/3 judges). The lift comes from a capture fault, not the arm. Recapture the base. |
| F41#7, F41#15 | dialogue frames | n/a | n/a | not captured in either run (no matching frames); still unscored |

**Common judge asks (Stormwood):**
- Break the tiled leaf carpet into groves and clearings.
- Add a storm key and rim light, plus white-violet lightning.
- Replace the flat lavender puddle decals.
- Pull the fight camera out of the canopy.
- Give Fenn and Oswin their own portraits.
