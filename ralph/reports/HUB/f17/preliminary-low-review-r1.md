# F17 preliminary Low-frame visual review — R1

## Scope and provenance

Independent, source-blind visual review performed on 2026-10-02. Only the images listed below and the supplied settled rubric were used. No source code, project reports, or Godot execution informed these findings.

Reviewed gameplay frames, ordinary player camera, native 1920×1080, Low/Compatibility:

- `ralph/reports/HUB/f17/destination-day-night-r2/farm-door-day.png` — Day 1, 08:00.
- `ralph/reports/HUB/f17/destination-day-night-r2/farm-door-night.png` — Day 1, 23:00.

Visual references:

- `docs/reference/tetherbound-meadows-keyart.png` — STARTING SETTLEMENT, DAY, NIGHT panels.
- `docs/art/reference/19_Meadows_Asset_Boards_Visual_Direction.png` — village life, architecture, ground and props.
- `docs/reference/palworld-02-open-field-path.jpg`.
- `docs/reference/palworld-04-plateau-landmark.jpg`.
- `docs/reference/palworld-05-base-building.jpg`.

Supplied rubric: Bar A requires coherent, appealing Palworld/Animo-class creature/world appeal; Bar B requires Valheim-class light/atmosphere at gameplay distance. Village/Hall intent is a Hall roof clear against sky, three depth bands along the road, warm daytime stone/timber versus blue night with localized warm windows, and a welcoming settlement.

## Destination down road

- **DAY: YES.** In `farm-door-day.png`, the Hall at approximately x=855–1033, y=255–398 is identifiable at the road's end. Its tall central roof clears the sky, and its doorway provides a destination cue.
- **NIGHT: YES.** The same Hall region in `farm-door-night.png` remains identifiable. Two warm façade lights help retain the destination cue.

These answers establish destination readability from this camera only.

## Prioritized visible defects

1. **Uniform oversized street surface.** In both frames, the central street at approximately x=450–1510, y=425–720 reads as a broad surface with weak ground hierarchy: uniformly ochre by day and dark/mottled by night. It needs a convincing worn travel lane, softer grass transitions, and small surface variation. Reference paths have clearer usable width and stronger ground hierarchy.
2. **Insufficient atmospheric separation across depth bands.** The near houses, intermediate frontage, and terminal Hall provide three geometric depth bands, but the day frame retains similar sharpness and contrast across them. The mountain behind the left roofs also feels close and materially hard. A stronger distance/value hierarchy would make the Hall and surrounding landscape read as distinct spaces.
3. **Night player brightness overwhelms habitation lighting.** In `farm-door-night.png`, the player at approximately x=775–1140, y=510–1080 is severely brighter than the village, with clipped-looking pale clothing/backpack. This camera-side attention hotspot weakens the warm village lighting's ability to guide the eye toward habitation.

Address these three gaps before adding more small decoration.

## Per-domain observations

- **Architecture and silhouette:** Both frames establish near, intermediate, and terminal building bands. The left/right roof masses across approximately y=110–370 dominate the small Hall. Repeated dark tiles and closely related gables make the street feel assembled from similar modules. Give the Hall a stronger unique silhouette or more breathing room.
- **Ground and materials:** Daytime timber is warm and pale stone remains readable, but the street's broad ochre surface lacks a convincing worn route and soft transitions. See the first prioritized defect for region and action.
- **Vegetation and props:** In both frames, the lower-left planting bed at approximately x=0–620, y=470–880 contains many isolated, stiff blades and repeated flowers. Plant silhouettes and placement feel less cohesive than the references' clustered foliage. The two large stone monuments, particularly the foreground one at approximately x=650–1210, y=425–920, claim more attention than everyday settlement activity.
- **Light and atmosphere:** Day has readable warm materials but limited distance separation. Night establishes blue surroundings and localized warm windows, yet player illumination is excessively dominant. These frames do not establish Valheim-class atmosphere.
- **Village life and creature appeal:** Two small street figures are visible around approximately x=1090–1220, y=385–465, but social/useful activity is weak at this distance. No clearly readable creature is present; creature appeal remains unassessed. More legible lived-in activity or companion presence would better support Bar A.
- **Screen composition:** In both frames, the quest panel obscures substantial right frontage at approximately x=1515–1865, y=255–420, limiting assessment of settlement character from this view.

All pixel regions above refer to the reviewed native 1920×1080 gameplay frames and are approximate.

## Acceptance limits

This is a preliminary structural/readability critique only. **No full Bar A, Bar B, or F17#6 acceptance is granted.** Two Low/Compatibility still frames do not establish the complete visual result. Final acceptance requires native Medium/High views and interior, motion, and weather coverage. Creature appeal cannot be judged from these frames. A fresh Medium/High matrix is pending.
