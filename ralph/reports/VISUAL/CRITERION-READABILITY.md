# Relay and lightning criterion witnesses

## F04#1: travelling relay charge remains open

The code-blind [native-frame review](criterion-readability/f04-relay-current-review.md)
fails the relay charge's readable travel, ground path and lateral answer.
The camera enters geometry at the first send-out view, nose-to-nose bodies
hide the tell and route, and later foreground beams mask the lower frame.
Warning/recovery text, creature identity and impact noticeability pass narrowly.
These are not a full-motion verdict or proof that escape is mechanically impossible.

The first packet is 128 native 1920×1080 Compatibility frames on visual branch
`5504b073d3c0e7030f2d994cf7def431b5dc6f8b`; the 20 reviewed originals are committed
under `criterion-readability/relay-baseline/`, with the complete frame manifest.
A second instrumented run at `9e5e2e16477338ec62a5e3eb28eca4fdf974b75d`
(integrating main `4ee9f4157`) exited 0 and measured three charges:

| Charge | Centre gap at start | Contact reach | Actual projected travel |
|---|---:|---:|---:|
| 1 | 4.481 m | 3.304 m | 1.333 m |
| 2 | 2.753 m | 3.304 m | 0.000 m |
| 3 | 3.554 m | 3.304 m | 0.267 m |

Seven metres is the configured maximum, not the achieved travel. The contact
threshold combines Tuskroot radius 1.289 m and Terrapup radius 1.464 m with the
production 1.2 scale. The second charge starts inside that threshold. The
measured distance is the flat displacement from `lunge_started` to
`strike_ready`, projected along the emitted heading; it does not assume the
maximum was reached. Source inspection confirms contact ends the burst early.
This explains a short shove independently of the camera obstruction. At the
configured 16 m/s, even the first distance affords only roughly 0.083 seconds
of travel; this is a derived estimate, not a wall-clock performance measurement.

Fixture disclosure: actual Captain Vance challenge and third Tuskroot send-out;
level-12 starter, healing at the third send-out, first two opponents advanced
through the combat manager's victory resolution; first tell stationary, later
tells receive ordinary lateral input. Production camera/HUD and enemy profile,
no enemy placement or attack-timing override, no player attack input. These
are presentation/contact observations, not an earned fight or a difficulty pass.
The two runs' movement outcomes differ; do not treat their frame numbers as
matched pixel pairs. Both logs, full manifests, the instrumented harness and
runner are committed; the second packet retains four representative originals.

Next implementation belongs with the existing combat lane: establish space for
the charge before its tell, then prove travel and an actual lateral escape with
the shared camera correction. Do not shrink creatures or animate an apparent
charge that never physically happens. Shared camera/collision work is already
claimed in issue #356 by Stormwood-B and Meadows core; this visual PR makes no
parallel camera or combat tuning change.

F04#6 aftermaths and the other seven owner-listed criteria remain open.

## F10#3: current warning and rejected electrical-path experiment

**Disposition: rejected and removed from production.** The
[independent paired review](criterion-readability/strike-branches-visual-review.md)
prefers the baseline overall. Four repeated, detached pale shapes read as
runes/arrows rather than electrical charge, especially in the near views.
The darker interior also weakens the filled-hazard read. Boundary/countdown
remain legible and impacts are effectively tied, but those preserved features
do not establish improvement. Do not repeat a symmetric ground-glyph solution.
Future warning work needs an electrical buildup that preserves filled-area
readability and survives the trainer's centre occlusion. No new lightning
production change is retained from this experiment.

The [current baseline review](criterion-readability/f10-criterion-current-review.md)
inspected 30 original frames from a fresh 114-frame capture at `5504b073d`.
At the sampled brush stand the former central obstruction is resolved: the
trainer's legs, warning progression and most fill remain visible. Peripheral
fern masking survives. The warning is readable but still has generic area-attack
semantics, and the impact bolt's broad ribbon finish remains weak.

A second 114-frame packet at `9e5e2e164` plus the archived two-file candidate
replaces diagonal hatching with four forked ground paths and darkens the fill.
The fixed 3 m boundary, closing inner ring and accumulating perimeter arc are
unchanged. Both packets use three production-camera stands (outside, inside,
brush inside), normal/reduced motion, native 1920×1080 and Compatibility on the
GTX 1060. Rain and ambient actors are not deterministic pixel matches. The
candidate only changes the lightning shader and its presentation config.

Each packet holds Break and uses a staged warning followed by a no-hit impact
when the real warning tween reaches its end. Fixed 60 FPS is simulation-time
evidence, not device performance or wall-clock flash-comfort proof. Source
manifests retain their historical `DRY RUN` labels; these are disclosed
presentation fixtures under the owner's fixture ruling, not earned-route,
damage, full phase-cycle or continuous-play evidence.

Validation on the rendered candidate: 62 existing tests / 782 assertions,
0 failures; lightning mechanics smoke 40 assertions / 0 failures; cleanup
smoke PASS, including normal/reduced sky/local light and warning/impact expiry.
All four processes (capture plus three checks) exited 0. No shader/script error
was reported by the capture; placement warnings remain in the committed log.
The [independent source review](criterion-readability/strike-branches-source-review.md)
finds no blocking source defect for the current configuration, while noting
extra per-fragment arithmetic and unproven thin-line stability/device cost.

The packet archives 60 original PNGs across the two versions, both complete
manifests, hashes of all 228 generated images, exact candidate source/config,
capture harness, runner and test logs. Full F10#3 remains open: the new
electrical-identity candidate failed, and phase/motion/device evidence remains
incomplete. The current baseline's scoped brush improvement stands separately.
