# Riverwatch duel foreground plant (11:00 AM CT Tue 13 Oct)

Defect (coordinator, from tb/ev-systems 90e50523 F42-2/r5 duel sheet frames 02, 04): a bush between the combat camera and Captain Oreth's duel filled the lower left.
Fix: tb/ev-visual 1ed1d631, combat.json camera.occluder_clear_margin 2 -> 10 m (the fight camera sits 9.5 m behind the ally; soft occluders on the camera side now stand aside with the rest of the ring, F10#2 decision). Presentation only.
Re-shot: tools/art_pipeline/capture_named_fight.gd --trainer=captain_riverwatch --frames=8 --interval=0.75 (Compatibility 1280x720) on tb/ev-visual 307748fbd; _sheet.png = the pre-fight frame plus seven in-fight frames. No foreground plant over the duel in any in-fight frame.
