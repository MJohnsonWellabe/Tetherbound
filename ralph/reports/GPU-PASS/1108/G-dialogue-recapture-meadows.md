# G-dialogue-recapture-meadows: new Meadows dialogue baseline on the fixed blend (GPU High)

**Frames:** `tb/gpu-frames-1108` 1c7b2f364, main 8df122a83 (PR #910 blend fix), High, one-sided.
- 48 `__dialogue` frames from `phase2_capture_dialogue.gd --biome=meadows --seed=2042`.
- `conversation_camera_blend` is 1.000 on every frame, with no timeouts.
- The 7 script errors (`camera_occlusion.gd:191` freed-node check) have no visible effect, per the GPU lane.

**Sets:**
- **The four Meadows board rows with dialogue frames in job.json,** each a 2×2 of that row's frames (3, 3, 3 and 2 frames), on its job.json subject and recorded defect.
  - Those rows are F38#16, F38#17, F38#36 and F38#37. No other F38 row lists a dialogue frame.
- **The other 37 conversations** as four 3×3 sample sheets (36 frames). One frame was left out to keep the 3×3 layout: `warrens_watch_pell`.

**Batch `G-dm`:**
- Three code-blind judges, standard prompt.
- Anchors: craft, f36_0_npc:C1 (7.47/7.53) and f10_2_r3_capacitor. This is a confirming batch.
- **Fit:** slope 1.2314, intercept −0.7679, r 0.905, RMSE 0.587. No warnings.
- **Process note:** judge b's JSON was missing one closing brace in one set (Qp, F38#16). I added the brace and changed no score.

## New baseline vs old (part-blended) scores

| Row | Old (board) | **New (blend 1.000)** | Change | Raw a, b, c | Recorded defect |
|---|---|---|---|---|---|
| F38#36 dialogue speaker occlusion | 6.26 | **7.11** | +0.85 | 6.4, 6.2, 6.6 | creature intrusion: FIXED / PARTIAL / FIXED |
| F38#37 dialogue rock obstruction | 6.75 | **6.87** | +0.12 | 5.9, 6.2, 6.5 | FIXED / PARTIAL / PARTIAL |
| F38#17 named trainer subject visibility | 7.34 | **6.58** | −0.76 | 6.0, 5.7, 6.2 | "no speaker visible": FIXED / PARTIAL / FIXED |
| F38#16 tournament subject identity | 6.75 | **6.25** | −0.50 | 5.8, 5.6, 5.7 | "same grey-haired character": FIXED 3/3 |
| Meadows sample 1 (9 conversations) | n/a | 6.13 | | 5.4, 5.8, 5.6 | |
| Meadows sample 2 | n/a | 6.91 | | 6.0, 6.4, 6.3 | |
| Meadows sample 3 | n/a | 6.46 | | 5.8, 5.9, 5.9 | |
| Meadows sample 4 | n/a | 6.78 | | 6.0, 6.4, 6.0 | |
| **All 47 Meadows dialogue frames judged (mean of the 8 sets, frame-weighted)** | | **≈6.60** | | | |

**Every recorded defect is FIXED or PARTIAL; none is PRESENT.** With the blend complete, the speakers are in frame. Rows fall where staging problems the part-blend used to hide now show.

**F38#16 falls:**
- Mira is seen "small, through a window pane and a post, with the player's head in front of her" (3/3).
- The player's head takes about 40% of Oskar's shot (3/3).

**F38#17 falls:**
- The companion's (Terrapup's) flank fills about half of Keeper Hald's shot (3/3).
- Warder Solene's face is blown out to near-white (judge b).

## The one shared cause: the dialogue camera's clearance (3/3 top change)
The judges name the same cause across every set: the camera does not keep the companion creature, the player's head and backpack, or glass and walls out of the speaker's third.

**Companion creature crowding:**
- Keeper Hald and Old Bram (F38#17).
- Tether Patrol, Tether Grunt, Juno, Bryn and Dorn (sample 1, five of nine frames).
- Kest, Tobin, Wilhelm and Rae (sample 3).
- Orrin and Warder Ness (sample 4).
- Garrick's companion head cut at the edge (F38#37).

**Player's head or back in the shot:**
- Captain Halder (F38#36).
- Oskar and Mira (F38#16).
- Mira and Nessa (sample 2).

**Shooting through glass, windows or walls:**
- Bram behind a translucent shelf (sample 2, 3/3).
- Mira through a window (F38#16).
- The quarry foreman still boxed in by rock (F38#37, PARTIAL 2/3).

**Dark scenes:**
- Warden Aldis in a dark interior with a blown-out lamp behind his head (sample 4, 3/3).
- Gil, Corin and Ren underlit.

One clearance rule (exclude the companion and the player body from the speaker frustum, never shoot through glass or walls) would lift every Meadows dialogue row. This is the T6 "tighter conversation shot" cluster in `CLUSTERS-6TO7.md`, now with a concrete cause.

## Owner rules
- Red appears only beside Team Tether staff (3/3).
- Judge b flags a "flat saturated crimson/magenta banner" behind Captain Halder that competes with him. It is a Tether banner, so the use is correct, but it pulls the eye.
