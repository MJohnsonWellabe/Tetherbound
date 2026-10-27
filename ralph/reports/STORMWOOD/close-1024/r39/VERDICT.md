# r39b: Stormwood path posts (CPU, code-blind, 26 Oct)

**Arms:** three spur-junction gateways, each seen from the road at 18 m in calm: Verge (Ash Road), Moss Nook (Conductor) and Deepwood Ridge.
- **OFF:** the lane.
- **ON:** `stormwood_path_posts.json`. The junction lamps take the Meshy Stormwood lantern post at 6.6 m, with warm pane glow, one warm light and the lamps' existing daylight halo, in place of the pale box post, kit wall lantern and flame sphere. Colliders unchanged.
- r39, the first version (4.2 m, no halo), lost the road read by eye and was not judged.

**Result:** mapped **5.88 -> 6.43 (+0.55)**. Raw means are 6.20 -> 6.60, and all three judges prefer ON. The fit is weak (r 0.64, anchor RMSE 0.64, no warnings).

**Defect** "junction lamps read as placeholder kit lanterns": PRESENT 2 / PARTIAL 1 -> PARTIAL 3/3.

**Judges' shared ask:** a larger copper-and-glass lantern on a visible post or bracket that reads from the road.

**Also flagged, on both arms:** a flat yellow-green vertical light column behind the trees at the junctions. It reads as an unexplained billboard. Identified: it is the F09 pocket reward shaft at each gateway (`stormwood_pockets.json reward_beacon.shaft`). It is deliberate wayfinding, tuned in judged rounds 5 and 7 so the reward reads from the road. It is left as it is; a recolour toward white-violet would be the F09 owner's call.
