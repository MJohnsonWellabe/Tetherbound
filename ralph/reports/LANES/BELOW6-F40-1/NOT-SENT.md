# BELOW6-F40-1 (Cloudreach open terrain, GPU High 5.90): one hypothesis tested and removed; nothing sent

## Tested: "the brown soil skirt is the carved crown's bank with stretched UVs"
Built a flag (`carved_bank_uv_1112`) that mapped the carved crown's bank faces by run and height instead of the crown's top-down UVs, and captured the row's frames with it on (`_sheet_cpu_bank_uv_no_change.jpg`: main above, flag on below; Realm Gate Crag approach, Heartstone approach, Sky Shrine close). **No pixel of the brown band changed.** The code and the flag are removed again (12 Nov); nothing of it is left on `tb/below6`.

## What the brown band actually is
The Realm Gate Crag approach stand seats the player at (-8.2, 150.1, -152.6), on the island's south rim; the production camera sits 5 m behind and 3 m above, at (-9.9, 153.0, -157.4), which is past the rim. The lower fifth of the frame is the island's own side wall seen from outside and slightly above: a dark brown band with blurred turf below it. Any player who stops at that rim and turns to face the crag sees the same thing.

## What that leaves, in order of cost (none built)
1. **The wall's top band.** The side wall under the turf lip is dark brown at this distance. Giving the top few metres of `StratifiedCliffBody` the pale strata the cliffs behind it have would turn the band into rock ledge. I did not find which material draws it; the first step is a false-colour capture of that stand (one material at a time), as LANE-FLOOR2 did for the Warrens wall.
2. **The stand.** The approach view could look from further up the island, but the old stand does show its subject, so it is not the allowed kind of stand move.
3. **The terrain itself** (the judges' "stratified terraces and ledges in place of lawn discs"): a rise with collision along the gate approach in `cloudreach_world.gd _mesa`. Multi-hour, with route and collision risk. Eight dressing candidates at the stands have already failed, so more props there repeats a parked approach.
The cobble pad under the trainer in all three frames (`cloudreach_f40_items.json candidates[0]`, ON) is the other thing every judge names ("generator output"); an A/B with it off has never been run.
