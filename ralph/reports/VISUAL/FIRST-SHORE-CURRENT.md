# First Shore's current boundary — draft visual repair

X04 / WORLD §6.3 and §6.6; owner explicitly rejected the freestanding First
Shore fence because it does not prevent access. Causal repair `d3c3764af`, wave
iteration `1560de9ef`, with main `b81b4fdab` integrated. PR #329 stays draft:
**environmental crossing-state clarity does not pass**. The owner redirected
effort to coverage of the whole game's visuals; this local iteration is parked
with the failed criterion explicit. Claude owns merges.

## Reproduced cause and change

The ten-metre fence stood roughly thirteen metres inland on a much wider
beach. It could be bypassed on either side. Existing progression enforcement
comes from the six-metre-per-second adverse route current and the outward tide
race around Reedhaven, both controlled by `water_swim_lesson_complete`.
The current renderer ignored that flag and displayed the authored open speed.

Only First Shore's fence **and collider** are retired. This is explicitly a
small collision removal; it is not described as presentation-only. The six
other mandatory dock blockers remain. A compact installed-family timber notice
beside the approach reports the existing route state and persists after opening.
A shared-family lantern lights its shaded lettering. No new transaction,
interaction, entitlement or current strength is introduced.

The current renderer binds the same closed-dock and exact return-shortcut facts
as physics, refreshes when effective velocities change, and rebinds replacement
world flags. Final restoration applies each route's multiplier once. The foam
pattern now uses raised, advected wave patches and wet faces beneath individual
crests. Stable authored-corner joins precede subdivision, avoiding folded inner
bends. This iteration remains visually insufficient.

## Verification

- Focused current-field, current-view and notice tests on `1560de9ef`: **15 tests, 502
  assertions, zero failures**. Includes shared physics parity, live flags,
  replacement-world reload, effective shader motion, notice grounding and
  clear approach, no notice collision or progression writes. Actual production
  bend winding and perpendicular widths pass: 57,096 shared vertices / 101,152
  triangles, zero inverted triangles. This is geometry evidence, not Ally cost.
- `smoke_tidewake_b_current_restore.gd`: **20 checks, zero failures**; production
  Guardian settlement, world save/load and retained calmer physics/presentation.
- `smoke_water_first_shore_current_gate.gd`: **zero failures**. Real production
  scene; First Shore collider absent, other six blockers present. One initial
  position fixture at the authored sheltered-current centre, then ordinary
  forward input. Closed attempt z217.9999 →210.5765; same swimmer after the
  directly posed existing lesson flag z211.1832 →221.7093. This proves bounded
  current rejection and opening, not earning the lesson or complete crossing.
- An earlier probe at x0/z220 reached an overlap/edge balance point instead
  of sustained pushback. The revised smoke deliberately tests the authored
  sheltered centre x−9.6. Per-route full-strength visual encoding does not prove
  exact spatial overlap/edge parity or close every possible flank.
- Twelve native Windows 1920×1080 Compatibility captures under
  `shots/shore-current-r5` compare closed/open overview, notice and water by day
  and night. Production camera, teleported stands and directly posed flags are
  disclosed visual fixtures. Godot 4.7 `5b4e0cb0f`, GTX 1060 3 GB, driver 560.94.
  No script/shader errors; deprecated interpolation and portal resource-UID
  fallback warnings remain. Portal textures resolve by their text paths.
- Buffered native temporal capture: 48 frames per state. Closed spans 7.770 s
  (120–272 ms sampling intervals); open spans 8.210 s (117–333 ms). Local GIFs
  preserve measured intervals. Sampled frames show crest movement and calm-state
  contrast; they do not certify continuous motion quality or target performance.

![Draft closed/open shore comparison](_sheet_first_shore_current.jpg)

## Independent review and unfinished acceptance

`shore_portal_review` passes the r5 source: First Shore-only removal,
unchanged current/lesson authority and other docks, correct per-route state
adapter, landward physical notice and reload handling. Review caught 81 inverted
triangles in an earlier densely sampled strip; authored joins fixed all of them,
independently checked against production geometry. Shader normals approximate
longitudinal slope; transverse/packet derivatives are a quality limitation.

Code-blind `shore_current_blind_judge` inspected r5 day/night frames, sequence
samples and the Tidewake/Veilfall, Meadows and Palworld references. It accepts
the unobstructed notice in the inspected ordinary-camera compositions and
recognizes calmer open water. R5 integrates better than r4, but long smooth
angular ridges still resemble translucent sheets; the disturbance can read as a
route, and repeated distant tide-race puffs remain. It does **not** accept the
water effect or environmental crossing-state clarity.

Whole-frame A is **no**. B is **yes only for recognizable genre ambition**, with
an explicit failure of shipping-quality parity; this is not a visual-bar pass.
Broad empty sand/sky, engineered cliff walls, sparse stippled foliage, glossy
creature versus dark props, oversized rope and disconnected paving remain.

Further wave tuning is deferred while the broader visual coverage resumes.
Water/shore integration, full closed-route flank proof, mounted/guest movement
and Ally performance remain open. Portal replacement was separately merged as
PR #328 and is included in this capture's main baseline.
