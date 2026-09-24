# Cloudreach from the production player camera — ROADMAP step 11

STATE and ROADMAP step 11 call the earlier Cloudreach survey stands unusable:
some sat below the floor, and some looked straight at authored landmark
elevations. This lane re-captures the four quick-tour stands through the
production camera's geometry and gets one blind verdict on the result.

## The capture tool (`tools/_capture_quick_tour_cloudreach.gd`)

- **It never ran on main.** It called `_run()` from `_init`, before the `Game`
  autoload exists, and quit with "Game autoload is missing". It now defers
  its start, as `capture_cloudreach_act_one.gd` does.
- **Production camera geometry.** The pivot sits at the trainer's feet plus
  movement.json's camera height (1.75m), on a 5.2m arm, yawed toward the
  target.
  - The pitch is the rig's resting pitch (−12°). It tilts up only as far as
    keeps the target inside the top of the frame, and never past the rig's
    +32° limit.
  - The old free camera looked straight at each target's authored
    elevation. That left the trainer at the frame edge (cliffhold) or out of
    frame (summit).
- **Framed where the trainer settles.** Each shot is taken where the trainer
  actually ended up. The tool first holds the trainer on the stand until a
  collider exists under it (bounded at 600 frames). Any stand the trainer did
  not stay on is reported by name.
- **Other changes:** a `--locations-only` flag, and no more `.png.png`
  filenames.

Contact sheet: `_sheet_player_camera.png`. Rendered under software GL
Compatibility (the shipped renderer), 1280×720.

## Defect the capture found: the summit crown has no floor

At the summit-approach stand (100, 5290), `ground_height_at` reports 1160m
and the summit's flat grassy crown is drawn there. But a ray from 2000m down
to −200m hits no collider, on any layer. The trainer falls through: the
capture reports "no collider under the stand after 600 frames" and frame 04
is taken from the grass line with the trainer below it.

A 10m-grid probe of x 20–180, z 5140–5410 marks a large area in which
ground is drawn but nothing collides. It includes the `SummitSupplyPosition`
anchor at (100, 1160, 5297).

**Cause, from source (`cloudreach_world.gd`):**
- The summit region's `CliffMass` is built with `collision = false`.
- An earlier fix removed its whole-mass collider because the eroded outer
  slopes stopped the final road. Its only replacement is a 12m-wide
  `SummitWalkableCrown` strip from z 5350 to 5376.
- The rest of the flat core disc (about a 179m × 94m ellipse at y=1160) is
  drawn and cannot be stood on.

**Why it is not fixed here:**
- Crown-only collision for the flat core, which other regions get, would put
  a ceiling over the authored road.
- The road's last stretch climbs underneath that disc: at (148, 5290) the
  road is at about 1141m, 19m below the drawn crown.
- Collision has to follow what the player can actually reach, so the fix
  belongs with ROADMAP step 12's earned-route and no-softlock work. The
  whole summit ascent and arena have to be re-walked after it.

## Blind verdict (visual-judge skill, code-blind sub-agent)

- **(A) Does it read as the art direction / region board?** No. What
  carried it: the gate-on-a-path composition, a recognisable dome and a good
  sky. What sank it:
  - single-green mid-value palette with no warm key and no violet shadow
  - no altitude
  - clouds that read as solid shapes
  - an Aviary reduced to a dome on a box
  - a night that does not read as night
- **(B) Same kind of game as Palworld?** Partly, mostly no. What sank it:
  - no creature on screen
  - flat empty foreground ground
  - low density
  - placeholder-looking props and floating objects
- **Ranked gaps:**
  1. Empty flat foreground ground.
  2. No altitude or layered depth: no drops, no aerial perspective, and
     solid cloud shapes.
  3. Landmarks and palette miss the region identity.

### Triage of the judge's defects

| Finding | Disposition |
|---|---|
| "Floating salmon/pink objects" in the dome (04) | **Fixed.** They are the eleven Kenney `tree-log` perches. The birds meant for them were retired (`cloudreach_aviary.json` birds.count 0), so the perches hang from 6cm ropes that vanish at this distance. The Kenney palette texture renders them salmon. They now take the aviary's own timber material, verified in the re-render. |
| Trainer absent in 04 | **Traced.** The summit crown has no floor (above). |
| Oxblood banners on the Aviary (04) | **Rejected.** This is the Team-Tether-occupied Summit Eyrie (`OccupiedSummitPylon`, `MarkedWindblownTetherBanner`), so reserved red is correct. The departure from the region board's friendly blue is an art-direction question. |
| Keyboard glyphs in the HUD frame | **Rejected.** A pad-less capture uses the last input device, which here is the keyboard. |
| "FOOD" label hard to read | **Recorded, not changed.** An earlier blind pass deliberately softened this corner's outlines (`playground_hud.gd::_soften_vitals_contrast`). Flipping it on one conflicting verdict would just churn. |
| Night reads as a desaturated day | Open. It is a grading change, Cloudreach look config. |
| Grass scatter seam (01), even tufts, one hero tree per stand, empty foreground, no drops or aerial perspective, solid cloud-sea shapes | Open. These need scene work: density, grading and composition. |
| Aviary as the board draws it, cliff strata, waterfalls, bird emblem | Needs art that is not in the build. It is Meshy-eligible under the owner's authorization, subject to the reference and validation rules. |
