STATUS: land

Hard rule fix: Fulgocobra's copper collar plates ship as gunmetal slate (`below6_fulgocobra_slate_collar`, ON). GPU High, G-cw-collar-wardenring-r2.md (tb/item-scout-1108 d958f1cc): F36#46 pose stage 5.29 -> 5.70 (+0.41, 3/3), Stormwood world states 6.12 -> 6.54 (+0.42, 3/3), no set loses; 0 red pixels on every arm pose frame.
Files: `data/config/creature_coat_flags.json` (main's file plus this one flag), `creature_fulgocobra_owner1101_Image_0_face_slate.png` and its `.import`, `tests/test_below6_fulgocobra_collar_landed.gd`, this report folder. Nothing else from tb/below6.
Checks: coat, remake, charged, below6, value_lift and colourway tests pass (73 tests); `texture_import_policy.py --check` passes.
