# Independent visual verdict — `final-stonewater-05`

**OWNER-0912 Tier 2 #6: FAIL — the causeway approach blocker remains.**

The production manifest is complete and internally consistent: `complete: true`,
17/17 planned 1280 × 800 PNGs, no capture failures, production Meadows scene,
and production `StonewaterReach` runtime node. I inspected every frame at native
resolution and compared the set with `final-stonewater-04` and its independent
HOLD. The wreck, three-beat approach, Springhead cascade, and continuous clear
water remain accepted. The newest causeway correction does not close the central
visual blocker: it moved the far-bank CrownStone, but the large rock masking the
actual approach is still present. The front day/night pair therefore repeats the
same obscured, rock-plus-wall silhouette, and neither direction proves the
promised paired stepped buttresses as readable structure.

## Strict requirement verdicts

| Requirement | Verdict | Frame evidence |
|---|---|---|
| Three-beat approach | **PASS** | `01-haulage-wreck-day`/`09-*-night` and the stronger `15`/`16-*-oblique-*` pair establish the broken-haulage warning. `02-road-arrival-*`, `03-overlook-water-*`, and `04-run-east-day` carry the road toward the waterworks. `05`/`14-spring-arrival-*` and `06`/`08-springhead-*` provide the terminal intake beat. The sequence remains geographically coherent in day and night. |
| Wreck identity | **PASS** | `15-haulage-wreck-oblique-day/night` gives the clearest production-road read of the broken wagon body, separated wheel, long displaced beam/axle, nearby standard, and blocking rock. Warm wood remains distinct at night. `01`/`09` retain the wider arrival context. |
| Causeway approach mass and route | **FAIL** | In `04-run-east-day` and `10-causeway-front-day`, the enormous foreground/channel rock still hides the causeway's right pier, much of the aperture edge, and its relationship to the water route. The masonry reads as a short capped wall attached to a boulder, not as the location's dominant civil-waterwork crossing. `12-causeway-front-night` compresses rock and arch into one nearly black mass and loses the route opening almost completely. |
| Causeway buttress silhouette | **FAIL** | `10` and `12` cannot show paired stepped supports because the right side is occluded. `11-causeway-reverse-day` and `13-*-night` cleanly show the open arch and water direction, but the visible dress still reads mostly as a flat rectangular face with small side blocks; neither frame establishes two substantial forward buttress shoulders/feet. Source presence and dimensional tests do not substitute for a readable silhouette. |
| Springhead intake cascade | **PASS** | `05`, `06`, `08`, and `14` retain a raised headwall, cyan vertical intake fall, side structures, and short lower spill into the broad basin. The drop and masonry remain readable in both states without renewed foreground occlusion. |
| Continuous grounded water and bank discipline | **PASS** | `03`, `04`, `06`, `10`, `11`, and `13` show a continuous blue run through the causeway and onward to Springhead. Dense grass does not repopulate the water sheet; tall clumps remain bank-side. The hard cyan contact outline at the blocking rock remains crude, but does not break water continuity. |
| Day/night value and hierarchy | **FAIL** | The wreck and Springhead survive their night pairs, controlled water value connects the region, and `13` keeps the reverse arch legible. The player's actual causeway approach does not survive: `12` turns the retained rock into a dominant black slab and merges it with the dark masonry. A modest causeway material lift cannot recover geometry hidden behind the rock. |

## Delta from `final-stonewater-04`

- **Retained successes:** complete three-beat journey, readable wreck in both
  oblique states, continuous vegetation-free water, Springhead fall/spill, and
  stable day/night terminal identity.
- **Narrow improvement:** the separate far-right/far-bank boulder visible at the
  edge of R4's front pair is gone, and the causeway cap has slightly more night
  separation.
- **Still blocking:** the large rock immediately in front of the right causeway
  pier is unchanged in the played approach. It still dominates `04`, `10`, and
  `12`; the approach aperture and both buttresses cannot be read together.

## Root-cause correction to the previous diagnosis

The visible evidence shows that the rock moved by the latest pass was not the
approach blocker. Production source places the new smaller `CrownStone` at
`(-111, 3496)`, well outside the direct front sightline. The retained
`EastGateStone` is at `(-101.5, 3471.5)` with scale `1.35`; from the dedicated
front stand `(-104, 3465)` toward causeway `(-84, 3482)`, its centre has only
about **3.3 m** of lateral clearance from that sightline. That matches the huge
rock occupying the right half of `10`/`12`. The latest source contract checks
the west run stone and CrownStone clearance, but not this EastGateStone, allowing
the visible failure to remain while tests pass.

## Smallest remaining correction and reproof

Move or substantially reduce `EastGateStone` so the full arch aperture, both
piers, and both stepped buttress feet are simultaneously visible from the real
approach in `04`, `10`, and `12`. Preserve the now-secondary far-bank crown,
water, wreck, Springhead, vegetation clearing, and restrained lighting. If the
buttresses still read as shallow boxes after the occluder is removed, strengthen
their side-plane/profile rather than adding more foreground mass. Recapture the
same 17-frame plan; no new evidence views are required.

This report judges visible production presentation only. It makes no claim about
collision, wading, swimming, or traversal mechanics.
