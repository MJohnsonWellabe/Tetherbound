# F08#3 settlements and cliff identity: re-capture and code-blind judge (3:55 AM CT Tue 13 Oct)

Capture: tb/ev-visual 7ef9e430, tools/capture_cloudreach_settlement_identity.gd --preset=Low (Compatibility, 1280x720), five existing stands (Cliffhold approach/court/windwatch, Galefoot approach/hearth), day and night; sheet _sheet-r5.png. One fresh code-blind judge, frames and docs/reference only.

**Verdict: FAIL** (Cliffhold FAIL, Galefoot WEAK). Holds for the F39/F40 catalog pass (Codex cloudreach); this lane stops here.
- Cliffhold night: no warm source at the approach (frame 2), one faint window at court/windwatch; fire ring unlit.
- Signs of life: two tiny distant NPCs; the approach frames the settlement as a horizon speck.
- Cliffs/spires: flat, near-untextured beige/white surfaces; read as mesa or glacier, not high cliff; spires self-lit blue at night.
- Stray geometry: leaning poles crossing roofs, unanchored ropes (one through the follower's talons), a bead line hanging from a sky dot (Galefoot hearth), a floating doormat slab, a hard-edged dark grass square, a leaf card clipping the camera.
- Oxblood risk: dark-red tower banner with white emblem at both settlements.
- Galefoot hearth: elder NPC sunk into the shrine blocks; shrine stone self-lit at night.
- Shared kit: same cottage and tower at both settlements; identity comes from backdrop only.
- Galefoot night is acceptable (several warm windows, fire, lit tent).
- Cliff-identity matrix (capture_cloudreach_frame_matrix.gd) not re-shot: the settlement half already fails the criterion.
- Disclosed: the judge reported no HUD visible in these frames (the tool's capture path).

## r6 (5:56 AM CT Tue 13 Oct): tb/ev-visual 55f7b31b (settlement banner palette, Cliffhold door lanterns, eave-anchored tar guy ropes, cliff rock 2x frequency + deeper normal), same capture, fresh code-blind judge
**Verdict: FAIL** (Cliffhold FAIL, Galefoot WEAK). Fixed: no oxblood on either village (banners now blue). Galefoot night believable (lit windows, lit tent). Still: Cliffhold windows dark at night (only a ground glow from the new lanterns); guy ropes still read as short leaning sticks; Galefoot's lantern line hung from the sky (fixed after this capture in 3f9a8fec: two timber posts; not yet re-judged); white spires and cliff faces still read flat; terrain patch seam at windwatch; same cottage/tower kit at both settlements. Judge prompt wording ("stands") was read as market stalls; that part of its verdict is disregarded.

## Scored (owner 10-point rule, 7:09 AM CT Tue 13 Oct): r5 vs r6, 10 paired frames shuffled, one code-blind judge (its version guesses matched the withheld key)
**r5 5.1 → r6 5.6 /10** (done at 8.5). Gain is the oxblood banner and stray poles. Remaining: Galefoot bead line (posts added in 3f9a8fec, not in this capture); icy distant spires; Cliffhold lacks cliff-edge identity; night lit mostly by blue moonlight. r7 (3d4e1e70b: limestone spires with relief, warm window glow) capturing.
- r7 scored 7:31 AM CT Tue 13 Oct (3d4e1e70b vs r6, shuffled pairs): **5.4 vs 5.4, no gain** — rows 1-8 pixel-identical below the sky (spire colour hidden by fog; window glow blended away by the glass alpha); only the lantern-line posts changed (anchored, but a bare pole now splits the plaza). Spire-colour approach stopped. r8 (opaque warm night panes, lantern line at eave height) next; judge's top asks: real rock + a cliff edge behind Cliffhold (+0.8-1.0), warm light as the night read (+0.7), remove stray lines (+0.5).
