# Cast image-only visual verdict

Evidence artifact only; not a live backlog, implementation diagnosis or whole-game acceptance sign-off.

## Evidence and scope

Capture: `shots/ranked-audit-current/cast/`, revision `b2fe128ef`, including the merged shading repair. Main baseline supplied for this audit: `1ba253eb`. The capture coordinator reported 128 native 1920x1080 frames, exit 0, no errors and no screenshot skips: 41 humanoid entries with front, rear and face views, plus five lineups. These are entries, not proof of 41 distinct deployed characters.

Review coverage: all entries' front and face contact-sheet views, all 41 individual rear frames, all five individual lineup frames, and individual native front/face witnesses for the findings below. Not every front/face was separately enlarged. Face views are diagnostic close-ups, not gameplay cameras. Full-body views and lineups establish which problems survive smaller presentation.

Image and reference review only. No implementation, asset internals or old defect lists were used to derive the findings. Native filenames below are relative to the capture directory. The current Team Tether and civilian palettes are retained under the owner exception; none of these recommendations calls for palette replacement.

Inspected comparison references:

- `docs/reference/tetherbound-meadows-keyart.png`
- `docs/reference/palworld-02-open-field-path.jpg`
- `docs/art/reference/04_Main_Character_Style_Reference.png`
- `docs/art/reference/22_Main_Character_Choices.png`
- `docs/art/reference/24_Kael_Character_Board.png`
- `docs/art/reference/25_Sera_Character_Board.png`
- `docs/art/reference/16_Warden_Aldis_Character.png`
- `docs/art/reference/npc-board-2026-08-30/00_MEADOWS_NPC_DESIGN_BOARD.png`

The ART_DIRECTION target is recognizable named identities, readable rank without nameplates, coherent stylized materials and a trainer with clear large color blocks. Reference facial and material finish is a target, not a requirement to reproduce illustration pixels.

## Separate acceptance bars

**Bar A — identity: partial, not a full-cast pass.** The trainer, named trio, Warden and many civilian roles clearly belong to the intended illustrated adventure direction. Clothing, silhouettes and practical equipment preserve substantial reference identity. However, inconsistent facial readability and weak differentiation in some repeated entries prevent a complete identity verdict. These neutral-stage images cannot certify the cast's integration into the Meadows keyart world or the later chapters.

**Bar B — genre/finish: fail for the represented cast asset finish.** The cast is recognizably aiming at a stylized creature-adventure game, but the uneven surface quality, unreadable facial details, hard value clipping and ragged geometry remain well below the polished finish target. This is not a gameplay-camera parity comparison: production conversation/travel captures and motion remain necessary. A clean capture run and a merged shading repair do not establish visual acceptance or quantify improvement without a matched earlier capture.

## Ranked findings

### 1. Facial features are frequently too blurred or poorly separated to carry personality

Several faces resolve as dark eye patches and soft painted mouth/beard marks over coarse facial planes. The trainer is noticeably clearer under the same presentation. This affects named and ordinary roles, rather than a single outlier. The oversized diagnostic views expose the problem most strongly; the soft facial read is also visible in full-body comparisons and lineups.

Native witnesses:

- `048_officer_a_face.png`: dark eye surrounds, blurred mouth and coarse cheek/nose transitions.
- `060_innkeeper_face.png` and `058_innkeeper_front.png`: eyes and facial hair lose clean feature boundaries even though the broad friendly innkeeper silhouette survives.
- `084_rival_trainer_face.png`: dark eye shapes and soft mouth reduce the intended expressive face.
- `102_former_tether_member_face.png`: eyes, brow and cheek markings merge into a mottled mask.
- `006_kael_face.png`: the broad bald/bearded identity survives, but the eyes and beard detail are substantially less resolved than the board.
- Comparator: `003_trainer_face.png`; recurrence at smaller scale: `126_lineup_03.png`.

**Repair class:** face texture/feature definition plus targeted facial form and shading. The images do not identify whether resolution, UV allocation, filtering, normals, lighting or a combination is responsible. Diagnose that before replacing assets or applying a global sharpness treatment.

**Acceptance witness:** the same diagnostic angles, then actual conversation framing and a slow head/camera turn. Eyes, eyelids, mouth and facial hair must remain distinguishable at the intended presentation distance, with character-specific expression preserved. Do not demand close-up illustration detail from distant background NPCs.

### 2. Captain value response overwhelms facial and clothing detail

Captain A's face and hair become nearly solid white over broad regions; Captain B's face and hands become very bright against near-black features. Bright trim outlines compete with the face and turn varied costume surfaces into similar glossy-looking bands. This is visible in the full-body frames and lineups, so it is not solely a diagnostic-crop issue. Comparable forms on the adjacent trainer retain considerably more tonal structure.

Native witnesses:

- `052_captain_a_front.png`, `053_captain_a_rear.png`, `054_captain_a_face.png`.
- `055_captain_b_front.png`, `056_captain_b_rear.png`, `057_captain_b_face.png`.
- `116_captain_field_rear.png`, `119_captain_ridge_rear.png`, `122_captain_riverwatch_rear.png` show the repeated finish in the corresponding variants.
- `125_lineup_02.png` and `128_lineup_05.png` corroborate the imbalance at smaller size.

**Repair class:** material/value response and material separation, retaining the current palette and identity. Do not assume emission, exposure or a particular shader bug from the images. This is a request to recover tonal and surface detail, not to change Team Tether's hues.

**Acceptance witness:** matched stage views under the current lighting plus ordinary sun, shade and indoor production views. Light hair and skin should retain form; metal, cloth and leather should respond differently; captain faces should remain readable without lowering the whole scene's exposure.

### 3. Ragged edges, apparent loose fragments and coarse transitions compromise important characters

Sera's hair/braid and Lyra's hair show angular breaks and small isolated-looking fragments. Kael's fur mantle and Grandpa's scarf show broken-looking surface edges. Several faces and accessories have sharp local triangular transitions inconsistent with the otherwise smooth stylized treatment. The back views reveal additional surface roughness rather than a problem restricted to front portraits.

Native witnesses:

- `009_sera_face.png` and `008_sera_rear.png`: fragmented-looking hair edges and a lumpy, uneven braid surface.
- `012_lyra_face.png` and `011_lyra_rear.png`: thin jagged hair pieces and patchy costume transitions.
- `006_kael_face.png`: conspicuous triangular mantle edges and apparently detached small pieces.
- `015_grandpa_face.png`: ragged scarf surface below the face.
- `078_local_historian_face.png` and `087_field_researcher_face.png`: irregular glasses/face boundaries and local sharp fragments.
- `017_villager_farmer_rear.png`, `023_villager_smith_rear.png`, `029_villager_ranger_rear.png`: repeated angular marks on exposed arms, also visible at full-body stage size.

**Repair class:** targeted mesh/surface cleanup, attachment definition and shading continuity. These are visible symptoms, not a confirmed topology, winding, skinning or alpha diagnosis. Do not flatten designed hair clumps or eliminate intentional clothing layers to conceal the issue.

**Acceptance witness:** native turntables plus the actual idle, walk and conversational gestures, including rear/side views. Hair, fur, glasses, collars and exposed limbs should remain coherent with no visible loose shards, false holes or abrupt surface breaks. Static images cannot prove animation deformation quality.

### 4. Some repeated entries do not carry enough identity or rank information in their silhouette

The generic `rank_grunt`, `rank_officer` and `rank_captain` entries in lineup 04 have essentially the same cap, mask, jacket and trouser silhouette; the front distinction largely comes from a small chest marker. Their rear views are effectively indistinguishable. Likewise, the five `villager_*` entries rely heavily on two repeated bodies/outfits, with three of them mainly distinguished by hair treatment. This is weaker than the clear role variety of the more developed civilian group and the dedicated Team Tether lineup.

Native witnesses:

- `127_lineup_04.png`, `104_rank_grunt_rear.png`, `107_rank_officer_rear.png`, `110_rank_captain_rear.png`.
- `124_lineup_01.png`, `017_villager_farmer_rear.png`, `020_villager_keeper_rear.png`, `023_villager_smith_rear.png`, `026_villager_quarryman_rear.png`, `029_villager_ranger_rear.png`.
- Stronger counterexamples: `125_lineup_02.png` and `126_lineup_03.png`.

**Repair class:** identity/silhouette and role-appropriate accessory or clothing variation within the installed cast and retained palette. This is conditional on use: these images do not establish whether generic rank entries are actually deployed, nor whether aliases depict the same intended character. Do not count every duplicated capture entry as an identity defect or require unique meshes for every background role.

**Acceptance witness:** actual occupied-world encounters without nameplates, viewed from front, side and rear. Rank should read at normal encounter distance; story-relevant recurring NPCs should remain identifiable without relying only on their name. Verify actual deployment before allocating asset work.

## Strengths to preserve

- The trainer has the clearest and most coherent overall finish: readable face, practical backpack, recognizable orb holder, distinct cloth/leather/metal cues and large travel-readable color blocks (`002_trainer_rear.png`, `003_trainer_face.png`).
- Kael, Sera and Lyra retain distinct broad identities: powerful fur-mantled figure, long white braid and layered robe, and nimble scarfed explorer. Their current problems do not justify discarding those designs.
- The Warden's long coat, fur collar, hair, mask and staff create a distinct leadership silhouette (`031_warden_front.png`, `032_warden_rear.png`). His simple staff finish is less convincing than the detailed coat, but this is a localized secondary issue rather than a reason to replace the whole character.
- The developed civilian group is substantially more varied than the reusable villager bases: innkeeper, helper, historian, farmer, researcher, traveler and courier read as different roles through build, hats, aprons, glasses, bags and tools (`126_lineup_03.png`).
- Dedicated Team Tether grunt, officer, captain and Warden forms show an intelligible progression in costume weight and silhouette (`125_lineup_02.png`), subject to the captain material problem above.

## Limits and required follow-through

The uniform stage isolates asset appearance but does not establish world-lighting behavior, natural interaction distance, NPC placement, dialogue presentation, animation, co-op consistency, LOD transitions or target-device performance. Face crops are diagnostic only; fixes must earn acceptance at the real camera. Fine fragments may matter less at travel distance, while broad captain whitening and silhouette repetition already survive smaller framing. No true transparency, exact shader cause, broken rig, missing animation or missing in-world NPC is inferred from these stills. Current palette exceptions remain respected throughout.
