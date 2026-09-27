# F09#0: whole Stormwood chapter from the Cloudreach boundary (run 9 at d3414e84)

`godot --headless --path . --script tests/smoke_stormwood_continuous.gd -- --through-aftermath --witness-dir=user://storm_run9_d3414e84`

The run exited 0 with 0 SCRIPT ERROR. Log: `run9-d3414e84.txt`. Its last line is "stormwood continuous: OK — chapter-entry through the Stormheart kept and Waterward aftermath passed without Stormwood flag or position fixtures".

| Step | Result |
|---|---|
| Prefix: arrival through Ondra's arch recipe | PASS 1259.7 s |
| Capacitor Alpha, Crown gathering, two frames, paid Crown arch | PASS 2059.0 s |
| Crown arrival, guardian, Wen, Rootgate | PASS 195.2 s |
| Deepwood, rods, Kestrel, core ascent | PASS 1908.6 s |
| Marrow five rounds and the real four-conduit Break | PASS 344.4 s |
| Stormheart offer kept at five, Waterward aftermath | PASS 9.4 s |

**Six regions** (region bounds from `stormwood_world.json`, with the same lookup as `stormwood_surge.gd` `region_at`):
- **Cinder Verge:** "walk to Ashfoot Waycamp arrival", log line 77.
- **Glowmoss Hollows:** "Ash road toward Lantern Pools", line 106.
- **The Conductor Run:** "road to Rodline Post", line 168.
- **The Hollow Crown:** "TRAVELLED the actual paid Crown arch; Crown arrival earned".
- **The Deepwood:** `stormwood:lantern_hollow_reached`, `rod_deepwood_disabled`.
- **The Dynamo:** `rod_dynamo_disabled`, `core_reached`, and the helix climb ("ASCENT trace stage=3").

**Shortcuts (disclosed under the 06:58 owner ruling):**
- The start is the smoke's Cloudreach-boundary fixture: an in-memory completed-Cloudreach party and entitlement, then entry through the production realm router. It is not an earned Cloudreach save.
- Harness-driven input throughout: stick and button presses, with fights driven by the harness pilot.
- Helper routing for blockers B1–B8 (`ralph/reports/STORMWOOD/dry-run/BLOCKERS.md`). That includes rests at camps, the Crown-footing entry, fighting nearer wilds first, the plant-edge retry, and the approach-slab east lane with a direct heading.
- No Stormwood flag, position or party write.
