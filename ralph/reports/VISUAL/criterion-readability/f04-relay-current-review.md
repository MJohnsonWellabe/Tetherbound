# F04#1 — current relay presentation review

Date: 2026-09-27. Independent code-blind review of selected native 1920x1080 images in `D:/tetherbound/visual-acceptance/shots/relay-criterion-baseline`. Verdict: **F04#1 is not visually accepted in this witness.** Basic warning/recovery text and creature identity read, but camera obstruction, overlapping bodies and an obscured ground lane prevent the attack from becoming a clearly readable travelling-charge problem with a visible tactical answer.

## Scope and criterion

Inspected exactly these 20 native files: `0001.png`, `0010.png`, `0015.png`, `0020.png`, `0025.png`, `0030.png`, `0031.png`, `0032.png`, `0040.png`, `0060.png`, `0064.png`, `0070.png`, `0075.png`, `0079.png`, `0080.png`, `0082.png`, `0090.png`, `0113.png`, `0120.png`, `0128.png`. The packet contains 128 PNGs; this is selected critical-frame review, not exhaustive or continuous playback. Manifest state labels were used only to orient tell/commitment/recovery samples, not as proof that the intended action is visually readable or correctly implemented.

Disclosed fixture: production CameraRig and HUD; staged Captain Vance approach through challenge; level12 Terrapup starter; first two send-outs resolved through the manager to reach the actual third Tuskroot; no actor-position or attack-timing overrides; first tell stationary and later ordinary move_right input. This does not establish an earned complete encounter, all party compositions, all camera positions, difficulty, collision safety or smooth motion.

Basis: `docs/design/ART_DIRECTION.md`, the Captain Vance and Relay criterion in `docs/design/BOSSES.md` section4.2, and the previously viewed approved Meadows/Palworld references. The relevant target is a full-body charge cue, visible travelling lunge, readable ground path and tactical response at the normal camera. No production source/config/diffs or prior review reports were inspected for this task. No engine or edits to production were performed.

## Blocking findings, by impact

### 1. Combat framing hides the information needed to respond

`0001` is almost entirely an extreme close-up of brown geometry, with only the HUD reliably readable. This is a real bad displayed frame in this staged entry; sampling does not establish how long it persists or whether it recurs at every entry. `0010` improves visibility but the creatures' large overlapping head/body shapes occupy nearly the entire central and lower frame. The ground between them and their escape-side edges are largely unavailable.

The issue persists beyond initial entry: `0060`/`0064` lose the ally's left/lower silhouette behind a large diagonal foreground surface. At `0075`, a thick horizontal foreground beam covers the lower part of the encounter, including foot/ground information. At `0128`, large dithered translucent creature surfaces overlap across much of the screen; the enemy remains recognizable, but sorting the two bodies and their relation to the ground becomes harder.

This is not just a request for prettier framing: the hidden space is the space needed to judge a lateral exit. Cause class visible from images: camera/composition and foreground occlusion, with actor scale/spacing contributing. No specific code cause is inferred.

Acceptance witness: at the same production entry and ordinary sidestep, keep both combatants' relevant silhouettes, the attack lane and at least one reachable lateral exit readable through tell, travel and recovery. An initial geometry-filled frame and foreground beams should not replace the decision space during an actionable cue.

### 2. The attack reads as contact pressure, not a clearly travelling charge

In `0015`, `0020`, `0025` and `0030`, the creatures are already nose-to-nose. Tuskroot's head stays close to the ally's face with a relatively similar standing silhouette. These selected tell poses do not show a strong, unmistakable whole-body loading action: a lowered head, braced stance or other distinct charge preparation is not clearly separated from ordinary close contact at this framing.

The tightly adjacent samples `0030` to `0031` to `0032` show Tuskroot pressing farther into the ally followed by a pale hit overlay and hit spark. They do not expose a long, understandable journey across open ground. This is a visual delivery failure in the captured configuration, not a claim that the code has no displacement or that uninspected intermediate frames contain none. Likewise `0079` to `0080`/`0082` reads as another overlapping-body hit. A travelling-lunge or authored distance pass cannot be inferred from manifest counters.

There is a useful lowered-head recovery silhouette in `0040` and `0090`; preserve it. Its relationship to the attack would be stronger if the preceding loading and travel shapes were comparably distinct.

Acceptance witness: at ordinary engagement distances, visibly distinguish loaded anticipation, committed travel through identifiable ground space and lowered recovery. Show the feet/body progressing along that lane at gameplay speed, including a missed charge beside a player who exits it. That requires a continuous witness in addition to native keyframes; no smoothness or exact timing judgment is made from these samples.

### 3. The ground cue is conspicuous in color but incomplete as tactical geometry

`0015` has a very bright magenta ring/strip beneath the creatures. `0020` shows a lane-like shape toward the lower-left edge, but much of its extent and shape sit beneath bodies and the HUD. By `0025`/`0030`, the visible cue is mostly disconnected strips around feet plus fragments between creatures. In `0064`, `0070`, `0075` and `0079`, similar magenta fragments do not supply a readily traceable start-to-end ground path. `0113`/`0120` still mostly show segments beneath the ally rather than a clear lane with a readable safe side.

`0128` is a partial positive: a large leftward arrow is unmistakably visible and gives a directional hint. Yet its endpoint is cut off at the left edge, the bodies heavily overlap, and the ally's dithered silhouette crosses the mark. This does not demonstrate where the threatened corridor ends or where the controlled body can safely stand.

The movement fixture exposes more surrounding ground later, but the ally still takes a visible hit in `0080` (spark/white overlay and reduced health bar). That is not proof movement or evasion is impossible; the samples do not identify exact input onset, successful lane exit or collision outcome. It means this sequence does not provide a visible successful tactical answer. Text saying to move is not a substitute for seeing which side is safe.

Acceptance witness: the normal camera should show the marked corridor's meaningful boundaries, direction, and a distinct open side during the whole actionable tell, followed by a clearly visible lateral miss. Maintain a useful grounded cue without making it a body-obscuring overlay. Proving a safe physical route still needs gameplay/collision evidence outside this image review.

## Bounded passes and strengths to preserve

- Enemy name, level, element and health are readable. Yellow `incoming — move` text is plainly legible at `0015`–`0030`, `0064`–`0079` and `0113`–`0128`; cyan `it's open — hit it` is distinct at `0032`/`0040` and `0080`/`0082`/`0090`. This passes basic state-text visibility, not the full-body tell or tactical-path criterion.
- Tuskroot's brown face, tusks and green rock/moss back retain a recognizable species identity. Terrapup's white face marking, blue eye and pale stone plates remain distinct in ordinary unhit views. The visual fix should preserve these identities.
- Hit events are conspicuous at `0032`, `0080` and `0082` through sparks/flash and health loss. The pale overlay reduces ally surface detail, so this is a pass for event noticeability only, not polished hit rendering.
- Lowered Tuskroot head/body posture during `0040`/`0090` supplies some recovery distinction; there is also usable open ground visible beside the combat at several frames. Neither alone establishes a safe dodge route.

## Final status

F04#1 remains **blocked visually** on this current production-camera witness. Prioritize readable encounter framing, then a visibly separated load/travel/recovery sequence and traceable ground corridor with a demonstrated lateral answer. These findings do not prescribe a model-size or controller implementation. No full encounter, Bar A, Bar B, timing, smoothness or whole-game acceptance is declared. The stills establish concrete readability failures; they do not prove unseen motion or the absence of a mechanically possible dodge.
