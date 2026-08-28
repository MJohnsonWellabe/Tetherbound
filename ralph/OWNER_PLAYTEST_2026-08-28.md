# Owner playtest — 2026-08-28

**Owner played the shipped build on real hardware.** Under CLAUDE.md's precedence
this is category 1 — explicit owner-play evidence — and outranks every other
document in this repo, including the Gate F backlog and the historical register.

This is also the **first device evidence this project has had all week.** Every
lane has been marking device frame rate, GPU cost and controller feel
`[OWNER-ONLY]` and working blind around them. The build played was the one at
`ralph/reports/gate-f-candidate` era `main` with the grass field ON.

---

## 1. The grass re-renders as you walk — OWNER'S MAIN COMPLAINT

> *"the grass rerenders like every step. it's very alive feeling which I think
> hurts performance."*

**Read the two halves separately, because they want opposite responses.**

*"Very alive feeling"* is a compliment and the owner has separately said the
grass is **awesome** and must not be changed. Density, colour, silhouette, wind
and the cover tiers stay exactly as they are.

*"Rerenders like every step"* is a defect, and there is a named mechanism for it.
`grass_field.gd::_process` snaps the ring's centre to a grid:

    var snap := float(config().get("snap", 2.0))
    var centre := Vector3(snappedf(at.x, snap), 0.0, snappedf(at.z, snap))
    if centre.is_equal_approx(_centre): return

`snap` is **2.0 m**. The function's own comment says why the snap exists and what
it costs:

> *"Following the camera continuously makes every blade swim against the ground
> it is supposed to be growing out of, because the ring's own noise lookup is in
> WORLD space while the instances are in LOCAL space -- a sub-metre move
> re-rolls which tufts survive."*

So every 2 m of travel the surviving tuft set changes. At the 5.0 m/s walk in
`combat.json` that is **a re-roll about every 0.4 seconds** — which is what "every
step" describes. The snap made the swim less bad; it did not remove the re-roll,
it made it periodic.

**Not yet established, and must be measured rather than assumed:** whether this
also costs frame rate, or is purely visual. `_process` itself is light — a
`wind_time` uniform write per material every frame, and the centre write only on
a snap. The owner's "I think hurts performance" is a hypothesis from feel, not a
measurement, and this project has no way to measure the device.

## 2. Catching still feels bad

> *"catching still sucks"*

Gate F has **never exercised catching**. X03 is the catching lab and has not run
in either attempt — the 2026-08-27 run never reached it, and run 2 stopped at S02.
So there is no evidence file to reconcile this against; it is unmeasured, and
the owner has now played it.

## 3. The HUD is too big on screen

> *"the hud on screen is way too big"*

**This is the second owner report of the same thing** — `HIST-136` and OP23-09
are the first. `GF-B-005`/`GF-B-006` landed on 2026-08-27 and moved the roster
off the play space and re-led the quickbar with the item icon, and the owner is
still saying it is too big afterwards. So the previous fix addressed placement
and legibility, not **scale**, and scale is what is being reported.

Note the tension to resolve rather than ignore: the HUD's sizes are floored by
`MIN_PHYSICAL_GLYPH_PX` for 7-inch handheld legibility, and the quickbar badge
sits exactly at that floor. "Too big" and "must stay legible on a 7-inch panel"
are both owner requirements and the fix has to satisfy both.

## 4. Some locations still look poor

> *"some locations still look lame"*

Consistent with `GF-B-007` (the Old Quarry does not read as a quarry) and
`HIST-163`/`165`/`164`/`166`. Not yet localised to specific places by the owner.

## 5. TMs look awful

> *"tms look awful"*

Live content: `scripts/creatures/tm_db.gd`, `data/moves/tms.json`,
`scripts/world/tm_pickup.gd`, `scripts/ui/tab_backpack.gd`, plus
`data/config/trade.json` and `data/config/chapter_rewards.json`. Covers the world
pickup, the backpack entry and wherever a TM is presented as a reward. No prior
backlog item names TM presentation.

## 6. The Burrow Warrens needs a reason to go in — NEW DESIGN DIRECTIVE

> *"there needs to be a point to going in the burrows warren. like a prize at the
> bottom or an alpha animal or something."*

This is an owner gameplay decision, so it is ordinary work rather than invention
under CLAUDE.md's "ask instead of inventing" rule. The owner names two candidate
shapes — a prize at the bottom, or an alpha creature — and has not chosen between
them.

Constraints that bound any answer: five creatures total and no storage; trainer
creatures cannot be caught; catching is available during wild combat; no new
creature meshes for the Meadows, so an "alpha" is differentiated by material,
scale, animation, VFX, traits and encounter context rather than by a new mesh.
