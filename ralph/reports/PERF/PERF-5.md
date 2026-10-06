Verdict: OPEN; Crossing Hall static batching is a disabled candidate, not a device performance or visual verdict.
Product: 45b1ce1d49cc7f00de45b3909638bc8d271d2402; existing static_mesh_batch.merge only, static_geometry_batching=false.
PortalSurface, PortalStoneInfill and DisplayedRelic are excluded; original actions, signs, approaches, light/material updates and collision remain independently controlled.
Existing Hall control at 45b1ce1d49: 1 test/17 assertions/0 failed/exit0, INVALID because the detached home membrane emitted two get_tree ERRORs.
Raw failed proof: realms/hall-batch-unit-first/{stdout.log,stderr.log,native.log,exit.txt,source.txt}; private homes remain local, original assertions retained.
The mounted control at 659f8595cb failed before all assertions: Engine main loop is null in runner _init; SCRIPT ERROR/leaks retained in realms/hall-batch-unit-mounted-first. This attempt is INVALID.
Approach changed to the original detached control/all17 assertions: home membrane now obtains a tree only while mounted, preserving its existing null-tree day fallback; corrected native check pending.
Medium1080p realm routes, Hall before/after visual equivalence, real draw/frame gain and one final independent review remain OPEN; no READY or flag flip.
