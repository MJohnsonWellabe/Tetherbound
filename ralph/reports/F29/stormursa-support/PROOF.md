# F29#3 Stormursa support-constrained faint — PARKED

- 13 Oct 2026, 03:10 CT: two actual Blender attempts; no output GLB or acceptance.
- Canonical OFF candidate source hash stayed a0a1511eaed151f1e4a1849be84e1b86d21c2103ac99f1303775fba9c90ffbcb.
- Attempt v1b failed initial front-left reach: 0.7118 asset units versus guarded upper limit 0.7111.
- Attempt v2 retained that guard and computed pelvis-only lowering from measured reach to create slack.
- V2 failed frame-zero evaluated weighted-sole penetration: 0.1275 m estimated production scale.
- Geometry distances use raw asset coordinates; production estimate uses 4.10 m standing bounds. No native contact PASS.
- Source asset, rest bones, mesh, scale and production flags unchanged; no new Meshy requests.
- v1b-failure.json and v2-failure.json preserve errors and input hashes; v2-launcher.json records exit 1 and released lease.
- Private scripts/logs: .artifacts/codex-service-creatures/stormursa-support-prototype and C:/CodexTemp/codex-service-creatures/stormursa-support-v1b and -v2.
- The v1b launcher lost supervision after a transient identity-check failure; Blender later exited itself. Its terminal failure JSON, not launcher exit status, is the result.
- V2 used corrected bounded supervisor; no resource abort. No visual judge is claimed because no candidate passed contact/export gates.
- Two failed attempts park this support approach. Further work requires materially different rig/skin/control reconstruction, not guard relaxation.
- No READY, F29#3 closure, or flag enablement.
