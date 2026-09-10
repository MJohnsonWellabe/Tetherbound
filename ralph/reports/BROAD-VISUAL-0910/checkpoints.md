# Broad visual improvement — twelve-hour checkpoints

Start 2026-09-10 01:19:58 UTC. End target 13:19:58 UTC.
Owner direction: `docs/owner/OWNER_DIRECTIVE_2026-09-10_BROAD_VISUAL_IMPROVEMENT.md`.

## Eight-hour checkpoint — 09:19 UTC

Four hours remain until 13:19:58 UTC. PR117 remains the integration branch.

- Water deep opacity at `9fc53908f` removes the angular underwater silhouette
  through the sea. Five matched native views per variant, fresh day/night
  preference, four factory tests / 27 assertions, byte-identical canonical
  terrain rebuild and a clean 64.487 m physical opening swim support it.
- Shared grass grounding and blade-local curvature at `8b04e32d9` are retained.
  Fourteen candidate and fourteen original-control frames across Meadows,
  Stormwood and Water are clean; all three fresh location judges prefer the
  combined form. Grounding alone had mixed verdicts and is not counted as a
  separate visual win. Actual shader GPU checks pass; 720 measured local
  frames show similar medians but inconsistent heavy tails. No Ally or commercial
  grass acceptance is claimed. Cloudreach's separate shader transfer is held
  for renderer and native comparison after a caught coordinate error was fixed.
- Actual multiplayer entry now builds Cloudreach's authored grass instead of
  omitting it with sliced loading. Two complete peer-crossing runs pass with
  1,048,134 grass / 13,342 flowers / 778 bushes in each visible Cloudreach world,
  and zero decorative cover in its simulation shell. The minimap's incompatible
  texture reuse was reproduced in a focused negative control and corrected;
  its image-size error is absent from both peers in the second crossing.
  Departure Sync node-cache diagnostics remain open and are not called clean.
- The smaller available-action HUD strip passes its functional smokes and
  eight native day/night party-state frames. Fresh comparison prefers the empty
  state. Its claimed two-party colour gain is not credited: both controls and
  candidates actually bind the same bright label colour. The shortest actual
  authored objective still wraps to two lines, so
  no current objective-height gain is claimed. Existing duplicate recall text
  in the separate combat prompt remains a diagnosed follow-up.
- Fresh continuity now earns five creatures, gathers and pays for camp, rests
  them, wins all tournament rounds, and reaches the bridge guardian; it still
  failed there after 1,207.545 seconds. Focused copied-save diagnosis found an
  injured usable reserve that the test driver had not prepared. Ordinary earned
  potion care allowed two real guardian wins, key reward/spend, and a physical
  bridge crossing in one clean focused replay. Another replay's strict gate
  offer failure remains unreproduced. A bounded wait for the real arbiter's
  published offer is now in the driver; eight focused tests / 67 assertions
  pass. New fresh continuity is required before crediting the entire prefix.
- Full CI `34454848997` passed on `9fc53908f`: all 26 executed jobs, 3,203 unit
  tests / 490,808 assertions, with three known conditional skips. The raw-log
  audit is preserved. The newer changes require their own full CI after push.

Next: fresh continuous prefix, Cloudreach's grass transfer, bounded settlement
night-light comparison, remaining shared visual opportunities, and final
integration/CI/handoff. Most implementation remains with Sol/Luna; Astra handles
hard diagnosis, coordination and fresh blind judgments. Four-biome continuity and
the commercial visual bar remain open.

## Six-hour checkpoint — 07:19 UTC

Six hours remain until 13:19:58 UTC. Pushed PR117 head is `c0a4d243b`;
local head additionally retains resource-appropriate harvest labels at `f2dc2422b`.

- Replacement CI run `34447522002` passed all 26 executed jobs on `c0a4d243b`:
  3,202 unit tests / 490,800 assertions, zero failures. Three known conditional
  jobs remain skipped. All executed logs and their caveats are preserved in
  `CI-C0A-AUDIT.md`; uncommitted experiments and the newer label commit are outside
  that run's coverage.
- Water horizon correction `8c1b0edcb` is retained: finite-plane extension plus
  removal of the overlapping flat Terrain3D background. A clean 2x2 diagnostic,
  factory tests, five native frames per pair, independent day/night preference
  and 64.486 m physical opening swim support the bounded fix. Canonical terrain
  rebuild was clean and all 31 binary files stayed byte-identical. The angular
  water value/depth boundary remains open; a separate diagnostic is prepared.
- Shellwatch and Deep Watch authored return-current reductions `0dbbe5793` are
  retained. Eight unit tests / 52 assertions and 47 production action/save/reload
  checks pass. Two failed smoke attempts remain recorded; the final correction
  waits for the real combined world flag to settle on its idle update. This is
  not played combat or earned realm-transition proof.
- Shared grass-normal shading is withdrawn after a modest isolated preference
  failed to carry across locations: South Bridge and Glass Field tied; Root Walk
  preferred the original. A separate generated shared turf albedo is currently
  a process-local experiment: South Bridge modestly preferred it by day, Glass
  Field tied, and Grandpa's Village preferred the original by day. A direct GPU
  array readback is being added before the final disposition. No grass quality
  acceptance or broad texture improvement is claimed.
- Cloudreach's bounded crown geology candidate has six clean native frames and
  six matched hidden-visual control frames across Gate, Windscar and Upper.
  Geometry now roots in the actual eroded crown and has matching installed-mesh
  collision with route/landing/landmark/battle-yard guards. Four geometry tests
  pass, including nested transforms; earlier fixture failures are preserved.
  Blind judgments and actual traversal checks remain pending. Not retained yet.
- The fresh through-bridge attempt remains failed at earned materials, before
  tournament/bridge. Three compatibility helper attempts also failed. Exact
  provider instrumentation proved the neighboring `Chop` prompts were stone,
  invalidating the compatibility/timing hypothesis. Those helper changes were
  withdrawn. Production prompts now say Chop/Mine/Gather by actual resource.
  The Meadows-only route now uses the existing bounded refused-stand policy;
  its five-assertion live-selection smoke passes. A copied-save physical run is
  active. A fresh canonical prefix is still required after any focused success.

Next: finish the candidate decisions without counting weak results as wins,
resolve the actual gathering path, run a new canonical continuous extension,
and continue broad scene improvements supported by runtime evidence. Most
implementation remains with Sol; Astra coordinates hard diagnosis and fresh
independent image judgments. No full four-biome or commercial-quality acceptance.

## Four-hour checkpoint — 05:20 UTC

Concrete retained state is at `5c2db16b5`; PR117's last pushed head is
`4d3a69b7f`. About eight hours remain in the authorized run.

- Settlement foundations/interiors: `4d1305cf1`, all nine production entries,
  floors and sidewalls passed; this is a functional repair, not a visual bar pass.
- Player night rim: `6794cb039`, preferred at two locations with daylight
  equivalent. Lyra's existing emissive texture remains a separate limitation.
- Creature platform transfer: `176b17638`, controlled negative case carried
  the creature 128.062 m; the fixed case carried it 0 m. Native catalogue
  teleport tracing retained the creature at home.
- Stormwood palette: `44473241c`, preferred at Glass Crown and Lantern Hollow.
  Shared thin-leaf lighting: `e986f6d42`, modest Meadows canopy preference;
  Water had no meaningful preference. Neither is commercial visual acceptance.
- Critical wildlife: the first Stormheart resite cleared the approach but CI
  found two empty 10 m road samples. `5c2db16b5` adjusts its Z position while
  keeping the same pair/count/species/levels. Full ROAD and clearance checks
  passed; actual bodies remain seated on terrain 56.6 m and 103.8 m beside
  the road. No scatter rebake is required for encounter-only data.
- Fresh opening through rested team: clean guarded run 04:59:34–05:12:05,
  campaign elapsed 742.83 s, five ready creatures, paid camp and real rests.
  Ten traced aim exits were ordinary releases followed by strikes. The older
  intermittent 219 s aim failure did not reproduce and is not declared fixed.
  Coverage observation remains incomplete: 179 samples, 141 below two, one
  undersampled interval, unknown indoor/road membership; no complete campaign
  or runtime road-coverage claim follows from this prefix.
- Combined focused validation 05:14:01–05:14:07: 13 tests / 334 assertions,
  clean, including full ROAD, critical clearance, Water material binding and
  exact leaf-only fade binding.
- Withdrawn with preserved patches/frames/fresh verdicts: Cloudreach local
  cover, footprint clearance, basal leaves, far turf, authored upland materials,
  Stormheart material treatment, and unsupported Stormwood detiling parity.
  The procedural-grass complaint remains open; exhausted knob/shape rounds
  are deferred under the owner's broad-improvement rule.
- New held candidates: near-camera leaf Pixel Dither (one catalogue plus four
  ordinary movement views clean in 103 s); Water Fresnel binding (six native
  day/night frames clean in 47 s). Matched controls/judgments are pending.
- CI run34439181372 is not a pass: unit shard2 failed the ROAD assertion above;
  other completed unit shards passed. Logs are being preserved and audited.
  The road correction needs complete replacement CI after this run's audit.
- Content audit identified disconnected Stormwood side-chain event producers;
  existing contracts are being checked before any new quest behavior is added.

Next: finish the two held visual comparisons, validate Water swimming after
material changes if retained, finish CI correction/audit, then expand earned
continuous play and address concrete content integrations alongside visual work.

## Setup — 01:25 UTC

- Fetched main: `5471c4deb`, including PR115 consolidation and PR116 domain
  acceptance criteria. New integration branch `codex/broad-visual-pass-0910`.
- Game source matches main at start; existing phone attachment and root
  diagnostic `manifest.json` preserved untracked.
- Sol assignments: shared creature presentation and shared terrain/vegetation.
  Luna assignment: guarded native production baseline capture, exclusive Godot
  lease. No production mutations before baseline release.
- Known failed density/mipmap/night-grade experiments remain held; no art pass
  or campaign completion claimed. This setup is not a player-visible checkpoint.

## First two-hour checkpoint — prepared 03:17 UTC

- Concrete commits: `ce6f5ccc8` Water material scale/detiling;
  `325028e0b` broader shared procedural grass and enabled Water profile;
  `3a61c10b6` compact empty hotbar; `306d3a67d` actual-bound large-creature
  camera framing and active indigo Voltarach alpha palette. Lower models wrote
  the implementation; Astra coordinated, reviewed and performed blind judging.
- `ce6f5ccc8` CI run 34428339298: 26 executed jobs passed, three skipped,
  no actual retries. Raw logs audited and preserved; teardown/null-material
  diagnostics and excluded campaign/export gates remain explicit caveats.
  Later commits require their own CI; the earlier green is not transferred.
- Shared grass: 22 focused tests / 87,832 assertions; native Meadows 20,
  Stormwood 24 and Water 12 matched frames. Fresh judges preferred fuller
  ground cover, with stiff blades still open. Water arrival → Pell → 64.488 m
  physical swim lesson passed with cover enabled, no post-arrival fixture writes.
- Camera: measured maximum-body pair fits at 5 m and 11 m separation, with
  zero behind-camera bounds corners. Native production encounter test passed
  after a deterministic approach fixture replaced an intermittent wrong-prompt
  conflict. Stronghold production room test capped request/arm/hit at 2.25 m.
  Blind judge prefers the wider shot; facial/art quality remains below the bar.
- Empty hotbar: native dock cases passed. Production playground assertions
  passed, but its headless run was correctly marked non-clean for the same
  dummy-renderer null-material diagnostic present in pre-change CI. No retry.
- Settlement work remains uncommitted: real terrain pads address measured
  burial up to 3.22 m. Terrain/scatter were regenerated; baked floor unit checks
  and workshop placement checks pass. Eight of nine production entrances
  traversed. Actual contact tracing identifies Fenn blocking Still Grove's
  doorway; the door itself is sound. Shared workshop dressing has six Stormwood
  and four Meadows native frames; independent verdicts are pending.
- Cloudreach's first capture exited -1 without frames; changed boot diagnostics
  then produced a valid day/night Gate Crag pair in 118 s. The first failure is
  preserved, not renamed a timeout. A distinct cover candidate is now rendering.
- Withdrawn for no visible progress: grass clump 03 and character emission
  floor 01. Skyrill face-mask candidate remains withdrawn. Their patches,
  captures and negative verdicts are retained; these are not shipped wins.
- Runtime diagnostics also exposed ordinary Stormheart creatures overlapping
  the critical destination and a named Mosshock relocating during catalogue
  travel. These are separate from the corrected alpha palette; focused tracing
  is prepared. Full uninterrupted campaign acceptance is still open.
- Tooling finding: a validation wrapper's generic descendant PID set followed
  reused Windows PIDs after Godot exited. Root stopped that exact wrapper before
  its deadline; no game failure was hidden. It now observes the retained process
  handle and tracks only fresh Godot descendants. A combined focused run then
  passed 5 tests / 1,854 assertions with a complete clean receipt.

Next: finish settlement entry/visual proof and Cloudreach cover judgment, test
the distinct night-rim hypothesis, trace creature relocation/critical-space
overlap, then expand production travel and continuity checks as visuals settle.
