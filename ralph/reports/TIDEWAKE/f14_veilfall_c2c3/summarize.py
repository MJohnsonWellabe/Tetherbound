import json, glob, sys, os
D = sys.argv[1]
TIER = {
 "water_lantern_shell_sentinel": "named_wild", "water_gull_basalt_claw": "named_wild",
 "water_brine_root_watcher": "named_wild", "water_drowned_garden_songweaver": "named_wild",
 "water_deep_watch_tidecoil": "top", "water_aquaryn_alpha": "top",
 "water_trainer_pell_trial": "floor", "water_trainer_calder": "top", "water_trainer_tess": "top",
 "water_trainer_tovin": "ladder", "water_trainer_solm": "ladder", "water_trainer_irva": "ladder", "water_trainer_bex": "ladder",
 # F14#1 Veilfall. top: BOSSES §4.10 (Venn, "Veilfall gate") and §4.11 (Nerissa, "final captain") are the
 # Veilfall major fights -> COMBAT §7 top-trainer rule. veilfall_trainer: no BOSSES §4 entry -> the same
 # normalized rule as floor/named_wild/ladder (ratio <= 0.55 and reader win >= 0.90). No threshold changed.
 "water_trainer_venn": "top", "water_trainer_nerissa": "top",
 "water_trainer_fennel": "veilfall_trainer", "water_trainer_morra": "veilfall_trainer", "water_trainer_evi": "veilfall_trainer",
}
# Not a fight in production (BOSSES §4.12 "This is not a combat boss"): printed as an N/A row, never PASS.
NO_FIGHT = {"water_abyssal_guardian_release": "BOSSES §4.12: not a combat boss; captive body with physics off (water_veilfall.gd::_build_guardian); no fight to pilot"}
rows = []
for f in sorted(glob.glob(os.path.join(D, "*.json"))):
    d = json.load(open(f))
    for r in d["rows"]:
        r["seeds"] = d["seeds"]; r["file"] = os.path.basename(f); rows.append(r)
order = list(TIER)
rows.sort(key=lambda r: (order.index(r["case"]), ["terrapup","ripplet","galewisp"].index(r["starter"])))
def c2(r):
    m, rd = r["pilots"]["MASHER"], r["pilots"]["READER"]; t = TIER[r["case"]]; fails = []
    mc, rc = m["median_lead_cost"], rd["median_lead_cost"]
    if t in ("floor", "named_wild", "ladder", "veilfall_trainer"):
        if mc <= 0 or rc > 0.55 * mc: fails.append("reader cost %.3f > 55%% of masher %.3f" % (rc, mc))
        if rd["win_rate"] < 0.90: fails.append("reader win %.2f < 0.90" % rd["win_rate"])
    if t == "top":
        if rd["win_rate"] < 0.75: fails.append("reader win %.2f < 0.75" % rd["win_rate"])
        if m["lead_faint_rate"] < 1.0: fails.append("masher lead faint %.2f < 1.00" % m["lead_faint_rate"])
        if m["party_wipe_rate"] < 0.25: fails.append("masher team wipe %.2f < 0.25" % m["party_wipe_rate"])
    return fails
def c3(r):
    fails = []
    for p in ("MASHER", "READER"):
        s = r["pilots"][p]
        if s["max_single_hit_frac"] >= 0.5: fails.append("%s max hit %.3f >= 0.50" % (p, s["max_single_hit_frac"]))
        if 0 <= s["min_tell_s"] < 0.8: fails.append("%s min tell %.2f < 0.80" % (p, s["min_tell_s"]))
    return fails
print("| Encounter | Tier | Starter | Seeds | Masher win / lead faint / wipe | Masher med lead cost | Reader win | Reader med lead cost | Ratio | Med s (M/R) | Max hit | Tells s | C2 | C3 (measured) |")
print("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
for r in rows:
    m, rd = r["pilots"]["MASHER"], r["pilots"]["READER"]
    f2, f3 = c2(r), c3(r)
    ratio = rd["median_lead_cost"] / m["median_lead_cost"] if m["median_lead_cost"] > 0 else float("nan")
    tell = "%.2f–%.2f" % (min(m["min_tell_s"], rd["min_tell_s"]), max(m["max_tell_s"], rd["max_tell_s"]))
    print("| %s | %s | %s | %d | %.2f / %.2f / %.2f | %.3f | %.2f | %.3f | %.2f | %.0f / %.0f | %.3f | %s | %s | %s |" % (
        r["case"], TIER[r["case"]], r["starter"], r["seeds"], m["win_rate"], m["lead_faint_rate"], m["party_wipe_rate"],
        m["median_lead_cost"], rd["win_rate"], rd["median_lead_cost"], ratio, m["median_seconds"], rd["median_seconds"],
        max(m["max_single_hit_frac"], rd["max_single_hit_frac"]), tell,
        "PASS" if not f2 else "FAIL: " + "; ".join(f2), "PASS" if not f3 else "FAIL: " + "; ".join(f3)))
for k, why in NO_FIGHT.items():
    print("| %s | none | all | 0 | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A: %s | N/A |" % (k, why))
