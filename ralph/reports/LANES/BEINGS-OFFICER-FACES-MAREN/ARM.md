# BEINGS-OFFICER-FACES-MAREN: Maren apart from Sera (F41#8, F41#18)

**Status: ready to queue** (coordinator's split, 13 Nov). Overlay turns on `beings_stormwood_maren` only.

**Defect (3/3, G-below6-uniform-cloth-c673):** "Lieutenant Sera and Officer Maren share one face, coat and portrait."

**Cause:** both trainers use `humanoid_key` `officer_b` with no variant (`stormwood_trainers.json`); the game's own resolve gives them the same body, texture and plate.

**Change:** Maren keeps officer_b; her hair goes chestnut-honey in the body texture (`officer_b_lod0_texture_0_vis1_maren.png`) and in a matching plate (`npc_identity_stormwood_maren.png`). Hair chosen by position on the model and the plum hue, face excluded; made by `../BEINGS-OFFICER-FACES/derive_officer_hair.py`. Sera is untouched. Presented gender unchanged.

**CPU:** `_sheet_cpu_sera_maren.jpg` (Sera, Maren, the Nysa face-swap option and Varga, with plates; only the first two matter for this arm).

**By-eye line:** in Maren's dialogue frame her hair is chestnut-honey, not plum like Sera's. If it is plum, hold.

**Capture:** `CAPTURE.json` (Stormwood dialogue; judge Sera and Maren together).

**Tests:** `tests/test_beings_officer_faces_flag.gd` and the character tests, 96 tests, 0 failed.

**Landing:** record ON with `_why_on`; update the OFF assertions in `test_beings_officer_faces_flag.gd` for Maren.
