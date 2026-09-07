# Phase 1 integration brief

Implementation base: main `e78f2ab45f5d22bbf2ffcbb0394bd5b17b99f779`; owner-reference PR 68 landed after its code jobs passed and ancestry was verified. Root owns integration and the physical realm seam. No Water or other art branch is part of this landing.

## Bounded lanes after the reference landing

1. Root: Cloudreach reward/dialogue retarget, Stormward Overlook display and physical descent/gate, namespace scopes, legacy and split-world entitlement reconciliation. Keep internal Cloudreach landmark/pickup IDs to preserve discoveries and one-time claims. Add Stormwood key and reveal; retain legitimate Water rewards only when earned by the later Stormwood finale. Gate writes must retain host authority and carry their owning realm explicitly.
2. Map lane: replace the two-realm map selection assumption with configured realm map definitions. Preserve Cloudreach wrapper and its tests. Each player owns independent fog and map objects for each realm. The third-map test must prove actual round-trip payload isolation, including legacy single-map ownership. Root serializes this lane's PlayerState/save edits with all other shared-state work.
3. Relic/curve lane: Wings of Cloudreach with Skyborne through the existing one-active-relic selection; real launch, glide and climb stamina costs use the selected power. Selecting another relic restores ordinary costs. Level cap 100 changes no earlier XP curve. Exercise production cost paths and bounded curve calculations. Root integrates relic registry and shrine presentation after map lane's shared edits finish.

## World boundary for entry evidence

The Stormwood root is `Stormwood`, with the existing player/camera/HUD/spawner node conventions and explicit shell ownership. Terrain3D collision and baked installed-family forest scatter are present at first playable entry. Entry arrives beneath the canopy, with Struck Sentinel and the distant split Stormheart Tree establishing direction. A shell keeps collision and authoritative services while suppressing local camera/HUD/input ownership. The gate remains locked without its entitlement; a client requests world mutation, never writes a fallback unlock after a server rejection.

The future world footprint is x[-2560,2048], z[0,6144], 2 m Terrain3D spacing with 256-sample regions (108 aligned regions). Region names and their nineteen named landmarks follow §12. Six-region composition and full route authoring remain root work. No forest assembled from primitive cylinders is accepted. New roster boards supply future replacement references; installed creature bodies remain placeholders under the owner's explicit mesh restriction.

## Baseline runtime evidence

The elevated `tests/smoke_realm_teleport.gd` run exited 0 and printed `REALM TELEPORT OK: OP-0905-20 loading overlay, OP-0905-21 cross-realm debug teleport`. It constructed Meadows and Cloudreach. No script errors occurred. The log contains repeated missing male/female villager hair-mask imports, one unresolved Cloudreach placement warning, and texture mipmap warnings. These are baseline limitations, not Stormwood acceptance evidence. Log: `D:/Tetherbound-source/stormwood-baseline-realm-smoke.log`.

## Acceptance for the integration wave

Physical keyed entry and return, correct active realm and personal map after each transition, completed old Cloudreach saves receiving the new entitlement once, legitimate future Water ownership preserved, Wings cost behavior and clean power swapping, cap-100 curve safety, and host/client late-join agreement. Targeted checks come first; shared save/autoload edits require the full suite before this phase is claimed closed. A configured destination or a passing pure-data test alone earns no playable-entry score.
