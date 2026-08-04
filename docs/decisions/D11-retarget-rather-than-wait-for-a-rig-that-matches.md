# D11 — Retarget animation rather than wait for a character that already fits

**Status:** accepted
**Milestone:** MA5

## The problem

Every free character pack worth looking at ships **no animation clips**, and
every free animation library is authored on a **different skeleton**.

That is not bad luck, it is how the market is arranged. Character packs sell on
how the character looks in a still, so they ship a mesh, textures and a rig.
Animation libraries sell on how much motion you get, so they ship clips on
whatever rig the studio uses. The two only line up inside one studio's own
ecosystem.

Which left the trainer stuck. The KayKit Ranger is the one character we had that
came with matching clips, and the blind critic's verdict on him was that he
alone decides whether the game reads as Palworld "before anything else in the
frame is considered" — he is a bald flesh-coloured egg, measuring **1.36:1,
2.01:1 and 4.50:1** skin pixels to clothing across three survey frames, and *"in
`05` the character is, numerically, mostly a floating head."*

The two obvious moves both fail:

- **Take a better-looking character.** Styloo's knight is 8–10k triangles with
  2K textures and a proper Rigify skeleton. It has zero clips. The trainer would
  stand in his bind pose in every frame of the game.
- **Wait for a pack that has both.** Nothing free has both. Buying does not
  reliably fix it either — the one paid pack that looked right ships `.blend`
  only, and this environment has neither Blender nor `bpy`.

## The decision

**Write a retargeter and treat "the rig does not match" as a data problem.**

`scripts/player/animation_retarget.gd` replays a clip authored on one skeleton
onto another, given a `{source_bone: target_bone}` map that lives in
`data/config/art.json`. Twenty-five KayKit clips now drive a Styloo knight.

The one line worth knowing:

```
target_local = target_rest * (source_rest⁻¹ * source_local)
```

Each source rotation becomes a **delta from its own rest pose**, applied to the
target's rest pose. Copying raw rotations is the classic failure: the rigs hold
their arms at different angles at rest, so "arms down" on one becomes "arms out
sideways" on the other, and every clip is wrong by the same constant — which
looks like a bad animator rather than like a bug.

Rotation only, plus the root's position taken the same way as a rest-relative
delta and scaled by the height ratio. Bone positions are skeleton geometry;
copying them stretches the target's limbs to the source's proportions.

## What this buys beyond the trainer

The mapping is data, so the machinery is not humanoid-specific. The five
quadrupeds in the owner-supplied `Animals.glb` **share one bone-naming
convention with each other**, so one quadruped map animates all five at once.
One piece of code, two tables, two problems.

## The cost, stated

Retargeting is easy to get **subtly** wrong, and every way it goes wrong
produces a clip that loads, plays, reports the right length and is incorrect. A
forearm twisted 90°, hips sinking through the pelvis, `foot.l` wired to
`DEF-foot.R` — `has_animation("Walking_A")` passes for all of them.

So this is one of the places where **a test is not the acceptance**.
`tools/preview_trainer.gd` stands the trainer on a plain card, holds him at
mid-clip in each of the five poses the game drives, and photographs him from two
angles — two because a mirrored limb is invisible head-on and obvious from
three-quarters, and a sunk pelvis is the reverse. The retarget was accepted by
looking at those ten frames, not by a green test.

The first run of that tool immediately earned its keep: it showed a sword and a
shield floating beside the trainer, welded into the same skinned mesh and riding
bones no clip touches. No assertion in the project would ever have caught that.

## If it had failed

Fall back to Quaternius Universal Base Characters and record why. It did not
fail, so that stays a note rather than a branch.

## See also

- `scripts/player/animation_retarget.gd` — the algorithm and its failure modes
- `data/config/art.json` — `trainer.retarget_bones`, `trainer.hide_bones`
- `tools/preview_trainer.gd` — the acceptance check
- `docs/reviews/MA-03-calibration-round.md` — the critique that forced this
