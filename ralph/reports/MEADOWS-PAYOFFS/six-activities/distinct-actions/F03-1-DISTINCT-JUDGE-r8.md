# F03#1 distinct optional action: code-blind judge, round 8 (hall)

Judge input: the 4 frames in `r8/` (`hall_01.jpg` .. `hall_04.jpg`) plus the designed/other action lines supplied in the brief. No code, data, config, tests or scripts were opened.

| activity | action shown | matches ledger | distinct from nearest | overall |
|---|---|---|---|---|
| hall | Player's Burrowback fights a large, named **Alpha Galecrest** (Lv 19, bird, nameplate "Alpha Galecrest") in a meadow among a small flock of ordinary Galecrests. The player opens the orb aim mid-fight (4% capture chance shown), then wins: "The wild creature is beaten.", +334 XP, "The west shoulder has gone quiet." | PASS (the "defeat" branch of catch-or-defeat is shown; the once-only reward is not visible) | PASS. The nearest activity is **vault** (Elder Trailpup fight); **bram** is next. This fight is outdoors, against a wild bird alpha with a live capture reticle. Vault is an underground Trailpup fight with a heartstone. Bram is a fight against a human trainer's creatures, which cannot be caught. | PASS |

## Evidence

- **01 (prompt):** An "Alpha Galecrest / LEVEL 19 / AIR" boss-style nameplate sits over a world label. The alpha is a large blue-and-white raptor, and two smaller ordinary Galecrests stand behind it. A faint translucent arena boundary is visible at the upper left. The combat HUD is up (Burrow Strike / Tremor Roll / Throw / Switch, Orbs 7). There is no visible interact prompt; the frame already shows the encounter.
- **02 (fight start):** The alpha rears up and towers over the trainer, so the scale reads correctly. Hit feedback reads "your type held — that barely landed". The orb aim reticle shows a 4% CAPTURE CHANCE. The catch branch is offered, which marks this as a wild fight and not a trainer fight.
- **03 (fight mid):** Burrowback is engaged at close range. Burrowback's HP bar has dropped since frame 02, and the capture reticle is still up.
- **04 (fight end):** "The wild creature is beaten." with +334 XP, and Burrowback reaches Lv 20. The site-specific line "The west shoulder has gone quiet." shows the site has been cleared.

## Caveats (do not flip the verdict)

- **The once-only reward is not shown.** Frame 04 shows only ordinary XP and a flavour line. Nothing marks a unique, one-time site reward.
- **The site is not legible as off-road rare habitat on the Hall approach.** The alpha fight is set in the same open flower meadow as the rest of the region, and the faint dome is the only thing marking the site.
- **Frame 01 is labelled "the prompt" but shows no interact prompt.** The encounter has already started.

## Fix (most important, non-blocking)

Show the unique reward in the end frame: a named once-only item or reward toast, plus a "site cleared / won't return" marker. Without it, the ending looks like any ordinary wild win.
