# The Meadows progression curve

**Owning prompts:** `docs/ralph-prompts/57-TEAM-progression-curve.md`,
`docs/ralph-prompts/67-FIVE-creature-pressure-and-bond.md` (Gate C).
**Data:** `data/config/chapter_curve.json`.
**Reader:** `scripts/creatures/chapter_curve.gd`.
**Enforced by:** `tests/test_chapter_curve.gd`.
**Measured by:** `python3 tools/_probe_pacing.py`.

This is the chapter-wide curve every regional package (D1–D5) inherits and
tunes. It does not replace `MEADOWS_PROGRESSION_SPEC.md`; it is the numeric
band that spec's prose implies, in one place, in data.

---

## 1. What already existed, before this document

Most of prompt 57 was already built and should not be rewritten:

- **Levels, XP, the curve and the award** — `data/config/progression.json`,
  `scripts/creatures/progression.gd`. Every number tunable, none hard-coded.
- **The chapter's pacing was already measured and already tuned.** `SH47`/`D42`
  flattened `xp_to_next_exponent` 1.6 → 1.15 and doubled the award to `30 + 16L`
  specifically to delete 8 hours of field grinding, and left
  `tools/_probe_pacing.py` behind as the re-runnable measurement plus five
  guard tests in `tests/test_trainers_data.gd`.
- **The trainer ladder escalates** from level 2 to the Warden's level-20 ace
  across 15 critical-path fights, with tests forbidding a step of more than
  four levels and forbidding anything in the stronghold out-levelling the boss.
- **Bond, individuality/appraisal stars, traits, the second-trait unlock,
  elixirs with a spend cap, the Mudsnout → Tuskroot gate (level 15 + bond 55 +
  heartstone), Best Creature, and the release ceremony** all exist and are
  tested.

Two things did not exist, and they are what this document adds.

## 2. What was missing

**(a) The curve was not written down anywhere tunable.** The expected team
level per region lived inside `tools/_probe_pacing.py`; the fight order lived
in a `CRITICAL_PATH` constant inside a test file; the opposition levels lived
scattered across five band directories. A regional package could not read "what
should my region be" from anything.

**(b) Wild opposition did not escalate at all.** `progression.json`'s
`level.wild_band` was one global `[2, 6]` for the whole 8km corridor. A wild
creature standing at the Meadows Hall rolled the same level as one in the
practice meadow. Two consequences, both bad, and the second is the one that
matters most:

1. The field stopped being opposition roughly an hour into a four-hour chapter.
2. **The five-creature cap stopped being a decision at the same moment.** A
   creature caught in the stronghold approach arrived at level 4 against a team
   at 16. Nobody weighs that against a member they raised. The hard cap
   (CLAUDE.md: five, no storage, ever) cannot be loosened and must not be — so
   the only available lever is making a late catch strong enough to argue for.

## 3. The curve

Team bands are **measured**, not chosen: they are what `tools/_probe_pacing.py`
prints per band against the shipped XP curve and award (2026-08-22).

| Region | world z | team enters → leaves | wild field | authored opposition | key tools |
|---|---|---|---|---|---|
| Lower Meadows | < 1360 | 3 → 8 | 2–6 | trainers 2–7 | orbs, first TMs, beds |
| Stone & Root (Quarry / Warrens) | < 3180 | 8 → 10 | 6–8 | warrens 9–11, guardian 14 | rootstone, saddle, greater orb, heartstone |
| The River Lock (Relay) | < 4760 | 10 → 13 | 9–12 | trainers 8–16 | relay TMs, full-bond second trait |
| Upper Meadows / Ironwood | < 7000 | 13 → 16 | 11–14 | captains 13–16 | ironwood, sigils, riding, Tuskroot |
| Stronghold Approach & Hall | rest | 16 → 20 | 14–17 | 15–19, Warden ace 20 | everything |

The `world z` column is the corridor's own band table
(`MEADOWS_MACRO_LAYOUT.md` §3), the same bounds
`scripts/world/world_perimeter.gd` styles the corridor edges with. A test
asserts the two never drift apart.

**Four invariants the tests enforce on every region:**

1. Nothing in a region's field out-levels what that region brings the team to
   (`wild high ≤ team exit`) — a region may be dangerous, never a wall.
2. Something in it is beatable on arrival (`wild low ≤ team enter`).
3. A catch there is a real option (`wild high ≥ team enter − 2`) — §5 below.
4. Neither the team band nor the wild band ever goes backwards.

**No player scaling.** The band is resolved from a spawn's **world position**
and nothing else. A level-3 player who walks to the approach meets the same
level 14–17 creatures a level-19 player does. Prompt 57 requires this and
`MEADOWS_PROGRESSION_SPEC.md` §3 says it outright.

## 4. The one opposition change made here

`captain_field` 11/12/13 → **13/14/15** and `captain_ridge` 12/13/15 →
**14/15/16**.

This was the chapter's only backwards step. The player reaches Captain Halder
at z=5590 having already beaten the relay captain (11/11/12, z=3757) and
Captain Riverwatch (13/14/16, z=4350); a level-11 lead against them read as the
region going soft. Both remain inside spec §3's "roughly 10–16 entering this
band" and inside the existing captain-band test's 10–16 window, and the
retune keeps `band4_upper_meadows_ironwood/trainers.json`'s own claim that Vess
is "a level step above the Field Captain" true.

Everything else in the trainer table was already correct and was left alone.

`tests/fixtures/band_split_baseline/trainers.json` pins every value of every
pre-split entry, so these two levels had to be updated there as well. That
fixture exists to stop one band author's edit silently moving or rerolling
another band's content — `order`, index, `centre`, `position`, `count` and the
seeds derived from them — and a deliberate level retune moves nothing and
rerolls nothing. `tests/test_band_content.gd`'s header now says so explicitly,
because the alternative reading is that no authored number in the Meadows may
ever be tuned again, which nobody intended.

## 5. How the five-creature limit is made to bite

The limit is absolute and nothing here softens it: five creatures, no storage,
no reserve, no sixth slot, not even a disabled one. The design job is to make
**replacing** one a considered decision.

**What replacing already costs, all of it implemented:** invested levels (the
curve is steep enough that a mid-chapter replacement starts several fights
behind), accumulated bond and its per-node stat scaling, the second trait that
unlocks at full bond, Best Creature designation, an in-progress evolution gate,
and the traversal slot if the creature cut is the mount. The release ceremony
(R4.10) shows those before the choice commits.

**What was missing was the other half of the trade: a reason to want the new
one.** That is what the regional wild band supplies. `five_slot` in
`chapter_curve.json` holds the two numbers that decide it:

- `max_catch_level_deficit: 2` — the strongest wild creature in a region may
  never sit more than two levels below the team expected to arrive there. This
  is the number that keeps the cap live in the back half of the chapter.
- `min_distinct_wild_species: 6` — more desirable creatures than slots is the
  whole mechanism. Asserted against the merged spawn table (currently 12
  distinct species out of a 17-species roster), so deleting species from the
  world fails the build rather than quietly making the five free.

A knock-on worth naming: the Upper Meadows Meadowhart cluster now rolls 11–14
instead of 2–6, so the mount is met at a level that can actually fight. Prompt
67 asks that traversal not create a dead slot; a rideable creature caught at
level 2 in a level-14 region was exactly that dead slot.

## 6. Deliberately left to the regional packages

- **The wild ecology those bands describe does not exist yet above z≈2900.**
  Band 3 and Band 5 have **zero** wild spawns; Band 4 has one Meadowhart
  cluster. Half the corridor has no creatures in it. The curve is in place and
  will strengthen them the moment they are authored, but populating them is
  prompt 60 (`60-WILD-ecology-journey.md`) and packages D3/D4/D5, not this one.
- **Band 2 has no trainers at all** — prompt 59's gap. Its opposition is
  currently the Burrow Warrens alone.
- Encounter density, resource cadence, travel time and rest rhythm: prompts
  58/61 and the regional packages.
- Final tuning of every number above: Gate F's end-to-end pass, which is the
  first time anyone plays the whole thing in one sitting.

## 7. Design questions this repo does not settle

**Type matchups are not a mechanic.** Both prompts (and spec §5) lean on "type
coverage" as a source of roster pressure — ground tank, water counter, air
offense. There is no type effectiveness anywhere in combat:
`data/config/combat.json` has no type chart, and `data/moves/moves.json`'s own
header says `type` is "flavour/vocabulary ... not cross-checked". So a creature
cannot currently be *the answer* to anything; roles are expressed only through
base stats. Adding a type chart is on `CLAUDE.md`'s ask-don't-invent list
("changing the type system"), so it is flagged here rather than built. Until it
is settled, roster pressure rests on levels, bond, traits/appraisal, evolution
and traversal — which is enough for the cap to bite, but not the pressure the
prompts describe.

**Feeding is not a bond source.** Prompt 67 and `GAME_DESIGN.md` §12 both list
feeding and favourite food among bond earners. Bond is currently earned from
winning a battle (4), a successful catch (10) and resting together per day (2);
food is a player-only satiety/buff system and there is no favourite-food data on
any species. Adding one is small, but it is new gameplay and no owner directive
asks for it, so it is recorded rather than invented.
