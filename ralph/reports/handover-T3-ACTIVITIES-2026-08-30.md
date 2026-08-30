# Handover — T3-ACTIVITIES, 2026-08-30

**Branch:** `ralph/T3-ACTIVITIES`, off `origin/main` at `cba700b5` (LAND-0830B).
**Working tree:** all listed below, pushed at handover time.

---

## 0. Post-handover follow-up (coordinator work order, second pass)

After the §1-§9 work below was pushed, CI came back red on `29638d3c` and the
coordinator sent a follow-up work order. Two parts:

**Part A — fix CI. Done.** `tests/test_dual_type.gd::test_no_trainer_roster_
creature_is_dual_typed` failed: `night_watch_farro` (my own Band 2 trainer,
§2 below) fielded `nightburrow`, which the concurrent DARK-FEATURES/T3-
MATCHUPS lane landed as Ground/Dark the same day. My own species-type check
while designing that trainer only read `type`, never `type_secondary`, so I
missed it. Per `ralph/reports/MATCHUPS_DESIGN_2026-08-30.md` sec4.4, keeping
dual-typed creatures off every authored trainer roster is a deliberate
invariant (it is the whole reason that design note can claim the authored
ladder does not move at all) — not a bug to route around. Fixed by swapping
`nightburrow` for `trailpup` (single-typed, Band-2-resident, not already used
by Dorn/Pell/Kest in the same file). Re-verified: `test_dual_type.gd` and the
rest of my own targeted suite are green, and `tests/smoke_local_requests.gd`
still passes end to end with the new roster. Commit for this fix is separate
from the original §1-§9 work so the fix is visible on its own.

**Part B — three JUDGE-3 blind-pass findings routed to content.** See §10.

---

## 1. What I was asked, and where I got to

Owner-approved scope (2026-08-29), in priority order: five new optional
activities, reward reachability, a captain rebalance, and dead-Meadows
cadence if time remained.

**1. OPTIONAL ACTIVITIES — done, all five, all played-path verified.**
**2. REWARD REACHABILITY — audited clean; two findings resolved as explicit
decisions.**
**3. CAPTAIN REBALANCE — done for both named captains, verified with
non-mirror combat-lab evidence.**
**4. Cadence pass — not started; see §6.**

---

## 2. The five Local Requests

All five are `spec` sec6 candidates (`docs/MEADOWS_PROGRESSION_SPEC.md`), all
data-driven through the existing `objectives.json` `local` array +
`revealed_by` pattern `band1_old_champion` (Old Bram) already proved, and all
reuse existing world verbs, existing NPC rigs and existing creature meshes —
nothing new was generated.

| activity | band | mechanism | giver/battle | reward |
|---|---|---|---|---|
| Meadowhart Herd | 1 | discovery, no combat | Rae (new `village_npcs.json` entry, off-spine near the existing BAND1-D1 herd, spawns.json order 1005) | 3x `orb_basic` |
| Broken Cart | 1 | gather + deliver | Coll (new `cart_repair.gd` node, South Bridge approach) | the repair itself; no item reward, the point is the delivery |
| Night Watch | 2 | trainer battle | Farro (`night_watch_farro`, band2 trainers.json order 2003) — one character is both giver and fight, Old Bram's own shape | 40 coins, 2x `potion_small` |
| River Nest | 3 | trainer battle | Doss (`river_nest_doss`, band3 order 3000) | 45 coins, 1x `potion_large` |
| Lost Creature | 4 | trainer battle | Rue (`lost_creature_rue`, band4 order 4002) | 50 coins, 1x `revive` |

**Why one-character-is-the-giver for three of the five.** The brief asked for
"a giver" per activity. Old Bram (the one existing Local Request) already
establishes that a trainer's own pre-battle dialogue can BE the giver — he
introduces the mystery, offers no fetch-quest, and the fight is the whole
activity. I followed that precedent for Night Watch/River Nest/Lost Creature
rather than adding three more standalone NPCs: it is proven, tested-by-
precedent, and adding a second body per activity would have doubled the
placement/siting work for no mechanical gain. Meadowhart Herd and Broken Cart
are not combat, so each gets its own placed body instead.

**Species/reward choices are all existing content.** Night Watch's Farro
fields `nightburrow`+`duskhush` (both Band 2 residents) rather than Kest's
own `burrowback`+`duskhush` loadout one fight back, so the two optional
Band 2 fights do not read as the same encounter twice. River Nest's Doss
fields `paddlenewt`(water)+`galecrest`(air) — literally spec sec6's own
"aggressive Water/Air creatures". Lost Creature's Rue fields `burrowback`+
`trailpup` as her own guard team; the player is never asked to fight the
stolen Meadowhart itself. All three trainer levels sit inside their band's
`chapter_curve.json` floor/ceiling (`test_every_trainer_fights_at_their_own_
regions_strength` is green).

**Sites**, all ground-checked with the new `tools/_probe_activities_sites.gd`
(same pattern as T3-PICKUPS's own `_probe_pickups_sites.gd`) and checked for
≥20m clearance from every other authored point in their band:

| who | position | worst local slope (3m pad) |
|---|---|---|
| Rae | (-205, 1185) | 6.2° |
| Coll's cart | (80, 1240) | 10.5° |
| Farro | (95, 2900) | 9.8° |
| Doss | (66, 3988) | 3.1° |
| Rue | (-300, 5870) | 12.3° |

**`cart_repair.gd`** (new, ~110 lines) is the one new script this branch
adds beyond content. It is a thin wrapper reusing two mechanisms that already
exist: `item_gate.gd` (SB10's own "does the player have what it takes"
multi-item consume — already the South Bridge key's and the three Sigils'
mechanism, now pointed at `["wood","stone","fiber"]` instead of a key) and
`building_prefabs.gd`'s existing `"wagon"` prefab (already parked once in the
village by `village.json`, a `Prop_Wagon.gltf` from the installed
quaternius_medieval kit — no new mesh). No new turn-in system, no new
inventory/currency/recipe concept.

**Played-path verification: `tests/smoke_local_requests.gd`** (new). Boots
the real `meadows_playground.tscn`, adopts a starter, then for each of the
five activities: finds the real placed body, drives the real dialogue panel
to the real `battle:`/`give:`/`flag:` effect, and — for the three combat
activities — runs the fight to a real win through the real
`encounter_director`/`combat_manager` pipeline (the same HP-floor allowance
`smoke_boss.gd`/`smoke_trainer_battle.gd` already use, for the same "this is
about wiring, not balance" reason), then asserts the real `defeat_flag`/
reward/consumption happened and that `scripts/world/quest_log.gd` — the real
reader, never restated — reports the Local Request as revealed and done. One
boot covers all five rather than five separate CI-cost world boots. **Green,
full run, after the captain rebalance landed too** (log in §4).

`tests/test_item_cache_pickup.gd` (new, 15 tests) closes the one direct-test
gap T3-PICKUPS's own handover flagged for `item_cache_pickup.gd`. Covers
everything reachable without a live `/root/Game` autoload per D02's own pure-
logic scope (`flag_id`, `was_taken`, `restore_progression_from_game`,
`_build_visual`'s PackedScene-vs-Mesh branch) using a `Node`-typed fake
carrying the real `progression_state.gd`, the same shape
`test_harvest_permanence.gd`'s `FakeHarvestGame` already uses. Documented
plainly what it does NOT cover and why (`_on_picked_up()`'s own `/root/Game`
lookup, same class of gap `test_harvest.gd` already documents for
`harvest_node.gd::_on_gathered()`).

---

## 3. Reward reachability

**Re-verified against the live tree before trusting anything in the prior
handovers**, per this repo's own "evidence-backed already fixed is valid"
rule. Result: **every elixir and every armor piece the T3-PICKUPS handover
flagged as still-open is already placed.** T3-PICKUPS's own harvest-node
scatter covers `hide_helm`/`hide_leggings`/`hide_boots`/`travel_pack` and its
`item_cache_pickup.gd` covers `elixir_might`; T3-REWARD's three captain
rewards cover `elixir_guard`/`elixir_vigour`, and its Warrens reward covers
`hide_vest`. A repo-wide id-presence scan (every band's harvest/trainers/
props, `burrow_warrens.json`, `trade.json`, dialogue) found exactly two other
item ids with no reference anywhere — `fishing_rod` (its own blurb already
says why: "for water that doesn't exist yet", not a bug) and `saddle_frame`
(my first pass of the scan missed `data/recipes/` entirely; it IS reachable,
through `recipes_rootstone.json`'s own recipe). **Nothing in the reward
ladder is orphaned as of this branch.**

Since nothing was left to route new activities' rewards through, I did not
force one — Broken Cart's payoff is the repair itself (the giver's own
"I won't forget it" line, no item), which is honest for a fetch-and-deliver
beat rather than inventing a reason to hand over an item nobody needed
placed.

**Two decisions recorded explicitly** (both in `items.json`'s new
`_comment_t3_activities_board_audit`, not left silently unresolved):

1. **The board's "Defense Elixir" duplicate** (appearing in both the
   PERMANENT and TEMPORARY columns of the owner's own concept art) is a
   labelling artifact, not two items. `elixir_guard` (permanent) and
   `stoneguard_brew` (temporary) already cover both real niches either label
   could mean.
2. **Clarity Draught stays unbuilt, on purpose.** The temporary tonic row
   already has one tonic per stat `creature_instance.gd`'s buff plumbing can
   actually multiply (speed/attack/defence — no fourth hook exists). A real
   Clarity Draught needs either a genuinely new buffable axis (accuracy,
   catch-chance, status-cure) or it is just a fourth name for one of the
   first three. The former is a combat-mechanics change on the scale
   CLAUDE.md's own ask-list reserves for the owner; I did not invent one.
   Left named for whoever next owns new item/buff design.

---

## 4. Captain rebalance

Acted on T3-TYPECHART's own explicit recommendation
(`handover-T3-TYPECHART-2026-08-30.md` §4.3/§8, itself owner-authorised the
same session): **"give `captain_field` and `captain_ridge` a second type
each (the -35% discounts are the real problem, not the +56% taxes)."**

Both captains fielded a mono-type team of three (`captain_field`: Ground x3;
`captain_ridge`: Air x3), which the new type chart turns into a free -35%
exchange discount for ANY player carrying the right single type — the exact
defect T3-TYPECHART's design note flagged as the real balance problem
(worse than the tax, because it lets a prepared player trivialise a Sigil
fight on type alone).

**Fix, both captains:** swapped their weakest original member (lowest level
of the three) for a same-level, same-band-4-resident creature of a different
type. Same team size, same level ladder, same reward — a data edit, not a
new fight.

- `captain_field`: `burrowback`(13, Ground) → `duskhush`(13, Air). Team now
  reads Air/Ground/Ground.
- `captain_ridge`: `pipwing`(14, Air) → `trailpup`(14, Ground). Team now
  reads Ground/Air/Air.

Both swaps mirrored into `tests/fixtures/band_split_baseline/trainers.json`
(the frozen pre-split fixture `test_band_content.gd` diffs byte-for-byte —
the exact trap T3-REWARD's own handover names). One flavour line
(`captain_ridge_challenge`'s "Mine fly it every day") no longer held once his
team included a ground creature; changed to "Most of mine fly it every day.
The one that doesn't just digs in instead." — the two substrings
`test_each_captains_challenge_signals_its_own_kind_of_readiness` actually
pins ("breathing", "left in your five") are untouched.

**Verified with non-mirror combat-lab evidence**, per the brief's own ask
(`smoke_combat.gd`'s own director draws a mirror ground-vs-ground matchup,
a weaker check for exactly this reason). New tool
`tools/_probe_captain_typechart.gd` runs the real `type_chart.gd` against
each captain's real roster for three DIFFERENT challenger types (never the
same type on both sides), reporting the average multiplier dealt/taken and
flagging any full 3-of-3 mono-type sweep. Raw output committed at
`ralph/reports/captain-typechart-probe-t3-activities-2026-08-30.txt`. Before
this branch, `captain_field` would have shown `water challenger: dealt avg
x1.250 ... MONO-TYPE FREE SWEEP`; after it:

```
--- captain_field: air, ground, ground ---
  water  challenger: dealt avg x1.100, taken avg x0.950  [in=[0.8, 1.25, 1.25] out=[1.25, 0.8, 0.8]]
  ground challenger: dealt avg x1.083, taken avg x0.933  [in=[1.25, 1.0, 1.0] out=[0.8, 1.0, 1.0]]
  air    challenger: dealt avg x0.867, taken avg x1.167  [in=[1.0, 0.8, 0.8] out=[1.0, 1.25, 1.25]]
--- captain_ridge: ground, air, air ---
  water  challenger: dealt avg x0.950, taken avg x1.100  [in=[1.25, 0.8, 0.8] out=[0.8, 1.25, 1.25]]
  ground challenger: dealt avg x1.167, taken avg x0.867  [in=[1.0, 1.25, 1.25] out=[1.0, 0.8, 0.8]]
  air    challenger: dealt avg x0.933, taken avg x1.083  [in=[0.8, 1.0, 1.0] out=[1.25, 1.0, 1.0]]
```

No mono-type sweep on either captain, in either direction, against any of
the three challenger types.

**Consciously NOT done: the 57.6% Ground census.** T3-TYPECHART's own
priority order put the mono-type-captain fix FIRST and the census question
second, as a separate, larger question. My two swaps are symmetric
(Ground-for-Air on Field, Air-for-Ground on Ridge), so the chapter-wide
type census is **unchanged** at Ground 38 / Water 10 / Air 18 (57.6/15.2/
27.3%) — fixing that for real means touching wild spawn tables and/or other
trainers across multiple bands, which is a much larger authored-content pass
than this branch's remaining budget covered. Flagging it exactly where
T3-TYPECHART left it, not silently dropping it.

**Test evidence for this section:**

```
--only=test_trainers_data.gd,test_band_content.gd,test_dialogue_runner.gd,
       test_chapter_curve.gd,test_chapter_rewards.gd,test_type_chart.gd
# -> 171 tests, 4193 assertions, 0 failed
tests/smoke_boss.gd   # -> OK, after the roster edit (the Warden fight itself is untouched, but the world boots the new band4 content alongside it)
tests/smoke_local_requests.gd   # -> OK, re-run after the captain edit (Lost Creature fights next to both captains in Band 4)
```

---

## 5. Full test evidence

```
xvfb-run -a "$GODOT" --headless --path . --script tests/run_tests.gd -- \
  --only=test_trainers_data.gd,test_band_content.gd,test_dialogue_runner.gd,test_quest_log.gd,test_chapter_curve.gd,test_chapter_rewards.gd,test_spawns_data.gd
# -> 205 tests, 5895 assertions, 0 failed

xvfb-run -a "$GODOT" --headless --path . --script tests/run_tests.gd -- --only=test_item_cache_pickup.gd
# -> 13 tests, 16 assertions, 0 failed

xvfb-run -a "$GODOT" --headless --path . --script tests/run_tests.gd -- \
  --only=test_trainers_data.gd,test_band_content.gd,test_dialogue_runner.gd,test_chapter_curve.gd,test_chapter_rewards.gd,test_type_chart.gd
# -> 171 tests, 4193 assertions, 0 failed  (after the captain rebalance)

xvfb-run -a "$GODOT" --headless --path . --script tests/smoke_local_requests.gd
# -> local requests smoke test passed  (all five, real world, real systems)

xvfb-run -a "$GODOT" --headless --path . --script tests/smoke_boss.gd
# -> boss smoke test passed  (post-rebalance sanity: the world still boots and the chapter's own climax still resolves)
```

I did not run the full unrestricted suite (`tests/run_tests.gd` with no
`--only`) — the targeted runs above cover every file this branch touches or
could plausibly affect (trainer/dialogue/objective/quest-log/type-chart/
band-content data, plus the two new scripts' own direct tests and the one
integration smoke test), and the last full-suite baseline on this lineage
(T3-PICKUPS, same day) was 1521 tests / 0 failed. A successor picking this up
for landing should run it once to catch anything from other lanes landing in
the interim, matching every predecessor handover's own recommendation.

---

## 6. What I did not get to

- **Spec section-12 dead-Meadows cadence.** Fourth priority, explicitly
  "if time remains" — it did not. Untouched.
- **The chapter-wide Ground census (57.6%).** See §4 — deliberately deferred
  to whoever owns a wider roster-diversification pass, not silently dropped.
- **A played walkthrough at handheld/controller resolution.** Everything
  above is real-world-scene, real-system verification through
  `tests/smoke_local_requests.gd`'s input-action driving, but nobody has
  looked at any of the five new sites, Coll's parked wagon, or the captain
  fights' new matchups by eye. Same honest gap T3-PICKUPS's own handover
  named for its 17 pickups.
- **Broken Cart has no dedicated unit test beyond the smoke test.**
  `cart_repair.gd` reuses `item_gate.gd`, whose own contract is already unit-
  tested (`tests/test_item_gate.gd`, untouched by this branch); the smoke
  test is what proves the new wiring (the wagon prefab, the prompt, the two
  conversations) actually reaches it.

---

## 7. File footprint

**New:**
- `scripts/world/cart_repair.gd` (+ `.uid`)
- `tests/smoke_local_requests.gd` (+ `.uid`)
- `tests/test_item_cache_pickup.gd` (+ `.uid`)
- `tools/_probe_activities_sites.gd` (+ `.uid`)
- `tools/_probe_captain_typechart.gd` (+ `.uid`)
- `ralph/reports/captain-typechart-probe-t3-activities-2026-08-30.txt`
- `ralph/reports/handover-T3-ACTIVITIES-2026-08-30.md` (this file)

**Modified:**
- `data/config/bands/band2_stone_and_root/trainers.json` — Farro (order 2003)
- `data/config/bands/band3_the_river_lock/trainers.json` — Doss (order 3000)
- `data/config/bands/band4_upper_meadows_ironwood/trainers.json` — Rue
  (order 4002), captain_field/captain_ridge roster swaps
- `data/config/village_npcs.json` — Rae
- `data/dialogue/bands/band1_lower_meadows.json` — Rae's two conversations,
  Coll's two conversations
- `data/dialogue/bands/band2_stone_and_root.json` — Farro's two conversations
- `data/dialogue/bands/band3_the_river_lock.json` — Doss's two conversations
- `data/dialogue/bands/band4_upper_meadows_ironwood.json` — Rue's two
  conversations
- `data/dialogue/trainers.json` — one flavour line on `captain_ridge_challenge`
- `data/items/items.json` — the reward-audit decision comment
- `data/progression/objectives.json` — five new `local` entries
- `scripts/world/playground_world.gd` — `cart_repair.gd` wiring
  (`BROKEN_CART_AT`, `_build_broken_cart()`)
- `tests/fixtures/band_split_baseline/trainers.json` — mirrored the two
  captain roster edits (frozen pre-split fixture)

**Not touched:** `scripts/combat/**` (the type chart itself is untouched,
only which species meet it), `data/creatures/species.json`, terrain/grass/
scatter/material files, any band-1 South Bridge/Old Bram content beyond
adding two new sibling entries.
