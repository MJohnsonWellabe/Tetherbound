STATUS: ready (land; capture-only, no score claim)
BRANCH: tb/item-catch-card
HEAD: see git log

# Stale "X broke free / Weaken it more" card in catch frames (LANE-SCOUT flag; F38#14, F39#9) — LANE-MESHY 8 Nov

## Finding
- Not the capture's `_top_up_verdict_card`: it is armed per throw and released right after that throw's verdict shot (`_release_verdict_hud`).
- Not a player-facing HUD bug: the game raises the verdict card on `catch_resolved`, which combat_manager emits only after ABSORB, `first_shake_delay` 0.9 s, each shake (`shake_interval` 0.85 s) and `settle_pause` 0.8 s, i.e. roughly 4 s after the strike. `hud.json catch_card.clear_on_release_1107` stays OFF (a base vs ON capture showed no difference on these frames).
- It is a CPU wall-time artefact: on llvmpipe each rendered frame feeds the catch timer 0.3 s or more, so the whole absorb, shake and verdict timeline elapses inside the few frames between the strike and the shutter (and, for 02-orb-in-flight, inside the unpaused `_capture`'s own POSE_FRAMES). A temporary probe (reverted) logged the card state per still on a Meadows `--stages-on-catch` run: at 02-orb-in-flight the old card had already expired (`_outcome_left` -0.07, `_breakout_card_up` false); the card in the frame is the photographed throw's own verdict (3 shakes, "So close"), resolved before 03-strike was taken.
- On current main, F39#9's three Tidewake stills (with `--stages-on-catch`, #864) show no broke-free card; 03-absorbing shows that throw's own "Caught" card, the same CPU artefact.
- So these stills are reliable on the GPU (60 fps: flight and strike come well before the verdict) and unreliable on CPU.

## Change on this branch
- `job.json` F38#14: the three Meadows repros add `--stages-on-catch` (same disclosed stand as F39#9), so the stages come from the weakened throw's real absorb and shake path instead of the full-health ~0% throw. On CPU the card still appears (artefact above); on GPU it should not.
- `overlay_clear.json`: the overlay used for the base vs `clear_on_release_1107` check (no runtime effect).
- No game code or config change.

## Note
- In the Meadows run every weakened throw also failed at 3 shakes (pinned roll), so `08-caught-verdict` never succeeded there; Tidewake's succeeded.
