# Occupied street: first scene comparison

Fresh code-blind reviewer `cliffhold_scene_blind` inspected all12 individual
native1920x1080 frames, the visual-judge rubric, ART_DIRECTION, Meadows key art,
Palworld02/04 and the Sky Aviary board. No source/change description/history.
Neutral A=6a8940e5e baseline, B=first occupied-street candidate.

**Both sets: Bar A NO, Bar B NO. B is a real but mixed improvement.**

| View | Preference | Reason |
|---|---|---|
|001 approach day|B, slightly|Raised dwelling gives destination a clearer silhouette.|
|002 approach night|B, slightly|Raised buildings remain identifiable; neither has convincing warmth.|
|003 court day|A|B's blunt retaining wall and house obscure tower; oversized masonry dominates.|
|004 court night|A, slightly|Same landmark regression; extra lights do not compensate.|
|005 Windwatch day|B|Visible stair and upper dwelling establish a second occupied level. Pale lamp heads are defects.|
|006 Windwatch night|B|Stair-side occupation and warmer ground improve; luminous cream slabs and dark stair remain.|

Largest gaps: missing layered surrounding landscape (001–004); blurred ground,
hard transitions, inconsistent vegetation scale and oversized wall masonry;
unfinished architectural integration, slab-like lamps and disconnected-looking
fence ends (005/006). Existing scene/layout/material work can address part;
convincing cliff/ledge silhouettes and finer foliage/transition art may be needed.
Creatures and HUD are absent in this diagnostic and cannot be accepted by it.
No whole C2 or F08#4 acceptance.

First candidate: `after/` ten diagnostic frames, `matrix-after/` three production
matrix frames. Baseline diagnostic is `../route-root-support/after/`; original
matrix frames are `matrix-before/`. All13 candidate images opened by root.
Matrix21/32 show variable live wild creatures obscuring the approach; not a
controlled creature comparison. Diagnostic uses production rig but parks the
companion behind camera, hides HUD and authors flags/time/stand/pitch.

Source review found rail collision and stair surface-index omissions. Both
fixed before the diagnostic run: real native physics27/27, prefab bounds fit;
existing grass tests9/1616/0. Matrix captures precede the collision-only fixes.
Diagnostic log retains pre-existing `fly_tutorial_completed` unscoped flag error,
placement warning and limestone texture UID fallback. Exit0 is not a clean game
validation claim. Full matrix, motion, performance and full suite remain open.

Next real change responds to the two court regressions: narrower, staggered
upper street, finer masonry and installed wall lanterns instead of slab-like
stand assemblies. Do not reroll the first candidate's frames.

## Staggered candidate

Fresh independent `cliffhold_staggered_blind` inspected all12 neutral comparison
frames and the same rubric/references. A=staggered candidate, B=6a8940e5e.
**Bar A NO, Bar B NO for both; A is the stronger settlement arrangement overall.**
Baseline slightly preferred for001/002: tower shaft/roof silhouettes separate
better. Candidate preferred003/004: second occupied level and clearer court
route;005/006: readable stair/upper-street relationship. Candidate still obscures
some tower shaft, retains a slab-like wall/slope join, and needs warmer night
hierarchy. The right fence gap persists. Biggest gaps remain landscape depth,
ground/construction finish and habitation/night hierarchy. No third layout
micro-iteration: next substantial work must supply the missing surrounding
landscape and integrated ground rather than retune the same six frames.

Candidate retained as work in progress, not READY or accepted. Six native final
diagnostic frames in `staggered/`, all individually opened by root. Revised
platform and houses pass independent native actual-physics27/27 and prefab
floor-fit2/2; separate `*-staggered` probes/logs preserve first-trial evidence.
Final production-matrix settlement view is captured separately in `matrix-final/`.
