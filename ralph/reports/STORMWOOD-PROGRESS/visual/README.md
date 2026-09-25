# Stormwood lane: in-engine visual evidence

Captured by `tools/capture_stormwood_lane_evidence.gd` in the production
`scenes/world/stormwood.tscn`. The run used xvfb and opengl3 on llvmpipe at
1280x720. Frames are JPG (quality 0.8).

- `after/` is branch `ralph/stormwood-landing` @ 4c115f141.
- `before/` is its merge-base with main, 47774c350. The same tool file was
  used and the only change was the checkout, so the stand points, camera and
  staged flags match `after/`.
- Each run's per-frame record (player/camera position, prompt text, open
  dialogue line, surge phase and staged flags) is in `after/frames_*.json` and
  `before/frames_before.json`.

## Camera and state

- **Camera.** Every frame uses the production player camera
  (`CameraRig/Camera3D`), following the real Player. No free camera or survey
  stand was used, and no frame uses the fight camera because no fight was
  captured.
  - Placement: one `Game.debug_teleport_to`, then the Player is set at the
    stand point facing the subject. The rig gets its target, yaw and pitch and
    settles on its own.
  - Close prompt views orbit the rig 12–28° off the trainer's back so the
    trainer does not hide the subject.
  - Dialogue frames are taken after the dialogue panel opens.
- **State.** Every frame is **staged state**; none was earned by play.
  - The tool sets progression flags directly (list below).
  - It pins the day/night clock.
  - For items 1–5 and the matrix frames it pins the Surge clock to Calm
    (elapsed 60 s).
  - The HUD still shows the fresh-save objective "Find Ashfoot Waycamp",
    because the chapter itself was not played.
- **Forest scatter.** Every outdoor frame in this set (items 1–4, and all
  matrix, surge and sky frames) shows the forest scatter from *before* the
  F09 forest re-bake. The forest will be re-captured after that re-bake.

## Frames

Before/after sheet for item 1: `sheet_crown_before_after.jpg`. Before/after
sheet for items 2–5: `sheet_items2to5_before_after.jpg`.

| Frame (after/ and before/) | Camera | State | What is visible (after) | Before (main) |
|---|---|---|---|---|
| `crown_rain_ledger_approach` | player | staged: `crown_reached`, `named:crown_guardian:cleared` | Trainer on the Crown meadow. The record stone is a small green rock mid-frame, about 13 m ahead. | Same view, no stone |
| `crown_rain_ledger_prompt` | player | staged (same) | Glass-green stone with a white glyph plate beside the trainer. Prompt: "Read the Crown record". | No stone, no prompt |
| `crown_rain_ledger_dialogue` | player | staged (same); opened by pressing interact | Panel "Crown Record: The Rain Ledger — glass tallies…". No portrait, so the portrait area is empty. | No stone, no panel |
| `crown_root_census_approach` / `_prompt` / `_dialogue` | player | staged (same) | Stone right of the trainer with its prompt. Panel "The Root Census — rings of names…". | Nothing there |
| `crown_reversal_mark_approach` / `_prompt` / `_dialogue` | player | staged (same) | Small stone ahead, with a wild fennec creature in the left foreground. Prompt and panel "The newest record is not written…". | Nothing there |
| `parcels_marl_prompt` | player | staged: `lantern_pools_linked`, `side_pims_parcels_1`, `…delivered:cook_marl` | Marl at Ashfoot in front of a cottage, with a wooden parcel crate about 1.5 m to his left. Prompt: "Greet Marl". | Same view, no crate |
| `hesk_report_prompt` | player | staged: `rootgate_released`, `side_dark_arches_1`, `side_dark_arches_2` | Rodkeeper Hesk beside the trainer. Prompt: "Greet Rodkeeper Hesk". | Same |
| `hesk_report_dialogue` | player (conversation push-in) | staged (same); opened by pressing interact, through the real NPC branch | Hesk dark-arches report: "The Rodline arch answers Lantern Hollow again…" | Hesk's ordinary line: "You came down from Cloudreach?…" |
| `arch_c_rodline_approach` | player | staged: `rootgate_released` | Dark blue-grey crenellated Rodline Long Road Arch (pair C) on a dark slab, 16 m away | Same (the arch exists on main) |
| `arch_c_rodline_prompt` | player | staged (same) | Arch close up. Prompt: "Relight Rodline Long Road Arch · 3 Stormglass", which wraps onto 2 lines. | Same prompt |
| `footing_verge_road_prompt` | player | staged: `arch_recipe_known` | Round pale-stone footing. Prompt: "Choose this footing for your road". | Prompt: "Inspect the old arch footing" |
| `stormheart_offer_prompt` | player | staged: `legendary_freed` (Marrow's auto-played release conversation was closed first) | Freed Stormheart cobra rearing inside the Dynamo core. Prompt: "Accept the Stormheart's offer". | Same prompt |
| `stormheart_offer_yes_no` | player | staged: the conversation was started with `DialoguePanel.start("stormwood_stormheart_offer")` and advanced to its last line. The real path needs a host claim for a fight participant. | Panel: "Will you walk out with the Stormheart? Yes: … No: it stays free." with **E Yes / Esc No** | Last line is "The Spark it guarded is yours either way…" with only "Close" (no Yes/No) |

ACCEPTANCE §4 matrix, after only (`sheet_matrix.jpg`):

| Frame | Camera | State | What is visible |
|---|---|---|---|
| `matrix_forest_day` / `_night` | player | staged clock (day 08:00 / night 23:00), Calm pinned; **pre-re-bake scatter** | Near Lantern Hollow: broadleaf trees, a cottage, two bears. Day has a blue sky; night has a moonlit dark-blue sky. |
| `matrix_rod_line_day` / `_night` | player | staged clock, Calm | Verge Rod Station pylon about 30 m ahead, small and thin. It is **mostly hidden behind the trainer's head** in both frames. |
| `matrix_giant_trunks_day` | player | staged, Calm | Fallen Giant catalogue stand facing east. **No giant trunk is visible**: the view shows ordinary broadleaf trees and a blue bird creature. |
| `matrix_stormheart_trunk_day` | player | staged, Calm | Stormheart trunk mouth: huge bark walls and inner spiral ramps. Prompt: "Challenge Officer Kestrel" (a trainer nearby). |
| `matrix_glass_scars_day` | player | staged, Calm | Glass Field: pale-cyan glass spikes, with the Stormheart tower on the horizon. Prompt: "Take Small Potion". |
| `sky_restored_rod_line_day`, `sky_restored_forest_day` | player, raised pitch | staged: `long_storm_ended` (aftermath cycle) | Blue sky with clouds, which looks the same as the pre-release Calm frames |
| `surge_{calm,building,break,fading}_01..06` (`sheet_surge_strips.jpg`) | player, **no HUD** | Surge clock set to phase start + 2 s, then running on its own. Frames are 5 s of surge time apart. Cinder Verge marked clearing (-604, 772). | Same stand in each phase. Building warms the grass and ground. Break turns the dead trees violet. Fading is close to Calm. The sky stays blue in every phase, and no rain or lightning flash is visible. |
| `surge_break_telegraph` | player, no HUD | natural host strike during staged Break; player health restored between Break frames | Pale-violet 3 m telegraph ring on the ground around the trainer. It also appears in `surge_break_04` and `_05`. |

## Defects seen in the frames

- The Crown record stones are small (1.5 m) mossy rocks with a flat white
  glyph quad. They are easy to miss from 13 m.
- The Crown record dialogue has no portrait.
- The portrait on Hesk's dialogue is a young man (`villager_male.png`) for an
  old white-bearded Rodkeeper. The body text also repeats the speaker name
  ("Rodkeeper Hesk: …") under the speaker header. Crown records and the
  Stormheart line do not repeat it.
- Stormwood daytime reads as a sunny meadow: blue sky, light-green broadleaf
  trees, bright grass. The ART_DIRECTION row asks for cool blue-green light
  from below, "little direct sky until the aftermath", white-violet lightning
  and black pools. None of those appear in these frames.
- Surge phases differ only by an ambient tint. No rain particles are visible
  in any frame, the sky never changes, and there is no flash or copper
  flicker. So "restored sky" has nothing to contrast with. `long_storm_ended`
  only changes Surge timing (`stormwood_surge_rules.gd`); no sky or colour
  code reads it.
- A flat pale-green wall or plane (the terrain edge) is visible on the Crown
  horizon.
- The Dynamo core floor has large flat untextured teal and violet shapes.
- In `matrix_stormheart_trunk_day`, the "80 m" stand is already at the trunk
  mouth.
- The Verge Rod Station pylon is not visible from the 74 m catalogue stand
  (-604, 772) that the surge strips use. It is only visible from 30 m.

## Missing

- **≥30 s motion video per Surge phase.** Not produced. The six-frame strips
  cover 25 s of surge time per phase and do not replace motion, sound or
  per-frame flicker review.
- **A giant-trunk frame at the Fallen Giant.** No trunk is visible from the
  catalogue stand. The Stormheart trunk frame stands in.
- **Before frames for the ACCEPTANCE matrix and surge.** Not produced; the
  lane did not change them.
- **Fight-camera frames.** None; no item required a fight.
- **Earned-state frames.** None; every frame is staged, as listed above.
- **Forest frames after the F09 re-bake.** Not yet taken.
