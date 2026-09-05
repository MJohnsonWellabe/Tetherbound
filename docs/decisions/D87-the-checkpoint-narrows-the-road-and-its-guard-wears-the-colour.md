# D87 — The South Bridge checkpoint narrows the road, and its guard wears the faction colour

**Date:** 2026-09-05 · **Decided by:** lane N09-BRIDGE-CHECKPOINT-0905, under the
COMMON rule that a lane makes the smallest defensible call and records it rather
than stopping to ask. Sources: `ralph/reports/W22-BRIDGE-SIGNPOST-0904/JUDGE.md`
(the landing-time blind verdict, run by W24-LANDING under the owner directive of
2026-09-05 02:24 UTC), `docs/decisions/D86-the-south-bridge-is-held-from-the-approach.md`,
`data/config/palette.json`'s `_reserved` note and `data/config/npc_ranks.json`.

Two small calls. Neither is a new mechanic; both are reversible in data.

## 1. D86 §1's "on the shoulders" becomes "narrowing the road, never sealing it"

D86 §1 put the checkpoint's barricade frames on the road's shoulders and wrote the
rule as a coordinate: *"on the road's shoulders (|z| >= 1.5 m local)"*. The landing
judge failed exactly that: **"texture the barricades, put them across the road"**,
and in its ranked list, *"the untextured barricades ... do not block the road"*.

D86 §1's REASON survives the judge's finding intact and is not being reopened. It is
mechanical: `gated_crossing.gd`'s leaf is the one thing that shuts this road and it
swings open on the real unlock, so a barricade that seals the way would need either
its own second unlock or would leave the player walking into timber behind an open
gate. Nothing here changes that.

What changes is the coordinate that was standing in for the reason. `|z| >= 1.5`
is not the same rule as "never seal the road", and measured on the built world
(`tools/_probe_n09_checkpoint.gd`) it bought neither: each frame's inner edge sat at
|z| = 1.44 against a 1.50 m road half-width, so 2.88 m of a 3.00 m road was clear and
the barricade was decorating the verge. The rule is restated as the thing it was
protecting:

> **The checkpoint's barricade may reach into the roadway and narrow it. It may
> never close it, and it never stands on the deck.**

This is not a new grammar for the project; it is the one it already uses for exactly
this situation. `data/config/tether_relay.json`'s `_comment_barrier` describes the relay
approach as *"a barricade across the open road, 5.5 m short of the gate piers ... so it
reads as a checkpoint held on the approach rather than crowding the gate's own open
threshold"*, with *"a 3.4 m gap ... [that] keeps the road itself walkable, the same
'line with a walked-through gap' grammar `relay_approach_checkpoint` already uses 400 m
up this same road"*, and *"deliberately asymmetric ... rather than mirrored, for the
same reason that cluster's own round-4 note gives: a mirrored barricade reads as
generated, not built."* The South Bridge is the chapter's FIRST checkpoint and was the
only one of them standing beside its road rather than across it.

`BARRICADE_SIDE` 2.4 -> 1.65 with a shallow inward funnel yaw puts each frame's inner edge
at |z| = 0.69/0.67, so each reaches ~0.82 m into the road and the clear gap down the
centreline falls from 2.88 m to **1.36 m** — a 55 % narrowing to a single-file gap that the
0.4 m player capsule still walks (0.28 m of clearance each side, and
`tests/smoke_traversal.gd`'s own walk is unaffected: it starts at `near_point(11.0)`, 1.4 m
PAST the frames). The two frames stand 3.4 m in front of the archway on the village-side
approach, exactly where D86 §1 put them; the deck between the rails still carries nothing
new.

The yaw is small on purpose, and that is worth recording because the obvious choice was
wrong. A first pass used a strong 24°/28° funnel at `BARRICADE_SIDE` 1.85 and hit a 1.51 m
collider gap — and a fresh code-blind judge, given only the frames, still said *"the dirt
lane runs clean and unobstructed between them … wide enough to drive a cart through"*.
It was reading the timber, not the collider, and it was right to: turning a beam swings
its tip AWAY from the centreline by `cos(yaw)` while ADDING to the collider's z extent by
the frame's half-width times `sin(yaw)`, so a strong angle buys the idea of control and
pays for it in the only measurement a viewer takes. At 24°/28° the visible gap between the
two pieces of wood was 2.11 m against a 1.51 m collider gap. Flattened to 6°/8° the two
agree: the tips come in to |z| 0.76 and the visible gap is 1.51 m against a 1.36 m collider
gap. **Where the physical gap and the read disagree, the read is the thing the rule is
about** — the rule exists so the crossing looks held, and the collider only exists so the
player can still get through it.

## 2. The Bridge Sentry gets a per-individual oxblood palette, and the grunt rank does not

The judge: *"the guard wears none of the faction's red"*, and *"put the faction's red
on the guard"*.

The cause is a stale claim in `npc_ranks.json`. Its `_comment_oxblood` still says the
grunt rank's body palette is *"a warm rose-red family multiplied onto the grunt rig's
own dark tactical texture"*; T1-GROUND (2026-08-30) replaced every rank multiply with a
neutral value ladder (grunt `#dcdcdc`, officer `#eeeeee`, captain `#ffffff`) to stop a
dark multiply crushing an already-dark texture, and the faction colour has lived in the
rig's own paint ever since. Measured off `grunt_lod0_texture_0.png`, that paint IS
oxblood-family — median hue 340 degrees, saturation 0.35 — and its median **value is
0.173**, which through a 0.86x neutral multiply renders at value 0.149 and saturation
0.250. The colour is there and it is too dark to be a colour.

The fix is scoped to the ONE body this lane owns: a `palette` override on the Bridge
Sentry in `data/config/south_bridge_dressing.json` (`village_npcs.gd::model_config`
lays the same five override keys over a rank block that a trainer entry takes).
`#ff6943` holds the red channel at full so the multiply saturates without darkening, and
the grunt rank's own additive emission floor (`emission_floor` 0.18) is `tint * 0.18` so it
moves with it, from a neutral grey lift to a red-biased one.

**It has a measured ceiling, and the ceiling is part of the decision.** Tuned in three
passes against the number a blind judge supplied by measuring the banners in the same
frame (red-to-blue 3.38), the guard's rendered torso went 1.24 -> 1.76 -> 2.40 -> 2.57
while the tint's own red-to-blue went 1.00 -> 1.49 -> 2.77 -> 3.81. The last step bought
0.17. A palette entry cannot get further because the emission floor and the tonemap both
pull toward neutral and neither is reachable from it. So: the Bridge Sentry now stands in
the banners' own hue family (12 degrees against their 8, saturation 0.61 against 0.70,
value deliberately unmoved so they stay in a dark uniform), and anything past that needs the
rank's `emission_floor`, the rig's texture, or accessory geometry. Recorded as a ceiling
rather than chased.

**The grunt RANK is deliberately not touched.** Repainting every Team Tether body in
the game is a cast-wide look decision that two blind rounds have already tuned
(`npc_ranks.json`'s `_comment_ladder` records the measured ceiling on it), and it is
not a checkpoint-dressing lane's to make. If a later cast lane decides the whole
faction should carry visible oxblood, this entry becomes redundant and should be
deleted rather than kept as a special case.

## What this does not decide

- Whether the hero checkpoint gate's own blue banners should be oxblood. They cannot be
  retinted: the `.glb` carries ONE material over ONE primitive with one baked atlas
  (verified in the file's JSON chunk and again on the imported scene), so the only
  material slot paints the posts, lintel, lanterns and stonework as well as the cloth.
  Routed to the coordinator as needing a Team Tether asset lane — see this lane's report.
- Whether the whole Team Tether cast should read as oxblood at gameplay distance.
- Anything about the signpost's board size. The lettering is a `Label3D` and its
  contrast, weight and fit are material-level and were fixed; its 5-7 px cap height at
  a gameplay stand is a function of a 0.24 m board read from 10-15 m, and no material
  setting reaches it.
