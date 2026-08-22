# GATE-D3 evidence — the River / Tether Relay, played rather than read

Session of 2026-08-22, branch `claude/d3-setup-kf3tcf`, from `main` at
`4bd5da3`. This is the round `ralph/lanes/START_D3.md` asked for: a real driven
run, a real blind visual pass, and prompt 64's remaining acceptance items
verified rather than assumed.

The previous round's numbers were **analytical** — it read the band's own JSON,
projected each entry onto the spine and differenced z values. This round drove
a body through the region and looked at what was actually there. Three of the
previous round's conclusions did not survive that.

---

## 1. What was found, ranked by what it costs a player

### 1.1 The wild population is under the map — 137 of 155

The region's headline number was "50 clusters / 155 creatures, density is
done." A driven walk down the whole spine came within 35m of **eleven** of
them.

That is not a placement problem. `tools/_probe_wild_grounding.gd`, committed
here, boots the world and measures every wild body against the ground it was
authored on:

```
after 10s of world time      wilds   underground   deepest
  band1_lower_meadows           16       5 (31%)    1263.5 m
  band2_stone_and_root          16       8 (50%)    1263.9 m
  band3_the_river_lock         155     137 (88%)    1266.5 m
  band4_upper_ironwood          18      18 (100%)   1264.4 m
  band5_stronghold               9       9 (100%)   1264.2 m
```

They never stop falling.

**Mechanism.** `creature_body.gd::_physics_process` subtracts gravity
(26 m/s²) on any frame where `is_on_floor()` is false. Terrain3D builds
collision *dynamically around the camera* within a granted radius
(`ralph/BAKE-GUARDS` §8.2), and `playground_world.gd` hands it the player's
own camera. A creature spawned four kilometres from the player therefore has
no floor on the frame it spawns and never gets one, because collision arrives
around the camera and the camera never went there. Four seconds of settle at
26 m/s² is 208m — which is exactly what the probe measures at the 240-frame
settle every smoke test in this repo uses.

**Why nothing caught it.** `encounter_director.gd::_stand_on_ground` succeeds
and reports nothing: `place_on_ground` puts the body at the analytic height
and returns true. The fall happens afterwards, in physics, silently. So "155
creatures are authored" and "the region plays empty" were both true at once,
and every existing test agreed with the first one.

**Whose it is.** Not this band's, and **no band's `spawns.json` can help a body
with no floor under it.** It belongs to distance activation / creature
streaming, which `ralph/DONE.md`'s own GATE-D3 entry already names as the
coordinator's lane. Five lanes editing `creature_body.gd` is precisely the
collision `GATE_D_LANE_CONTRACT.md` exists to prevent. The probe is committed
so that lane can reproduce it in one boot and prove it fixed.

**What it means for the owner's density directive:** the 2026-08-22 directive
raised this band from 18 creatures to 155. Until streaming lands, it has bought
roughly 18 creatures a player can meet. Re-run the probe before crediting any
band's density number again.

### 1.2 The river gorge is not in the terrain the player walks

Prompt 64's first acceptance line is "river feels like a major regional
landmark". The authored channel is 10–15m deep. Three separate camera
positions failed to show a cut, and the blind critic — told nothing, shown
only pictures — reported independently that "a flat plain with a dark grey
strip running across it, level with the grass on both sides" is what is there.

It is not only the camera. Standing the real player body in the channel and
reading where it comes to rest:

| spot | analytic heightfield | body rests at | delta |
|---|---|---|---|
| (−120, 4200) | −16.59 | **−2.68** | +13.91 |
| (−120, 4206) | −17.17 | **−2.68** | +14.49 |
| (−152, 4195) | −2.00 | +0.90 | +2.90 |
| (−152, 4203) | −23.83 | **−1.91** | +21.92 |

The collision/rendered terrain is 14–22m shallower than the heightfield that
authored it. `data/terrain/playground/` was last written 2026-08-21;
`terrain_playground.json` has moved since, and
`build_playground_terrain.gd`'s own header states that dirty-region detection
from a config diff is deliberately not built.

**The river still gates the region** — a body walked north into the bank 90m
east of the crossing stops at z≈4194 and does not cross, so progression is not
broken. What is missing is the *landmark*: the region's identity beat reads as
a grey stripe on a lawn.

Terrain and the bake are coordinator-owned (`GATE_D_LANE_CONTRACT.md` §3), so
this is reported, not fixed.

### 1.3 Dead travel is 632m, not 81m

The previous round reported a longest dead-travel gap of **81m**, computed
from config. Driven, with only authored content counting (see §2 on why
scatter pickables must not), it is **632m** — from Captain Oreth at z=4350 to
the band's north exit at z=4760, the last third of the region, with nothing
within 35m of the walked line. Two more stretches over 250m sit at the
region's entrance and in its middle.

Some of that is §1.1: with the wild population restored, most of these gaps
close on their own. That is the honest reading and the reason no spawn was
moved this round — moving content to fill a gap caused by creatures falling
through the world would be authoring around a bug.

---

## 2. The driven run

`tools/_probe_band3_driven.gd`, committed. It boots the world and drives the
real `Player` through the real `player_controller.gd` along Band 3's reach of
the authored spine, asking each frame what is standing near the body rather
than what a config file says should be. Two things it separates that the
analytical pass could not:

- **Authored gatherables from scatter pickables.** 12 `harvest_node.gd` nodes
  are authored in this band; **2,412** `vegetation_harvest_point.gd` pickables
  in the same `harvestable` group also stand in it. Counting the second as
  content reports zero dead travel in an empty field. They are counted and
  reported, and they never end a dead stretch.
- **The objective line at the state a player arrives in.** A fresh save tracks
  "Catch your first wild creature," which is an artefact of booting the sandbox
  scene. Set the main chain up to `warrens_cleared` first.

Result of the corrected run: 2,063m walked, 25,491 physics frames, three
stalls (320m handed over, never counted as walked), ending at z=4758.

**Re-driven after the content fixes in §5**, by the same instrument that found
them, which is the only reason to trust that they worked:

| | before | after |
|---|---|---|
| stalls | 3 (320m handed over) | **2 (57m)** |
| trainers met | 4 of 5 | **5 of 5** |
| prop clusters met | 2 of 4 | **5 of 5** |
| authored gatherables met | 3 of 12 | 4 of 12 |
| walked | 2,063m | 2,322m |

The checkpoint wedge is gone — the walk no longer stalls at (239.5, 3677.5),
and the one remaining stall is the relay compound wall, which is a wall. With
the body no longer teleporting over its own region, every trainer and every
prop cluster in Band 3 is now actually encountered on the walked line.

Dead travel is unchanged at 632m, as expected: it is §1.1 wearing a different
hat and no prop moves it.

**Two probe defects were found and fixed mid-session**, and both had produced
believable wrong answers that would have sent the next round to fix content
that is not broken:

1. Wild bodies were snapshotted at boot. They roam, so the run was measuring
   how far each had wandered, not what the player passed. Now re-read live
   every frame.
2. The stall handler advanced the waypoint index before teleporting, so a
   stall stepped the body to the waypoint *after* the one it wanted. At the
   Hess picket that jumped clean over the relay compound — Orrin, Dell, Vance
   and the relay yard were never sampled, and the gap they should have filled
   was reported as 185m of dead travel.

---

## 3. Prompt 64 acceptance, item by item

| Acceptance line | Verdict | Evidence |
|---|---|---|
| River is a major regional landmark | **No** | §1.2 — gates correctly, does not read |
| Wild ecology is real and findable | **No** | §1.1 — 137 of 155 under the map |
| Team Tether presence builds before the captain | **Yes** | Hess at 140m out, Orrin at ~70m, then Dell and Vance in the compound; walked in that order |
| Relay is a compact assault, not four NPCs together | **Yes** | walls, gate, gantry, apparatus, lit conduit runs, 46m dead-ground skin; the two pickets are outside it |
| Vance is a real milestone | **Yes** | see below — carried by presentation, and his level is what the curve authors |
| Rescue/crossing visibly changes what the player can do | **Yes** | §4 |
| Player leaves understanding Team Tether by experience | **Yes** | checkpoint → picket → picket → officer → captain → captive, no exposition |

**On Vance.** He is rank `captain`, three creatures at L11–12, xp bonus 120,
and he stands at the end of a real compound with the captive behind him so the
rescue cannot be walked to without the fight.

An earlier draft of this file called that a curve defect — Dell is L10, one
level under him, and `captain_riverwatch` past the crossing is L13–16, so the
region's set-piece boss is not its hardest fight — and proposed moving one of
them. **That was wrong and is withdrawn.** `chapter_curve.json`'s own band3
tuning note authors this ladder explicitly: *"The relay's four-fight ladder
(8, 9, 10, 11-12) is the densest trainer run in the chapter and carries the
player across this whole band on its own."* Vance is exactly where the curve
puts him, and Riverwatch's 13–16 is the band-exit gate matching band4's
trainer band, not an accident. Proposing a curve edit here would have reopened
a settled decision to fit content, which is the specific thing
`GATE_D_LANE_CONTRACT.md` §3 forbids.

The accurate statement is narrower and is not a defect: Vance is the region's
**story** climax and Riverwatch is its **difficulty** gate, deliberately. What
carries Vance as a milestone is presentation — rank, the compound, the four-
fight run into him, the captive behind him — not his level, and presentation
is what prompt 64 actually asks for.

---

## 4. The world responds — verified in the real quest system

Driving the flags in the order `smoke_relay.gd` proves they land, and reading
the tracked objective from `/root/Game`'s own `quest_log` against
`progression` — the same pair that fills the HUD:

```
arriving from the Warrens  : Defeat the Relay Captain.
+relay_captain_defeated   -> Find who Team Tether is holding at the relay.
+captive_rescued          -> Shut down the Tether Relay.
+relay_disabled           -> Restore the Old Mill Crossing.
+mill_crossing_restored   -> Defeat the Upper Meadows captains. 0/3
```

The region's objective is legible from the HUD line alone on arrival, every
victory beat changes it, and the last one hands off to Band 4. This is prompt
64's "objective changes / story acknowledges" and SE27's chain, proven end to
end rather than asserted.

---

## 5. The blind visual pass

Two rounds, both judged by an independent critic that was shown the frames,
the contact sheet and `docs/reference/`, and told nothing about what changed —
the thing the previous round recorded honestly that it could not do.

`tools/capture_band3_region.gd` (committed) shoots nine frames in the order a
player walks the region, and deliberately includes the region's own longest
empty stretch. It carries the two capture-tool fixes the previous round found
and could not keep, because its tool was never committed: the day/weather
clocks are pinned *after* the settle and both nodes' processing stopped, and
the Player is parked above the terrain rather than 500m under it where
`water.gd` reads it as submerged and ramps a red vignette across the shot.

**Fixed in response to the critique, inside this lane's own files:**

- The relay approach checkpoint. The critic said nothing there reads as a
  picket; the driven run independently *wedged the player body* on it — three
  props stood 0.4m and 1.2m from the road centreline. Rebuilt as a barrier
  line across the road with a 6.4m walk-through gap, laid out on the spine
  leg's own normal, with the picket's watch post off the verge behind it.
- `old_mill_crossing_gear` was authored 101m from the crossing it names.
  Re-sited to the south landing where the player stops at a shut gate, plus a
  workbench and anvil, because the gate is shut for want of a gear.
- `old_mill_yard` (new): the critic's reading of the mill as "a prop dropped
  on grass" with no yard, no track and no boundary.

**Three of the critique's findings were the camera, not the region**, and were
fixed in the capture tool rather than in content: two river framings that hid
a cut the terrain does have (`target_h` is added to *ground* height, and at a
channel floor 25m down, asking for −7 aimed the camera at y=−32 — a steep
pitch into the near grass); and the checkpoint shot from 27m, where this prop
kit's sub-metre crates are thirty pixels of speck. A player walks *through*
that checkpoint.

**What the second round named that this lane cannot fix**, all shared or
coordinator-owned, reported here rather than edited:

- **Near-ground cover.** Named first in both rounds and the largest single
  difference from the Palworld bar: the ground is a tiling texture with no
  grass geometry, tufts or flowers. This band sits at the chapter's floor
  `density_scale` of **0.03**. **Requested: 0.06 for band3**, matching band2's
  0.05 and short of band1's 0.07 — the region is travelled at pace and should
  not read as busy as the home meadow, but 0.03 is reading as bare in every
  wide frame.
- **No creature is readable in any frame** — which is §1.1 wearing a different
  hat, and the critic's loudest point in both rounds.
- The trainer renders as a featureless black silhouette at 15m; the tree stock
  is one tree at three scales and roughly half its implied height; the sky is
  cloudless in all nine frames; a hard haze band clamps at a fixed distance;
  the terrain material streaks badly on steep faces (no triplanar projection),
  which is what makes the river bank unreadable; Team Tether's oxblood is not
  used anywhere, so the enemy installation reads as the friendliest palette in
  the set.

### 5.1 An unexplained rendering artefact at the checkpoint — open

Round 3 was asked about the dark band in the checkpoint frame and answered
with measurements rather than an impression: from y≈450 to the bottom edge,
across the full 1280px width, the region is a constant RGB ≈ (46,58,44)
varying by under three levels; the top edge is dead straight and
horizon-parallel; the props standing in it keep full saturated wood tone; the
terrain and a wall segment visibly terminate in mid-air at the seam. Their
reading was a water body or terrain hole rendering as an unshaded plane.

**Two explanations were tested and both are wrong.**

*Not the camera being underground.* That was the leading theory, and it had a
real basis — §1.2 shows the analytic heightfield and the collision terrain
disagreeing by up to 22m, so an eye seated on the analytic value can end up
inside the ground. The capture tool now raycasts every eye and target onto the
real physics surface (a genuine fix, kept). At this viewpoint the ray returns
the analytic height unchanged, the eye is identical before and after, and the
artefact is identical too.

*Not water.* `terrain_playground.json`'s global level is **-17.0** and the
river's is **-9.0**. The eye is at **-2**. Both surfaces are far below it.

**What is established:** it is positional, not a height effect. The same 1.7m
eye 19m further back at (214, 3668) renders clean; at (232.5, 3672) it does
not. Repro: `tools/capture_band3_region.gd`, viewpoint `03`, eye (232.5, 3672).

Handed over rather than guessed at a third time. It is in terrain/rendering,
not in band content, and nothing in `data/config/bands/band3_the_river_lock/`
can produce or fix it.

**Convergence.** Round 2 named new defects, so the pass had not converged when
this session ended. Every band-scoped item it named is fixed; the remainder is
the list above, none of which is this lane's to touch. A third round is worth
running only once the density request and the streaming fix have landed —
re-judging the same shared-asset defects a third time moves nothing.

---

## 6. State

Full suite green with all content changes in: **1301 tests, 715475
assertions, 0 failed**, run in the foreground.

`python3 tools/_probe_chapter_map.py` is unchanged for this band by this
session's edits (prop clusters do not appear in it): 5 trainers, 50 clusters /
155 creatures authored, 12 authored gatherables.

`smoke_art.gd`'s eleven failures are the known inherited defect
(`ralph/lanes/COMMON.md` §4), fixed on `ralph/integration-D`, not caused here.

Not pushed to `main`, no PR, no workflow dispatched — integration is the
coordinator's (`COMMON.md` §9).
