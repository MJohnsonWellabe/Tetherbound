ROW: F41#8 (5.31 GPU), Stormwood named character silhouettes (Hesk, Maud, Bryn share the local_historian body)
BRANCH: tb/item-victory-card (arm files only; the overlay applies over main)
OVERLAY: ralph/reports/LANES/ITEM-F41-8-ARM/overlay_hesk_cap.json
FRAMES: the F41#8 job frames (Hesk, Maud and Bryn dialogue/post frames)

State on main: the coats are already three colours. Hesk is the base olive; Bryn
is blue-grey hue 212 and Maud violet hue 265 (lanekit_f41_8_*, ON, CPU +0.36). Each
has one accessory: Hesk a rod staff, Maud a lantern cane, Bryn an oilskin hat. So
from the head up, Hesk and Maud are the same bare-headed white-haired figure.

Arm: Hesk gains the installed wool cap and scarf (meshy-1020 npc_acc_wool_cap_scarf,
already worn by trader_fenn in another chapter), tinted copper #c9935a to match
the Stormwood copper highlights, on the Head bone at the same offset as Fenn's.
Each of the three then differs at the head (cap, bare, oilskin hat), at the hand
(rod, cane, empty) and in coat colour. Config only: no new mesh or texture, no red
or oxblood, identity kept. The list replaces Hesk's accessory list on merge, so the
rod is repeated unchanged.
