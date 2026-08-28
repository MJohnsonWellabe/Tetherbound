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

**The world pickup is the defect, and the reason is sharper than "primitive".**
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

## 3. Some locations still look poor — **STOOD DOWN, with evidence**

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

`tools/capture_content_0828.gd` renders six frames through the real render path
(`xvfb-run` + `opengl3`, never `--headless` with a real driver) at the camera
stands the changes are about: the den with the alpha and the lit door in one
frame, the alpha close, the shut door head-on, the vault prize, and the TM prop
at walk-up and at decision distance. `--before` writes to a separate directory
so the same stands can be run against a stashed tree.

Frames are for an independent critic; `ralph/conventions.md` forbids grading
your own.
