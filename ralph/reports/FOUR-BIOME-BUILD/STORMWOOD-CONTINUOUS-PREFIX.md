# Stormwood continuous prefix evidence — 2026-09-08

## Scope

`tests/smoke_stormwood_continuous.gd` begins from its disclosed completed-
Cloudreach in-memory seam and uses ordinary input after production Stormwood
entry. This note records two terminal runtime findings while extending its
existing bound through Keeper Ondra. Neither repair below is claimed runtime-
proven until the queued rerun reaches a terminal verdict.

## Runtime 1: Rodline provider order

`%TEMP%/stormwood-continuous-20m-20260908.log` terminated exit 1 after proving
entry, Hesk, Tamsin, pair A, Maren, Dace and pair B. At Bryn's requested stance,
the exact `InteractionArbiter` winner was the co-located route-07 `Take Good
Candy` provider at 1.430 m; Bryn's body was 1.08 m away and his prompt was
1.46 m away. The route had not collected route-07 until after Bryn, so the
failure was an honest ordinary-action ordering defect in the harness.

The repair moves the same controller-driven one-time route-07 collection to
immediately before Bryn and removes the later duplicate. It neither deletes the
pickup nor bypasses either provider.

## Runtime 2: charged-window expiry

`%TEMP%/stormwood-continuous-20m-r2-20260908.log` terminated exit 1 after Dace.
The Lantern Pools window wait returned in 1 ms because *some* Break/Fading time
was open. Travel and interaction across the two selected nodes then consumed
about 45.7 simulation seconds. Neither node committed: the durable save carried
no Pools receipt, zero Stormglass, and pickaxe durability 38—the two wear points
from pair A only.

The source explains the variance. Once Dace's lower rod is disabled,
`disabled_rod_break_multiplier` shortens this region's Break from 120 to 60
simulation seconds (`data/config/stormwood_surge.json:3`), but the old wait
accepted even the last instant of Fading. The repair reads the production
`stormwood_surge_rules.gd::phase_at` state and its actual following phase,
requiring at least 55 contiguous open simulation seconds before departure. It
does not hardcode a production phase duration or change weather timing. Each
node must then independently settle its exact +3 Stormglass, durable source
receipt and one pickaxe wear before the route leaves it; a failure prints the
runtime phase/remaining state and all three deltas.

`tests/test_stormwood_continuous_charged_window.gd` pins the Break-to-Fading
boundary and the fail-closed per-node checks. It passed together with the Crown
helper contract: 6 tests / 78 assertions, no native `ERROR:` in
`%TEMP%/stormwood-charged-window-contract.log`. The coordinator independently
reproduced the same 6 / 78 result in
`root-stormwood-window-crown-review-20260908.log`.

## Current boundary

The corrected run in
`%TEMP%/stormwood-continuous-b492274fd-20260908.log` again earned the prefix
through Maren's three explicitly won rounds and the live Verge switch. An
ordinary aggressive road fight on the next leg ended in a loss; the harness
used ordinary party-cycle recovery and reached Dace. At the Dace button edge,
the arbiter activated `EncounterDirector` rather than Dace's prompt.

This provider identity is decisive rather than inferred from timing. The arbiter
only emits `activated(provider)` after the winning offer is actionable
(`interaction_arbiter.gd:368-381`). Outside a fight, the encounter director's
only actionable interaction offer is the nearest live wild inside engage range
(`encounter_director.gd:2536-2568,2922-2938`); its fainted and creature-control
lines are explicitly non-actionable. A roaming wild therefore entered engage
range between the eight stable prompt samples and the physical button-edge
recompute. The bounded repair resolves only that exact director-started live
fight, recovers through ordinary party controls when necessary, and re-approaches.
It still fails every other competitor and returns success only after the exact
requested provider is observed.

The continuous prefix has not yet earned a clean Ondra terminal. The next full-
world run must begin from the same disclosed chapter-entry seam and prove the
button-edge retry, reordered Rodline prompts and measured Pools window before
any Crown helper is composed. No timeout, player pose, material, weather,
progression fixture or wild suppression was added by these repairs.

## Runtime 4: Varga was standing inside Bryn

`%TEMP%/stormwood-continuous-e78a76080-20260908.log` proved Dace's three won
rounds, `lower_rods_disabled`, a production window with 131.966 simulation
seconds open, both exact Pools +3 receipts and one wear each, paid pair-B
relight, route-07-before-Bryn, and Act I completion. The next required Varga
challenge was unreachable: from the target stance and all four cardinal
approaches, Bryn's live greeting won. The final measurement was Bryn 1.4165 m,
Varga body 1.07 m / prompt 1.48 m.

This was an exact production data overlap. `stormwood_npcs.json` put Bryn at
`[-700,44.18,2300]`; `stormwood_trainers.json` put Varga at the identical XYZ.
The visible Act-II objective instead says Varga waits on the exposed ascent
beyond Rodline, and `conductor_road` begins `[-700,2300] -> [-560,2480]`.
Varga is moved to that segment's exact midpoint `[-630,56.45764165,2390]`;
the Y is `StormwoodHeightfield.height_at(-630,2390)`. It is 114.0 m from Bryn,
inside the playable-first dead-travel limit, and clear of both Bryn and the
separate story-Varga greeting. The continuous harness now walks those 114 m
through ordinary controller input before requesting the exact trainer.

The same edit closes a harness isolation defect found during review. Each run
constructs a unique scratch `SaveGame` before its first yielded frame and before
its explicit reset, so subsequent transition autosaves cannot share journals or
reach the default `user://saves`, `user://worlds` or `user://characters` trees.
The static contract proves order and uniqueness; the next full-world run must
also compare those default trees before/after and prove ordinary Varga approach.
The coordinator independently ran the Varga route plus save-isolation contracts:
5 tests / 28 assertions, no native `ERROR:` in
`root-varga-route-review-20260908.log`. This is configuration/static evidence,
not the still-pending ordinary approach proof.

## Fresh-session handoff

The owner requested wrap-up before the Varga runtime could launch. There is no
Stormwood Godot process or resumable runtime session. The default campaign save
trees were fingerprinted before the queued proof and again after the focused
contracts: eight files, unchanged aggregate SHA-256
`C1B17A987B5E2B7C3D1EECA13F828BFD574ABF69ED0D67B1797DDB8E2E04CC28`.

The next action is one full `tests/smoke_stormwood_continuous.gd` run with a
unique `--log-file`, beginning at the disclosed Cloudreach-complete seam. It
must prove the ordinary 114 m Bryn-to-Varga walk, exact Varga activation/all
three rounds/durable win, continued Ondra recipe, and the default-save
fingerprint unchanged afterward. Stop at its first actual failure; do not
compose the separately prepared Crown helper until Ondra is earned in that run.
