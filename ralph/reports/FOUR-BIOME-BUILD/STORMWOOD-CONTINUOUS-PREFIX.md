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

The continuous prefix has not yet earned a clean Ondra terminal. The next full-
world run must begin from the same disclosed chapter-entry seam and prove the
reordered Rodline prompts plus the measured Pools window before any Crown helper
is composed. No timeout, player pose, material, weather or progression fixture
was added by these repairs.
