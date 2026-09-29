# F04#6 "distinct aftermath" (Meadows named fights): pass bar for the closing judge round

Written before any frame is rendered. It does not change after frames exist. Give it to the judges unchanged, before the frames. It restates and tightens `ralph/reports/MEADOWS/f04/final_F04_6/BAR.md` (the Meadows lane's bar, same command). If the two disagree, this file governs the CLOSER round and the difference is listed in "Ambiguities".

## What F04#6 requires
- ACCEPTANCE §6.1 F04: the Warrens guardian, relay officers, three captains and Warden each have "a distinct aftermath".
- Dashboard row F04 criterion "Distinct aftermath per fight": status partial. Evidence so far is only the profile test asserting each fight sets a defeat/reward flag. Gap: "Visible, distinct aftermath judged".
- Round 5 (`ralph/reports/MEADOWS/f04/JUDGE_F04_6_aftermath_r5.md`) FAILED. Blocking defects:
  - Dell: step-aside never seen; the companion creature filled the frame after the lines.
  - Vance: banner already translucent in the first frame, gone by the third; nothing else changes; same model and portrait as Halder.
  - Vess: banner strike imperceptible; sigil low contrast, close to Oreth's blue.
  - Non-blocking then: sigil disc overlaps the hip; no token moves toward the player; the Warden's heart and key float forever.
- The fixes were on PR #437, closed as superseded. #442 (`bf67c3e0`) merged them (occluders, bystander step-aside, victory shot, strike when the lines are seen, stand-down on the last line, single hand-over). They have not been re-judged. Main is now at or after `71f2ca35`.
- Spec text is thin. BOSSES §4.2 to §4.5 only says each captain awards a Sigil, Vance's defeat frees the captive and disables the relay, and the Warden hands over the Heart and Realm Key. The visible-aftermath beats (standard struck, stand-down, hand-over) come from `scripts/world/trainer_aftermath.gd` and the r5 judge's terms.
- Out of scope: the Warrens guardian's vault door (judged with F04#0), and Keeper Hald (no aftermath row in ACCEPTANCE F04; see Ambiguities). Look-dev polish (token art, portrait reuse) goes to Phase 2.

## Frames to capture
One folder per fight. Each has 12 in-aftermath frames `<id>-a01` to `<id>-a12` plus `<id>-99-after`, plus the in-fight frames (`--frames=4`, judge ignores them). The judge sees only `a01`-`a12`, `99-after` and `RUN.txt`. Lines frames are those with the dialogue box on screen. Resume frames are those after it closes.

| Fight | trainer id | Aftermath expected |
|---|---|---|
| Captain Oreth | `captain_riverwatch` | Sigil 1 |
| Captain Halder | `captain_field` | Sigil 2 |
| Captain Vess | `captain_ridge` | Sigil 3 |
| Captain Vance (relay) | `relay_captain` | Freed captive, relay disabled, standard struck |
| Officer Dell (relay) | `relay_officer_dell` | Stand-down from the post |
| Warden Aldis | `warden_aldis` | Heart of Meadows and Realm Key |

## Per-frame fail clauses (lines frames)
- **L1:** camera inside or behind geometry, including the player's creature as a see-through close-up.
- **L2:** the speaker's head is covered by the player's creature, another person, scenery or a token.
- **L3:** combat HUD on screen (creature bars, move buttons, target reticles).
A fight fails framing if more than 2 of its lines frames hit L1-L3.

## Resume-frame rule
At least 2 of the resume frames (`a0N` after the box closes, plus `99-after`) must show the trainer on screen with no more than 25% of the trainer's silhouette covered by the player's creature. Any fight where the trainer is absent or hidden in every resume frame fails, unless the beat for that fight is by design an exit (none is).

## Per-fight required beat
Each beat must be visible without reading the dialogue text.

| Fight | Required and visible | Fails if |
|---|---|---|
| Oreth, Halder, Vess | 1. Their own Sigil disc, with its own emblem, on screen during the lines. 2. The oxblood Team Tether standard is clearly up in the first lines frame and visibly fading or gone in a later one. 3. Either the Sigil moves toward the player (at least two frames, closer or shrinking into them) or the captain steps away or turns. | Any of 1-3 missing, or the standard is already translucent/gone in the first lines frame, or a judge needs an enlarged crop to see it. |
| Vance | 1. Standard seen up, then struck, during the lines. 2. Steps aside or turns in at least one frame where he is on screen. 3. He is distinguishable from Halder in a single frame without the dialogue text and without the setting (portrait, model or a staged element differs). | Any missing, or his only change is a banner already faint in the first frame. |
| Dell | Steps aside or turns away in at least one frame where he is on screen and unobstructed. | Dell is not visible in any frame after stand-down begins, or is covered by the creature in all of them. |
| Warden | Heart and Realm Key on screen during the lines, and they move toward the player or leave by the end of the resume frames. | Either is missing, or both float unchanged in `99-after`. |

## Distinctness across the six
The judge sorts the six aftermaths from frames alone. A pair fails if indistinguishable apart from text. Setting alone does not separate a pair that shares token, beat and trainer model; at least one staged element must differ (token, emblem colour with different emblem, movement, prop). Two sigils whose emblems differ but whose colours are close (Vess vs Oreth) are non-blocking; two sigils with the same emblem are blocking.

## Two-judge protocol
- Two independent judges, fresh contexts, neither has seen source, tests, config or any earlier report (including r5 and this file's Sources section). Each gets only: this file from "Per-frame fail clauses" downward (no "What F04#6 requires" section, so no hint of the earlier failures), the six folders' frames and `RUN.txt`, and the trainer id to display name map.
- Prompt to give each judge (verbatim): "You are shown six folders of stills. Each is the moment after a trainer is beaten in a creature game: the trainer's lines, then the game resuming. Frames a01 to a12 are in order; 99-after is the last. Using only the frames and the rubric below, answer per folder: (1) lines frames hit by L1, L2, L3 (list frame ids); (2) the required beat, quoting the frame ids where each element is visible, or say it is not visible; (3) resume-frame rule; (4) PASS, PARTLY or FAIL. Then sort the six aftermaths and name any pair you cannot tell apart without the text. Do not guess at things you cannot see; say 'not visible'. Do not read anything except these frames and the rubric."
- Cite frame ids for every claim. A verdict without frame ids for its beat is void and re-asked once.
- Both judges look at each frame at full 1280x720. Enlarged crops are allowed but a beat that appears only in a crop counts as not visible (the standard clause above).

## Thresholds
- **PASS (criterion met):** both judges give PASS on all six fights, no pair fails distinctness in either judge's sort.
- **FAIL:** any fight is FAIL from either judge, or PARTLY from both judges.
- **Split** (one PARTLY, other PASS for a fight, everything else clean): not a pass. Record the frame-level disagreement, do one strict re-check of that fight only by a third fresh judge; that judge's verdict decides that fight. One split re-check per fight, no more.
- **Non-blocking (reported, not failing):** sigil disc overlapping the body without covering the head; close token colours with different emblems; reused portrait/model (except the Vance clause above); stills can't show motion smoothness; Warden icons lingering if they moved or shrank by the end.
- A failing round records the exact per-fight defects in STATE and stops; do not re-render with a changed bar. Fix, then a new round is a new decision.

## Dispatch (render.yml, workflow_dispatch; do not run from this file, the lane that closes the criterion runs it)
Precondition: main contains #442 (it does: `bf67c3e0`). Use the current main SHA as `checkout_ref` (a SHA, not `main`, so the evidence names its commit). Harness options are DISCLOSED shortcuts: `--keep-alive` tops up the fixture creature; `--resolve=won` ends each fight through combat_manager's own resolve; the player does not steer.

Recommended, one job (the script shares one world boot, about 15 min under software GL, plus under 2 min per fight, so about 30 to 45 min wall clock; timeout gives headroom):
- checkout_ref: `<main SHA>`
- script: `tools/art_pipeline/capture_named_fight.gd`
- args: `--trainer=captain_riverwatch,captain_field,captain_ridge,relay_captain,relay_officer_dell,warden_aldis --out=res://shots/f04_6/closer --frames=4 --keep-alive --resolve=won --after-frames=16`
- mode: `render`
- resolution: `1280x720`
- timeout_minutes: `120`
- label: `f04-6-closer`

Frames land at `shots/f04_6/closer/<id>-aNN.png` and `<id>-99-after.png`, in artifact `render-f04-6-closer-<run_id>`. Note the prior render.yml collects shots/ into the artifact; convert to jpg as r5 did if the judges want smaller files.

Fallback if the single job hits a fault mid-list (the harness returns failure count but earlier trainers' frames are already saved): re-dispatch only the missing ids, same args with `--trainer=<ids>` and `--out=res://shots/f04_6/closer_b`, label `f04-6-closer-b`. At most 2 render jobs at a time (coordinator rule); r5 ran six one-trainer jobs, each one world boot, so six jobs would be about 6 x 20 min, two at a time about 60 min.

## Ambiguities and the conservative reading
1. **Harness camera.** `--face-trainer` exists (turns the rig toward the beaten trainer for aftermath frames) and the Meadows BAR command omits it. Its purpose is exactly the Dell defect (creature filling the frame). Conservative reading: do NOT add it, because the game's own post-fight camera and step-aside are what F04#6 is judging, and adding it could hide a real occlusion. If the fixed round fails only on creature occlusion, report that and let the owner decide whether the harness flag is a fair aid.
2. **What "distinct" means.** Neither ACCEPTANCE nor BOSSES defines it. Conservative reading: each fight has its own visible staged element and no pair is indistinguishable without text (as r5 judged), not merely a different flag or different text.
3. **Sigil hand-over motion.** BOSSES does not require the token to travel to the player; r5 lists non-movement as non-blocking, the Meadows BAR requires movement or a step-away. Conservative reading: keep the stricter clause 3 (movement or step-away) for captains.
4. **Which fights count.** ACCEPTANCE names guardian, relay officers, three captains, Warden. Keeper Hald and the Warrens guardian are not aftermath-judged here; guardian is out of scope per the Meadows BAR. If the owner reads "each named fight" as including Hald, add `keeper_hald` (id unverified; check `TRAINERS.trainer` ids first) to the trainer list and the table with the Warden's non-token rule replaced by "visible change or stand-down".
5. **"Relay officers" plural.** Dell is the only relay officer id captured in r5; Vance is the relay captain. Conservative reading: the two above cover the relay. If the data has more relay officers (check `data/config` trainers), they must be added.
6. **Standard (banner) visible at time of lines.** The tool's strike starts when the lines are seen (`strike_seconds` config, default 1.6 s), so frame a01 can already be mid-fade at 16-frame cadence. Conservative reading: a01 must still show the standard up (mostly opaque); if the harness cadence makes that impossible, it is a capture defect, not a game pass, and is reported, not waived.
7. **No ready-made contact sheet tool named** in the Meadows evidence; judges look at the frames directly.

## Blockers
None found. The capture tool exists on main and this branch (`tools/art_pipeline/capture_named_fight.gd`), and render.yml validation accepts the args. Unverified: the exact runtime of this command on a runner (no run timing is recorded in RUN.txt or the reports; the estimate is from the script's own comment).
