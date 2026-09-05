# Shared visible progression feed

## Current contract — merged-main reconciliation, 2026-09-05

Cloudreach uses the W13 implementation shipped on main and D76's **unordered**
five-task bond ladder. Each completed task grants a node; the nearest incomplete
task is the next suggested action. The branch's older ordered-bond decision and
standalone presenter are superseded, not a second supported architecture.

`scripts/creatures/progression_feed.gd` is the single static, bounded event log.
Game's progression wrapper methods use that same log. There is no
`Game.progression_feed` instance. Consumers use `peek_since(seq)` and
`latest_seq()`; `revision()` is a change counter, **not an event cursor**.
`epoch()` changes on clear/new-game/load so a reset cannot replay old banners
or hide a new event that reuses an earlier sequence number. Readers receive copies
and cannot mutate another consumer's payload.

The existing PlaygroundHUD contains the sole MomentBanner. Existing PartyStrip
rows render their own XP/bond feedback; CombatHUD and the Team screen read the
same log. Do not mount the deleted progression_feedback_hud or
progression_strip_overlay scripts. Inactive combat strips cannot resurrect during
exploration. The shared presentation group and moment_visible() accessor allow
world/UI lifecycle coordination without a second banner.

## Producers and ownership

- Real XP awards use CreatureInstance.gain_xp.
- Candy uses gain_levels; set_level remains silent construction/hydration.
- Battle completion calls the shared battle-credit helper exactly once.
- Feeding, walking, discovery, rest and milestone producers share the same feed.
- In a live game only current owned party members publish individual progression.
  Trainer/wild construction and the temporary Fly loaner do not produce owned
  team feedback. Standalone unit tests can exercise producers without an autoload.
- Trainer reward_summary receipts report the production payout, not a second
  grant. Team-wide receipts remain distinct from per-creature XP attribution.

## Cloudreach Fly-route credit

cloudreach_physical_runtime.gd::_on_landed credits the owned carrier only after
observed flight, real ground contact, the authored route checks and a **changed
canonical completion event**. credit_distance(creature, 25, "fly_route") retains
the configured 25m bonus and explicitly publishes this small route credit despite
ordinary walking's coarser notification interval. Repeated landings, reloads and
the non-owned Maela loaner cannot farm or misattribute the reward.

## Evidence boundaries

Merged selected regression run: 352 tests / 33,703 assertions, with three stale
chapter fixtures failing because they omitted the required physical shrine vanes.
Progression/feed/bond/level-up/save selections passed. After updating only those
fixtures, chapter progression separately passes 8 tests / 115 assertions,
including a negative control that arrival alone cannot reveal the shrine truth.

The merged lifecycle smoke passes 34 checks, including reward receipt retention,
combat/relay ownership, modal and tree-pause timing, and same-sequence feed reset.
The dedicated feed lifecycle, production integration, full unit suite and fresh
rendered evidence are being rerun. Older isolated UI sheets describe the replaced
branch presenter and are historical evidence, not acceptance of this merged UI.
Full continuous chapter and external visual acceptance remain open.
