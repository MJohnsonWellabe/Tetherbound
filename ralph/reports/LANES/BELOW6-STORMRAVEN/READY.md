STATUS: land

F41#13 Stormraven night coat (`below6_stormraven_night`, ON). GPU High, G-below6-stormraven-r3.md (tb/item-scout-1108 23aba198): 5.76 -> 6.67 (+0.91, 3/3). Needs Medium before the row can close.
Files: `data/config/creature_coat_flags.json` (main's file plus this one flag), the two textures and their `.import` sidecars (`_Image_0_night.png`, `_glow_read_r2.png`), `tests/test_below6_stormraven_night_landed.gd`, `tests/test_dark_value_lift_flags.gd` (adds this coat to LATER_COATS), this report folder. Nothing else from tb/below6.
Checks: coat, remake, charged, below6, value_lift tests pass; `texture_import_policy.py --check` passes.
