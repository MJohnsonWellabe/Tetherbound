# THINGS-STORMRULE: the conversation clearance rule in Stormwood, now the posts are clear. READY, low expectation, not queued.

LANE-THINGS, 12 Nov 2026. Branch `tb/things` (keep-clear ON, as in the STORMPOST landing). CPU: `_sheet_rule_off_vs_on_cpu.jpg` (left: rule off, as main will be; right: rule on; Nysa above, Sera below).

## The arm
One key: `camera.json conversation.twoshot_v2.clearance_1112.exclude_realms` from `["stormwood"]` to `[]` (`overlay_rule_in_stormwood.json`). No code.

## CPU result
**No change on Nysa or Sera.** With the posts clear the default shot already has the player at the left edge and the speaker in view, so the rule counts both shots as clear and leaves them alone. (The creatures behind Nysa differ between the two frames only because they wander.)

## Where it could still matter
- Rows where the player's own companion stands in the frame: the rule steps it behind the lens. Subset captures on CPU spawn no companion, so I cannot show this.
- Posts where the default shot puts the player's head over the speaker.
- The regression that got Stormwood excluded (a creature's head over Sera on the swung shot) needed a wild creature beside her; with 16 m clear that case should not arise, but only a GPU capture of the whole Stormwood dialogue set can confirm it.

## Why it is not queued
Two arms are out (GALELAND attempt 2 and SPEAKERCENTRE), and on CPU this one shows nothing. It is cheap to capture: the whole Stormwood dialogue set, base against this overlay, after the STORMPOST landing is on main. Expect level on most frames; a gain only where a companion is in frame.
