# THINGS-BEAM: the cyan sky beam through the catch target (F38#7, and other catch and fight captures)

**Row.** F38#7 catch aim: High 6.77, Medium 7.26 (`G-closeout-meadows-ui.md`, d3be8b49). 3/3: "a tall cyan sky beam cuts through the target". The same beam can stand in any fight or catch capture taken near the current objective (F38#33, F38#14, F39#9, F39#23 are catch rows).

**Cause.** The beam is the quest objective beacon. In play it stands down while a fight is on screen. It finds the fight through the tree's current scene; in a capture the world is added under the root and is not the current scene, so the lookup found nothing and the beam stood through the whole catch. A capture fault in effect, fixed on the game side because the lookup was fragile.

**Change** (`scripts/world/objective_beacon.gd`, no flag): when the current-scene lookup finds no combat manager, the beacon looks in its own parent world. Behaviour in normal play is unchanged (the first lookup already succeeds there).

**CPU** (`_sheet_beam_off_cpu.jpg`; left main, right this branch; aim at 0% and at 82%): the beam is gone in every catch frame; nothing else changes. No script errors.

**Not in this arm.** The small reticle, and the High frame whose camera sits in a bush.

**Ask.** F38#7 job.json frames (phase2_capture_catch.gd, Meadows), base = main, arm = tb/things, High. No overlay.
