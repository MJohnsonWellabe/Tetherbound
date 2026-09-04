# D74 — A speaker without a body wears a faction or family plate, never the player's

**Date:** 2026-09-04 · **Decided by:** lane W04-PORTRAITS, implementing owner directive
2026-09-04 item 8b (*"fix the picture during dialogue always being the main character"*)
under `ralph/briefs/0904/COMMON.md`'s rule to make the smallest defensible call and
record it rather than ask.

## The rule

`dialogue_panel.gd` draws whatever a line's `portrait` names. From this date every
`portrait` in `data/dialogue/` names the plate of the body the world stands that
speaker in (`tools/_capture_portraits.gd` renders one plate per installed humanoid
body, dressed by `village_npcs.gd::model_config()` exactly as the world dresses it), and
`tests/test_dialogue_portraits.gd` refuses any line whose speaker is not the player
resolving to `trainer.png`. `trainer.png` is the player's face and only the player's.

Three kinds of speaker have no body of their own. They are settled here so nobody
re-opens them:

1. **A posted Team Tether notice** (`Team Tether Notice`: the hall-approach board in
   `village.json`) wears the faction's generic plate, `grunt.png`. The words are the
   organisation's, and a masked grunt reads as "Team Tether says" where a villager or
   the player would misattribute them. The stronghold's duty board and readout live in
   `stronghold.json` and are re-pointed by that file's own lane against the same eight
   contract names.
2. **The generic trainer refusals** (`trainer_no_usable_creature`,
   `trainer_no_ally_deployed`, speaker `Trainer`) are said by whichever trainer the
   player just walked up to — villager or Team Tether — and `trainer_npc.gd` does not
   pass the speaker through. They wear the neutral civilian plate `villager_male.png`.
   The right fix is for `trainer_npc.gd` to hand the panel the trainer's own portrait;
   that is a code change outside this lane and is recorded as a limitation, not done.
3. **A named speaker the world never stands up** (Coll, who owns the Broken Cart and
   speaks from the cart's prompt) wears the plate of the nearest family, here
   `villager_male.png`. If a body is placed later, re-point to that body's plate.

## Plate names are a contract

`trainer.png`, `grandpa.png`, `villager_male.png`, `villager_female.png`, `grunt.png`,
`officer.png`, `captain.png`, `warden.png` are fixed names other lanes and files point
at; they are not renamed. Named-cast plates (`mira.png`, `halda.png`, `grunt_b.png`,
…) sit beside them so a speaker whose body is a per-individual base (a Team Tether
trainer's `base` override, a villager's hair colour) can be drawn as that body.

## A finding, not a decision

Every villager on the shared `villager_female` rig (Mira, Tam, Halda, Rae, Doss, Sela,
Dara, Nan) renders an identical face: the rig's only per-NPC differentiator is the
`hair_ponytail` mesh, which sits at the nape (y 1.36–1.55 m, wholly behind the head)
and is invisible from the front — in the plate and in the world alike. Spec §21's
"NPCs differ by hair colour" is therefore not being delivered by that rig from any
conversational angle. The plates are honest to the bodies; making the villagers
actually differ is a rig or texture task for a lane that owns the rig.
