# F03#0 lure judge, round 9 (code-blind; juno, final camp layout)

Judge input: the 5 frames in `r9-judge/` (`juno_01` to `juno_05`), plus the F03 lure criterion and the ruling (visible from the road, then readable on approach). No code, data, config, tests or scripts were opened.

| activity | visible from road | readable on approach | overall |
|---|---|---|---|
| juno | PASS (marginal) | PASS (marginal at 65 m, clear at 30 m) | PASS (marginal) |

## Evidence

**Visible from road: PASS, marginal.**
- 01 (160 m, road, no HUD): a dark grey smoke column stands left of centre (about x 350-390, y 255-350; about 40 x 95 px). It rises above the treeline against pale mountains and sky, and it is the highest-contrast vertical shape on the horizon. A player looking down the road would notice it and wonder what it is. The column does look more like a solid dark pillar with a rounded, abruptly ending top than like drifting smoke, but it still says "something is there".
- 02 (160 m, the actual walk, no deliberate look): the in-play evidence is weak. Only the top of the column shows, a faint brown-grey blob of about 30 x 30 px above the companion Tup's head (about x 845-870, y 130-165). The companion walking at the player's right hides the rest. The sky here is hazy and pale, so contrast is low. A tiny white banner post is just visible behind trees left of Tup (about x 740, y 240), too small to register. Judged on 02 alone, a player would probably miss it. The ruling passes because 01 shows the same cue clearly from the road at the same distance and the column persists as the player walks.

**Readable on approach: PASS. Marginal at the labelled 65 m, clear by 30 m.**
- 03 (65 m, labelled "first readable"): this is overstated. The only lure element is one oxblood banner on a white post at the right (about x 945-1005, y 135-205; about 60 x 70 px). It sits right against the quest panel, and the smoke column is pushed behind the minimap at the right edge. No Meadowhart, patrol member or camp is visible. The frame reads as a Tether-coloured flag at most, not as a patrol holding a creature.
- 04 (about 30 m): this is readable. The smoke column dominates the top centre. A Meadowhart silhouette stands on the ridge against the sky (about x 665-710, y 110-178; about 50 px tall) and clearly reads as a large deer. A second small oxblood banner is beside it (about x 730), and there are small dark figures near the base of the smoke. A large oxblood banner sits at the left, partly overlapped by the TEAM panel. What (Meadowhart) and who (Tether banners) are both clear.
- 05 (prompt): two oxblood banners, a campfire, white tents, a dark-clad patrol member, and a large Meadowhart close at the right (taller than the trainer). The prompt reads "Challenge Tether Patrol". What and who are unambiguous.
- Marginal notes: nothing shows visually that the Meadowhart is stolen or held. There is no tether, pen or restraint, and in 05 it stands loose beside the player. The patrol member wears black, so the faction read rests on the banners and the prompt text.

## Fix

This is a pass, so no fix is required. The single most important improvement is to make the column clear the right-side occluders during real play. At 160 m in 02, the companion at the player's right hides all but its top 30 px, and at 65 m in 03 the minimap and quest panel cover the camp's side of the screen. Make the column taller and denser so it rises well above the companion's head and the right-hand HUD, or site it so it falls toward the centre of the screen from the road.
