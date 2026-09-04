# G3-FINALE-0903 — Meadows Hall as the chapter's payoff

Task: `docs/prompts/69-STRONGHOLD-chapter-finale.md`, coordinated with 46
(release ceremony) and 67 (five-creature pressure). Branch
`ralph/G3-FINALE-0903`, from `main` @ `3c73aab5`.

## Headline verdict

**The finale is already built and already correct.** Every system prompt 69
asks for — the five-space route, the elite-gated door, the recovery point,
the reveal-before-Warden ordering, the Warden fight itself, the legendary
freeing, the five-creature release ceremony, world healing, and save/load
persistence across every finale state — exists, is wired end to end, and
passed real execution on this branch, first attempt, in this session. No
code change was needed to satisfy prompt 69's acceptance bullets.

The one open question the task brief raised — whether the Warden actually
*reads* as harder than Keeper Hald, given his weakest creature (level 16)
leads off two levels below Hald's floor (18) — was measured, not assumed.
**The Warden fight is unambiguously the harder fight**, by every hard
number: roughly double the duration and hits absorbed of Hald's fight, in
both team compositions tested, and its own round times climb rather than
stay flat. No level or order change was made to `warden_aldis` or
`stronghold_elite`; the data does not support one. See §1.

The only functional change on this branch is two missing `.gd.uid` sidecar
files that Godot's import generated for `tools/_capture_band1_map_trails.gd`
and `tools/_capture_band1_signpost_legibility.gd` (committed without one
originally; the repo's convention pairs every `.gd` with a `.gd.uid`). Not
part of this lane's scope, added because the import step produced them and
leaving them untracked would have been noise on every future diff.

## Method

Container has no working directory Godot; installed 4.7-stable per the
task's own instructions and ran `godot --headless --path . --import`
(clean run, exit 0, ~9 minutes in this container). All following runs are
against that same imported tree, this session, this branch — nothing here
is `(reported)`.

## 1. Is the Warden the hardest meaningful fight? — measured

`tools/_probe_combat_ladder.gd` fights the authored trainer at the level
`chapter_curve.json`'s band-5 curve puts the player at (elite: step 0.8 →
L19; Warden: step 1.0 → L20), full party HP, through the same
`encounter_director.begin_trainer_battle()` path and real piloted input
(`combat_pilot.gd`) the smoke suite uses — not a stat-sheet comparison.
Fought twice per trainer, with both chapter-curve team archetypes the probe
ships (`ground`: terrapup/bramblebun/mudsnout/trailpup/meadowhart — "a
player who catches whatever is in front of them"; `mixed`: a
type-diversified team — "a player who prepared"):

```
godot --headless --path . --script tools/_probe_combat_ladder.gd -- --team=mixed --only=stronghold_elite
godot --headless --path . --script tools/_probe_combat_ladder.gd -- --team=mixed --only=warden_aldis
godot --headless --path . --script tools/_probe_combat_ladder.gd -- --team=ground --only=stronghold_elite
godot --headless --path . --script tools/_probe_combat_ladder.gd -- --team=ground --only=warden_aldis
```

| team | trainer | foes | seconds | party hp left | hits taken | misses forced |
|---|---|---|---|---|---|---|
| mixed | stronghold_elite (Hald) | 3 | 47.1s | 98.4% | 3 | 12 |
| mixed | warden_aldis | 5 | **94.5s** | 96.3% | **6** | 26 |
| ground | stronghold_elite (Hald) | 3 | 59.6s | 97.8% | 4 | 16 |
| ground | warden_aldis | 5 | **82.4s** | 97.1% | **5** | 22 |

The Warden fight ran **38–101% longer** than Hald's and cost **1.25–2×** the
hits taken, in both team compositions. Both trainers were won cleanly by a
curve-appropriate team (as designed — this measures relative escalation,
not a wall), so the comparison that matters is relative, and it is
consistent in both directions tested.

Round-by-round (mixed team), the Warden's own send-out order — confirmed by
reading `encounter_director.gd::_send_out_next_creature()`: plain FIFO off
the JSON `team` array, no level sort, no ace-protection logic — is:

```
Hald:   galecrest L18  14.2s   burrowback L19  17.2s   duskhush L19  12.5s
Warden: burrowback L16 14.0s   brooktail L17  17.0s   galecrest L17 11.6s   meadowhart L18 24.6s   tuskroot L20 20.9s
```

The concern named in the task brief — that a level-16 lead-off, two levels
below Hald's floor, would read as an anticlimax right after Hald's L18-19
team — does not materialize in piloted play: the Warden's own round 1
(14.0s) is statistically indistinguishable from Hald's round 1 (14.2s) and
sits inside the spread of Hald's own three rounds (11.6–17.2s across both
runs). At this game's level/stat curve a 2-level gap does not move fight
duration as much as the raw numbers suggest on paper; matchup and the
pilot's own damage output dominate more than trainer level does. What
clearly does move the numbers is the fourth and fifth creatures — the
Warden's own rounds climb to its longest (24.6s, 20.9s) exactly where
Hald's fight has already ended, which is the design the `trainers.json`
comments describe ("a whole extra creature, not just levels, is what
actually punishes a party") and it is now demonstrated, not asserted.

**Decision: no change to `warden_aldis` or `stronghold_elite`'s levels or
team order.** Both rows stay inside `chapter_curve.json`'s band-5
`trainer_levels: [15, 20]` window as authored; the window itself does not
need to move. This is a measured "already satisfied," not an unexamined
one — re-run the four commands above against any future rebalance to keep
this honest.

## 2. Five-space structure and pacing

`data/config/stronghold.json`'s `chambers`/`passages`/`gauntlet` blocks and
`scripts/world/stronghold.gd` build exactly spec §8's five spaces in §8's
order (`outer_works → courtyard → tether_approach → warden_arena →
legendary_chamber`), each fought against by `tests/smoke_stronghold.gd` —
**passed this session** (route order, floor-per-space, doorway
traversability, the one elite-gated blast shutter both closed-then-open,
gauntlet placement, the recovery bed's real heal, the machine's scale).

Escalation across the whole approach + Hall, not just the Hall's own four
spaces: `stronghold_outer_watch` (grunt, 2 @ L15) → `stronghold_checkpoint`
(officer, 3 @ L16) → `stronghold_patrol` (grunt, 2 @ L15-16, first body
*inside* the Hall) → `stronghold_courtyard` (officer, 3 @ L16-17) →
`stronghold_elite`/Hald (captain, 3 @ L18-19, the one door in the complex)
→ recovery point → `warden_aldis` (warden, 5 @ L16-20). Every space carries
exactly one trainer, never a repeat of the same fight; rank and team size
both step up monotonically except for the outer-watch→patrol reset, which
is a new area (crossing from the open approach into the building itself),
not a repeated room. No room's only content is an identical trainer.

The recovery point sits between the elite and the Warden, exactly where §8
puts it ("elite, then rest, then the Warden") — a real `creature_bed.gd`
instance, not decoration; `smoke_stronghold.gd` and `smoke_gate_e_finale.gd`
both drive it and both pass (the latter faints a real party member, rests
it at the bed, confirms hp/fainted state recovers).

## 3. Tether reveal legibility

`data/dialogue/stronghold.json`'s `stronghold_reveal` conversation (a Team
Tether maintenance readout, environmental, read on the Warden Arena
threshold **before** he speaks — order enforced and verified live by
`smoke_gate_e_finale.gd::_read_the_reveal_before_he_speaks`) ties every
conduit and gauge the player has walked past all chapter to one line: the
legendary is "SOURCE: LEGENDARY CLASS, GROUND. DESIGNATION VERIDIAN.
CONTAINED, CHAMBER 5," drawn on for 1,411 days. `docs/decisions/D41`'s
drained-ground grammar (quarry → relay → Upper Meadows pylons → this
approach) is the landscape half of the same ladder, first-appearance to
strongest, already implemented per §5 below. The reveal is read as
architecture and machine-voice, not told in a cutscene.

## 4. Legendary freeing and the five-creature decision

Verified by direct code reading (this session's own Explore pass, not
re-summarized in full here) and by `smoke_gate_e_finale.gd` passing live:
`stronghold_climax.gd`'s stage machine (`STAGE_CHAMBER → STAGE_FREED →
STAGE_JOIN → STAGE_CEREMONY → STAGE_FAILURE → STAGE_DONE`) cannot leave
`STAGE_CEREMONY` while `Game.pending_catch != null`, and `pending_catch` is
only ever cleared by the release ceremony's own commit in
`tab_creatures.gd`. Both the ceremony and the legendary-join path mutate
the party exclusively through `autoload/party.gd`'s `add()`/`remove_at()` —
no ad hoc mutation found anywhere else. The ceremony itself (`tab_creatures.gd`
`_release_stage`: `choose → confirm → done`) shows portrait/model, name,
level, HP, type, traits, moves, bond, Best Creature status and a
`_history_line()` (battles fought, day caught, levels gained "with you"),
defaults focus to "Keep them," and fences the shell so the choice cannot be
dodged — this session's live run of `smoke_gate_e_finale.gd` drove exactly
this path on real input and confirmed the legendary (`veridian`) lands on a
belt of five with the chosen release gone and nobody duplicated.

## 5. World healing after the win — D41/§9

`scripts/world/meadow_healing.gd`, triggered off `legendary_freed`
(polls `progression.revision`, so a post-victory load applies immediately
too — see §6), does five things in one `apply()`: restores drained
vegetation world-wide via `vegetation.restore_drained()` (keyed off every
station's own `drain_factor`, not one hand-picked site), fades the two
runtime dead-ground skins (`approach_drain_skin.gd`, `tether_relay.gd`'s
relay skin — the baked terrain colour maps are a documented, accepted D45
non-goal, not a gap), kills every lit tether fitting world-wide by material
signature, opens the `road_gate_open`/`hall_approach_open` barriers, and
withdraws seven named beaten patrol trainers. This session's own run of
`smoke_gate_e_finale.gd` printed real numbers on this branch: **1,156
plants regrown, 21 tether lights killed, 4 patrols withdrawn** (barriers:
0 opened in that run only because `ARRIVED_AT_THE_HALL`'s scripted flags
had already opened both gates before the healing ran — `smoke_stronghold_reload.gd`'s
narrower setup shows 2 barriers opening for real when they start closed).
Wiring is complete end to end: `stronghold_climax.gd:470` sets
`legendary_freed` → `playground_world.gd` has already stood up the
`MeadowHealing` node at world build → its own poll loop fires `apply()`.

**One gap found, out of this lane's file ownership, not fixed:**
`scripts/world/stronghold_occupation.gd` (the Hall's exterior garrison
dressing — braziers, sky-fill lights, tether work-lamps, the checkpoint
camp) has no reference to `legendary_freed`, `meadow_healing`, or any
progression flag at all — it is placed once at `build()` and never reacts.
If "the stronghold's own visible occupying force withdraws or goes dark
after the Warden falls" is expected as part of the world's answer, nothing
currently does that; `meadow_healing.gd` only touches lit tether-network
*fittings* by material signature (which excludes warm firelight) and named
*beaten trainers*, not `stronghold_occupation.gd`'s static dressing. Not
this lane's file (not in the exclusive-ownership list in the task brief) —
flagging for the coordinator rather than touching it.

## 6. Persistence — measured, not asserted

`tests/smoke_stronghold_reload.gd` **passed this session**, both windows:

- **Settled ending** (`defeated_warden`, `legendary_freed`,
  `legendary_joined`, `legendary_settled` all set before boot): a fresh
  world load stands **no** legendary body at all (no caged copy of a
  creature that already left), climax stage comes back `"done"`, and the
  machine control is refused — `_place_legendary()` checks
  `legendary_settled` before spawning anything.
- **Freed-but-unsettled window** (a save landed between `legendary_freed`
  and `legendary_settled` — real, because the dialogue panel doesn't pause
  the tree the way the ceremony's own menu does): the legendary comes back
  **freed, not caged** (`ContainmentVFX` absent), and the climax stage
  resumes toward the join offer rather than getting stuck.

All finale state rides the same generic `progression_state.gd` flat-flag
save/load path (`save_data()`/`load_data()`, VERSION 3 of the save format)
— there is no finale-specific save code to diverge from the rest of the
game's persistence, and no stronghold/climax script implements its own
`save_state`/`load_state`. `Game.pending_catch` (the ceremony's own seam) is
deliberately never saved (`game_state.gd` comment: "the player cannot walk
around owning six"), which is why the freed-but-unsettled window is safe on
reload — `_hand_over_the_legendary()` re-checks `party.is_full()` fresh
every time rather than trusting stale state.

## 7. Full continuous run — the actual acceptance bar

`tests/smoke_gate_e_finale.gd` **passed this session, first attempt**: a
full five-creature, finale-level team walked in from the entrance, fought
the patrol → courtyard → elite gauntlet, rested a fainted creature at the
recovery point, watched the shutter lift, read the reveal before the Warden
spoke, beat the Warden, pulled the lever, took the full-belt release
ceremony (a real creature, "Kettle," was released; the legendary joined a
belt of five), watched the objective chain terminate on the roster
decision, watched the region answer (numbers in §5), and got a post-victory
villager acknowledgment that closed the objective chain. This is the exact
continuous path prompt 69's "Evidence run" section asks for.

## Acceptance bullets (prompt 69)

| Bullet | Status |
|---|---|
| stronghold feels like a climax, not a late content room set | **Met** — escalating rank/team-size ladder, no repeated rooms, §2 |
| Warden tests the chapter's team-building skills | **Met on aggregate numbers, measured** — §1: 38–101% longer / more hits taken than the fight immediately before it, both team archetypes. **Combat *identity* (distinct from "largest numbers") was a real gap this report's first pass missed** — see the encounter-contract addendum below: data-side fix (W-1/2/3/7) landed this session, the shared AI mechanism (G-2) is the coordinator's own branch |
| reveal is understandable in the world | **Met** — §3, environmental readout ahead of the Warden's own words |
| legendary freeing has ceremony | **Met** — §4, live-tested |
| five-slot decision can be genuinely difficult | **Met mechanically** (identity/history surfaced, choice explicit and permanent, enforced ordering); whether it *feels* difficult to a real player is a subjective playtest question this session cannot answer from a synthetic finale-level team |
| world visibly responds | **Met** — §5, with one out-of-scope gap flagged (garrison dressing never withdraws) |
| no progression/save duplication | **Met, measured** — §6, both reload windows |
| final sequence leaves a strong next-chapter question without entering Biome 2 | **Met** — `rift_collapse.gd`/SG44 is a distant, non-enterable sky effect, unchanged by this lane, out of this lane's ownership and not touched |

## Addendum — GATE3_ENCOUNTER_CONTRACTS.md (Fable, `ralph/G3-ENCOUNTERS-0903`)

After the report above was written, the Gate 3 coordinator relayed a
finding from `docs/specs/GATE3_ENCOUNTER_CONTRACTS.md`: every opponent in
the game currently shares one global `combat.json` `enemy` AI block
(`scripts/creatures/wild_creature.gd:333`), so §1's escalation measurement
in this report, while accurate about *aggregate numbers*, could not answer
prompt 69's actual requirement that the Warden have "a recognizable combat
identity, not simply the largest numbers." That is a real gap this report
did not catch on its own first pass — the ladder probe measures outcomes,
not behaviour, and behaviour was uniform across every trainer in the game
at the time it was measured.

Contract G-2 (a per-body `combat` override merged in `set_engaged()`, plus
five reusable behaviour profiles — WALL/CHARGER/DIVER/CURRENT/ACE) is being
implemented by the coordinator directly, on their own branch, because
`wild_creature.gd` is shared across all five Gate 3 lanes. This lane's half
is authoring the Hall cast's data against that contract, in the three rows
already under this lane's exclusive ownership.

### What changed (commit `a54aacd5`)

- **W-1** (`warden_aldis` levels): 16/17/17/18/20 → **18/18/19/19/20**. The
  shipped opening was two levels *below* Hald's own weakest member (18) —
  measured concretely in §1 above (round 1 of both fights ran at nearly
  identical pace, 14.0s vs 14.2s), which is the "soft front" the contract
  names. No member now sits below the elite's floor; the ace is unchanged
  at the chapter's highest; still inside `chapter_curve.json`'s band-5
  `[15,20]` window (not edited — that file is G3-ECONOMY's).
- **W-2** (send-out order + profiles): burrowback (**WALL**) → galecrest
  (**DIVER**) → brooktail (**CURRENT**) → meadowhart (**CHARGER**) →
  tuskroot (**ACE**, `lunge 6.5`/`cone_degrees 72` — Earth Fist's own shape
  from the Warrens guardian, G-9). Order in the JSON array is authoritative
  send-out order (confirmed by this lane's own earlier reading of
  `encounter_director.gd::_send_out_next_creature()` — plain FIFO, no sort).
- **W-3** (TM-tier quicks, Warden only): `rock_throw`/`aqua_shot`/
  `wind_blade`, each confirmed on-type against `species.json` and each
  15–20% harder than the species default per `data/moves/moves.json`.
- **W-7** (`stronghold_elite`/Hald): duskhush → **mosshell**. His own
  shipped `_comment` claimed "three creatures of three different types"
  against an actual Air/Ground/Air team; now Air/Ground/Water, matching the
  comment. Profiles: galecrest DIVER, burrowback default (no override),
  mosshell WALL.
- `stronghold_courtyard` (Solene): checked against the contract, **no
  change made** — no W-contract assigns her row a `combat` profile, and
  W-8 keeps both her and Hald on species moves, reserving TM-tier quicks
  for the Warden alone.

The `combat` blocks are inert data on this branch: `set_engaged()` does not
read them yet (that merge is the coordinator's, on a separate branch), and
G-2's own contract guarantees an absent/unread block leaves today's
behaviour byte-for-byte unchanged — so authoring them ahead of that merge
carries no behavioural risk on this branch.

### Validation

- `test_trainers_data.gd`: 50 tests, 1386 assertions, 0 failed (checked by
  hand first against the specific guards this change could trip —
  `test_the_wardens_team_is_the_hardest_in_the_chapter`'s `lowest >
  captain_high` and `highest >= lowest + 2`, `test_no_step_on_the_critical_
  path_jumps_more_than_four_levels`, `test_nothing_in_the_stronghold_out_
  levels_the_warden`, `test_the_critical_path_alone_pays_for_the_warden_
  ready_level` — all still hold with the new numbers, then run for real).
- `test_chapter_curve.gd`: 18 tests, 451 assertions, 0 failed.
- `smoke_stronghold.gd` (route): passed.
- `smoke_gate_e_finale.gd` (full continuous run): passed, including the new
  Hald team (mosshell) and the new Warden team/order/moves end to end —
  the same continuous walk-in → gauntlet → recovery → elite → reveal →
  Warden → lever → ceremony → healing → acknowledgment path as the original
  report, now exercised against the raised levels.

### W-9 (Hald's line matches his geometry) — verified, no change needed

W-9 asks that the blast shutter be visible behind Hald from his challenge
position, lit by its own conduit run, so his line ("the shutter behind me
stays down while I'm standing") is literally true on screen. Checked with a
small read-only headless probe against the live scene (not rendered, pure
transform query — `tools/`-style, not committed):

- Hald's world position: `(10.0, 6.17, 7629.0)`, facing `-Z` (`facing_deg
  180`, matching `stronghold.json`'s own `_why` note that this turns him to
  face the corridor the player walks in from).
- The blast shutter (`BlastShutter_defeated_stronghold_elite`): `(8.0,
  8.17, 7635.1)`, **6.7 m** from Hald along the vector `(-2.0, 2.0, 6.1)`.
  `dot(Hald's forward, vector to shutter) = -0.907` — strongly negative,
  meaning the shutter sits almost dead-centre on his back axis, not off to
  a side that could read as incidental.
- The `tether_approach → warden_arena` conduit
  (`data/config/stronghold.json`'s `conduits` array, `offset: 2.6`,
  self-lit via `_live_material()`) resolves to an unnamed mesh at `(10.6,
  6.23, 7637.1)` — **3.2 m** from the shutter, i.e. the same passage.

Already satisfied by existing geometry; no code or data change made. This
is a geometric/transform verification, not a rendered one — I did not run
this through `tools/survey.sh` or the blind-judge skill, so "visible" here
means "on the unoccluded line the numbers describe," not "confirmed
legible in a real frame." If the coordinator wants photographic
confirmation, that is a `tools/survey.sh` + visual-judge pass this session
did not do.

### W-4 (Warden Arena dressing + re-measurement) — not done, flagged open

W-4 asks for the arena's end wall and door to be dressed (banners, the
conduits converging on the chamber door, two braziers outside the 11 m
combat ring) and the Warden's silhouette re-measured at 16 m against the
1.5:1 luminance floor `CREATURE-LEGIBILITY-0903` established. This is
squarely this lane's file (`scripts/world/stronghold.gd`) but is a
genuinely visual task — new geometry plus a real headless-rendered capture
plus a blind-judge pass, per this project's own rule that visual work is
never judged by the agent that made it. That pipeline
(`tools/survey.sh`, xvfb, Compatibility renderer, `.claude/skills/
visual-judge/SKILL.md`) was not set up or run this session. Rather than
manufacture a low-confidence pass, this is left open and named here so the
coordinator can route it — either back to this lane in a follow-up session
with render time budgeted, or to whichever lane is already doing the
Hall's other visual work this session found in progress
(`_comment_base_t1_hall_3`'s JUDGE-5 pass, `hall_occupation`'s lighting
rounds).

### Design intent — what the Warden's fight is supposed to feel like

The coordinator asked this lane to state intent so the G-2 merge can be
checked against it, separately from the contract's own numbers:

The Warden should feel like **the only fight in the chapter fought by
someone who has trained for exactly this job**, not like a bigger wild
encounter. Concretely: the first four send-outs should each be
*legible as the profile a captain already taught* — a player who has
fought the region's captains and Hald should be able to name what's coming
before it swings, the way `stronghold_warden_defeated`'s own line ("Rest
your five first. He fields more than I do") tells you going in that this
is attrition, not a single hard check. The fifth (tuskroot, ACE) should be
the one moment in the whole chapter where the correct read is "step out of
this, don't trade with it" — mechanically identical in shape to the
Warrens guardian's Earth Fist (W-2's own point: the chapter's first
telegraph-worth-respecting and its last are the same shape, met at level 14
and again at level 20), so a player who learned that lesson in the first
hour gets to feel it pay off in the last one. What it should *not* feel
like: a wall that out-punishes good play regardless of positioning (G-3's
own *fails if* — no profile should one-shot a full-health curve-appropriate
creature), and not a repeat of Hald's own fight at a higher number — Hald
is the "last check of the kit" (W-8), spends the player's consumables, and
is beatable clean; the Warden should cost more of the *fight itself* —
faint pauses, repositioning against five different rhythms in a row — not
just more HP bars. If the G-2 merge makes WALL/CURRENT read as
interchangeable "the enemy hits me sometimes," or makes DIVER's retreat
read as the AI simply being far away rather than *leaving and coming back
from a new side*, that's the gap between the contract's numbers and this
intent worth checking for.

## What changed on this branch

- `tools/_capture_band1_map_trails.gd.uid`,
  `tools/_capture_band1_signpost_legibility.gd.uid` — added (Godot-generated
  sidecars for two scripts committed without one; see commit `37afeb04`).
- `ralph/reports/G3-FINALE-0903/REPORT.md` — this report (commit
  `24bb3754`, this addendum).
- `data/config/bands/band5_stronghold_approach/trainers.json` — the
  `warden_aldis` and `stronghold_elite` rows only, per
  `GATE3_ENCOUNTER_CONTRACTS.md` W-1/W-2/W-3/W-7 (commit `a54aacd5`). See
  the addendum above for the full reasoning; `stronghold_courtyard` was
  checked and left unchanged.
- No other files changed. Every system this lane owns was verified against
  its acceptance bullet by real execution and left as authored, or (the
  Warden/Hald data) changed against a design contract and re-verified by
  the same tests that verified it before the change.

## What was not chased further

- The `stronghold_occupation.gd` garrison-withdrawal gap (§5) — not this
  lane's file ownership.
- Whether the five-slot decision *subjectively* reads as difficult needs a
  real (non-synthetic) playtest team carried the length of the chapter,
  which prompt 67's own acceptance criteria (roster pressure earlier in the
  Meadows) are better positioned to answer than a finale-only session.
- Visual/render verification (blind judge pass) was not run this session —
  no rendering path was exercised, only headless logic/combat. If prompt
  69's environmental-storytelling bullets need a visual pass, that is
  `tools/survey.sh` + `.claude/skills/visual-judge/SKILL.md` work this
  report did not do.
- **W-4** (Warden Arena wall/door dressing + luminance re-measurement) —
  open, flagged in the addendum above. This is the one contract item
  assigned to this lane ("Hall lane") that genuinely was not attempted,
  because it needs the render pipeline and a blind-judge pass this session
  did not set up.
- The G-2 mechanism itself (`set_engaged()`'s merge, the five profiles'
  actual in-engine feel) is the coordinator's own branch and was not
  re-verified here beyond confirming the `combat` blocks this lane authored
  parse correctly and stay inert until that merge lands.
