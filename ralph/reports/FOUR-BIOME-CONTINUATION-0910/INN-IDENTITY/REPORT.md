# The Inn — focused identity evidence

## Outcome

The production Meadows inn no longer reads as a second copy of Grandpa's
House. Its street face now has a full-width green public porch, front and side
lodging signs, paired warm lanterns, guest seating, barrels, and luggage. Honey
plaster and deep-green timber further separate its facade masses while keeping
the village's shared medieval kit and roof family.

The authored doorway lane remains clear and ordinary traversal/collision is
unchanged outside the two porch posts and compact luggage prop.

## Blind visual disposition

**POLISH (identity PASS).** The exterior is unmistakably a commercial inn in
all six day/night frames, including the former house-twin angle. The remaining
commercial gap is shared scene presentation rather than building identity: the
night grade is heavily red, and the usable interior is bright and sparse for
the size of the room.

## Production captures

- `01-inn-exterior-front-day.png` / `01-inn-exterior-front-night.png`
- `02-inn-exterior-corner-day.png` / `02-inn-exterior-corner-night.png`
- `03-inn-doorway-day.png` / `03-inn-doorway-night.png`
- `04-inn-interior-bar-day.png`
- `05-inn-interior-tables-day.png`

All eight frames use `res://scenes/world/meadows_playground.tscn`; the capture
changes only camera and authored time-of-day state. The capture completed with
no missing frames. Repeated player velocity-clamp warnings came from parking
the player below the scene for fixed-camera evidence and did not affect the
world or images.

## Verification

`tests/test_inn_exterior_identity.gd`: **4 tests, 17 assertions, 0 failures**.

The checks cover public silhouette width, two readable sign faces, paired
night lanterns, occupied hospitality dressing, a clear 1.6 m doorway lane,
material differentiation from the farmhouse, and inn-only production wiring.
