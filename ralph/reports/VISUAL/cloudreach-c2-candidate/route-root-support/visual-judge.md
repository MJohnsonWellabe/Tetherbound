# Blind route-root support comparison

Fresh reviewer route_support_blind_judge opened all20individual native1920x1080
frames, the visual-judge rubric, ART_DIRECTION, Meadows keyart, two Palworld
gameplay references and the Sky Aviary board. No code, reports, history or
change description. Neutral mapping revealed after verdict: A=final corrected
surface sampling, B=c461d5e6f yard-bound baseline.

**Scoped vegetation grounding: A PASS; B FAIL. Overall Bars A/B: NO for both.**

| Pairs | Preference | Visible finding |
|---|---|---|
|001/002 Cliffhold approach|Tie|Vegetation reads against terrain; distance limits root inspection.|
|003/004 Cliffhold court|A|B has floating grass left of tower, x435–665/y610–695, and raised right strip x1260–1920/y620–740. A places these against the visible slope/garden edge.|
|005/006 Windwatch|Tie|No material grounding difference.|
|007/008 Galefoot approach|A|A's grass/flowers frame and connect the approach. B has plain lawn, isolated clump and abrupt right shelf; no equally clear airborne clump here.|
|009/010 Galefoot hearth|Tie|Props and vegetation substantially equivalent, no definite unsupported strip.|

Remaining defects named by reviewer:
- A003/004 retains straight parallel grass-bed edges and abrupt density changes.
- Both001–004 mix oversized sparse angular blades with finer settlement grass.
- Both005/006 have disconnected rightmost fence rails ending near x1580.
- Both009/010 have right-angle grass/dirt cuts left of trainer and minimally
  articulated ground beneath houses, fire ring and benches.
- Both007/008 repeat narrow vegetation strips on the stepped cliff.

Largest reference gaps: hard ground transitions, too much empty sky and weak
settlement/distant overlap, inconsistent foliage scale/shape and blunt terrain.
Readable trainer and coherent roof/timber family help, but full visual acceptance
fails. Creature quality cannot be judged because the fixture parks the companion.

Before frames: ../yard-bounds/after/001..010 (baseline committed c461d5e6f).
After frames: after/001..010 in this directory. Frame names include full subjects.
No reroll: one final ten-frame run, after the reviewed exclusion correction.
