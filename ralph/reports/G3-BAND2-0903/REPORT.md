# G3-BAND2 — Stone & Root (Old Quarry / Burrow Warrens)

Branch `ralph/G3-BAND2-0903`, off `main` at the time of this session. No pull
request opened — the Gate 3 coordinator (session_01Rra117rfv84LPqbL5ACBn4)
lands this branch.

## Headline finding

**No code or data changes were made.** Every priority in prompt 63's
contract, checked against the actual shipped config and actual test/smoke
runs on this branch (not against comments alone), is already satisfied by
prior lanes — principally `BAND2-63`, `BAND2-63-WARRENS`, `CONTENT-0828`,
`T3-REWARD`, `FIRST-HOUR-FUN-REBUILD`, `MQ2B`, `SH47`, `TRAINER-JOURNEY`,
`EXT-04` through `EXT-10`, `T1-CREATURE`/`T1-CAST`/`T1-LIGHT`. This is an
"evidence-backed already-satisfied" outcome per the lane brief, not a
default-to-inaction call: I read every owned file end to end, cross-checked
the claims each one's own `_why`/`_comment` blocks make against the game's
other systems (dialogue, recipes, progression, tests), and then ran the real
tests rather than trusting the comments.

## What I verified, and how

### 1. Rootstone has an understood purpose (prompt 63's central question)

Traced the real player path, not just the quarry file:

- **Before Band 2**, `data/dialogue/bands/band1_lower_meadows.json` already
  tells the player what rootstone is for, twice, in NPC dialogue: "A
  Meadowhart will carry you once you've built one. Rootstone for the frame,
  and the only rootstone left is past the south crossing," and "Once you've
  got rootstone worked out and a saddle frame built, one of these would
  carry you the same way." `data/dialogue/village.json`'s Quarry Foreman
  also names Team Tether working "the old rootstone seams" before the
  player ever leaves the village.
- **The tournament prize** (`data/recipes/recipes_rootstone.json`'s
  `saddle` entry, `unlocked_by: recipe_saddle`) hands the player the saddle
  *recipe* before they have the material — explicitly authored, per that
  file's own comment, so "the reward is a promise, not a purchase" and
  rootstone is something the player already wants before reaching the
  quarry.
- **At the quarry**, Dorn (the first Team Tether trainer) stands "between
  the player and the rootstone seams... The saddle and the Greater Orb are
  both priced in rootstone... so this fight has a purpose the player
  already understands before a word is spoken" (`trainers.json`
  `quarry_picket_dorn._why_here`).
- **The item itself** (`data/items/items.json` `rootstone.description`)
  states plainly: "everything made with it comes out stronger than the
  same thing made of ordinary rock."
- **The recipes** (`data/recipes/recipes_rootstone.json`) are real and
  un-gated (no second flag on top of the material itself, deliberately):
  `orb_greater`, `reinforce_axe`, `reinforce_pickaxe`, `saddle_frame`,
  `saddle`. `tests/test_recipes.gd` (47/47 green on this branch) confirms
  all five are defined, costed only in real items, and affordable in one
  pass over the chapter's own rootstone economy
  (`test_one_pass_over_the_chapter_can_afford_its_own_rootstone_recipes`).
- **The Warrens' own deposits and clear reward** give more rootstone (4
  deposits inside the dungeon, 5 more on clearing) so a player who commits
  to the dungeon is rewarded in the same currency the quarry taught them to
  want.
- **The evolution lead** (Mudsnout → Tuskroot) is carried by a second,
  separate material — the Heartstone — sourced in the Warrens' optional
  vault, with a pickup line rewritten specifically (by `BAND2-63-WARRENS`)
  to say what the stone is for at the moment the player is looking at it:
  "the kind of stone a creature is held against to finish becoming what it
  was already turning into." `progression.json`'s
  `evolution.mudsnout.item_id` is wired to `heartstone`, confirmed live by
  `smoke_warrens.gd`.

This is not a "gather a material nothing consumes" loop. Rootstone is
consumed by five real recipes the player is told about before they ever
swing a pickaxe, and the Warrens' own deposits/reward keep paying it.
**No defect found; nothing changed.**

### 2. Wild ecology outside the dungeon

`data/config/bands/band2_stone_and_root/spawns.json` (57 entries per
`WORLD_AND_CONTENT.md` §7, confirmed by file inspection) is a Ground-heavy
roster (burrowback/mudsnout/trailpup, plus meadowhart and night-gated
duskhush) — explicitly a deliberate design choice per the file's own
`_comment_species_variety`, not an authoring shortfall: prompt 63 asks for
"ground-oriented stronger populations," not a wider catalogue that would
blur the region's identity. Real roster temptations exist:

- an alpha Trailpup (order 2011, `level_bonus:3`) and alpha Meadowhart
  (order 2012) on the loops past the ranger camp and the Warrens' second
  mouth — both explicitly authored as "the credible reason to reconsider a
  slot";
- a night-gated alpha Duskhush (order 2006);
- the one Nightburrow in the entire Meadows (order 2100, `alpha
  level_bonus:5`), the chapter's rare/special find, sited on this band's
  western rock per the brief's own siting rule.

`tests/test_chapter_curve.gd::test_the_meadows_offers_more_creatures_than_the_party_can_hold`
and `test_a_catch_is_a_real_option_in_every_region` both pass (18/18 total
in that file) — the cap keeps biting in this band, verified, not asserted.
**No defect found; nothing changed.**

### 3. Trainers

`chapter_curve.json`'s own `tuning` comment for this band still reads "the
band has no trainers of its own, which is prompt 59's gap, not this file's"
— **this is stale**. `data/config/bands/band2_stone_and_root/trainers.json`
now has 4 trainers: `quarry_picket_dorn` (level 9, at the quarry
threshold), `warrens_watch_pell` (levels 10-11, at the Warrens mouth,
introduces the Air matchup one fight before the Ground-heavy dungeon),
`band2_outrider_kest` (level 12, past the Warrens, escalating), and
`night_watch_farro` (levels 12-13, an optional night-gated activity that
introduces Duskhush). The file's own header comment
(`_comment_why_this_band_had_none`) documents this exact reconciliation:
prompt 59's gap was real, and a `TRAINER-JOURNEY`/`BAND2-63` lane closed it.
`tests/test_chapter_curve.gd::test_every_trainer_fights_at_their_own_regions_strength`
and `tests/test_chapter_content_map.gd::test_every_region_has_human_opposition_in_it`
both pass. **`chapter_curve.json` is not in this lane's file ownership** (it
covers all five bands), so I did not edit it — flagging here for the
coordinator or whoever owns that file to update the sentence. I attempted
to message the coordinator session directly and it was not reachable from
this session; this report is the record.

### 4. Camp/rest staging

The `ranger_camp` cluster (`props.json` order 2001, on the
`ranger_camp_spur` loop, off the critical path) has a real `rest`/`craft_at`
block — a `creature_bed`, a craft anvil, a campfire, and seating —
explicitly fixed by an earlier `T5-CADENCE` lane after an audit scored this
band's camp row FAIL for having props but no interaction path. It is the
band's one authored field camp, sited away from both the quarry and the
Warrens (not inside either danger zone), with its own adjacent wood/fiber
harvest nodes so a player does not have to leave to feed a build. A second
prop cache (`stoneguard_brew`, a defence tonic) sits just outside the
Warrens mouth specifically for "where a player braces before the Guardian."
**No defect found; nothing changed.**

### 5. Navigation

`map_landmarks.json` names both `the_old_quarry` and `the_burrow_warrens`
as discoverable regions, with a documented fix history for a stale pin
(`GATE-F-LEG-S06` moved the Warrens region centre to match the dungeon's
actual relocated site after a real playtest walked the old pin into
unvetted terrain and got stuck — the kind of defect this lane would
otherwise have had to find itself). The corridor's own spine (South Bridge
→ quarry → Warrens → river handoff) is the critical path; `quarry_rim_overlook`,
`ranger_camp_spur`, and `warren_undertrail` are named optional loops
carrying the alpha temptations, the camp, and the supply-cache Team Tether
evidence. **No defect found; nothing changed.**

### 6. Mudsnout → Tuskroot evolution lead

Covered under §1 above (Heartstone). `smoke_warrens.gd` on this branch
confirms live: taking the Heartstone puts one in the satchel, sets its
one-time flag, and `progression.json`'s `evolution.mudsnout.item_id`
resolves to `heartstone` — the gate `R4.6` built and shipped switched off
now has a real source, sourced from this band's optional branch as prompt
63 asks. **No defect found; nothing changed.**

## Evidence run (per prompt 63's own template)

Reconstructed from the config and the live `smoke_warrens.gd` run rather
than a manual playthrough (no display driver in this container; see
Environment note below):

- **Rootstone had an understood purpose**: yes — told in Band 1 dialogue
  before the crossing, reinforced by the tournament's saddle-recipe prize,
  reinforced again by Dorn's own positioning, spent by 5 real recipes.
- **Dungeon duration/readability**: `smoke_warrens.gd`'s own walked route
  (entrance → mouth → hall → den → vault, with the branch door tested shut
  then open) measures **52m** walked end to end in the test's own drive
  (the file's header cites 123m/26s for the full authored route on an
  earlier measurement pass); five chambers, one gated optional branch —
  compact, not a maze.
- **Guardian identity/difficulty**: Warren Guardian, a Burrowback alpha at
  level 14 (species floor 1.70m, guardian reads at **2.29m** live), signature
  move `earth_fist` (not the species' ordinary `tremor_roll`), its own aura
  light and alpha glow. Confirmed level 14 > every resident's level (levels
  9-11) and > the field's own ceiling (8), per
  `test_the_warrens_fights_above_its_field_but_inside_its_region`.
- **Optional temptation**: the Elder Trailpup (level 13) in the vault,
  behind the guardian, reachable only after the guardian falls — "worth
  seeing even if not caught" per prompt 63, and genuinely optional (the
  clear flag/reward pay before the vault is ever reached).
- **Camp/rest use**: the `ranger_camp` cluster, on the spur, with a real
  rest/craft interaction.
- **Dead travel**: none found — `spawns.json`'s density comments
  (`_why_zone` blocks) document a deliberate cluster-every-30-80m pacing
  the length of the band, and `harvest.json` fills the two longest
  previously-bare stretches (the quarry-to-camp ridge, the post-Warrens
  oak forest) with gatherables.
- **Reward usefulness**: clear reward is 90 coin, 5 rootstone, 2 Greater
  Orbs, 1 revive, 1 hide_vest (the largest armour piece in the game,
  previously unobtainable anywhere) — confirmed paid exactly once by
  `smoke_warrens.gd`'s own `_the_story_reward_pays_once` and
  `_a_cleared_guardian_does_not_come_back` checks, both green on this
  branch.

## Tests actually run on this branch (all first-attempt green)

```
~/.cache/tetherbound-art/godot --headless --path . --script tests/run_tests.gd -- --only=test_chapter_curve.gd
  18 tests, 451 assertions, 0 failed

~/.cache/tetherbound-art/godot --headless --path . --script tests/run_tests.gd -- --only=test_band_content.gd
  6 tests, 1145 assertions, 0 failed

~/.cache/tetherbound-art/godot --headless --path . --script tests/run_tests.gd -- --only=test_dialogue_runner.gd
  66 tests, 1007 assertions, 0 failed

~/.cache/tetherbound-art/godot --headless --path . --script tests/run_tests.gd -- --only=test_recipes.gd
  47 tests, 342 assertions, 0 failed

~/.cache/tetherbound-art/godot --headless --path . --script tests/run_tests.gd -- --only=test_chapter_content_map.gd
  4 tests, 37 assertions, 0 failed

~/.cache/tetherbound-art/godot --headless --path . --script tests/smoke_warrens.gd
  warrens smoke test passed
  (full world boot: 385,333 props scattered, 21 field trainers placed,
   guardian placed level 14 / 2.29m tall / earth_fist confirmed, cave
   walked end to end, branch door tested shut-then-open, Heartstone
   pickup confirmed, evolution gate confirmed wired to heartstone, clear
   reward confirmed paid exactly once, guardian confirmed does not
   respawn on a second build)
```

I did not run the full ~28-minute unit suite or the Gate F S04-S10 harness
— out of scope for a lane whose own investigation found no code change to
verify, and the coordinator's own brief only asks for the named tests. If
the coordinator wants the full suite run against this branch before
landing, it has not been run here.

One non-fatal engine warning surfaced during `smoke_warrens.gd`, worth
naming rather than silently absorbing: `ERROR: Parameter "material" is
null.` from `material_get_instance_shader_parameters` inside
`creature_body.gd::_build_model` → `apply_size_multiplier`, triggered while
dressing the guardian (`burrow_warrens.gd::_dress_the_guardian`). The test
still passed and the guardian's live scale/height assertions after this
line succeeded, so this reads as a headless/dummy-renderer artifact (no
real GPU driver in this container) rather than a real defect — but I did
not chase it further, since `creature_body.gd` is outside this lane's file
ownership and the assertion suite built specifically to catch a broken
guardian did not catch anything broken here. Flagging for whoever next
touches guardian presentation to watch for on a real renderer.

## Findings not fixed, and why

1. **`chapter_curve.json`'s stale "no trainers" comment** (see §3 above).
   Not in this lane's file ownership; not edited. I tried to reach the
   coordinator session directly (`SendMessage` to
   `session_01Rra117rfv84LPqbL5ACBn4`) and it was not reachable from this
   session at the time — this report is the fallback record.
2. **The headless material-null warning** during guardian dressing (see
   above). Not chased — outside file ownership, did not fail anything,
   plausibly a container/driver artifact.

## Vegetation changes proposed but NOT applied

None. I read (but did not edit) `data/config/bands/band2_stone_and_root/vegetation.json`
and confirmed both of its Band-2-relevant clearings are already authored
and already match what `burrow_warrens.json` expects: the Warrens-mouth
clearing (order 2002, centre matching `burrow_warrens.json`'s `site.at`
exactly, radius 30 matching `site.clear_radius_m`) and the ranger-camp
clearing (radius 15). Both are already flagged in-file as waiting on "the
coordinator's single re-bake" (a pre-existing, already-documented
dependency from `BAND2-63-WARRENS`/`GATE_D_LANE_CONTRACT.md` §4, not
something this lane found or is newly proposing) — until that bake runs,
a stale scatter bake may still show a tree standing in the Warrens'
doorway. This is a bake-freshness issue, not a data-authoring gap, and
outside a Band 2 content lane's remit to fix (the brief explicitly
forbids running the bake).

## Prompt 63 acceptance bullets

- region feels mechanically different through exploration/material/dungeon
  play — **met** (Rootstone tier, ground-heavy dungeon, distinct trainer
  ladder).
- Rootstone creates real capability — **met** (§1 above).
- wild ecology remains present outside the dungeon — **met** (§2 above).
- Warrens guardian is memorable, not standard fight + HP — **met**: unique
  name, alpha presentation (scale/glow/aura light), a signature move no
  ordinary Burrowback has, foreshadowed by Pell's own dialogue before the
  player ever reaches the door.
- optional exploration has worthwhile payoff — **met** (Elder Trailpup,
  Nightburrow, alpha Trailpup/Meadowhart, quarry-rim/ranger-camp/undertrail
  loops).
- Team Tether evidence advances curiosity — **met**: the quarry's lit
  pylon run (evidence, no explanation, by design), the supply cache on the
  ranger-camp spur, and dressing inside the Warrens itself (abandoned dig,
  never explained) — all three sites, not just one.
- player exits stronger and understands why — **met**: clear reward,
  Heartstone lead, saddle progression all legible by the time the player
  leaves for the river.

All seven read as met against the current shipped state, verified by the
tests above rather than taken on the prior lanes' own word.
