# Flower grouping in Meadows and Stormwood

Priority 2 of [the whole-game ranking](AUDIT.md): reduce repeated prominent
flower heads and give the two colors independent placement. This is a bounded
distribution/scale improvement, not a vegetation-family or regional pass.

## Decision and independent review

Retain the Meadows/Stormwood treatment with the Ridgeline preservation below.
All 24 initial native comparison frames were
reviewed independently of code: each region has five candidate preferences
and one tie. Strongest witnesses are Meadows quarry day and Ironwood day,
plus Stormwood Glowmoss Calm. Grass, shrubs and ferns retain plant mass while
flower-poor intervals separate groups. Village night is mixed: a concentrated
right-hand patch remains conspicuous. Thin stems, simplified heads, repeated
grass, mottled ground and Stormwood darkness remain unfinished.

The broader Ridgeline regression check **blocked unrestricted retention**:
its diagonal purple-white planted edge was weakened, particularly at night.
The initial `final-meadows` packet records that failure, not an accepted result.
The revised implementation opts its lilac tier into preservation of original
positions, yaw, fade rank, size and distribution for cells inside the 72 m authored zone.
A world-cell blend returns to the regional treatment over 16 m outside it.
Source review caught an excessively noisy annulus when noise coordinates were
interpolated; the final shader mixes two completed noise masks instead.
The intermediate run loaded before that source correction is excluded from
the final packet. Fresh `preserved-final` captures use the corrected shader.
The first fresh attempt produced zero frames due to a harness bool conversion
of an unset gold-tier shader override; it was fixed to honor the declared false
default before rerunning. That failure is not counted as a successful capture.

The corrected fresh run exits 0 with four native Ridgeline frames. Independent
review finds the diagonal purple-white group and its night cue restored; both
baseline/candidate pairs are practical ties, as intended for preservation.
The two requested outer-transition stands were skipped because the production
camera spring collapsed. **Outer blend appearance remains unassessed.** No
whole-region or unrestricted transition pass follows from this core-view check.

Tidewake's separate six-pair experiment has four ties and two weak baseline
preferences: Deep Watch loses a small lavender accent without a compensating
group. Its production settings remain unchanged. Cloudreach uses a separate
distribution system and was not changed or captured in this experiment.

- [Meadows and Stormwood native review](flower-patches/flower-patches-visual-review.md)
- [Tidewake review and non-retention](flower-patches/flower-patches-tidewake-review.md)
- [Independent source review](flower-patches/flower-patches-source-review.md)

Both Bar A identity and Bar B finish remain open. No whole-game acceptance.

## Source and scope

The old lilac/gold `seed` fields were never read by the current field builder.
Shared world-cell/item tags therefore reused positions, yaw and fade rank;
different tier counts mean not every flower overlapped. The old config claim
that seeds separated their patches was incorrect.

`placement_seed` now salts those hashes. Optional noise offsets and thresholds
give each tier independent patch distribution; smaller flowers and greater
size variation reduce the repeated large disks. Noise offsets do not enforce
mutually exclusive color territories. Density above one only changes survival
inside the same fixed lattice; it adds no instances. Only the two flower tiers
in `grass_field.json` opt in, inherited by Stormwood. Bushes, litter, grass,
stones, baked scatter, terrain, routes, collision, harvesting and saves keep
their existing configuration. This does not fix the independently baked
broadleaf/groundmat distribution.

The default seed, offset and disabled thresholds preserve the previous
calculation. An independently reproduced CPU hash probe, rerun by the parent,
passed 400,000 default comparisons with zero mismatches and found zero exact
lilac/gold XY matches among 100,000 shared cell/tag pairs. Mean separation was
1.043 m for the sampled 2 m cell. This is formula evidence, not a GPU
minimum-spacing guarantee. Same mesh/instance/draw/texture-read counts. Inside
the preservation zone/blend, the shader additionally computes original hashes
and one original noise field. Parameter blends and rasterized coverage can
change cost. Device cost is open. The CPU hash probe predates this spatial
blend and does not validate it.

## Capture identity and limits

Base `07299f301d04dffe4319ee1371d30e55399f77ac`, with main
`3dad15f417d9538b43cd5d2376ec0c1ab96d991f` integrated, plus the three production
files hashed in the evidence inventory. Fresh GitHub fetch confirmed that
main before captures. A later fetch found `4316362e2`; it changes Cloudreach
test/report evidence and the criterion dashboard, not these production files.
Godot 4.7 stable `5b4e0cb0f`, Compatibility /
OpenGL 3.3, NVIDIA GTX 1060 3 GB driver 560.94, native 1920x1080.

Initial packet: 36 native frames, 18 sequential matched pairs. Meadows:
village, quarry, Ironwood, day/night. Stormwood: Cinder Verge, Glowmoss,
Conductor Run, Calm/Break. Tidewake: First Shore, Reedhaven, Deep Watch,
day/night. All three engine runs exit 0. Meadows records one unselected
dynamic Meadowhart place skip during row construction; all selected pairs
exist. Material receipts identify the intended tiers in each region.

Fixtures disclose staged positions, flags, party, time/phase, hidden HUD,
parked companion and frozen director. Production scene and CameraRig are
used. Wind, weather, actor poses and time can advance between variants.
These views establish comparative composition, not full journeys, combat,
performance, temporal aliasing or whole-region acceptance.

The initial production-config run exits 0 with eight native stills and no skips:
Ironwood and Ridgeline, day/night, original config versus candidate. Runtime
receipts verify both material profiles; independent source comparison matches
all 18 settings exactly and confirms no nonflower config changes. Original
settings are restored from a saved config for the baseline, rather than
mistakenly treating newly loaded candidate settings as baseline. Every pair
in all four manifests has identical recorded feet and camera coordinates
(rounded to 0.1 m). Ridgeline's separate authored mask is still active; its
visible result was independently rejected at Ridgeline, leading to preservation.

That run also records 24 native Ironwood movement samples and 19.736 m
of player displacement through ordinary forward input from the staged start.
The [contact sequence](flower-patches/motion-contact.jpg) includes eight
whole-frame previews and labeled lower-left detail crops. This is sparse
sequence evidence, not smooth-playback, shimmer or performance proof. The
large creature and a later tree partly occlude the field. Five unaltered
native motion frames are committed; all 24 native hashes remain recorded.

Post-config focused tests pass **22 tests /87,833 assertions /0 failures**,
engine exit 0 and empty stderr. These existing tests cover field geometry,
stable lattice rules, independent regional profiles and surface clearances.
They are not an image-quality or GPU-performance test.

The [evidence inventory](flower-patches/evidence-inventory.json) records all
72 native-image hashes (48 comparison stills plus 24 movement samples),
initial and revised production-source hashes, retained file paths and artifact
hashes. Thirty-one unaltered native PNGs, ten comparison sheets, a motion sheet,
five manifests, engine logs, source probe and capture runners are committed.
Full native sources remain in the local `shots/flower-patches-*` folders.
Runners record this machine's absolute paths; relocate those paths before
reproduction elsewhere. Evidence logs normalize trailing whitespace; copied
text artifacts trim blank lines at EOF. Artifact text hashes normalize CRLF to
LF; native images use exact bytes and production hashes record workspace bytes.
