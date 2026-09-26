# VERDICT: attack poses (§5.1) and cast faces (§5.2)

Code-blind review of `attack/` (57 species, front idle vs side attack at 45 %) and `faces/` (41 humanoids).

## A) Attack-pose expression

Classes: **CLEAR** = the pose reads as an attack (lunge, head-down charge, pounce, open jaws, raised talons). **WEAK** = the pose changed but barely reads as an attack. **NONE** = no readable attack. Two kinds of frame land in NONE: frames that look like idle, and frames where the body has collapsed or broken so badly that it reads as a heap, not an attack.

Counts: **CLEAR 40, WEAK 11, NONE 6.** Geometry flags: **21 MAJOR, 20 MINOR** (the flags overlap all three classes).

The most common defect is systemic. The head-down "charge" pose drives the head and forelegs of most quadrupeds through the stage floor, so the face disappears and the forelegs are cut off at the ground plane.

| Species | Class | Geometry flag | Frame | Reason |
|---|---|---|---|---|
| terrapup | CLEAR | MINOR | 003_terrapup_attack.png | Head lowered into a charge crouch; front paws read as stumps sunk into the floor |
| ripplet | WEAK | – | 006_ripplet_attack.png | Paws drawn to the chest and a slight lean back; no lunge or open jaw |
| galewisp | NONE | MINOR | 009_galewisp_attack.png | Upright, wings folded, reads as an idle profile; feet mostly hidden under the chest fluff |
| bramblebun | CLEAR | – | 012_bramblebun_attack.png | Low crouch with antlers thrust forward |
| mudsnout | CLEAR | MINOR | 015_mudsnout_attack.png | Head-down charge; snout and tusk tips at or under the floor |
| trailpup | CLEAR | MINOR | 018_trailpup_attack.png | Play-bow lunge; forelegs lie flat along the floor |
| burrowback | CLEAR | MAJOR | 021_burrowback_attack.png | Head-down dive; snout and forelegs sunk through the floor, face half-buried |
| meadowhart | CLEAR | MAJOR | 024_meadowhart_attack.png | Broken rig: forelegs missing, detached hoof fragment on the floor, neck and barrel seams split apart |
| tuskroot | CLEAR | MAJOR | 027_tuskroot_attack.png | Head-down charge; face and forelegs through the floor, only the tusk tip shows |
| paddlenewt | CLEAR | – | 030_paddlenewt_attack.png | Low forward crouch, head extended |
| mosshell | WEAK | MAJOR | 033_mosshell_attack.png | Shell tips forward with the head fully hidden; front of the shell sinks into the floor; face unreadable |
| brooktail | WEAK | – | 036_brooktail_attack.png | Hunched with paws at the mouth; reads as eating, not striking |
| galecrest | CLEAR | MINOR | 039_galecrest_attack.png | Airborne, talons forward, wings up; lower wing and tail feathers smear through the legs |
| duskhush | CLEAR | MINOR | 042_duskhush_attack.png | Low lunge with talons forward; tail feathers stretched and smeared |
| pipwing | WEAK | – | 045_pipwing_attack.png | Slight forward lean only |
| reedwing | WEAK | – | 048_reedwing_attack.png | Squat with the neck pulled back; a possible wind-up, but barely distinct from idle |
| veridian | CLEAR | MAJOR | 051_veridian_attack.png | Head-lowered charge; chest drops to the floor, forelegs vanish, one antler curl looks detached |
| nightburrow | CLEAR | MAJOR | 054_nightburrow_attack.png | Head-down dive; face and forelegs buried in the floor |
| stormtrail | CLEAR | – | 057_stormtrail_attack.png | Clean crouch-lunge |
| riftfrill | CLEAR | – | 060_riftfrill_attack.png | Low forward crouch, head extended |
| ashtusk | CLEAR | MAJOR | 063_ashtusk_attack.png | Same as tuskroot: face and forelegs through the floor |
| sparkit | CLEAR | MINOR | 066_sparkit_attack.png | Flat pounce; chin on or into the floor |
| cindercub | CLEAR | MINOR | 069_cindercub_attack.png | Head-down pounce; chin into the floor |
| shadelet | CLEAR | MINOR | 072_shadelet_attack.png | Flat lunge; head pressed into the floor, eye at floor level |
| frostclaw | CLEAR | MINOR | 075_frostclaw_attack.png | Stalking pounce; chin on the floor |
| cannonback | WEAK | MAJOR | 078_cannonback_attack.png | Braced with the cannons forward, but the head is hidden and the front body spreads flat through the floor |
| riptusk | CLEAR | MAJOR | 081_riptusk_attack.png | Head-down charge; head and forelegs through the floor, only the tusk visible |
| mirejaw | CLEAR | MAJOR | 084_mirejaw_attack.png | Lunge whose head and jaws are buried in the floor; face unreadable, forelegs gone |
| aquaryn | CLEAR | MINOR | 087_aquaryn_attack.png | Low crouch with the head forward; thin stray sliver near the fins |
| torrentoad | WEAK | MINOR | 090_torrentoad_attack.png | Squat with the head forward; chin on the floor, little wind-up |
| cragclaw | WEAK | MINOR | 093_cragclaw_attack.png | Claw pushed forward but lying flat on the floor; face hidden under the shell |
| riverdrake | CLEAR | MINOR | 096_riverdrake_attack.png | Low lunge; head flattened on the floor |
| sirenseal | NONE | MAJOR | 099_sirenseal_attack.png | Body collapsed flat into the floor with a gap between the mane section and the torso; reads as dead |
| mangrove_monitor | CLEAR | MINOR | 102_mangrove_monitor_attack.png | Flat lunge; head and belly on or into the floor |
| tidecoil | CLEAR | – | 105_tidecoil_attack.png | Head strikes forward with jaws open |
| abyssal_guardian | WEAK | MINOR | 108_abyssal_guardian_attack.png | Nearly the idle silhouette; body floats with no ground contact |
| voltwig | CLEAR | MINOR | 111_voltwig_attack.png | Flat lunge; head and eye at the floor line |
| mosshock | CLEAR | MAJOR | 114_mosshock_attack.png | Head-down lunge; head sunk through the floor, face lost |
| staticub | CLEAR | MAJOR | 117_staticub_attack.png | Head-down charge; head and forelegs cut off by the floor |
| voltarach | CLEAR | MAJOR | 120_voltarach_attack.png | Forward pitch; front legs crumple into the floor and leg pieces lie detached on the ground |
| fulgocobra | NONE | MAJOR | 123_fulgocobra_attack.png | Body split into two separate pieces; head section buried in the floor; no strike reads |
| stormraven | NONE | MAJOR | 126_stormraven_attack.png | Collapsed flat onto the floor with the legs gone; reads as dead, not a dive |
| pebbik | NONE | MAJOR | 129_pebbik_attack.png | Torso sunk into the floor; only the head, ears and tail show |
| craghorn | CLEAR | MAJOR | 132_craghorn_attack.png | Ram with the head down; face and forelegs through the floor |
| stormbrush | CLEAR | MAJOR | 135_stormbrush_attack.png | Head-down charge; front half sunk into the floor |
| tanglevolt | CLEAR | MAJOR | 138_tanglevolt_attack.png | Head-down lunge; head and forelegs through the floor |
| thundertunnel | CLEAR | MAJOR | 141_thundertunnel_attack.png | Dig or charge with the head into the floor; face lost |
| glimmermoth | WEAK | – | 144_glimmermoth_attack.png | Slight lean with the wings folded |
| stormcapra | CLEAR | MAJOR | 147_stormcapra_attack.png | Horn ram; head and forelegs sunk through the floor |
| skyrill | CLEAR | MINOR | 150_skyrill_attack.png | Flat lunge; head half-buried |
| aeriex | CLEAR | MINOR | 153_aeriex_attack.png | Low forward lunge; a stray thin vertical sliver floats behind the neck |
| ribbonray | CLEAR | – | 156_ribbonray_attack.png | Horizontal dart forward |
| breezetail | CLEAR | – | 159_breezetail_attack.png | Pounce crouch |
| cloudfang | CLEAR | MINOR | 162_cloudfang_attack.png | Stalking crouch; chin on the floor |
| cliffspike | WEAK | – | 165_cliffspike_attack.png | Body lowered with the quills up; little directional intent |
| tempestwing | CLEAR | MINOR | 168_tempestwing_attack.png | Head-down dive with the wings raised; head at or under the floor |
| solmane | NONE | MAJOR | 171_solmane_attack.png | Body sunk into the floor, head missing, one wing standing vertical; broken |

**Lists:**
- **CLEAR (40):** terrapup, bramblebun, mudsnout, trailpup, burrowback, meadowhart, tuskroot, paddlenewt, galecrest, duskhush, veridian, nightburrow, stormtrail, riftfrill, ashtusk, sparkit, cindercub, shadelet, frostclaw, riptusk, mirejaw, aquaryn, riverdrake, mangrove_monitor, tidecoil, voltwig, mosshock, staticub, voltarach, craghorn, stormbrush, tanglevolt, thundertunnel, stormcapra, skyrill, aeriex, ribbonray, breezetail, cloudfang, tempestwing
- **WEAK (11):** ripplet, brooktail, pipwing, reedwing, mosshell, cannonback, torrentoad, cragclaw, abyssal_guardian, glimmermoth, cliffspike
- **NONE (6):** galewisp (idle-like); sirenseal, fulgocobra, stormraven, pebbik, solmane (collapsed or broken)
- **MAJOR geometry (21):** meadowhart, fulgocobra, sirenseal, solmane, voltarach, pebbik, stormraven (broken or detached); burrowback, nightburrow, tuskroot, ashtusk, riptusk, mirejaw, staticub, mosshock, stormbrush, craghorn, stormcapra, tanglevolt, thundertunnel, veridian (head or forelegs through the floor)

The MAJOR list does not include cannonback or mosshell. Their MAJOR flags are shell-body floor sinking and appear in the table only.

## B) Faces

The dominant failure is low-resolution, blown-out or posterized skin with blurred eyes and brows, typical of the Meshy-textured NPCs. No subject shows a full hair-colour tint washing over the whole face. What does occur is local mask misalignment: hair texture smeared onto the cheek, or skin-coloured patches inside the hair.

Counts: **MAJOR 20, MINOR 11, clean 10.**

| Subject | Severity | Frame | Reason |
|---|---|---|---|
| kael | MAJOR | 006_kael_face.png | Low-res blotchy skin, eyes barely readable, posterized coat |
| sera | MAJOR | 009_sera_face.png | Skin blown to white and merging with the white hair; face edge lost |
| lyra | MINOR | 012_lyra_face.png | Very pale, blown skin; eyes readable |
| villager_farmer | MINOR | 018_villager_farmer_face.png | Stray dark patch on the left cheek and a nose seam; shared base face with the smith and ranger |
| villager_smith | MINOR | 024_villager_smith_face.png | Same cheek patch and seam; same face as the farmer and ranger, only the hair recoloured |
| villager_ranger | MINOR | 030_villager_ranger_face.png | Same cheek patch and seam; same face, hair recolour only |
| grunt_a | MAJOR | 039_grunt_a_face.png | Skin blown white, eyes smeared into dark blurs |
| grunt_b | MINOR | 042_grunt_b_face.png | Readable; slight skin seam and softness |
| grunt_c | MAJOR | 045_grunt_c_face.png | Blown-white skin, crude posterized eyes and mouth |
| officer_a | MAJOR | 048_officer_a_face.png | Posterized yellow skin, blurred features, dark hair texture smeared onto the forehead and cheek |
| officer_b | MAJOR | 051_officer_b_face.png | Blown skin, blurry eyes, dark hair or collar texture smeared over the right cheek |
| captain_a | MAJOR | 054_captain_a_face.png | White hair and blown skin merge; eyepatch is a blur; mouth near-invisible |
| captain_b | MAJOR | 057_captain_b_face.png | Heavily posterized yellow and black skin, blurred eyes |
| innkeeper | MAJOR | 060_innkeeper_face.png | Blown-white skin, posterized brows and beard, orange bleeding at the face edge |
| inn_helper | MINOR | 063_inn_helper_face.png | Blown skin; skin-coloured stripe inside the hair (mask misalignment) |
| trader | MAJOR | 066_trader_face.png | Blown or posterized skin with a halo, smeared beard |
| craftsperson | MINOR | 069_craftsperson_face.png | Mottled low-res skin; features still readable |
| creature_caretaker | MINOR | 072_creature_caretaker_face.png | Blown skin, soft eyes; green hair stays on its mask |
| farmer | MAJOR | 075_farmer_face.png | Blown, blotchy skin; eyes and mouth crude and blurred |
| local_historian | MAJOR | 078_local_historian_face.png | Skin blown white and merging with the white hair and beard; glasses smeared |
| young_trainer | MINOR | 081_young_trainer_face.png | Blown skin, soft low-res eyes |
| rival_trainer | MAJOR | 084_rival_trainer_face.png | Blown-white skin, blurred brows and eyes, orange hair tone bleeding into the brow line |
| field_researcher | MINOR | 087_field_researcher_face.png | Blown skin; readable behind the glasses |
| wandering_trainer | MAJOR | 090_wandering_trainer_face.png | Near-pure-white skin, posterized moustache and brows |
| lost_traveler | MAJOR | 093_lost_traveler_face.png | Blown skin, blurred brows, skin-coloured patches inside the hair |
| alpha_tracker | MAJOR | 096_alpha_tracker_face.png | Blown and posterized skin with dark smudges around the eyes and mouth |
| courier | MINOR | 099_courier_face.png | Blown skin, soft features |
| former_tether_member | MAJOR | 102_former_tether_member_face.png | Blown skin with grimy smears; eyes are red blurs |
| captain_field | MAJOR | 117_captain_field_face.png | Same model as captain_a: white hair merging with blown skin, blurred eyepatch |
| captain_ridge | MAJOR | 120_captain_ridge_face.png | Same model as captain_b: posterized and blurry |
| captain_riverwatch | MAJOR | 123_captain_riverwatch_face.png | Same model as captain_b and captain_ridge: posterized and blurry |

**Clean (10):** trainer, grandpa, villager_keeper, villager_quarryman, warden, grunt, rank_grunt, rank_officer, rank_captain, rank_warden.

**§5.2 distinctness notes (outside the face-quality severity):**
- villager_keeper and villager_quarryman are the same head.
- villager_farmer, villager_smith and villager_ranger share one face and differ only in hair colour.
- grunt, rank_grunt, rank_officer and rank_captain are pixel-alike masked heads, so rank does not read at the face.
- warden and rank_warden are the same model.
- captain_a and captain_field are one model, and captain_b, captain_ridge and captain_riverwatch are another.
