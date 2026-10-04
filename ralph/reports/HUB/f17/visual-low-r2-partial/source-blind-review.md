# F17 Low R2 partial capture — independent source-blind review

Review date: 2026-10-02. This is an image-only review of six retained farm-door PNGs. No game source, fix narratives, local engine execution, or local game screens were inspected. Findings are limited to native 1920×1080 Low readability and visible appearance from this one ordinary player camera.

## Exact image provenance

Images were viewed from `D:/tetherbound/.tmp/f17-proof-r1/low-r2-artifact/tree/ralph/reports/HUB/f17/visual-low-r2/`:

- `0000-actual-farmhouse-doorway-day-clear-low.png` — standard acceptance image.
- `0001-actual-farmhouse-doorway-night-clear-low.png` — standard acceptance image.
- `0002-actual-farmhouse-doorway-diagnostic-house-lights-off-night-clear-low.png` — diagnostic only; excluded from acceptance.
- `0003-actual-farmhouse-doorway-day-rain-low.png` — standard acceptance image.
- `0004-actual-farmhouse-doorway-night-rain-low.png` — standard acceptance image.
- `0005-actual-farmhouse-doorway-diagnostic-house-lights-off-night-rain-low.png` — diagnostic only; excluded from acceptance.

References used from the prior image-only review:

- `docs/reference/tetherbound-meadows-keyart.png` — STARTING SETTLEMENT, DAY, NIGHT panels.
- `docs/art/reference/19_Meadows_Asset_Boards_Visual_Direction.png` — village life, architecture, ground/props.
- `docs/reference/palworld-02-open-field-path.jpg`.
- `docs/reference/palworld-04-plateau-landmark.jpg`.
- `docs/reference/palworld-05-base-building.jpg`.

Rubric supplied for this review: ART_DIRECTION §4.1 full Bar A/Bar B intent. Bar A requires coherent, appealing Palworld/Animo-class creature/world appeal; Bar B requires Valheim-class light/atmosphere at gameplay distance. Village/Hall intent includes a roof clear against sky, three road depth bands, warm daytime stone/timber, blue night with localized warm windows, and a welcoming settlement. This review applies that supplied intent without inspecting project source or reports.

## Hall as destination

- **DAY: YES**, in both `0000` clear and `0003` rain.
- **NIGHT: YES**, in both `0001` clear and `0004` rain.

The Hall at approximately x=855–1033, y=255–400 remains centered at the street's end. Its central roof clears the sky, and its doorway reads as an endpoint. Warm façade lights retain that cue at night. Nearby houses, intermediate frontage, and the terminal Hall provide three geometric depth bands. These answers apply only to this farm-door view.

## Highest visible defects

1. **Street material and path hierarchy:** Across the standard frames, the central street around x=450–1510, y=420–720 remains an overly broad ochre surface by day and dark mottled surface by clear night. It has weak distinction between a worn travel lane, gathering space, and grass margins. Establish clearer route width, softer grass transitions, and ground variation at useful scales.
2. **Night trainer highlight dominance:** In `0001` and `0004`, the trainer at x=750–1165, y=500–1080 draws disproportionate attention through extremely bright hair, collar/cuffs, and backpack. Pale clothing contains clipping-looking white regions, reducing material detail and competing with the village's inviting light cues. The diagnostics do not establish a cause.
3. **Night rain mood:** In `0004`, the broad sky at y=0–300 becomes pale gray and the house façades at y=300–480 are considerably brighter/less blue than in `0001`. The night-rain view therefore has a weaker blue-night/localized-warm hierarchy and reads less distinctly nocturnal. The Hall remains readable despite this mood gap.

## Other domain findings

- **Architecture:** Near roof masses across y=110–370 still dominate the smaller Hall. Repeated tile rhythm and related gables limit distinctive settlement character. The Hall could benefit from a more individual silhouette or more breathing room.
- **Depth and atmosphere:** The clear-day frame retains strong surface detail/contrast from foreground through Hall and the left mountain. Day rain softens distant forms somewhat, but the path still has a weak depth/value hierarchy. The references separate near ground, village activity, and distant land more convincingly.
- **Vegetation:** The lower-left planting around x=0–650, y=480–875 reads as isolated stiff blades and repeated small flowers rather than coherent planted masses. Grouping and silhouette variety would improve visual cohesion.
- **Village life:** Small figures are visible along the right frontage around x=1090–1220, y=385–465, but useful/social activity is not strongly legible at this distance. No clearly readable creature is present; **creature appeal is unassessed**.
- **Weather:** Rain streaks and a grayer sky are visible in `0003`/`0004`. A still image cannot establish rain motion, temporal consistency, or the full wet-weather experience.
- **Screen composition:** The quest panel around x=1515–1865, y=255–420 obscures substantial right frontage and limits assessment of that area.

## Supported night on/off comparison — diagnostics only

Compare `0001` with `0002` for clear night, and `0004` with `0005` for rainy night:

- In each off diagnostic, trainer hair and backpack are visibly dimmer/less luminous; the backpack appears a deeper orange rather than the brighter yellow-orange of the corresponding standard frame.
- **Clipping-looking white collar and cuffs persist in both off diagnostics.** The trainer remains much brighter than much of the street.
- Visible street, house windows, and Hall doorway/façade cues remain broadly similar between each pair. The images support a trainer brightness difference, not a claim that all village lighting was removed or that the overall night-lighting defect was resolved.
- Clouds, rain streaks, and luminous particles differ between stills. No cause, mechanism, exact light contribution, or general fix effectiveness is inferred from these pairs.

All pixel regions are approximate coordinates in the native 1920×1080 images.

## Partial-capture status and acceptance limits

Capture status supplied with this task: original run `37085229684` failed after a 60-minute wrapper timeout with status `124`; six PNGs were retained, with no manifest, motion capture, or exit-code file. **This is not a complete capture.** These operational facts were supplied by the coordinating agent and were not independently verified by this image-only reviewer.

**Full Bar A, full Bar B, and F17#6 acceptance are withheld.** Four standard Low farm-door stills plus two excluded diagnostics cannot establish either full bar. There are no dedicated Hall/interior, reverse, detail, or motion views, and no Medium/High coverage in this review. The distant Hall destination cue passes the narrow readability question; creature appeal and the full visual standard remain unassessed.
