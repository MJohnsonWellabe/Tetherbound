# F05 WO8 "the land heals": final blind verdict (round 4)

**Result: FAIL.** The question was "Does the land visibly heal, readable to a
player without being told?" Criterion 5 stays **NOT MET**.

## Frames

These are in-engine frames from the production camera rig, with the HUD on
and the clock held at 13:00. The JPEGs are in this directory, and `_sheet.jpg`
is at half size.

- **h01–h09** are the before/after pairs at the quarry, the approach, the
  works and the Highfield.
  - They come from `capture_heal.gd.txt` on `50b67871`.
  - That commit already has the staged fall, the dark dead screens and the
    re-authored herd.
  - It predates `0164134f`, which changes only the landing dust.
- **s00–s28** show one approach-trunk pylon (`ApproachConduits/Pylon_13`)
  falling, seen side-on to its baked fall azimuth.
  - They come from `capture_pylon_side.gd.txt` on `0164134f`, run with
    `--fixed-fps 60`, so each frame number is true time.
- **Disclosed staging:**
  - The main chain up to the Warden and `legendary_freed` are set directly.
  - The player is placed at each vantage.
  - `s00` is taken before the player is placed at the side vantage. It is not
    part of the continuous take.

## What the judge saw

- **Works slope (h08/h09).** The land visibly changes, from a bleached slab
  to green. The judge says it reads as a texture swap: a darker slab with
  the same hard stencil edge remains.
- **Quarry and approach pairs.** A machine is removed and the cable goes.
  The ground is unchanged.
- **Highfield.** The animals appear, which reads as a spawn. The judge still
  reads the herd as placed props: roughly even spacing, the same standing
  pose, and one larger deer.
- **The fall.** It is "a slow physics topple, legible as an event", with a
  thin puff of dust. The pylon falls **into the near oak** and its top clips
  the canopy (s12–s20).
- **Other defects:**
  - Residue of the beam (h04, h09).
  - A black diagonal bar in the s-sequence foreground.
  - A white blob at the right screen edge.
- **Bar A (key art): No.** The drained-then-healed promise is absent.
- **Bar B (Palworld): Yes, weakly.**

## In lane: open

- **Fall through a tree.** The baked `pylons.falls` table checks only fixed
  authored static bodies, and excludes vegetation by design (for
  determinism). `Pylon_13`'s azimuth lies into an oak.
  - Fix: re-bake with tree trunks from the vegetation scatter as blockers,
    read deterministically from the scatter data rather than streamed
    colliders.
- **Hard stencil edge on the regreen overlay (h09).** It needs a soft,
  noise-masked edge. The mask is in `meadow_healing.gd`'s regreen mesh.
- **Herd.** Normalise the scale variety (one deer read as mis-scaled). A
  looser, deeper grouping away from the treeline.

## Outside this lane

- **The before-state is not drained.** Away from the works slope, the ground
  is lush before the heal, so a runtime regreen has nothing to contrast
  against. That is the terrain scar bake and vegetation density.
  - The owner's decision was "runtime regreen of the baked scar stations …
    no re-bake". Only the works station carries a visible scar.
- **Herd animation.** Meadowhart has only idle, walk, run, attack, hit and
  faint clips: no graze or lie clip, which is an art request.
- **The cyan vertical column is `objective_beacon.gd`** (UX), not the tether.
- **The black bar and the edge blob in the s-sequence** are unidentified, and
  are likely foreground vegetation or a companion at that vantage.

## Code proof (separate from the visual bar)

- Unit tests 22/0.
- The heal smoke passes on `0164134f`:
  - 29 pylons down, 0 left standing, 168 cable pieces hidden;
  - reload and reload+30 are identical;
  - the regreen fades in live and snaps on a load.
