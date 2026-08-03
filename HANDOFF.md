# HANDOFF — read this first

Owner's standing directive: build the first fifteen minutes of gameplay so it
looks and feels like `docs/01_GAME_DESIGN.md` and `docs/02_ART_BIBLE.md`
describe, a Palworld or Pokemon-on-Switch grade opening rather than a tech demo.
Everything else is subordinate to that.

The owner has repeatedly rejected a claim of "verified working" that turned out
to be wrong. **Do not report anything fixed from a screenshot glance, and do not
report it fixed because the tests are green.** Get a material property, a mesh
count, a pixel, or a state read out of a running browser before you say a thing
works. A whole session of this one was spent tuning tint values against a defect
that no tint could reach, so: confirm which system a defect belongs to before
changing anything.

## The visual pass, and what it changed

The owner's verdict entering this session was that the visuals were "so far
off", with the bar set at "it looks like Palworld or we stop". The reference is
five Palworld screenshots, now in `docs/reference/`, which is what the critic
loop scores against.

Five things were wrong at once, and the frames only got better when all five
moved:

- **No grade, and no headroom for one.** Every material the game creates is a
  `StandardMaterial`, whose lighting term clamps to 1.0 before albedo. Nothing
  could be brighter than its own albedo, so there were no highlights and nothing
  to bloom. There is now a `DefaultRenderingPipeline` (D63). Two ordering traps
  in `Engine.ts` are load-bearing and commented there; read them before touching
  the constructor.
- **The ground read as brown dirt.** Biome vertex colours are ALBEDO, multiplied
  by a detail texture and again by sub-1.0 light. The shipped value is roughly
  what a frame shows times three.
- **The meadow was 95% bare.** `minDistance`, not `density`, was the binding
  constraint on ground cover: the ceiling is about `0.318 * density /
  minDistance^2`. Do not push `minDistance` under ~1.0; the Poisson pass costs
  25 `mask()` calls per grid cell at ~80 noise evaluations each, so cost grows
  as its inverse square and chunk streaming becomes a soft hang.
- **The first frame was a bald plane.** A 19m disc of suppressed ground cover
  sat centred on the spawn point. Now 0; the per-house clearings do that job.
- **The vegetation models were wrong** (D64). This was the real one, and it was
  reached last, after a lot of tinting. See that record.

New: `SunDisc.ts` (also what makes bloom visible at all), `FarRidge.ts` (the
hazy mountains; camera-locked and running invented noise, both deliberate and
explained in the file), per-instance colour on every scatter prop, and pals now
cast shadows.

## Tools

`tools/probe.mjs` is new and is what you should use while iterating: three
frames instead of nine, and `--close` puts the camera at head height, which is
the only framing that shows ground cover honestly. `tools/survey.mjs` is for the
record. Both need `CHROMIUM_PATH=/opt/pw-browsers/chromium` exported or they
launch nothing.

## Known gaps, honestly stated

- **The ground has no macro variation.** One flat vertex colour per biome under
  one 9m-tiling desaturated photo. Biome transitions still snap over a single
  2m quad. This is the largest remaining gap to the reference.
- **No clouds.** The sky is a two-colour vertical gradient plus a sun disc. Every
  reference frame has cloud. `SkyDome` paints a 1x256 ramp; the cheap upgrade is
  a second alpha-blended shell with an FBM texture painted ONCE at boot and
  tinted per palette by a single `Color3` write. Do not repaint a large canvas
  on palette change; it is a several-hundred-millisecond hitch several times per
  in-game hour.
- **Still one variant per family.** `propPlan.ts` takes `variants[0]`
  unconditionally, so every oak in the world is one mesh. Per-instance colour
  now hides this much better than it did, but the batcher upgrade is still owed
  and all the variants ship.
- **The survey's `meadow-open` viewpoint is underwater.** The terrain at
  (420, -260) is below water level, so two of the nine survey frames are mostly
  water plane. That is a bad viewpoint, not a rendering bug, but it makes the
  contact sheet read worse than the game does.
- **Performance is unmeasured on real hardware.** The ceiling was lifted
  deliberately for this work (D63) and vegetation triangle costs went up 3x to
  16x per model. Nothing here has been on an Ally. Frame times in the survey are
  software-rendered and are not a device measurement. `?stats=1` on the real
  device is the only number that counts.
- **The gamepad fix has still never been tested on real hardware** (D61).
- **The starter trio is spread along the wrong axis**, needing a change in
  `src/ui/starterPlacement.ts` rather than in data.

## Harness trap that will cost you an hour

Headless Chromium throttles requestAnimationFrame hard, so the fixed-step loop
barely ticks. A `page.keyboard.press('KeyE')` is never sampled and the game
looks completely broken when it is fine. Hold keys for 2.5 seconds or more, or
drive the DOM directly. Dialogue choices are `.dlg__choice` elements, not
`<button>`. The panel advances on `pointerdown`, which is not throttled.

For screenshots the render loop re-poses the camera every frame: pose LAST,
immediately before the shutter, or use `loop.stop()` first.

## Standing project rules

See `CLAUDE.md`, which wins over this file, and `docs/` which wins over that
except on the two conflicts `CLAUDE.md` names. Party cap 5 enforced only in
`Party.add()`. The player never wields a weapon. The throw is always available.
No storage box. Every tunable in `src/data/*.json`. Seeded RNG only in world
generation. TypeScript strict. Files split past 300 lines. Fixed 60Hz via the
`Loop.ts` accumulator. Dispose everything you create. Write the test before the
formula in `combat/` and `party/`.

Run `npm run decisions` for the next free number before writing a decision
record. Do not guess it.
