# F38#0 Meadows recapture and survey audit

- Lane `tb/codex-visual-meadows`, from merged main `122682adbc2b6b37b03c1c0d13287beece3fa23e`; audit checkout HEAD `021b32eef270640c6b3176dfc6c770dc887f9d5d`.
- Existing production fixture planned 22 sites × three times × two weather states × four views = 528 frames per preset, using fixed support stands, production camera/population, no candidate toggles or creature-scale changes.
- Medium and separately admitted High each saved 354/528 (174 missing), terminated exit 1, and had no resource abort. Terminal receipts and hashes remain under `C:/CodexTemp/codex-service-catalog/`.
- Capture definition was materialized byte-for-byte from source commit, SHA256 `e18a7a004277e5b5866c241a17ad0021f9614f31abf178f67eb2a02bc04b1e14`; source tree was clean before launch.
- Prior 24-pair neutral survey sampled 353 shared IDs and remained WEAK/WEAK; Bar A/B NO. Raw High/Medium manifests have 354 frames each, 353 shared IDs, 174 missing per preset.
- Survey frame IDs match 0 of 23 nonclosed Codex-owned catalog sighting IDs. Coverage, gaps, prior review overlap, blind mapping, source hashes, and exact next requests are in `survey-id-audit.json`.
- Scope is 23 rows: 9 top-20 and 14 impact>12. Survey has no exact sighting-ID matches; direct packets and the six baseline follow-ups remain scope-limited, with all row dispositions unchanged.
- Older broad review findings are retained below in REVIEW.md; its 24-pair review was not replaced by the follow-up samples.
- Two fresh independent blind baseline reviews covered P2-005, P2-006 (mill only), P2-012, P2-013 and P2-014. Neutral sheets, full-resolution pairs, mapping and scoped observations are in this folder and REVIEW.md.
- Two further blind readers reviewed the retained 12-frame real-fight sheet (`fight-legacy-source.png`, SHA-256 `ef9ae90a0f5f5d5dcafe9c697202df31ddd2ed7633370a18c1b2a918de361ea4`): both saw overlay/HUD readability issues but did not confirm P2-062 ally occlusion or mesh clipping in the selected sample. The sheet is now preserved in this packet; its original run, manifest and frame IDs remain unverified. A source audit found v3 state-15 High/Medium frames marked non-live after a loss; their mapping to catalog sighting `warden_aldis-r15` is unverified, so that sighting remains outstanding. See FIGHT-REVIEW.md and `fight-v3-blind/REVIEW.md`. Row remains blocked.
- Three independent blind reviews completed a batch from the retained v3 Warden/Galewisp High and Medium manifests: all 14 live frames per preset, including exact P2-062 states 01/02/03/05 and P2-064 states 03/05/08. All source frames are `candidate=false`; the disputed/limited findings are in `fight-v3-blind/REVIEW.md`. This is baseline evidence, not before/after, and changes no score or status. Item-level audit found no exact South Bridge Grunt 01/02/03/05/r05 or verified Warden Aldis r15 receipt in retained manifests; no P2-062 candidate pairs exist.
- Crosswalk qualitative dispositions and next-evidence requests now reflect these six scoped reviews; numeric impacts and catalog/board statuses are unchanged.
- P2-034's existing Low close/8 m pairs received a new two-reviewer blind batch; neither side improved identity for either view. Sheet, mapping, hashes and scope limits are in `p2-034-blind/`.
- A new source-only P2-034 candidate targets only Meadows harvest order 1029: two raised navy seams echo the Basic Orb icon while retaining the original 0.38 m height. The earlier height-only attempt is not repeated. The candidate is flag-off and unrendered; no row score/status changes. Clean matched High/Medium captures and independent blind review are still required.
- P2-003's exact retained approach/detail pairs remain FAIL, Codex-owned, impact 40. Two independent source candidates are OFF: one suppresses only lighting on the measured approach-pylon line while preserving all 15 pylons, measured heights/spacing, cables and collision; the other adds one installed Quaternius training Dummy beside the approach-room WeaponStand/Sword, outside the central passage lane and Warden ring. Neither is rendered or reviewed; P2-003 remains open pending matched High/Medium candidate views and independent blind full-bar review.
- These High/Medium pairs are not before/after variants. No row score, status or acceptance criterion changed; no closure. Exact row-specific captures and candidate comparisons remain required.
- The landscape matrix excludes real fights and catch sequences; native fight/catch fixtures remain future targeted evidence. P2-087's packet stays root-owned.
- No native engine work, real-fight capture, import/render/export, CI or PR was run or dispatched in this audit.

## F38#0–#5 acceptance audit

- `#0` Frame-count floor met (354 High and 354 Medium), but 174 frames are missing per preset and 0/23 catalog sightings match; full rescore is incomplete.
- `#1/#2` Not met: open/blocked rows remain, with no complete set of main-branch fixes and code-blind PASS reviews.
- `#3` Not met: retained v3 Warden/Galewisp captures provide 14 live samples per High/Medium preset and have three blind baseline reviews; this does not establish a High/Medium matrix PASS.
- `#4` Not established here: no code-blind village-road/Crossing-Hall distance-and-close verdict.
- `#5` Not established across the matrix; three fight reviewers noted foliage, HUD/event text or attack-overlay clutter, and the remaining defect set lacks full-matrix inspection.
