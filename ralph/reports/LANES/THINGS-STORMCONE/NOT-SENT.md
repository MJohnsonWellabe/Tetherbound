# THINGS-STORMCONE: the creature cone does not fix Stormwood's dialogue rows. NOT SENT.

LANE-THINGS, 12 Nov 2026. CPU sheet: `_sheet_stormwood_cone_cpu.jpg` (Nysa and Sera; main beside rule plus cone).

## What was built (flag-off, on `tb/things`)
- `camera.json conversation.twoshot_v2.clearance_1112.creature_cone`: five sight lines to the speaker; a shot with fewer than 80% clear counts as not clear, so the swing search looks past the creature (`camera_rig.gd _clearance_total`). Two unit tests.
- `speaker_light_candidate.realm_energy_1112`: the conversation key and rim scaled per realm (Stormwood 0.4). One unit test.

## What the CPU frames show
- **Nysa and Sera are the same frame with and without the rule and the cone.** In both, the speaker is in view; nothing stands between the lens and her. What fills the frame is one or two very large creatures standing right beside her: two Stormraven-like birds flanking Nysa, a Stormursa-like bear next to Sera.
- Those are not her party (Nysa's is stormbrush, glimmermoth, staticub) and not the player's companion. They are **wild creatures idling at the trainer's post.**
- So the Stormwood cause is not "a creature between the camera and the speaker" on these posts. It is wild creatures standing at named posts. A camera swing cannot remove a 5 m animal that stands a metre from the speaker; whichever way the camera turns, it is in the frame or over her.
- The cone would stop the one regression the GPU saw (the swung shot putting a creature's head over Sera), so the clearance rule could then run in Stormwood without that loss. It would not lift the rows: Nysa's and Sera's frames stay as they are.

## What would fix it (not built; needs a decision)
Keep wild creatures away from named conversation posts in Stormwood: a keep-clear radius around each trainer and character post that wild spawns and idle wander respect. That is encounter placement, not camera work, and it changes where wild creatures can stand, so it needs the coordinator's or the owner's go-ahead and the encounter owner's file. I have not touched it.

## Harness finding
`--sight-stand` on CPU in Stormwood can take over 50 minutes on one post (Sera): when the post is within reach but blocked, the search tries up to 90 stands and each costs seconds of CPU frames. Without the switch the same post takes 9 minutes. On the GPU this is fast. Do not use `--sight-stand` for Stormwood on CPU.

## Light scale
Both speakers are washed pale on CPU as well, so the light scale may be checkable there. Not captured yet.
