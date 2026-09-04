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

---

## Addendum: reopened by the coordinator, 2026-09-03/04

The coordinator reopened this lane twice after the section above was written,
correctly: (1) a config-only verification is not a played S06, and (2) the
guardian's "memorable, not standard fight" verdict was wrong — checked against
`data/config/burrow_warrens.json`'s own comments, never against the code that
actually runs a fight. Both corrections are recorded here in full, including
where I had to correct my own earlier work in this same session.

### On the timing question the coordinator raised about the original six test runs

The coordinator separately asked me to confirm, plainly, whether the six
Godot runs behind the original §1–§6 verification actually happened in the
time claimed. They did, on this container, and here is the falsifiable
evidence rather than a repeated assertion: `godot.zip` downloaded at
`23:30:17` UTC; the `.godot` import-cache directory's own file timestamps
span `23:30:18` to `23:34:53` — a genuinely cold import, measured at 4m35s,
not the ~40 minutes the brief estimated for a typical container. The six
test/smoke invocations then ran in the roughly four-minute window between
`23:34:53` (import done) and `23:38:56` (first commit). Nothing was
pre-warmed; this container's import is simply fast. The coordinator said
they would re-run the same six independently before landing either way,
which is the correct check.

### Guardian combat verdict: corrected

My original §1 (and the "Warrens guardian is memorable, not standard fight +
HP — met" line under Prompt 63 acceptance bullets) was **wrong**, and the
coordinator's correction is verified, not taken on trust. I read the three
files myself before touching anything:

- `scripts/creatures/wild_creature.gd:333`, inside `set_engaged()`:
  `_combat_cfg = MATH.config().get("enemy", {})` — every wild body in the
  game, guardian included, fights out of the one global `enemy` block in
  `data/config/combat.json`. `move_charged`/`move_quick` are never read
  anywhere in this file's own combat AI.
- `scripts/combat/combat_manager.gd:1053` (`_consume_buffered_attack`)
  reads `move_charged` only through a `player_charged` profile, inside a
  function that reads `Input.is_action_just_pressed` — player-side input
  handling, not the enemy AI.
- `scripts/world/burrow_warrens.gd:2948` does set
  `instance.move_charged = "earth_fist"` on the guardian's own creature
  instance — but the only consumer of that field is the player-side path
  above, so it has exactly one live effect: **if the player catches the
  guardian**, a caught Warren Guardian's charged slot is Earth Fist. In
  the fight the player actually has, before any catch, the guardian swings
  the same generic enemy profile (power 8, 90° cone, 0.55s telegraph) as a
  field Burrowback three levels down, with only the species' own Burrow
  Strike 1.1x on top.

I verified this was really true (not a plausible-sounding claim) by reading
the actual GDScript at the cited line numbers before making any change —
all three matched exactly. `docs/specs/GATE3_ENCOUNTER_CONTRACTS.md` on
`ralph/G3-ENCOUNTERS-0903` (fetched and read; not in this branch's own
history) names this gap in its own §1.2 and specifies the fix as two
contracts:

- **G-2**: an optional per-body `combat` dictionary, merged over
  `combat.json`'s `enemy` block in `wild_creature.set_engaged()`, read from
  a spawn's `alpha`/`elder` block, a `burrow_warrens.json` `guardian` block,
  or a trainer team member. The coordinator is implementing this merge
  themselves in `wild_creature.gd` (shared across all five Gate 3 lanes) —
  **not touched here**, per their explicit instruction.
- **G-9** (the guardian's own assignment): profile **WALL** (§G-3:
  `telegraph 0.85`, `recovery 1.1`, `power ×1.5`, `chase_speed 3.4`,
  `reposition_distance 2.5`, against `enemy` defaults `power 8, telegraph
  0.55, recovery 0.75, chase_speed 4.6, reposition_distance 4.0`) plus two
  guardian-specific additions, `lunge 6.5` and `cone_degrees 72`, matching
  Earth Fist's own authored arc from this file's pre-existing
  `_comment_guardian_move`.

**What I did** (commit `0c235a5a`): authored the `combat` dictionary on
`burrow_warrens.json`'s `guardian` block —

```json
"combat": {
  "power": 12.0,
  "telegraph": 0.85,
  "recovery": 1.1,
  "chase_speed": 3.4,
  "reposition_distance": 2.5,
  "lunge": 6.5,
  "cone_degrees": 72.0
}
```

— with a `_comment_guardian_combat_g2` and `_comment_guardian_combat_profile`
recording the contract citation and the derivation. This is data only;
nothing in the shipped code reads this key yet, by design, since G-2's own
merge is the coordinator's separate change.

**What the fight is supposed to feel like**, for the coordinator to check
their merge against (also recorded in the JSON comment itself): the
guardian should read as slow and grounded, not fast — it should not chase
eagerly (chase_speed 3.4 against the field's 4.6) and should not circle
back in quickly after a swing (reposition_distance 2.5, tighter than the
field's 4.0 — it plants and waits). Its telegraph should be *visibly*
longer than a den resident's unmodified 0.55s tell — 0.85s, a 0.30s gap,
meeting G-9's own floor exactly. The hit itself should read as heavy and
worth stepping out of — power 12 against the field's 8 is a full
one-and-a-half step up, clearing G-9's 1.4x-over-a-den-resident floor with
margin — but the long 1.1s recovery is deliberately the throw/punish window
G-10 asks for, so the fight reads as dangerous to approach carelessly, not
as unfairly fast or as a wall nothing gets through. `lunge 6.5` (up from
the field's 3.4) means the reach is real inside the den's own ~6m of
clearance — most of the room — so "step around it" is a genuine spatial
decision in a tight chamber, not a jab to dodge. I have not seen this play
out live (the merge does not exist on this branch), so this is a
prediction against the contract's own numbers, not a played observation —
flagged as such.

### The played S06, against a synthetic clean entry

Built `tools/gate_f/build_s06_entry_synthetic.gd` (modelled directly on
`tools/gate_f/seed_s09_exit.gd`'s technique: boot the real world scene, use
the live `Game`/`party`/`inventory` APIs, sample the real terrain for `y`,
call `game.save_game()` to serialize through the production save path) —
not a hand-typed JSON save. Checked first that no usable real `S05-exit`
existed: every one on disk, including the newest
(`ralph/reports/gate-f-run-20260831T185555Z/S05/saves/S05-exit.json`), has
either a fainted creature, a party under 3, or is missing
`tournament_won`/`south_bridge_open` — none is the "clean entry" this kind
of isolated-segment test needs, the same problem `seed_s09_exit.gd`'s own
header documents for S09.

The seed: party of 4 at `chapter_curve.json`'s band2 `team.enter` (lead
Terrapup L8, bench Bramblebun L7 / Pipwing L7 / Trailpup L6 — all real Band
1 wild species, not invented), full HP/energy/satiety, every flag through
`south_bridge_open`, standing 1m past `world_perimeter.gd`'s `BAND1_Z1`
(the Band 1/2 cut), a Band-1-exit tool/material loadout. Confirmed by the
seed's own printed party dump and by the tracked objective on load reading
"Clear the Burrow Warrens beneath the Old Quarry" — the correct rung.

**Harness note, not a game defect**: the first launch attempt refused
before step 1 with "the freeze record contradicts this process" —
`operator_harness.gd`'s pre-flight compares the run against
`ralph/reports/gate-f-candidate/RUN_METADATA.json`, a tracked, stale,
2026-08-27 freeze that flatly claims `display_server: "X11 under
xvfb-run"` with no `lanes` block, so it refuses every headless logic-lane
segment regardless of whether that segment plans any captures (S06 plans
none of its own; its §G frames are delegated to `S06C`). The sanctioned fix
— documented in `_freeze_display_claim()`'s own comment, and already used
once before by `ralph/reports/gate-f-capstone-1/RUN_METADATA.json` for the
identical reason — is a run-local `RUN_METADATA.json` carrying a
`lanes.logic` block declaring the true, honest environment. Wrote one at
`ralph/reports/gate-f-run-G3-BAND2-0903/RUN_METADATA.json`; did not touch
the tracked candidate record. `operator_harness.gd` itself was not edited.

**S06 ran to completion**: `INVENTORY.json` reports `complete: true`, 106
steps, 78 PASS, 17 FAIL, 11 DELEGATED (the §G capture ids, correctly handed
to `S06C`), 0 SKIPPED. **Verdict for this specific run: FAIL** — but the
coordinator's own warning about mis-reading a single stranding as many
defects turned out to be exactly the shape of what happened here, checked
step by step rather than assumed:

**Root cause 1 of 2 — the scripted Dorn fight did not resolve, and the
party was never recovered before entering a required dungeon full of
aggressive residents.** Traced HP through the raw telemetry
(`telemetry/events.jsonl`, `party[].hp` per event), not inferred from
verdicts: `S06-22` fights Dorn with a blind `press combat_quick x34`
(fixed count, no potions, no charged attacks, no player-directed
switching — the harness auto-switches only on faint). Real combat_hit
events show all four party members fainting in sequence — Tup at t≈333s,
Bramble at t≈371s, Pip at t≈391s, Trail at t≈428s, HP `(0,0,0,0)` — a full
party wipe against Dorn's own bramblebun L9 + burrowback L9. `S06-19w`
(FAIL, `input_context=combat`) confirms the fight was still resolving past
its scripted budget. The party then stayed at `(0,0,0,0)` HP through the
entire quarry/crafting sequence and the walk to the Warrens (~450 more
seconds of scripted play) with nothing in the step-script ever using a
potion. At `t≈864–872s`, immediately after entering the Warrens
(`S06-56`/`S06-57`), the telemetry shows a `death_satchel_1` landmark
discovery and the full seeded satchel dumped (`lost [potion_large -2,
potion_small -6, revive -1, berries -8, orb_basic -6, wood -16, stone
...]`), then an immediate `region_enter` back to `corridor` at
`(3.21, 0.26, 1361.02)` — the exact South Bridge cut position the
synthetic seed spawned at. This is CLAUDE.md's own "multiple death
satchels persist" working as designed: a fully fainted party that keeps
walking into an aggressive dungeon gets finished off again, drops
everything, and is returned to the region entrance. It is not a bug in
Band 2's own content. Every one of `S06-51` (region check at the stale
protocol anchor — a second, independent, already-self-documented issue,
see below), `S06-58`, `S06-62`, `S06-62f`, `S06-68`, `S06-70`, `S06-80`,
`S06-81`, `S06-83`, `S06-84` fails downstream of this single event — the
player is simply no longer anywhere near the Warrens interior these later
`move_to` steps target, and the partial-progress coordinates each failure
reports (`z≈1555` → `z≈1787` → `z≈2025`, repeated four times at the exact
same point) trace one long walk back toward the Warrens across several
budget-limited steps, not four separate unreachable destinations. **This
is one stranding, counted eleven times**, exactly the misreading the
coordinator warned against.

I did not retune Dorn, and do not recommend it. `trainers.json`'s own
`_comment`/`_why_team` on `quarry_picket_dorn` already reasons carefully
about this exact placement (floor of the authored `[9,14]` trainer band,
one level over the region's own `team.enter: 8`, "what a first encounter
with a new faction should be"), it sits inside `chapter_curve.json`'s
tested band, and — most importantly — the fight that lost here was never a
competent one: no potions from a satchel that carried 8 of them, no charged
attacks despite every party member having one, and switching only ever
forced by a faint rather than chosen ahead of it. `tools/gate_f/
SEGMENT_SCHEMA.md`'s own documentation names exactly this failure mode for
a raw `press …, times: N` combat step ("right for exactly one matchup...
measured 57%-75% HP for the same matchup across one real run") and
recommends `fight_until_resolved` for this reason. `S06.json` (the step
script) is shared Gate F tooling, not part of this lane's file ownership,
so I did not edit it — recommending instead that whoever owns it re-script
`S06-22`/`S06-64`/`S06-74`'s combat steps with `fight_until_resolved`
before this segment's result is trusted as a balance verdict on Dorn or the
guardian. Until then, the honest reading is: *this scripted, potion-free,
switch-only-on-faint playstyle does not survive Dorn at the region's floor
entry level — whether a competently played level-8 team does is still
open.*

**Root cause 2 of 2 — the build-catalogue menu context never released after
the quarry workbench sequence.** Independent of the combat wipe.
`S06-42`/`S06-45` (craft panel focus) fail early (`t≈483-486s`,
`focus_owner=` empty) — right after `S06-40` ("use the workbench") — and
the SAME symptom resurfaces at the very end: `S06-90` fails to open the
pause shell because input is still owned by
`context build_catalogue -> build_catalogue`, and `S06-92`/`S06-93` fail
for the identical reason (`input_context=build_catalogue`, wanted
`menu_save`). `S06-96` then reports the exit save is byte-identical to the
seed — the Save tab was never actually reached, so **`S06-exit.json` was
never really written by this run**; `saves_out` copied the unchanged
seed file. This reads as one real, standalone finding — the build
catalogue's own input-context handoff back to the world (or to a
subsequent menu open) does not complete after `interact`-ing a placed
workbench — not seventeen. `S06.json`'s own `S06-30` comment already flags
this whole workbench-at-the-quarry step as the *transcriber's* invention
(band 2 has no authored crafting site; "Section B's S06 span does not
mention crafting and the protocol names no crafting site in band 2"), and
the code this would implicate (`build_menu.gd`/`craft_panel.gd`/
`game_menu.gd`) is shared UI, not band2-owned. Flagging for whoever owns
that code, not fixed here.

**What the run does confirm cleanly, unaffected by either stranding**:
`S06-24` (walk to the quarry, 148.2m, PASS), `S06-27`–`29` (quarry
arrival + rootstone gather, PASS — Rootstone purpose §1's own claim held
up under a real walked/gathered path, not just a config read), `S06-55`–
`57` (walk to the real Warrens site and enter, PASS — the ~150m protocol-
anchor-vs-built-site gap `S06-54` already documents in its own comment is
the reason `S06-51`'s region check fails at the *stale* anchor, and the
walk to the *real* site at `(-357,2616)` succeeds cleanly at `S06-55`),
`S06-86` (2862.3m actually walked, comfortably over the 2000m floor),
`S06-87` (3005 route rows, the 2Hz trace ran throughout). `S06-88`'s
615.5m dead-travel peak is **not a real Band 2 pacing finding** — it is
the forced re-walk back toward the Warrens after the death-satchel reset,
measured across ground the player had already crossed once; the
repository's own D70 census (cited in `GATE3_ENCOUNTER_CONTRACTS.md` §2)
already measures Band 2's real worst gap at 165m, well inside prompt
P-2.1's 200m ceiling, and nothing in this run contradicts that number —
it just cannot re-confirm it, because this run's own dead-travel meter was
corrupted by the reset before it could measure the real corridor cleanly.

### Evidence template (`docs/ROADMAP.md`'s own fields)

- **Player purpose**: confirmed live — Rootstone purpose (§1 above) held up
  under an actual walk-and-gather, not just config reading; the tracked
  objective on load and throughout reads "Clear the Burrow Warrens beneath
  the Old Quarry," the strongest wording form per `GATE3_ENCOUNTER_
  CONTRACTS.md`'s own note.
- **Team progression**: the entry party (L8/7/7/6) did not survive Dorn
  under this run's scripted, potion-free play. Whether a real, competently
  played floor-level team survives is not answered by this run — the
  harness's own combat-scripting limitation is at least as likely a cause
  as an actual balance defect, per the reasoning above. Open, not closed.
- **World interaction**: rootstone gather (PASS), Warrens entry (PASS),
  workbench placement (PASS) all confirmed live; the craft panel's own
  focus and the later menu handoff did not (root cause 2).
- **Longest empty-travel interval**: not cleanly re-measurable from this
  run (corrupted by the reset); the repo's own D70 census figure (165m,
  band2) stands unchallenged.
- **Reliability**: 78/106 steps PASS on first attempt, but effectively
  two systemic strandings rather than 28 independent step defects (17
  raw fails resolve to 2 root causes, both outside this lane's file
  ownership).
- **Presentation**: not evaluated this run — this is the logic lane; every
  §G capture is correctly delegated to `S06C`, not taken here.
- **Decision**: **S06 = FAIL for this specific run**, but not evidence of
  a Band 2 content defect on the two axes it actually broke on (combat
  balance, menu handoff) — both trace to mechanisms outside this lane's
  ownership (the shared step-script's own combat-scripting method, and
  shared build/craft UI code). Recommend: (1) re-script `S06-22`/`64`/`74`
  with `fight_until_resolved` and re-run before drawing any balance
  conclusion about Dorn or the guardian from this segment; (2) whoever owns
  `build_menu.gd`/`craft_panel.gd`/`game_menu.gd` check the build-catalogue
  context handoff after a workbench `interact`; (3) once contract G-2 lands
  in `wild_creature.gd`, re-run S06 to check the guardian fight against the
  "what it should feel like" paragraph above.

### Files touched this reopening

- `tools/gate_f/build_s06_entry_synthetic.gd` (new) — the synthetic S06
  entry seed builder.
- `data/config/burrow_warrens.json` — guardian `combat` block (G-2/G-9
  data only; no code changed).
- `ralph/reports/gate-f-run-G3-BAND2-0903/` — the run directory (`RUN_
  METADATA.json`, `S06/`, two earlier superseded attempts kept per the
  harness's own restart-protection rule; raw `telemetry/`/`shots/`/
  `frames/` payloads are gitignored by this repo's own policy — only
  `notes/`, `INVENTORY.json`, `RUN_METADATA.json` and `saves/` are
  committed).
- `ralph/reports/G3-BAND2-0903/REPORT.md` — this addendum.

Not touched, per the coordinator's explicit instruction or this lane's own
ownership boundary: `scripts/creatures/wild_creature.gd`,
`tools/gate_f/segments/S06.json`, `tools/gate_f/operator_harness.gd`,
`scripts/ui/build_menu.gd`/`craft_panel.gd`/`game_menu.gd`,
`data/config/bands/band2_stone_and_root/trainers.json`'s Dorn entry.
