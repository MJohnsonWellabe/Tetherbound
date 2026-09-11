# Meadows relay visual pass — 2026-09-11

## Result

The Tether Relay is now a readable occupied mini-stronghold rather than a dark
slab crowded with duplicate grunts. The installed hero apparatus remains the
focal point; its pad has an oxblood service rail, the stone courses remain
visible in daylight, and bounded teal practicals identify the live gate and
console deck. The relay approach camp's cloth-only banner now has a physical
mast and its existing fire has a bounded warm night fill.

The decorative staffing was reduced from four ground grunts plus two deck
grunts to two ground grunts plus one console guard. The real Hess/Orrin/Dell/
Vance trainer encounters, captive, console gate, rewards and progression flags
are unchanged.

Fresh production evidence:

- `shots/locations/06-relay-standing-day.png`
- `shots/locations/06-relay-apparatus-day.png`
- `shots/locations/06-relay-road-day.png`
- `shots/locations/05-relay-camp-standing-day.png`
- `shots/locations/05-relay-camp-fire-night.png`

The bounded capture wrote 10/10 frames on the combined camp/relay pass and 4/4
frames on the final corrected relay material pass, both with zero failed
frames. The final material candidate corrected `Color.darkened()` in the right
direction (0.50 to 0.30); the rejected 0.66 candidate made the structure darker.

## Validation

- Focused unit/resource run: 3 tests, 37 assertions, 0 failed.
- Existing relay station smoke: passed the open gate, gantry and pad floors,
  ramp-only route, live-to-dead conduit transition, and local ground/scatter
  heal. The smoke emitted its two pre-existing deliberate `smoke_relay_gate`
  unscoped-flag diagnostics before reporting pass.
- `git diff --check`: clean for the four implementation/test files.

## Honest disposition

`POLISH`, not commercial `PASS`. The hero machinery, faction colour and
staffing hierarchy are materially clearer, and the former crushed-black defect
is closed. The lower platform is still a simple rectilinear masonry structure,
the approach camp's dedicated fire-detail capture still has a known capture-rig
fault that floats the trainer, and neither frame proves combat spectacle or the
earned four-fight approach. Those are not claimed closed by this visual pass.
