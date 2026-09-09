# Lane 0 resume — Cloudreach rendered allocation failure

Date: 2026-09-08. Entry head: `452a4d63c`. Scope was the preserved
`Parameter "mem" is null` crash in `cloudreach_look.gd::_plant_tufts` only.

## Verdict

The original crash did not reproduce during one exclusive full-production render of
the entry implementation. That run completed **only stand 01** with all visible ground
cover enabled, produced its PNG and exited zero. The original failure therefore remains
unresolved and no production fix was committed. The three-stand output described below
came from a temporary batching candidate; it is auxiliary, unaccepted evidence and is
not entry-equivalent.

The leading hypothesis is memory pressure around the large number of small ground-cover
render allocations. It is a hypothesis, not allocator proof. The runtime currently has
1,684 ellipse patches and creates a near and far MultiMesh for most plantable patches.
The preserved failure happened while assigning one of those MultiMeshes to its render
instance. A small isolated probe successfully assigned the production tuft mesh at
16,000, 20,000 and 24,000 instances, ruling out those instance counts as an intrinsic
failure. An instrumented entry-code production run then attached all patch resources,
reported about 883 MB through `OS.get_static_memory_usage()`, and rendered successfully.

A batching candidate was investigated and rejected from production in this lane.
Whole-biome batching changes Godot's AABB-centre visibility-range behavior. A bounded
spatial-bin version can conservatively expand range and preserve transforms, but it was
not justified after the entry path succeeded exclusively. Both candidate and its small
invariant fixture were removed; `scripts/world/cloudreach_look.gd` is byte-for-byte back
at the entry version.

## Exclusive production result

Command (isolated APPDATA profile, Compatibility renderer, never owner saves):

```powershell
C:/Users/mattj/.cache/tetherbound-tools/godot-4.7/Godot_v4.7-stable_win64_console.exe \
  --rendering-method gl_compatibility --resolution 1280x800 --path . \
  --log-file .artifacts/lane0-full-profile-engine.log \
  --script res://.artifacts/wave6_cloudreach_visual.gd -- \
  --out=res://.artifacts/lane0-profile \
  --only=01-arrival --profile-realm-load
```

This entry-code diagnostic completed `mount` in 128,507 ms, captured
`01-arrival-first-reveal.png`, and had no `ERROR:` or `SCRIPT ERROR:`. The only warning
was the already-known `cr_candy_broken_route_good_07` surface-placement warning.

The immediately following three-stand capture also exited zero and completed all
frames. Its log is `.artifacts/lane0-fixed.log`; despite the historical local name,
this run used a temporary batching candidate that preserved exact transforms and
counts but changed culling behavior. It is auxiliary candidate evidence only: it is
not entry-equivalent, not accepted visual-audit coverage and not evidence for a shipped
fix. Images:

- `.artifacts/lane0-fixed/01-arrival-first-reveal.png`
- `.artifacts/lane0-fixed/04-high-roost-before-fly.png`
- `.artifacts/lane0-fixed/05-upper-cloudreach-cliffhold.png`

It had the same known candy-placement warning and no `ERROR:`, `SCRIPT ERROR:`, native
allocation error or crash. Arrival's local cover counts matched the instrumented entry
run exactly: main 282, far 48, fill-main 582 and fill-far 95.

## Confounded attempts — do not use as patch verdicts

The headless `smoke_cloudreach_look.gd` started at 19:12:17 local and ended at 19:15:23.
It overlapped another full-production Meadows process on an approximately 8 GB machine
whose pagefile peak reached 8.4 GB. It crashed with `realloc_static` / `mem_new` null
while growing the temporary whole-biome transform array. That is system-commit
confounded and is neither evidence against entry code nor proof of the batching cause.

A second spatial-bin smoke started at 19:16:16 local during the same unauthorized
full-world overlap. Root stopped its PIDs 22768/25024 immediately; its 73-byte log has
only the engine banner. It is explicitly interrupted, neither pass nor fail. No Godot
process remained after the stop. These overlaps were an operator error in this lane;
future full-world validation must hold the exclusive RAM lease.

## Next trigger

Proceed with the complete Cloudreach catalogue only under the exclusive RAM/render
lease. Reopen a production allocation change only if that exclusive run reproduces the
failure. If it does, the bounded-bin candidate is the narrow direction to re-evaluate:
retain exact seeded transforms and per-tier materials, use local spatial bins, and
expand each bin's visibility end by the maximum displacement from original patch AABB
centre to batch AABB centre so no original patch culls earlier.

Changed tracked file: this report only. Production and tests are unchanged.
