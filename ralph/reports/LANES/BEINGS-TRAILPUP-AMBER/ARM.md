# BEINGS-TRAILPUP-AMBER: amber paws and eyes on the live coyote (F36#83)

**Status: CPU-ready, NOT queued.** Three of my arms are in the current GPU batch. Coordinator: take it when a slot frees.

**Row:** F36#83 Trailpup poses, GPU High 6.53.

**Defect, quoted (G-things-t4-rescore, 3/3):** "no amber paws or eyes, so the recorded 'stock animal' defect is still PRESENT". Owner pick, 1 Nov: "Trailpup concept 1 (nearly real coyote, glowing amber paws and eyes)".

## Cause, and how it was confirmed
The owner-picked remake that carried the amber glow is held OFF (`remake_owner1101_trailpup`: Stormtrail shares its mesh and the remake lost twice to the installed coyote, 6.70 against 7.37). So the game shows the installed `nat1024` coyote, which has no emission map at all: the live albedo is `creature_trailpup_nat1024_Image_0.jpg` and no enabled coat flag keys it. The CPU base frames show a plain coyote with no elemental trait. That is the whole defect: the trait was never on the model that ships.

## Change
`data/config/creature_coat_flags.json` `beings_trailpup_amber` (OFF): the live albedo gets a coat with
- an emission map: paws glow amber (full below 6% of standing height, fading out by 15%, fur grain kept), and the two irises glow amber;
- an albedo copy with the paws warmed and the irises amber, so the trait still reads where emission is weak.

Both textures are derived from the live albedo and the model's own UVs by `derive_amber.py` in this folder. No new art, no Meshy. Glow covers 5.5% of the surface. The coyote's coat, silhouette and size are untouched. Stormtrail wears its own texture and does not change (checked on CPU: paws identical; only its drifting motes differ run to run).

This is the owner's stated trait for this species (one elemental trait: glowing eyes plus glowing markings), not a recolour.

## CPU before and after
`_sheet_cpu_base_top_arm_bottom.jpg` (judges' crop; hit 000, hit 050, faint 050, faint 100). Arm: four amber paws in the standing and hit tiles, one lit paw tucked under the body in faint 050, pale amber paws in faint 100. The eye is a small amber dot at this distance.

## By-eye line for the GPU lane
`trailpup-hit-000`: all four paws are amber and brighter than the legs above them. If the paws look like the base's cream fur, hold. Also check the amber does not clip to white or lemon yellow on High; if it does, lower `emission_energy` from 1.3 to about 0.9 before judging.

## Risks and no-loss frames
- Hue: on CPU (LDR) the first try read lemon; the amber was deepened (1.0, 0.48, 0.07). Forward+ glow may brighten it again.
- "Glowing socks": if judges call the paws painted-on, the next step is thin amber lines running up the lower legs, not a brighter paw.
- Eyes barely read at stage distance; the row may still say "eyes not visible".
- Red rule: the test checks no texel of the glow is red (green stays above a third of red).
- The faint still reads as belly-up to some judges; this arm does not touch poses.

## Landing notes
Flag ON with `_why_on`; turn `test_flag_is_off_and_declares_scope` into an ON pin. Grep `tests/test_dark_value_lift_flags.gd` `LATER_COATS`: this coat does not override a value lift (Trailpup has none), so no entry should be needed; run that file to confirm.
