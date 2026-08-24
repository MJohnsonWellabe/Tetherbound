# Are the choke points actually impassable?

**Owner directive, 2026-08-23:** *"There are some spots where we are relying on
having to cross a bridge or choke point. It needs to actually be impassable
otherwise. Like a deep gorge you can't cross or a river."*

Measured twice, by two sessions, on the **baked Terrain3D surface the player
collides with** — not on `playground_heightfield.gd`'s recipe, and not by
reading the intent out of a comment. The two disagree by up to 22 m near the
river channel, which is deeper than the gorge, so only the baked value decides
whether a crossing is a crossing.

## The verdict

| barrier | authored trench | 45° (player) | 60° (ridden legendary) |
|---|---|---|---|
| **River / Old Mill Crossing** | 340 m polyline with a bend | **SEALED** | **SEALED** |
| **South Bridge gully** | 90 m bar (`half_length` 33 + `end_fade` 12) | **PASSABLE, 401 m front** (x −192…208) | — |
| **Sigil Gate gorge west** | 108 m bar (40 + 14) | **PASSABLE, 401 m front** (x −190…210) | — |
| **Sigil Gate gorge east** | 108 m bar (40 + 14) | **PASSABLE, 401 m front** (x −83…317) | — |

**Three of the chapter's four gates gate nothing.** The scan swept a 400 m
window around each and found the *entire window* walkable: the trench occupies
90–108 m of it and open ground surrounds it on both sides. A player does not
detour around the tip — they can approach on a ~400 m front and never meet the
bridge at all. The locked leaf on the South Bridge and the three-Sigil gate are
decorative against anyone who drifts a hundred metres sideways.

## Why the river works and the others do not

It is not the profile. Every one of these is cut to the same arithmetic —
depth 11.0 against a 3.4 m rim is ~72° of wall against the player's own 45°
`floor_max_angle` — and the river proves that profile seals when it is long
enough. `terrain_playground.json`'s `river` block says so in its own words: it
is *"a 340 m channel with a bend in it that severs EVERY bearing it crosses"*,
authored as a polyline rather than a bar precisely because a bar cannot do that.

The other three are single straight bars cut across one road. **The defect is
length, not depth.**

## The measurement, and why the obvious version of it lies

`tools/_probe_crossings.gd`. Three instruments, in increasing order of how hard
they are to argue with: cross-sections along the authored course; a 1 m flood
fill across the full 2,048 m corridor; the same fill at the mounted limit
(`riding_controller.gd` raises `floor_max_angle` to 55° for rideables and 60°
for the legendary).

Two ways this measurement has already been wrong, both recorded because the
contradiction was more informative than either answer:

- **A plain flood fill reports the whole corridor as crossed the moment ONE
  leak exists**, because the flood spreads along the entire far bank. Its first
  run reported 2,047 of 2,049 columns passable *next to cross-sections
  measuring 69–80° walls*. The windowed scan (64 m windows, 32 m stride) is
  what localises a real leak.
- **Testing path gradient instead of the surface normal.** Godot tests the
  contact surface normal against `floor_max_angle`, which does not care which
  direction you approach from. On a planar 70° face a path near the contour has
  a gentle gradient — so a gradient-based fill switchbacked down cliffs and
  called 1,509 m of the river passable. A real player slides. Using the true
  normal turned that into SEALED.

Also: a sample off the end of the baked world is not flat ground. Skipping the
check on a NaN neighbour let the outermost columns fall through as walkable and
invented 1 m and 3 m holes at the corridor walls.

## Status

The river needs nothing. The three bars are being extended to sever every
bearing, keeping `depth`, `rim` and `half_width` untouched — the South Bridge's
`half_width 3.6 + rim 3.4` is exactly the 14 m clear span its bridge prefab is
built to match, so changing the profile would break the bridge. Acceptance is
the same probe reporting SEALED for all three at 45°, with the 60° figure
stated.
