# THINGS-DUSTTRAIL: short dust behind stone moves, not bead strings

**Row.** F38#3 Meadows fight (High 6.89 / Medium 7.03, pooled High 7.25). `G-closeout-f38-20-f38-3.md`, 3/3: "the dust trails read as strings of pale dotted beads over both creatures"; the scout names replacing them as the main lever.

**What draws them.** `_sheet_gpu_main_beads.jpg` is main at High (`G-things-foestand-meadows`, frame 02): long looping strings of pale dots across both creatures during Pebble Toss. They are the dust trail ribbon shared by three move archetypes in `vfx.json move_library.archetypes` (`stone_throw`, `charge_dash`, `quake_ring`): 1.7 m long, opacity 0.94, one per pebble.

**Change** (overlay only, no code): for those three archetypes the trail is 0.55 m long (was 1.7), opacity 0.5 (was 0.94), slightly wider (0.42 from 0.34) with almost no sag. The trail becomes a short puff behind each stone; the impact burst at contact is unchanged.

**Not shown on CPU.** I captured the fight on both sides (32 frames each). No frame on either side caught a trail, so I cannot show the difference; the CPU frames only confirm nothing else changed and there are no script errors.

**Ask.** The same Meadows fight set, base vs arm, High. By-eye check first: frame 02's bead loops should be short puffs. If the strings are still there at a third of the length, the next step is removing the trail for these moves and keeping only the impact burst.
