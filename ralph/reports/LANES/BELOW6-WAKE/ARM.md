# BELOW6-WAKE: the wake foam without its pinwheel (F39#5 5.98, F39#14 6.12)

**Flag:** `data/config/human_water_contact_visual.json soft_churn_1112` (OFF; overlay turns it on).
**Code:** `shaders/human_water_contact.gdshader` (`soft_churn`, 0 keeps today's look), `scripts/player/human_water_contact_view.gd _set_ring`. Test: `tests/test_wake_soft_churn_flag.gd`.

**Why:** after the swim pose shipped, the judges' next remainder on both rows (3/3) is "a radial pinwheel seam at the centre of the wake foam in surface_west". It is visible in the GPU base frames too (tb/gpu-frames-1108 `G-below6-swim-r4/`, the spoked discs behind the swimmer).

**Cause:** the churn inside the foam lip is masked by `broken_foam`, a function of angle only, so its gaps are spokes that meet at the centre of each wake disc.

**What the arm does:** with `soft_churn 1`, the churn is masked by a patch pattern in the disc's plane and fades out over the inner third of the radius. The lip keeps its angular breakup, which does not reach the centre. Applies to the contact ring and every trail ring, local and remote.

**CPU:** the swim capture ran clean (0 script or shader errors), but the CPU water is pale and the foam barely shows on either side, so I cannot show the difference there. This arm needs the GPU pre-check as its first look.
