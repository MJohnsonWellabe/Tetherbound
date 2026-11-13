# BEINGS-OFFICER-FACES-NYSA-HAIR: Nysa apart from Varga without changing her face (F41#8, F41#18)

**Status: ready to queue.** The gender-neutral option the coordinator asked for (13 Nov). Overlay turns on `beings_stormwood_nysa_hair` only.

**Defect (3/3, G-below6-staticub-fur-dialogue-c673):** "Officer Nysa shows the same male face and portrait as Lieutenant Varga."

**Cause:** both trainers use `humanoid_key` `officer_a` with no variant.

**Change:** Nysa keeps her officer_a face and the judged uniform cloth; her hair goes ash-silver in the body texture (`officer_a_lod0_texture_0_vis1_cloth2_nysa.png`, built on the cloth texture) and in a matching plate (`npc_identity_stormwood_nysa_hair.png`, eyes and face excluded). Made by `../BEINGS-OFFICER-FACES/derive_officer_hair.py --nysa-neutral`. Varga is untouched. Nysa's presented gender is unchanged.

**Held, not in any overlay:** `beings_stormwood_nysa`, which would move Nysa to an officer_b copy (a woman's face). The game never states Nysa's gender, so that is the owner's call; the coordinator has asked. The record is OFF and attached to no trainer.

**CPU:** `_sheet_cpu_sera_maren_nysa_varga.jpg`: Sera, Maren, Nysa (this option) and Varga with their plates.

**By-eye line:** in Nysa's frames her hair is ash-silver and Varga's is black. If both are black, hold.

**Risks and known limits:**
- This keeps the shared face, so judges may still say "same face as Varga". It answers the hair-and-plate half of their ask only.
- On the body the top and back of the hair turn grey-silver, but the forelock over the forehead stays near-black: it lies inside the box that protects the eyes and brows. Two other selections (a narrower box; selecting dark texels by how much skin surrounds them) did not move the forelock and the second turned one eye grey, so this version is kept. The plate is fully silver.
- At gameplay distance the difference from Varga is smaller than on the plate. If the judges see no difference in the world frames, the next step is the owner's answer on the face, not more hair passes.

**Capture:** `CAPTURE.json` (Stormwood dialogue; judge Nysa and Varga together).

**Tests:** `tests/test_beings_officer_faces_flag.gd` (including that the held record is unattached) and the character tests, 96 tests, 0 failed.

**Landing:** record ON with `_why_on`; update the OFF assertions for Nysa.
