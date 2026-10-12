# F11#3: Long Storm aftermath and Spark/shrine persist. OPEN (FAIL at step #34)

- **Scenario:** `tools/net/proof_scenarios/stormwood_f11_aftermath_shrine_two_peer_reload_rejoin.json` via `tools/net/run_two_peer_proof.sh`. A scratch copy scales the slow-host budgets: `budget_s` ×3 and `build_allowance_s` 600; at the 150 s default, step #1 `load_save` died twice on "peer silent >15 s".
- **RD-17 alignment (coordinator-approved, committed):**
  - The physical Waterward gate is retired (ACCEPTANCE F11: superseded by RD-17, see F18#2). Step #32 now expects the guest's press to leave it sealed.
  - The aftermath and saved-world checks expect `realm_gate_water_unlocked` false and `realm_key_water` true.
  - The `realm_key_water` true comes from the shipped `stormwood_chapter.json` objective `stormwood_waterward_revealed` (the aftermath view's `grants_flags`), not from a fixture. Nothing spends it now that the gate is retired.
  - Steps #34, #35, #42, #43 and #70 cross realms through the disclosed `stormwood_proof_return` fixture in `tools/net/portal_smoke_travel.gd`: an initial Home Key; Meadows by a real Home Key trip; Stormwood by the Hall's Stormwood arch. The host crosses first, which is the real player case. `stormwood_proof` is unchanged.
  - Helper alignment (disclosed): `_home()` re-presses the Home Key after the exact "not ready" refusal, about once a second for up to 10 presses, as `travel()` already does for `portal_enter`.
- **Game defect found and fixed:** `scripts/net/foundation_travel_lifecycle.gd` `accept()`.
  - A guest hurt in Meadows (damage_revision 1) crossed to Stormwood. The crossing rebuilds its vitals at 0, so the host refused every later sample as a damage rollback. Host diagnostic: `stale_sample_136565ms … damage 0<1`. From then on every guest Home Key or portal request got "Your authoritative travel state is not ready."
  - Fix: a lower damage_revision is refused only within the same realm. A frozen portal action already lapses on a realm change.
  - Unit test `test_foundation_travel_protocol::test_a_realm_crossing_restarts_the_damage_revision_without_staling_the_guest` fails without the fix and passes with it; the file passes 10/10.
- **Still failing (2026-10-11, 3:24–3:35 PM CT, host first, with the fix and the re-press):**
  - Steps #1–#34 pass; at #34 the host's Home Key reaches Meadows.
  - At #35 the guest's Home Key in Stormwood is refused "not ready" 3 times (peer-1: `PORTAL_SMOKE_HOME_RETRY press=1..3 … "kind":"home_key_begin","ok":false,"reason":"Your authoritative travel state is not ready."`).
  - The 4th press gets no reply before the 10000-frame budget runs out.
  - This is a game defect in the guest-after-host Home Key; it goes to the coop-chapters host-first portal investigation.
