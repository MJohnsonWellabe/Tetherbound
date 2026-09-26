# Creature attack contact

X04 bug slice against ART_DIRECTION §5.1 and ACCEPTANCE §4. Baseline
`7a6b45ee0` (integration 35). This evidence concerns five installed attack clips;
whole-creature and whole-game Bars A/B remain open. Claude owns integration.

## Reproduction

`tools/capture_creature_attack_contact.gd` boots the production Meadows scene,
uses a disclosed species-adoption fixture and the existing smoke's one initial
position fixture, walks to a wild creature with movement input, engages through
interact, and sends one quick-attack input. It captures actual animation playback,
body position and terrain height through the production combat camera. It does
not alter fighter stats, terrain, animation time, body transforms during combat,
or combat timing. `--view=side` is an optional disclosed camera-yaw diagnostic.

Native Windows Godot 4.7 Compatibility, 1920×1080, GTX 1060 3 GB. Fixed 60 Hz
capture is visual evidence, not performance telemetry or earned progression.
Shared `D:/tetherbound/RENDER_LOCK.json` must be held by `combat`.

```
godot --path . --rendering-method gl_compatibility --resolution 1920x1080 \
  --fixed-fps 60 --script tools/capture_creature_attack_contact.gd -- \
  --species=tuskroot --out=<absolute-output-directory>
```

Tuskroot baseline completed with 61 frames, no harness failures, exit 0. At
`tuskroot_production_028.png` the front of the creature visibly sinks into the
ground. Raw local evidence: `shots/attack-contact-baseline/tuskroot/trace.json`
and its associated PNGs. Existing world-placement warnings were present.

An independent CPU skinning evaluation sampled the five installed clips at
approximately 240 Hz, including exported keys. Bind reconstruction agrees with
source vertices within 4.8e-7 model units. At the production fitted scale, minimum
heights relative to the bind floor were:

| Creature | Attack start | Worst sample | Worst time |
|---|---:|---:|---:|
| Tuskroot | −0.292 m | −1.306 m | 0.458 s |
| Riptusk | −0.665 m | −1.147 m | 0.454 s |
| Staticub | −0.644 m | −1.197 m | 0.458 s |
| Fulgocobra | −1.287 m | −2.508 m | 0.458 s |
| Solmane | −1.571 m | −3.127 m | 0.458 s |

These figures measure deformed skin against a flat bind plane, not live terrain.
The common authored pelvis/spine fold drives the front below that plane. Some
channels also lack a neutral frame-zero key. Anatomy differs: cobra coils use
nominal leg bones, while Solmane's actual hind contact is predominantly root
weighted. A uniform whole-body lift would introduce visible floating.

## Disposition

Attack-only asset candidates and full playback validation are in progress.
No repair or visual pass is claimed by this reproduction commit. Preserve mesh,
skin weights, material, scale, duration, other clips and gameplay behavior.
