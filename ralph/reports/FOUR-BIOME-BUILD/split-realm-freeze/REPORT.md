# Split-realm freeze — evidence handoff

Status: **locally green twice on the final integrated proof.** Runs
`net-local-split-integrated3-1788843045` and
`net-local-split-confirm-1788843300` both completed the full two-peer
`smoke_net_split_realms` path with **ALL CHECKS PASSED**. The 15-second heartbeat and
literal 6,000-physics-frame realm-entry budget were not raised. The timer now starts
before `Game.enter_realm()` and covers the complete readiness coroutine; it is no
longer a wall-clock approximation started after the work. All focused runs were
cleaned and left no orphan `Godot*` processes.

The final two repairs came from subsequent red confirmation runs. ENet's stock
5-second reliable-ACK minimum dropped both healthy peers while the client built
Cloudreach and the host built its simulation shell. Session now configures both
connected packet peers above Game's bounded transition window; the independent
15-second application heartbeat remains unchanged. A cold Meadows return then
measured 65.026 seconds, proving the candidate 60-second readiness cutoff was below
an already-progressing valid build; the finite deadline is now 120 seconds, consistent
with the existing ~85-second cold-Meadows measurement.

The green run still emitted the pre-existing multiplayer node-cache errors during
ordinary transition RPC teardown, while old-realm nodes were being removed. They did
not interrupt heartbeats, fail an assertion, or prevent either crossing from
settling, so they do not overturn this smoke verdict. They remain a separate teardown
cleanup defect and must not be mistaken for a clean error log.

## Starting CI evidence

Run `34177060785`, shard-7 job `101909010387`, artifact `10037747552` supplied the
starting peer logs. Its client peer last heartbeated at physics frame 840, then
rebuilt Meadows after the swap. The scene-authored Player fell through the partially
built floor to roughly y=-347 while Warrens/Stronghold built synchronously; the final
authored line was the Warrens guardian-facing message and the peer was killed for
>15 seconds of silence.

## Focused evidence sequence

| Run | Measured result | Recorded evidence |
|---|---|---|
| `tetherbound-net-local-split-realms-20260908T015540Z-25972` | Warrens/Stronghold staging removed the original silence. Honest readiness then exposed Cloudreach not ready within the nominal frame budget. Cloudreach Player still fell to y~-273. | Coordinator verdict and `peer-1.log`. |
| `net-run-local-1572031` | Cloudreach Player hold kept the client at its authored y=60 with no runaway-velocity warnings. Host went silent immediately after standing up its Cloudreach shell. | Coordinator verdict and `peer-0.log`. |
| `net-run-local-1445704` | Awaitable ridge boundaries alone did not yet prevent host silence; the log still had no live stage breadcrumb after shell attachment. | Coordinator verdict and `peer-0.log`. |
| `net-run-local-1484908` | Live markers plus per-ridge slicing removed the >15-second silence. The client exhausted 6,000 uncapped headless physics signals in only ~10.9 seconds while still advancing normally through routes. | Last client marker: `routes:Ridge004:station:14:spur:begin total=10864ms`. |
| `net-run-local-1442208` | `_step_enter_realm` enforced the unchanged 6,000-frame budget as its intended 100 seconds at 60 Hz. Heartbeats stayed healthy, but the builder stopped advancing at a RockShoulder expansion. | Verdict: `5458 observed physics frames / 100008 ms`; last client marker: `Ridge001:station:14:spur:begin total=11001ms`. |
| `net-run-local-1459961` | Skipping only `_build_embedded_rock_shelves` in sliced RockShoulders proved the core `_mesa` returned, but the immediately following `await _shell_build.call("breathe")` never resumed. Heartbeats and 5,589 physics frames continued for the full 100 seconds. | Last client marker: `Ridge001RockShoulder29:embedded_shelves:deferred total=8791ms slice=114ms`. |

The final run is the decisive isolation. The last marker is emitted *inside* `_mesa`
after the candidate visual expansion has been skipped. Therefore `_mesa` returned.
Its caller's next statement is the budget `breathe()` await; the 114 ms slice requires
a yield and that nested continuation is never resumed even though the peer emits
thousands more physics frames and regular heartbeats. Further reducing visuals cannot
repair that scheduler failure.

## Candidate diff assessment at the red boundary

This assessment records the candidate state before the integrator continuation. Its
warnings explain why that candidate was not landed as a fix; the definitive current
verdict is the green transition-guard run recorded below.

### Independently proved; retain selectively

- `scripts/world/burrow_warrens.gd`, `scripts/world/stronghold.gd`, and their awaited
  `scripts/world/playground_world.gd` call sites: top-level authored stages yield
  through the existing budget. The original post-Warrens peer silence no longer
  reproduced, and the full Stronghold completion log was reached.
- Meadows and Cloudreach transition-player hold/restore: sliced real builds keep the
  scene-authored Player inert until placement/readiness. Cloudreach stayed at y=60
  instead of falling below y=-273/-347; invalid-config/Terrain3D error returns restore
  the prior process mode.
- Exact `shell_build_complete() == _shell_ready` and the peer runner's readiness wait:
  probes no longer accept a published-but-partial current scene.
- Awaitable `_route_ridge`, per-complete-station/row/face boundaries, awaited
  `_emit_shoulder_top`, and off-tree ridge/collider assembly: these preserve generated
  order and topology and removed the measured host heartbeat silence. They do **not**
  by themselves prove full build completion.
- `_step_enter_realm` budget accounting: keep numeric `budget_frames=6000`, start
  before awaiting `Game.enter_realm()`, and compare the process's actual physics-frame
  delta across the complete transition and settle. Wall milliseconds are diagnostic
  only; the independent coordinator and heartbeat guards remain separate.
- `scripts/world/shell_build_budget.gd::is_slicing()` is the production seam used by
  the safe player hold and sliced-only decisions.

### Diagnostic/incomplete; revert or redesign before commit

- The high-volume per-station/per-mesh `mark()` calls in
  `scripts/world/cloudreach_world.gd` are diagnostic noise. Remove them after the next
  scheduler proof; a begin/top-level-complete breadcrumb can remain.
- The sliced RockShoulder `_build_embedded_rock_shelves` skip is a measured cheap win,
  but it did not solve readiness. Revert it (and its `docs/SECOND_PASS_BACKLOG.md` row)
  unless the playable-first integrator deliberately accepts that visual deferral.
- `ShellBuildBudget.mark()` exists only to make killed-peer progress durable. Keep a
  low-volume version or remove it with the noisy call sites.
- At this boundary, the route changes could not be committed as a claimed fix: the
  focused smoke was still red and the nested continuation defect remained.
- `tools/net/peer_runner.gd` also contains a structured Livewire `data` result change
  from another lane. It is not part of this lane and must not be reverted with these
  edits.

## Materially different strategy recommended at the red boundary

The handoff recommended moving suspension ownership out of the deeply nested
`RefCounted.breathe()` coroutine.
Use an explicit world-root build queue/state machine: bounded authored jobs return to
the root, the root alone awaits the next frame, and readiness is published only after
the queue drains. Equivalently, make the budget report that a yield is due while the
world-root scheduler performs the actual await. Do not add another nested visual skip
or another `await _shell_build.call("breathe")`; the final run proves that is the
unreliable seam. The next proof remains the unchanged two-peer
`tests/smoke_net_split_realms.gd`, with the 15-second heartbeat and 6,000 nominal-frame
budget intact.

## Definitive integrator continuation — locally green

The changed scheduler strategy reached an end-to-end pass without changing the
15-second heartbeat or 6,000 nominal-frame realm-entry budget:

- `net-local-flattened-1788835995`: moving the signal await up one RefCounted
  layer cleared the original RockShoulder boundary, then stranded after a later
  route continuation while 5,445 frames continued.
- `net-local-node-owned-1788836395`: making the world Node own the signal await
  changed the stranded boundary again; 6,000 frames continued, proving the
  full deep coroutine tree itself was unreliable rather than one helper call.
- `net-local-route-placeholder-1788836738`: sliced builds kept the authored
  visible/colliding route ribbons but deferred geological shoulders. It reached
  landmarks, where the first full visual landmark held a peer for >15 seconds.
- `net-local-mp-placeholders-1788837041`: named colliding landmark placeholders
  reached the post-environment cover/look boundary.
- `net-local-lightweight-look-1788837312`: omitting cover and post-build look
  dressing only in sliced multiplayer builds completed the first crossing,
  Cloudreach shell, cross-realm gathers and Meadows fight. The final swap then
  exposed a separate race: live Cloudreach and a Meadows shell began building
  concurrently in the host process.
- `net-local-transition-guard-2-1788837965`: `realm_shells.gd` tore down the
  soon-to-be-live Cloudreach shell immediately but deferred standing Meadows up
  until the host's announced current scene reported ready. **ALL CHECKS PASSED**.
  The client entered Cloudreach in 4,000 ms; the host Cloudreach shell was ready
  in 3,629 ms; the reverse host crossing completed in 17,423 ms without heartbeat
  silence; the final report held the expected Meadows shell and no Cloudreach
  shell.

The final teardown also logged the existing node-cache/RPC errors noted in the
status above. The smoke nevertheless completed its ordinary multiplayer transitions,
all unchanged-budget assertions, and cleanup; this is a green functional verdict with
a separately visible teardown-cleanliness follow-up, not a claim of an error-free log.

Solo Cloudreach remains unchanged. The intentionally reduced multiplayer visual
presentation is recorded in `docs/SECOND_PASS_BACKLOG.md`; the functional route
ribbons, bridges, regions, named landmark crowns and encounters remain present.
The sliced collision recipe now preserves the full build's exact 48x48 settlement
terrace, 38x36 observatory crown, and both differently sloped Waterward crown strips,
so the visual deferral does not replace those authored chapter surfaces with a generic
box. A deliberate full-live-visual experiment reached the gameplay mount after
83 seconds and then exceeded the unchanged heartbeat, confirming why that cosmetic
tree remains second-pass work.

## Final integrated timings

| Run | Client to Cloudreach | Client back to Meadows | Host to Cloudreach | Result |
|---|---:|---:|---:|---|
| `net-local-split-integrated3-1788843045` | 339 frames / 17.646 s | 1,367 frames / 65.026 s | 347 frames / 31.966 s | ALL CHECKS PASSED |
| `net-local-split-confirm-1788843300` | 338 frames / 16.257 s | 1,491 frames / 69.491 s | 346 frames / 33.554 s | ALL CHECKS PASSED |

Both are far below the unchanged 6,000-physics-frame cap and retain the unchanged
15-second heartbeat. An independent read-only re-review found no remaining P0/P1 in
the timeout, readiness rollback, frame accounting, sliced landmark collision, or CI
registration changes.
