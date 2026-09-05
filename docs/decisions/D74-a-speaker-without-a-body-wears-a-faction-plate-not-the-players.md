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

## The plate's ground is part of the contract too

A plate is **256x256, fully opaque, on (242,242,242)** — measured off
`trainer.png` and `grandpa.png`, the two plates that already shipped and that
every new plate has to sit beside in the same box. The rendered plates were
transparent cut-outs at first, and a code-blind judge called that the loudest
mismatch it found: in one dialogue box the villagers floated free on the dark
panel while Grandpa drew as a bright white card, *"a player sees it the first
time Grandpa speaks."* `tools/_capture_portraits.gd` renders on transparency and
composites onto that ground in code, so the value is exact rather than something
tonemapping can drift.

The same tool enforces, per plate, what that judge measured by eye: subject
coverage inside a 38–68% band (the shipping plates sit at 51% and 55%), under
1.5% of the drawn pixels clipped to flat white (the shipping plates clip 0.2%
and 0.6%), and nothing reaching the top or upper sides, which is where hair, a
hat brim or a carried prop gets sliced. The bottom edge is deliberately
unchecked: a head-and-shoulders plate is meant to run off the bottom, and both
shipping plates do.

One lens for every plate. The camera steps back automatically when a subject
does not fit, rather than the window being tuned per character — a wide-brimmed
hat gets distance, not a different lens.

## Plate names are a contract

`trainer.png`, `grandpa.png`, `villager_male.png`, `villager_female.png`, `grunt.png`,
`officer.png`, `captain.png`, `warden.png` are fixed names other lanes and files point
at; they are not renamed. Named-cast plates (`mira.png`, `halda.png`, `grunt_b.png`,
…) sit beside them so a speaker whose body is a per-individual base (a Team Tether
trainer's `base` override, a villager's hair colour) can be drawn as that body.

## Two findings, not decisions

**One face, eight villagers.** Every villager on the shared `villager_female`
rig (Mira, Tam, Halda, Rae, Doss, Sela, Dara, Nan) renders an identical face:
the rig's only per-NPC differentiator is the `hair_ponytail` mesh, which sits at
the nape (y 1.36–1.55 m, wholly behind the head) and is invisible from the front
— in the plate and in the world alike. Spec §21's "NPCs differ by hair colour"
is therefore not being delivered by that rig from any conversational angle. Two
independent code-blind judges counted the repeats unprompted ("seven of 34 cells
are one asset"). The plates are honest to the bodies; making the villagers
actually differ is a rig or texture task for a lane that owns the rig. The
per-NPC file names (`mira.png`, `halda.png`, …) are kept so that a fix there
re-renders straight into the right names with no dialogue edit.

**A texture artefact on the shared rigs.** A hard-edged pale wedge sits on the
right cheek, with thin dark lines on the neck, on `villager_female` and
`villager_male` alike. It is in the body texture, not the plate: a judge given
only the frames spotted it on the standing NPC in the world *and* on the
portrait, and used the fact that the two match as proof the portrait is the
right person. Not introduced here and not fixable here — it belongs to whoever
owns those two rigs' textures.
