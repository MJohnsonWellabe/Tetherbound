# Map legibility contract recovery — 2026-09-08

## Finding

CI `34213024669`, unit shard 2, prints three script errors in
`test_map_legibility.gd` yet exits successfully. The full map lacks the
`CANVAS_OUTLINE_SIZE` and `MARKER_KNOCKBACK` constants those tests assign to
typed locals. Execution aborts before the assertions run. The isolated baseline
reproduces this: 13 tests, 21 assertions, exit 0, three script errors.

Type guards in `005c04f65` make missing values explicit failures without
changing any contrast, opacity or outline threshold. The resulting baseline is
13 tests, 24 assertions, three failures, exit 1, no script errors.

Targeted history identifies the loss at `b583e1d4b`, the earlier consolidation
that selected the Cloudreach map file wholesale after duplicate-function merge
conflicts. It predates this goal's minimap/corrupt-open rollback. This repair
does not restore the old legend layout or reverse Cloudreach's realm handling.

## Narrow production repair

Restore the original `ddf1f39af` map-specific outline size (10) and opaque
marker backing (`Color(0.04,0.06,0.07,1)`, three-pixel soft skirt). The actual
canvas draw calls use these constants; they are not unused test-only aliases.
Canvas label drawing again calls the existing tested `label_core_colour()`
function. The minimap already has this backing and remains unchanged.

Fog, discovery, realm selection, map texture lifecycle, zoom and controller
bindings are unchanged. No additional palette or layout iteration is proposed.

## Validation

- Map legibility: 13 tests, 32 assertions, zero failures and no script errors.
- Fog/discovery: 5 tests, 18 assertions, zero failures.
- Realm view: 8 tests, 36 assertions, zero failures.
- Zoom persistence: 3 tests, 9 assertions, zero failures.
- `git diff --check` passes.

Logs are `%TEMP%/root-map-legibility-baseline.log`,
`%TEMP%/root-map-legibility-failclosed.log`,
`%TEMP%/root-map-legibility-restored.log`, and
`%TEMP%/root-test_map_{fog,realm_view,zoom_persistence}.gd.log`.

Rendered first/second-open regression evidence and a code-blind recording
verdict are still pending. Numeric tests do not establish visual acceptance or
close the already deferred map-label crowding. The active CI run predates this
repair and cannot prove it.
