STATUS: blocked
BRANCH: tb/item-f40-12  HEAD: 94d776038937a0bb7ce5f1ffea5cb5b4732e8028 (origin/main; this branch adds only this evidence)

# F40#12 P2-076 Cloudreach dialogue speaker missing (LANE-CR, 7 Nov 2026)

Row F40#12 P2-076. Live 5.01 (GPU batch 1, 3/3 PRESENT: "only the player stands in view while the speaker is missing").

**Finding: the defect does not reproduce on current main. No lane change is needed; the row needs only its GPU re-score (High, then Medium).**

Re-captured all three scored frames on main, CPU llvmpipe, Compatibility, seed 2042:
- `phase2_capture_dialogue.gd --biome=cloudreach --subset=…trader_kelm --subset=…captain_veyra` (at 563f4a16, F40#2's branch: one OFF candidate in cloudreach_f40_items.json, which does not affect these sites)
- `phase2_capture_defeated_dialogue.gd --subset=…captain_veyra` (at 94d776038937a0bb7ce5f1ffea5cb5b4732e8028)

Manifest, every frame: `dialogue_speaker_body = near`, the speaker named, `conversation_camera_active = true`. Kelm and Captain Veyra each stand large and centred, facing the camera, with their dialogue panel (`_sheet_f40_12_current.jpg`: Kelm, Veyra, Veyra defeated).

Why it changed since the GPU score: the CAMFX speaker fixes in `tools/phase2_capture_dialogue.gd` (`_frame_speaker` moves the player beside the live body and hands it to the conversation camera; placement flags are raised per row) landed after batch 1.

Not judged on CPU: there is no candidate to A/B. The old base is gone, and a same-build pair would be flat.

Possible follow-ups, all outside this lane's files:
- The trainer's shoulder and pack intrude at lower left in every frame (the conversation camera, CAMFX).
- The panel covers the speaker's torso (`hud.json`/dialogue panel).
- Veyra stands on a bare cobble arena under Team Tether banners (on story).

Flags: none touched. Tests: none. Files: this READY and one sheet (181 KB).
