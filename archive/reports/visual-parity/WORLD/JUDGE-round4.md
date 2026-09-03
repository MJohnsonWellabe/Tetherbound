# Visual Judge — WORLD round 4 (blind)

Method: compared round4 stand frames against round3 stand frames (same 9
camera/time-of-day combinations), against the project's own key art
(`docs/reference/tetherbound-meadows-keyart.png`), against the Palworld bar
references (`docs/reference/palworld-0*.jpg`), and glanced at the 7-frame
repeat-test to check for render-to-render drift. No code, diffs, or reports
were read.

## Per-stand comparison, r3 → r4

**01-spawn-outward-day** — Same frame in every respect I can see: same tree
placement, same shadow shape and length off the two boulders, same cloud
streaks, same sky value. No visible change. Remaining defect (carried over):
ground reads as a flat mid-green with almost no value variation — the only
dark note in the whole frame is the cast shadow, so the grass has no
form of its own the way the key art's meadow does (visible tussock, worn
dirt, colour drift toward the tree line).

**01-spawn-outward-golden** — Same frame. The "golden hour" sun is a huge,
pale, near-white **oval** (clipped flat at the top of frame, wider than tall)
sitting directly over the big boulder, easily 15% of the frame's width. It
throws no golden cast on the scene at all — the grass, fence and character
readalmost identically to the day frame, just slightly darker/browner
overall. This is the sun-halo defect named in the brief and it is
unchanged. Remaining top defect: the sun shape/scale and the total absence
of warm colour temperature on lit surfaces.

**01-spawn-outward-night** — Same composition and same lighting level as
round3 (byte size differs ~12%, but I cannot find a visible difference —
likely cloud-noise or compression, not a content change). Ground is
underlit but still legibly green-black, not pure black; sky is a flat
navy without stars or moon in frame. No change, better or worse.

**01-spawn-outward-dawn** — Same frame as round3: a cool grey-lavender sky,
warm low-angle rim light on the character/rocks. This is actually the one
"dawn" frame in the set that reads correctly (soft cool sky + warm raking
light) — but it is unchanged from r3, so no credit for r4 specifically.

**03-rise-overlook-day** — Same frame. Distance does separate a little:
foreground rock/moss is warmer and more saturated than the far ridge and
village, which fade toward a grey-blue haze — this is the one time-of-day
where the haze-depth cue in the brief is actually present. Unchanged from
r3.

**03-rise-overlook-golden** — Same frame. Same oversized pale oval sun as
the spawn-outward-golden shot, again with no warm light cast on the
landscape below it — the hillside is a flat khaki-grey, not gold. Distance
haze is present (near/far separation still reads) but the colour story is
wrong for "golden."

**03-rise-overlook-night** — Same frame: a near-uniform steel-blue wash
over the entire image, sky and ground alike, with a hard horizontal
horizon line. Ground does not read as ground at night — it reads as the
same material and value as the sky, just below a seam. No change from r3.

**03-rise-overlook-dawn** — Unchanged and still broken: the entire frame,
sky and ground together, is a flat, saturated red-orange wash with no
horizon-line colour separation and no gradient toward the sun. This is
the single worst frame in the set relative to any reference — it does not
read as dawn, sunset, or any real sky.

**06-moon-stand-night** — Unchanged and still broken: same flat oxblood/
maroon full-frame wash as round3, with a pale pink circle standing in for
the moon. Given this is meant to be the moon-focused night beauty shot, it
is the frame furthest from "cool blue night" of anything in the set.

**Repeat-test (drift check)** — `_sheet_repeat.png`: frames 04–07 (dawn
re-applied four times with nothing else changed) are visually identical to
each other and to frame `01-spawn-outward-dawn`/the round3 dawn stand. The
red-wash dawn bug is fully deterministic, not a flicker or a race — it
reproduces the same way every time the dawn preset is applied. Day/golden/
night sanity frames in the same sheet likewise match their round3/round4
stand counterparts. No render-to-render drift observed anywhere in this
sheet.

## Summary of round3 → round4

Across all 9 stands, I cannot find a single visible content change. File
sizes differ by fractions of a percent to ~12%, consistent with
non-deterministic cloud noise/dithering in a re-render, not a lighting or
scene change. Every defect present in round3 is present, unchanged, in
round4:

1. Oversized pale sun oval at golden hour (both spawn-outward and
   rise-overlook) — **still present, unchanged.**
2. Dawn overlook and moon-stand still read as a flat red/oxblood wash
   rather than a pink-gold dawn sky or a cool blue night — **still present,
   unchanged.**
3. Night overlook still a flat steel-blue wash with no ground/sky value
   separation — **still present, unchanged.**
4. Day and dawn spawn-outward and day/golden overlook distance-haze
   separation — **the one thing that already worked, still works,
   unchanged.**

## Answers to the brief's specific questions

**(1) Is the low golden/dawn sun still an oversized oval/halo?**
Yes, unchanged. In both `01-spawn-outward-golden` and
`03-rise-overlook-golden` the sun is a pale, pill-shaped blob roughly
15% of frame width, flat-clipped at the top edge, with no visible warm
light cast onto the scene below it. It reads as a lighting-rig artifact,
not a sun.

**(2) Do dawn and night overlook frames still show a uniform red/orange
wash where the key art shows cool blue night and pink-gold dawn?**
Yes, unchanged, and this is the biggest single problem in the set.
`03-rise-overlook-dawn` and `06-moon-stand-night` are both flat,
full-frame red/maroon washes with no sky gradient and no separation
between ground and sky value. `03-rise-overlook-night` is a flat
steel-blue wash (better hue than the dawn/moon frames, but equally flat).
None of the three come close to the key art's NIGHT panel (deep blue sky,
visible moon and stars, warm firelit village windows standing out against
the dark) or its golden-hour standing-stone panel (graduated orange-to-
lavender sky with the sun as a small, warm, partially-occluded disc near
the horizon).

**(3) Does distance separate (near warm / far cool, haze) at the overlook
by day, golden, night?**
Day: yes, weakly — the near ridge is warmer/more saturated than the
hazy blue-grey far ridge and village. Golden: yes, similarly, though the
whole frame skews cool/khaki rather than warm. Night: no — the flat
steel-blue wash gives no near/far value or hue separation at all; the only
depth cue left is the silhouette of the near ridge against the horizon
line.

**(4) Does night ground read (not black) while the sky stays dark?**
At spawn-outward-night, yes — the ground is dark but distinguishable
(grass blades, boulder, fence posts all still legible), and the sky is
comparably dark navy, so the two don't separate especially well but
neither is "black." At rise-overlook-night, no — ground and sky are the
same flat blue value across a hard horizon seam, so "sky stays dark, ground
reads" does not hold; they're both the same wash.

## Three biggest gaps vs. the key art (ranked)

1. **Time-of-day colour is not being generated — it's a flat colour wash
   over an otherwise-day-lit scene.** The key art's NIGHT panel is built
   from actual dark-blue sky, visible moon/stars, and warm lit windows
   punching through the dark; its golden panel is a graduated sunset sky
   with a small warm sun disc. Round4's dawn and moon-stand frames are a
   single flat red tint laid over the daytime geometry with no gradient,
   no stars, no distinguishable light sources. This is the largest,
   single most damaging gap and it is present in 3 of 9 stands
   (dawn-overlook, night-overlook, moon-stand).
2. **The sun/moon disc itself is the wrong shape, size and colour.** Key
   art suns and moons are small, round, and warm- or cool-tinted to match
   their sky; round4's is a large pale oval that reads as a UI element or
   lighting bug, not a celestial body, in both golden shots.
3. **Flat, undifferentiated ground value.** Even in the working day frame,
   the meadow key art shows worn dirt paths, tussock clumping, and colour
   drift toward tree lines and water — texture that gives the ground form
   at a glance. Round4's meadow ground is a nearly uniform mid-green
   outside of the single cast shadow, closer to a colour swatch than
   Palworld's or the key art's grass.

## Bar questions

**A. Do these frames read as belonging to the world in the key art?**
**No.** The two working states (day, and the one dawn-lit spawn-outward
shot) are in the right register — plausible meadow greens, a soft warm
rim light — but 3 of 9 stands (golden-hour sun shape, dawn-overlook,
night-overlook, moon-stand — effectively half the set once you count both
golden shots) are dominated by artifacts the key art has no analogue for:
a giant pale sun-oval, and flat red or steel-blue full-frame washes. A
viewer shown these next to the key art board would flag the sky/light
immediately, not accept it as the same place at a different hour.

**B. Shown beside the Palworld screenshots, would someone say these are
trying to be the same kind of game?**
**No.** Independent of the lighting bugs, these are empty terrain stands —
no creatures, no combat, no UI, no NPCs beyond the two static trainer
figures — so there is no direct comparison on the criteria the rubric
allows (creature presence, fight-as-event, HUD). On the criteria that do
carry over — ground/foliage density and how much of the frame is empty —
Palworld's fields are busier (grass texture, rock scatter, tree density)
than Tetherbound's meadow, which reads comparatively sparse and flat even
in the best (day) frame.

## Fixable vs. not

**Fixable by scene/lighting-preset changes (no new art needed):**
- The oversized sun/moon disc shape and scale (golden and moon-stand) —
  this is a light/skybox parameter, not an asset.
- The flat red/steel-blue full-frame washes on dawn-overlook,
  night-overlook, and moon-stand — these look like a tint/post-process
  being applied without a matching sky gradient underneath; giving those
  presets an actual gradated sky (as day and the working dawn
  spawn-outward shot already have) is a lighting-preset fix.
- Ground value/texture flatness in the day frame — scatter density,
  ground-texture variation, and worn-path detailing are scene-dressing,
  not new meshes.

**Not fixable without new art or a different pipeline:**
- Matching the key art's per-leaf canopy detail and painterly GI is out of
  scope per the rubric itself (never expected from a real-time renderer).
- If the empty-terrain stands are meant to eventually carry Palworld-style
  creature/combat density, that requires creature placement and combat
  staging that isn't visible in this survey at all — it can't be judged
  "not there yet" vs. "missing," but it is not a lighting fix.

## Bottom line

Round4 is, as far as these 9 stands show, **a no-op relative to round3.**
Every defect the brief asked about by name — the oversized golden/dawn
sun, the red-wash dawn/night overlook, the flat night-overlook wash — is
present in round4 exactly as it was in round3, pixel-for-pixel as far as I
can tell. The repeat-test confirms the dawn bug is fully deterministic
(four re-applications produce the same wash), so this is a real, stable
defect in whatever generates the dawn/night sky, not noise. Whatever
change round4 was meant to test did not reach these frames.
