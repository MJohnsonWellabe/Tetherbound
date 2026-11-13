# THINGS-TELLDUST: the "bead strings" are the wind-up dust; make it a soft low band

**Correction to THINGS-DUSTTRAIL.** I filed DUSTTRAIL on the reading that the "strings of pale dotted beads" (F38#3, 3/3) and the "ring of white puffs over Terrapup" (F38#28, 3/3 at Medium) were the stone moves' trail ribbon. Looking again, I now think that is wrong:
- every GPU frame that shows the beads also shows the HUD's "! incoming — move" line, which is the opponent's wind-up, before anything is thrown;
- `combat.json telegraph.soft_style` draws a wind-up as "dust kicked up along the tell outline": separate puffs 0.42 m across, one every 0.34 m, at 0.6 alpha, along the attack's ring, lane or pattern shape. Puffs smaller than their spacing along a curved outline are exactly a looping string of beads.

So DUSTTRAIL probably changes nothing in those frames (it may still thin the trail behind a thrown stone). The GPU lane's by-eye check on DUSTTRAIL will settle it: if the beads are unchanged there, this arm is the one that matters.

**Owner rule this sits under.** Owner, 24 Oct: "I don't like how the fights outline the area of the attack." The painted outlines stay off; this arm only changes how the dust that replaced them looks.

**Change** (overlay only, five values in `telegraph.soft_style`): puff size 0.42 to 0.8 m, spacing 0.34 to 0.3 m, alpha 0.6 to 0.32, rise 0.16 to 0.06 m, colour `#9c8763` to a darker earth `#8a7654`. The puffs now overlap into one soft, low, dim band of dust along the same outline, sitting on the ground, in place of bright separate dots hanging in front of the creatures. Hit geometry, timing and the tell's length are unchanged.

**Not shown on CPU.** My CPU fight captures (Low, Compatibility) include tell frames (`t01-stand-mid` and so on) and none of them shows any wind-up dust, on main or otherwise, so I cannot show before and after. `_sheet_gpu_main_beads.jpg` is main at High.

**Risk.** A dimmer, lower band is a weaker danger cue. The HUD line and the attacker's own wind-up glow still announce it. If judges or play find it too quiet, alpha is the first value to raise.

**Ask.** By-eye check first on the frame with "! incoming — move": the beads should be one soft band on the ground. Then judge F38#3 and the Warden set, base vs arm.
