# F22#4 other Meadows named fights: CPU baselines (21 Oct 2026, tb/fights) — US Central

Same capture tool, renderer and fixture as the Riverwatch rounds (CPU llvmpipe Compatibility/Low, 1920x1080, seed 1042206, Lv3 Ripplet, keep-alive). Control code `5d26ccdb9` / `72d5a9230` (all F22 candidates OFF). Single-arm scoring (no A/B), three fresh code-blind judges, sheets of six frames each (kept local; scores below).

| Fight | Member captured | J1 | J2 | J3 | Mean Bar A | Mean Bar B |
|---|---|---|---|---|---|---|
| Captain Halder (`captain_field`) | 1, Tuskroot (signature: halder_range lane charge) | 4.3 | 4.2 | 4.6 | **4.37** | 3.33 |
| Captain Vance (`relay_captain`) | 4, Tuskroot | 4.4 | 4.5 | 5.0 | **4.63** | 3.60 |

Shared defects (all judges): the signature telegraph is a thin magenta outline (Halder's lane reads as a short box ending at Ripplet; Vance's is a tangled loop); no wind-up on the boss and no impact on hits; the boss is about Ripplet's size; HUD ~35% with dead text. Halder's ground has no identity (open grass, campfire, red frame); Vance's relay has identity but dark floor, stair-stepped wall and foreground cage/pylon occluding the fight.

Not captured, with the reason:
- Captain Vess (`captain_ridge`): from the fresh fixture the challenge dialogue completes but no fight starts (3 presses, fighting=false for 900 frames); likely a road-order prerequisite.
- Officer Dell (`relay_officer_dell`, live member 2): the capture hung after "fight live" for 30+ min and was killed.
- Warden Aldis: in a multi-trainer run the previous fight (Halder) was still live, so the "warden" frames show Halder; invalid. Needs its own run.
- Nerissa (Tidewake), Veyra (Cloudreach), Stormwood finale: not in the Meadows capture tool; need their realm's capture path.
