# Cloudreach live-crossing cover 01 — candidate

## Defect and production route

Cloudreach already authors procedural grass, flowers and understorey bushes in
`cloudreach_ground_cover.gd`. A normal solo world built them, but
`cloudreach_world.gd::_ready()` also rejected the build whenever
`ShellBuildBudget.is_slicing()` was true. A real visible multiplayer realm crossing
uses that sliced build path with `simulation_only == false`, so the player could
finish loading Cloudreach without its authored ground cover. A remote simulation
shell uses `simulation_only == true` and should continue omitting decoration.

The candidate schedules `_build_ground_cover()` for every visible Cloudreach
world using the existing `if not simulation_only` distinction. It passes the
existing `ShellBuildBudget` to the cover builder and awaits completion before
player placement. The builder releases work once per patch, every 2,048 placement
attempts, and every 2,048 MultiMesh uploads. Seeds, density caps, exclusions,
meshes, materials and transforms are unchanged. Cloudreach is the only production
caller; other realms use separate cover routes.

The temporary `should_build_ground_cover(shell)` helper and a smoke that only
repeated its boolean were removed. Simulation-shell absence and live-world
presence are proven through the existing real two-peer `smoke_net_split_realms.gd`.

## Focused construction receipt

After cleanup, `cloud-live-cover-focused-second` ran from 08:47:03 through
08:47:08 and completed cleanly. The real cover class produced 2,600 grass,
20 flowers and 10 bushes in both unsliced and yielding-budget construction.
All assertions passed and the yielding path reported three budget releases.
The 2,600-grass fixture crosses the 2,048 placement and upload release boundaries.

## Actual two-peer functional receipt

`cloud-live-cover-net-first` ran from 08:47:09 through 08:50:47. The coordinator
exited 0 with every check passing. Before the swap, the client's visible sliced
Cloudreach world reported 1,048,134 grass, 13,342 flowers and 778 bushes. The
host's simulation-only Cloudreach shell reported grass 0, flowers 0, bushes 0
and `present=false`. After the swap, the host's visible sliced Cloudreach world
reported the same 1,048,134 / 13,342 / 778 census. This proves the intended
visible-world versus simulation-shell routing through an actual two-peer realm
transition.

The run must not be called error-free. Peer 0 logged `The new image dimensions
must match the texture size` at `scripts/ui/minimap.gd:337`; a separate fix is
pending. During realm departure it also repeatedly logged missing trainer `Sync`
node-cache entries. No `SCRIPT ERROR` was found in the inspected child logs.
These child errors did not fail the coordinator assertions, but remain integration
debt and need separate validation.

`cloud-live-cover-net-second` reran from 09:11:29 through 09:15:07 after the
separate minimap correction. Coordinator checks again passed with the identical
visible-world cover counts and zero simulation-shell counts. The minimap image
dimension error was absent from both child logs. Peer 1 was clean; peer 0 still
logged 304 departure-time missing trainer `Sync` node/cache error lines. The
repeat confirms cover routing and the minimap repair, while leaving the separate
realm-departure synchronization fault open.

## Limits

No native visual comparison, frame-time claim, broad visual acceptance, full CI
result, repeated reconnect proof, or error-free child-process claim is established.
The candidate has focused deterministic construction evidence and repeatable
functional two-peer routing evidence. The departure synchronization errors and
current CI remain pending.
