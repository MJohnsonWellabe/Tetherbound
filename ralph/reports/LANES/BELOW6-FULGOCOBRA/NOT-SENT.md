# BELOW6-FULGOCOBRA (F36#46, 5.87): PARKED, NOT SENT

Flag `creature_coat_flags.json below6_floor_fulgocobra` (OFF): blacks lifted to blue-charcoal, copper neck plates moved to gold, edge rim, on top of the face coat that ships.

**Correction (12 Nov).** My first "no visible change" was not a result: the flag named a glow texture that does not exist, so `parse_coat_flags` dropped the whole entry and the arm frame was the base frame. `test_creature_coat_flags` caught it after the merge with main (I had not run that test when I added the flag). The path is fixed and the test passes.

Two real CPU looks since (`_sheet_cpu.jpg`: base above, the second look below; standing and hit 050):
1. Lift 0.04 + 0.2v, rim 0.6: the coils show a little slate scale detail; otherwise the same black cobra.
2. Lift 0.065 + 0.32v (atlas mean value 0.29 -> 0.37), rim 1.0: slightly more scale detail in the coils. The silhouette against the stage is unchanged, the rim does not show, and the plates read gold on base and arm alike on CPU.

Both are well under +0.5 by eye, so the albedo-lift approach is parked after two attempts. The cobra is black by identity; lifting it further turns it grey.

What the judges named and this does not touch: the hood stays raised in the faint (LANE-THINGS' faint grounding). A different idea, not built: the stage itself is dark grey, so a near-black animal has no value step to stand on in these frames; in the field it stands on grass. If the row is to move, judge it on a field frame or give the pose stage a lighter floor for dark subjects (a stand change, which needs its own review).
