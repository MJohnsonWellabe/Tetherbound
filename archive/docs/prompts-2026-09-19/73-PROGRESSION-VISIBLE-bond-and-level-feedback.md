# PROGRESSION-VISIBLE — bond and level progression the player can see while it happens

**Written 2026-09-04** as the A1/A2 contract `docs/FINISH_THE_MEADOWS_ADDENDUM_2026-09-04.md`
asks for first. Source directive: `docs/owner/OWNER_DIRECTIVES_2026-09-04-C.md` §1, which
outranks this file where they differ. It supersedes the narrower
`47-CREATURE-level-up-feedback.md` (a level-up toast) and owns the "bond gain feedback"
and "level-up feedback" lines of `67-FIVE-creature-pressure-and-bond.md`; both stay valid
where they do not conflict.

The owner's sentence this is built to answer:

> Bonding and leveling creatures is basically invisible. It needs to be a big thing. Not
> just when the bond goes up but also while trying to bond.

And the reason it is load-bearing: no-refight plus a level gate means the chapter asks the
player to grind toward numbers. *"Once we make bonding and leveling more important and
visual it will feel better to grind it. That's what we need."* Until this lands, every
tracked objective in Phase 2 asks for a grind the player cannot see.

---

## 1. What is true today — measured on `main` at `75bb1dc7`, do not re-derive

### Bond

- The live model is **five lifetime counters** on `scripts/creatures/creature_instance.gd`:
  `battles_fought` (153), `landmarks_visited_together` (136), `distance_m_together` (137),
  `rest_nights_together` (138), `feeds_together` (139). The old `bond: int` field (126) is
  dead, kept for save-parse compatibility.
- The ladder is `data/config/bond_milestones.json`, read only by
  `scripts/creatures/bond_milestones.gd`. **It is ordered**: `tier()` (48–63) stops at the
  first incomplete task, so a creature has tier N only when the first N tasks are complete
  *in order*: 50 battles → 3 landmarks → 4,000 m → 4 nights → 10 meals.
- Crediting sites, all silent: battles `scripts/combat/combat_manager.gd:926`; distance
  `autoload/game_state.gd:630` (all party members, on a discovery tick); landmarks
  `game_state.gd:639`; rest `game_state.gd:801` (only creatures in a bed); feeds
  `scripts/ui/tab_backpack.gd:1946` (the one creature fed).
- What bond does: +1 % attack and defence per node (`data/config/progression.json`
  `bond.effects_per_node`, applied at `scripts/creatures/progression.gd:134`); the second
  trait reveals at 5 nodes (`progression.gd:172`, `creature_instance.gd:721`); Mudsnout's
  evolution needs tier 3 (`scripts/creatures/evolution.gd:152–161`).
- **No signal or event fires on any bond change or milestone, anywhere.** Every consumer
  polls `bond_nodes()`. The one sentence the game can say about it is
  `bond_milestones.gd:80 progress_text()` ("38/50 wild creatures defeated together").

### XP and level

- `level`, `xp` on the instance (117–118). `gain_xp()` (534–546) returns levels gained and
  loops while `xp >= xp_to_next()` under `cap: 50`; curve `int(40 * level^1.15)`.
- Awarders: combat victory `combat_manager.gd:908–942` (`_award_victory`; the finisher gets
  full, other non-fainted members get `party_share 0.5`); trainer `xp_bonus`
  (`encounter_director.gd:2379`); Warrens bonus (`burrow_warrens.gd:3191`); rest bonus
  (`home_recovery.gd:24`). **Catching awards no XP.**
- A level-up recomputes stats and nothing else. No moves on level (moves are species
  defaults plus TMs); evolution is player-triggered from the Team screen at level 15 plus
  bond tier 3 plus the heartstone.
- **No signal.** `combat_manager.gd` writes a plain dict `last_xp_award` that the combat HUD
  polls.

### What the player is shown

- `scripts/ui/combat_hud.gd:1180–1263`: a "+N XP" line, and on level-up "+N XP · Name
  reached Lv N", with a 1.22× scale-pop tween. **Active creature only, ~2.4 s, no sound.**
- The Team screen (`scripts/ui/tab_creatures.gd`) is the only complete surface: "Lv N",
  "EXP n / m" with a bar, "Bond n/5" with `scripts/ui/bond_meter.gd` and the progress
  sentence, and the caption "+N % ATK/DEF per node".
- `scripts/ui/party_strip.gd:898` shows "Lv N" and KO/REST tags. **No XP bar, no bond.**
- `game_state.gd:732 push_world_message()` is a one-shot toast the world HUD already
  polls (`playground_hud.gd:4025`). **Nothing in progression uses it.**

### Conventions that bind the implementation

- There is **no event bus**. `project.godot` declares one autoload, `Game`, with a comment
  that it is meant to stay the only one, and it declares zero signals. Cross-system change
  is revision-counter polling (`party.revision`, `_last_progression_revision`).
- Save fields live in `scripts/save/save_game.gd` at three places (write 778–787, read
  842–860, migration defaults 391–404 and 626–646). A new field goes in all three.
- `tests/test_level_up_announcement.gd` asserts on the **source text** of `_set_xp_line`
  rather than running it. That is the false-positive shape `33-TEST2` exists to close. No
  test written for this prompt may pass by grepping a script.

---

## 2. The contract

### 2.1 One progression feed, matching the repo's own convention

Add a small queue on `Game` beside `push_world_message` — call it the **progression
feed** — that every progression change pushes into and every presenter drains. Not a
signal (the no-signal rule stands), a queue with a revision counter, exactly the shape the
world-message toast already uses.

Event kinds, each carrying the creature's instance id and display name:

| kind | payload | pushed from |
|---|---|---|
| `xp_gained` | amount, xp, xp_to_next, level | `_award_victory`, trainer bonus, Warrens bonus, rest bonus, candy |
| `level_up` | old_level, new_level, levels_gained, stat deltas, `trait_unlocked`, `evolution_ready` | the single place levels change: `creature_instance.gain_xp()` and `set_level()` |
| `bond_credit` | task id, before, after, target | each of the five crediting sites in §1 |
| `bond_near` | task id, remaining | derived at credit time when `remaining <= near_threshold` |
| `bond_milestone` | node index, task id, what it changed (the +% line, trait, evolution gate) | derived at credit time when `tier()` rises |

Rules:

- **One source of truth per kind.** A level transition is detected inside the instance,
  never re-derived by each awarder (prompt 47's rule, kept).
- Multi-level jumps push one `level_up` with `levels_gained > 1`, never five.
- Events for creatures other than the active one are **not dropped**; they are what the
  party strip renders.
- Candy (`docs/FINISH_THE_MEADOWS_ADDENDUM_2026-09-04.md` §B, its own prompt) pushes the
  same `xp_gained`/`level_up` events. The addendum's rule: *"candy level gains use the same
  core feedback language rather than a separate silent path."* Build the feed so that is
  automatic.
- The companion-reaction layer (addendum §E) and CL-A2's level-up flourish are consumers
  of this feed. Provide the hook; do not build them here.

### 2.2 Three loudness levels, and which surface owns each

The directive asks for *"subtle but readable"* ordinary gains and *"strong audiovisual"*
milestones. Three levels, deliberately, so the loud one stays special:

| Level | When | Where | Duration |
|---|---|---|---|
| **Tick** | every `xp_gained`, every `bond_credit` | the party strip: a per-creature XP sliver fills; the creature's bond pip flicks once with a one-word label ("+bond · fed", "+bond · won") | ≤ 1 s, no sound or a single soft tick |
| **Near** | `bond_near`; XP within one ordinary fight of a level | the same pip/sliver pulses slowly until the milestone; the Team screen row says what is left ("2 more nights") | until resolved |
| **Moment** | `level_up`, `bond_milestone` | a HUD banner naming the creature, the new level or the milestone, and **what changed** (stat deltas, "second trait revealed", "evolution ready"); a sound cue in `data/config/audio.json`; the hook for CL-A2's flourish and the companion reaction | ~3 s, queued behind combat |

Constraints inherited from the repo:

- Controller first, 1280×800 handheld legibility, everything inside the 5 % safe area
  (the HUD judge already flagged the food bar outside it, CL-B4).
- **Never cover combat controls.** During a fight, Moments queue and flush at the result
  beat; Ticks may show on the strip at once.
- The banner must not steal focus from an open menu or a dialogue; it is a passive layer
  like the world message, not a modal.
- The owner's rule on noise: reactions and feedback need cooldowns. Two Moments within
  five seconds collapse into one banner listing both.

### 2.3 The Team screen answers the two questions

The directive's acceptance sentence: **"How bonded am I with this creature, and what am I
doing that increases it?"** The Team screen already has the meter; it does not answer the
second half. Per creature it must show:

- the current node count and, for **every** task, its counter against its target, with the
  currently-credited task marked "next" and the completed ones marked done;
- a one-line benefit for the next node ("+1 % attack and defence", "reveals second trait",
  "unlocks evolution");
- level, XP bar, XP to next, and the level at which anything changes (evolution eligibility
  at 15).

### 2.4 The ordered ladder — a decision to record, not to make silently

Today a creature fed ten meals before its fiftieth battle shows **no bond progress at all**
from those meals, because `tier()` stops at the first incomplete task. The directive wants
the player to see *which actions* strengthen the bond, and under the ordered ladder four of
five actions are invisible until their turn.

Two honest options. The orchestrator picks one and records it in `docs/decisions/`
(`docs/00_START_HERE.md`: open design questions are decided by the orchestrator, not queued
for the owner):

1. **Unordered ladder (recommended).** A node is earned when *any* task completes;
   `tier()` becomes the count of complete tasks. Every action reads immediately. The five
   targets stay as tuned. `tests/test_bond.gd`'s tier-ordering assertions change with it,
   and `evolution.gd`'s `bond_tier: 3` gate now means "any three".
2. **Keep the order, show all five.** The feed still credits every counter (so the Tick
   fires on a meal even before the battles milestone) and the Team screen shows all five
   with the active one marked next. Cheaper, but the player will see "fed 10/10 · not yet
   counted", which is the kind of thing the owner calls invisible.

Either way, no new tasks are added. *"Do not add arbitrary meter-filling chores."*

### 2.5 Tunables

Put them in `data/config/progression_feedback.json` (new), not in code: near thresholds
per task and for XP, tick/near/moment durations, the Moment cooldown, sound cue ids, and
the banner's safe-area inset.

---

## 3. Ownership and scope

**Owns:** `autoload/game_state.gd` (the feed only), `scripts/creatures/creature_instance.gd`
(`gain_xp`/`set_level` push), `scripts/creatures/bond_milestones.gd` (credit helpers push;
the ladder rule per §2.4), the five crediting sites listed in §1, `scripts/ui/party_strip.gd`,
`scripts/ui/combat_hud.gd`, `scripts/ui/tab_creatures.gd`, `scripts/ui/bond_meter.gd`,
`scripts/ui/playground_hud.gd` (banner), `data/config/progression_feedback.json`,
`data/config/audio.json` (two cue ids), and the tests below.

**Does not own:** candy items and their placement (addendum §B/§C, their own prompt);
companion reactions (addendum §E); the level-up flourish shader (CL-A2); any change to
XP awards, the curve, the cap, or what a level grants. If the work seems to need a new
award source, stop and flag.

**Save format:** no new persisted fields are expected. If §2.4 option 1 is chosen, the
counters are unchanged and only `tier()` changes; no migration. If a "last seen level"
per creature is needed to catch up a banner after load, add it in all three places in
`save_game.gd` and bump the version.

---

## 4. Validation — behaviour, never source text

Unit (`godot --headless --path . --script tests/run_tests.gd -- --only=<file>`):

- `tests/test_progression_feed.gd` (new): every kind in §2.1 is pushed exactly once by its
  source; a 3-level jump yields one `level_up` with `levels_gained == 3`; a non-active party
  member's award is present in the feed; draining empties it and bumps the revision.
- `tests/test_bond.gd`: updated for the §2.4 decision; `bond_near` fires at the configured
  remaining count and not before; `bond_milestone` carries the correct benefit text.
- `tests/test_level_up_announcement.gd`: **rewritten to run `_set_xp_line` against a stub
  manager** and assert the rendered text, replacing the source-text grep. It must be seen
  to fail with the feed disconnected before it is trusted.

Smoke:

- `tests/smoke_progression_feedback.gd` (new): drive a real wild fight to victory, a feed,
  a landmark discovery and a bed rest with the real interact path; assert the party strip
  ticked for each, the Team screen shows the counters, and a forced level-up produced one
  banner inside the safe area at 1280×800. Never `--headless` with a rendering driver.
- `smoke_gate_b_continuous` and the Gate F S01–S03 segments still pass on first attempt;
  the banner must not have broken any dialogue, menu or combat-result step.

Visual: capture the level-up banner and a bond-milestone banner on the route strip's fight
frame (after 0.1 / CL-H9 lands) and put them to the blind judge with the HUD in frame.

---

## 5. Done when — the addendum's own bars

- During a continuous Meadows segment a player can identify **at least two real actions**
  that increased bond, can inspect progress toward the next milestone, and recognises a
  milestone without debug data.
- Normal combat and (once it exists) candy produce clear, consistent level feedback, and
  the player can tell how close a creature is to the next level **from the world HUD**,
  not only the Team screen.
- The evidence template for the segment records the two bond actions and the level-up by
  name.

**Fails if** only the final bond-up event becomes visible while the process stays opaque;
if a level changes in data and the player must open a menu to learn it; if the banner ever
covers combat controls or steals focus from a menu; or if any new test passes by reading
a script's source.
