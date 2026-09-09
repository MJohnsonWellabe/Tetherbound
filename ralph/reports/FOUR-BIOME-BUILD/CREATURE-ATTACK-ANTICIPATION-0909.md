# Torrentoad attack anticipation — 2026-09-09

Status: source candidate; initialized engine assertions pass, while the parent test
wrapper correction remains unrun. Independent visual review is still required.

## Cause and bounded candidate

The retained combat review shows neutral idle poses through attack exchanges. Production
confirms the cause: `WildCreature` emits its 0.40–1.00 second telegraph without starting
body motion, then `CombatManager` calls `play_attack()` only after the gameplay strike
has resolved. The installed attack clip therefore reaches its visual contact roughly
another half-second after damage.

Torrentoad is the bounded first candidate. Its species entry explicitly attributes the
installed rig to `animate_quadruped.py`; that source keys ordinary quadruped contact at
frame 15, or 0.625 seconds at 24 fps. Direct parsing of all 45 attack sampler input
accessors in the installed GLB finds the same exact maximum, 0.9583333333333334 seconds
(23 frame intervals). The animation map therefore records `attack_contact_phase =
15/23`. On entering TELEGRAPH, the animator scales the anticipation segment to the
body's actual combat-profile duration. The existing impact-time `play_attack()` call
continues from the contact pose at normal speed rather than restarting the clip.

The setting is optional and clip-specific. Unannotated species preserve their existing
animation behavior. AI decisions, telegraph/recovery/cooldown values, strike signals,
damage resolution, movement, collision, mesh, scale, materials, and emission are
unchanged. Movement cancellation and hit reactions clear the temporary playback rate.

## Files

- `scripts/creatures/wild_creature.gd`
- `scripts/creatures/creature_animator.gd`
- `data/creatures/species.json` (Torrentoad animation metadata only)
- `tests/test_creature_attack_telegraph_animation.gd`
- `tools/_capture_torrentoad_attack_anticipation.gd` (fixed production-body evidence only)

## Validation

The focused test uses an actual `AnimationPlayer` and the production `WildCreature`
TELEGRAPH transition. It covers 0.40 and 1.00 second profile endpoints, the unchanged
emitted gameplay duration, real clip advancement, contact continuation without restart,
locomotion cancellation, and hit interruption.

- First combined run: the existing companion animation suite passed 27/27. Three of
  four new tests passed. The real-advance case failed because the pure unit runner runs
  from `SceneTree._init`, leaving its AnimationPlayer outside the active tree; the raw
  engine error was `Cannot get path of node as it is not in a scene tree.` Retained at
  `.artifacts/creature-attack-anticipation-20260909/focused-tests.log`.
- Corrected initialized-child run: the child placed the actual AnimationPlayer in the
  active SceneTree and passed 8/8 assertions, including effective
  `get_playing_speed() == 1.0` after impact and locomotion cancel. Its retained line is
  `ATTACK_TIMING_RESULT={"assertions":8,"failures":[]}` in
  `.artifacts/creature-attack-anticipation-20260909/appdata/Godot/app_userdata/Tetherbound/creature-attack-telegraph-child.log`.
- The corrected parent wrapper still exited 1 because Windows redirected the child line
  exclusively to `--log-file`, while the parent parsed only `OS.execute` output. This is
  retained in `corrected-focused-tests.log`. The parent now parses the explicit child log;
  that final wrapper correction has not been rerun. Each future invocation uses a unique
  process/tick-named child script and log, checks the child exit code before reading, and
  therefore cannot reuse this retained result. The corrected prefix/JSON parser was checked
  without Godot against the retained line and returned 8 assertions with zero failures.

Art limit: frame 15 is the pipeline's authored strike key, not an anatomy claim about
where every Torrentoad limb intersects a target. A combat render is still required to
judge whether the wind-up reads clearly at ordinary camera distance.

## Fixed visual sequence

Executed once. One 1280x800 fixture uses the installed Torrentoad model,
`WildCreature`, and actual `AnimationPlayer` for both lanes under the same transform,
camera, floor, and light. Lane A removes only the optional contact-phase metadata from
its local animator; lane B uses production data. Each captures neutral `t000`, mid-beat
`t050`, strike time `t100`, and recovery `t120`. A JSON manifest records actual intent,
beat remainder, emitted telegraph duration, strike count, animation position, speed
scale, effective playing speed, and UTC shutter time. Filenames expose only A/B and
neutral timestamps. No world scene, roster search, camera change, asset, or palette edit
is involved.

The component fixture completed 8/8 PNG saves with no engine error. Both lanes emitted
one 1.0-second telegraph and exactly one strike event at `t100`; the manifest records
RECOVER with 0.75 seconds remaining at that shutter. A is unchanged between `t000` and
`t050`, then starts its attack at position 0.0 at `t100`. B is visibly compressed into
anticipation at `t050`, reaches the strike pose at `t100`, and continues recovery at
`t120`. This is manually stepped production-state component evidence, not ordinary live
combat acceptance.

The frozen first capture exposed a narrow metadata error: B reached position 0.6534089
at `t100`. Dividing that by the then-configured 15/22 phase proves the active imported
clip is 0.958333 seconds long, which the direct GLB sampler parse independently confirms.
The first candidate's `species.json` hash was
`8FF1320C8A52B03980BE9E727EC068BDB7192D0366C6EEA41CF144C6D32D0A50`; its 15/22 value
sought about 28 ms after the authored 0.625-second contact key. The metadata is corrected
to 15/23; corrected `species.json` SHA-256 is
`570F0EF6C9F915B875FD3F0F5D71AA5BFC8CE098978E51CAA199F3286558A16F`. The focused
test constants changed from the synthetic 22/24-second assumption (test hash
`A579B7F19894DFDE0B9A972B11F93D28DBA7277DEEDAD52AA1F7030FF190FBB8`) to the installed
23/24 duration (current test hash
`9BABAFA2D11AA257549CCE62E2331637BDEFC8BE15714E98C01844FAFE25C30D`); this metadata-only
test correction has not been rerun. Existing PNGs and manifest remain immutable
pre-correction evidence; no second capture has run. The helper now records
`assigned_animation`, because the first manifest
honestly contains an empty `current_animation` after its controlled pause even though
its animation positions, speeds, and rendered poses are valid.

Capture artifacts:

- `shots/creatures-attack-anticipation/torrentoad/manifest.json` SHA-256
  `76EE65957F74A6E4B9B6D8E0116EDD749C578AF63C820EBCFDF1FD9C77014BB3`.
- `A-t000.png` and `B-t000.png` are byte-identical, SHA-256
  `5393D30D1582012A52F42EDA967CE736EEEFFCFEAAAB97761E017B37E0301EF6`.
- A sequence hashes at `t050/t100/t120`:
  `B6428D12B4B05B280B1E12CBA8221CCC94C393210170E047969472DF270159E4`,
  `8B145B94A7C02E1D4D68D3071550EFC8D75E504262B0F78A3DBAB8C4BAF4C90F`,
  `F0E8804ED12A5D4C4F3A6D9F4A904324CF6DA55912F74E561A27ADD08053F3AA`.
- B sequence hashes at `t050/t100/t120`:
  `16405C966F8BDE0C295EF2792DA985FE6FFED4688699BCBBDD9A0DADAC242E95`,
  `D275C3D7EB754209786CCBA2FE8CA9EBD7A3E10E64B35213FB4F199EBCEDFD85`,
  `F3874852F1C09133C04B62BEFFFE04958E64DEE8D72C84DFEB5A745BC6C2954C`.
- Guard receipt: exit 0, 56.48% peak system commit, 254 peak processes,
  362.23 MB peak Godot private memory, and zero Godot processes afterward.

## Final corrected candidate and evidence

The final source also clears timed attack presentation on both engagement boundaries.
Ordinary teardown calls `set_engaged(false)`, while failed-catch breakout calls
`set_engaged(true)` directly after absorb suspended physics. Both now clear the old hold,
timed clip marker, and playback rate. `cancel_hold()` does not change the animator's
`_finished` state, so this cannot revive a fainted creature. Routine retargeting remains
unchanged because it writes `_opponent` directly.

The final focused run completed 5 tests and 28 assertions with zero failures and no
`ERROR:` or `SCRIPT ERROR:` lines. It includes the installed GLB's 23/24-second duration,
the 0.625-second contact result, 0.40/1.00-second telegraph endpoints, continuation without
restart, movement and hit interruption, legacy-family fallback, and actual initialized
WildCreature `set_engaged(true)` / `set_engaged(false)` boundaries. Its child wrapper uses
unique paths and scans and echoes the explicit child log plus every line inside multiline
`OS.execute` chunks before handling a nonzero child exit.

- Final unit log:
  `.artifacts/creature-attack-anticipation-final2-20260909/focused-unit.log`.
- Final unit receipt: exit 0 at `2026-09-09T10:40:46.9592694-05:00`, zero engine-error
  lines and zero Godot processes afterward.

The final component capture is distinct from the frozen first capture:
`shots/creatures-attack-anticipation/torrentoad-corrected/`. It completed 8/8 1280x800
images with no engine error. A and B emit one 1.0-second telegraph and exactly one strike
at `t100`; B is assigned `attack` at position 0.31250003 / effective 0.625x at `t050`,
then position 0.62500007 / 1.0x at `t100`. A is assigned `idle` at `t050` and starts
`attack` at position 0.0 at `t100`. The manifest SHA-256 is
`1C3D91CE493523879D4B521EE1075C873DC47ADCDFF37F5D054D0E4108F8BA48`.

Final image SHA-256 values:

- A `t000/t050/t100/t120`: `3C685263C887E98A8079BFF91F2E36D8C9BDA4D5569C86E28D77DEAF8A8913BE`,
  `650CEF13AE37D71B82A320E53F99F82158644014557C9420F671E58859015EBC`,
  `75B31D7C714730BFDE764C093DA15621ABA4CB6B7688007FF8FB353B879F3054`,
  `9D5C56F2D958D99D752A6FF1D048B1AA90ED9A44E36AC7C3B06DA26977514F65`.
- B `t000/t050/t100/t120`: `3C685263C887E98A8079BFF91F2E36D8C9BDA4D5569C86E28D77DEAF8A8913BE`,
  `1335103B0E6D37361E152763B19F0FE5D2E3E77C08FA88BD6B419CA8E8A6A810`,
  `42838B78D3AE9E7326C12FAE83A84C5189C6CB784730FB76F1A2A19F7817AF7D`,
  `CAEF391DBF5EFB5BCB3B906C92461382584ABA235AA4A523518DD3E355AC3D68`.

The capture uses the frozen `77745ef0` Torrentoad vivid source, extracted read-only to
the artifact directory: 1024x1024, SHA-256
`32237F65F34A220B3218D3A60FFC9C22E0F52656922ACB7E3FDF9DD0F274BE7E`.
Both lane materials use the same local override; the manifest confirms two surfaces,
texture filter 3 before and after, and no generated mipmaps. The protected production
import uses VRAM compression mode 2 with mipmaps disabled. Loading the same source pixels
through `ImageTexture` preserves pixels, filtering, and no-mipmap behavior for the A/B
motion comparison, but does not prove byte-identical VRAM-compressed import output.

Final frozen production/source hashes:

- `scripts/creatures/creature_animator.gd`:
  `1135A32BD2BC6B2B6C947D3E9F380037BFE3376A52F47273D69AA3B3B8267A37`
- `scripts/creatures/wild_creature.gd`:
  `D2CA525ED6FD57607A608171638FD2A2F8F9600BF5292B510C87FB980AE92553`
- `data/creatures/species.json`:
  `570F0EF6C9F915B875FD3F0F5D71AA5BFC8CE098978E51CAA199F3286558A16F`
- `tests/test_creature_attack_telegraph_animation.gd`:
  `92E8B0FC8B553246C1FEBE302B9B0BCAF7F1B75C1390FCDE30F31729D8282A7E`
- `tools/_capture_torrentoad_attack_anticipation.gd`:
  `BB0B510A259FCCE26AF1FB651F188060705617B106B81A04FE7DA634B8B48D42`

Final capture guard receipt: exit 0, no stop reason, 54.21% peak system commit, 257 peak
processes, 371.87 MB peak Godot private memory, and zero Godot processes afterward.
These frames remain manually stepped production-state component evidence. Ordinary live
combat acceptance and final independent image acceptance are intentionally not claimed.
