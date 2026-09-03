# T1-NPC-CAST — preview round 1, all 24 board designs

Owner directive, live in-session: use the Meshy key the coordinator handed
over (see the notification quoted in this lane's session — key received
via a scheduled-trigger notification, cross-checked against the live
`/openapi/v1/balance` endpoint before being trusted, and the owner
separately confirmed "yes use the key" directly in conversation before it
was used). Never written to a file, commit, manifest or prompt block —
`export`ed into the shell environment only, per `meshy.py`'s own stated
rule.

## What changed since the plan doc

The 24 `board_panel_source.png` crops committed earlier were **not** in a
format `meshy.py generate` can actually use — `reference_views()`
(`tools/art_pipeline/meshy.py:1099`) requires individually named
`front.png`/`side.png`/`back.png`/`three_quarter.png`/`head.png` files, at
least 2 and (per the coordinator's own hard-won lesson from the creature
batch) **at most 4** — the real API limit, undocumented in `views.json`,
that silently 400s past it with zero credit cost if exceeded. Split all 24
board panels into named per-view crops before running anything:

- **Team Tether grunts/officers** (5 subjects): `front` / `three_quarter` /
  `back` / `head`, proportional thirds of each panel's 3-figure row plus
  the head bust.
- **Team Tether captains** (2 subjects): `front` / `side` / `back` /
  `head` — the panel actually draws 5 poses (front/3-4/side/back/head);
  dropped `three_quarter` to stay at 4 images, keeping the two clearest
  angle changes instead.
- **Village/Trail** (17 subjects): `front` / `side` (or `three_quarter` for
  one), matching each panel's actual 2-figure layout.
- **`traveling_merchant` specifically**: the board draws only ONE pose of
  her (beside the cart), not two — there is no second angle to crop. Cropped
  a person-only `front.png` (excluding the cart as much as the pose
  allows) and a tighter bust-up `three_quarter.png` of the same single
  pose as the second required image, since `reference_views()` refuses
  fewer than 2. Flagged here because it is not a real second angle and the
  quality shortfall shows in the results below.

Verified every subject has 2–4 named views before spending anything
(`ls .../reference/ | grep -v board_panel_source | wc -l` for all 24 —
5 Team Tether grunt/officer subjects at 4, 2 captains at 4, 17 village/trail
at 2).

## Preview run — clean, no silent failures

24 subjects × 3 candidates × 20 credits = **1,440 credits**, run in three
batches (Team Tether, Village, Trail), balance checked before and after
every batch:

| Batch | Before | After | Spent |
|---|---|---|---|
| Team Tether (7) | 2,880 | 2,460 | 420 (7×60) |
| Village (9) | 2,460 | 1,920 | 540 (9×60) |
| Trail (8) | 1,920 | 1,440 | 480 (8×60) |
| **Total** | **2,880** | **1,440** | **1,440** |

Every one of 72 `generate` calls printed real candidate task ids (checked
by eye, batch by batch, watching for the coordinator's silent-400
signature — a call that prints a header and no ids). All 72 candidates
fetched afterward via a parallel poll (`concurrent.futures`, 12 workers):
**72/72 SUCCEEDED, 0 failed.** Thumbnails composited into three labelled
contact sheets (`shots/npc_cast_preview_team_tether.png`,
`_village.png`, `_trail.png` — gitignored render evidence, sent directly
to the owner, not committed, same convention as `shots/rank_variety/`
earlier in this lane).

**Balance now: 1,440.** Comfortably above the 900 reserved for
T1-CREATURE-MESH, per the coordinator's hard instruction to leave that
untouched. **Stopped here without spending on refine or texture**, per
the coordinator's explicit "report before any refine or texture spend."

## Verdict, per subject — honest, with the failures named

**Team Tether (7/7 usable) — this is the actual fix.** All three ranks now
generate with visibly different silhouettes: officers get longer coats and
layered command pieces than a grunt, captains get a full-length flowing
cape reaching past the knees. This is the exact gap
`tools/_capture_rank_variety.gd`'s render proved earlier in this lane —
distinguishable at a glance now, not just by chest-badge colour. One minor
drift: `grunt_c` came back in shorts and a leaner build rather than
matching the other grunts' trousers — still usable, not re-rolled.

**Village (7/9 clean, 1 real failure, 1 minor).** Innkeeper, Inn Helper,
Trader, Craftsperson, Creature Caretaker, Local Historian and Young
Trainer are all clean, distinct, on-brief. Minor: Farmer's candidates
generated holding the pitchfork as part of the mesh despite the prompt
saying it's a separate accessory — acceptable, a held prop is easy to
separate later or just keep. **`traveling_merchant` failed outright**: all
three candidates fused the cart into her body geometry (one candidate
reads closer to a wheelchair than a hand-cart). Root cause: the reference
crop still shows cart at her hip even cropped tight, and per the
coordinator's own lesson from the creature batch, **image content beats
prompt text** — "no cart geometry" in the prompt did not overcome a cart
visible in the reference image. Needs a genuinely person-only reference
(re-crop with the cart fully excluded, accepting a worse pose if
necessary, or drop image-to-3D for this one subject and try text-to-3D
instead) before spending anything further on it.

**Trail (7/8 clean, 1 partial).** Rival Trainer, Field Researcher, Lost
Traveler, Campfire Traveler, Alpha Tracker, Courier and Former Tether
Member are all clean. **`wandering_trainer` candidate A** picked up a
companion creature fused onto his back — same image-over-text failure
mode, since the board panel draws a companion creature beside him and the
prompt's "generate the human alone... not part of this generation" didn't
override it. Candidates B and C are clean and usable without a re-roll, so
this one does NOT need to be re-spent on, just don't pick candidate A.

**Net: 22 of 24 subjects have at least one clean, on-brief candidate ready
to refine. 1 (`traveling_merchant`) needs a fixed reference crop and a
re-roll before it's worth refining. 1 (`wandering_trainer`) is fine as-is
if candidate B or C is picked.**

## Stopped here, as instructed

No refine or texture spend has happened. Waiting on a go-ahead (owner or
coordinator) before picking winners and spending the next tier — refine is
40 credits/candidate, texture 30; even refining only the 22-23 clean
subjects at one candidate each is ~900-920 credits, which would leave the
900 creature reserve exactly at its floor or slightly under, so that
decision point deserves an explicit answer rather than being made
unilaterally by this lane.

## File footprint, this round

- **Added:** 62 per-view reference crop files under
  `assets/creatures/tetherbound/<slug>/reference/{front,side,back,
  three_quarter,head}.png` for the 24 subjects (counts vary 2–4 per
  subject, per the layout notes above).
- **Added:** this report.
- **Not committed (gitignored, by design):** `assets_raw/<slug>/` (72
  manifests + fetched thumbnails/models — raw generator output), `shots/
  npc_cast_preview_*.png` (render evidence, sent to the owner directly).
- **Not touched:** anything past preview tier — no refine, no texture, no
  rig, no animation, no installed `assets/characters/**` model, no
  `data/config/art.json` wiring. All of that is still ahead of this branch.
