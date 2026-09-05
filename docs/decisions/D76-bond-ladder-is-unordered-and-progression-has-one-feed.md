# D76 — The bond ladder is unordered, and progression speaks through one feed

**Date:** 2026-09-04 · **Decided by:** lane W13-PROGRESSION-FEED, under
`docs/prompts/73-PROGRESSION-VISIBLE-bond-and-level-feedback.md` §2.4 ("a decision to
record, not to make silently") and `docs/00_START_HERE.md`'s rule that open design
questions are decided by the orchestrator and recorded here rather than queued for the
owner. Source directive: `docs/owner/OWNER_DIRECTIVES_2026-09-04-C.md` §1 — *"Bonding
and leveling creatures is basically invisible. It needs to be a big thing. Not just when
the bond goes up but also while trying to bond."*

## 1. A bond node is earned by completing ANY task, not the next one in the list

D70 turned bond into five concrete tasks (50 wild wins, 3 landmarks, 4,000 m, 4 nights,
10 meals) and `bond_milestones.gd::tier()` counted them **in order**: a creature had tier
N only when the first N tasks were complete in sequence. Under that rule a creature fed
ten meals before its fiftieth battle showed **no bond progress at all** from those meals,
and four of the five actions the directive wants the player to *see* strengthening the
bond were invisible until their turn came.

Prompt 73 §2.4 offered two honest options. This lane takes **option 1, the unordered
ladder**:

- `tier()` is now the **count of completed tasks**, in any order.
- The five tasks and their targets are unchanged (D70's calibration stands; no task is
  added — *"Do not add arbitrary meter-filling chores."*).
- The "next" task the Team screen and the bond meter point at is the incomplete task
  **closest to completion** (by fraction, list order breaking ties), so the sentence under
  the meter always names the thing the player is nearest to finishing.
- `progression.json`'s `evolution.mudsnout.bond_tier: 3` now means "any three of the
  five", and `traits.unlock_bond_nodes: 5` still means "all five".
- No save migration: the five counters are the persisted state and none of them changed;
  only how `tier()` reads them did. A creature that was tier 1 under the ordered rule can
  only be tier ≥ 1 under this one, so no player loses a node on load.

Why not option 2 (keep the order, show all five)? Because the player would see
"10/10 meals fed · not yet counted", which is exactly the shape the owner calls invisible,
and the ordered rule's one virtue — "a creature works toward exactly one line" — is kept
by the "next" marker without the cost.

`tests/test_bond.gd`'s tier-ordering assertions were rewritten for this rule in the same
change.

## 2. One progression feed, polled, not signalled

`project.godot` declares one autoload and zero signals, and cross-system change in this
repo is revision-counter polling. The feed follows that convention:

- `scripts/creatures/progression_feed.gd` holds a bounded, sequence-numbered event log
  behind static functions (`push`, `peek_since`, `drain`, `revision`). It is static rather
  than a node because the producers are `RefCounted` instances (`creature_instance.gd`)
  that have no scene tree to reach `Game` through, and unit tests run without the
  autoload at all.
- `Game` exposes the same queue beside `push_world_message` (`push_progression_event`,
  `peek_progression_events`, `take_progression_events`, `progression_feed_revision`) and
  clears it on a new game, so anything that already talks to `Game` need not know where
  the storage lives.
- **One source of truth per kind.** `xp_gained` and `level_up` are pushed from inside
  `creature_instance.gain_xp()` / `gain_levels()`, never by an awarder, so every award
  source (victory, trainer bonus, Warrens bonus, rest bonus, candy) speaks the same
  language without being edited. `bond_credit`, `bond_near` and `bond_milestone` are
  pushed from `bond_milestones.credit()`, which every crediting helper routes through.
- A multi-level jump pushes **one** `level_up` with `levels_gained > 1`.
- Presenters keep their own cursor (`seq`) and never drain: the party strip, the world
  HUD banner, the combat HUD line and the Team screen all read the same log. The log is
  trimmed to its last 64 events on push; `drain()` exists for tests and the new-game
  reset.
- Consumers the prompt names but does not build here — CL-A2's level-up flourish and
  the addendum §E companion reaction — hook in by polling `peek_since()` for `level_up`
  and `bond_milestone`, the same way the banner does.

## 3. Three loudness levels, and what is deliberately quiet

- **Tick** (every `xp_gained`, every `bond_credit`): the party strip only. Distance
  credit is ticked once per `distance_tick_m` (250 m), not on every half-second
  discovery poll, or the strip would never stop flickering.
- **Near** (`bond_near`, and XP within one level-matched fight of a level): a slow pulse
  on the strip and a "N more" line on the Team screen, until resolved.
- **Moment** (`level_up`, `bond_milestone`): the top-centre HUD banner, a sound cue, and
  the hook above. Moments **queue during a fight and flush at the result beat**; two
  within `moment_collapse_seconds` collapse into one banner listing both; the banner is
  a passive layer that cannot take focus and is held while a story modal is up.
- `set_level()` stays **silent**. Every caller of it is a spawn or story path (a
  starter's first level, a trainer's roster, a trade, a pinned encounter); announcing
  those would fire a banner for creatures the player did not level. Candy therefore
  goes through `gain_levels()`, which announces, rather than through `set_level()`.

## 4. Tunables

`data/config/progression_feedback.json` (new): near thresholds per task and for XP,
tick/near/moment durations, the collapse window and cooldown, the banner's safe-area
inset, and the two sound-cue ids. `data/config/audio.json` gains a `progression` block
mapping those two ids to the generated files.
