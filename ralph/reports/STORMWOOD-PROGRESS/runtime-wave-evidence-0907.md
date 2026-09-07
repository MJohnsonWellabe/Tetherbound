# Runtime wave evidence — 2026-09-07

Unmerged runtime wave on `ralph/stormwood-chapter-runtime-0907`, based on main
`096a724aa4de127b830f0b6133740ab46375073b`. These results do not increase the
merged-main scorecard until the wave lands. No phase is closed.

- Fresh actual-world opening: `D:/CodexWork/stormwood-prefix-current.log`, exit 0.
  Authored realm entry, Ashfoot arrival, live interaction arbiter selects Hesk,
  dialogue completes and quest HUD advances to Tamsin. 108 Terrain3D regions,
  19 NPCs, 26 trainers, 660 wild placements. No errors; mipmap/deprecation warnings.
- Root rerun of `smoke_stormwood_arches.gd`: exit 0, PASS in
  `D:/CodexWork/stormwood-arches-root-proof.log`. Real interaction arbiter,
  inventory, ledger, Session and Area3D passage in a minimal single-host world.
  Two endpoint relights cost three each, duplicate activation costs nothing,
  passage moves player and active companion, combat refuses travel. No ENet proof.
- Root harvest authority/catalogue run: 11 tests, 9,548 assertions, zero failures,
  `D:/CodexWork/stormwood-harvest-authority-root.log`. Host clock controls charged
  availability; host catalogue controls yield; racing peers produce one grant;
  generic harvest cannot bypass reserved site flags. Inventory/tool validation
  remains the existing character-local preflight; no claim of hostile-client
  tool ownership validation or actual two-process delivery.
- Root lightning live fixture: 11 assertions, zero failures,
  `D:/CodexWork/stormwood-lightning-shelter-root.log`. Movement out of the warning,
  host publication, duplicate-impact suppression. Minimal scene; not ENet proof.
- Full unit wave2b: 2,678 tests, 3,800,523 assertions, two failures, exit 1.
  The new v23 world-key expectation was corrected and its focused suite passed.
  Cloudreach visited-grid serialization encountered allocator failures during
  the full run; its exact test passes in a fresh process (1 test, 10 assertions).
  This is evidence against a reproducible map logic regression, not a green
  final full-suite result. The run started before later runtime edits.

- Final focused Stormwood unit run: 69 tests, 19,519 assertions, zero failures,
  `D:/CodexWork/stormwood-runtime-all-focused.log`. Includes four rod-station
  host gates, save/reload idempotence and region-specific Surge duration changes.
- Actual harvest fixture: `D:/CodexWork/stormwood-harvest-live-root.log`, exit 0,
  21 assertions. Calm refuses; Break grants three Stormglass and spends one
  pickaxe durability; natural post-deletion runtime scan delivers the chapter
  event. A freed-node reference bug found by this smoke was fixed. Headless
  dummy material warning remains; this is not a rendered visual assessment.

Still missing: rod-station combat-to-switch route proof, constructed arch pairs and mandatory Crown
connection, Dynamo encounter and ending, player-gear strike integration, full
chapter save/load and multiplayer interaction proof, accepted rendered visuals.
