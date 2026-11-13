# PARKED (13 Nov): G-below6-fulgocobra-r2 DO NOT SHIP

F41#13 7.37 -> 6.91 (-0.46, 0/3); F36#46 5.94 -> 5.64 (-0.30, 1/3). The olive body "merges into the grass" and yellow is "off the white-violet Stormwood palette". The flag, both textures and the flag test are removed from tb/below6; `make_olive_veins.py` stays as the record. Keep base's navy coat.

# BELOW6-FULGOCOBRA: olive scales with glowing gold veins (F36#46, F41#13)

Rows: F36#46 Fulgocobra (5.87) and F41#13 electric creature finish (6.67 after Stormraven r3; the judges name Fulgocobra as the bigger remaining gap).

Recorded defect (G-below6-stormraven-r3, 3/3): the board shows olive-black scales with glowing gold vein lines; in game the snake is navy with painted gold bands that "read as decorative stripes", and the copper throat plates look bolted-on.

## Arm

`data/config/creature_coat_flags.json` `below6_fulgocobra_olive_veins` (OFF). Overlay: `overlay.json`. Two derived textures, made by `make_olive_veins.py` from the live coat (no Meshy generation):

- `_Image_0_olive.png`: dark scales turn olive, the gold bands sink into olive-brown except their centre line, copper plates go to dark bronze, the cyan arcs and eye turn gold.
- `_glow_vein_r1.png`: emission on the vein centre lines and the former arc cracks only, all gold. Energy 1.5.

One element colour, same mesh, silhouette and scale pattern, no red.

## Round 2 (after the GPU pre-check hold on r1)

The pre-check held r1: vein cores rendered near pure white (RGB about 251,251,231), the head went pale grey, and the eye glow was lost. Changes, same flag and file names (textures regenerated in place):

- Glow map: deeper amber (hue 40, saturation 0.95) at 72 percent value; emission energy 1.5 to 1.0.
- Vein albedo: a mid gold (value capped at 0.5) so rim plus emission does not push it to white.
- Head and hood plates: olive (saturation 0.30, value 0.66) instead of near-grey.
- Eye and arc cracks: gold at their full original glow strength, so the eye reads lit.

## CPU

`_sheet_cpu_idle_base_left_arm_right.jpg` (r2 crop of `stormwood__fulgocobra__idle`, seed 2042). Veins read yellow-gold on the coils and hood edge, the head is olive with a gold eye ring, and the throat plates are dark bronze. Pixels at L 230 or above in the crop: base 20789, arm 5901. CPU has no bloom, so the GPU pre-check is still the real test of the vein cores; the next lever is energy (try 0.8).

Not from this arm: the trainer stands on an NPC's head in this stand, in base and arm alike.
