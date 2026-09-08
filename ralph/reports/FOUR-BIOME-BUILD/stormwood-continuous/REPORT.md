# Stormwood continuous solo prefix — 2026-09-08

## Scope and disclosed seam

`tests/smoke_stormwood_continuous.gd` begins at the Stormwood chapter boundary,
not at a fresh save. Its wrapper creates an in-memory completed-Cloudreach
fixture (the nine disclosed Cloudreach facts, five level-44 party members, and
the ordinary knife/axe/pickaxe loadout), then calls the production realm router.
It sets no `stormwood:*` fact and never writes position, combat state, health,
trainer outcomes, or earned Stormwood inventory. The reusable segment advances
with production locomotion, controller input, dialogue, weather, gathering,
interactions, combat, ledger rewards, and chapter events.

This is chapter-entry acceptance evidence. It is not evidence that Meadows and
Cloudreach earned the disclosed input state in the same process or save.

## Proven uninterrupted prefix

The first run in `%TEMP%/stormwood-continuous-solo-award-final.log` reached all of the
following without a debug teleport, reload, Stormwood flag fixture, position
write, or combat-state write:

1. Entered Stormwood through `Game.enter_realm` and settled the arrival.
2. Walked to Ashfoot, earning `stormwood:chapter_started` by proximity.
3. Completed Hesk and Tamsin's production conversations.
4. Witnessed an actual Break while sheltered at Ashfoot.
5. Gathered the six Stormglass cost through live charged-node interactions.
6. Relit both pair-A arches and crossed their live travel threshold.
7. Collected the route-03 candy through its ordinary prompt.
8. Activated Maren's real challenge and resolved all three rounds through
   controller combat.
9. Observed the hosted authority's explicit `finished, won=true` event, then
   observed the durable Maren defeat fact and disabled the Verge rod through
   its live switch.
10. Continued on ordinary locomotion through another wild encounter to Dace.

The follow-up in `%TEMP%/stormwood-continuous-dace-act2.log` repeated that prefix
and continued further:

11. Recorded the intervening Ash-road wild as an actual `outcome=lost`.
12. Recovered through ordinary party-cycle/recall input, then won all three Dace
    rounds, observed hosted `finished, won=true`, committed Dace's durable defeat
    fact, operated the Hollows switch, and earned `stormwood:lower_rods_disabled`.
13. The autosaved world from that same process contains both authored Pools
    harvest-node facts and `stormwood:arch:b_pools:lit`, proving the segment also
    gathered pair B's six Stormglass and relit its first endpoint before timeout.

The Maren run also proves the solo hosted-reward repair in commit `7a773b8b0` in
the production world: before that repair, the same three resolved rounds ended
without the durable defeat fact. The focused real-ledger regression separately
proves solo/host authority, active-client refusal, receipts, inventory, replay
idempotence, and Captain Marrow's Dynamo defeat fact.

## First current boundary

The Dace boundary is cleared. The follow-up observed the source-supported
condition the earlier harness could not see: the route wild ended in a loss.
The harness then ran its ordinary party-cycle/recall recovery path, the named
challenge became available, and the live three-round fight passed. This proves
the player path recovers; it does not claim that lost-wild recovery was the sole
cause of the earlier harness attempt's missing challenge.

The current boundary is diagnostic capacity, not a demonstrated production
softlock. The expanded segment exhausted its fixed eight-minute wall-clock
watchdog after pair B's Pools endpoint and before its next checkpoint at the
Rodline endpoint. The last persisted pose was `(-782.55, 27.30, 1674.73)`, on
the authored road between the relit Pools endpoint and the harness's
`(-900, 1780)` intermediate waypoint. The save contains no Rodline-link or Bryn
fact. Because the old harness logged neither per-leg starts nor its live state
at watchdog expiry, it cannot distinguish remaining ordinary travel from a
stalled navigator and must not classify this as either pass or product defect.

The prepared diagnostic now logs each walk's start, end, distance, elapsed wall
time and consumed physics-frame budget. If its outer watchdog expires, the
failure includes the active phase, live player/target/remaining distance,
walked-frame budget, combat state and navigator availability.

The whole-prefix ceiling is now 20 minutes, derived from the expanded scope
rather than guessed from the old prefix. From the last persisted pose, the
authored legs through the `(-900,1780)` and `(-700,2300)` waypoints, Rodline
arch/Bryn, and the two conductor-road points to Ondra total 1,536.8 m. The
unchanged walker allowance of 80 physics frames per metre has a 256.1-second
target-clock estimate for that distance at the wrapper's configured 480 Hz;
actual wall time can be higher with runtime overhead. Adding that estimate to
the eight minutes already observed, Varga's unchanged five-minute sequence
bound, and 60 seconds for the nearby pickup, switches and two dialogues yields
18.3 minutes. Twenty minutes is a bounded margin for the prepared Act-II scope.
It does not relax the per-walk frame budget, 120-second weather window,
180-second live-fight bound, five-minute trainer bound, or prompt/dialogue
assertions.

## Prepared Act-II opening (not yet runtime-proven)

The reusable segment now continues past Bryn for one bounded Act-II slice. Its
contract comes directly from `data/config/stormwood_chapter.json`'s first two
Act-II objectives and `stormwood_chapter.gd`'s production event bindings:

1. collect the visible route-07 candy that shares Rodline Post, so its prompt
   cannot be mistaken for the named trainer interaction;
2. challenge and defeat `lieutenant_varga_rodline_bridge`, requiring the hosted
   victory to earn both the defeat fact and `stormwood:varga_defeated` through
   `trainer:varga_defeated`;
3. walk the authored `conductor_road` points to Keeper Ondra and finish her
   in-progress dialogue, requiring `dialogue:ondra_arch_recipe` to earn
   `stormwood:arch_recipe_known`.

The exact intended terminal flag for this bounded extension is
`stormwood:arch_recipe_known`. It does not fabricate Crown materials, place the
missing arch, cross the Glass Sink, clear the guardian, or claim Act II complete.
All extension actions are locomotion, ordinary prompt activation, dialogue, and
controller combat. Dace and the first pair-B endpoint are now runtime-proven;
Rodline/Bryn and the prepared Act-II extension remain unproven until one
uninterrupted runtime reaches them.

## Focused checks

- `tests/smoke_stormwood_hosted_rewards.gd`: 8 checks passed, exit 0; log
  `%TEMP%/stormwood-hosted-rewards-final.log`.
- Root's independent repeat: 8 checks passed, exit 0; log
  `%TEMP%/root-stormwood-hosted-rewards.log`.
- Continuous script check-only parse passed after the outcome/recovery change;
  log `%TEMP%/stormwood-continuous-outcome-check.log`.
- Dace/pair-B continuation: exit 1 only at the fixed eight-minute harness
  watchdog after the Pools endpoint; log
  `%TEMP%/stormwood-continuous-dace-act2.log`.
