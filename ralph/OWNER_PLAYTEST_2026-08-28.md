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

---

## 4a. LOCALISED — the weak locations are the CONSTRUCTED ones

Owner, asked which locations looked lame:

> *"burrow warrens and the castle are the lame looking locations. basically
> everywhere we had to build an under ground or build a building"*

**This reframes item 4 entirely, and it is a better diagnosis than the backlog's.**

The register has been treating this as individual places failing — `GF-B-007`
(the Old Quarry does not read as a quarry), `HIST-163`/`165` (the mill has no
wheel, the well no well), `HIST-164` ("three named landmarks are two kits used
twice"), `HIST-166` ("bridges and gates are overlapped fence panels"). Each was
filed as its own site.

The owner has named the class instead: **every space this project CONSTRUCTS
looks worse than every space it GROWS.** The Meadows terrain, the scatter, the
grass, the sightlines — all praised or unremarked. The Burrow Warrens (an
underground interior) and the Stronghold/castle (an assembled building) are the
two called out, and the owner generalises it himself to "everywhere we had to
build an underground or build a building".

That is a claim about **method**, not about art assets:

- Outdoor space is Terrain3D plus a 762k-placement scatter with authored bands,
  paths and landmarks — a system with a lot of variety per square metre.
- Interior and structural space is assembled from a **modular kit** —
  `burrow_warrens.gd` composes chambers from a footprint; the stronghold
  composes five spaces along a route (`outer_works -> courtyard ->
  tether_approach -> warden_arena -> legendary_chamber`); `props.gd` places kit
  modules. The result reads as rooms made of repeated panels.

**So the question to answer is not "how do we fix the quarry" but "why does
constructed space in this project read as unfinished, and what would change
that".** Candidate directions, none chosen: silhouette variety and vertical
interest rather than flat-walled boxes; lighting authored per space rather than
inherited; set dressing density inside interiors approaching what the meadow
gets outside; and landmark-specific geometry where a kit genuinely cannot say
what a place is.

Two constraints stay binding. New meshes need **owner-supplied reference art**,
and Meshy generations are reserved for Team Tether hero objects — so this is
mostly a composition, lighting and dressing problem rather than a modelling one
until the owner supplies art. And `tools/_probe_village_kit_modules.gd` (from
the HIST-CLUSTERS lane) found the installed kit has **more modules than were
being used**, so "the kit cannot express it" should be tested before it is
believed.

**This also lands directly on the Warrens payoff work in item 6.** The chamber
holding the alpha and the prize is the one room in that dungeon a player is
meant to remember. If constructed space is the weakness, that chamber is where
fixing it matters most, and the two items should be built together rather than
in sequence.

---

## 7. REGRESSION — grass grows through indoor buildings

> *"grass grows through indoor buildings now"*

**"Now" is the important word: this is a regression introduced by enabling the
grass field on 2026-08-27**, and it is live in the build the owner is playing.

**Mechanism, read out of `grass_field.gd`.** The field's ONLY exclusion is
terrain *texture* names:

    for entry: Variant in cfg.get("forbidden_ground", ["rock", "path"]):
        ...
    _material.set_shader_parameter("forbidden_base_mask", mask)

That keeps grass off painted rock and painted path. It has **no concept of a
building footprint, a floor, or an interior.** A structure standing on
grass-painted terrain therefore has grass growing up through it, because from
the field's point of view that ground is still grass.

The old scatter did not have this problem in the same way: its placements are
baked, and `playground_heightfield.gd::_apply_flats` flattens eleven building
pads that the bake is authored around. The runtime field never learned any of
that.

**There is already a precedent for the fix in the same file.** `grass_field.gd`
carries a channel described as *"Tell the grass where the bushes gather, so it
gives way to them"* — so a mechanism for the field yielding to other content
exists and works. Buildings plausibly want the same treatment rather than a new
one.

**This does not license changing the look.** The owner's standing instruction
holds: density, colour, silhouette, wind and the cover tiers stay as they are.
Grass should stop existing inside buildings; it should look identical
everywhere else.

Worth checking while in there, since they share a cause: whether grass also grows
through any other placed structure — the Warrens' surface entrances, the
stronghold, jetties, bridges, or the player's own built pieces. The owner named
buildings; the defect is "the field does not know about placed geometry".

---

## 8. TMs are cardboard cards — all three surfaces

> *"the tms are everywhere that they look bad b there cardboard cards."*

So the answer to "which surface" is **all of them**, and the reason is the asset
rather than the presentation: a TM is represented as a flat card. World pickup
(`tm_pickup.gd`), backpack entry (`tab_backpack.gd`) and reward moment
(`chapter_rewards.json`, `trade.json`) all show the same thing, so fixing one
surface fixes none of it.

A TM is a permanent, chapter-scale reward — `chapter_rewards.json` hands them out
at chapter beats and `trade.json` sells four of them. It should read as an
object worth crossing a map for. A flat card reads as a placeholder.

Note the standing constraint: a new mesh needs owner-supplied reference art, and
Meshy is reserved for Team Tether hero objects. Whether a TM qualifies for new
art is an owner call, not a lane's — but material, form and presentation work is
available without it.
