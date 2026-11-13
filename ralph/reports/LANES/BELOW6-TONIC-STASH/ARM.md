# BELOW6-TONIC-STASH: the stashed tonic stands on a crate (F38#12)

Row: F38#12 harvest reward identity (GPU High 5.89, PARTIAL 3/3). Frames: Basic Orb basket, travel pack, stashed attack tonic.

Of the three, the tonic is the weakest read: a bare 0.3 m vial alone on the grass with a small glow, where the orb has its basket and the pack is trainer-sized.

## Arm

- `data/config/harvest_stash_support.json` `enabled` (OFF) is the switch. Overlay: `overlay.json`.
- The band-3 tonic node (`data/config/bands/band3_the_river_lock/harvest.json` order 3019) carries `visual.stash_support_1113`: an installed wooden crate (`quaternius_fantasy/Crate_Wooden.gltf`) 0.55 m tall, with the node's own tonic model on top shown at 0.62 m.
- `scripts/world/harvest_node.gd` `_stash_support_visual` builds it. Visual only: the anchor, prompt, reward and collision are unchanged. No other node has the block.

## CPU

`_sheet_cpu_base_left_arm_right.jpg`: `phase2_capture_world_inventory.gd --biome=meadows --subset=meadows__inventory__harvest__attack_tonic --seed=2042`, cropped. The vial now stands at about chest height on a crate and reads as something left there on purpose. The switch file was added after this capture; the capture used the node block directly, which builds the same visual.

The other two frames are unchanged by this arm. If the row needs more, the next step is the same treatment for the travel pack (a stump or rack under it) and a lid or cloth on the orb basket.
