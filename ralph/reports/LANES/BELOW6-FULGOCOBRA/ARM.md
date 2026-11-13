# BELOW6-FULGOCOBRA: olive scales with glowing gold veins (F36#46, F41#13)

Rows: F36#46 Fulgocobra (5.87) and F41#13 electric creature finish (6.67 after Stormraven r3; the judges name Fulgocobra as the bigger remaining gap).

Recorded defect (G-below6-stormraven-r3, 3/3): the board shows olive-black scales with glowing gold vein lines; in game the snake is navy with painted gold bands that "read as decorative stripes", and the copper throat plates look bolted-on.

## Arm

`data/config/creature_coat_flags.json` `below6_fulgocobra_olive_veins` (OFF). Overlay: `overlay.json`. Two derived textures, made by `make_olive_veins.py` from the live coat (no Meshy generation):

- `_Image_0_olive.png`: dark scales turn olive, the gold bands sink into olive-brown except their centre line, copper plates go to dark bronze, the cyan arcs and eye turn gold.
- `_glow_vein_r1.png`: emission on the vein centre lines and the former arc cracks only, all gold. Energy 1.5.

One element colour, same mesh, silhouette and scale pattern, no red.

## CPU

`_sheet_cpu_idle_base_left_arm_right.jpg`, `stormwood__fulgocobra__idle`, seed 2042. The body reads olive-black with thin bright lines across the coils and hood, and the throat plates sit in the body. The sheet was captured at emission 2.2, where the lines clip to near-white on CPU; the flag now ships 1.5. If the GPU pre-check still shows white lines, lower the energy; if they are too faint, raise it toward 2.0.

Not from this arm: the trainer stands on an NPC's head in this stand (creature stand overlaps a post), in base and arm alike.
