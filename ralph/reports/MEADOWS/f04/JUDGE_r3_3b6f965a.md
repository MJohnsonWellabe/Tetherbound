<!-- Code-blind judge (sonnet subagent) on the six fight renders at 3b6f965a (render runs 36427399935 warden, 36427404915 halder, 36427410051 vess, 36427414871 oreth, 36427419851 vance, 36427425615 dell). Frames are not committed (size); the verdict cites them by name. -->
# F04 fight-readability verdict

Judged blind from JPG frames + `fight_log.txt` in each of six folders (warden, halder, vess, oreth, vance, dell). Functional/readability only, per instructions — art polish is out of scope.

---

## Vance (Captain Vance — Tuskroot CHARGER, "step off the lane")

**Q1 — Tactical question readable: PARTLY.**
Early tells (`t01`, `t02`) clearly show a magenta lane painted on the ground from Tuskroot toward the player, readable at the normal fight camera (`relay_captain-t01-stand-start.jpg`). But the fight moves into a gate/tunnel structure for the second half, and the decisive dodge (tell 4, the one avoid in this run) happens with the **camera clipped fully inside wall geometry** — see below. The tactical question is readable for half the fight and unreadable for the other half of the same encounter.

**Q2 — Tell readable, hit vs avoided distinguishable: FAIL for the avoided case.**
`relay_captain-t04-dodge-start.jpg`, `-t04-dodge-mid.jpg`, and `-t04-dodge-strike.jpg` are **all three solid stone-wall texture** filling the entire frame — no creatures, no lane, no player, nothing but HUD text and a starburst VFX. The bottom-of-screen confirmation text ("it missed you") is legible, but the entire visual telegraph and payoff of this fight's signature mechanic — the one tell in this run that actually succeeded — is invisible. Log: `tell 4: 0.80s, policy dodge` / `strike 4 policy=dodge outcome=miss`. Where the camera does work (`t02`, `t03`), hit feedback is strong: `relay_captain-t02-dodge-strike.jpg` shows a clear "Camera STAGGERED — recovering" banner with a white flash and blue recovery ring.

**Q3 — Aftermath: FAIL.**
`relay_captain-a01.jpg` is an extreme close-up of the back of the player trainer's own head/hair filling almost the entire frame — Captain Vance is not visible at all, only the "Greet Captain Vance" interact prompt. By `a05`–`a14` the camera recovers to a normal angle, but **no victory dialogue box ever appears** in any of the 28 aftermath frames or `99-after` (contrast with warden/halder/vess/oreth, which all show a portrait + line). No fight-specific change (token, banner, stand-down) is visible anywhere in this fight's aftermath. Combat HUD is correctly gone once recovered.

**Q4 — Framing notes.** Camera-in-wall (t04) and camera-in-own-hair (a01) are the two worst framing failures across all six fights.

**Overall: FAIL.** This is meant to be the flagship "read the lane, step off it" fight, and the one frame set that would prove the mechanic works is the one place the camera is inside a wall. The aftermath never confirms victory. Both problems point at the same likely cause: the arena's tunnel/gate section is too tight for the fight camera.

---

## Halder (Captain Halder — Tuskroot CHARGER, exposed field)

**Q1 — Tactical question readable: PASS.**
Open field, no geometry problems. `captain_field-t01-stand-start.jpg` shows the magenta charge lane clearly painted from Tuskroot across the ground, "! incoming — move" tell text legible, good silhouette separation between player creature, Tuskroot, and the bystander trainer.

**Q2 — Tell readable: PASS for the tell itself; avoided outcome unverifiable — FAIL for "distinguishable."**
Tell frames are clean and readable (`t01`–`t04`, all four look like the lane sample above). But per `fight_log.txt`, **all six logged strikes in this fight resolve `outcome=hit`**, including both dodge attempts (`tell 2: policy dodge → strike 2 outcome=hit 20.7`; `tell 4: policy dodge → outcome=hit 20.7`). The design intent for this fight is explicitly "the answer is to step off the lane" — but this capture never once shows that answer working. There is no "avoided" frame to compare against a "hit" frame for this fight at all, so hit-vs-avoided is impossible to judge as distinguishable here; the more concerning read is that the lane-step-off never pays off in this run.

**Q3 — Aftermath: PASS.**
`captain_field-a01.jpg`: Captain Halder is clearly visible and unobstructed (Camera is at frame edge, not blocking him), portrait + line ("Clean. No arguing with clean.") is shown, combat HUD is gone. No obvious banner/standard/token handoff visible, but the dialogue and framing both work.

**Q4 — Framing notes.** Clean throughout. No wall clipping observed in this set.

**Overall: PARTLY.** Presentation is the best of the two charger fights, but the captured run never demonstrates the fight's entire reason for existing — a successful dodge of the charge.

---

## Oreth (Captain Oreth — Mosshell WALL, patience-then-punish)

**Q1 — Tactical question readable: PARTLY.**
`captain_riverwatch-t01-stand-start.jpg` shows a small Mosshell (a turtle, visually much smaller than the player's own creature) with a magenta zone tell and "! incoming — move" text — readable. But Mosshell here reads as a small, unthreatening creature rather than a "WALL" — nothing in the framing communicates "heavy/tanky" the way Vance/Halder's charge-lane does communicate danger. The intended patience/punish rhythm is not something a still can confirm (needs the long recovery window to actually feel long), but the punish cue text is present and legible.

**Q2 — Tell readable, hit vs avoided distinguishable: PASS.**
`captain_riverwatch-t01-stand-strike.jpg` shows a strong dual callout — "it's open — hit it" (punish window, teal) stacked with "it hit YOUR weakness" (damage warning, orange) — clearly worded and color-coded. Log shows both a hit (`strike 1 …outcome=hit 23.8`) and a miss (`strike 2 …outcome=miss`) in this run, giving a real comparison; both are legible via the on-screen text even where the VFX dust partially obscures the models.

**Q3 — Aftermath: PASS.**
`captain_riverwatch-a01.jpg` and `-99-after.jpg` are the cleanest aftermath shots in the whole set: Captain Oreth fully visible, the player trainer visible, the player's creature to the side without blocking anyone, portrait dialogue present, HUD gone. No visible fight-specific token/banner change, but the framing is exemplary.

**Q4 — Framing notes.** Best-framed fight of the six. Worth flagging as a scale outlier: this Mosshell reads noticeably smaller than the Mosshell fought in the Dell encounter (see Dell section) — same species name, very different footprint between fights.

**Overall: PASS**, with the caveat that "WALL" as a threat read doesn't come through visually — it reads as a small, harmless-looking creature rather than an obstacle to be patient against.

---

## Vess (Captain Vess — Galecrest DIVER, positional read)

**Q1 — Tactical question readable: PASS.**
`captain_ridge-t01-stand-start.jpg`: Galecrest is grounded with wings raised inside a magenta zone marker on a wooden banner post, "! incoming — move" legible. The zone-marker language is consistent with the other fights' tells, which is good for a player learning the game's visual grammar, though it means the "dive" doesn't read as visually distinct from a ground charger's lane — both use the same pink-zone convention.

**Q2 — Tell readable, hit vs avoided distinguishable: PASS.**
Log shows both hit (`strike 1 …hit 14.3`) and miss (`strike 2 …outcome=miss`) outcomes. `captain_ridge-t02-dodge-strike.jpg` (the miss) shows the player's creature at full, undamaged health with no stagger/flash — clean, legible "nothing happened" state that reads correctly as avoided.

**Q3 — Aftermath: PARTLY.**
`captain_ridge-a01.jpg`: dialogue box and portrait are present ("You read the gusts. Most don't bother." — good, on-theme line), HUD gone. But Captain Vess herself is not confidently identifiable in the live 3D scene behind the dialogue box — a small distant figure near a "Watchtower" sign may or may not be her, and the player's creature again occupies roughly a third of the frame on the right edge. Not as broken as Vance/Dell, but not a clean unobstructed shot either.

**Q4 — Framing notes.** Serviceable; creature partially crowds the aftermath frame edge.

**Overall: PASS**, with the aftermath shot weaker than Oreth's or Halder's.

---

## Dell (Relay Officer Dell — composition: Mosshell / Burrowback / Galecrest)

**Q1 — Tactical question readable: PARTLY.**
The composition intent (three different creatures, each fought differently) is real and does happen — `relay_officer_dell-r05.jpg` shows the fight has moved on to **Burrowback**, and `relay_officer_dell-r07.jpg` shows **Galecrest**, both with fresh full health bars, confirming the switch. But every numbered frame (`01`–`24`) and all four `t0N` tell triplets are captured **only during the Mosshell opener** — Burrowback and Galecrest never get their own readable tell sequence in this capture, so the "each fought differently" half of the design intent cannot be verified from what's here. It may simply be a coverage gap in this specific capture rather than a missing feature, but as delivered, two-thirds of the fight's stated purpose is not demonstrated.

**Q2 — Tell readable, hit vs avoided distinguishable: PASS (for Mosshell only).**
`relay_officer_dell-t01-stand-start.jpg` reads clearly (named health bar, "incoming" tell). Log shows both hit and miss outcomes for Mosshell's phase, and the strike frames show visible chip damage on Camera's health bar. Not verifiable for the other two creatures (no tell frames captured for them).

**Q3 — Aftermath: FAIL.**
This is the clearest aftermath failure in the set. `relay_officer_dell-a01.jpg` through `-a16.jpg` and `-99-after.jpg` are **visually identical** except for the in-game clock advancing (09:19 → 09:42) — Mosshell (the player's own creature) fills roughly the left half of every frame and **entirely blocks Officer Dell**, who is barely a silhouette in the archway background. No dialogue box, no portrait, no victory line, and no visible fight-specific change (no banner/standard/token/objective update) appears in any of the 17 aftermath frames. `fight_log.txt` logs `ERROR: The object does not have any 'meta' values with the key 'aftermath_standard'` at `trainer_aftermath.gd:79 begin_fall` right at the resolve boundary — this is very likely the root cause: whatever is supposed to play out here (a standard/banner-fall sequence, going by the key name) never fires, and nothing else fills in for it. Combat HUD is correctly gone, which is the only part of Q3 that passes.

**Q4 — Framing notes.** Mosshell fills 40–60% of frame in every aftermath shot and every resolve-phase shot (`r01`), consistently pushing the trainer to the edge or out of view entirely.

**Overall: FAIL.** The composition premise is real but under-demonstrated, and the aftermath is completely broken — eighteen frames of a static, half-obstructed non-event with an explicit error in the log at exactly that moment.

---

## Warden (Warden Aldis, final boss — Tuskroot HEAVY, "get clear")

**Q1 — Tactical question readable: PASS.**
`warden_aldis-t01-stand-start.jpg`: distinct, urgent "!! HEAVY — get clear" text (double exclamation, orange) — visibly different phrasing/urgency from the "! incoming — move" used for the regular chargers (Vance/Halder), which is a good design signal that this is a bigger, final-exam-tier threat. Arena is a clean circular room with sigil banners; no clutter competing with the read.

**Q2 — Tell readable, hit vs avoided distinguishable: PARTLY.**
The avoided case is excellent: `warden_aldis-t04-dodge-strike.jpg` shows explicit text "missed — too far, or facing the wrong way" with the player's creature back to full green health — unambiguous. But hit feedback is inconsistent across the three hit instances captured: `t02-dodge-strike.jpg` shows a strong "Camera STAGGERED — recovering" banner with a white flash, while `t01-stand-strike.jpg` and `t03-stand-strike.jpg` (both also logged as hits) show only the unrelated "it's open — hit it" punish-window text, with hit confirmation reduced to a small health-bar dip that's easy to miss at a glance. This may be a frame-capture timing artifact (the stagger flash being short-lived) rather than a real inconsistency, but as delivered, a player glancing at the "strike" beat cannot rely on always seeing a hit confirmed the same way.

**Q3 — Aftermath: PASS.**
`warden_aldis-a01.jpg` is the strongest aftermath shot in the whole set for actually landing the story beat: Warden Aldis fully visible and unobstructed, combat HUD completely gone, portrait dialogue reads "You won. Take the Realm Key — it opens the Storm Road beyond the village," and a glowing key icon is visible near his hand — a clear, fight-specific, objective-relevant change (unlocks the next area). Note the same `aftermath_standard` meta error appears in this log at the identical resolve point as Dell's, but here it evidently did not stop the dialogue/reward beat from firing.

**Q4 — Framing notes.** Later aftermath frames (`a15`, `99-after`) regress: once the player resumes control, their own creature drifts in front of the camera and fully re-obscures Warden Aldis for the rest of the sequence — not a problem for the victory line itself (already delivered cleanly at `a01`), but worth noting as the same creature-blocks-camera pattern seen elsewhere.

**Overall: PASS.** The final boss's climactic tell and its victory payoff both land clearly; only the mid-fight hit-feedback consistency and the late-aftermath framing are worth a second look.

---

## Ranked defect list (worst first)

1. **Vance — camera clipped inside wall geometry for the entire "successful dodge" tell** (`relay_captain-t04-dodge-start/mid/strike.jpg`), the exact moment this fight exists to teach. Same fight's aftermath opens with the camera buried in the trainer's own hair (`a01`) and never shows a victory line at all.
2. **Dell — aftermath is completely non-functional**: 17 frames of a static, half-obstructed shot with no dialogue, no token, no banner, and a logged error (`aftermath_standard` meta missing) at exactly that moment. Warden logs the identical error but its dialogue/reward still fires, which narrows this down to a real, reproducible bug rather than a one-off.
3. **Halder — the fight's central tactic never pays off in this run.** All six logged strikes resolve as hits regardless of stand/dodge policy, so "step off the lane" is never shown working for this specific Captain, undermining the one thing this fight is supposed to teach.
4. **Creature scale inconsistency across fights** — Mosshell reads as almost as large as the player's own creature in Dell's fight (`relay_officer_dell-01.jpg`) but as a small, low-threat turtle roughly a quarter that size in Oreth's fight (`captain_riverwatch-t01-stand-start.jpg`), undercutting Oreth's "WALL" read.
5. **Player's own creature repeatedly obstructs the post-victory shot** — worst in Dell (blocks Officer Dell almost entirely, every frame) and late-Warden (`a15`, `99-after`), present to a lesser degree in Vess. Only Oreth and Halder keep the trainer consistently clear.
6. **Hit-confirmation text/VFX is inconsistent between otherwise-identical "hit" outcomes** (Warden `t01`/`t03` vs `t02`) — likely a capture-timing artifact, but worth checking on real hardware since a player only gets one look at each beat.

## Per-fight overall

| Fight | Overall |
|---|---|
| Vance | FAIL |
| Halder | PARTLY |
| Oreth | PASS (WALL threat-read weak) |
| Vess | PASS (aftermath shot weak) |
| Dell | FAIL |
| Warden | PASS |
