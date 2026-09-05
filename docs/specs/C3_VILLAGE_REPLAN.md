# C3 — The village replan

**Status:** design contract, W19-CONTRACTS lane, 2026-09-04. Written against `main` at
`ef16544f`. Read-only on code and data; every *do* is an instruction to an implementation
lane. **Source directive:** `docs/owner/OWNER_PLAYTEST_2026-09-04.md` OP-0904-1. Plan row:
CL-O1 in `docs/GATE2_GATE3_CLOSURE_PLAN.md` §2.G; `docs/FINISH_THE_MEADOWS.md` Phase 2a C3.

The owner's words:

> Someone has to reorganize the opening village still make it houses along a road instead
> of in a circle. Have a field of berries, a grove of trees and a stone area.
>
> There are still too many people in the village. 5 at most. Put the rest throughout the
> rest of the game.

Every contract has an id (`V-…`, distinct from `GATE3_ENCOUNTER_CONTRACTS.md`'s relay
`V-1..V-6` — those are cited as "relay V-n" where they appear), a **do**, an **owns**, a
**tests** line and a **fails if**. Coordinates are world metres `(x, z)`; **+z is south**,
down the corridor (`MEADOWS_MACRO_LAYOUT.md` §3, D50). New coordinates are **layout intent,
not surveyed ground** — the repo's own rule (`terrain_playground.json` `_comment_ow5d`) —
and stage 1 below is the survey that turns them into positions.

---

## 0. The rules this document is built inside

- **The opening must never break.** `tests/smoke_opening.gd` is the chapter's first gate
  and it is fragile in specific, known ways (§4). Every stage below leaves it green.
- **No new humanoid meshes, no Meshy.** The 19 villagers are the installed cast
  (`docs/art/HUMANOID_ASSET_INVENTORY.md`); resiting moves bodies, not models.
- **One village family** (D24): every structure stays a `building_prefabs.json` prefab
  from the Medieval Village MegaKit at kit-native scale.
- **Resite, never delete.** CL-O1's own *fails if*: "the redistributed villagers are
  removed instead of resited." Every one of the 14 who leave gets a place, a reason to be
  there and something to say (§3). This is half of CL-O4's density answer.
- **Grandpa's house, its flat, its garden and the opening's markers do not move.**
  `playground_world.gd` `HOUSE_AT (−22,−16)`, the flat at (−22,−16) r14 h1.2, the door
  gate, the loft bed (CL-G12, owner-reproduced broken; not this contract's), the six farm
  plots (D50-hoe), the practice meadow at (30,−40) r15 where the first catch happens
  (`band1_lower_meadows/spawns.json` bramblebun), the road gate at (27.5,−16) whose key
  lies in the grass beside it. `MEADOWS_MACRO_LAYOUT.md` §3 says Band 0 does not move; this
  contract moves the *square*, not Band 0.
- **The tournament ground keeps everything it has** (§2.4).
- **Terrain changes cost a bake** and are staged so the opening is playable between every
  stage (§5, §6).
- **No `docs/owner/*` edits.**

---

## 1. What is there, measured

`data/config/village.json`: the settlement is a **ring around the well** at (10,−10) on
the square flat (r18, h0.9): workshop north (2,2), cottage_a north-east (18,−2, Mira's
shop), cottage_b east (21,−14), inn west (−1.5,−9), wagons, three fence runs, five oaks,
three doorsteps, plus the mill/footbridge/ranger station at the Pond 500 m away. Five
painted routes leave the well (`terrain_playground.json` `paths.routes`): Grandpa's house
west, the inn, the practice meadow south-east, the Pond north-west, the Rise east — a
hub with spokes, which is the "circle" the owner sees. The corridor spine leaves the
square **south** through TrailGate at (13.8,22.4) — `trail.bands[0]` (27.5,−16) → (14,20)
→ (8,90). The village fence (`village_boundary.json`) is a rounded blob with three gates:
RoadGate east (38,−22), PondGate north-west (−21,21), TrailGate south (13.8,22.4).

`data/config/village_npcs.json`: **19 villagers**. Twelve stand on or beside the square;
seven are already elsewhere (Rae at the herd, Maren and Sorrel at the Pond, Tobin on the
Rise road, Kell and Sela conditional). The 2026-09-02 playtest already said "still too many
characters in the village" and T1-CREATURE-RIG had placed twelve civilian bodies "that
had never stood up anywhere"; OP-0904-1 says it again with a number.

Harvest (`band1_lower_meadows/harvest.json`, 48 nodes, 28 inside the fence): wood ×8,
stone ×4, fiber ×8, berries ×6, one Revive and one potion within 80 m of the square,
scattered singly across the yard so no place is "the berries" or "the stones".
`tests/test_village_boundary.gd` pins all 28 inside the polygon.

---

## 2. The plan

### 2.1 V-1 — Houses along a road, not around a well

The road is **the chapter's own road**: the painted spine from Grandpa's door east to the
square and south through TrailGate. The village becomes a **street** on that L, roughly
80 m long, houses on both sides, the well at the bend where the two legs meet, the road
running *through* rather than *around*.

*Do:* re-site the five buildings and the well onto the two legs. Target coordinates (intent):

| Structure | Today | Target | Leg | Why |
|---|---|---|---|---|
| Grandpa's farmhouse | (−22,−16) | **unchanged** | west end | Band 0 does not move |
| inn (`inn`, interior) | (−1.5,−9), yaw 90 | (−6,−14), yaw 90, door east onto the road | west leg, south side | already the first building past the farm; nudged onto the road's shoulder |
| well | (10,−10), yaw 15 | (10,−10), **unchanged** | the bend | it is the one thing the routes already meet at; it stays and the routes are pruned around it |
| cottage_a (Mira's shop) | (18,−2), yaw −135 | (18,4), yaw −90, door west onto the south leg | south leg, east side | first house on the road out, the shop faces the traffic |
| workshop (Tam's) | (2,2), yaw −125 | (2,12), yaw 90, arch bay east onto the south leg | south leg, west side | the smithy across the street from the shop; its yard is the stone area (V-4) |
| cottage_b | (21,−14), yaw −70 | (19,−18), yaw −110, door north-west onto the west leg | west leg, south side, by the bend | keeps its own flat at (21,−14) r7 — the move is 4 m, inside it |
| wagon ×2, doorsteps ×3, fences | various | re-derived from the built colliders (stage 1) | — | dressing follows buildings |
| the five oaks | various | two stay (behind the workshop, the south edge); three become the grove (V-3) | — | "a grove of trees" wants its trees |

The three routes that made the hub a hub — the inn spur, the Pond spur from the well, the
Rise spur from the well — are **replaced by two**: the street's west leg (Grandpa's door →
the well) and the street's south leg (the well → TrailGate), both already the spine. The
Pond road and the Rise road leave from the street's ends (PondGate off the west leg's
north side, RoadGate off the bend), so no gate moves.

**What this costs:** cottage_a and the workshop leave the square flat's r18 disc (their
targets are 14–22 m from (10,−10) on the south leg — right at the flat's edge). They need
ground. The honest options, stage 1 decides between them by probing: (a) the square flat's
radius grows from 18 to 26 and the south leg's houses sit on it; (b) each gets its own
small flat, as cottage_b already has. Either is a `terrain_playground.json` `flats` edit
and therefore **a bake** (§5). The west-leg buildings (inn, cottage_b) stay on existing
flats and move in stage A.

*Owns:* `data/config/village.json`, `data/config/terrain_playground.json` (`flats`,
`paths.routes`, `building_aprons.footprints` — the village entries only),
`scripts/world/village.gd` (no change expected), `data/config/vegetation.json` (the
village `clearings` that hold scatter off the footprints).
*Tests:* `tests/test_village_boundary.gd` (every structure's footprint inside the fence;
the three gates' geometry rule holds — §4.2); a new `tests/test_village_street.gd`: every
structure's door node is within 6 m of one of the two street legs' polylines and faces
it (dot of door-forward with the leg's normal > 0.5), and no structure's footprint
intersects the painted road (`paths.width` + `shoulder`); `tests/smoke_gate_a_build_house.gd`
and `tests/smoke_gate_b_continuous.gd`'s village beats stay green.
*Fails if* any building's door faces away from the road, if any footprint stands on the
painted road, if the well moves, or if the replan is done by moving Grandpa's house.

### 2.2 V-2 — The berry field

*Do:* a **field** on the farm side of the street: the open ground north of Grandpa's
kitchen garden and west of the inn, centre (−22,2), roughly 18 × 12 m, fenced on the road
side with two `fence_run`s and a `garden_gate`-style opening (the props cluster already
exists), holding **all six** of the village's berry nodes re-sited into two rows —
today's (−32,−1), (−9,−19), (0,18), (28,6), (20,−16), (38,−36) become six bushes at
(−28,−2), (−24,−2), (−20,−2), (−28,6), (−24,6), (−20,6) — plus the six existing farm plots
directly south of it. A `map_landmarks.json` minor landmark **"Berry Field"** at (−22,2),
`discover_radius` 20, so the map names it. Garrick's farmer body leaves (§3); the field is
Grandpa's and the player's.

Why here: berries are the one resource with no tool (D50-hoe), the first thing the
player picks, and the farm is where the hoe teaches tilling; one place for "food" beside
the house closes the opening's gather loop (`objectives.json` `tournament_feed_team`) on
ground the player already walks between the bed and the road.

*Owns:* `data/config/bands/band1_lower_meadows/harvest.json` (the six berry entries — ids
and `order` unchanged, positions only), `data/config/village.json` (two fence runs),
`data/config/bands/band1_lower_meadows/props.json` (a `berry_field` cluster: crates, a
bucket, from the installed prop family), `data/config/map_landmarks.json`.
*Tests:* `tests/test_harvest.gd` (the six berry `order`s survive; all six within 12 m of
the landmark); `tests/test_village_boundary.gd` (all inside the fence);
`tests/test_gate_a_material_route_contract.gd` (the route's berry stock is unchanged);
`tests/test_map_landmarks.gd` (the landmark exists and is discovered from the doorstep —
the starting reveal already covers this ground).
*Fails if* a berry node leaves the fence, if the field is placed where the smoke's gather
walker cannot reach it (§4.3), or if any bush regains a respawn (D72).

### 2.3 V-3 — The tree grove

*Do:* a **grove** on the practice-meadow side of the street: the ground between the south
leg and the practice meadow, centre (30,−26), roughly 25 m across, holding **the village's
wood**: today's eight wood nodes within 80 m — (16,−28), (26,−44), (40.5,−28), (−8,8),
(6,−34), (36,−16), (−14,−8), (33,−23) — re-sited into a stand at (22,−24), (27,−30),
(33,−26), (36,−20), (24,−36), (30,−38), (38,−33), (20,−30), with three of the five square
oaks moved in among them at 1.15–1.25 scale as the canopy the harvest saplings sit under,
and one `vegetation.json` **clearing removed** so the scatter's own trees are allowed
back around the stand (today the practice-meadow clearing holds them off). A minor
landmark **"The Grove"** at (30,−26), `discover_radius` 25.

The grove is bounded on the east by the existing practice-meadow fence runs (which now
fence *something*) and on the south by the practice meadow itself — the first catch
happens at its edge, which is the right place for the first place the player chops.

*Owns:* `harvest.json` (eight wood entries, positions only), `village.json` (three oaks
moved), `vegetation.json` (one clearing), `props.json` (a `grove` cluster: a woodpile, a
stump — installed props), `map_landmarks.json`.
*Tests:* `tests/test_harvest.gd`, `tests/test_village_boundary.gd`,
`tests/test_gate_a_material_route_contract.gd` (wood stock unchanged),
`tests/test_veg_corridor.gd` / `tests/test_scatter_rules.gd` (the clearing edit is
inside the village's own bands and the fingerprint moves only there —
`tests/test_scatter_fingerprint_covers_bands.gd`).
*Fails if* the grove overlaps the practice meadow's spawn disk (r15 at (30,−40); the
2.4 m clearance `test_village_boundary` already pins), if a wood node stands on the
painted road, or if the scatter change re-rolls anything outside the village clearing
(D57: it will not — the clearing is a rejection test resolved before the draws).

### 2.4 V-4 — The stone area

*Do:* a **stone yard** behind the smithy: the ground south-west of the workshop's new
site, centre (4,−30), roughly 16 m across, holding the village's stone: today's (22,−34),
(47,−34.5), (−18,6), (11,−32) re-sited to (0,−28), (5,−33), (9,−27), (3,−36), with the
`rock_form` layer's own outcrop grammar (the terrain's `_comment_rock_form` dressing)
placed by `props.json` as two `rock_outcrop` clusters from the installed rock family, so
the stones read as an outcrop the smith works, not four pebbles. A minor landmark
**"Stone Yard"** at (4,−30), `discover_radius` 20. Tam stands at its edge (§3, he keeps
his spot at (8,−16), 15 m from it — the road-side face of his own yard).

*Owns:* `harvest.json` (four stone entries), `props.json` (two clusters), `map_landmarks.json`.
*Tests:* as V-2/V-3; plus `tests/test_gather_point_props.gd` (the outcrop props do not
occlude the node prompts — the sightline smoke `smoke_interactable_sightline.gd` covers
this).
*Fails if* a stone node is inside a prop's collider, or if the yard sits on Grandpa's
flat (it does not: (4,−30) is 24 m from (−22,−16)).

### 2.5 V-5 — The tournament ground and Grandpa's house keep everything

*Keep, verbatim:* the board at (20,15) facing 205°, the ring, Bryn's practice challenge at
(13,9), the two spectator benches (`tournament_ground` cluster), Halda's post at
(23.5,11.5), the 14 m vegetation clearing, the bracket, the three rounds, the sign-up
ladder, `min_party_size 5` / `min_level 5`. Grandpa's house: the farmhouse shell, the
flat, the door gate, the loft (broken, CL-G12, not here), the six plots, the two garden
rails, the cart, the door lantern, the woodpile and crate.

*What changes near them:* cottage_a's new site at (18,4) is 12 m from the board at (20,15)
and 9 m from Bryn at (13,9). Stage 1 probes the colliders; if cottage_a's footprint or its
doorstep enters the board's 2.6 m prompt radius or Bryn's challenge radius, cottage_a
moves **south along the leg**, never the board. The tournament ground is the reason the
south leg is a street at all — the road out passes the ring — and `tournament.json`'s
"board and Bryn 9.2 m apart on purpose" is preserved.

*Owns:* nothing in `tournament.json`, `grandpa_house.gd`, `farm.json` — this section is a
constraint on V-1.
*Tests:* `tests/test_tournament.gd` (unchanged, green); `tests/smoke_gate_a_opening_segment.gd`;
`tests/test_village_boundary.gd`'s existing pins on the practice disk and the (48,−58)
catch stand.
*Fails if* any tournament or farmhouse coordinate moves.

---

## 3. Five villagers stay; fourteen go out into the chapter

### 3.1 V-6 — The five

The choice is by **function the opening cannot lose**, then by story:

| Stays | Why they cannot leave |
|---|---|
| **Mira** | Band 1 trainer, the shop (OF31, owner-asked), tournament quarter-final, the Orb recipe |
| **Oskar** | Band 1 trainer, creature swaps, tournament final, the bridge lore that names Team Tether as the obstacle |
| **Tam** | the tools (`tam_tools_given`, a MAIN STORY rung), Band 1 trainer, tournament semi-final, the smith the stone yard belongs to |
| **Halda** | the tournament marshal (13-branch ladder), the champion's Revives and the saddle recipe (CL-G3), the every-trainer task's voice (C2 T-8) |
| **Bram** | the general shop (`village_bram_shop`) — the village's second merchant, kept so the five include a place to buy and not only sell; his shop-exit clip is `CURRENT_STATE.md` §3's and stays that lane's |

Grandpa is in his house, not on the street, and is not counted; the owner's "5 at most"
is about the people standing in the village. Sela and Kell are conditional bodies who
arrive **after** their flags — and both are resited (§3.2) so that even after the rescue
and after the freeing, the street holds five.

**One role moves so the five can be five:** the Quarry Foreman's camp hammer
(`village_quarry_foreman_hammer`, flag `camp_hammer_given`, a rung the build objective
needs) moves onto **Tam's tools conversation** — `village_tam_tools` gains
`give:camp_hammer:1` and `flag:camp_hammer_given` on the line where he hands over the
axe, pickaxe and knife. A smith handing over a hammer needs no explanation; a quarryman
standing in a village square 1,800 m from his quarry did.

*Owns:* `data/config/village_npcs.json` (the five entries stay; the rest gain `place_when`
or move to band files), `data/dialogue/village.json` (Tam's line; the Foreman's hammer
branch retired).
*Tests:* `tests/smoke_gate_b_continuous.gd` (the tools beat, the hammer, the tournament
readiness ladder — must stay green); `tests/test_gateb_objective_chain.gd`;
`tests/test_band_dialogue.gd`; a new assertion in `tests/test_village_boundary.gd`: the
number of `village_npcs.json` bodies with an unconditional placement inside the fence is
**exactly five**, and the number placed inside the fence under any flag combination never
exceeds five.
*Fails if* a sixth body can stand inside the fence under any flag state, if
`camp_hammer_given` can no longer be set before the build rung, or if any of the five loses
a `greeting_when` branch in the move.

### 3.2 V-7 — Where the fourteen go, and what they do there

Every move reuses the mechanism `relay_site.json` and `pond_npc.json` prove:
`village_npcs.gd::build()` takes a second config path, so each band gains a
`people.json` (Band 1 already has `pond_npc.json`; it is renamed or extended). Positions
are intent; each is placed by a ground probe (`tools/_probe_world_content_0903b.gd`'s
method: dry, < 12° over a 2 m pad, off the painted road's shoulder). Each entry keeps its
rig, its `config_key` and its existing `greeting`, and gains the branch its new role
names. **Nobody is deleted; nobody stands in the village.**

| Who | Rig | Today | Goes to | Band | What they do there | Feeds |
|---|---|---|---|---|---|---|
| **Quarry Foreman** | quarryman | (0,−6) | the Old Quarry floor, ~(392,1792), by the conduit head | 2 | the quarry relay's voice: "they run the conduit off my quarry" — surfaces C2's relay chain; his hammer gift moved to Tam | C2 T-7 |
| **Wilhelm** (innkeeper) | innkeeper | (−8,−3) | the Trail Camp, ~(341,932), by the fire | 1 | the camp's host; a capped food stock (`trade.json`: berries, a cooked meal — 3 per day); voices the camping chain | C2 T-12, C4 |
| **Corin** (trader) | trader | (9,4) | the Old Mill Crossing near bank, ~(−150,4232) | 3 | a peddler stuck at the shut crossing; capped potions/Revives (2 each per in-game day — C4's scarcity rule), moves to the mill's yard on `mill_crossing_restored` | C4 |
| **Ada** (craftsperson) | craftsperson | (−3,7) | the abandoned ranger camp, ~(−262,2258) | 2 | salvaging; teaches the `saddle_frame` use in one line ("build it and it shows on the animal"); voices the Ironwood survey | C1 §6, C2 T-11 |
| **Garrick** (farmer) | farmer | (6,−34) | a Long Field farmstead on the Band 1 road, ~(−45,185), with three berry nodes and a fence | 1 | the first face past the fence; "the herd's been through my field" points at Rae's Meadowhart | density |
| **Old Perrin** (historian) | local_historian | (−15,−5) | the Rise crest overlook by the dead tree, ~(−378,352) | 1 | the man who knows the seven roads (spec §29); stands at the first overlook C1's Scout uses | C1 R1-7 |
| **Tobin** (lost traveler) | lost_traveler | (80,−33) | the South Bridge approach, ~(−28,1298) | 1 | turned back at the crossing: "he sized up my team and laughed" — the diegetic warning for D75's level gate | D75 |
| **Maren** (field researcher) | field_researcher | (−343,501) | **stays** at the Pond ranger station | 1 | voices the Rootstone survey | C2 T-11 |
| **Sorrel** (alpha tracker) | alpha_tracker | (−390,524) | **stays** at the Pond shore | 1 | voices the alphas task; she is 100 m from the elder Mosshell | C2 T-9 |
| **Lark** (courier) | courier | (19.6,−35.3) | the near-bank river walk, ~(−32,4062) | 3 | "can't get a letter across since they pulled the gear" — points at Sela and the mill | story |
| **Ren** (former Tether member) | former_tether_member | (26,−19) | the wind-ridge traverse, ~(334,5704), near the Band 4 rest point | 4 | the deserter who explains consoles answer only once their guard is down, and what a Sigil is | C2 T-7, T-10 |
| **Sela** (after rescue) | villager_ranger | (16,−10) `if captive_rescued` | the Pond **ranger station**, ~(−348,505), `if captive_rescued` | 1 | a ranger goes home to the ranger station, not to the square; `village_rescued_ranger_home` plays there | story |
| **Kell** (after freeing) | villager_keeper | (184,52) `if legendary_freed` | **stays** — already outside the fence on the Rise road | 1 | the storm-road traveller, as shipped | story |
| **Rae** | villager_farmer | (−205,1185) | **stays** at the Meadowhart herd | 1 | as shipped | — |

Six of the fourteen were already outside the fence (Maren, Sorrel, Rae, Tobin, Kell,
Sela-conditional); the contract keeps them out and gives the other eight real places. Bands
2, 3 and 4 each gain two or three faces on the route — the "density" half of CL-O1.

*Owns:* `data/config/village_npcs.json` (entries removed or made conditional),
`data/config/bands/band{1,2,3,4}_*/people.json` (new or extended), `scripts/world/village_npcs.gd`
(no change expected — the second-config path exists), `data/config/trade.json` (Wilhelm's
and Corin's capped stock), dialogue files for the new branches.
*Tests:* `tests/test_band_dialogue.gd` (every new branch resolves); `tests/test_band_content.gd`
(each `people.json` entry sits inside its band's `z` range — `chapter_curve.json`);
`tests/test_camp_supply_reaches_every_band.gd` (unchanged, green: the trail camp gains a
host, not a second supply); `tests/smoke_relay.gd` (Sela's rescue still fires and her body
appears at the ranger station, not the square); `tests/smoke_gate_b_continuous.gd`; a new
`tests/smoke_village_five.gd`: boot a fresh save, count bodies inside `village_boundary.json`'s
polygon = 5; set `captive_rescued` and `legendary_freed`, count again = 5.
*Fails if* any villager is deleted, if any resited body stands on a painted road or
inside another cluster's collider, if Corin's or Wilhelm's stock is uncapped (C4), or if
the village count exceeds five under any flag state.

---

## 4. The opening's smoke constraints — read before touching anything

### 4.1 V-8 — `smoke_opening` finds its targets by prompt substrings

`tests/smoke_opening.gd` locates the wake gate by `"get up"`, Grandpa by `"grandpa"` and
`"talk"`, and the three starters through `starter_picker.gd`; it fails if a *village*
"Greet" prompt or a trainer prompt ever contains `"talk"` or `"choose"`
(`village_npcs.json`'s own header and `trainer_npc.gd::_prompt_for()` both record this).
The five who stay and the fourteen who move keep `"Greet <name>"` as their prompt label,
built by the placer, never stored. Every new conversation id, `voice` line and branch
name this contract adds is checked against those two substrings by
`tests/test_band_dialogue.gd` (extend: no prompt label anywhere in a `people.json` or
`village_npcs.json` contains them).

*Fails if* any prompt label in the village or on the route contains `"talk"` or `"choose"`.

### 4.2 V-9 — The fence corner past TrailGate

`village_boundary.json`'s `_why_third_road_and_jambs_2026_09_02` records the rule every
gate follows: **the gate sits at the exact midpoint of its own 4.4 m edge, and both
neighbouring edges are multiples of 6.15 m (±0.3)**, so the jambs seal and the visible
prefab reaches the corner. `stick_navigator.gd` (FENCE-CORNER-0903) rounds the concave
corner just past TrailGate (the `TrailGate → vertex 7` edge) with a committed detour that
a real body clears on a plain stick-hold. **The replan does not move TrailGate, PondGate or
RoadGate, and does not change the two edges either side of any gate.** The street's south
leg passes through TrailGate exactly as the spine does today. If V-1's workshop site
needs the fence's south-west run to move, the run that moves is the one *between* PondGate
and TrailGate, kept to 6.15 m multiples, and the corner past TrailGate is left as
measured.

*Tests:* `tests/test_village_boundary.gd` (the gate rule, every node inside, the
practice disk clearance); `tests/smoke_gate_b_continuous.gd`'s gather route (the walker
rounds the corner); the FENCE-CORNER-0903 escape probe (`village_boundary.json` names it)
re-run at every gate after any edge changes.
*Fails if* a gate or its neighbouring edges change, or if a keyless body can leave the
fence at any offset the escape probe walks.

### 4.3 V-10 — The gather route

`tests/helpers/gate_a_material_route.gd` walks the village's authored nodes to a target
stock of wood 69 / stone 42 / fiber 34; `test_gate_a_material_route_contract.gd` pins the
route's arithmetic; `smoke_gate_b_continuous.gd` drives it with the stick walker, which
fails on building walls and concave corners. The berry field, grove and stone yard
**concentrate** the nodes the route already uses; the walker therefore has *shorter*
legs, but each named place must be reachable from the road by a straight stick-hold with
no wall between: the field's road-side gate opening faces the street, the grove has no
fence on its street side, the stone yard's outcrops stand *behind* the nodes from the
road's point of view. Stage 1 walks the route with `tools/_probe_ow5_walk.gd`'s
wedge report before any node moves.

*Tests:* `tests/test_gate_a_material_route_contract.gd` (stock unchanged);
`tests/smoke_gate_b_continuous.gd` (the route completes); `tests/test_harvest.gd`.
*Fails if* the route's stock changes, if any node needs a wall to be rounded, or if the
walker's stall count on the route rises above today's.

---

## 5. Terrain and bake implications — what needs one and what does not

A **terrain re-bake** is `build_playground_terrain.gd` on the affected regions:
measured at ~143 s per 512 m region (D55) and the brief's 25–40 minutes for the village's
neighbourhood (the origin region and its three neighbours, plus their skirts). A **scatter
re-bake** is the vegetation pass at load and costs minutes, not the terrain. Harvest
nodes, props, NPCs, landmarks and dialogue cost **nothing**: they stand on sampled ground
(D09).

| Edit | File | Bake |
|---|---|---|
| Inn, cottage_b, well, fences, wagons, oaks moved *within existing flats* | `village.json` | none |
| Harvest nodes re-clustered (V-2, V-3, V-4) | `harvest.json` | none |
| New prop clusters, landmarks | `props.json`, `map_landmarks.json` | none |
| NPC resiting, dialogue | `village_npcs.json`, `people.json`, dialogue | none |
| Villager placement, capped stocks | `trade.json` | none |
| Grove clearing removed | `vegetation.json` | **scatter** (village region only, D57) |
| Cottage_a and the workshop onto the south leg (new or widened flat) | `terrain_playground.json` `flats` | **terrain** |
| The street's two legs replacing three spur routes (painted road, path_factor) | `terrain_playground.json` `paths.routes` | **terrain** |
| Building aprons for the two moved houses | `terrain_playground.json` `building_aprons.footprints` | **terrain** |
| `tether_relay.json` `dead_ground.enabled` | — | **not touched** (a relay-region concern, not the village's) |

So **exactly one terrain bake** is needed, for the south leg (flats + routes + aprons
together), and it is scheduled as its own stage. Everything else lands without one.
`tests/test_terrain_bake_freshness.gd` will go red the moment `terrain_playground.json`
changes and stay red until the bake lands — that is its job; the lane sequences the
stage so the red is one PR, not three.

*Fails if* a stage that says "no bake" edits `terrain_playground.json`, or if the bake
stage edits anything outside the village's regions.

---

## 6. The staged plan — the opening never breaks

Each stage is one branch, one PR, green on `smoke_opening`, `smoke_gate_a_opening_segment`,
`smoke_gate_b_continuous` (its reliable prefix) and `test_village_boundary` before it
lands. The village is playable between every pair.

| Stage | What lands | Bake | Gate |
|---|---|---|---|
| **0 — survey** | a scratch probe (`tools/_probe_village_street.gd`, uncommitted or under `tools/`) prints every built structure's world AABB, door node, prompt radius and every NPC's position, walks the gather route with the wedge report, and probes ground at every target in §2 and §3.2. Output: the *measured* coordinates that replace this file's intent, recorded in the lane's report | none | the numbers exist |
| **A — people** | V-6, V-7: the five stay, the fourteen move, the hammer moves to Tam, capped stocks, `smoke_village_five` | none | the village has five people; every resited body stands and speaks |
| **B — places** | V-2, V-3, V-4 on the existing flats: nodes re-clustered, clusters, landmarks; the west-leg buildings (inn, cottage_b) moved | scatter only | the gather route completes; three landmarks discover; `test_harvest`, boundary, material-route green |
| **C — the street** | V-1's south leg: cottage_a and the workshop moved, the flat(s), the two routes replacing three, the aprons; V-5 re-checked against the built colliders | **terrain** (one) | `smoke_opening`, `smoke_gate_a_build_house`, `smoke_gate_b_continuous` green on the baked terrain; the escape probe passes at all three gates |
| **D — judge** | a render from the four village stands `BAND1_COMPOSITION_PLAN.md` names (village approach, route out, the twins, the tournament ground) put to the code-blind judge with the one question: *does this read as houses along a road with a berry field, a grove and a stone yard?* | none | the verdict, committed under `ralph/reports/<LANE>/` |

Stages A and B are independent of each other and of C; C waits for A (so the street's
people are already where the street wants them) and for a bake window. D waits for C.

**If C's bake cannot be scheduled**, A and B still ship: five villagers, three named
places and a village that is measurably less of a circle (the inn and cottage_b on the
west leg, the spur routes' ends unused) is most of the owner's ask, and the rest is one
bounded bake.

*Fails if* any stage lands with `smoke_opening` red, if stage C is split across more than
one bake, or if stage D's judge is told what changed.

---

## 7. What this deliberately does not do

- Does not move Grandpa's house, the practice meadow, the road gate, the tournament
  ground, TrailGate/PondGate/RoadGate or the two edges beside any gate.
- Does not fix the loft bed (CL-G12), Bram's shop exit clip, or the dialogue camera
  (CL-G10) — those are their own rows.
- Does not add a villager, a building, a prop family or a mesh.
- Does not touch the Pond group (mill, footbridge, ranger station) except to receive Sela.
- Does not decide the Band 2–5 density numbers; it contributes eight bodies to them.

---

## 8. Evidence the lane scores

A fresh player walks out of Grandpa's door and, without a map, can say: that is the road,
those are the houses on it, that is where the berries are, that is the wood, that is the
stone. They meet five people in the village and at least eight more before the river,
each of whom says something about where they are. The opening smoke passes unchanged.
The gather route completes with fewer stalls than today. A blind judge shown the four
village stands says "street", not "circle".
