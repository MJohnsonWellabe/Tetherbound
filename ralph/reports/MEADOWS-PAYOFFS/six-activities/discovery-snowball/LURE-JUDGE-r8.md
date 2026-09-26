# F03#0 lure judge, round 8 (code-blind; juno)

Judge input: the 5 frames in `r8-judge/` (juno_01 to juno_05) plus the criterion (ACCEPTANCE F03, lure part: "a player can see the lure") and the ruling (visible from the road, then readable on approach). No code, data, config or other files were opened.

| activity | visible from road | readable on approach | overall |
|---|---|---|---|
| juno | PASS (marginal) | PASS (marginal on the 65 m frame) | PASS (marginal) |

## Evidence

**Visible from road**
- 01 (160 m, road, no HUD): a dark grey smoke column at left of centre (about x 350-390, y 255-350 at 1280x720, about 25 x 95 px) stands out as a dark vertical shape against the pale mountains and sky. It is the only vertical dark form on the horizon, and a player would notice it. Clear pass for this view.
- 02 (159 m, ordinary walk, HUD on, companion at right): the same column is only a short pale-brown stub (about x 835-865, y 128-160, about 20 x 35 px), right above the companion's head. Its base is hidden behind Tup's ears, and against the warm hazy sky its contrast is low. It is on screen, above the horizon line and in the upper third, so a player *could* notice it, but it is easy to take as a smudge of scenery. This is why the pass is marginal: the ordinary-walk frame is much weaker than the clean 01 view.

**Readable on approach**
- 03 (65 m, labelled first readable): the only lure element is one oxblood banner on a white gantry, top right (about x 935-990, y 135-205). It sits between the companion's back and the objective panel, and the panel nearly touches it. The banner is clearly Tether-coloured and man-made, but the smoke is out of frame and no Meadowhart or patrol member shows. By itself this frame says "someone's standard", not yet "a Tether patrol holding a Meadowhart". That is marginal.
- 04 (about 30 m): this frame reads. There are two large oxblood banners (a big one at left, about x 50-220, y 75-185, and a second in the distance at right), a thick smoke column rising from the camp at centre (about x 560-630), a Meadowhart silhouette with antlers standing on the rise between them (about x 660-710, y 110-175), and more banners. Together they say "red-banner camp, signal smoke, big deer creature".
- 05 (prompt): a campfire with smoke rising from it, a dark-clad figure (the patrol member) by the fire, two oxblood banners and the Meadowhart large at right. The prompt "Challenge Tether Patrol" names it outright. Who and what are unambiguous.
- Marginal note: in 04 and 05 nothing shows that the Meadowhart is *captive*. It has no leash, pen or tether, and in 05 it stands freely beside the player like a companion. The "stolen" part of the story is not readable, only "Tether camp + Meadowhart".

## Fix

No required fix; the verdict is PASS. The most valuable hardening:
1. Keep the smoke plume from sitting behind the companion's default screen-right position on the road approach, or make the plume darker and taller so it beats the warm, hazy sky seen in frame 02. The ordinary-walk sighting depends on a 20 x 35 px low-contrast stub.
2. Secondary: give the Meadowhart a visible restraint (tether line or pen) so the "held/stolen" read survives at 30 m.
