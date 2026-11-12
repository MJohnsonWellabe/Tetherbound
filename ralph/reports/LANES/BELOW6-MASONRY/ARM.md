# BELOW6-MASONRY: Cloudreach wall stones at human scale (F40#15, 5.89)

**Flag:** `data/config/cloudreach_visual.json masonry_scale_1112` (OFF; overlay turns it on).
**Code:** `cloudreach_world.gd`, where the two shared masonry materials are built. Test: `tests/test_cloudreach_masonry_scale_flag.gd`.

**Why:** G-rescore-stale-tier2 has the row's recorded strips FIXED 3/3 and names what holds it now: "stretched giant cobbles on the Cloudreach wall" (also named on F40#17). In `walk_03_day` a Stormward Overlook pier fills the left 40 percent of the frame, and each cobble on it is as large as the trainer's torso.

**Cause:** every masonry piece in Cloudreach shares one material (`cloudreach_environment_materials.gd masonry`) with `tile 0.28`: the uneven-brick texture repeats once every 3.6 m, so a single stone is about a metre across.

**What the arm does:** `tile 0.7` (the texture repeats every 1.4 m, stones about 0.35 m) and a step lighter wall tint (`#a3a793` for `#8d927f`). Material values only, on every Cloudreach masonry and trim piece; no mesh, collision or placement change.

**CPU look** (`_sheet_cpu_walk03_and_route_base_top_arm_bottom.jpg`; walk_03 left, route_day right; base above, arm below): on the near pier the stones drop to a half to a third of their size and read as a built wall. They are still uneven across that face, because the pier is a castle tower mesh stretched to its size. The distant piers in route_day look the same at that distance. 0 script errors. No CPU judge batch; the aerie dusk frame was not captured on CPU.

**Scope warning:** this is a shared material. Controls with masonry in frame (Sky Shrine, aviary) should be judged as a no-loss set.
