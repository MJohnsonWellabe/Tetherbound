# SCENE-CACHE: found rewards staged as a traveller's cache (F38#12)

Row: F38#12 harvest reward identity, GPU High 5.89 (G-rescore-stale-tier2; raw 5.5, 5.6, 5.5; PARTIAL 3/3). Recorded defect: "Several reward harvest nodes read as generic crates or vegetation without a clear visible connection to their named item." Frames: stashed attack tonic, Basic Orb cache, dropped travel pack.

**This arm replaces BELOW6-TONIC-STASH** (queued, not captured). Its overlay turns on the tonic crate as well, so only one of the two should be judged.

## Cause, and how it was confirmed

On the three GPU frames (`tb/gpu-frames-1108`, `G-rescore-stale-tier2/F38-12/main/High`) each reward already shows its own item: a vial, a basket of orbs, a pack. The recorded "generic crate" is gone, which is why the defect is PARTIAL rather than NOT_FIXED. What holds the score is staging: each one is a single small object alone on bare lawn, with nothing that says someone left it there. The tonic is a 0.3 m vial with a halo; the orb basket and pack have no setting at all. Checked by eye on the frames; there is no hidden object or wrong model to fix.

## Arm

- Switch: `data/config/harvest_stash_support.json` `cache_dressing_enabled` (OFF) and `enabled` (OFF, the inherited tonic crate). Overlay: `overlay.json` turns both on.
- `scripts/world/harvest_cache_dressing.gd` builds a node's `visual.cache_dressing_1113.props`: installed props at stated offsets round the reward, each rested on the ground under it. Visual only: no collider, prompt, claim or save change; the props leave with the node when it is taken.
- Three nodes carry a block:
  - order 1029, "A cache of orbs": a wooden chest behind the basket, a small creature cage, a sack and a rope coil.
  - order 1030, "A dropped travel pack": a cold stone fire ring with a cauldron on it, a camp stool and a bucket. An abandoned camp, as the node's own note says ("a pack left by whoever was here before").
  - order 3019, "A stashed tonic": the vial on its crate (BELOW6's block) with a barrel, a second crate, a pouch and a rope.
- All props are from families already in the world (Quaternius fantasy props and the camp stone ring).

## CPU (Compatibility, Low)

`phase2_capture_world_inventory.gd --biome=meadows --subset=…orb_basic --subset=…travel_pack --subset=…attack_tonic --seed=2042`. `_sheet_cpu.jpg`: top row base, bottom row arm. Two earlier CPU rounds used a Kenney log, bedroll and fire pit (flat salmon-pink, off-style) and then a nature log that did not show; both were replaced.

## By-eye line for the GPU lane

On `meadows__inventory__harvest__attack_tonic`: the vial stands on a crate with a barrel beside it. On `…orb_basic`: a chest stands behind the basket and a dark cage beside it. On `…travel_pack`: a cauldron on a ring of stones to one side, and a bucket on the other. If the rewards still stand alone on the grass, the switch did not apply: hold the arm.

## Risks and no-loss frames

- The defect text names "generic crates". The tonic vignette uses crates and a barrel as a setting; the vial is the subject on top. If judges read it as "a crate again", drop `enabled` and keep `cache_dressing_enabled`.
- Only these three nodes change. F38#6 (ground pickups) does not use harvest nodes and must be identical.
- `tests/test_harvest.gd` stalled on BELOW6's machine with the switch on or off (their note); not re-run here.
