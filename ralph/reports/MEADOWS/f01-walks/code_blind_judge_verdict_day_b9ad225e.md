# Code-blind judge verdict — DAY village walk (day_b9ad225e)

Criterion under test (functional/readability only; art polish deferred): *"Normal-controller DAY walk reaches every opening NPC, camp and gate"* — each target must be reached AND identifiable in-frame as what it is.

| Target | Frame(s) | Reached? | Evidence in the image |
|---|---|---|---|
| Grandpa | `visits_day_003_reached-grandpa.jpg` | YES | Player faces a named elder NPC indoors, interact prompt reads "Talk to Grandpa" directly over him. |
| Bram (inn) | `visits_day_014_reached-bram.jpg` | YES | Player at a counter facing an NPC; prompt "Greet Bram"; background shelf sign reads "ROOMS · ALE · STOCK", clearly an inn interior. |
| Tam | `visits_day_022_reached-tam.jpg` | YES | Player and companion face an NPC outside a stone/timber building near a well; prompt "Greet Tam". |
| Mira (shop) | `visits_day_027_reached-mira.jpg` | YES | Player faces an NPC across a counter indoors; prompt "Greet Mira" (shop-counter framing matches a shopkeeper). |
| Oskar | `visits_day_033_reached-oskar.jpg` | YES | Player faces an NPC in a fenced yard near a tree; prompt "Greet Oskar". |
| Halda | `visits_day_041_reached-halda.jpg` | YES | Player faces a blue-haired NPC in a grassy yard; prompt "Greet Halda" (a second background NPC is also visible, unambiguous who is greeted). |
| The old key | `visits_day_049_take-the-old-key.jpg` / `visits_day_050_reached-the-old-key.jpg` | YES | A small pedestal with a key-shaped glinting object sits at path's edge under "The Rise" gate sign; prompt "Take the old key"; a follow-up dialog from Grandpa Elias ("There you go. The old key still turns.") confirms the pickup. |
| RoadGate (The Rise) | `visits_day_053_at-gate-roadgate_-closed.jpg` / `visits_day_054_reached-gate-roadgate.jpg` | YES | Player stands at a closed wooden gate under a "The Rise" sign; prompt "Try the gate"; both frames show the sign text clearly. |
| Practice Meadow camp | `visits_day_068_end.jpg` / `visits_day_069_reached-practice-meadow-camp.jpg` | PARTLY | Position is reached (log: `VISIT Practice Meadow camp kind=camp dist_m=2.53`) and the approach frame (068) shows a small cluster — one conical orange tent-like shape, a crate/basket, two sacks, a barrel and a signed gate arch — which is a plausible but weak camp read (no campfire, bedroll or seat visible; the crate/sack/barrel grouping reads closer to a supply cache than a lived-in camp). The arrival frame (069), the one actually tagged "reached", is significantly obstructed: a large foreground creature model fills the center-left of the frame, and a translucent cyan vertical slab (a HUD element labeled "NEXT · Practice Meadow" with a hex icon) covers roughly the left fifth of the screen, further crowding the already-small, distant camp geometry on the right. No prompt text is shown for this target (log shows `prompt="-"`), so there is nothing textual to confirm identity either — identification rests entirely on the obstructed geometry. |
| TrailGate (South Bridge) | `visits_day_081_end.jpg` / `visits_day_082_reached-gate-trailgate.jpg` | YES | Player stands under a timber gate arch with a large, unmistakable "South Bridge" sign (also a second hanging sign reading "South Bridge" visible off to the side). |
| PondGate (The Pond) | `visits_day_095_end.jpg` / `visits_day_096_reached-gate-pondgate.jpg` | YES | Player stands at a gate arch with a clear "The Pond" sign in the 095 end frame; the 096 arrival frame is a closer, partially obstructed angle (sign edge-on and partly hidden behind the post) but the preceding frame plus map/log context make the identity unambiguous. |

## Overall

**DAY WALK: FAIL** — blocking item: **Practice Meadow camp**. The arrival frame does not cleanly read as a camp: it lacks any clear fire/bedroll/seat signifier, its tent/crate/sack grouping is small, distant and ambiguous (closer to a supply cache), it has no on-screen prompt to disambiguate, and its own arrival frame is doubly obstructed — by a large foreground creature and by a translucent cyan HUD slab covering roughly the left fifth of the screen.

## Secondary observations (not deciding the verdict)

- The same translucent cyan vertical slab/HUD element that obstructs the Practice Meadow camp frame is also faintly visible at the left edge of `visits_day_041_reached-halda.jpg`, suggesting it is a persistent HUD element (not scene geometry) that intermittently crosses into the frame rather than something unique to the camp.
- `visits_day_096_reached-gate-pondgate.jpg` (the frame actually tagged "reached") is a tighter, more obstructed angle on "The Pond" sign than its preceding `_end` frame; the sign is legible but partially occluded by the gate post itself. This did not block the verdict here because the immediately prior frame gives an unambiguous clean read of the same sign, but it is a weaker "reached" frame than the other gates.
- Several interior NPC shots (Grandpa, Bram, Mira) are cropped close with camera angled into a corner/ceiling; NPCs are still identifiable via the prompt text and framing, but the compositions are tight.
