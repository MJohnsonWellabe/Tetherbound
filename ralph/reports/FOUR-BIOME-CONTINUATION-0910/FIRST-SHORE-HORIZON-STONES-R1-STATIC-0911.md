# First Shore Horizon Stones — R1 static recovery candidate

## Route-order identity

The authoritative Water catalogue's next entry after `first_shore__01__first_shore_welcome_beacon` is `first_shore__02__first_shore_horizon_stones`, backed by `water_world.json` landmark `first_shore_horizon_stones` at `(-63.636, 24.812, 75.838)`.

## Baseline disposition

`STALE / POLISH-GAP`. The accepted day and night frames preserve one of Water's better broad depth reads: separated islands and the distant pointed Veilfall mass. The Water judge nevertheless records little detail or activity distinguishing those layers, and the named “Horizon Stones” have no visible authored stone subject in the frame. Near-to-far scale is almost entirely bare grass, water, and repeated island caps.

## Bounded candidate

- Preserve the accepted northward viewpoint and its distant island/Veilfall orientation.
- Place an asymmetric three-stone aperture 20.66 m ahead: 6.8 m west marker, 5.4 m east marker, and a 1.65 m sighting stone on the open center axis.
- Reuse installed natural-rock assets; do not add a shrine primitive or new art family.
- Add two small warm base practicals, each capped at 0.76 energy / 7 m range, to retain the stone edges and trainer ground at night without flattening the horizon.
- Keep the full 10.5 m visual footprint clear of the authored four-metre exploration spine and add no collision.

## Static evidence

- `data/config/water_first_shore_horizon_stones.json` owns only the viewpoint-relative visual arrangement and light budget.
- `scripts/world/water_first_shore_horizon_stones.gd` terrain-fits three installed stones and two base practicals.
- `scripts/world/water_world.gd` mounts the presentation only in the normal visual build.
- `tests/test_water_first_shore_horizon_stones.gd` verifies route clearance, heading alignment, asset existence, silhouette hierarchy, finite grounding, bounded lights, zero collision, production mount, and unchanged landmark data.
- `tools/capture_water_first_shore_horizon_stones.gd` defines three day/night production views. It was parse-checked only; no frames were produced in this lane.

## Expected disposition

`POLISH` floor, pending fresh production frames. The candidate supplies the missing named foreground identity while deliberately retaining the strongest part of the baseline—the open horizon. It is not claimed `PASS` until production evidence confirms that live vegetation and creatures do not occlude the aperture and that the installed rock silhouettes remain distinct against both day sky and night sea.
