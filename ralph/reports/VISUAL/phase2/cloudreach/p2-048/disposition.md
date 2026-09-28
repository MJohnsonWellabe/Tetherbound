# P2-048 disposition

**Deferred. Owner: Shared map UI lane, with Cloudreach label coverage.** No fix or visual acceptance is claimed.

The clipped discovered-region label requires a shared map-callout layout change and device-profile verification across long labels and zoom states. No independently judged layout fix is available in this lane.

## Evidence and source audit

scripts/ui/tab_map.gd::_draw_region_callout builds a single-line gutter rectangle, then sends the full region display name to _draw_string_legible with the finite available width. _spread_callouts reserves a fixed vertical gap. Simply enabling multiple lines would also require collision/spacing work; shortening the region name would conceal the defect and change its authored identity. The catalog retains the original 1920x1080 map/HUD comparison.

Original capture IDs and reproduction provenance remain in `../../catalog.csv` and the biome manifest. This disposition preserves the unresolved defect; source inspection is not a visual PASS.

## Required follow-up

Implement measured wrapping or an explicit readable overflow treatment in the shared map callout layout. Recheck Cloudreach Gate / Lower Cliffs together with other long region/destination labels, map fit/local zoom and controller focus at 1920x1080. Do not claim acceptance from string presence in source.
