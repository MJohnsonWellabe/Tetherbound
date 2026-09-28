# Independent roster visual audit

Capture snapshot: `b2fe128ef`. Main baseline supplied for this audit: `1ba253eb`. No draft attack branch is included. This is a code-blind visual ranking, not change acceptance, whole-game acceptance, or a motion verdict. Only images, capture metadata and the art-direction/reference material were used; no engine run or production edit was made.

## Scope and sampling

The supplied packet contains 183 native 1920x1080 frames: 57 species with front, rear and a fixed 45%-attack pose, plus 12 lineups. Completion, exit 0 and no skips/errors were supplied by the capture owner. I inspected the complete `_sheet_roster_front.jpg` (all 57 species) and `_sheet_roster_lineups.jpg` (all 12 lineups), then 22 native PNGs listed below. This is complete front/lineup sheet coverage with native outlier sampling, **not native inspection of all 183 frames**, nor complete rear/attack coverage. The first manifest records were checked for capture context.

Native PNGs inspected, under `shots/ranked-audit-current/roster/`:

- `001_terrapup_front.png`, `016_trailpup_front.png`, `026_tuskroot_rear.png`, `027_tuskroot_attack.png`.
- `052_nightburrow_front.png`, `055_stormtrail_front.png`, `061_ashtusk_front.png`, `076_cannonback_front.png`.
- `080_riptusk_rear.png`, `081_riptusk_attack.png`, `085_aquaryn_front.png`, `112_mosshock_front.png`.
- `116_staticub_rear.png`, `117_staticub_attack.png`, `122_fulgocobra_rear.png`, `123_fulgocobra_attack.png`.
- `124_stormraven_front.png`, `142_glimmermoth_front.png`, `169_solmane_front.png`, `170_solmane_rear.png`, `171_solmane_attack.png`, `183_lineup_12.png`.

## Overall judgment and separate bars

**Bar A — identity: substantially present at the roster design/silhouette level, not closed for the complete presentation.** The roster clearly contains designed fantasy companions with recognizable animal families, characteristic faces, meaningful size differences and elemental palettes. The Water and Cloudreach boards have recognizable counterparts. This is a stronger established identity base than the environmental finish seen in the region audit. Preserve it. The current rendered surface treatment reduces the boards' organized material/color hierarchy, particularly on large hero bodies and dark variants. Fixed stage poses cannot establish those identities through ordinary traversal and combat.

**Bar B — finish: below the reference target in the sampled native views; not closed.** Broad irregular color patches, dark internal form loss and soft/uneven hero surface detail are visible at close range. Several sampled attack stills are visibly unacceptable as stage presentations because substantial body parts intersect the floor. They require an in-world check before attributing the same defect to production combat. There is no evidence here for smooth locomotion, weight transfer, attack timing, facial motion, camera behavior, world lighting robustness or performance. Neither bar is a whole-game or chapter acceptance.

## Ranked confirmed still-image priorities

### 1. Restore coherent material and large color shapes across the roster

**Evidence:** `001` has a very readable face and silhouette, but irregular dark patches break up forehead, limbs and paws; `026` has strong mottling across the rear limbs and flanks; `076` carries similarly busy blue/cream/brown patches across shell, tubes, face and legs; `080`/`081` show scattered pale patches across Riptusk's armor and body; `116` has an uneven blotchy rear surface; `169`/`170` have dense bright/dark speckling across Solmane's mane, wings and body. The full front sheet shows this is not one species. The broad treatment also makes quite different physical materials look similarly painted and uneven.

**Impact/recurrence:** this affects creatures that are recurring player focal subjects, and occupies a large share of their visible body. It weakens finish even when the design is readable. It is the broadest proven roster concern, ahead of adding details or redesigning species.

**Repair class:** material/texture/color design first, with asset-surface cleanup where the native shape still looks soft. The images do not establish a specific shader, texture generation, UV or topology cause. The reference boards use more organized light/dark masses and distinguish feathers, fur, shell and smooth skin more clearly.

**Acceptance witness:** compare the same front/rear views and ordinary gameplay distance for Terrapup, Cannonback, Riptusk, Staticub and Solmane. Their existing palettes and silhouettes must survive, while eyes, face planes, limbs and armor/feather groups remain the primary readable structures. Add matched ordinary world day/shadow views to prove the improvement holds outside the stage. Do not erase all markings or make every material uniformly smooth.

### 2. Recover internal form and face readability on dark/elemental variants

**Evidence:** `052` Nightburrow's chest, near shoulder and legs merge into a largely black mass despite the bright stage floor; the white muzzle and purple motes carry much of the reading. `055` Stormtrail's illuminated yellow patches dominate while the muzzle, chest and trunk have very little separation. `061` Ashtusk retains an effective eye/tusk focus but the lower body is very dark. `124` Stormraven is a legible raven silhouette, yet the beak, eye surround and wing/body separation are compressed into a narrow dark-blue range. The complete front sheet repeats this dark-body behavior among several variants. This is a relative visual judgment, not a measured clipping claim.

**Impact/recurrence:** affects recognizable elemental variants throughout ordinary exposure; these are likely to be still less legible against darker environments, but that additional loss needs world evidence. Their silhouettes are already useful and should not be replaced simply to brighten them.

**Repair class:** value/material/lighting balance, with distinct facial and major anatomical color grouping. Stage light contribution cannot be separated from material contribution by these stills.

**Acceptance witness:** match the same neutral stage and actual forest/day/shadow/night views. Retain the intended dark identity and localized elemental accents, while the face, near/far limbs and torso remain visibly separable at gameplay distance without relying on particles. Check alongside a brighter companion so a global exposure lift does not wash out that companion.

## Severe diagnostic finding requiring production confirmation

The fixed attack samples need immediate in-world validation. `027` Tuskroot loses the snout, lower head and front support region into the stage floor. `081` Riptusk places the lowered head and front feet at/through the floor plane. `117` Staticub's muzzle and front legs are cut off by the plane. `123` Fulgocobra has a head/neck portion and body sections disappearing through it, making continuity difficult to read. `171` Solmane loses most of its front body and limbs below the plane. These are clear image defects in this packet, not small ambiguous toe contacts.

The packet does **not** establish whether the stage placement/root convention caused these intersections, whether production combat has the same pose placement, or what the uninterrupted animation does. No claim of stiff motion or successful anticipation/strike/recovery follows from one fixed pose. Rank the **validation** as urgent because of the severity and recurrence; do not turn it into a proven whole-game animation diagnosis yet.

**Repair class if reproduced:** pose/root contact and anatomical animation, potentially rig/asset interaction; source cause is unseen. **Acceptance witness:** uninterrupted ordinary in-world attacks for these five species, at normal camera scale and an unobstructed side/three-quarter witness. Show stance, anticipation, strike, recovery and supported contact with continuous limbs/body, then reproduce a correctly placed neutral diagnostic sequence. Fixes must keep a readable energetic attack rather than merely removing the pose change. A still of a raised body alone is not sufficient.

## Strengths to preserve

- The roster is varied and recognizable on the full sheet: quadrupeds, birds, amphibians, serpents, insects and large legendary bodies have clearly different outlines.
- `001` Terrapup's large eye, cream facial mask, ears and compact paws establish a friendly companion identity. The sheet's Ripplet and Galewisp provide similarly immediate starter readings.
- `085` Aquaryn keeps an elegant long neck and distinctive fin/crest silhouette with a coherent blue/white family. `142` Glimmermoth has an exceptionally readable wing pattern and small expressive face. These are strong identity anchors even though surface refinement remains possible.
- `169`/`170` Solmane's winged-lion mass, gold palette and scale are unmistakable; `183` demonstrates an effective contrast between that body and the long aquatic legendary outline. Preserve this size and shape diversity.
- The darker creatures are not identity failures: Nightburrow's mask and armor, Ashtusk's tusks, Stormtrail's canine outline and Stormraven's bird form read. Their value treatment needs refinement rather than a wholesale redesign.

## References used

Art direction: `docs/design/ART_DIRECTION.md` (read for the current audit). Image references read during the current audit:

- `docs/reference/tetherbound-meadows-keyart.png`.
- `docs/reference/boards-2026-09-06/stormwood-creature-roster-board.png`.
- `docs/reference/boards-2026-09-06/water-realm-creature-roster-board.png`.
- `docs/reference/boards-2026-09-06/cloudreach-cliffs-creature-roster-board.png`.
- `docs/reference/palworld-01-boss-fight-forest.jpg`.
- `docs/reference/palworld-02-open-field-path.jpg`.
- `docs/reference/palworld-03-field-boss-meadow.jpg`.
- `docs/reference/palworld-04-plateau-landmark.jpg`.
- `docs/reference/palworld-05-base-building.jpg`.

The Palworld images support the broader finish/gameplay-presentation bar, not a demand to copy their specific creature designs. All stage evidence is staged diagnostic evidence, not earned playthrough or continuous-motion proof.
