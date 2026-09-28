# P2-042 accepted second phase comparison

Capture source: `7f98994dd54433b56a938621d3035df11871e94f`, with only
`presentation.phase_readability_candidate.enabled` temporarily true. The
launcher restored false after capture. Windows/NVIDIA Compatibility,
1920x1080, seed 2042, the production camera and both original catalog stands.
All eight stills and 160 timed samples completed without capture failures.
Camera positions match the baseline within 0.0002 m. Production weather
randomizes decorative lightning; matching seeds do not promise identical
flash timing.

Compact evidence is in `after-r2/` and `after-r2-motion/`, committed at
`0fd0893ba`. Raw images remain in the ignored
`.tmp/stormwood-phase2/p2042-after-r2/` directory.

Independent code-blind reviewer: `stormwood_phase_round2_judge`, fresh context
with images, manifest mappings and the visual-judge rubric. No game source,
config, diffs, previous verdicts or catalog status was inspected.

**Four-phase identity: PASS at both stands, native and small size.**
**Readability preservation: PASS. Bar A: NO. Bar B: NO.**

| Phase | Persistent identifying evidence at Sentinel and Stormheart |
|---|---|
| Calm | Comparatively warm brown ground, green foliage and sparse rain, without ground mist. |
| Building | Cyan/green ground, foliage and trunk lighting with diagonal rain; the color field remains distinct beneath Stormheart's enclosed canopy. |
| Break | Dark violet treatment and heavier rain; Sentinel also has visible white sky lightning. Stormheart remains distinguishable without a magenta ground circle. |
| Fading | Warmer ground with pale low mist persisting across the sequence, including Stormheart samples 10 and 19 without a magenta circle. |

The baseline fails the same four-way test. The accepted sequence establishes
warm/sparse, cool cyan, dark violet storm, then warm/low mist. Gold road pulses
and magenta danger circles vary within phases and were explicitly excluded
as phase identifiers. The magenta circle in the Fading still is not a Fading
cue.

Trainer, Sentinel NPC, gold path and the Sentinel's white split remain
readable. Mist stays translucent and does not close the foreground. No new
visible obstruction, scale change, seam or geometry failure was found.
Stormheart's existing enormous dark bark panels, black horizontal band and
ground gaps remain severe defects; preservation is not acceptance of them.

## Full regional bars remain open

The three largest gaps from the references are:

1. Generic character presentation and muddy NPC costume grouping. Lighting
   and background separation are scene work; distinctive costume shapes,
   material grouping and expressive character/creature art remain art work.
   No clear creature portrait in these views supports creature-appeal or
   relative creature-scale acceptance.
2. Stormheart's enclosing bark geometry does not read as a living tree
   stronghold with a visible core and ascent. Grounding, entrance visibility
   and focal lighting are scene work. Coherent trunk/root architecture and
   human-scale stronghold detail also require art work where absent.
3. Thin repetitive ground cover and a flat sparse horizon lack the grouped
   planting, clearings and layered destinations of the references. Clustering,
   terrain/prop composition and value grouping are scene work; foliage and
   ground-material variety remain art needs where the installed forms cannot
   support those groupings.

Bar A is NO because the shared natural/electrical vocabulary does not yet
produce the boards' composed natural world and compelling landmark. Bar B is
NO because character appeal, landscape organization and landmark construction
remain substantially below the five Palworld references.

## Inspection and limits

The reviewer inspected all 16 native before/after stills; 24 native temporal
images (both stands/all four phases at sample 10 in both sets, plus sample 19
in the candidate); both still sheets and all 14 temporal sheets containing
320 temporal thumbnails. References: Meadows key art, both Stormheart
stronghold boards and all five Palworld gameplay images.

This accepts the catalog's eight original still sightings with supporting
sampled phase sequences. It does not establish continuous traversal, complete
transitions, audio, precise flash rhythm, other locations, interface quality
or hardware performance. Those broader claims are not made.

The accepted presentation is enabled following this verdict. The actual
on-disk enabled-config surge suites pass 55 tests / 762 assertions. Their
expected phase rows now include the configured overlay; the previous
in-memory wrapper did not enable production nodes and is not enabled-path
evidence. Phase timing, strikes, damage, progression, camera behavior and
aftermath remain unchanged.
