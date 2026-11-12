# The 8 lowest GPU High rows not in the build queue (LANE-SCOUT, 9 Nov 2026)

- **Source:** every GPU High mapped score in `GPU-PASS/1108/` (A, B and the four F biome files), lowest first.
- **Left out, because the coordinator's build queue covers them or a shipping arm already does:**

  | Rows | Covered by |
  |---|---|
  | F38#24, F38#30 | Warrens |
  | F39#29 | Nerissa |
  | F38#28, F38#2, F38#14, F38#7 | Creature rim / ghost-glow |
  | F41#5, F41#4, F41#2 | Stormwood ground and rain |
  | F38#17 | Banner |
  | F38#27 | Settings |
  | F38#3 | In the build queue |
  | F40#3, F40#6, F40#11 | F40 capture fixes |
  | F41#13, F41#15 | `charged_1105` and the albedo arm, shipping |
  | F41#21 | Section C `victory_on` arm, 7.13, shipping |

- **Note on F40#6 and F40#11 (5.10 and 5.50):** they would otherwise top this list. Their visual defect (the rider sliding upright down the cliff over cloud puffs) still needs a scene fix once the capture is fixed.

| # | Row | GPU High | Judges' named defect | Likely object or config | Kind |
|---|---|---|---|---|---|
| 1 | F39#21 named fight victory hierarchy | 4.75 | The "Officer Venn defeated" reward is a small top-right toast over the full exploration HUD (roster, quickbar, hint bar, gather prompt); no focus beat on the defeated officer (PRESENT 3/3). | Hide the exploration HUD during the victory beat and centre a gold reward panel. That is the same recipe as the F41#21 `hud.victory_focus` / `victory_on` arm (UIPOSES), applied to Tidewake named fights. | **config arm** (if `victory_on` is shared across biomes; otherwise small code) |
| 2 | F41#8 named character silhouettes | 5.31 | Named roles (Rodkeeper Hesk, Elder Maud, Warden-elect Bryn) are small and alike at normal distance; one body serves three roles. | Hesk, Maud and Bryn all use `local_historian` (`stormwood_npcs.json`). Give each its own appearance variant: headwear, held prop or recolour, via `appearance_variants` and `npc_role_accessories.json`, the recipe used for F41#20. | **config arm** (recolour plus accessories from installed parts); new_art for distinct bodies |
| 3 | F38#8 Fly carrier grip pose | 5.46 | The trainer hangs rigidly under Galecrest, arms straight up and legs straight down; the bird reads as perched on the hands (PRESENT 3/3). | The trainer fly-grip pose: bend the elbows, trail the legs back with bent knees (bone offsets like `post_stance.gd`). Also take the glide frame at cruise height. | **code** (pose offsets), plus a capture-stand fix |
| 4 | F38#32 camp and workshop prop legibility | 5.66 | Props overlap; a large foreground CAMP sign fills the lower left of frame 3; a row of white shapes on the horizon reads as scatter or an artefact (PRESENT 3/3). | Camp prop placement in the camp dressing config: space the tent, bed and bonfire, and move the CAMP sign out of the stand's foreground. Find what the horizon white row is (likely distant scatter cards). | **config arm** (placement) |
| 5 | F39#8 Aquaryn mounted-water pose | 5.66 | Aquaryn sits on a flat white foam disc with no wake or bob (B.md). | The mount's water-contact VFX: replace the foam disc with a bow wake and V trail, and add a slight bob. | **code / VFX** (installed particle materials) |
| 6 | F40#9 named NPC post readability | 5.72 | Named NPCs are small and sit behind the trainer or trees (PRESENT 3/3). | Post spots in the Cloudreach NPC placement config: move Sora 3–4 m out of the arch shadow, move Maela clear of the trunks, and clear grass in a 2 m disc at Tavi's pad. F38#35 showed pose work is flat at this size. | **config arm** (placement plus grass clearing) |
| 7 | F38#1 creature collapse and rest | 5.76 | The fainted Terrapup in frame 3 is a pale, see-through sprawl that reads as floating; faint and rest share one pose (PARTIAL 3/3). | First re-check under ghost-glow: the see-through part is likely the creature rim that ghost-glow tones. Then give Terrapup a resting pose distinct from the faint (curled, or sternal with the head up). | **config arm** (re-capture with ghost-glow), then **code** or animation choice |
| 8 | F41#1 Stormheart finale | 5.78 | An interior with walkways, lanterns and banners but no crown or core in view; lightning drawn as flat white line strokes; four identical royal-blue banners at equal spacing. | Banner variation (two sizes, uneven spacing, muted storm blue) in the Stormheart dressing config. Replacing the polyline lightning with mesh lightning is code. All three judges list a visible crown and core as new_art. | **config arm** (banners), **code** (lightning), **new_art** (crown and core) |

**Just above the list:**
- F41#3 actor spacing, 5.78: Sparkit sits inside Voltarach's legs. Fix with a fight spacing rule or a boss-body fade (code). The rim arm was flat; see `G-f41-fight-rim.md`.
- F38#31 alpha read, 5.85.
- F40#8 route markers, 5.85.
