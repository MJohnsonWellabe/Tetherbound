# Cloudreach image-only visual verdict

This is an evidence artifact, not a live backlog or acceptance sign-off.

## Capture identity and review scope

- Reviewed all 44 native frames in `shots/ranked-audit-current/region/cloudreach/`, with `manifest.jsonl`: 12 environment stands across six Cloudreach areas at day/dusk/night (36 frames), plus four major approaches at day/night (8 frames).
- Capture checkout: `b2fe128ef`; main baseline: `1ba253eb`. The checkout includes unmerged PR365 work. These images must not be described as shipping-main evidence.
- Staged DRY RUN, actual camera, HUD hidden. Environment stands include Galecrest; major approaches park the companion behind the camera.
- Parent reported process exit 0 and zero screenshot skips. One boot fixture error attempted to set obsolete/unscoped `fly_tutorial_completed`. No new renderer errors were reported. This is not a clean-execution or progression-acceptance claim.
- Review was image-only: no implementation, configuration or prior defect queues informed the findings. References: `docs/reference/boards-2026-09-06/cloudreach-sky-aviary-stronghold-board.png`, `docs/reference/tetherbound-meadows-keyart.png`, `docs/reference/palworld-04-plateau-landmark.jpg`, and `docs/reference/palworld-02-open-field-path.jpg`, assessed against the ART_DIRECTION target contract.

## Separate acceptance bars

**Bar A — identity: partial, not a pass for the represented Cloudreach scenes.** Elevated plateaus, the three-bell bridge, rustic cottages and the recognizable aviary dome establish the intended highland adventure direction. However, the repeated slab-like cliffs, coarse ground cover and comparatively simple landmark construction do not yet achieve the layered landscape and substantial stone architecture of the Cloudreach board or the coherent natural grounding of the Meadows keyart. This conclusion concerns visible scenes only; it does not imply that occluded or uncaptured destinations are absent.

**Bar B — genre/finish: fail for the represented scenes.** The captures clearly aim at a stylized creature-adventure game, but abrupt ground transitions, repetitive terrain forms, coarse vegetation and uneven architectural/material finish remain below the polished gameplay comparison target. Readable routes, recognizable destinations and usable nighttime visibility are strengths, not sufficient evidence of finish parity. These staged stills do not certify motion, earned traversal, device performance or shipping-main quality; the boot fixture error and capture gaps below remain applicable.

## Ranked findings

Ranked by repeated whole-scene impact. All frame names below are relative to `shots/ranked-audit-current/region/cloudreach/`. Repair classes and acceptance witnesses are recommendations from visible evidence, not source diagnoses or implementation assignments.

### 1. Cliffs lack convincing geological form and depth

Large smooth or faceted walls, thin shelf extrusions and pale angular distant formations repeatedly dominate the landscape. Green caps over nearly uniform vertical faces read as constructed platforms. This recurs through the lower cliffs, causeways, ravine, upper region and major approaches.

Strongest witnesses:

- `013_cloudreach_env_windscar_ravine_0_day.png`
- `016_cloudreach_env_windscar_ravine_1_day.png`
- `039_cloudreach_place_sky_shrine_heartstone_day.png` — terrain evidence only; the shrine is occluded.
- `041_cloudreach_place_cliffhold_settlement_day.png`

**Repair class:** asset/form first, material second. Texture contrast alone will not repair slab silhouettes.

**Acceptance witness:** a grounded approach and elevated overlook showing varied cliff profiles, readable strata and coherent near/far rock treatment. Recheck day, dusk and night with distinct terrain depth and natural plateau edges.

### 2. Ground cover reads as coarse grass ribbons and carpets

Large angular blades, uniform fields and abruptly ending dense strips repeatedly overwhelm the terrain. High Roost is especially carpet-like; other locations alternate dense bands with almost bare green ground. Night shifts some grass toward conspicuously pale mint or white.

Strongest witnesses:

- `019_cloudreach_env_high_roost_sky_shrine_0_day.png`
- `021_cloudreach_env_high_roost_sky_shrine_0_night.png`
- `028_cloudreach_env_upper_cloudreach_1_day.png`
- `037_cloudreach_place_three_bells_bridge_day.png`

**Repair class:** asset/form plus distribution and material. The references provide a finer ground layer, varied clump sizes and gradual density transitions.

**Acceptance witness:** the same views plus walking footage, showing natural cover at trainer scale without hard population boundaries or bright nighttime grass bands.

### 3. Paths and settlements sit on visibly segmented ground

Brown route strips have hard polygonal borders; village forecourts contain conspicuous green wedges and soil patches. Broad bare slopes make buildings feel placed onto a surface rather than joined to an inhabited landscape. This remains visible in companion-free approaches.

Strongest witnesses:

- `025_cloudreach_env_upper_cloudreach_0_day.png`
- `026_cloudreach_env_upper_cloudreach_0_dusk.png`
- `004_cloudreach_env_gate_lower_cliffs_1_day.png`
- `041_cloudreach_place_cliffhold_settlement_day.png`

**Repair class:** material integration plus composition. Preserve route readability while creating believable worn edges, verge transitions and grounded building approaches.

**Acceptance witness:** continuous native-camera walks from grass through path to door, including the upper settlement's current patchwork forecourt.

### 4. Landmark construction lacks the reference's architectural hierarchy

The aviary has a recognizable dome, but its many thin lines and comparatively plain stone base read closer to a greenhouse framework than the substantial stone monument in the board. Shrine cylinders, oversized cobble bands, colored rails and flat banners also read as assembled simple shapes. Cliffhold's tower is especially plain at approach distance.

Strongest witnesses:

- `043_cloudreach_place_summit_eyrie_stronghold_day.png`
- `022_cloudreach_env_high_roost_sky_shrine_1_day.png`
- `028_cloudreach_env_upper_cloudreach_1_day.png`
- `041_cloudreach_place_cliffhold_settlement_day.png`

**Repair class:** asset/form first, local material finish second. Establish primary supports, secondary ribs, convincing entrances and restrained crafted details. A global lighting change cannot supply missing form.

**Acceptance witness:** both roughly 90 m approach and close entrance views, retaining existing recognizable silhouettes while making construction and architectural hierarchy convincing.

### 5. Lighting does not consistently establish landscape and destination hierarchy

Several dusk views compress cliffs into similar beige values. At night, grass and stone can become strongly cool and pale while settlement and aviary entrances provide limited warm focal separation. This is not a general nighttime visibility failure: the trainer and main routes remain readable.

Strongest witnesses:

- `017_cloudreach_env_windscar_ravine_1_dusk.png`
- `027_cloudreach_env_upper_cloudreach_0_night.png`
- `042_cloudreach_place_cliffhold_settlement_night.png`
- `044_cloudreach_place_summit_eyrie_stronghold_night.png`

**Repair class:** material/lighting plus composition. Avoid treating this as a blanket exposure or saturation problem.

**Acceptance witness:** matched three-time-of-day views with distinct foreground, middle and distance values, and visibly inhabited landmark entrances, preserving current navigation readability.

## Strengths to preserve

The three-bell bridge and aviary are recognizable destinations. Main approach paths point toward them clearly. Cottage silhouettes establish a coherent rustic family. Dusk produces attractive warm scenes. Nighttime trainer and route readability is generally intact.

## Uncertainty and capture gaps

- Galecrest substantially obscures many of the 36 environment frames. The four companion-free approaches confirm several findings, but companion obstruction itself needs ordinary follow and movement footage before assigning a production repair. Creature shrinking is not implied.
- Frames `010_cloudreach_env_broken_causeways_1_day.png` through `012_cloudreach_env_broken_causeways_1_night.png` appear to place the trainer against steep rock. They are weak witnesses for ordinary grounded traversal; no collision or navigability conclusion follows.
- `039_cloudreach_place_sky_shrine_heartstone_day.png` and `040_cloudreach_place_sky_shrine_heartstone_night.png` show a cliff wall, not the shrine, despite the manifest's “clear sightline” label. They support terrain observations only. Shrine absence cannot be inferred; a valid shrine approach remains a capture gap.
- The boot fixture's obsolete/unscoped flag error prevents claiming clean execution or progression acceptance.
- Stills do not establish flight, interiors, combat, motion quality, full destination coverage or device performance. Unseen destinations and details must not be treated as absent.
- This is a current-checkout ranking against reference targets, not a before/after repair comparison or shipping-main verdict.
