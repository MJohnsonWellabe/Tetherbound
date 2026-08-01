# D28. The target is a PC handheld, not a phone

Kind: conflict

`CLAUDE.md` constraint 8 read "Mobile is the primary target. Test at 390x844
first." Overridden by the owner: the game is played on a ROG Ally from the
GitHub Pages URL, so the reference device is 1080p, 120Hz, gamepad plus
touchscreen, and the test viewport is 1280x720.

Touch is NOT dropped. It works, it costs one mounted listener set, and deleting
working input support to make a document self-consistent is vandalism. What
changes is that touch no longer gets a vote on the frame budget, the view
distance or the UI layout, all of which were being held down to suit a
mid-range phone.

`ARCHITECTURE.md`'s frame budget moved from 16ms to 8ms as a consequence. A
120Hz panel has 8.3ms per frame, and M2 still has to fit pals, orbs and
particles into whatever is left.
