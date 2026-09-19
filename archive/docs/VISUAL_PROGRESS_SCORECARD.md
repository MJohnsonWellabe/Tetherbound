# Visual progress scorecard

Updated 2026-09-09, resumed four-biome build. This measures reviewed visual
acceptance, not the amount of code or art already produced.

**Full biome visual passes: 0 of 4.** This is not a claim that the project is
0% complete. There is no stable, equally weighted checklist from which to
calculate an honest overall visual completion percentage yet. Track the
specific passes and remaining defects below instead.

Status meanings: **Passed** meets the named narrow criterion; **Partial** has a
verified improvement with open defects; **Needs work** has not met the full
review bar; **Held** means the tested change is not being applied; **Active**
means attribution or repair is underway, with no acceptance credit yet.

## By biome

| Biome / latest sampled location | Full visual status | Verified progress | Remaining gap / next work |
|---|---|---|---|
| Meadows / Ridgeline Watch | Needs work | Shared terrain filtering correction landed and exposes actual mip levels | Latest matched scene review shows no clear overall ground improvement; character separation and broader scene quality remain open |
| Cloudreach / Windscar Beacon | Needs work | Shared terrain filtering correction landed | Latest matched view shows no clear visual gain; held landmark geometry receives no shipping credit |
| Stormwood / Glowmoss Hollows | Partial; full bar not passed | Smoother distant ground in the neutral comparison | Character presentation, separation, lighting and composition remain open |
| Water / Gull Rest Signal Spire | Partial; full bar not passed | Cleaner distant shoreline/ground appearance | Foreground texture stretching is more conspicuous; held landmark geometry and creature quality remain unaccepted |

These are representative recent comparisons, not a claim that every location in
each biome was re-audited after the filtering change. All four sampled scene
reviews answered No to both reference questions. Evidence: complete
[sets A–D and their mapping](../ralph/reports/FOUR-BIOME-BUILD/SHARED-TERRAIN-REVIEW-DISPOSITION-0909.md).

## By category

| Category | Status | What is established | What remains |
|---|---|---|---|
| Terrain texture filtering | Passed, narrow technical criterion | Twelve shared textures expose ten mip levels on Windows and Linux; correction landed in PR107 | This does not certify terrain composition, all surface materials or temporal stability |
| Distant ground / shoreline appearance | Partial | Visible local improvement in Stormwood and Water | Meadows and Cloudreach have no clear improvement in the matched views; full biome bars remain open |
| Creature surface and facial hierarchy | Held / needs work | Valid162-image experiment,20 isolated species, four fresh neutral reviews | Broad mipmap candidate loses contrast in some face regions;32 import changes are held; anatomical paint attribution is needed |
| Creature animation ground contact | Held / needs work | Torrentoad's low attack pose has4965 textured vertices below the floor; rest has none | Bounded CPU correction failed clearance; third production round has not begun |
| Torrentoad face / eyes | Held / needs work | Shared color thresholds are insufficient; source atlas and pose geometry are available | Visible eye/brow atlas regions remain unproved; no paint selector accepted |
| Night lighting / readability | Held | Matched trial helped Meadows visibility | Stormwood lost depth; original global contrast1.08 remains in place |
| Character identity / accessories | Needs work / explicit deferrals | Arlo's generic identity is accepted for now; Warden staff candidate was reviewed | The held staff did not establish a convincing grip/material result; no broad character-quality pass is claimed |
| Landmarks and scene composition | Needs work | Latest terrain comparisons keep geometry constant to isolate filtering | Held Windscar/Gull Rest geometry is excluded from shipped visual credit; existing wider scene gaps remain |

Creature verdicts are intentionally nuanced: Cloudreach and Water isolated
cohorts received a literal genre-resemblance Yes, but still a key-art No. The
fixed five-creature lineup and Stormwood cohort did not pass either reference
question. A genre resemblance answer is not a finished-art pass.

Evidence:

- [Creature experiment disposition and full neutral verdicts](../ralph/reports/FOUR-BIOME-BUILD/CREATURE-MIPMAP-DISPOSITION-0909.md)
- [Torrentoad face/contact attribution](../ralph/reports/FOUR-BIOME-BUILD/TORRENTOAD-FACE-CONTACT-ATTRIBUTION-0909.md)
- [Night-lighting trial](../ralph/reports/FOUR-BIOME-BUILD/SHARED-NIGHT-GRADE-RESUME-0909.md)
- [Explicit identity and other deferrals](SECOND_PASS_BACKLOG.md)

## Current order

1. Preserve the failed Torrentoad CPU proposal and move to another visual defect.
   Resume this subject only with a materially different, bounded authoring plan
   addressing both face attribution and contact; this is not a proven rig ceiling.
2. Keep the held global filtering/night experiments closed rather than repeat
   the same settings to chase a pass.
3. Update each row only when its new native capture and independent review
   support a changed status. Keep playable-path testing running alongside art.
