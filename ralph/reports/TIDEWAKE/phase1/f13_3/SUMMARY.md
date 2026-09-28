# F13#3 "Six local chains, one per group, satisfy WORLD §5" (Phase 1)

WORLD §11 (the six selected Tidewake chains) and its §1 rule for an optional activity:
a discoverable lure, a distinct action, a useful reward, acknowledgement, saved
completion, and a route that works through ordinary play. The shared state is
"hidden → discovered (physical lure/NPC knowledge) → in progress → action complete →
acknowledged/rewarded".

## One uninterrupted run of all six, with real swims (`continuous_six_chains_8d7e3ddf.log`)
- Command: `godot --headless --path . --script tests/smoke_tidewake_b_chain_route.gd -- --continuous --save-dir=user://twlane_chains2`
- Tree: 8d7e3ddf, the lead map pins (98ce9985), dock residents and current comets included.
- Result: **619 checks, 0 failures, exit 0; one disclosed position write (POSE line).** All six `CHAIN ... PASS` lines appear twice: once on first completion and once after the save, reset and load.
- Every inter-island leg is **swum by real input** along the authored sheltered routes.
  The party is the retained five, with no swim mount. Each leg logs a `SWIM` line with
  distance, minimum stamina and health.
- There are no inter-island position writes.

| Chain | Lure → action → payoff → acknowledgement |
|---|---|
| side_water_lantern_return | Pell's lead ("the dry nook beneath Lantern Cove's rock arch, west of First Shore") → swim, claim the nook cache → Candy I → `water_pell_lantern_thanks` |
| side_water_gull_research | Adair's lead → Gull Rest research satchel → Candy II → `water_adair_gull_thanks` |
| side_water_cradle_care | Otto's lead ("the dry shell nest on Tidal Cradle's upper slope") → mine 4 Reef Stone → 3 berries + 4 Reef Stone kept → `water_otto_nest_thanks` |
| side_water_garden_records | Edda's request → copy the Drowned Garden vault wall → Candy II → `water_edda_garden_return` / `_thanks` |
| side_water_deep_watch_chart | Orsen names Tidecoil → **real Tidecoil fight won** → the chart control (a separate action) → Candy III → `water_orsen_deep_watch_charted` |
| side_water_lastlight_shelter | Halen's lead → gather 4 driftwood (axe) and 4 reed (knife) → deliver → rest a companion through the bed's Rest prompt → shelter built → `water_halen_shelter_thanks` |

**Saved completion:** after all six chains the run takes a production save, then a
reset, then a load.
- Every record, receipt, reward and quest-log `done` is re-asserted.
- Each requester is walked and swum to again and greeted. Each gives an
  acknowledgement, with no re-offer. These are the second block of `CHAIN ... PASS`
  lines.

## The lure clause
WORLD §11 counts NPC knowledge as discovery ("physical lure/NPC knowledge"), and every
chain opens with a named requester pointing at a named place. This pass makes that
knowledge findable in ordinary play, not only in the requester's line:
- **Map pins (98ce9985).** A requester's lead now pins its destination on the Tidewake map
  with a question-mark marker. The pin appears once the lead is heard, is derived from
  the chain's own flags on every peer, and goes away when the chain completes.
  - Data: `water_local_chains.json lead_map_pins`.
  - Tests: `tests/test_water_lead_map_pins.gd`, 5 tests, 39 assertions, 0 failed.
  - Frame: `map_leads_98ce9985.jpg`, with all six pins on the map.
- **The lead line** also appears as a HUD toast (`TALK ... hud=` lines) for five of the
  six. Orsen's greeting names Deep Watch and Tidecoil in dialogue only (`hud=''`), and
  its pin appears after the Tidecoil win. The lead also appears in the quest log.
- **Physical props:** the earlier code-blind lure judges are in
  `../../full/f13_3_lures/VERDICTS.md`.
  - Lantern Cove was WEAK with all four judges.
  - The other five varied between judges on identical frames.
  - The prop look (a distinct silhouette per place, a warm light, a readable object at
    the end) goes to the Phase 2 catalog under STATE §1 ruling 4.

## Shortcuts disclosed
- **Log self-label:** the log prints "DRY RUN - does not count: declared fixture start".
  That label predates the owner's relaxed-proof rule (2026-09-27). The run counts under
  that rule, with the shortcuts below disclosed.
- **Declared fixture start:** the retained five at L43, a carried pickaxe, axe and knife,
  and upstream story flags set before the world loads. The flags are the swim lesson,
  Reedhaven repaired, the Brine trial, Aquaryn resolved, Salt Crown charted, the
  Shellwatch and Sluice departure facts, and the Swim Stone character flag.
- **One position write:** back to the Deep Watch landing after the real Tidecoil win.
  The walk back from the cliff-foot shallows stalls. The same shortcut was taken at
  a524fb4d.
- Walks are planned by the harness and steered by real left-stick input. The run is
  headless.
- **Tidecoil setup:** the 8d7e3ddf tree carried this lane's Tidecoil surface-mode data,
  since reverted to main's setup (414eff8e).
  - The Deep Watch chain passed on both setups: at a524fb4d with main's setup, and
    here with the surface mode.
  - The chain only needs the win. The fight's C3 stays under F14#0.
- A first attempt at 98ce9985 (`run1_six_chains_98ce9985_timeout_in_rewalk.log`)
  passed all six chains but hit the process timeout during the reload re-walk under CPU
  contention.
  - `run1b_resume_lastlight.log` resumed only Lastlight. It is superseded by this run.
- Two-peer coverage is unchanged from a524fb4d/1fa83a57
  (`../../full/f13_3_chains/two_peer_local_chains_1fa83a57.log`: ALL CHECKS PASSED).
