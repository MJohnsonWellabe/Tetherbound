# Meadows finale: in-engine visual evidence and blind verdict

Lane: Meadows finale (F05). **The visual bar is not met.** The code-blind
judge's verdict is recorded below. Every failure it found becomes work,
whether in this lane or reported to the lane that owns it.

## How the frames were made

- `visual/capture_finale.gd.txt` is the script; drop the `.txt` to run it:
  `xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 --resolution 1280x720 --script capture_finale.gd -- <out>`.
  The crossing ran with `F05_CROSSING_BACK_M=60`.
- It runs on `d804518b`'s game code. The later commits `683f440b` and
  `9b4181fa` change only comments and reports.
- The frames come from the production Meadows scene, through its own
  `CameraRig` following the real Player, with the HUD on. Nothing is hidden
  and nothing is touched up. JPEG quality is 85.
- Fixtures, disclosed:
  - `defeated_warden` and `realm_key_cloudreach` are set directly.
  - The party is 4 creatures built with `make_creature`.
  - For each still, the player is placed at the vantage and the rig's yaw is
    set behind them.
  - The lever, the dialogue and both prompts are the real ones, pressed with
    injected `interact`. The run answers by **refusing**, which is why the
    herd display appears.
- The crossing is 30 kept frames, one per second of play, with
  `move_forward` held throughout. The rig is steered at the far trigger until
  the realm changes. The realm changed during second 5; seconds 5–30 are the
  walk on into Cloudreach. The log reads: `crossing: realm now 'cloudreach',
  scene 'CloudreachCliffs', party 4`.

| Sheet | Frames |
|---|---|
| `visual/_sheet_finale.jpg` | 01/01b before healing, 02 lever, 03 dialogue, 04 offer announcement, 05 accept prompt, 06 refuse prompt, 06b refusal line, 07/07b after healing, 08–10 herd display, crossing picks |
| `visual/_sheet_crossing.jpg` | 20 approach, then t01–t30, one per second |

## Blind verdict (code-blind sub-agent, rubric `.claude/skills/visual-judge`)

**A. Does it belong to the key-art world?** Partly, for the meadow (01b, 07b,
08–10). No for the chamber and for Cloudreach.
**B. Is it trying to be the same kind of game as Palworld?** Yes in intent,
no in execution.

The judge's ranked top-3 gaps:

1. Cloudreach (t05–t30) reads as a block-out. The mown green ramp has
   single props, a white-void horizon and staircase path edges.
2. The finale chamber (02–06b) has no readable form, and its climax is not
   staged. The stag is near-black on brown-black geometry, the shadows are
   blotchy, the camera sits inside the creature in 04, and the key text is
   about 12 px under a stale hint.
3. Healing the land has no visible payoff. 01 and 07 look the same; in 01b
   and 07b only the cable and the pylon glow go dark. The herd reads as white
   dots, and Terrapup (t03) is a smear that blocks the camera.

The per-frame readability answers:

| Question | Answer |
|---|---|
| Does the land visibly change (01 vs 07, 01b vs 07b)? | No, and barely: only the cable and the pylon glow. |
| Is the text legible (04, 06b)? | Yes, but small. In 04 a stale smith hint is the large line. |
| Is it clear the player is choosing (05, 06)? | No. Only one prompt shows at a time. |
| Is the stag distinct among the herd (08–10)? | Distinct, yes. Part of a herd, no. |
| Crossing | On the span at t03, far side at t04, hard cut to Cloudreach at t05. The camera loses the player at t03, behind a companion. |

## What becomes work

In this lane's paths (next work order, F05 WO6):

- **Stage the choice.** Show both answers as one readable choice at
  dialogue size, not a HUD strip line (`stronghold_climax.gd`,
  `stronghold_climax.json`).
- **Group the herd around the stag.** The display joins the herd rather
  than standing near it (`meadow_healing.gd/.json`).
- **Make the healing visible.** At the drained stations: a ground tint or
  saturation return, and the quarry frame aimed at a real drained patch
  (`meadow_healing.gd/.json`, and the capture).

Reported to their owners, because they are outside this lane:

- **Camera collision near large creatures and companions** (04, t03):
  camera/UX.
- **A stale objective and toast during the finale** (02–04): HUD/quest.
- **Chamber lighting and the tether-machine model** (02–06): stronghold
  art.
- **Oxblood on a friendly cart canopy and box** (08–10, 20): Meadows
  dressing.
- **Cloudreach density, horizon, path edges and a cart clip, and the hard
  cut at the realm change** (t05–t30): the Cloudreach lane, and the realm
  router.
- **Needs art that is not in the build:** a readable tether machine, a
  Terrapup that reads as a companion, proper herd animals, one creature
  style, and a Cloudreach asset family.
