# D32. Mouse look has a no-pointer-lock fallback

Kind: implementation

Reported by the owner as "on pc I don't know how to look around but I can
move". Pointer lock was requested on the first canvas click and nothing on
screen said so, which makes a working camera indistinguishable from a broken
one.

Two fixes, because discoverability and robustness are different problems. A
control prompt now sits at the bottom of the screen and says how to look
whenever mouse look is not engaged, and holding right mouse looks around
without requiring a lock at all, for the setups that refuse or lose it.

The general lesson: a control scheme the player has to guess is a broken
control scheme, and "works once you know the trick" is not working.
