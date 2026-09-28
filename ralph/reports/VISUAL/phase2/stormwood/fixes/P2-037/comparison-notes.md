# P2-037 native comparison coverage

The retained first comparison contains six baseline exterior frames, six
candidate exterior frames and five candidate route frames. The route baseline
is retained in `../catalog-baseline/routes/`. Every source frame is native
1920 x 1080 on Windows Compatibility; manifests identify the source commit,
reproduction command, source image hashes and compact sheet tiles.

The exterior pairs have identical camera positions. The five route pairs
have a maximum camera-position difference of 0.0001071 m. Phase and aftermath
state match within each pair. These checks establish comparable fixtures,
not visual acceptance. The candidate remains disabled.

The four frames from `p2037-after-locations-r1` are excluded. Restricting the
location helper to two destinations changed the neighboring destination used
for its fallback heading. The frame IDs stayed the same, but cameras differed
by as much as 73.81682 m. `comparison-coverage.json` retains all four camera
comparisons and the rejected manifest hash. Those images cannot establish
before/after improvement. The correction is an exact replay of the original
12-destination, day/night, approach/close command, with only the output path
and temporary candidate activation changed.

The exterior helper uses declared 400 m and 100 m stands, debug travel,
phase/clock pins, healing and an aftermath fixture. Location and route helpers
use their existing debug travel fixtures and production camera. None proves
earned arrival or campaign progression. The original close location views
are beneath elevated architecture; exterior evidence is needed to judge the
whole tree. P2-037 remains open until its complete visual defect is resolved.
