# Bram lure walk on main integration-32 (blocked; coordinator decision needed)

**Run:** local render, `tests/capture_activity_lures.gd --activity=bram --save=res://tests/fixtures/f03_lure_saves/S04-exit.json.gz`. The data is at the branch head: the fire is at (176, 909) with a 42 m opaque column.

**Result:** the walk reaches Bram, but his lure is first seen only **after leaving the road with a deliberate look**, at 53.6 m (`receipt.txt`).
- The band1 road here is a woodland path.
- Bram's camp is 55 m east of it, behind dense trunks and canopy.
- In the road frame (`bram_02_left-road-lure-not-yet-on-screen.jpg`), neither the fire nor the column clears the trees or the companion at the player's right.

Two approaches have been tried: moving the fire off his sightline, then a taller, opaque column. Neither makes him visible from this road, so no code-blind judge was run on these frames.

**Next:** Bram's site was held fixed by an earlier coordinator ruling (lure cue ruling (b)). Relocating his camp to open ground in the road's line of sight, as was done for the herd, needs a coordinator decision.

Earlier runs of this walk sometimes wedge on a band1 road cut near (21.9, 171.9), and the saved S04 pose loads entombed on the porch. Both are Meadows core's.
