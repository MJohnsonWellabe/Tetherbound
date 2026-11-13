# BELOW6-FULGOCOBRA-COLLAR: collar plates off the reserved red (hard rule)

Hard rule: red and oxblood are Team Tether only. G-things-wardenring-f41-13-closeout (LANE-SCOUT, tb/item-scout-1108 7d2ccb33b), 3/3: Fulgocobra's "copper-red collar plates" sit near the reserved red range.

## Arm

`data/config/creature_coat_flags.json` `below6_fulgocobra_slate_collar` (OFF). It is the live coat (`lanekit_face_read_fulgocobra`: same glow map, rim, roughness and specular) with one change, the albedo:

- `creature_fulgocobra_owner1101_Image_0_face_slate.png`, made by `make_slate_collar.py` from the live coat's albedo. Copper pixels (hue within 32 degrees of red, saturated, mid to bright; 5.3 percent of the texture) become gunmetal slate, keeping their shading. The blend is done in RGB, so half-copper edge pixels do not pass through green.
- Gold bands, navy scales, cyan arcs and the eye are untouched.

Fulgocobra only. No Meshy generation. Overlay: `overlay.json`. Kept separate from the faint arm so each can be judged on its own.

## CPU

`_sheet_cpu_stage_base_left_arm_right.jpg`: creature stage, `capture_f36_poses.gd --species=fulgocobra --game-clips --clear-ruler --roles=hit --whole-body`, frame hit-000, cropped. The collar plates and the head crest go from copper-orange to dark gunmetal. Strongly red-orange pixels in the full frame: 1719 on base, 478 on the arm (the rest is the trainer's hair and jacket trim).

## Note for landing

If both this and the faint arm ship, they do not conflict: one is a coat flag, the other a pose scope. If a later coat for Fulgocobra is built, it should start from the slate albedo.
