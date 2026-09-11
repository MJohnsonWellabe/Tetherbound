# Pickup glow far-size cap — shared production proof

## Verdict

**RETAIN the 1.0 far-scale cap.** This is a safe, modest shared improvement rather
than a complete pickup-presentation pass. Road Gate and Old Mill keep their landmark
hierarchy while their small finds remain visible in day and night. Ironwood's green
and pink cues are reduced but still carry too much brightness against the open glade,
especially at night. The cap closes the specific bug where distance compensation can
enlarge a cue beyond its authored world radius; it does not address authored radius,
additive strength or night exposure.

## Receipt

`manifest.json` records **6/6 valid 1280x720 production frames**, with no load or
save failures:

- Road Gate approach, day/night
- Old Mill crossing axis, day/night
- Ironwood crafting glade, day/night

All six came from one production Meadows load with live Terrain3D, current baked
scatter, props, pickups and encounters. HUD/overlay were hidden and weather/time
were pinned. No pickup, light, prop, creature or progression content was injected.
The hidden trainer first streamed Terrain3D at Road Gate; each teleported world view
then re-sampled ground and re-seated the trainer after streaming. The cold-first
grounding defect from the Ironwood R2 receipt did not recur.

## Full-resolution comparison

- **Road Gate:** compared with `ROAD-GATE-R1/01-road-gate-approach-open-*`. The
  white pickup cues remain immediately discoverable but no longer challenge the
  gate lintel, blocked opening and village silhouette for first read. Dynamic gate
  state and creature positions differ, so this is a composition match rather than a
  pixel-difference test.
- **Old Mill:** compared with
  `OLD-MILL-CROSSING-IDENTITY-R3/04-crossing-axis-*`. The cyan bank cue remains
  visible at the frame edge while the mill tower, wheel and bridge retain priority.
  There is no new daytime disappearance or night-time scene takeover.
- **Ironwood:** compared with `IRONWOOD-GROVE-IDENTITY-R1/04-crafting-glade-*`.
  Both cues remain visible and are modestly smaller, proving the cap does not hide
  tall-grass finds. Their additive brightness still competes with the pale elder
  trunks and trainer, so further work—if approved—should test the shared strength or
  authored-radius lever rather than a location-specific exception.

Focused validation already passed 18 pickup/Ironwood tests, 77 assertions, and the
combined Band 4/pickup/Ironwood selection passed 26 tests, 109 assertions, with zero
failures. The proof run exited 0; the renderer was verified clear and released.
