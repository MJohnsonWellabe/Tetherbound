# r48: Ashfoot storm room light + window patch + Stormwood dressing (CPU, code-blind, 27 Oct): GAIN +0.94, arm m48

**Arms:** the Ashfoot inside stand, all four phases. The lane has storm_view ON (GPU SW16, 6.96).
- **OFF:** the current room (r47's OFF frames; the lane changed only in main's creature and board files since).
- **ON:**
  - `storm_room`: r47's window wash and dimmed hearth and room lamp, plus the new `window_patch` (the window's 3x2 pane pattern on the west wall, level 0.12 / 0.3 / 0.6 / 0.2 by phase, lifted by the surge flash).
  - `stormwood_dressing`: dark blue-green moss clumps along the wall plates, tie beam and sill with short tufts; three small storm-glass crystals (the Glass Field Meshy crystal, no glow) on the sill and shelf; a copper lightning rod; a copper chain coil.

**Result:** mapped **5.37 -> 6.31 (+0.94)**. 3/3 judges prefer ON: 5.0/6.0, 5.0/6.0, 5.4/6.2. Linear fit r 0.62, slope 1.01, no warnings.
- **Warm room, no storm light:** PRESENT 3/3 -> **PARTIAL 3/3**. "Building and break cast cool violet window-light patches on the left wall; break the clearest white-violet shafts."
- **Nothing says Stormwood:** PRESENT 3/3 -> **PARTIAL 3/3**. Moss, crystals and the rod are credited (one judge read the rod as a broom). "No copper" stays: the rod and coil are small at this lens.

**Remaining asks:**
- the hearth's warm orange still dominates the base grade;
- the moss reads as evenly spaced beads;
- the left wall goes flat lilac in break and loses grain;
- larger copper/glass storm gear;
- a visible storm sky through the window from this lens.

**Hard rule note (Team Tether colour):** one judge (both arms, unchanged) saw "a small dark-red bracket or object on the back wall right of the fireplace". It is on main already, not part of this arm. Lane follow-up: identify and recolour it if it is a kit piece in red.

**Checks on the arm config:** `smoke_stormwood_ashfoot_shelter.gd` 16 checks, 0 failed, no script errors (shelter roof and lightning shelter unchanged inside, at 11 m and at 60 m).

**Arm:** `tb/stormwood-m48-on` ebcae6ed. It is lane HEAD with `storm_room` and `stormwood_dressing` ON.
