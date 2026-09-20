# Meadows payoff and co-op admission evidence

## Scope and provenance

Branch `ralph/meadows-payoffs`, stacked on PR134 (`ralph/first-expedition`) and the design PR132. Base before this slice: `1009f1345`. Runtime: Windows Godot4.7.stable.official.5b4e0cb0f; Compatibility captures used NVIDIA GTX1060 3GB,1280×800. This is bounded implementation evidence, not Meadows/chapter acceptance, Ally performance, invitation transport or a finished activity quota.

## Co-op admission

Commit `780d295b7`: `peer_registry.gd::admission_verdict` checks the actual host-inclusive capacity and a nonempty, edge-trimmed String identity before registry insertion, realm preparation or snapshot. A live identity cannot evict its current holder, including peer1. The character can rejoin once the previous peer row is removed. The existing ID format is preserved; there is no fabricated Steam/GUID requirement.

ENet admits one extra transport handshake socket so a full game can deliver its reason; the registry remains capped at the host's configured total. `session.gd` sends a specific rejection on the ledger channel and uses the existing six-frame close-flush lifecycle. JoinDriver surfaces that reason while preserving cold-host transport retries. Already-rejected senders cannot restart the timer or become admitted during its flush window.

Validation:

- Root-run existing unit runner, selectors `peer_registry,join_driver,multiplayer_identity`:16tests,81assertions,0failed. Agent's final targeted registry/retry checks also pass.
- `tests/smoke_net_identity_admission.gd`, two actual processes and shipping Session RPCs: final run exits0, all checks pass, neither peer log contains `ERROR:` or `SCRIPT ERROR`.
- A host with admitted cap1 refuses the spare socket in9frames with `This session is full (1/1).`; no snapshot applies and host registry/world hash remain unchanged. This is a compact capacity-boundary test, not a five-machine trial.
- Rehost at cap4; a joiner claiming the host's identity receives the readable conflict in9frames; no snapshot, inactive rejected client, unchanged host registry/world. A distinct legal identity then joins and applies its snapshot in10frames.
- First attempt exited1 because the smoke looked for a top-level field that the existing harness wraps away. The returned detail and peer logs already contained the correct refusal. The assertion was corrected, transient-retry handling reviewed, and the full scenario rerun successfully.
- The final repeated-hello guard was added after the successful world run, reviewed and parsed; its specific adversarial sequence was not replayed.

Local raw run: `%TEMP%/identity-admission-final-1789869559/`. Retained `admission-run.json` and peer logs identify the precommit HEAD865025cfd plus the working-tree admission diff. They must not be described as a clean865025cfd run.

Limits: no lossy-network acknowledgement guarantee, authenticated platform identity, build/protocol/content compatibility,120s reservation, Steam binding, lobby, invite UI or cross-router witness. Those remain required future work. This closes a concrete admission defect; it does not deliver invitation co-op.

## Cart presentation

Commit `fbb709c4e`: `cart_repair.gd` now uses one WagonAssembly for the existing wagon mesh and its solid collision. Cart-only metadata in `building_prefabs.json::prefabs.cart_repair_patch.presentation` specifies an11° broken lean,0.19m lift, repaired local offset[-0.9,0,2.3], repaired yaw−25°, and1.1s transition. The source site remains[80,1240], yaw40°. The terminal wagon sits farther onto the shoulder at world yaw15°, with installed timber/rope repair pieces; small stone chocks remain at the old seat. Existing village wagons and shared materials are unaffected. Coll's completion line now describes a completed repair.

Restoration applies the saved flag's terminal pose without replaying the animation; false state resets the broken pose. Collision moves/rotates with the assembly. No new NPC, currency, item reward, road gate, mesh or purchase was added.

`tools/capture_cart_repair.gd` reuses the production catalogue survey, world, trainer, HUD and camera. It debug-travels to fixed stands and deliberately injects the cart flag for before/after views. Its manifest discloses this. These captures cannot prove an earned turn-in, walkable approach, save roundtrip or late join.

Initial production baseline showed a pristine wagon before completion. First changed capture showed the damaged lean, but the repaired5m displacement made the wagon smaller and harder to read. A code-blind lower-tier review rejected the payoff readability and both broad visual bars. The final correction halves that displacement, turns the wagon into a three-quarter view, and makes the chocks smaller/darker. The initial critique remains valid evidence of the broader road/foliage/depth gaps; a local prop change cannot close those bars.

Final capture:6/6 frames complete. Senior inspection accepts the bounded presentation correction: the repaired cart remains identifiable at comparable near-view scale, the close view shows a contained wheel repair, and the smaller darker chocks read as work traces. `_sheet-final.png` pairs all three stands before/after; `_sheet-first.png` preserves the rejected first round. `cart-capture.json` records actual body/camera poses. No `SCRIPT ERROR`; the normalized distinct engine-error set matches the baseline's GLES shutdown leaks. This is not a second independent BarA/B pass.

The blind first-round review's three largest gaps were: (1) ambiguous small/end-on repaired-cart silhouette, (2) disconnected-looking dirt patches and uniform grass obscuring road/contact, and (3) repeated tree wall/weak depth and subject hierarchy. It answered BarA **No**, BarB **No**. The later pose correction addresses the first local issue; road, ground, foliage, depth and broader activity staging remain open. Still frames do not establish movement, collision feel, repair timing, normal approach, companion behavior or handheld performance.

`tests/smoke_local_requests.gd` exits0 and all five activities pass, including the real cart's empty-hand refusal, exact one wood/stone/fiber cost, bounded animated terminal pose, attached collision, visible parts, restore and disabled prompt. This cart fixture calls the existing `_on_tried` directly and supplies materials; it is not a controller approach or earned-gathering witness. The first invocation caught a SceneTree test typo (`get_node_or_null` belonged on `root`); corrected before the runtime rerun. No shipped code parse failure was involved. The successful run has no `SCRIPT ERROR` and retains the baseline dummy-renderer shutdown leak types. A passing restore-seam assertion is not a disk or network witness.

**Inherited transaction defect remains open:** `_on_tried` requests a world flag, then spends local wood/stone/fiber even when the request is only pending. Concurrent peers can both pay for one world fact; refusal/disconnect can strand the payment. The visual work does not make this atomic. A focused turn-in transaction must replace this split before co-op activity acceptance. Coll is a dialogue speaker without a world body; WORLD's former visible-Coll wording was corrected explicitly, not silently implemented with a new NPC.

## Integrated local verification

`tests/smoke_playground.gd` exits0 with `smoke: OK` after both changes. No `SCRIPT ERROR`; normalized distinct `ERROR:` set equals the previous first-expedition world baseline, including its null-material/dummy shutdown errors. No claim of a clean engine log. JSON parsing and scoped `git diff --check` pass; STATE remains under25KB. Root ran smokes serially with isolated APPDATA profiles; renders used the free shared render lock and no headless/driver combination. All engine processes exited and the render lock was released.

Commands, from the repository with the installed Godot4.7 executable:

```text
godot --headless --path . --script tests/run_tests.gd -- --only=peer_registry,join_driver,multiplayer_identity
godot --headless --path . --script tests/smoke_net_identity_admission.gd
godot --path . --rendering-driver opengl3 --resolution 1280x800 --script tools/capture_cart_repair.gd -- --biome=meadows --output=<fresh-output-dir>
godot --headless --path . --script tests/smoke_local_requests.gd
godot --headless --path . --script tests/smoke_playground.gd
```

The two-peer run sets a unique `TB_NET_RUN_ID`/`TB_NET_OUT_DIR`; the existing harness isolates peer profiles. Retained logs: `local-requests.log`, `playground.log`, `units.log`, `admission-host.log`, `admission-client.log`. Renders/logic ran on the relevant working-tree source before its commit, not an exported package. No full campaign, owner fun check, device test or packaged-build claim follows.

## CI and next blocker

PR134 run35481978049 unit shard3 failed because the sparse CI checkout omitted eight committed Meadows review receipts read by `test_meadows_named_location_ledger_0912.gd`. All four manifest blobs parse with `complete=true`; all four review blobs exist and contain their historical PASS. Commit `865025cfd` materializes exactly those tracked text blobs, leaving the test and historical evidence unchanged. Its workflow blob equals the previously unmerged fix at `a2d2f9d12`; both that commit and `db67c2d6c` were absent from main. The fix is pushed to PR134 as well as included in this branch. Historical PASS text is not new visual acceptance.

The same CI's region job106001595537 reports Warrens egress stopping15.53m short at local[0,0.35,-25], four haze cards against a six-card assertion, and Root_5/Root_6 at1.11m/1.58m above floor. `scripts/world/burrow_warrens.gd`, its config and `tests/smoke_warrens.gd` are unchanged from origin/main in this stack. Classify/reproduce those failures next; do not waive the egress failure or assume every visual count is still the right contract. The checkout repair does not fix them. CI/package acceptance remains open.

Read-only follow-up establishes one stale expectation: `burrow_warrens.json::haze` deliberately contains four pool cards. Its R29 comment says the doorway card was removed because it intersected the production threshold camera; the R17 comment removes rejected crossed shaft cards. The latest config commit is44056970f. Do not add rejected planar haze back merely to satisfy the smoke's old minimum-six count. This finding does not resolve egress or establish whether Root_5/6 intrude on a traversable lane.
