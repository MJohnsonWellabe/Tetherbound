# G-below6-namedposts: storm-lantern posts beside the Stormwood named villagers (F41#8; GPU High)

## Verdict: DO NOT SHIP
Both sets lose, and all three judges prefer base in each.

| Set | Base | Arm | Gain |
|---|---|---|---|
| F41#8 row | 5.92 | 5.43 | −0.49 |
| Named-villager dialogue frames | 6.38 | 5.65 | −0.73 |

The post does not light the villagers into the scene. It puts a bright prop beside them, and its light blows out their faces and the player's.

## Frames
- **Source:** `tb/gpu-frames-1108` 119fdc336, High, `phase2_capture_dialogue.gd` seed 2042.
- **Build:** `tb/below6` 0c220406a on both sides, no import.
  - **base:** overlay off.
  - **arm:** `BELOW6-NAMEDPOSTS/overlay.json` (`named_posts_1112`, read by `stormwood_named_posts.gd`): one storm-lantern post per villager.
- **Frames:** the F41#8 row (elder_maud, rodkeeper_hesk, warden_elect_bryn inventory frames), plus their `__dialogue` frames. Dialogue blend is 1.000 on all frames. 0 script errors, 0 blank.
- **GPU lane pre-check (mean L of the villager box, base → arm):** Maud 130 → 156, Hesk 110 → 127, Bryn 102 → 120. The player also brightens by about +16, so the contrast between villager and player barely changes.
- **Render check:**
  - Row: mean difference 5.5, 17.8% of pixels changed.
  - Dialogue frames: mean difference 11.1, 27.2% of pixels changed.

## Batch `G-np`
- Three code-blind judges, standard prompt.
- Two sets: the row stacked, and the three dialogue frames stacked.
- Anchors: craft, f36_0_npc:C1 and f10_2_r3_capacitor. This is a confirming batch.
- **Fit:** linear, slope 1.3544, intercept −1.6154, r 0.918, RMSE 0.548. No warnings.

## Results

| Set | Base raw → mapped | Arm raw → mapped | Gain | Prefer arm |
|---|---|---|---|---|
| F41#8 row (3 inventory frames) | 5.5, 5.6, 5.6 → 5.92 | 5.1, 5.2, 5.3 → 5.43 | **−0.49** | 0/3 |
| F41#8 dialogue (3 frames) | 5.7, 5.8, 6.2 → 6.38 | 5.3, 5.3, 5.5 → 5.65 | **−0.73** | 0/3 |

### What the judges see (3/3)
- **Row:**
  - The post "competes with the characters' silhouettes" and "hides part of the elder".
  - "Bloom blows the trainer out to white in all three frames" and turns heads "into white glow".
  - It "pools orange on the mud".
- **Dialogue:**
  - The post "fills the left third of all three conversations".
  - "Elder Maud's hair and face are blown out", and "its emissive head and the bloom crowd the speaker".
  - Base is "cleaner ... the cottage reads behind Maud".
- **Recorded defect** (the repeated named-role silhouettes): PARTIAL 3/3 on both sides. The post does not address it.

## What holds F41#8 down (3/3, both sides)
1. **Repeated silhouettes** among the background sentinels and the small tan-vest figures. Judges ask for new art: distinct outfits and faces.
2. **Portrait mismatches.** "Rodkeeper Hesk's portrait shows a young dark-haired boy while the in-world speaker is a bearded man in a hat. Warden-Elect Bryn reuses the same portrait."
3. **Overexposed faces.** Speakers' faces burn orange-white, and the player blooms white at the frame edge even on base.
4. **Off-palette colour and hard edges.** Salmon-pink bears, cobalt wolves, and hard black path patches.

## Recommendation
1. **Drop `named_posts_1112`.** Lifting the villagers needs a bloom and emissive clamp on characters, not more light.
2. **Fix the portraits:** give Hesk and Bryn their own portraits, matched to their world models. This is a data fix and can ride along.
