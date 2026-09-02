# FIX — knife not visible in trainer's hand (owner playtest 2026-09-01, item 1)

**Verdict: scale, not attachment.** The knife equips and bone-attaches
correctly — same `tool_hold.gd` path the axe and pickaxe already use
without complaint. The bug is that `held_scale: 0.14` (set by the earlier
BACKLOG-KNIFE-SCALE fix for "the knife is comically large") shrinks the
blade's own cross-section to ~3.7cm x ~1cm, thin enough that from the
game's normal third-person distance it reads as an empty hand.

## Why the previous lane didn't land a fix

`ralph/ralph/OWNER-0901-KNIFE-VISIBILITY` (archived) spent its turn
building `tools/_capture_knife_visibility.gd` and was mid-run when it went
idle — no fix, just the tool. Its own capture confirms the size read
(`prop size: 0.087 x 0.213 x 0.081 m`) but the run never got far enough to
compare that against a render and see the knife was actually gone.

## What was checked and ruled out

- **Bone attachment**: `tool_hold.gd::_ensure_prop_root()` finds
  `RightHand` on the trainer's real skeleton (confirmed by dumping
  `Skeleton3D.get_bone_name()` for every bone) and attaches a
  `BoneAttachment3D` there. Not the `Hips` fallback.
- **Position offset**: tested `held_offset` shifts up to 0.3m on each
  axis — the prop's `global_position` genuinely moves (confirmed via a
  probe script printing `tool_hold.gd::prop_node().global_position`), but
  a 0.213m-long, ~1cm-thick sliver moved 0.3m away from the hand is still
  imperceptible at this camera distance. Not an offset/rotation bug.
- **Material/rendering**: `held_scale: 1.0` (the original "comically
  large" size) rendered fine and full-size, proving the OBJ import,
  materials (`Knife.mtl`, all opaque, none matched by
  `build_material_finish.gd`'s finish table so it's a no-op here), and
  bone-attachment pipeline all work. The only variable that mattered was
  scale.

## The fix

`data/items/items.json`'s `knife.held_scale`: `0.14` → `0.28`
(~0.43m overall, still the smallest of the three hand tools next to the
axe's ~0.83m and pickaxe's ~1.2m effective size).

## Evidence

`tools/_capture_knife_visibility.gd` (restored from the archived branch,
this is the real shipped tool now, not a throwaway) renders the trainer
idle with the knife equipped. Compared at `held_scale: 0.14` vs `0.28`,
same camera, same pose:

- **0.14** — zoomed 4x on the hand, the grip is empty. No sliver, no
  glint, nothing readable as a knife.
- **0.28** — a small blade is clearly visible hanging from the hand, from
  the front, 3/4, and rear angles (occluded only in a pure side profile,
  same as the hand itself is at that angle — not knife-specific).

Render command:

```
xvfb-run -a -s "-screen 0 1280x720x24" \
  ~/.cache/tetherbound-art/godot --path . --rendering-driver opengl3 \
  --resolution 1280x720 --script tools/_capture_knife_visibility.gd
```

Frames land in `shots/knife_visibility/<TAG>/` (gitignored, not
committed — re-run to reproduce).
