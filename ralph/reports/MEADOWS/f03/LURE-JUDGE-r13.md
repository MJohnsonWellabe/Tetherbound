<!-- Code-blind judge (sonnet subagent) on herd_night_walk_8fc88f20 (04-10), herd_night_cue_8fc88f20 (40 m pair) and hall_south_14e917a3 (10-16). -->
# F03b Visual Judge Verdict — Optional-Activity Lures (herd / hall)

Judged code-blind from the .jpg frames only, in `judge_f03b/`. All pixel coordinates are approximate, on a 1280×720 frame.

---

## A. Herd at night (Meadowharts) — **PARTLY**

**Sequence read (herdnight_04→10):**

- **04 `lure-first-seen` (23:31, ~56m):** The player's own out companion (a large lumpy spotted creature, "Put Terrapup away") fills the right two-thirds of frame (x≈630–950, y≈180–520). Above its head line, on the horizon, the actual cue is already visible: two pale Meadowhart-like silhouettes at x≈635–665,y≈225–240 and a small warm firelight spark at x≈705–715,y≈245–255. Small but present.
- **05/06 `road-glance…`/`lure-first-readable` (23:35/23:42):** Companion put away, same framing; the herd+fire cluster (same coordinates) is now unobstructed and a clean, isolated bright spot against the dark hillside — this is the frame where the cue reads best from distance.
- **07 `road-glance-before-exit` (23:54):** This checkpoint is **not** a glance toward the herd. The frame is dominated by an unrelated NPC encounter — a large black/white badger creature (x≈730–900,y≈200–420) and NPC "Tobin" (x≈690–745,y≈350–430), with a "Greet Tobin" prompt. The herd cue survives only as scraps at the edges (pale shape x≈630–670,y≈210–230; a light blob clipped at the right edge x≈965–990,y≈245–265); firelight is not distinguishable.
- **08 `road-exit-glance-toward-lure` (00:02):** Still occluded — the companion is back on screen mid a **"Take the revive"** prompt (apparent companion KO), filling x≈650–960,y≈190–410. Herd cue is squeezed above it (creature x≈615–650,y≈210–225; fire x≈760–790,y≈215–235).
- **09 `approach-30m` (00:08, 55m):** Clear again — two Meadowharts x≈595–660,y≈195–230, fire x≈750–790,y≈215–235.
- **10 `prompt-offered` (00:22):** Herd reads cleanly, x≈590–660,y≈190–290, fire x≈700–740,y≈250–280, with an explicit, well-named prompt: **"Watch the Meadowhart herd."** No distinct watcher/NPC figure is visible next to the fire in this or the 09 frame — it reads as "herd near an unattended campfire," not "herd with someone watching it."

**Fixed 40m comparison (herdcue_road vs herdcue_glance):** Looking straight along the road, the cue is nearly invisible — only a sliver of one creature clipped at the extreme right edge (x≈1195–1260,y≈290–360), no fire glow at all. Only once the camera is turned toward the fire (herdcue_glance) does it read cleanly (two Meadowharts x≈480–560,y≈225–290, fire x≈610–660,y≈245–280). So a player who never glances off-axis at ~40m gets essentially nothing; an ordinary player looking down the road may not notice it without a deliberate look, though the actual walk capture (04–06) shows it does read from the natural over-the-shoulder angle at ~56m without an explicit "glance" beat.

**Verdict: PARTLY.** The cue (fire + two pale silhouettes) is real, world-space, and becomes legible on approach, ending in a correctly-named prompt ("Watch the Meadowhart herd," frame 10). But three things weaken it: (1) at a dead-ahead road view it is nearly imperceptible (herdcue_road) and depends on an off-axis angle to register; (2) the two frames meant to test "does the player glance toward it before leaving the road" (07, 08) are instead occupied by an unrelated NPC/companion event that visually blocks the sightline exactly at the decision point; (3) "someone watching it" does not read visually anywhere in the set — it is a campfire beside a herd, with no watcher character model in view.

---

## B. Hall (Alpha Galecrest) — **PARTLY**

**Sequence read (hall_10→16):**

- **10 `lure-first-seen` (17:15, ~140m):** No name tag, no creature of any kind. Only distant ruin/pylon towers on the horizon (x≈150–260,y≈90–165 and x≈440–545,y≈165–195). At this labeled checkpoint there is in fact no legible lure yet.
- **11 `road-glance-at-first-sighting` (17:25):** No Alpha name tag either. What is visible is the player's **own** companion Gale, out ("Put Gale away" prompt, team panel highlights Gale), a large gray-white bird at x≈390–560,y≈280–410 — same species as the wild alpha, a real confusability risk for a player trying to read "is that the wild encounter or my own creature."
- **12 `lure-first-readable` (17:38, ~112m):** The floating name first becomes legible here: "...ha Galecre..." (reads as "Alpha Galecrest," edges clipped by distance/fade) at x≈520–650,y≈230–260, hovering near a dark castle-like silhouette (x≈470–660,y≈175–260). No creature body is identifiable under it yet — the lure at this distance is text-only.
- **13 `road-glance-before-exit` (17:59, ~58m):** Name at x≈490–650,y≈230–260. A large gray-white bird (wings, beak, legs clearly rendered) stands in the open field right beside the road path at x≈610–750,y≈185–310, unobstructed by any structure or terrain — this is the first clear, plausible sighting of the alpha's own body, and it is in direct line of sight from the road.
- **14 `road-exit-glance-toward-lure` (18:09, ~48m):** Full "Alpha Galecrest" name now clearly readable (x≈545–750,y≈245–270), floating in front of a large dark ancient tower (x≈740–1080,y≈0–460). **No bird body is visible anywhere in the frame** at this checkpoint, despite being closer than frame 13. The name persists as a world-space marker while the creature itself has dropped out of view (moved off, or occluded by the tower) — a real gap in continuous body-visibility right at the moment the player is meant to be drawn off the road.
- **15 `approach-30m` (18:23):** Name at x≈545–750,y≈235–265; a bird in a landing/flapping pose reappears just below/left of it at x≈605–700,y≈235–330, now in an open flower meadow off the road.
- **16 `prompt-offered` (18:37):** Two large birds are clearly visible with detailed plumage — one centered, wings fully spread, x≈490–790,y≈150–430, a second smaller one to the right, x≈640–980,y≈130–400 — this is the first frame that reads unambiguously as "a pack," not a lone bird. However, the on-screen text is **"You backed off."** with the bottom prompt reading **"Put Gale away"** (a companion-toggle prompt), not a distinct pack/alpha interaction prompt. The name tag itself is partly obscured by the near bird's wing here.

**Line of sight from the road:** At the last still-on-road checkpoint with a visible body (13, ~58m) the alpha is standing in open ground beside the road path, clearly not hidden behind a structure — good. But the very next checkpoint (14, ~48m, explicitly the "toward lure" exit glance) shows no creature at all, so "reliably in line of sight the whole time before leaving the road" is not fully supported by this frame set.

**Verdict: PARTLY.** The floating "Alpha Galecrest" name is a genuine world-space lure (not HUD/minimap) and does eventually resolve into a readable, named pack of 2+ birds on approach (frames 13, 15, 16). But: it is text-only until ~58m with no body attached before then; the body then disappears again at the ~48m road-exit checkpoint even though the name is still shown; the player's own same-species companion (Gale) is visible earlier in the sequence and could be mistaken for the wild encounter; and the terminal "prompt-offered" frame shows a defensive "You backed off." message plus a companion-toggle prompt rather than a clear pack-engagement prompt, so the intended arc ending "at the prompt" is not crisply demonstrated by these frames.
