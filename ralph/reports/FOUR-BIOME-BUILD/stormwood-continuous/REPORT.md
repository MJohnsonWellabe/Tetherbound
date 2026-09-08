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

The run in `%TEMP%/stormwood-continuous-solo-award-final.log` reached all of the
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

The Maren run also proves the solo hosted-reward repair in commit `7a773b8b0` in
the production world: before that repair, the same three resolved rounds ended
without the durable defeat fact. The focused real-ledger regression separately
proves solo/host authority, active-client refusal, receipts, inventory, replay
idempotence, and Captain Marrow's Dynamo defeat fact.

## First current boundary

The same run opened Dace dialogue but did not start hosted combat. This is not
yet classified as a production blocker. The immediately preceding wild combat
was recorded only as “resolved”; the harness did not capture its outcome and
only attempted recall when no body existed. Production intentionally does not
auto-switch after a wild loss, so a fainted deployed member would make Dace's
pre-dialogue `can_challenge` check false while healthy party members remained.

The next harness revision now records every `CombatManager.exited` outcome and
uses ordinary `party_cycle` followed by `creature_recall` before each trainer.
It fails closed with the live manager/trainer/ally/defeat state if Dace remains
unavailable. Until that revised run executes, “fainted ally after the route
wild” is a source-supported candidate, not a proven diagnosis, and Act I beyond
Dace is not claimed.

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
controller combat. It remains prepared source coverage until the Dace boundary
is cleared and one uninterrupted runtime reaches it.

## Focused checks

- `tests/smoke_stormwood_hosted_rewards.gd`: 8 checks passed, exit 0; log
  `%TEMP%/stormwood-hosted-rewards-final.log`.
- Root's independent repeat: 8 checks passed, exit 0; log
  `%TEMP%/root-stormwood-hosted-rewards.log`.
- Continuous script check-only parse passed after the outcome/recovery change;
  log `%TEMP%/stormwood-continuous-outcome-check.log`.
