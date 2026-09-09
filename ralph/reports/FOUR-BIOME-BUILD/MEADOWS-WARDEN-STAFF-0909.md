# Meadows Warden staff — 2026-09-09

Status: **held after fresh image judgment**. Source and initialized component
proof are complete; six matched frames were captured, but the fresh judge
prefers the baseline's cleaner presentation. Staff grip and material language
are unresolved despite geometric attachment. See `VISUAL-FRESH-WARDEN-0909.md`.
No shipping or visual acceptance. Pending statements below retain earlier history.

## Defect and retained evidence

The current installed Warden is the board-16 rebuild, not the superseded painted-mask body. `docs/art/reference/16_Warden_Aldis_Character.png` shows the full-body Warden holding a wood staff and explicitly labels it **TETHER STAFF (CONTROL DEVICE)**. The current retained production images `ralph/reports/audit/fresh-repro-shots/11-tether-warden.png` and `ralph/reports/T1-VILLAGERS/shots/tether-05-warden.png` show the correct green-haired, bearded Warden bare-handed.

The installed `assets/characters/warden/warden_lod0.glb` has one skin, 24 joints and complete idle/walk/sprint/jump/throw animation tracks. The missing silhouette is not an old model or missing animation. `docs/specs/ASSET_LEDGER.md` records that the installed candidate won partly because the staff-negative take was selected, and `data/config/art.json` previously declared no Warden accessory. No suitable installed staff, cane, rod or wand prop exists; an unrelated axe, pickaxe or torch was not substituted.

## Bounded implementation

- `data/config/art.json`: the Warden alone declares five non-colliding pieces on the installed rig's actual `RightHand` bone: a 3.5 cm wood shaft, muted-gold ring and hub, and two restrained leaf-green capsule marks. The 1.65 m shaft is fitted along the current idle hand axis from standing ground to shoulder height.
- `scripts/characters/character_model.gd`: accessory primitives now accept an optional explicit rotation, and a `cylinder` may declare height independently from diameter. Existing box/ring/disc/capsule/sphere defaults remain unchanged.
- `scripts/characters/npc_ranks.gd`: rank badges append to a deep copy of base identity accessories. The previous replacement would have discarded the Warden staff in every real ranked build. No parsed base or rank dictionary is mutated.
- `tools/_probe_warden_staff_geometry.gd`: initialized production-config/rank-path proof. It builds the actual fitted Warden under an active SceneTree and samples idle at 0.00/0.72 seconds and walk at 0.28/0.91 seconds.

No cloth, emission, badge, body, collision, gameplay, imported asset or other cast geometry was changed.

## Focused proof

Final run: `.artifacts/warden-staff-geometry-0909-r3/`

- UTC: `2026-09-09T17:31:05.8189785Z` to `2026-09-09T17:31:07.2575528Z`
- command: `.artifacts/warden-staff-geometry-0909-r3/command.txt`
- isolated profile: `.artifacts/warden-staff-geometry-0909-r3/{appdata,localappdata}`
- raw output: `.artifacts/warden-staff-geometry-0909-r3/stdout-stderr.log`
- engine log: `.artifacts/warden-staff-geometry-0909-r3/engine.log`
- result: exit 0, **79 assertions, 0 failed**, Godot processes after exit: 0

The actual instantiated nodes prove:

- all five pieces exist on `RightHand`, with every BoneAttachment resolving the same live bone origin;
- the hand origin intersects the shaft axis and lies within its length;
- the shaft and circular head have 0.0000 m separation in every sampled pose;
- the hub is centred in the ring and both leaf marks remain attached;
- the rank path retains all five identity pieces and appends the existing rank badge pieces;
- the shaft is an actual 1.65 m × 0.035 m `CylinderMesh` at the current Warden scale;
- the idle low end lands within 0.12 m below to 0.16 m above the standing plane, the high end stays in the board-16 shoulder-height band, and the control head is above the gripping hand;
- the same joins remain exact at both walk samples while the staff follows the animated hand.

The first run is retained under `.artifacts/warden-staff-geometry-0909/` (UTC `17:26:43.6566466Z`–`17:26:45.3679379Z`, exit 1). It caught the literal `Hand.R` mismatch: this rig calls the bone `RightHand`, so the existing accessory fallback made the parts static. No result from that run is presented as proof. The second diagnostic under `.artifacts/warden-staff-geometry-0909-r2/` (UTC `17:28:32.6198596Z`–`17:28:34.1790206Z`, exit 0) proved the corrected live attachment and exposed the initial longitudinal placement as inverted. The final fitted run above supersedes it. All three raw logs remain intact.

`data/config/art.json` parses successfully and `git diff --check` reports no whitespace errors in the owned source/config files. No import, world boot or render was run.

## Remaining disposition

The component proof establishes attachment, scale and continuity. It cannot judge whether the code-native staff reads as the intended control device beside the current Warden.

One bounded matched capture used `tools/_capture_warden_staff_ab.gd`, derived from the mature bare-stage camera/light setup in `tools/_capture_npc_cast_test.gd`. It built the actual `NPC_RANKS.config_for("warden")` config twice. The baseline deep copy filtered exactly the five `tether_staff_` descriptors, retained both production rank badges, and reconstructed byte-equal to the unchanged after config when those five entries were restored. Both variants used baseline body bounds for the same `seat_y=-0.0000`, fixed camera `(0,1.1,2.6)` looking at `(0,0.9,0)`, identical lights and waits, idle time `0.72`, walk time `0.28`, and 1280×800 Compatibility rendering. It loaded no world, terrain or other cast member.

Capture artifact: `.artifacts/warden-staff-capture-0909/`

- UTC: `2026-09-09T17:42:46.9990480Z` to `2026-09-09T17:42:56.5970452Z` (9.598 s)
- exact command: `.artifacts/warden-staff-capture-0909/command.txt`
- raw receipt: `.artifacts/warden-staff-capture-0909/receipt.json`
- resource samples: `.artifacts/warden-staff-capture-0909/resources.csv`
- raw logs: `.artifacts/warden-staff-capture-0909/{stdout.log,stderr.log,engine.log}`
- manifests: `.artifacts/warden-staff-capture-0909/{image-manifest.json,raw-manifest.json}`
- process identity: launcher PID `14740`, owned PIDs `[11720,14740,16144]`, retained process handle `1288`
- result: exit 0, no stop reason, peak system commit `59.2323%`, peak process count `260`, stderr empty, six PNGs, Godot processes after exit `0`

Matched frames and SHA-256:

- baseline front idle: `baseline/front-idle.png` — `B2A0720F017E9F963CB073E22B61976528E0976576A172AC3700D9B3071DE038`
- after front idle: `after/front-idle.png` — `7F99D43A167AD5BE9FE141DDC8D38187F103910FC25BA6B66DDEFF757B1AE1E3`
- baseline 35° idle: `baseline/three-quarter-idle.png` — `F38B702D90BB1D0FA70150FA05634F238F55712FFAE0C0916473CEA90D24BF51`
- after 35° idle: `after/three-quarter-idle.png` — `D782BE305E13FD1A58BDAB80A2D17377823471089BBCE017A26062663CFFDB58`
- baseline front walk: `baseline/front-walk.png` — `C62FBA4CAFDBF2022E67CEDAB0C4EF5932AEA1C16C06386AC1C5224FD0C4E9E5`
- after front walk: `after/front-walk.png` — `9034BDDE2BFEBC6F6C5DE96A605CE0426B0386FFABCC8D8431D2C936C8D0837E`

Raw SHA-256 values are retained in `raw-manifest.json`; stdout is `0DFC45E49DE066A3A437205E23E9E4854AD788316ADB440AE146557F78104542`, empty stderr is `E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855`, and engine log is `AD4F61355EF836350D79963C8D8B03CC606061D1FE1C7CF536179C88665BD85B`.

These frames are component appearance evidence only. They require a fresh independent image-only verdict. No author verdict is supplied, and no production field/world acceptance follows from a bare-stage capture.
