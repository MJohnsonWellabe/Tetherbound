# Stormwood lightning shape evidence

Owner-directed F10#3 art scope: retain purple, replace the pole with branching sky-to-ground lightning, and make the warning read as an impending strike. #356 comment 5856599855 records the ownership exception. **Scoped lightning still-image acceptance: PASS in normal and reduced modes (judge-r7.md). Whole-frame Bars A/B: NO; the full F10#3 criterion remains open.** PR365 was closed under the subsequent PR-cleanup instruction; this report does not reopen it or claim a merge.

## Production change

The warning keeps the existing 3 m damage boundary and 1.2 s duration. Six irregular leaders grow inward toward a compact contact mark. Its perimeter has soft segmented ends and an open interior. Reduced motion keeps the advancing warning and visible impact while suppressing rim modulation and scaling existing light flashes.

The descending channel has tapered forks at multiple scales, a camera-facing ribbon core and a restrained purple halo. Single-plane geometry avoids doubled front/back contours; Gaussian transverse profiles soften the ground leaders. Original deterministic mesh generation uses its own RNG, preserving host strike scheduling. Strike damage, multiplayer authority, timing and persistence are unchanged. Current main 9850b3be1 is integrated in 63f3006b1; Claude's warning-centre positioning, phase distinctions and restored-sky work remain.

## Native evidence

All captures use Windows Godot 4.7, NVIDIA GTX1060 and Compatibility, saved at 1920x1080. Each mode has 19 samples: 0.0–1.7 s in 0.1 s steps, plus 1.25 s; impact occurs at 1.2 s. Fixed60fps keeps engine sample timing deterministic. This is a production CameraRig fixture at the Surge strip, frozen noon Break, stationary trainer and scripted impact with HUD hidden and no damage. **DRY RUN — does not count toward earned chapter completion.**

- `lightning-shape/before/`: pinned Claude request 387cf60fdcf9b65c1ef01c418b4f3bb07718e1d6, original 19 frames.
- `lightning-shape/after-normal/` and `after-reduced/`: latest finish candidate, source commit 20f86ab4698bb4dbd4273939234a548e7086a294, source blobs hashed in `frame-manifest.json`.
- `lightning-shape/reviewed-r3/`: representative preceding failed frames; all originals remain in the local capture directories named by the review.
- Run logs, frame dimensions/hashes, focused tests and independent source/visual reviews are adjacent. Latest focused validation: **64 tests, 819 assertions, zero failures**; neither capture log contains a script/shader error.

The baseline and candidate branches also differ in vegetation. Whole-frame comparisons are therefore not pixel-isolated proof of the lightning change. Neither set proves night/phase coverage, ordinary combat/HUD interaction, co-op or Ally performance. Ordered samples show states; they do not certify perceived continuous timing or photosensitivity safety.

## Review history and next gate

R1 failed countdown and bolt shape. R2 passed warning information but failed rigid bolt shape. R3 passed countdown, footprint, branching silhouette, contact, recovery and retained reduced information, but failed graphic finish: hard foreground cuts and thick outlined lightning. R4 softened the tube and segment ends but failed hollow/doubled contours, flat ground strips and weak contact hierarchy. The latest revision changes geometry to a single camera-facing ribbon and gives the ground leaders a Gaussian profile; R5 passed information and branching identification but failed weak channel/contact finish. The next candidate increases main-channel weight, adds short return arcs and uses capsule-ended segments after a core/halo isolation exposed hard-end wedges. R6 passed warning, branching identity, contact/recovery and reduced information but failed swollen luminous joints. R7 narrows the bright core, strengthens selected secondary forks and reduces the halo; the independent review passes all scoped lightning still-image gates. No broader scene acceptance is implied. The local light remains restrained. The competing yellow road emission is existing scene work and remains a whole-frame failure. No same-frame repeat verdict was used as progress.

Whole-frame Bars A/B still fail: empty distant terrain, missing forest depth, competing bright road channels and inconsistent living-subject presentation. Those remain in the whole-game audit; this bounded change cannot close F10#3 or F10#4 by itself.

## Provenance

Both approved Stormheart stronghold boards under `docs/reference/boards-2026-09-06/` were opened before authoring. They informed electrical silhouette, taper and hierarchy only. All mesh vertices and shader code are original project work. No new purchase, Meshy submission, roster expansion, copied reference pixels or external geometry is involved.
