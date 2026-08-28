# CONTENT-0828 — content lane for the 2026-08-28 owner playtest

Branch `ralph/CONTENT-0828`. Three items from `ralph/OWNER_PLAYTEST_2026-08-28.md`,
in the coordinator's priority order: the Burrow Warrens payoff, TM presentation,
and "some locations still look lame".

---

## 1. The Burrow Warrens needs a payoff

> *"there needs to be a point to going in the burrows warren. like a prize at
> the bottom or an alpha animal or something."*

### What is actually there — established before changing anything

The first thing to say is that **the cave already had both halves the owner
asked for**, and had for six days:

| | shipped state before this pass |
|---|---|
| the alpha | `Warren Guardian`, a level-14 Burrowback in the den, aggressive, catchable |
| the prize | a Heartstone on a lit plinth in the `vault`, behind a rock slab that only lifts once the guardian is down |
| a rare catch | a level-13 Terrapup in that same vault — the **only** wild Terrapup in the entire game |
| the payout | 45 coins, 4 rootstone, 60 xp |

So this is not a missing feature. It is a payoff that does not land, and the
useful question was **why the owner played it and did not find one**.

**The Gate F evidence cannot answer that.** `ralph/reports/gate-f-run-20260825T201354Z/S06/`
is the segment that walks the Warrens, and its guardian steps look like they
ran — `S06-74 fight the guardian`, `PASS`; `S06-80 the Warrens are cleared`,
`FAIL, flag warrens_cleared NOT set`. But `S06-70` records the player stopping
**1380 m short** of the den, at (16, −3, 1321), and every later step fires at
that same spot. Nothing in S06 ever reached the cave, so the "flag not set"
line is not evidence about the guardian, and S06 carries no evidence about the
Warrens at all. The only walked evidence for this dungeon remains
`ralph/BAND2_WARRENS_EVIDENCE_2026-08-23.md`.

### Three findings, from reading current `main`

**1. The chapter's boss is the only notable creature in the game that is not
built with the game's own alpha system.**

`encounter_director.gd::_make_alpha()` is a complete, shipped alpha
implementation: `apply_size_multiplier()` for gameplay size, `set_alpha(true)`
for the colourway swap, a silhouette rim light and a ring of drifting motes.
Every band file uses it — `bands/band2_stone_and_root/spawns.json` gives a
roadside duskhush `{"level_bonus": 3, "scale": 1.3}` and it comes out looking
like an alpha.

The Warren Guardian used none of it. It got a nickname and `art_scale: 1.4`,
and `art_scale` multiplies the **model pivot only**. Two consequences:

- It wore the ordinary burrowback texture, with no rim and no aura, standing
  three metres from residents wearing the same texture. **A roadside duskhush
  read as more of an alpha than the dungeon boss.**
- Its collider, hit-cone reach and catch-accuracy bonus were a field
  burrowback's, under a 1.4× silhouette. `creature_body.gd` names that exact
  case at the declaration of `body_scale` and calls it "the invisible
  discrepancy PW2 forbids" — a throw or a swing that visually connects
  resolves against a body that is not there.

And the material this needed **was already installed**:
`creature_burrowback_lod0_base_color_alpha.png` and its emissive sibling, the
heavier-stone-plates repaint CREATURE-IDENTITY-2 authored for this exact
species. It had simply never been switched on here.

**2. The dungeon paid picket money for a boss fight.** From this repo's own
reward audit, `data/config/chapter_rewards.json`:

| activity | pays |
|---|---|
| `warrens_watch_pell` — *optional* picket, standing 35 m outside the door | 40 coins, 2 potions, **3 orbs** |
| **Burrow Warrens clear** — required dungeon, 5 fights + a level-14 boss, measured 5–9 min | **45 coins, 4 rootstone, 60 xp** |
| `relay_captain` (Vance), one band later | 60 coins, 3 greater orbs, a revive, 120 xp |

The audit row also carried `understood_when_received: false`, flagged and
consciously left, because the Heartstone is useless to a player who does not
own a Mudsnout at level 15 and bond 55. So for a large share of players the
literal answer to "what did I get for that" was 45 coins.

**3. Nothing in the den said there was anything behind the door.** The branch
door is a grey slab the same value as the wall it sits in, so from the den
floor it is a wall. The player fought the guardian in a room with no visible
reason to be there, and found the branch afterwards — if at all. And the rarest
catch in the chapter, the vault's Terrapup, had no name on it: it read as one
more aggressive animal in a dark room.

### A fourth finding, and it was only findable in frames

The before-capture is the reason this section exists. Rendered through the real
path at the stands the alpha work is about, the den and the vault came back with
**huge faceted olive slabs standing inside them** — one of them between the
camera and the guardian in `02-alpha-close`, the single frame that exists to
show the guardian, and two more filling the vault around the heartstone in
`04-vault-prize`.

They are the **mound's own boulders, hanging through the ceilings into the
rooms.**

The arithmetic that puts them there is in `_build_mound()` and `_place_rock()`.
Roof rocks are placed at `top = _floor_y + chamber height + 0.8` and then moved
**down** by `sink_m` (1.2), so the model's origin lands 0.4 m *below* the
ceiling it is meant to sit on — and is then scaled by up to `roof_scale`'s 2.8.
Nothing measured the result, so whatever hangs below that origin hangs into the
room, multiplied by the scale factor. Perimeter rocks reach the same way from
the side: their top course sits at `_floor_y + tallest - 1.0` on the footprint's
bounding-box edge, which for the den's far wall, the vault's `+x` wall and the
warren's `-x` wall **is** a chamber wall, with 1.2 m of jitter and up to 3.6×
scale to carry it through.

BAND2-63-WARRENS is where this became visible, and understandably: it lowered
every ceiling by 0.6–1.2 m to stop the cave reading as a six-metre grey slab on
the skyline, which was the right call, and neither `sink_m` nor the roof grid
was re-checked against the new ceilings. Its own blind rounds never caught it
because the interior frames it took were the mouth, the hall and the dressing —
not the two deep rooms, which are the two the payoff lives in.

**This matters more than anything else in item 1.** No rim light, colourway or
mote aura rescues a creature standing inside a boulder, and no lit door reads in
a room full of them. The alpha work and the door work are both downstream of
this being fixed.

**Fixed the way this codebase already fixes this class of problem.**
`creature_body.gd::_fit()` measures an imported model's bounds rather than
trusting a hand-tuned per-asset offset, because every model arrives differently;
`_keep_rock_out_of_the_rooms()` does the same — measure what was actually
instantiated *and scaled*, and if its underside is below the ceiling of a
chamber it stands over, lift it until it is not. Bounds are walked with an
accumulated transform rather than read off `global_transform`, because
`_build_mound()` runs inside `build()` and must not depend on whether the node
is in the tree yet. A rock over open ground is untouched, so the outcrop's
silhouette from the road — which two blind rounds tuned — is the silhouette that
was tuned.

### What shipped

Owner's chosen shape — the alpha is the obstacle, the prize is behind it — with
no new mesh, no invented legendary, no new system, and no change to the
five-creature rule.

**The alpha reads as one** (`burrow_warrens.gd::_dress_the_guardian`, rewritten
to make the same three calls `_make_alpha()` makes, in the same order):

- `set_alpha(true)` — the installed alpha colourway, the silhouette rim, the
  mote aura. All of it existed; none of it was on.
- `apply_size_multiplier(1.35)` replaces `art_scale: 1.4`, so silhouette,
  capsule, reach and catch bonus move together. Scale drops because it is now a
  real reach change rather than a picture.
- `signature_move: earth_fist` — a per-instance override of the charged slot
  (`creature_instance.gd` holds `move_quick`/`move_charged` as plain fields), so
  the meadow's own burrowbacks keep `tremor_roll` and the species is untouched.
  1.4× power against 1.0, a 0.62 s windup, a 72° cone: heavier, telegraphed,
  and **directional**, so a player who reads the windup can step around it.
  `earthshatter` is the stronger move and is deliberately not used — 360° at
  7.5 m inside a den whose `combat_arena_bounds_at()` clearance is about six
  metres cannot be stepped out of, and an unavoidable hit is not a memorable
  fight. A player who catches the guardian keeps Earth Fist.
- Level stays **14**. SH47/D42 lowered it deliberately against measured pacing
  and this pass does not reopen that.

**The fight becomes a fight for what is through the door**
(`_build_vault_door_seam`, `_sync_vault_door`):

- the shut slab carries an emissive seam down its own face and a warm spill on
  the vault side, so what the player can see across the den **while the alpha is
  still alive** is a sealed way on with something lit behind it;
- when the guardian falls the slab **sinks into the floor** over 1.4 s instead
  of blinking out. It animates only on that transition — a returning player who
  already opened it does not watch it grind down again.

**The payout is boss-scale and understood** (`clear.reward`): 90 coins,
5 rootstone, **2 Greater Orbs**, 1 revive, 140 xp. Same SC15 shape as every
other reward in the game; `chapter_rewards.json`'s `_comment_no_new_systems`
forbids a second economy and this is not one. The Greater Orbs are the
deliberate part, and they follow this region's own established logic:
`trainers.json` says Pell pays basic orbs because *"the reward for clearing the
door is the means to catch what is behind it"* — so the guardian pays greater
orbs, because what is behind **him**, through the door his defeat just opened,
is the only wild Terrapup in the game. Beat the alpha → take the orbs → watch
the door go down → the rarest catch in the chapter is standing next to the
prize. That loop is what the descent is for, and every piece of it but the orbs
already existed.

**The rare catch says what it is**: the vault Terrapup is now `Elder Terrapup`
on both the engage prompt and the combat plate, written the same two-object way
the guardian's name is so the species survives underneath and a caught one is
still a Terrapup. Presentation only — level, temperament, catch rate and the
fight are untouched.

### Owner questions this raises, flagged rather than decided

- **The alpha is catchable, and that is unchanged.** It is wild, not
  trainer-owned, so `CLAUDE.md`'s catching rule applies and always did. With the
  five-creature limit and no storage, arriving at the den with a full party is a
  designed decision point. Worth an owner read once played, but nothing here
  needed a new rule.
- **`apply_size_multiplier` raises the catch-accuracy bonus** (a bigger body is
  an easier orb target). That is the sanctioned behaviour every band alpha
  already has, and it partly offsets the harder fight — but it does mean the
  guardian is now slightly easier to catch than it was. Deliberate, recorded.

---

## 2. TMs look awful

> *"tms look awful"*

All three surfaces were captured before deciding which one the complaint points
at, per the coordinator's instruction.

**The backpack entry and the reward moment are not the defect.**
`tools/gen_item_icons.py::_icon_tm` draws a TM as a keyed disc — a circle with a
flat chord off the bottom so it reads as a chip rather than another sphere, a
rim groove, and the taught move's own slot glyph punched through the middle —
and the icons are tinted per item from `items.json`'s own `colour`. Twelve of
the fourteen TMs share `tm_quick.png`/`tm_charged.png`, which is a deliberate
call that file argues for and I agree with: the disc says *"TM, and it goes in
your quick slot"*, which is what a player needs before spending it, and which
move is on it is the item's name and the detail panel's job. The detail panel
already reads power, type, slot and the compatibility list from `move_db.gd` and
`tm_db.gd` rather than duplicating them.

**The owner later gave the answer himself, in §8 of the playtest:** *"the tms
are everywhere that they look bad b there cardboard cards."* That is the word
for it, and it names the world pickup exactly — the before-frame
(`05-tm-pickup-before.png`) is a flat tan rectangle standing upright in a
field, which is a cardboard card. §8 says all three surfaces, and the reason it
gives is *the asset* rather than the presentation: a TM is represented as a flat
card. On the two UI surfaces it is not — `gen_item_icons.py` draws a disc — but
the object the player walks up to was, and that is the one this lane changed.

**So the world pickup is the defect, and the reason is sharper than "primitive".**
What stood in the world was a 0.32 × 0.46 × 0.04 m flat box with a 0.16 m
**white box** glued to its front as a "rune" — two untextured primitives, knee
high, in a world where the warrens' own rootstone deposits were given real rocks
for exactly this complaint and `key_pickup.gd` has been through four blind
rounds of shape, metallic, emission and size work.

But everything in this project is primitive; that is the house style and it is
not what makes this one bad. The actual defect is that **the world prop and the
icon were not the same object.** The satchel shows a disc, the shop row shows a
disc, the detail panel shows a disc — and the thing the player walked up to and
pressed a button on was a rectangle.

**What shipped** (`tm_pickup.gd::_build_visual`): the icon, in three dimensions.
A disc standing on edge in a stone rim, on a small plinth so it is planted
rather than floating, stamped on both faces with the same radial mark the icon
punches, turning slowly. About 0.8 m overall — waist high, the register of a
signpost — against the old 0.46 m. The lessons the other pickups already paid
for are reused rather than re-learned: low metallic and real emission, because
`key_pickup.gd`'s own comment records that a high-metallic `StandardMaterial3D`
goes dark under the Compatibility renderer's flat ambient; and a light of its
own, because emission paints the mesh but throws nothing, so the prop had no
presence until the player was already on top of it.

The slow spin is the one thing here that is not borrowed, and it is deliberate:
at the distance where a player decides whether to walk over, a turning disc is
the only cue that survives when the silhouette is twenty pixels wide. Five TM
props exist in the whole world (`playground_world.gd::TM_AT`), so this is five
rotation writes a frame.

Colour still comes from `data/moves/tms.json`, which already carries a per-TM
colour tuned by type. No new asset, nothing sourced, no ledger entry needed.

---

## 3. Some locations look lame — **REFRAMED by the owner, and built into item 1**

The owner localised this mid-lane, and it changed the item:

> *"burrow warrens and the castle are the lame looking locations. basically
> everywhere we had to build an under ground or build a building"*

**That is a better diagnosis than the backlog's, and a different kind of claim.**
The register had been filing individual sites — `GF-B-007` (the quarry does not
read as a quarry), `HIST-163`/`165` (no mill wheel, no well shaft), `HIST-166`
(bridges are overlapped fence panels). The owner named the *class*: every space
this project **constructs** reads worse than every space it **grows**. The
terrain, the scatter, the grass and the sightlines drew no complaint at all.

That is a claim about method, and it lands on this lane's own room. The
coordinator's direction was to build items 1 and 3 together rather than in
sequence, because the chamber holding the alpha and the prize is the one room in
the dungeon a player is meant to remember.

### What the frames showed, once I looked at them as an answer to this question

`04-vault-prize-after.png` from the first round of item 1 is the whole
complaint in one image: a **perfect rectangular box.** Four flat walls meeting
at hard 90° corners, a flat ceiling, a flat floor, one triplanar texture at one
scale across all of it, one prop. Thirty metres away through the wall is a
meadow with hundreds of pieces of variety per comparable area.

It does not read as unfinished because the rock texture is bad. **It reads as
unfinished because a cave does not have corners.**

### What shipped

`_build_interior_rock()` breaks the three junctions that say "box", and nothing
else: the **wall/floor** line, with rock banked along the inside of every wall;
the **wall/ceiling** line, in the four ceiling corners only; and the **flat
floor**, with scree thinning inward from the walls. Plus the playtest's own
other named direction — **lighting authored per space rather than inherited**:
every chamber previously had one dim pool of roughly the same energy in roughly
the same place, which lights a room evenly and therefore says nothing about it.
The den's fill drops and a warm key washes the guardian's half, so the alpha
stands in warm light in a room that falls off cool around it.

Three rules keep the fix from becoming the problem it replaced: everything sits
within `edge_band_m` of a wall, so the middle of every room is untouched and a
den fight keeps the arena `combat_arena_bounds_at()` promises it; nothing goes
in a doorway (`_doorways`, recorded by `_build_passages()`); and **none of it
has colliders**, which is the rule `_build_site_skirt()`'s own comment already
states — this is dressing, and a pebble that stops a player is a bug.
`smoke_warrens.gd` still walks the whole cave, entrance to branch chamber, 52 m.

### Two rounds of this were wrong, and the frames are why I know

Worth recording, because both mistakes are the kind that reasoning does not
catch:

- **Round 1 tinted the rock with `mound.tint` and the cave filled with green.**
  That value was tuned against the outcrop standing in direct sun. `_tint_rock()`
  *multiplies* `albedo_color`, which is the right tool outside — it keeps each
  rock's own shading and two blind rounds tuned the mound with it — but under
  0.3–1.5 energy pools the multiply does almost none of the work and what
  survives is the model's own mint texture. **Round 2 tried a much warmer tint
  and it was still green.** The fix was to stop guessing at multipliers: the
  interior rock now wears the *same triplanar `Rock030` material the chamber
  wall behind it wears*. Triplanar is what makes that legal on models whose UVs
  were authored for something else — it projects from world space and needs no
  UVs, the same reason the walls use it on primitive boxes. The result is not a
  rock tinted to look like the cave; it is the cave's own stone in a rock shape.
- **Round 2 capped rock HEIGHT and said nothing about WIDTH.** A five-metre-wide
  boulder sitting correctly against the den wall still reaches two and a half
  metres into the room, and one of them ended up between the camera and the
  guardian — the exact failure this pass exists to replace. Both caps are now in
  metres against each piece's *measured* bounds, because these models arrive at
  different sizes and a scale number means nothing across them.
- **Round 1's key light lit the ceiling.** Put at y=3.9 with a 9.5 m range it
  washed the roof while the guardian went to silhouette — and taught the other
  half: the guardian is a wild body with a `home` and it **wanders**, so a tight
  spot on its authored stand cannot track it. It is a broad wash over its half
  of the den instead.

### What is still flat, honestly

The junctions are broken and the rooms read as rock rather than as boxes, but
**the walls themselves are still flat planes** and the ceiling is still a slab
between its corners. This pass changes what the room's *edges* do; it does not
give the space vertical interest, level changes, or a silhouette. That is the
larger half of the owner's diagnosis and it is not done here.

### The other named site

**The stronghold is untouched, deliberately.** The coordinator's instruction was
not to start it until the Warrens is right, and getting the method correct once
in a room that matters is worth more than two half-passes. What this lane
learned that transfers: the junctions matter more than the surfaces; a kit's
material has to be re-derived for the light it is actually seen in; and cap
dressing by measured metres, not by scale factors.

### The register's own sites remain art-blocked, and that is unchanged

`GF-B-007` is blocked twice over — the quarry's pit and cut face are
`terrain_playground.json`, which `GATE_D_LANE_CONTRACT.md` §3 puts with the
coordinator and which carries a scatter re-bake behind it, and the dressing half
(a crane, a hoist, cut blocks) is `HIST-008`'s blocked-on-art list. The
`ralph/HIST-CLUSTERS` lane landed RC-5b on `main` the same day and probed the
installed kit directly rather than trusting the register: 64 modules, nine used
by no prefab, and **no well, no mill machinery and no gate module** in it. That
independently confirms `HIST-163`/`165`/`166` as art-blocked, and that lane
shipped the one slice that was not (`HIST-164`, the inn).

None of that changes. What changed is that the owner's complaint was never
really about those sites.

## Superseded: the earlier stand-down on item 3

### Original assessment, kept for the record



> *"some locations still look lame"*

Checked `HIST-008`/`HIST-119` first, as instructed, and then checked what other
lanes had already established.

- **`GF-B-007` (the Old Quarry) is blocked twice over and neither block is this
  lane's to lift.** The Gate F defects lane refused it on 2026-08-27 and the
  refusal is sound: the pit, the cut face and the benches are
  `terrain_playground.json`, which `GATE_D_LANE_CONTRACT.md` §3 puts with the
  coordinator and no lane may edit, and which carries a scatter re-bake behind
  it. The dressing half — a crane, a hoist, cut blocks, a worked spoil heap — is
  `HIST-008`'s blocked-on-art list, and `CLAUDE.md` is unambiguous that a new
  mesh needs owner-supplied reference art and that Meshy is reserved for Team
  Tether hero objects. A quarry crane is none of those.
- **The village-kit question is already answered, and by measurement.** The
  `ralph/HIST-CLUSTERS` lane landed RC-5b on `main` **today** (`15e1a6c8`). It
  probed the installed kit directly rather than trusting the register: 64
  modules, nine used by no prefab, and **no well, no mill machinery and no gate
  module** anywhere in it. That independently confirms `HIST-163`, `HIST-165`
  and `HIST-166` as art-blocked, and that lane shipped the one slice that was
  not (`HIST-164`, the inn, which had an identical module histogram to the
  farmhouse shell).

So there is nothing left under item 3 that is not either art-blocked on
owner-supplied reference art or another lane's live ground as of today. Spent
the time on items 1 and 2 instead, per the coordinator's own instruction.

---

## Evidence

`tools/capture_content_0828.gd` renders six stands through the real render path
(`xvfb-run` + `opengl3` at 1280x800; never `--headless` with a real driver).
`--before` writes to a separate directory so the same stands can be run against
a stashed tree, which is how the before set was taken — `origin/main`'s
`burrow_warrens.gd`, `tm_pickup.gd` and `burrow_warrens.json` checked out over
this branch, then checked back.

Half-scale before/after pairs are committed at **`docs/evidence/content-0828/`**
(the container is ephemeral and `shots/` is gitignored):

| frame | before | after |
|---|---|---|
| `02-alpha-close` | a dark shape two-thirds hidden behind a boulder | a plated alpha lit in a stone room, with the lit branch door in the same frame |
| `01-den-alpha-and-door` | green rock across the ceiling and the far half of the room | a den of banked stone under a warm key; the alpha reads instantly against the ordinary Trailpup standing in front of it |
| `03-vault-door-shut` | a flat brown panel filling a hole in a wall | the same panel with a lit seam down it — a sealed way on |
| `04-vault-prize` | a vault two-thirds filled with green rock | a chamber whose wall/floor line is banked with the cave's own stone, the heartstone the bright thing in it |
| `05/06-tm-pickup` | a tan rectangle standing in a field | the disc its own icon draws, on a plinth, catching light at both walk-up and decision distance |

**The exterior was re-checked, because lifting rocks could have regressed work
two blind rounds paid for.** `tools/capture_warrens_63.gd` — the BAND2-63 pass's
own probe, unchanged — was re-run against this branch. The knoll still reads as
a stacked rock outcrop with its courses running all the way up, and the mouth
still reads as a hole in a stone face flanked by boulders. Nothing moved out
there, which is what clamping against each chamber's *interior* rect rather than
its walled footprint was for.

Frames are for an independent critic; `ralph/conventions.md` forbids grading
your own.

### Honest limits of this evidence

- **`01-den-alpha-and-door` does not deliver its own brief.** The stand was
  chosen to put the alpha and the lit door in one photograph, and at the angle
  the cave actually has, the door is out of frame. The claim that the door is
  visible from the den floor rests on `03`, which is a head-on stand, not on a
  frame showing both at once. Worth re-framing on the next pass.
- **Nothing here is a played run.** These are camera stands in a live scene, not
  a player walking the dungeon. The fight with Earth Fist, the door sinking on
  the guardian's death, and whether the payout lands as a *moment* are all
  unmeasured by this lane — they need the walked segment, and the only Warrens
  walk this project has is `ralph/BAND2_WARRENS_EVIDENCE_2026-08-23.md`, which
  predates all of it.
- **Software GL.** Composition, silhouette and relative value are trustworthy;
  fine lighting judgement is not. Device frame rate, GPU cost and controller
  feel remain `[OWNER-ONLY]`.

## Tests

- `tests/smoke_warrens.gd` — passes. It also gained an assertion: the clear
  reward now checks **every** item its own config names, not just coin and
  rootstone. `test_chapter_rewards.gd` checks that the *audit* names real items,
  and the audit is a different file from the config the dungeon actually reads,
  so an id typo'd in `burrow_warrens.json` would have pushed an error, paid
  nothing, and been caught by nothing. Asserted against the config's own list
  rather than numbers repeated in the test, so retuning the payout stays a data
  edit. Output: `90 coin, 5 rootstone, 2 orb_greater, 1 revive`.
- `run_tests.gd --only=chapter_rewards,moves,trainers_data,recipes` — 127 tests,
  2128 assertions, 0 failed.

## For the coordinator

- **No cross-lane files touched.** Nothing under `tools/gate_f/**`,
  `scripts/world/grass_field.gd`, `scripts/world/water.gd` or the HUD.
- **One shared file, one line:** `data/config/chapter_rewards.json`'s Burrow
  Warrens row. It is the reward audit, and leaving it stating a payout that no
  longer ships would make it wrong.
- **`tests/smoke_warrens.gd`** gained the reward assertion described above.
- **No new asset, no sourced asset, no Meshy generation**, so no
  `docs/ASSET_LEDGER.md` entry is due. Every texture used here
  (`creature_burrowback_lod0_base_color_alpha.png` and its emissive sibling) was
  already installed and already ledgered.
- **Playtest §7 (grass through indoor buildings): the Warrens is NOT affected,
  and that is a measured negative rather than an assumption.** `grass_field.gd`
  is another lane's file and this lane did not touch it. But the cave is a named
  interior and the playtest asks explicitly whether the defect reaches "the
  Warrens' surface entrances, the stronghold, jetties, bridges". Every interior
  frame this lane rendered — mouth, hall, den, vault, across five capture rounds
  — has a clean stone floor with no grass in it. The mechanism agrees: the cave
  floor is a built slab sitting `floor_clearance` above the terrain and the cave
  stands proud of the meadow, so any grass the field puts on that terrain is
  *under* the floor, occluded. The grass lane should not spend time on the
  Warrens on the strength of the "everywhere" wording.
- **Playtest §8 asks whether a TM qualifies for new art. That is an owner call
  and this lane did not make it.** What shipped is the material/form/presentation
  work §8 itself says is available without art: the world prop is no longer a
  card. If the owner does supply reference art for a TM, the disc built here is
  the shape to replace, and `tm_pickup.gd` is the only file that draws it.
- **The boulder fix is not scoped to the Warrens' payoff and is worth flagging
  as such.** It changes `_place_rock()`, which every mound rock in the cave goes
  through. It was in scope because it is the Warrens and because the alpha work
  was unreadable without it, but a coordinator re-baking or re-siting this cave
  should know the mound now measures its rocks.
