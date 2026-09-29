# F04#1 relay officers: code-blind visual judge (ccecb414 / 6090d8d1)

Inputs read (only these): `vance_ccecb414/` (all tell frames, 01-03, 05, 07-09, 22-24, a01, `RUN.txt`, `fight_log.txt`), `dell_members_6090d8d1/` (`README.md`, m1 and m2 tell frames, m1 01/04, m2 01/04, both `fight_log.txt`), `hit_avoid_relay_ccecb414c.txt`. No source, config, tests or other verdicts were read.

Criterion: "Relay officers: readable tell and distinct tactical question at the normal fight camera", plus a real hit/avoidance witness.

A cross-cutting note: in every frame of both fights the player's creature is labelled **"Camera"** in the bottom-left HUD. That looks like a fixture or debug name leaking into the player HUD. It is minor, but it is on screen.

---

## Captain Vance: Tuskroot (render 36479521318, live member 4)

**Q1: tell readable? PARTLY**
- The text "! CHARGE — step off the lane" reads cleanly in gold on the dark panel in t01-start, t01-mid, t02-start, t02-mid, t03-start, 03, 07 and 22. After the strike it switches to the cyan "it's open — hit it" (t01-strike, t03-strike, t04-strike, 05, 09).
- Ground marking: when a lane shows, it is a clear magenta rectangle running from Tuskroot out through the player's creature (t02-start, 07, and 22 partly). In t01-start/mid, t03-start and t04-start/mid, most of the lane is hidden under the player's creature, leaving only the ring and a few magenta slivers. See "contact spacing" below.
- Defect: in **t04-dodge-start and t04-dodge-mid the tell panel is washed out**. The panel background is gone and bright foliage shows through, so "CHARGE — step off the lane" is barely legible. This happens on a live tell.

**Q2: does "charge, step off the lane" read? PARTLY**
- The words and the lane together state the question clearly (t02-start and 07 are the best frames).
- The charge itself never reads as a charge. Tuskroot is already nose-to-nose with the player's creature at every tell start (t01/t02/t03/t04-start), so the "charge" plays as a head-butt at zero distance with no run-up.
- The capture never shows a successful step-off. Both dodge-policy strikes in the capture were hit (`fight_log.txt`: strike 2 dodge hit 21.9, strike 4 dodge hit 21.6). In t02-mid and t04-mid the player's creature is still on or against the lane at strike time. The only dodge miss (strike 6) happened in frames with broken framing (22/23), and a stand-still strike missed as well (strike 5 stand miss). So nothing on screen shows that stepping off the lane is what avoids the charge.

**Q3: hit vs miss on screen? PARTLY**
- A hit reads: an impact starburst and dust on the player's creature, the HP bar dropping and turning yellow (t03-strike, t04-strike), and "Camera STAGGERED — recovering" (08).
- A miss reads: the caption "it missed you" (23).
- But the only miss frame (23) has the camera buried in the player's creature, whose face fills the right half and covers Tuskroot and the moves panel. And t02-dodge-strike, a logged hit (21.9), shows no impact cue and no HP change from t02-mid. The damage only appears in 08.

**Q4: framing: FAIL**
- Camera inside geometry: in **23** the camera is effectively inside the player's creature, which renders as a dithered close-up filling half the screen and hides the opponent and the move panel. In 22 and 24 the player's creature is a dithered see-through mass across the centre. `fight_log.txt` lens probes put the camera inside `TetherRelay/Gate/GatePresentation` for frames 17, 22, 23, 24, r01 and r02, and inside HitSpark meshes for 01, 02, t01-start, 03, t01-strike and 15. A stippled dither is visible over Tuskroot in 01.
- Bystanders in the fight: a red-haired townsperson and a capped figure stand in frame on the left in 22, 23, 24 (and a01). A dark-haired armoured man stands at the right arena edge in 01, 02, 08, 09, t02-mid and t02-strike. The white-haired eye-patched figure by the banner matches Vance's dialogue portrait (a01), so it is read as the opposing trainer, not a bystander.
- **Contact spacing (separate):** the player's creature overlaps Tuskroot's head and hides most of the lane marking in t01-start/mid/strike, t02-start/mid, t03-start/strike, t04-start/mid, 02, 03, 05 and 07. This is the player's creature overlapping at contact range, and it is the main reason the lane is hard to see.

**Q5: hit/avoid log: PARTLY**
- `hit_avoid_relay_ccecb414c.txt` reports PASS for relay_captain (player_hits=9, stand_strikes_landed=4, dodges_avoided=3/4). But its opponent is **`galecrest_L12` using move `quick`**, not Tuskroot's charge. The headless witness does not exercise Vance's stated question.
- The live Tuskroot capture: player hits landed (Tuskroot's bar falls steadily from 01 to 24), and stand strikes landed (1 and 3). Only 1 of 3 dodges avoided (strike 6). A stand-still strike also missed (strike 5), so avoidance is not shown to come from stepping off the lane.

**Vance overall: FAIL.** The tell text and lane read when visible, but the frames never show the charge or a working step-off. Framing is broken (camera in the creature or gate volume in 22-24, bystanders in shot, t04 HUD washout), and the hit/avoid witness tests a different creature and move.

---

## Officer Dell: composition (m1 Burrowback run 36453075930, m2 Galecrest run 36453082333, at 6090d8d1)

Mosshell is not in this capture set. The README says earlier judges saw only Mosshell. Mosshell is judged here only through the headless log.

**Q1: tell readable? PASS (for readability alone)**
- "! incoming — move" is legible in gold under the opponent's name and bar in every tell start/mid frame for both members (m1 t01-t04, m2 t01-t03). "it's open — hit it" follows each strike.
- Marking: a magenta ring under the opponent is clear on both (m1 t01-start, t02-mid; m2 t01-start, t02-start).
- The GROUND and AIR type labels are readable.

**Q2: does each creature read as fought differently? FAIL**
- Burrowback and Galecrest use the **identical tell text ("! incoming — move") and the identical magenta ring**. Neither the text nor the ground marking tells the player to answer these two creatures differently.
- The only per-creature difference on screen is the silhouette and pose (Galecrest's spread wings), Galecrest's white wind-gust VFX (m2 t01-strike, m2 01, m2 t02-strike), and type feedback lines ("your type held — that barely landed", "STRONG — you hit a weakness"). Those describe type matchup, not a tactic.
- The shared instruction "move" never works in these captures. Every dodge-policy strike was hit: m1 strikes 2 and 4, m2 strike 2 (both `fight_log.txt` files). In m1 t02-dodge-mid the player's creature has clear ground between it and Burrowback, and t02-dodge-strike still shows an impact starburst on it with the HP bar dropping. So Burrowback's and Galecrest's questions are neither distinct nor answerable as presented.

**Q3: hit vs miss on screen? PARTLY**
- Hits read well: impact starburst on the player's creature plus dust (m1 t01-strike, t02-strike, t04-strike), the HP bar dropping into yellow and orange (m1 t04-strike), wind streaks with a starburst for Galecrest (m2 t01-strike, t02-strike), and a spark on Galecrest when the player lands a hit (m2 t03-start, where Galecrest's bar is orange and low).
- **No opponent strike missed in either Dell capture**, so the miss presentation is never witnessed for Dell's members.

**Q4: framing: FAIL**
- Bystanders in the fight:
  - A hooded humanoid stands against the player's creature's flank in m1 t01-start/mid/strike, m1 04, m2 t01-start/mid/strike, m2 t02-start/mid/strike and m2 01/04.
  - An armoured man stands on the left arena edge (m1 t01 and t02-t04).
  - A dark-clothed figure stands between the two creatures in m1 t02-mid/strike and m2 t01/t02.
  - The white-haired figure at the banner (the same model as Vance, presumably the opposing trainer) **stands inside Galecrest's ring and overlaps its wing** in m2 t02-start, t02-mid and t02-strike.
- Camera near geometry: a dark stone building fills the left 25-35% of the frame in m2 t01-t03 and m2 01/04, and m1 t02-t04. The camera is not inside it, but it takes a large slice of the fight view. The camera is not inside geometry in any Dell frame.
- **Contact spacing (separate):** the player's creature and Burrowback meet head-to-head, with Burrowback's face partly hidden, in m1 t01-start/mid, t02-start, t04-start/mid and m1 04. Galecrest keeps its distance, so there is no contact-spacing issue there.

**Q5: hit/avoid log: PARTLY**
- `hit_avoid_relay_ccecb414c.txt` reports PASS for relay_officer_dell (player_hits=14, stand_strikes_landed=4, dodges_avoided=1/4), but **only against `mosshell_L10`**. Only 1 dodge in 4 avoided (strike 2, moved 1.51). Strikes 4, 6 and 8 hit even though the player moved 0.99, 0.60 and 0.14.
- There is no headless witness for Burrowback or Galecrest. In their render captures, stand strikes landed (m1 1/3/5, m2 1/3) and player hits landed (Burrowback's and Galecrest's bars fall), but **0 of 3 dodges were avoided**.

**Dell overall: FAIL.** The tell is readable, but the composition question does not read: Burrowback and Galecrest share one generic tell and marking, moving never avoided either of them, bystanders and the trainer stand inside the fight, and the hit/avoid witness covers only Mosshell with 1 dodge in 4 avoided.

---

## Overall

**F04#1 RELAY OFFICERS: FAIL — blocking:**
1. Dell's Burrowback and Galecrest show identical "! incoming — move" tells and rings, and moving avoided 0 of 3 captured strikes. The composition question is neither distinct nor answerable on screen.
2. Vance's frames never show a charge (Tuskroot always starts at contact) or a successful step off the lane. Both captured dodges were hit, and the only dodge miss comes with a stand miss too.
3. Framing: in Vance 22-24 the camera is inside the player's creature and the gate volume. Bystanders stand in both arenas, a hooded figure presses against the player's creature, and in Dell m2 the white-haired figure clips into Galecrest. In Vance t04 the tell panel is washed out.
4. The hit/avoid witness does not cover the stated questions. Vance's headless row is Galecrest with the `quick` move, not Tuskroot's charge. Dell's is Mosshell only, with 1 dodge in 4 avoided. Burrowback and Galecrest have no headless row and no avoided dodge in capture.

Contact spacing (the player's creature overlapping the opponent at contact range) is not counted as a blocker above. It is a real, separate defect that hides Tuskroot's lane marking in most Vance tell frames and Burrowback's face in m1.

Minor: the player's creature is named "Camera" in the HUD in every frame.
