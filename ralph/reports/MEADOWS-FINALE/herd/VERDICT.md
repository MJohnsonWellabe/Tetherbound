# F05#3: the saved herd display grouped around the stag

**Result: qualified PASS on the criterion question.** A code-blind judge (round
2) was asked: "Is the freed stag shown grouped with a herd around it, visibly,
and unchanged after reload?"

## Frames

These are in-engine frames from the production camera rig, with the HUD on
and the clock held at 13:00.

- They come from `capture_herd.gd.txt`, run on ralph/f05-herd-group with
  `--fixed-fps 60`.
- The refusal is the real solo one: the lever, the chamber dialogue, and the
  refuse prompt pressed with injected `interact`.
- Then a real `save_game` to slot 3, a cleared progression, `load_game`, and a
  fresh Meadows world.
- `live-*` frames are taken after the refusal; `reload-*` frames are taken from
  the same three spots after the load.
- `capture_log.txt`: the herd display stands at (398.0, 5869.0) both live and
  after the reload.

## The verdict (round 2), summarised

- **Approach (1) and close (2): among the herd.** Deer stand to its left,
  right and behind; spot 2 is "the best in-the-herd read".
- **West (3): weakest.** It reads as the stag with a herd beside it. That arc
  is deliberately left open, so no deer stands between a player coming up the
  meadow and the stag. Round 1 failed on exactly that, with a deer in front
  from the west.
- **Reload:** spots 2 and 3 are essentially identical. Spot 1 holds at the
  herd level, with some drift in the camera and a wandering wild boar.
- **Qualified PASS:** "The stag is visible and sits with deer on several
  sides, and that holds after reload."

## Rounds

1. **Site (383, 5857):** a scatter trunk 1.2 m from the stag hid it from every
   vantage. The site was moved.
2. **Site (406, 5877):** this stood inside the Highfield drove camp (wagon,
   fence, fire). The blind round 1 verdict was FAIL as a set: a deer stood in
   front from the west, and the hero stand was blocked by a mid-ground trunk.
   Moved again.
3. **Site (398, 5869):** 15.1 m clear of scatter trees and solid bushes, 17.1 m
   from any authored prop, ground within 0.8 m over 8 m. The ring is 8.5–10.5
   m out on the north, east and west. Blind round 2: qualified PASS.

## Not in this lane (routed)

These are art, for X04:

- The Meadowhart mesh shows a flat tan oval body from some angles, and the
  herd is one model in one pose.
- The Veridian's antlers do not glow (the only glow is the chest), and it reads
  about 1.5x a deer.
- Some deer interpenetrate at the dense cluster.

The meadow's red Y-posts are Meadows-core dressing.
