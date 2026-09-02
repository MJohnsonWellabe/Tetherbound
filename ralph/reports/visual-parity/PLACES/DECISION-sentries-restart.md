# Hall gate sentries — clean restart (VP8, 2026-09-02)

Frames: `round11-sentries/` (1280x720, `--only=10-stronghold`, one render). Probe logs beside them.

## What the probe found (`tools/_probe_gate_sentries.gd`, headless, real playground boot)
- `Stronghold/GateSentries` holds **2** bodies, each `character_model.gd` with a Skeleton3D, 2 MeshInstance3D with meshes,
  `AnimationPlayer` playing `idle`, `visible_in_tree=true`, `has_model()=true`, height 1.80 m. So: **spawned, rigged, not empty**.
- Old world positions (6.0, 6.17, 7546.9) / (10.0, 6.17, 7546.9); gate-face camera (8.00, 5.02, 7536.70) looking at (8, 7.77, 7560),
  pitch 6.7 deg. Projected: feet px 740/540, heads 738/542 → **88 px tall, on-screen, 10.5 m away**, no collider on the sightline.
- Render AABB x-span 5.68–6.32 / 9.68–10.32 versus jamb stone at |x| 2.0–2.9 local (world 5.1–6.0 / 10.0–10.9): the body's
  CENTRELINE sat on the jamb's inner face, so half of each sentry was inside the jamb and the visible half was a 0.32 m
  sliver, 12–16 px wide. Round 10's own frame has that sliver: luma 0–3 in 960-px column 400, a dark stripe, not a figure.

**Root cause (one sentence):** the sentries were built and in frame all along, but placed with their centreline on the jamb
face, so every previous round photographed a 12–16 px sliver of a half-buried body.

## The fix (smallest edit)
- `data/config/stronghold.json` `gate_sentries.at`: `[±2.0, -13.1]` → `[±1.5, -14.9]`, `on_causeway: true` — 0.5 m inboard
  (body span 1.18–1.82 clear of the stone) and 0.7 m south of the jambs' proud face (-14.2), on the ramp deck.
- `scripts/world/stronghold.gd::_build_gate_sentries`: honour `on_causeway` via the existing `_causeway_y()` (same flag the
  garrison camp and braziers already use) so the feet sit on the deck, not floating at `_floor_y`.
- Re-probe after: feet (6.50, 5.69, 7545.10)/(9.50, 5.69, 7545.10), seated **0.00 m** above `ApproachRampBody`; 8.6 m from camera;
  projected feet px 732/548, heads 729/551 → **107 px**; jamb base columns 763/517; sightline clear.

## Measured proof (PIL, diff vs round-10 baselines with the identical camera; luma = .299R+.587G+.114B)
`10-stronghold-gate-face-day.png`
- west guard: rows y[272,379] → **108 px tall**, cols x[710,759], centre 734, **28 px** from jamb col 763; mean luma 53.8, p90 99.
- east guard: rows y[258,379] (top rows include ivy diff) → **≥108 px**, cols x[529,575], centre 552, **35 px** from jamb 517;
  mean luma 47.2, p90 85. Doorway background behind them 95. Both read as Team Tether grunts flanking the arch (see frame).
- **Day criteria PASS**: two humanoids ≥ 65 px, each within 120 px of a gate post.

`10-stronghold-gate-face-night.png`
- both silhouettes present at the same columns (west 107 px, x[711,750]; east x[530,575]).
- mean luma inside the projected boxes (x±22, y 272–379): **west 5.1, east 6.4** (diff-band boxes 5.4 / 11.8, p90 13 / 38).
  Doorway behind them 20.3, deck 6.6. Required ≥ 25.
- **Night criterion FAIL**: the guards are visible as dark shapes against the doorway but are not measurably lit, despite the
  gate sconce OmniLights 4.3 m away (energy 2.6, range 16) and the brazier fires 9.4 m away (range 26) confirmed present.

`10-stronghold-gate-day.png` (entrance stand, ~42 m): 572 px changed in the doorway region x 591–689 / y 280–344; at 6x
zoom the pair reads as two figures flanking the red door (~20 px tall) — the "ideally visible at gate-day too" ask is met.

## Decision
- Keep the change: day is strictly better (two legible guards where round 10 had none), night is not worse (baseline boxes
  5.5 / 14.1 with no figure at all). Nothing was reverted.
- Night is a **visual ceiling** for placement work: the emission floor (0.18, halved at night) plus point lights at 4.3 m still
  leave the grunt texture at 5–12 luma under the night exposure (1.2) — the whole gate face reads 6–20 in this frame.
  Next mechanism, if the night read is wanted: a dedicated low sconce/brazier per post at chest height (~2 m, energy tuned
  by `tools/_probe_grunt_luminance.gd`), or a night `character_emission_floor` bump — both are lighting decisions, not placement.
