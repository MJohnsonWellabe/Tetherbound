# F13#3 "Six local chains, one per group, satisfy §5": tb/tidewake-full

## One uninterrupted run of all six chains, with real swims (`continuous_six_chains_a524fb4d.log`)
- Command: `godot --headless --path . --script tests/smoke_tidewake_b_chain_route.gd -- --continuous --save-dir=user://twfull_chains`
- Code: a524fb4d, 0 dirty tracked files.
- Result: **619 checks, 0 failures. POSES: 1 disclosed position write.**
- Every inter-island leg is **swum by real input** along the authored sheltered routes, from
  the arrival with the retained five and no swim mount. That includes Garden and Deep Watch
  over the owner's 13:33 rest points (`SWIM ...` lines, min stamina and health per leg).
  There are no inter-island position writes.

| Chain | Lure → action → payoff → acknowledgement |
|---|---|
| side_water_lantern_return | Pell's lead → swim to Lantern Cove, claim the dry-nook cache → Candy I → `water_pell_lantern_thanks` |
| side_water_gull_research | Adair's lead → Gull Rest research satchel → Candy II → `water_adair_gull_thanks` |
| side_water_cradle_care | Otto's lead → mine the Cradle nest seam → 3 berries + 4 Reef Stone → `water_otto_nest_thanks` |
| side_water_garden_records | Edda's lead → the Garden records wall → Candy II → `water_edda_garden_return` / `_thanks` |
| side_water_deep_watch_chart | Orsen names Tidecoil → **real Tidecoil fight won** → the chart control → Candy III → `water_orsen_deep_watch_charted` |
| side_water_lastlight_shelter | Halen's lead → gather 4 driftwood (axe) + 4 reed (knife) → deliver → rest a companion through the bed's Rest prompt and panel → shelter built → `water_halen_shelter_thanks` |

- **Saved completion:** after all six there is a production save, a reset and a load. Every
  record, receipt, reward and quest-log `done` is re-asserted, and each requester is walked
  to again (swimming between islands) and greeted: acknowledgement, no re-offer. That is the
  second block of CHAIN PASS lines.

## Since a524fb4d
- Only lure props moved (1fa83a57): the Lantern rise group and the smoke look.
  `lantern_rewalk_1fa83a57.log` re-walks and swims the Lantern chain at that head:
  **70 checks, 0 failures**, so the new props don't block the route.
- **Two-peer** (`two_peer_local_chains_1fa83a57.log`, `tests/smoke_net_water_local_chains.gd`):
  ALL CHECKS PASSED.
  - A client's speech step is committed by the host and reaches both peers.
  - A client's delivery debits only the client, and the shelter it builds appears in the
    host's scene.
  - The per-character receipt check refuses the client until it claims its own Lantern cache.

## Lures (the §5 "see the lure" clause): `../f13_3_lures/VERDICTS.md`
- Four fresh code-blind judges, two rounds.
- **Lantern is WEAK with all four. Not closed.**
- The other five vary between judges on identical frames. In round 1, Gull, Garden and
  Lastlight got YES from both judges; Cradle and Deep Watch were split.

## Shortcuts disclosed
- A declared fixture start: the retained five at L43, carried pickaxe, axe and knife, and
  upstream story flags set before the world loads (swim lesson, Reedhaven repaired, Brine
  trial, Aquaryn resolved, Salt Crown charted, the Shellwatch and Sluice departure facts,
  the Swim Stone character flag).
- **The one position write:** back to the Deep Watch landing after the real Tidecoil win. The
  walk back from the cliff-foot shallows stalls, and after two harness strikes the shortcut
  is taken.
- Walks are planned by the harness and steered by real left-stick input.
- Headless.
- The two-peer smoke uses teleports and fixture materials, as filed.
