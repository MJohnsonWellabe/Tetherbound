# Branch archive (27 Oct 2026)

Owner, 27 Oct: "Get everything on main so I can delete all the branches other than main and this scoring branch."

Every branch below is merged into main as history only (an archive merge that keeps main's files unchanged). Every commit of every branch is reachable from main, so the branches can be deleted with nothing lost. Shipping code and config on main are untouched: the experiments that are off, rejected or unjudged stay out of the game.

To recover a branch's files: `git show <head>:<path>`, or `git checkout -b <name> <head>`.

Kinds of branch:
- **Lane trunks** (`tb/meadows`, `tb/stormwood`, `tb/creatures`, `tb/creatures-land`): experiments that are off, plus lane notes and round evidence.
- **GPU arms** (`*-on`): one change switched ON, for GPU judging. Unjudged arms: `tb/co12-on`, `tb/co14-on`, `tb/stormwood-m52-on`.
- **Landing branches** (`*-land*`): content already on main, or superseded by a later landing.
- **`tb/gpu-pass`:** all GPU judge files and contact sheets.
- **`tb/meshy-1024`:** Meshy assets and their provenance.

| Branch | Head | Last commit | Commits not on main | Files differing from main | Last commit subject |
|---|---|---|---|---|---|
| `tb/archive-2026-10-23` | `e4e8ecdec374` | 2026-10-23 | 547 | 0 | Archive: every branch not merged into main on 2026-10-23 |
| `tb/co10-on` | `fb6a2593b970` | 2026-10-27 | 1 | 1 | dog3 Terrapup r5 (CLOSE-OUT, on main): the large dog with a browner coat and small plates grown along the spine |
| `tb/co11-on` | `2b4f2256e241` | 2026-10-27 | 3 | 3 | Ripplet matte countershaded coat (near-bar close-out) |
| `tb/co12-on` | `6faa34c65862` | 2026-10-27 | 5 | 8 | CO12 = CO14: Cliffspike and Voltwig flinch, Nightburrow faint flame, Thundertunnel value lift |
| `tb/co13-on` | `685f250cf24c` | 2026-10-27 | 1 | 2 | Ripplet matte countershaded coat (near-bar close-out) |
| `tb/co14-on` | `134bf046dc28` | 2026-10-27 | 3 | 8 | Thundertunnel fur value lift (near-bar close-out, CPU b63 +1.10) |
| `tb/co3-on` | `33ba3f2a2bc8` | 2026-10-26 | 1 | 6 | CLOSE-OUT creatures (CO-3, on main): one shared subtle rim for every species, one faint settle rule |
| `tb/co4-on` | `4c35d5d7eba4` | 2026-10-26 | 2 | 12 | Tanglevolt arcs (CO-4, on CO-3): crisper, white-violet cores at emissive strength 3.0 for a tight GPU bloom |
| `tb/co5-on` | `e78759f17bbc` | 2026-10-26 | 1 | 6 | Tanglevolt arcs (CLOSE-OUT, on main): thicker, white-violet arc cores at emission 5.0 |
| `tb/co6-on` | `f3664d8e2585` | 2026-10-26 | 2 | 7 | Galecrest matte finish (CLOSE-OUT, on main): drop the x1.35 value lift, rim 0.25 -> 0.1 |
| `tb/co7-on` | `e6225b2153de` | 2026-10-26 | 2 | 2 | Grounded flinch for Cloudfang, Breezetail and Stormcapra (CLOSE-OUT candidate, CPU b50 judging) |
| `tb/co8-on` | `7e6b868d72e0` | 2026-10-26 | 3 | 2 | Stormcapra faint: roll -90 (side-lie facing the camera) instead of +90 (CLOSE-OUT candidate, CPU b51 judging) |
| `tb/co9-on` | `033a66f6a2a6` | 2026-10-27 | 2 | 7 | Mirejaw grade source: main's original albedo beside grade_fill.py, so the arm regenerates its own texture |
| `tb/creatures` | `1c383af7e292` | 2026-10-27 | 161 | 422 | CREATURES note: READY to land land15+land16 (99ec42eae); handoff, lane stopped |
| `tb/creatures-land` | `3d354b785050` | 2026-10-27 | 81 | 217 | CREATURES b63 verdict: Thundertunnel value lift +1.10 (confirming) |
| `tb/creatures-land-grandpa` | `f1209f09cf2d` | 2026-10-25 | 2 | 0 | F36#0 Grandpa eyes ship: art.json records the GPU verdict (tb/gpu-pass 9099a88322, 7.20 vs installed 7.09, all three judges preferred the ey |
| `tb/gpu-pass` | `5c6aa7489bab` | 2026-10-27 | 92 | 1353 | GPU queue: per-item biome card scores job (for when the owner resumes the lane) |
| `tb/item-scores-cs` | `87ab3ccebbb9` | 2026-10-27 | 2 | 4 | Cloudreach/Stormwood item scores: lane started (in progress) |
| `tb/item-scores-meadows` | `905c63638ba3` | 2026-10-27 | 2 | 3 | Meadows item scores: lane started (in progress) |
| `tb/meadows` | `831dcd6bdc5f` | 2026-10-27 | 186 | 459 | Meadows NOTE: wind-down handoff (state, path to 7.5 from MH9, road ruts MESHY, runbook) |
| `tb/meadows-land10` | `0133455e34ad` | 2026-10-25 | 1 | 1 | F38 tier-1 camera fixture plus baseline dressing fix (supersedes land7) |
| `tb/meadows-land11` | `89c5b91f64e4` | 2026-10-25 | 1 | 8 | F38 tier-1 new art wired OFF: Hall arch facades, stronghold gatehouse, Meadows cliffs and Ironwood trees |
| `tb/meadows-land12` | `a634da3791ec` | 2026-10-25 | 1 | 0 | F38 tier-1 camera fixture plus baseline dressing fix (supersedes land10 and land7) |
| `tb/meadows-land14` | `47ea49dca280` | 2026-10-25 | 1 | 4 | F38 tier-1 hero bundle 2 (all OFF for the GPU pass): lit keep, war banners, courtyard declutter, giant ironwood |
| `tb/meadows-land16` | `cd6927c915e4` | 2026-10-26 | 1 | 155 | F38 L4 / P2-005: Meshy ground-cover tiers and blade carpet, wired OFF (land16) |
| `tb/meadows-land2` | `0a88dd931021` | 2026-10-24 | 1 | 2 | F17#6 GPU: great-hall shafts off and arch rims dimmed on Forward+/Mobile; Compatibility unchanged |
| `tb/meadows-land3` | `4d204e4020e7` | 2026-10-24 | 1 | 1 | F17#6 GPU: no daylight shafts on Forward+/Mobile; Compatibility unchanged |
| `tb/meadows-land4` | `62e64e6bfeca` | 2026-10-24 | 1 | 1 | F38 L1 fixture: in-room Hall arch stands, Hall floor stands, per-view heading seats |
| `tb/meadows-land5` | `d9f675f3bdde` | 2026-10-25 | 1 | 1 | F38 L1 fixture: in-room Hall arch stands, Hall floor stands, per-view heading seats |
| `tb/meadows-land6` | `3e06c8ddff78` | 2026-10-25 | 1 | 47 | F04#6 r31: Meshy aftermath heroes as an OFF candidate (meshy_heroes_enabled) |
| `tb/meadows-land7` | `1edc159aef5b` | 2026-10-25 | 1 | 1 | F38 L1 fixture: legal camera stands, and --f38-baseline keeps shipped dressing |
| `tb/meadows-land8` | `7472798460dc` | 2026-10-25 | 1 | 8 | F38 tier-1 new art wired OFF: Hall arch facades, stronghold hero gatehouse, Meadows hero cliffs and Ironwood trees |
| `tb/meadows-land9` | `18d660876f7b` | 2026-10-25 | 1 | 8 | F38 tier-1 new art: Hall arch facades ON (CPU-provisional), gatehouse and Meadows hero pieces OFF |
| `tb/meadows-r6b-on` | `f6b946e47f94` | 2026-10-27 | 173 | 452 | Meadows r6b arm: stronghold spire + MH3 courtyard daylight and war banners ON (GPU candidate) |
| `tb/meadows-r7-on` | `0d8ef6dd2571` | 2026-10-27 | 179 | 455 | GPU arm: stronghold r7b ON (keep + spire, window-grid masks) with MH3 (courtyard daylight + war banners) ON |
| `tb/meshy-1024` | `299f3d7abd88` | 2026-10-27 | 28 | 410 | Meshy 1024: meadows_stronghold_spire (coordinator-generated for the lanes' MESHY requests; unwired, flag-off, unjudged) |
| `tb/stormwood` | `e7c9fd819d64` | 2026-10-27 | 83 | 94 | Stormwood handoff: READY land16 (P2-081 + P2-083), per-item F41 status, parked approaches |
| `tb/stormwood-land13` | `de5e5f850862` | 2026-10-26 | 1 | 1 | Stormwood land13: Ashfoot storm view ON (GPU SW16 +1.13) |
| `tb/stormwood-land4` | `4047308eafd0` | 2026-10-25 | 1 | 0 | Add Godot uid for the Ashfoot shelter smoke |
| `tb/stormwood-land5` | `90140cf6d9b5` | 2026-10-25 | 2 | 9 | Stormwood: heartstone presence candidate OFF (r16: no gain) |
| `tb/stormwood-land6` | `2f3e3fef937a` | 2026-10-25 | 1 | 9 | Stormwood land6: item 6 r16 batch (land5) + r18 Meshy candidate (flag-off) |
| `tb/stormwood-land6-on` | `1680e579f5ad` | 2026-10-25 | 2 | 9 | Stormwood land6 GPU candidate arm: r18 Meshy flags ON (heartstone hero, Stormheart meshy_interior, Ashfoot lining + hearth) |
| `tb/stormwood-m22-on` | `3ba59882989e` | 2026-10-26 | 1 | 1 | Stormwood r22 GPU on-arm (merged main): authored ground zones ON |
| `tb/stormwood-m25-on` | `72eaa19cac3b` | 2026-10-26 | 1 | 1 | Stormwood r25 GPU on-arm (merged main): Ashfoot storm finish + grade + pane ON |
| `tb/stormwood-m28-on` | `5d8167b15a3e` | 2026-10-26 | 1 | 1 | Stormwood r28 GPU on-arm (merged main): Fallen Giant hero ON |
| `tb/stormwood-m28b-on` | `5a3477e0e165` | 2026-10-26 | 1 | 1 | Arm: Fallen Giant hero ON (collider, moved clear of the road); from the merged head |
| `tb/stormwood-m28c-on` | `39af61624e6e` | 2026-10-26 | 1 | 2 | GPU arm m28c: Fallen Giant hero ON + moss bark ON + rod line stand_clear ON |
| `tb/stormwood-m29-on` | `e59d5de13280` | 2026-10-26 | 1 | 3 | Arm: SW7 follow-up bundle ON (heart cleft, low Fading steam, heartstone survey stand 8 m); from the merged head |
| `tb/stormwood-m29b-on` | `9517727f4ba8` | 2026-10-26 | 1 | 3 | GPU arm m29 (rebuilt on the lane after main #760): Arm: SW7 follow-up bundle ON (heart cleft, low Fading steam, heartstone survey stand 8 m) |
| `tb/stormwood-m30-on` | `58d995cb5bef` | 2026-10-26 | 1 | 1 | Arm: Lantern Pools hollow ON (grove, raised basins, glow fungi); from the merged head |
| `tb/stormwood-m31-on` | `ccdeebfd0a96` | 2026-10-26 | 1 | 2 | Arm: ground pass 2 (moss + black pools, no loam) and storm light ON; from the merged head |
| `tb/stormwood-m31b-on` | `946ded35a1db` | 2026-10-26 | 1 | 2 | GPU arm m31 (rebuilt on the lane after main #760): Arm: ground pass 2 (moss + black pools, no loam) and storm light ON; from the merged head |
| `tb/stormwood-m33-on` | `619dd7fdd073` | 2026-10-26 | 1 | 1 | Arm: Lantern Pools finish ON (Meshy lantern posts, black pools) |
| `tb/stormwood-m33b-on` | `c8c981b23ba7` | 2026-10-26 | 1 | 1 | GPU arm m33 (rebuilt on the lane after main #760): Arm: Lantern Pools finish ON (Meshy lantern posts, black pools) |
| `tb/stormwood-m34-on` | `4c6d0756690d` | 2026-10-26 | 1 | 1 | GPU arm m34: Ashfoot storm_finish.seated ON |
| `tb/stormwood-m35-on` | `16101403bd06` | 2026-10-26 | 1 | 1 | GPU arm m35: Ashfoot storm_finish.seated + firelit ON |
| `tb/stormwood-m36-on` | `6c9ba8743c7c` | 2026-10-26 | 1 | 1 | GPU arm m36: Ashfoot seated + firelit + storm_view ON |
| `tb/stormwood-m36b-on` | `0a633e222477` | 2026-10-26 | 1 | 1 | GPU arm m36 (rebuilt on the lane after main #760): Ashfoot seated + firelit + storm_view ON |
| `tb/stormwood-m39-on` | `de3d78ffd236` | 2026-10-26 | 7 | 9 | GPU arm m39: Stormwood path posts ON |
| `tb/stormwood-m41-on` | `aa74c99787bb` | 2026-10-26 | 12 | 15 | GPU arm m41: Crown Overlook vista (deck + Hollow Crown silhouette) ON; F41 survey stand on the deck |
| `tb/stormwood-m45-on` | `94adcb41228d` | 2026-10-26 | 32 | 39 | Stormwood m45 arm: storm-cloud form + distant skyline ON (GPU candidate) |
| `tb/stormwood-m45b-on` | `9e2642f9d409` | 2026-10-26 | 42 | 49 | Stormwood m45b arm: storm-cloud form + distant skyline ON on the merged lane (GPU candidate) |
| `tb/stormwood-m45c-on` | `8a22c917b3b1` | 2026-10-26 | 47 | 54 | Stormwood m45c arm: storm-cloud form + distant skyline ON on the merged lane (GPU candidate) |
| `tb/stormwood-m48-on` | `ebcae6ed1dbd` | 2026-10-27 | 53 | 55 | Stormwood m48 arm: Ashfoot storm room light + window patch + Stormwood dressing ON (GPU candidate) |
| `tb/stormwood-m48b-on` | `cc99525a5346` | 2026-10-27 | 55 | 61 | Stormwood m48b arm: Ashfoot storm room light + window patch + Stormwood dressing ON (GPU candidate) |
| `tb/stormwood-m52-on` | `9821ef2fe9e4` | 2026-10-27 | 80 | 96 | GPU arm P2-041: Crown Arch candidate ON (octagonal landing, fuller crown) |
| `tb/stormwood-r22-on` | `311e0094241f` | 2026-10-26 | 1 | 1 | Stormwood r22 GPU on-arm: authored ground zones ON |
| `tb/stormwood-r23-on` | `9707888997a7` | 2026-10-26 | 1 | 1 | Stormwood r23 GPU on-arm: Ashfoot storm finish ON |
| `tb/stormwood-r24-on` | `ab6769edb323` | 2026-10-26 | 1 | 1 | Stormwood r24 GPU on-arm: Ashfoot storm finish + storm grade ON |
| `tb/stormwood-r25-on` | `104be87eef29` | 2026-10-26 | 1 | 1 | Stormwood r25 GPU on-arm: Ashfoot storm finish + grade + storm pane ON |
