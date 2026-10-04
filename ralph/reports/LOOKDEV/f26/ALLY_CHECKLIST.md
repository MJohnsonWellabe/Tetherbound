# F26 Medium test on ROG Ally

Use the supplied F26 Windows zip and keep every extracted file together. Its
`F26_PACKAGE.json` identifies the source and checksums. This is an F26 test
candidate; full visual acceptance and the Ally result remain open.

1. On the Ally, note the exact model (Z1 / Z1 Extreme / Ally X), Windows version
   and AMD driver. In Armoury Crate select **15 W**. Note battery/plugged-in state
   and any custom CPU/GPU settings. Close other games and overlays that add load.
2. Double-click **F26_ALLY.cmd**. Enter the model and selected watts when asked.
   The script checks package hashes, uses an isolated test profile, and runs
   Meadows (village/Hall), Tidewake, Cloudreach and Stormwood serially at
   **Medium / Forward+ / 1920×1080**, uncapped with VSync disabled for the test.
   No editor, Git or Python install is needed.
3. Keep each game window visible and the device awake. Do not touch movement
   during the scripted routes. Startup/shader warmup and screenshots occur
   outside timing. Routes use ordinary movement and collision; dialogue/fight
   holds and declared stationary minimum-frame padding are included. Watch for
   missing materials, black/magenta meshes, unreadable fog, hitching and clipping.
4. Open the printed result folder. `ALLY_RESULT.json` summarizes mean/P50/P95/P99
   frame time, min/average/1% low fps and >100 ms hitches. Raw `route.json`, logs and start/end
   PNGs remain alongside it. **≥30 fps is required; 40 fps is preferred.** The
   summary checks mean and P95 against 33.33 ms (preferred 25 ms). Loading is
   reported separately by the raw native log, never discarded as a timed hitch.
   The 1% low is 1000 divided by the mean of the slowest 1% of frame times;
   minimum fps uses the single slowest frame. The harness also checks the
   all-realm vista far floors included in this package.
5. Send the **complete result folder**, declared power/battery settings and
   visible-fault notes to the coordinator. A complete route with good timings
   says `OWNER_REVIEW_REQUIRED`, pending verification of Ally identity, 15 W and
   all four results. A failed route is `INCOMPLETE`; slow timings are
   `BELOW_TARGET`. Keep failures and use a new folder for any rerun.

Compatibility stays the ordinary game's default until the owner result passes.
This four-route check does not certify release endurance, 720p fallback, earned
campaign, combat or internet co-op. Those acceptance gates remain separate.
