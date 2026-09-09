# Water return gate: installed masonry finish

Root-owned bounded visual assignment on shared `codex/aim-windup-proof-0909`.
Source baseline is main ab5314 plus preserved shared work. Own only
`scripts/world/realm_gate.gd`, `data/config/realm_gate_visual.json`, a bounded
visual/mechanical probe and this report. Do not edit Water terrain, progression,
Session, actor placement, lighting or held Veilfall work.

The independent `audit-resume/REJUDGE-WATER-GATE.md` names a plain blue-grey
threshold without surface identity. Root inspected the retained actual
`gate-day-view.png`: the large upright reads as a flat slab. The source confirms
explicit untextured BoxMesh masonry, not a failed asset binding. The installed
`T_UnevenBrick` texture already supplies the Hall, village and Cloudreach masonry
family. Reuse it at the established 0.28 tile scale with a restrained stone tint;
retain original silhouette, gate state colours and every mechanical dimension.

Acceptance for this narrow correction: real day/night return-gate views show
stone courses at unchanged camera/resolution; locked/unlockable/open visual
states and barrier behavior remain correct. A source-only change earns no
visual credit. A fresh code-blind critic remains required before acceptance;
the current session rejected creation of another critic with agent thread
limit reached. No substituted self-verdict is claimed. Two serious visual
rounds remain the ceiling, and broader First Shore staging stays separate.

Implementation: only the shared gate's two masonry materials changed. They now
sample installed `T_UnevenBrick_BaseColor.png` with world-space triplanar mapping;
`data/config/realm_gate_visual.json` supplies stone/trim tints, tile scale and
roughness. Gate geometry, barrier, seal and open-state materials are unchanged.

The existing `smoke_meadows_realm_handoff.gd` passed on the first invocation,
exit 0 in 5.6 seconds, with no native/script errors. It exercises production
reward idempotency, ordinary input, stamina, no-reload gate state and disk
persistence. Its tiny stage is not a full Meadows path. Complete logs and
launcher/engine-child memory samples are retained at
`.artifacts/water-gate-finish-mechanics-20260909/`. Peak system commit was 50%,
246 processes; the actual engine peaked at 105,992,192 private bytes and
156,409,856 working-set bytes. No guard fired. This proves mechanical compatibility
of the material change, not visible quality.

The first production Water run completed ordinary input through the actual return
gate into grounded Stormwood deck arrival, with unchanged WORLD/player flag
fingerprints. It exited 0 in 54.4 seconds and captured normal/day/night images at
1280x720. The images show the installed masonry on the gate.

This run is **not raw-error clean**: the concurrent character candidate's new
`art.json` binding entered the shared checkout before its PNG had been imported.
The engine reported `No loader found for resource:
res://assets/characters/trainer/trainer_teal_accent.png` from the new character
material path. The original character material remained visible as fallback.
This is a cross-lane integration failure, not a gate-material failure or an
accepted clean run. The character lane now owns the exclusive import correction;
one integrated Water rerun is queued afterward. All original raw logs, images,
resource samples and terminal result remain at
`.artifacts/water-gate-finish-world-20260909/`.

The corrected integrated repeat ran 12:40:02–12:40:58 UTC (55.75 seconds),
exit 0, no guard and no ERROR/SCRIPT ERROR in the complete retained logs at
`.artifacts/water-gate-finish-world-20260909-verified/`. Known deprecated
interpolation and Terrain3D mipmap warnings remain. All three 1280x720 frames
were written; ordinary gate input completed Stormwood deck arrival, with world
fingerprint 3731753825 and player fingerprint 4226899299 unchanged. This uses
synthetic prerequisite flags and is not an earned campaign continuation.

The independent reused image-only reviewer returned **A No / B No** for the
day/night gate views (frames 04–05). Visible masonry does not resolve the isolated,
edge-on doorway, bare setting or competing texture frequencies. See
`VISUAL-WAVE-IMAGE-REVIEW-0909.md` for review conditions. The material candidate
is held, not accepted or shipped. A separate Water-local threshold court is now
being developed; the shared gate material is frozen during that work.
