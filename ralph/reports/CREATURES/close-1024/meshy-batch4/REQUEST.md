# Meshy batch 4 (Creatures lane, 25 Oct 2026): identity-true naturalistic remakes for F36#0 / F36#1

Same route as batches 1-3 (image-to-image concept with the identity reference + `style_wolf.png` + `style_bear.png`, then multi-image-to-3D textured; deliver to `tb/meshy-1024` under `assets_raw/naturalistic-1024/<species>_b4/`).

Why:
- **Mosshock:** the batch-2 remake judged 7.15 with its new faint (b12), but it came out a toad; the shipped Mosshock is a lava salamander, so it stays OFF (owner 22 Oct identity rule; coordinator 25 Oct). Redraft as the salamander: long low lizard silhouette, the shipped palette minus any red or oxblood, sprawl-friendly limbs.
- **Pebbik and Riptusk:** fail the F36#1 roster on material and style, not pose. Pebbik is a blotchy, noisy bake with near-maroon patches and reads only trainer-height (5.88 mapped, roster r5). Riptusk reads with a noisy plate surface and a tail that looks like a second head (6.50, r3).

Admission and footprint: nose-to-tail at most 1.8x standing height (Mosshock at most 5.3 m, Pebbik 5.9 m, Riptusk 7.6 m), which keeps each inside its footprint allowance and the Warrens/Hall rings with margin. Taller than the 1.80 m trainer at the installed heights. No red or oxblood. Flag-off until judged.

| Species | Target height | Max length | Identity reference | Prompt |
|---|---|---|---|---|
| mosshock | 2.95 m (ratio 1.64) | 5.3 m | `assets/creatures/tetherbound/mosshock/reference/side.png` + `front.png` | `mosshock.prompt.txt` |
| pebbik | 3.25 m (ratio 1.81) | 5.9 m | `assets/creatures/tetherbound/pebbik/reference/side.png` + `front.png` | `pebbik.prompt.txt` |
| riptusk | 4.25 m (ratio 2.36) | 7.6 m | `assets/creatures/tetherbound/riptusk/reference/three_quarter.png` | `riptusk.prompt.txt` |
