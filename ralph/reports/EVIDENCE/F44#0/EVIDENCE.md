# F44#0: after a biome's boss, its named trainers/captains/Master rematch at the next band for better rewards
- Smoke: `tests/smoke_f44_biome_rematch.gd -- --biome=<b> --from-save=<generated f44_<b> save>`, built here, then aligned with the rematch-wiring lane.
- **Meadows: PASS, 21/21** at ff5e8752 (Sun 11 Oct, 3:03–3:32 PM CT). Witness `captain_riverwatch` (`meadows_captain_riverwatch.json`):
  - ordinary Interact admits the canonical r1 rematch;
  - every member at L33 (first win L15–16);
  - pilot wins (7921 frames);
  - the win is delivered once, paying `rootiron_ingot` 2, which the first win's reward never paid;
  - after a title reload: receipts and payout unchanged, cooldown kept.
- Disclosed:
  - generated post-Warden input (profile `f44_meadows`, `meadows_input_PROVENANCE.json`, party L35);
  - one teleport beside the rematch prompt;
  - witness changed relay_captain → captain_riverwatch (coordinator ruling, ba5d4f43).
- Owner finding: 7 Team Tether patrol profiles (relay_picket_hess, relay_picket_orrin, relay_officer_dell, relay_captain, stronghold_patrol/courtyard/elite) are withdrawn by the F05 Meadows healing at the Warden, the same moment their r1 tier opens, so they can never be rematched. Coordinator recommends dropping them from rematches.json.
- Game fix exercised (92ed032a): the win's payout waited behind ~100 combat_mastery duties, 8308 frames (~138 s game time); it now lands after 1111 frames (~18.5 s). Owner input was blocked for 0 frames.
- Tidewake and Cloudreach: rematch sources were wired by the rematch-wiring lane (tb/ev-rematch-wiring); its 21/21 PASS evidence is in ralph/reports/EV-REMATCH-WIRING/. Stormwood: PASS below.
- **Stormwood: PASS, 24/24** at 57ac1753 (Sun 11 Oct, 3:50–4:01 PM CT). Witness `officer_maren_verge_rod`, endgame tier (Stormwood's post-credits witness, also F44#1) (`stormwood_officer_maren_endgame.json`):
  - ordinary Interact admits it at L58 (first win L42–44);
  - pilot wins (4682 frames);
  - delivered once (711 frames after the win), paying `stormglass_plate` 2;
  - title reload: receipts and payout unchanged, cooldown kept.
  - Disclosed: generated input `f44_stormwood` at Ashfoot Waycamp (the portal leg was tried twice and is blocked by the relic power panel); post-load fixture flags `stormwood:marrow_defeated` and `regional_credits_seen`; one teleport.
- Game fix found by this witness (57ac1753): `stormwood_encounter_director.begin_trainer_battle` sent every non-Master spec to StormwoodEncounterHub.request_start, which restarts the chapter's canonical trainer, so every Stormwood rematch was dropped while the call reported success. Rematch specs now take the inherited path, as Masters do.

## F44#1 Meadows endgame (systems-b, Sun 11 Oct 2026, 6:46–7:39 PM CT) — PASS 21/21
`tests/smoke_f44_biome_rematch.gd -- --biome=meadows --tier=endgame` at 59460943e on the generated `f44_meadows_endgame` save (`meadows_endgame_input_PROVENANCE.json`). Captain Riverwatch, five L58, won after 13,752 frames. Unique reward rootiron_ingot ×2 paid once, and better than the first win. After a title reload: receipts unchanged, no second payout, cooldown retained. Result: `meadows_captain_riverwatch_endgame.json`.
Disclosed: a generated post-credits profile (regional_credits_seen) with the five at L58. The generator now lets post-credits profiles reach the Masters' cap ceiling of 60; four-chapter profiles keep L55.
Balance finding (not changed): an L55 team, about where the four-chapter clear ends, lost this five-creature L58 fight twice (14,607 and 17,792 frames). The Tidewake, Cloudreach and Stormwood endgame witnesses (smaller teams) were won at L55. Endgame rematches need post-credits leveling toward L58–60, consistent with PROGRESSION §6's L55–60.
An earlier run was lost to a deleted scratch worktree, so it is not counted.
