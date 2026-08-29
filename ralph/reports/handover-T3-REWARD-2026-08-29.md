# Handover — T3-REWARD, 2026-08-29

Coordination tooling dropped out on the coordinator's side and lanes are being
stopped and restarted fresh. This is a full context dump, written to stand
alone for a successor who has none of this session's history.

**Branch:** `ralph/T3-REWARD`
**HEAD at handover:** `27f0e026603eee9a1af4f5063476e087f46f4a38`
**Working tree:** clean, fully pushed, in sync with `origin/ralph/T3-REWARD`.
Nothing uncommitted, nothing stashed, nothing to lose.

```
27f0e026 T3-REWARD: §12 audit — materials/TMs are clean, fix a stale audit claim
5e2e7231 Merge remote-tracking branch 'origin/main' into ralph/T3-REWARD
961a8c02 Bump pasture_drover_juno's team to 13/13: T3-BAND4's own trainer undershot the region's band   <- main, merged in
8724888f T3-REWARD: audit and pin §11 roster temptation for bands 1, 3, 5
f71e908c T3-REWARD: reward-ladder TM/equipment and Band 2 roster temptation
d6e77c79 T3-CADENCE: measure post-tournament dead-travel, no authoring yet   <- branch's original base (origin/main at start of session)
```

`ralph/LAND-0829B` (an integration branch, per the coordinator) already
carries the two T3-REWARD commits pushed earlier today (`f71e908c`,
`8724888f`) — those are doubly safe. `27f0e026` (the §12 audit commit) landed
*after* that integration point and has not been swept into an integration
branch yet as far as I know; it is pushed to `origin/ralph/T3-REWARD` and
that is the only place it currently lives.

---

## 1. What I was asked to do, and where I got to

This session ran three sequential assignments from a coordinator, each
delivered as a scheduled-trigger message mid-session (not from a human). All
three are **complete and verified**:

### Assignment 1 — §14 reward ladder + §11 roster temptation, Band 2
(`docs/owner-direction/TETHERBOUND_MEADOWS_MIDGAME_FUN_REBUILD.md` §§11, 14)

**Done and verified.** Commit `f71e908c`.

- Found that `items.json` had three genuinely orphaned item classes with
  *zero* acquisition path anywhere in the game, despite full item data:
  three elixirs (`elixir_might`/`elixir_guard`/`elixir_vigour` — permanent
  stat boosts) and five armor pieces (`hide_helm`/`hide_vest`/
  `hide_leggings`/`hide_boots`/`travel_pack`). `items.json`'s own comment on
  the elixirs says outright they "belong in the world — a dungeon, a
  captain, a stronghold" and were deliberately kept out of Mira's shop to
  stay rare. Nobody had ever placed them.
- Mapped owner-direction §14's "Captain 1/2/3" reward shape onto the
  **existing, already-established** ordinal identity of the three regional
  captains (Field = "first of the three", Ridge = "second captain",
  Riverwatch = "third captain" — this is literally in each entry's own
  `_comment` in `trainers.json`, not something I invented):
  - **captain_field** (`band4_upper_meadows_ironwood/trainers.json`) → added
    `tm_earth_fist` (the strongest Ground TM sold at Mira's, one rung below
    the apex `tm_earthshatter`). Satisfies §14's "Captain 1: Sigil + strong
    TM".
  - **captain_ridge** (same file) → added `elixir_guard` (permanent
    defence). Satisfies "Captain 2: Sigil + equipment/preparation
    improvement".
  - **captain_riverwatch** (`band3_the_river_lock/trainers.json`) → added
    `elixir_vigour` (permanent max HP). Satisfies "Captain 3: Sigil + final
    preparation unlock/reward" — Riverwatch is the last Sigil collected,
    which is what physically opens the Meadows Hall approach.
  - **Burrow Warrens guardian** (`data/config/burrow_warrens.json`, `clear.reward`)
    → added `hide_vest` (the largest armor piece). Satisfies "Warrens
    Guardian: Rootstone progression + useful TM/equipment/recipe" — chose
    equipment over another TM because every Ground TM already has an
    acquisition path and one more copy is not a new reason to clear the
    dungeon.
- Updated `data/config/chapter_rewards.json`'s audit rows for all four to
  match.
- **§11, Band 2** (`band2_stone_and_root/spawns.json`): audited and found
  Band 2 had exactly ONE mechanically-tagged roster temptation (`alpha` on
  the duskhush cluster, order 2006) — and it was night-gated, so a
  daytime-only player met zero. Promoted two already-authored, already
  well-reasoned clusters to `alpha` status (no position/count/species
  changes, just the tag): order 2011 (trailpup — its own `_why` already
  said "a chance to catch a fresh individual with better IVs/traits") and
  order 2012 (meadowhart — the region's "second chance" mount pickup).
  Neither is time/weather-gated.
- **Tests added:** `test_the_three_captains_and_the_warrens_guardian_pay_the_ladder_shape`
  in `tests/test_chapter_rewards.gd`; `test_every_band_has_an_always_reachable_alpha_or_elder`
  in `tests/test_spawns_data.gd`.
- **Fixture care:** `captain_field`/`captain_ridge`/`captain_riverwatch` and
  their `trainers.json` rows sit inside `tests/fixtures/band_split_baseline/`,
  a frozen mirror `test_band_content.gd` diffs byte-for-byte against live
  data (see §3 below — this is a trap worth knowing about). Mirrored the
  `reward.items` additions AND the new `_why_t3_reward` comment key into the
  fixture. Band 2's `spawns.json` promotions (orders 2011/2012) are OUTSIDE
  the frozen baseline range (`baseline.size()` == 13, these are order
  2000+), so no fixture mirror was needed there — verified this before
  editing, not after a red test told me.

### Assignment 2 — §11 audit, bands 1, 3, 5
Coordinator's own framing: "audit first ... if a region already clears the
bar, say so with the evidence and move on rather than padding it."

**Done and verified.** Commit `8724888f`. No new content authored — all
three bands already cleared owner-direction §11's "2-3 credible reasons to
reconsider the five" bar:

- **Band 1**: elder Mosshell (order 1900, mechanical `elder` tag) + the
  off-spine Meadowhart herd (order 1005 — its own `_why_d1` already says
  "otherwise unseen in Band 1 ... the species the tournament final's mount
  and the saddle recipe already made them want").
- **Band 3**: alpha Burrowback (order 3002, mechanical) + the Old Mill
  Crossing Brooktail (order 3004 — self-described in its own comment as
  "the region's team-building temptation in prompt 60's sense").
- **Band 5**: alpha Galecrest (order 5001, mechanical, "the largest
  aggressor cluster in the chapter") + the solitary special-encounter
  Mudsnout (order 5004 — satisfies owner-direction §15's *specific* extra
  ask, "at least one final tempting roster opportunity" before the Hall) +
  the final-stretch Trailpup (order 5003 — the closest-to-the-Hall-door
  cluster that is *itself* framed as a temptation; two purely-ambient
  clusters, orders 5015/5021, sit a few metres geographically closer but
  carry no temptation framing at all, so they don't count against this).
- **Test added:** three pin tests in `tests/test_spawns_data.gd`
  (`test_band1_clears_the_roster_temptation_floor`,
  `test_band3_clears_...`, `test_band5_clears_..._and_its_own_final_opportunity`)
  plus a small helper `_band_spawns_by_order(band)`. These assert the
  specific entries (by order + species + tag) still exist, so a later edit
  can't silently delete the thing that clears the bar without a test
  noticing.

### Assignment 3 — §12, the reward side of activity cadence
Coordinator's framing: when a player stops for a beat, does it pay into
team strength/preparation/discovery/route knowledge/story pressure? Audit
first, including content that had just landed from T3-BRIDGE, T3-BAND4,
T3-CADENCE.

**Done, mostly clean, one real fix.** Commit `27f0e026`.

- Diffed `d6e77c79..961a8c02` (my original session base vs. new `main`) to
  find exactly what those three lanes added: 3 new harvest nodes in Band 4
  (2× ironwood, 1× fiber — both pre-existing material types with existing
  sinks), 1 new decorative prop cluster in Band 1 (Team Tether evidence,
  deliberately non-interactable), and 2 new TM pickups in `TM_AT`
  (`tm_wind_blade` in Band 1, `tm_riptide_lance` at a new watchtower
  landmark in Band 4).
- **Materials**: already fully covered by the existing
  `test_no_material_the_world_yields_is_an_orphan` (generic, reads every
  band's `harvest.json` via `BAND_CONTENT.load_config`). Confirmed green
  against the new nodes. No orphan.
- **TMs**: already fully covered by
  `test_every_tm_in_the_game_can_actually_be_obtained`. Confirmed green
  against the two new pickups. No orphan.
- **"Cache/chest" beats** (§5/§13 vocabulary item): checked
  `scripts/world/props.gd` — there is no item-granting mechanism on props
  at all, anywhere in the codebase. Every "cache" in the data
  (`quarry_supply_cache`, the new `tether_waypost`) is deliberately
  decorative Team Tether evidence with explicit comments saying so ("no
  dialogue in this file, no interactable on the hardware, no note to read").
  This is not an orphan-reward bug — it's a beat that pays via story
  pressure, which owner-direction §5's own list allows.
- **Real drift found and fixed**: `main`'s Warrens fix (FIRST-HOUR-FUN-REBUILD,
  landed in this session's merge) swapped the vault's wild Terrapup for a
  named "Elder Trailpup" — because Terrapup is a starter species and can't
  be an ordinary wild (there's a real, currently-passing test for this:
  `test_starter_species_never_spawn_in_the_ordinary_wild_population`).
  `chapter_rewards.json`'s own "Burrow Warrens clear" audit row still
  described the old Terrapup in two places (`enables` and `note`). Fixed
  the prose, and added
  `test_the_audited_warrens_prize_names_the_real_vault_species` to
  `tests/test_chapter_rewards.gd` so this exact class of "audit prose vs.
  actual world data" drift can't recur silently — it reads the real vault
  species out of `burrow_warrens.json` and asserts the audit's prose names
  it and doesn't say "Terrapup".
- **Flagged, not fixed** — outside this round's file ownership:
  `playground_world.gd`'s own comment on `TM_AT` documents a known, still-open
  gap. T3-BAND4 wanted to place a *second* `tm_wind_blade` near Captain Vess
  (an Air-prep beat before the Air captain), but `TM_AT` is keyed by TM id
  (one TM = one location) and collided with T3-BRIDGE's Band-1 placement of
  the same TM. The in-code note says Band 1's placement won because Band 1
  had a more severe gap (zero TMs over 2,384m), and that "Band 4's Air
  preparation beat before Captain Vess is therefore STILL UNMET and wants a
  different Air TM". `TM_AT` and `playground_world.gd` were explicitly
  frozen for me this round ("main's TM placement is settled"), so I did not
  touch it. **This is a real, concrete, still-open finding for whoever owns
  `playground_world.gd`/`TM_AT` next**: Band 4 needs a *different* unused
  Air TM (candidates: `tm_wind_blade` is taken; check whether any Air TM is
  still sitting unplaced — I did not do that inventory, because it would
  mean touching a frozen file to plan the fix and I ran out of clear mandate
  to go further than flagging it).

---

## 2. Done-verified vs. done-unverified vs. still open

**Done and verified** (all of it — I did not leave anything mid-change):
- Every commit above was tested with the actual Godot test runner, not just
  read for correctness. See §4 for exact commands and counts.
- A **full unrestricted suite run** (`tests/run_tests.gd` with no `--only`,
  114 files) was executed once, after the reward-ladder + Band-2 work
  landed but before the bands-1/3/5 and §12 work: **1512 tests, 3,354,166
  assertions, 0 failed**. I did not re-run the full suite after the later
  two commits, only targeted subsets (`test_chapter_rewards.gd`,
  `test_spawns_data.gd`, `test_band_content.gd`, `test_trainers_data.gd`) —
  those were green every time, and none of the later changes touched
  anything outside data files + those two test files, so I have reasonable
  but not absolute confidence the full suite is still green. **A successor
  should run the full suite once** if picking this up, mostly to catch
  anything from OTHER lanes landing in the interim, not because of anything
  I'm unsure about in my own diff.
- Reward ladder items resolve as real items, TM/elixir teach data is valid,
  coin income still covers the reward-audit invariant — all specifically
  asserted, not assumed.

**Still open** (not started, not mine to start without a mandate):
- The Band-4 Air-TM gap flagged above.
- Four of the eight orphan reward items I found are STILL unplaced by
  design, deliberately: `elixir_might` (attack) and three of the five armor
  pieces (`hide_helm`, `hide_leggings`, `hide_boots`, `travel_pack`;
  `hide_vest` is the one I placed). I judged three placements (one per
  captain + the guardian) was "the smallest coherent version" the task
  asked for, not "place everything that's unplaced". If a later pass wants
  more reward density, these are pre-vetted, already-tested, zero-new-system
  candidates — the only design work left is picking WHERE.
- `docs/owner-direction/TETHERBOUND_MEADOWS_MIDGAME_FUN_REBUILD.md` §8/§9
  (captain-purpose differentiation: "Captain 1 = power/fundamentals,
  Captain 2 = team composition, Captain 3 = endurance/expedition") is
  explicitly OUT of what I touched. I mapped §14's reward SHAPE onto the
  captains' existing ordinal identity (first/second/third), not onto this
  purpose framing, and flagged in my own commit message that they don't
  cleanly line up — see §5 below, "Disagreements". `ralph/T3-STRONGHOLD` is
  the lane actually reworking captain rosters for §8 differentiation (the
  coordinator told me this explicitly and pulled `trainers.json` ownership
  away from me for that reason) — that lane is the one to reconcile this,
  not me.

---

## 3. What I learned that is not visible in the diff

- **`test_band_content.gd` is a trap for anyone editing `trainers.json` or
  `spawns.json` inside the "pre-split baseline" range.** There is a frozen
  fixture at `tests/fixtures/band_split_baseline/{trainers,spawns,harvest,props}.json`
  that the live band files are diffed against, entry-for-entry, INCLUDING
  every key (not just "identity" keys like `order`/`centre`/`count` — the
  comment in the test file undersells this; in practice it checks
  everything except keys literally prefixed `_comment*`, which get a free
  pass as "documentation, not data"). If you add a new key to a live entry
  inside the frozen range and the key is NOT prefixed `_comment`, the test
  fails with `<field> was added` until you mirror the exact same change
  into the fixture. I used `_why_t3_reward` (matching this file's own
  `_why_*` convention for placement rationale) and had to mirror it by
  hand — cost me one red test cycle to discover, then it was mechanical.
  **Lesson for next time: if you want to skip the fixture-mirroring step
  entirely, prefix your new comment key with `_comment_` instead of
  `_why_`** — that's the one prefix the test exempts automatically. I did
  NOT go back and rename mine, because by the time I noticed the pattern
  the mirrored fixture edit was already done, tested, and correct; renaming
  would have been a no-op churn.
- **The `order` field is a seed, not a label.** `encounter_director.gd`
  derives a wild spawn's scatter position, level roll, IVs, traits and
  shiny draw from `hash("wild_spawn_%d" % order)`. This is why I was
  careful to only ADD keys to existing spawn entries (the `alpha` blocks)
  rather than touch `order`, `centre`, or `count` — any of those three
  would silently reroll every creature in that cluster on next boot, with
  no error and no test catching it except the exact-fixture-match check
  above (and only for entries inside the frozen range).
- **The "band's reserved order range" convention is real and load-bearing,
  not decorative.** Band 1 = 1000-1999, Band 2 = 2000-2999, Band 3 =
  3000-3999, Band 4 = 4000-4999, Band 5 = 5000-5999 (`spawns.json`,
  `trainers.json`, etc. — see each band file's own header comment). A new
  entry MUST take an unused order in its own band's range. This is enforced
  by `test_band_content.gd::test_order_is_unique_across_every_band`.
- **The single biggest time cost this session was standing up Godot itself**,
  not the actual edits. The container starts with no Godot binary and no
  import cache. `tools/art_pipeline/setup.sh godot` fetches a pinned
  4.7-stable build to `~/.cache/tetherbound-art/godot` (not committed, not
  persistent across fresh containers). Then `godot --headless --path .
  --import` has to run ONCE before any test can load a scene/resource — it
  took **about 5-6 minutes** in this container the first time (reimporting
  every creature GLB etc.), and the FULL unrestricted test suite run took
  **about 30 minutes** wall-clock (dominated by `test_scatter_rules.gd` /
  `test_veg_corridor.gd`, matching `ralph/conventions.md`'s own documented
  warning that these are "the expensive tail"). Both `--import` and the
  full suite run WILL exceed a naive 2-minute bash timeout — run them with
  `nohup ... &` and poll the background process rather than a blocking
  call, or you will conclude (wrongly) that Godot has hung. It has not; it
  is just slow. `ralph/conventions.md`'s own warning about `--headless`
  hanging forever with `--rendering-driver opengl3` did NOT bite me because
  I never passed that flag — I only used `xvfb-run -a "$GODOT" --headless
  --path . --script tests/run_tests.gd`, which worked fine both for import
  and for the test runner.
- **`git log`/`git status` showed my local `main` was badly diverged from
  `origin/main`** at session start (277 commits ahead locally, 84 commits
  ahead on the remote, neither an ancestor of the other) — I don't know why
  the sandboxed checkout's local `main` differed from `origin/main` at
  session start, but I did NOT try to reconcile it or figure out why; I
  just branched `ralph/T3-REWARD` directly off `origin/main` (the real,
  pushed history) and ignored local `main` entirely from then on. If a
  successor's session also starts with a weird local `main`, that's
  probably just how these sandboxes get provisioned and `origin/main` is
  always the one to trust.
- **Root cause I found and did NOT need to fix, because it was already
  fixed by someone else mid-session**: the Warrens vault's wild Terrapup
  bug (a starter species spawning as an ordinary catchable wild, which
  `CLAUDE.md`'s hard rules and `test_starter_species_never_spawn_...`
  explicitly forbid) — this was real, and it was fixed by whatever lane
  shipped FIRST-HOUR-FUN-REBUILD before I ever looked at it. I only found
  the STALE DOCUMENTATION of it (`chapter_rewards.json` still describing
  the old species) after the merge. Worth recording so nobody "rediscovers"
  the Terrapup bug as if it's still open — it isn't, only the audit prose
  was behind.
- **Dead end / thing that looked broken and wasn't**: I initially worried
  `data/config/chapter_rewards.json`'s `_comment_no_new_systems` /
  `invariants` block might restrict me from adding new item types to
  reward payloads (it explicitly forbids "a second inventory, currency,
  recipe or loot system"). It does NOT restrict adding an *existing* item
  id to an *existing* reward shape (`coins`/`items`/`xp_bonus`) — that's
  exactly what the file's own audit trail already does for every other
  reward row, and `tests/test_chapter_rewards.gd::test_every_item_the_audit_names_is_real`
  only checks that a reward key/item id is real, not that it's from an
  approved shortlist. No system was invented; confirmed this before
  committing, not after.

---

## 4. Verification — exact commands and counts

Environment setup (needed once per fresh container; NOT committed, lives in
`~/.cache/tetherbound-art/`):
```
tools/art_pipeline/setup.sh godot
export GODOT="$HOME/.cache/tetherbound-art/godot"
xvfb-run -a "$GODOT" --headless --path . --import   # ~5-6 min, run via nohup+background poll
```

Targeted runs (all green, run after every commit in this session):
```
xvfb-run -a "$GODOT" --headless --path . --script tests/run_tests.gd -- \
  --only=test_chapter_rewards.gd,test_spawns_data.gd,test_band_content.gd,test_trainers_data.gd,test_item_icons.gd,test_trade.gd
# -> 110 tests, 4071 assertions, 0 failed  (first checkpoint, after f71e908c)

xvfb-run -a "$GODOT" --headless --path . --script tests/run_tests.gd -- --only=test_band_content.gd
# -> 6 tests, 935 assertions, 0 failed  (after fixing the fixture-mirror miss)

xvfb-run -a "$GODOT" --headless --path . --script tests/run_tests.gd -- --only=test_spawns_data.gd,test_band_content.gd
# -> 29 tests, 2356 assertions, 0 failed  (after 8724888f, bands 1/3/5 pin tests)

xvfb-run -a "$GODOT" --headless --path . --script tests/run_tests.gd -- --only=test_chapter_rewards.gd,test_spawns_data.gd,test_band_content.gd,test_trainers_data.gd
# -> 84 tests, 3728 assertions, 0 failed  (post-merge with main @ 961a8c02)

xvfb-run -a "$GODOT" --headless --path . --script tests/run_tests.gd -- --only=test_chapter_rewards.gd
# -> 9 tests, 136 assertions, 0 failed  (after 27f0e026, the §12 Terrapup fix)
```

Full unrestricted run (once, after `f71e908c` + `8724888f`, before the merge):
```
xvfb-run -a "$GODOT" --headless --path . --script tests/run_tests.gd
# -> 1512 tests, 3,354,166 assertions, 0 failed
# (trailing PagedAllocator/ObjectDB leak warnings at process exit are normal
#  Godot shutdown noise, not test failures -- ignore them)
```

I did not re-run this full unrestricted pass after the merge or after
`27f0e026`; see "still open" above.

---

## 5. Disagreements / things I believe are wrong or worth a second look

1. **§8/§9's "Captain 1/2/3" purpose framing (power/fundamentals, team
   composition, endurance) does not cleanly map onto the three captains'
   OWN established design.** Reading `band3_the_river_lock/trainers.json`,
   `captain_riverwatch`'s own comment says: "Water-led but deliberately
   BALANCED ... so a party built to answer the first two cannot walk this
   one on type alone." That is a textbook description of a TEAM
   COMPOSITION test — but Riverwatch is the THIRD captain by every existing
   in-code label ("the third captain", matching the spec's own list order
   Field/Ridge/Riverwatch), and geographically it's actually the FIRST one
   a player reaches walking the road (59% of the way through the corridor,
   vs. Field at 76% and Ridge at 88% — this is measured and recorded in
   `captain_field`'s own `_comment_ow6`). So depending on which axis you
   read "Captain 1/2/3" against — design-list order, in-game encounter
   order, or purpose-fit — you get three DIFFERENT answers for which
   captain is "Captain 2, team composition". I did not attempt to resolve
   this; I mapped §14's reward SHAPE onto the design-list ordinal identity
   (Field=1st/Ridge=2nd/Riverwatch=3rd) because that's the reading with
   zero new invention, and flagged the ambiguity in my own commit message
   rather than silently picking one. **`ralph/T3-STRONGHOLD` (reworking
   captain rosters for §8 right now, per the coordinator) needs to resolve
   this properly** — if they re-theme which captain tests what, my reward
   placements (TM on Field, defence-elixir on Ridge, HP-elixir on
   Riverwatch) may need to move with them to stay narratively coherent, and
   they should re-read my `_why_t3_reward` comments before assuming the
   reward assignment is load-bearing/fixed.
2. **`chapter_rewards.json`'s audit is a real, valuable pattern, but it has
   already drifted from reality at least twice now** (the historical
   "three unobtainable apex TMs" bug its own header brags about catching,
   and the Terrapup/Elder-Trailpup drift I found and fixed this session).
   Both times the drift was PROSE describing something that used to be
   true. There is no generic mechanism that keeps prose honest against
   data — every fix so far has been a human/agent noticing by hand. If this
   file is going to keep being the chapter's reward-economy source of
   truth, it might be worth a policy of "any lane that changes a species,
   an item, or a reward number that an existing `chapter_rewards.json` row
   describes must grep that row and update it in the same commit" — I
   didn't have the mandate to propose or enforce that policy change this
   session, just noting the pattern.
3. **`TM_AT`'s Air-TM gap for Band 4 (see §1, Assignment 3) is a real,
   already-diagnosed, still-open content gap**, not a disagreement exactly,
   but it's the single most "shovel-ready" finding I'm leaving behind:
   someone already root-caused it (the in-code comment is thorough), the
   fix just hasn't been made because of a merge collision and a freeze that
   landed at the same time. Whoever next owns `playground_world.gd`/`TM_AT`
   should read that comment block directly (search `TM_AT` in
   `scripts/world/playground_world.gd`) before doing anything else with Band
   4's TM economy.

---

## 6. File footprint

**Files I changed** (all pushed, all in the commits listed at the top):

- `data/config/bands/band2_stone_and_root/spawns.json` — added `alpha` to
  orders 2011, 2012.
- `data/config/bands/band3_the_river_lock/trainers.json` — added
  `elixir_vigour` to `captain_riverwatch`'s reward + `_why_t3_reward`
  comment. **NOTE: `trainers.json` in every band was pulled from my
  ownership by the coordinator after this landed — do not add more to this
  file from this lane; it belongs to `ralph/T3-STRONGHOLD` now.**
- `data/config/bands/band4_upper_meadows_ironwood/trainers.json` — added
  `tm_earth_fist` to `captain_field`'s reward, `elixir_guard` to
  `captain_ridge`'s reward, both with `_why_t3_reward` comments. **Same
  ownership note as above — also, all of `band4_*` was pulled from me for
  `ralph/T3-RELAY`'s seam-gap work.**
- `data/config/burrow_warrens.json` — added `hide_vest` to
  `clear.reward.items` + `_why_t3_reward` comment. **Pulled from my
  ownership after this landed (`ralph/LAND-0829A` was mid-landing a
  separate Warrens fix in this exact file) — do not touch further from this
  lane.**
- `data/config/chapter_rewards.json` — updated audit rows for
  `captain_field`, `captain_ridge`, `captain_riverwatch`, "Burrow Warrens
  clear" (twice — once for the new reward items, once to fix the stale
  Terrapup reference). Not explicitly claimed by any other lane as far as I
  know; probably safe, but it's the chapter-wide audit file so check for
  fresh edits before touching it.
- `tests/fixtures/band_split_baseline/trainers.json` — mirrored the
  `reward.items` + `_why_t3_reward` additions for `captain_field`,
  `captain_ridge`, `captain_riverwatch` (required by
  `test_band_content.gd`'s exact-match check; see §3).
- `tests/test_chapter_rewards.gd` — added
  `test_the_three_captains_and_the_warrens_guardian_pay_the_ladder_shape`,
  `_reward_has_item` helper, and
  `test_the_audited_warrens_prize_names_the_real_vault_species`.
- `tests/test_spawns_data.gd` — added `_band_spawns_by_order` helper,
  `test_every_band_has_an_always_reachable_alpha_or_elder`,
  `test_band1_clears_the_roster_temptation_floor`,
  `test_band3_clears_the_roster_temptation_floor`,
  `test_band5_clears_the_roster_temptation_floor_and_its_own_final_opportunity`.

**Files I read carefully but did NOT change** (worth knowing, so a
successor doesn't re-derive the same reading): `docs/owner-direction/README.md`,
`docs/owner-direction/TETHERBOUND_MEADOWS_MIDGAME_FUN_REBUILD.md` (full,
§§0-21), `docs/MEADOWS_PROGRESSION_SPEC.md` (§§3-6, the captain/evolution/
five-creature-limit sections), `data/items/items.json` (full — this is where
I found the elixir/armor orphans), `data/config/trade.json` (full),
`data/config/catching.json`, `scripts/combat/encounter_director.gd` (the
alpha/elder/shiny mechanism), `scripts/data/band_content.gd` (the merge
mechanism), `tests/test_band_content.gd` (full), `tests/test_spawns_data.gd`
(full, before and after my edits), `tests/test_chapter_rewards.gd` (full).

**Files I was ABOUT to look at but did not get to**: none — I did not have
anything half-open when the stand-down arrived. My working tree was already
clean before this message (the §12 audit commit was already pushed as the
final action of my prior turn).

**Explicitly not-mine this round, per the coordinator**: `trainers.json` in
every band (`ralph/T3-STRONGHOLD`); `band4_*` harvest.json and spawns.json
(`ralph/T3-RELAY`); `playground_world.gd` and the `TM_AT` constant (frozen,
"main's TM placement is settled").
