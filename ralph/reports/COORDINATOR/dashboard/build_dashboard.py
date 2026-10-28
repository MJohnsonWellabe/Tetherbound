#!/usr/bin/env python3
"""Render the Tetherbound acceptance dashboard from criteria.json + status.json.

criteria.json: per-F-row atomic criteria with status/evidence/gap (research agent).
status.json:   coordinator's live notes (batches, lanes, decisions, next steps).
Output: tetherbound_dashboard.html (published as one artifact, same URL each hour).
"""
import html
import json
import sys
from pathlib import Path

HERE = Path(__file__).parent
crit = json.loads((HERE / "criteria.json").read_text(encoding="utf-8"))
status = json.loads((HERE / "status.json").read_text(encoding="utf-8"))

E = html.escape
ORDER = ["met", "partial", "in_progress", "failing", "blocked", "not_started"]
LABEL = {"met": "Met", "partial": "Partial", "in_progress": "In progress",
         "failing": "Failing", "blocked": "Blocked", "not_started": "Not started"}
CHAPTERS = [("Meadows", "M", ["F01", "F02", "F03", "F04", "F05"]),
            ("Cloudreach", "C", ["F06", "F07", "F08"]),
            ("Stormwood", "S", ["F09", "F10", "F11"]),
            ("Tidewake", "T", ["F12", "F13", "F14", "F15"])]
# Redesign rows (owner, 2026-09-29): every row outside the four original chapters is
# grouped by its `chapter` field (the wave name) in first-seen order, one section each.
_ORIG = {i for _n, _l, ids in CHAPTERS for i in ids}
_crit_rows = json.loads((HERE / "criteria.json").read_text(encoding="utf-8"))["rows"]
for _wave in dict.fromkeys(r.get("chapter", "Redesign") for r in _crit_rows if r["id"] not in _ORIG):
    CHAPTERS.append((_wave, "R", [r["id"] for r in _crit_rows if r["id"] not in _ORIG and r.get("chapter", "Redesign") == _wave]))
# Owner 25 Oct ("why aren't they with the rest of the visual cards"): every GPU-judged
# visual criterion sits in one Visual section at the end; the visual criteria of other
# features move there as one card, and their home rows count only what is left.
VISUAL_ROWS = ["F36", "F38", "F39", "F40", "F41"]
VISUAL_OTHER = ["F04#6", "F08#3", "F10#2", "F13#5", "F17#6", "F22#4", "F26#3"]
CHAPTERS = [(n, l, [i for i in ids if i not in VISUAL_ROWS]) for n, l, ids in CHAPTERS]
CHAPTERS.append(("Visual · judged on the GPU", "V", ["VISUAL_OTHER"] + VISUAL_ROWS))
# Owner 27 Oct ("move those out to the end and group based on whatever they're
# blocked on"): the open criteria outside the visual work leave their home rows and
# sit in one last section, one card per blocker, so every feature row above shows
# only its own deliverable work.
BLOCKED_GROUPS = [
    ("Owner action", "Only the owner can do these: the ROG Ally handheld test, a human play "
     "pass of the build, and the play-pass check of the 15-25 hour clear (the agent estimate "
     "is 8.8-12.5 h, a lower bound).", ["F26#5", "F49#1", "F49#2", "F47#0"]),
    ("The integrated four-biome run", "One save through all four chapters with every seam "
     "earned, not generated. The pieces and most seams exist; the earned Master, Kitchen and "
     "feast loop in every chapter and the last matched seams do not yet. Chapter exit cards "
     "M2, M3, S2 and T2 wait on this run and on the visual bar.", ["F49#0", "F19#5"]),
    ("Release after the run passes", "Publishes the rolling download from the commit where "
     "the integrated run passes.", ["F49#3"]),
]
BLOCKED_SEL = {_s for _g in BLOCKED_GROUPS for _s in _g[2]}
CHAPTERS.append(("Not done · grouped by what blocks them", "B",
                 [f"BLOCKED_{_n}" for _n in range(len(BLOCKED_GROUPS))]))


def norm(s):
    s = (s or "not_started").strip().lower().replace(" ", "_").replace("-", "_")
    return s if s in LABEL else "partial"


def pct(row):
    c = row.get("criteria", [])
    if not c:
        return int(row.get("pct", 0))
    w = {"met": 1.0}  # owner 2026-10-06: fill is met criteria only
    return round(100 * sum(w.get(norm(x.get("status")), 0) for x in c) / len(c))


rows = {r["id"]: r for r in crit["rows"]}
all_c = [x for r in crit["rows"] for x in r.get("criteria", [])]
counts = {k: sum(1 for x in all_c if norm(x.get("status")) == k) for k in ORDER}
overall = round(sum(pct(r) for r in crit["rows"]) / max(1, len(crit["rows"])))
_open_by = {"F36": 0, "look": 0, "other": 0}
for _r in crit["rows"]:
    _o = sum(1 for x in _r.get("criteria", []) if norm(x.get("status")) != "met")
    _open_by["F36" if _r["id"] == "F36" else "look" if _r["id"] in ("F38", "F39", "F40", "F41") else "other"] += _o
# Owner 2026-10-07: a criterion counts once evidenced on a lane branch; show how many are not yet on main.
evidenced_only = sum(1 for x in all_c if norm(x.get("status")) == "met" and str(x.get("note", "")).startswith("Landed: Evidenced"))
redesign_c = [x for r in crit["rows"] if r["id"] not in _ORIG for x in r.get("criteria", [])]
redesign_met = sum(1 for x in redesign_c if norm(x.get("status")) == "met")
last_id = crit["rows"][-1]["id"] if crit["rows"] else "F15"
accepted = sum(1 for r in crit["rows"] if r.get("criteria") and all(norm(x.get("status")) == "met" for x in r["criteria"]))


def bar(p):
    return f'<span class="meter" role="img" aria-label="{p}% of criteria met"><span style="width:{p}%"></span></span>'


def pill(s):
    s = norm(s)
    return f'<span class="pill s-{s}">{LABEL[s]}</span>'


def stack(cs):
    total = max(1, len(cs))
    segs = "".join(
        f'<span class="seg s-{k}" style="flex:{sum(1 for x in cs if norm(x.get("status")) == k)}" title="{LABEL[k]}: {sum(1 for x in cs if norm(x.get("status")) == k)}"></span>'
        for k in ORDER if any(norm(x.get("status")) == k for x in cs))
    return f'<span class="stack" aria-hidden="true">{segs}</span>'


# ---- sections -------------------------------------------------------------
# Owner 24 Oct: every feature, F38-F41 included, sits on this tab; a row with
# per-unit sub-rows shows them as nested cards whose counts add up to the row total.
VISUAL_FEATURES = set()
_GROUP_NAMES = {"0": "priority assets", "1": "top-20 catalog items", "2": "impact >12 catalog items"}


def _crit_li(x, label=""):
    return (f'<li class="crit s-{norm(x.get("status"))}"><div class="crit-head">{pill(x.get("status"))}'
            f'<span class="crit-text">{("<b>" + E(label) + "</b> ") if label else ""}{E(x.get("text", ""))}</span></div>'
            f'<dl><div><dt>Evidence</dt><dd>{E(x.get("evidence") or "None recorded")}</dd></div>'
            f'<div><dt>Remaining</dt><dd>{E(x.get("gap") or "Nothing")}</dd></div></dl></li>')


def _subcard(title, group):
    m = sum(1 for x in group if norm(x.get("status")) == "met")
    p_ = round(100 * m / max(1, len(group)))
    return (f'<li class="crit sub"><details class="frow"><summary><span class="fid"></span><span class="ftitle">{E(title)}</span>'
            f'<span class="fnum">{m}/{len(group)} met</span>{bar(p_)}<span class="fpct">{p_}%</span>{stack(group)}</summary>'
            f'<ol class="crits">{"".join(_crit_li(x, x.get("subject", "")) for x in group)}</ol></details></li>')
chapter_html = []
for name, letter, ids in CHAPTERS:
    cards = []
    _shown = []
    for fid in ids:
        if fid == "VISUAL_OTHER":
            _vo = []
            for _sel in VISUAL_OTHER:
                _f, _, _i = _sel.partition("#")
                _c = rows.get(_f, {}).get("criteria", [])
                if _i.isdigit() and int(_i) < len(_c):
                    _vo.append(dict(_c[int(_i)], text=f"{_sel} · " + str(_c[int(_i)].get("text", ""))))
            r = {"title": "Visual criteria from other features", "criteria": _vo}
        elif fid.startswith("BLOCKED_"):
            _gname, _gwhy, _gsel = BLOCKED_GROUPS[int(fid.split("_")[1])]
            _bc = []
            for _sel in _gsel:
                _f, _, _i = _sel.partition("#")
                _c = rows.get(_f, {}).get("criteria", [])
                if _i.isdigit() and int(_i) < len(_c) and norm(_c[int(_i)].get("status")) != "met":
                    _bc.append(dict(_c[int(_i)], text=f"{_sel} · " + str(_c[int(_i)].get("text", ""))))
            r = {"title": _gname, "criteria": _bc, "why": _gwhy}
        else:
            r = rows.get(fid)
            _moved = VISUAL_OTHER + sorted(BLOCKED_SEL)
            if r and any(s.startswith(fid + "#") for s in _moved):
                r = dict(r, criteria=[x for _n, x in enumerate(r.get("criteria", []))
                                      if f"{fid}#{_n}" not in _moved])
        if not r or fid in VISUAL_FEATURES or not r.get("criteria"):
            continue
        _shown.extend(r.get("criteria", []))
        p = pct(r)
        cs = r.get("criteria", [])
        met = sum(1 for x in cs if norm(x.get("status")) == "met")
        _top = [x for x in cs if not x.get("parent")]
        _groups = {}
        for x in cs:
            if x.get("parent"):
                _groups.setdefault(x["parent"], []).append(x)
        _parents = {}
        for _n, x in enumerate(_top):
            _parents[f"{fid}#{x.get('audit_index', _n)}"] = x
        items = (_subcard(f"{fid} biome-level criteria" if fid in ("F38", "F39", "F40", "F41") else f"{fid} other criteria", _top)
                 if _groups else "".join(_crit_li(x) for x in _top))
        for _par, _g in _groups.items():
            _k = _par.split("#")[-1]
            _name = "roster pose subjects" if fid == "F36" and _k == "1" else _GROUP_NAMES.get(_k, "items")
            items += _subcard(f"{fid} ({_k}) {_name}", _g)
        if r.get("why"):
            items = f'<li class="crit"><p class="note">Why: {E(r["why"])}</p></li>' + items
        _lbl = {"VISUAL_OTHER": "V"}.get(fid, f"B{int(fid.split('_')[1]) + 1}" if fid.startswith("BLOCKED_") else fid)
        cards.append(
            f'<details class="frow" id="{fid}"><summary>'
            f'<span class="fid">{_lbl}</span><span class="ftitle">{E(r.get("title", ""))}</span>'
            f'<span class="fnum">{met}/{len(cs)} met</span>{bar(p)}<span class="fpct">{p}%</span>{stack(cs)}'
            f'</summary><ol class="crits">{items}</ol></details>')
    # Owner 25 Oct: the section figure is met / total over the criteria shown in it.
    ch_pct = round(100 * sum(1 for x in _shown if norm(x.get("status")) == "met") / max(1, len(_shown)))
    if not cards:
        continue
    cards_html = "".join(cards)
    chapter_html.append(
        f'<section class="chapter ch-{letter}"><header><h2>{name}</h2>'
        f'<span class="chpct">{ch_pct}%</span></header>{cards_html}</section>')

cc = "".join(
    f'<tr><td>{E(x["id"])}</td><td>{pill(x.get("status"))}</td><td>{E(x.get("note", ""))}</td></tr>'
    for x in crit.get("cross_cutting", []))
# Chapter exit cards: progress = the weighted share of their feeder F-row criteria
# met (80%) plus the integrated continuous-path run and its evidence card (20%),
# which only counts once a card's `integrated_run` field is set.
CARD_FEEDERS = {"M1": ["F01"], "M2": ["F02"], "M3": ["F03", "F04"], "M4": ["F05"],
                "C1": ["F06"], "C2": ["F07"], "C3": ["F08"],
                "S1": ["F09"], "S2": ["F10"], "S3": ["F11"],
                "T1": ["F12"], "T2": ["F13", "F14"], "T3": ["F15"]}


def card_pct(card):
    feeders = [x for f in CARD_FEEDERS.get(card["id"], []) for x in rows.get(f, {}).get("criteria", [])]
    w = {"met": 1.0}  # met only
    fp = sum(w.get(norm(x.get("status")), 0) for x in feeders) / max(1, len(feeders))
    met = sum(1 for x in feeders if norm(x.get("status")) == "met")
    run = 1.0 if card.get("integrated_run") else 0.0
    return round(100 * (0.8 * fp + 0.2 * run)), met, len(feeders)


def card_row(x):
    cp, met, n = card_pct(x)
    run = x.get("integrated_run") or "not yet run"
    return (f'<tr><td>{E(x["id"])}</td><td>{bar(cp)} {cp}%</td><td>{met} / {n} feeder criteria met '
            f'({E(", ".join(CARD_FEEDERS.get(x["id"], [])))})</td><td>{E(run)}</td><td>{E(card_note(x))}</td></tr>')


def card_note(card):
    open_ids = [f"{f}#{i}" for f in CARD_FEEDERS.get(card["id"], [])
                for i, c in enumerate(rows.get(f, {}).get("criteria", [])) if norm(c.get("status")) != "met"]
    if not open_ids:
        return "All feeder criteria met; needs the integrated continuous run and its evidence card."
    return "Open: " + ", ".join(open_ids) + "."


cards_tbl = "".join(card_row(x) for x in crit.get("chapter_cards", []))


def li(items):
    # A bare string is one item; iterating it would print one letter per bullet.
    if isinstance(items, str):
        items = [items]
    return "".join(f"<li>{E(i)}</li>" for i in items)


batches = "".join(
    f'<tr><td>{E(b["name"])}</td><td><code>{E(b.get("sha", ""))}</code></td><td>{E(b.get("state", ""))}</td><td>{E(b.get("contents", ""))}</td></tr>'
    for b in status.get("batches", []))
# Shortcut debt (owner, 2026-09-27): every criterion closed under the relaxed-proof
# rule, with what its proof skipped, so the chapter-exit and release playthroughs
# exercise each item. Kinds are classified from the disclosure text.
CHAPTER_OF = {**{f"F0{n}": "Meadows" for n in range(1, 6)},
              **{f"F0{n}": "Cloudreach" for n in range(6, 9)},
              **{f"F{n:02d}": "Stormwood" for n in range(9, 12)},
              **{f"F{n:02d}": "Tidewake" for n in range(12, 16)}}
DEBT_KINDS = [
    ("Skipped part", "high", ("skipped", "skips", "no single run", "not proven", "excluded", "not exercised", "missing", "not covered", "no two-peer", "static computation", "not a four-peer", "open")),
    ("Flag or ledger written", "medium", ("flag", "ledger fixture", "set directly", "guardian_fixture", "defeat by ledger")),
    ("Fixture state", "medium", ("party", "L25", "L44", "L46", "granted", "fixture start", "declared start")),
    ("Start, position or checkpoint", "low", ("teleport", "position", "start save", "checkpoint", "placed", "joins", "resume")),
    ("Harness input", "low", ("harness", "pilot", "scripted", "accelerated", "signal")),
]
debt_rows = []
for r in crit["rows"]:
    for i, c in enumerate(r["criteria"]):
        ev = c.get("evidence", "")
        if c["status"] != "met" or "Shortcuts disclosed" not in ev:
            continue
        disc = ev.split("Shortcuts disclosed:", 1)[1].split("Independent re-check", 1)[0].strip()
        low = disc.lower()
        kinds = [k for k, _sev, words in DEBT_KINDS if any(w.lower() in low for w in words)]
        sev = next((sv for k, sv, _w in DEBT_KINDS if k in kinds), "low")
        debt_rows.append((sev, r["id"], i, c["text"], kinds, disc))
SEV_ORDER = {"high": 0, "medium": 1, "low": 2}
# Retirement (owner, 2026-09-27): a chapter card's passing integrated run replays its
# feeders' route on an earned save, so it retires their route shortcuts (starts,
# teleports, written flags, fixture state, skipped route parts). Harness input and
# accelerated clocks survive every scripted run; only a human play pass retires them.
# The four-chapter run (status.json "four_chapter_run") retires chapter-boundary
# fixture starts everywhere once it passes.
ROUTE_KINDS = {"Skipped part", "Flag or ledger written", "Fixture state", "Start, position or checkpoint"}
FEATURE_CARD = {f: cid for cid, fs in CARD_FEEDERS.items() for f in fs}
CARD_RUN = {x["id"]: bool(x.get("integrated_run")) for x in crit.get("chapter_cards", [])}
FOUR_CHAPTER = bool(status.get("four_chapter_run"))
def debt_state(rid, kinds):
    card = FEATURE_CARD.get(rid)
    open_kinds = [k for k in kinds if not ((k in ROUTE_KINDS and card and CARD_RUN.get(card))
                                           or (k == "Fixture state" and FOUR_CHAPTER))]
    if not open_kinds:
        return True, f"Retired by {card} run" if card and CARD_RUN.get(card) else "Retired by four-chapter run"
    how = []
    if any(k in ROUTE_KINDS for k in open_kinds):
        how.append(f"{card} integrated run" if card else "four-chapter run")
    if "Harness input" in open_kinds:
        how.append("human play pass")
    return False, "Open: " + ", ".join(open_kinds) + (" (retire via " + " + ".join(how) + ")" if how else "")
debt_rows = [(sev, rid, i, text, kinds, disc, *debt_state(rid, kinds)) for sev, rid, i, text, kinds, disc in debt_rows]
debt_rows.sort(key=lambda t: (t[6], SEV_ORDER[t[0]], t[1], t[2]))
debt_open = sum(1 for t in debt_rows if not t[6])
debt_summary = f"{debt_open} open, {len(debt_rows) - debt_open} retired of {len(debt_rows)} shortcut-closed criteria."
debt_tbl = "".join(
    f'<tr><td>{E(sev)}</td><td>{E(rid)}#{i}</td><td>{E(CHAPTER_OF.get(rid, ""))}</td><td>{E(text)}</td><td>{E(", ".join(kinds))}</td><td>{E(state)}</td><td>{E(disc)}</td></tr>'
    for sev, rid, i, text, kinds, disc, retired, state in debt_rows)
lanes = "".join(
    f'<tr><td>{E(l["lane"])}</td><td>{E(l.get("now", ""))}</td><td>{E(l.get("next", ""))}</td></tr>'
    for l in status.get("lanes", []))
lane_activity = "".join(
    f'<tr><td>{E(l["lane"])}</td><td>{E(l.get("checkpoint", ""))}</td></tr>'
    for l in status.get("lane_activity", []))
lane_activity_section = (
    '<section class="panel"><h2>Latest lane activity</h2>'
    f'<p class="meta">Last lane refresh {E(status.get("last_lane_refresh", ""))}. '
    'Branch checkpoints below do not increase acceptance on main.</p>'
    '<div class="tbl"><table><thead><tr><th>Lane</th><th>Latest checkpoint</th></tr></thead>'
    f'<tbody>{lane_activity}</tbody></table></div></section>'
    if lane_activity else "")
legend = "".join(f'<span class="leg">{pill(k)} {counts[k]}</span>' for k in ORDER)

# ---- delivery plan (Gantt) -------------------------------------------------
# Owner request 2026-10-11: one sentence per active lane, the criteria it
# helps, and how long until its next part (status.json "active_lanes").
_al = status.get("active_lanes", [])
active_lanes_html = (
    '<section class="panel" aria-labelledby="lanes-h"><h2 id="lanes-h">Active lanes</h2>'
    f'<p class="note">{E(status.get("active_lanes_note", ""))}</p>'
    '<div class="tbl"><table><thead><tr><th>Lane</th><th>What it is doing</th><th>Criteria it helps</th><th>Next part in</th></tr></thead><tbody>'
    + "".join(f'<tr><td><b>{E(l.get("lane",""))}</b></td><td>{E(l.get("doing",""))}</td><td>{E(l.get("criteria",""))}</td><td>{E(l.get("next",""))}</td></tr>' for l in _al)
    + '</tbody></table></div></section>')


# Owner request 2026-10-04: a frozen baseline of five lanes x 8-hour sprints,
# tracked live. plan.json holds the bars; progress is read from criteria.json.
import datetime as _dt
VCAT_PATH = HERE / "visual_catalog.json"
vcat = json.loads(VCAT_PATH.read_text(encoding="utf-8")) if VCAT_PATH.exists() else {"biomes": []}
_VSTATUS = {"done": "met", "parked": "failing", "open": "not_started"}


def render_gantt(_plan_path, heading, hid, blurb, summary=None):
    if not _plan_path.exists():
        return ""
    plan = json.loads(_plan_path.read_text(encoding="utf-8"))
    p_start = _dt.datetime.fromisoformat(plan["start"].replace("Z", "+00:00"))
    p_hours = float(plan.get("sprint_hours", 8))
    n_sprints = int(plan["sprints"])
    now = _dt.datetime.now(_dt.timezone.utc)
    now_pos = (now - p_start).total_seconds() / 3600.0 / p_hours
    W = {"met": 1.0}  # owner 2026-10-06: fill is met criteria only

    def _items(f):
        # Owner 12 Oct ("plan what's open"): a bar may name single criteria
        # ("F19#5"), one chapter card ("CARD:M2") or one release-wide row
        # ("XCUT:Release reliability"), so it measures only its open work.
        if f.startswith("VCU:"):
            # "VCU:<owner prefix>" -> that owner's catalog tasks, each row once across biomes.
            seen = {}
            for x in vcat["biomes"]:
                for t in x["tasks"]:
                    if t["owner"].startswith(f[4:]):
                        seen[t["id"]] = {"status": _VSTATUS.get(t["status"], "not_started")}
            return list(seen.values())
        if f.startswith("VC:"):
            # "VC:<biome>:<owner prefix>:<group>" -> that biome's catalog tasks.
            _, b, who, grp = (f.split(":") + ["", "", ""])[:4]
            return [{"status": _VSTATUS.get(t["status"], "not_started")}
                    for x in vcat["biomes"] if x["biome"] == b for t in x["tasks"]
                    if (not who or t["owner"].startswith(who)) and (not grp or t["group"] == grp)]
        if f.startswith("CARD:"):
            return [x for x in crit.get("chapter_cards", []) if x.get("id") == f[5:]]
        if f.startswith("XCUT:"):
            return [x for x in crit.get("cross_cutting", []) if str(x.get("id", "")).startswith(f[5:])]
        if "#" in f:
            fid, _, idx = f.partition("#")
            cs = rows.get(fid, {}).get("criteria", [])
            return [cs[int(idx)]] if idx.isdigit() and int(idx) < len(cs) else []
        # Pseudo-features: the 13 chapter exit cards and the release-wide
        # requirements, which F49's integrated run must also close.
        if f == "CARDS":
            return crit.get("chapter_cards", [])
        if f == "XCUT":
            return crit.get("cross_cutting", [])
        if f == "XPERF":
            return [x for x in crit.get("cross_cutting", []) if str(x.get("id", "")).startswith("Ally device")]
        return rows.get(f, {}).get("criteria", [])

    def feat_pct(feats):
        cs = [x for f in feats for x in _items(f)]
        if not cs:
            return 0.0, 0, 0
        done = sum(1 for x in cs if norm(x.get("status")) == "met")  # owner 24 Oct: blocked is not done
        return 100.0 * sum(W.get(norm(x.get("status")), 0) for x in cs) / len(cs), done, len(cs)

    # Freeze each bar's starting progress the first time the plan is rendered,
    # so "expected" measures the remaining work, not work done before the plan.
    froze = False
    for lane in plan["lanes"]:
        for b in lane["bars"]:
            if "baseline_pct" not in b:
                b["baseline_pct"] = round(feat_pct(b["features"])[0], 1)
                froze = True
    if froze:
        _plan_path.write_text(json.dumps(plan, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")

    # Owner, 2026-10-04: show every time in Chicago time.
    from zoneinfo import ZoneInfo
    _CT = ZoneInfo("America/Chicago")

    def at(pos):
        return (p_start + _dt.timedelta(hours=pos * p_hours)).astimezone(_CT)

    def fmt(t):
        local = t.astimezone(_CT)
        return f"{local:%a %d %b} {local.hour % 12 or 12}:{local:%M %p}"

    TRACK = {"done": "Done", "on_track": "On track", "behind": "Behind", "late": "Late",
             "planned": "Not started", "early": "Started early"}
    # Owner 10-10 ("make the delivery plan more legible"): the chart shows only the
    # current baseline's window, labelled by day; each bar carries its full name and
    # done/total; a plain summary and a slim table replace the expected-% columns.
    v0 = min(float(b["start"]) for l in plan["lanes"] for b in l["bars"])
    v1 = max(float(b["end"]) for l in plan["lanes"] for b in l["bars"])
    span = max(0.01, v1 - v0)

    def x(pos):
        return 100.0 * (pos - v0) / span

    def short(t):
        local = t.astimezone(_CT)
        return f"{local:%a} {local.day} {local:%b}"

    track_rows, lane_html, counts_t, now_items = [], [], {}, []
    for lane in plan["lanes"]:
        bars = []
        for b in lane["bars"]:
            s0, e0 = float(b["start"]), float(b["end"])
            actual, done, n = feat_pct(b["features"])
            base = float(b.get("baseline_pct", 0))
            frac = min(1.0, max(0.0, (now_pos - s0) / max(0.01, e0 - s0)))
            expected = base + (100.0 - base) * frac
            if n and done == n:
                st = "done"
            elif now_pos < s0:
                st = "early" if actual > base + 0.5 else "planned"
            elif now_pos > e0:
                st = "late"
            elif actual >= expected - 15:
                st = "on_track"
            else:
                st = "behind"
            counts_t[st] = counts_t.get(st, 0) + 1
            name = b["label"].split(" — ")[0]
            tip = (f'{name}: {fmt(at(s0))} to {fmt(at(e0))} {at(s0).tzname()}. '
                   f'{done} of {n} criteria done. {actual:.0f}% met, {expected:.0f}% expected by now. {TRACK[st]}.')
            bars.append(
                f'<div class="gbar t-{st}" style="left:{x(s0):.3f}%;width:{x(e0) - x(s0):.3f}%" title="{E(tip)}">'
                f'<span class="gfill" style="width:{actual:.0f}%"></span>'
                f'<span class="glabel">{E(name)} <span class="gcount">{done}/{n}</span></span></div>')
            note = " · ".join(filter(None, [", ".join(b.get("depends", [])), b.get("note", "")]))
            track_rows.append(
                f'<tr class="t-{st}"><td>{E(lane["id"])}</td><td>{E(name)}'
                f'{("<br><span class=meta>" + E(note) + "</span>") if note else ""}</td>'
                f'<td>{short(at(s0))} → {short(at(e0))}</td>'
                f'<td class="num">{done} / {n}</td><td><span class="tpill t-{st}">{TRACK[st]}</span></td></tr>')
            if lane.get("id") != "owner" and s0 <= now_pos < e0:
                now_items.append(f'<li><b>{E(lane["name"].split(" · ")[0])}</b>: {E(name)} '
                                 f'<span class="meta">({done} of {n} done, ends {short(at(e0))})</span> '
                                 f'<span class="tpill t-{st}">{TRACK[st]}</span></li>')
        lane_html.append(
            f'<div class="glane"><div class="gname">{E(lane["name"].split(" · ")[0])}'
            f'<span class="meta">{E(lane["name"].split(" · ", 1)[1] if " · " in lane["name"] else "")}</span></div>'
            f'<div class="gtrack">{"".join(bars)}</div></div>')
    # Day ticks (Chicago midnight) across the window.
    days, d = [], at(v0).replace(hour=0, minute=0, second=0, microsecond=0) + _dt.timedelta(days=1)
    while d <= at(v1):
        pos = v0 + (d - at(v0)).total_seconds() / 3600.0 / p_hours
        days.append((pos, d))
        d += _dt.timedelta(days=1)
    heads = "".join(f'<div class="gs" style="left:{x(pos):.3f}%"><b>{dd.strftime("%a")}</b><span>{dd.day} {dd.strftime("%b")}</span></div>'
                    for pos, dd in days)
    grid = "".join(f'<i class="gday" style="left:{x(pos):.3f}%"></i>' for pos, _ in days)
    now_html = (f'<div class="gnow" style="left:{x(now_pos):.3f}%"><span>now</span></div>'
                if v0 <= now_pos <= v1 else "")
    # Finish = end of the last lane bar (owner-only items follow it; owner 2026-10-07).
    finish = at(max(float(b["end"]) for l in plan["lanes"] if l.get("id") != "owner" for b in l["bars"]))
    tsum = " · ".join(f'{v} {TRACK[k].lower()}' for k, v in counts_t.items())
    open_c = sum(1 for x_ in all_c if norm(x_.get("status")) != "met")
    plan_html = f"""
  <section class="panel gantt-panel" aria-labelledby="{hid}"><h2 id="{hid}">{E(heading)}</h2>
    <div class="gsum">
      <div><span class="meta">Lane work projected to finish</span><b>{fmt(finish)} {finish.tzname()}</b></div>
      <div><span class="meta">{E(summary[0]) if summary else "Criteria met"}</span><b>{E(summary[1]) if summary else f"{len(all_c) - open_c} of {len(all_c)}"}</b></div>
      <div><span class="meta">Bars</span><b>{E(tsum)}</b></div>
    </div>
    <h3>Now</h3>
    <ul class="gnowlist">{"".join(now_items) or "<li>No lane is running; the plan starts when the lanes restart.</li>"}</ul>
    <p class="note">Each bar is one piece of work a lane takes to done. The darker fill is the share of its criteria met; the count is done / total.
      Hover a bar for dates and expected progress. {blurb}</p>
    <div class="gscroll"><div class="gantt">
      <div class="glane ghead"><div class="gname"></div><div class="gtrack">{heads}{now_html}</div></div>
      {"".join(l.replace('<div class="gtrack">', '<div class="gtrack">' + grid, 1) for l in lane_html)}
    </div></div>
    <div class="glegend">{"".join(f'<span class="tpill t-{k}">{v}</span>' for k, v in TRACK.items())}</div>
    <div class="tbl"><table><thead><tr><th>Lane</th><th>Work</th><th>Dates (CT)</th><th>Done</th><th>Status</th></tr></thead>
    <tbody>{"".join(track_rows)}</tbody></table></div>
    <details class="note"><summary>Rebaseline history</summary><ul>{"".join(f"<li>{E(r)}</li>" for r in plan.get("rebaselines", []))}</ul></details>
  </section>"""
    return plan_html


plan_html = render_gantt(HERE / "plan.json", "Delivery plan", "plan-h",
                         "Owner items (ROG Ally test, play pass, release) follow the lanes.")


# ---- visual catalog tab (owner 12 Oct) ----------------------------------------
_VPILL = {"done": "met", "parked": "failing", "open": "not_started"}
_VLABEL = {"done": "Done", "parked": "Parked", "open": "Open"}
# Task status follows the Acceptance tab's per-item rows (owner 24 Oct: one source,
# GPU-judged), so the two tabs cannot disagree; the catalog file keeps the defect text.
_vboard = {x["subject"]: norm(x.get("status")) for r_ in crit["rows"] if r_["id"] in ("F38", "F39", "F40", "F41")
           for x in r_.get("criteria", []) if x.get("parent")}
for _b in vcat["biomes"]:
    for _t in _b["tasks"]:
        if _t["id"] in _vboard:
            _s = _vboard[_t["id"]]
            _t["status"] = "done" if _s == "met" else "parked" if _s in ("failing", "blocked") else "open"
            _t["note"] = "Board: " + _s.replace("_", " ")
_vu = {}
for _b in vcat["biomes"]:
    for _t in _b["tasks"]:
        _vu[_t["id"]] = _t["status"]
_vdone = sum(1 for v_ in _vu.values() if v_ == "done")
vplan_html = render_gantt(HERE / "visual_plan.json", "Visual catalog plan (F38–F41)", "vplan-h",
                          "Codex lanes start when its main-plan work ends; Claude lanes start when the main lanes end.",
                          summary=("Catalog tasks done (each row once)", f"{_vdone} of {len(_vu)}"))
_VLETTER = {"meadows": "M", "tidewake": "T", "cloudreach": "C", "stormwood": "S"}


def _vpill(st):
    return f'<span class="pill s-{_VPILL[st]}">{_VLABEL[st]}</span>'


def _vrow(fid, title, items, crit_html):
    # One expandable row in the Acceptance tab's style: count, meter, percent, stack.
    met = sum(1 for x in items if norm(x.get("status")) == "met")
    p = round(100 * met / max(1, len(items)))
    return (f'<details class="frow"><summary><span class="fid">{E(fid)}</span><span class="ftitle">{E(title)}</span>'
            f'<span class="fnum">{met}/{len(items)} done</span>{bar(p)}<span class="fpct">{p}%</span>{stack(items)}'
            f'</summary><ol class="crits">{crit_html}</ol></details>')


_vsections = []
_vk = {"tasks": 0, "done": 0, "crit": 0, "crit_met": 0}
for _b in vcat["biomes"]:
    _r = rows.get(_b["feature"], {})
    _cs = _r.get("criteria", [])
    _ts = _b["tasks"]
    _crit_items = "".join(
        f'<li class="crit s-{norm(x.get("status"))}"><div class="crit-head">{pill(x.get("status"))}'
        f'<span class="crit-text"><b>#{n}</b> {E(x.get("text", ""))}</span></div>'
        f'<dl><div><dt>Evidence</dt><dd>{E(x.get("evidence") or "None recorded")}</dd></div>'
        f'<div><dt>Remaining</dt><dd>{E(x.get("gap") or "Nothing")}</dd></div></dl></li>' for n, x in enumerate(_cs))
    _cards = [_vrow(_b["feature"], "Acceptance criteria", _cs, _crit_items)]
    for _grp, _gname in (("top20", "Top 20"), ("impact>12", "Impact over 12")):
        for _who in ("Codex", "Claude"):
            _gt = [t for t in _ts if t["group"] == _grp and t["owner"].startswith(_who)]
            if not _gt:
                continue
            _items = "".join(
                f'<li class="crit s-{_VPILL[t["status"]]}"><div class="crit-head">{_vpill(t["status"])}'
                f'<span class="crit-text"><b>{E(t["id"])}</b> {E(t["subject"])}</span></div>'
                f'<dl><div><dt>Defect</dt><dd>{E(t["defect"])}</dd></div>'
                f'<div><dt>Status</dt><dd>{E(t["note"])}</dd></div>'
                f'<div><dt>Item</dt><dd>Impact {t["impact"]:.0f} · {E(t["fix_class"])} · {E(t["owner"])} · biomes {E(t["biomes"].replace(";", ", "))}</dd></div></dl></li>'
                for t in sorted(_gt, key=lambda t: -t["impact"]))
            _cards.append(_vrow(_who, f'{_gname} · {_who} ({len(_gt)} tasks)',
                                [{"status": _VPILL[t["status"]]} for t in _gt], _items))
    _done = sum(1 for t in _ts if t["status"] == "done")
    _pct = round(100 * _done / max(1, len(_ts)))
    _vk["crit"] += len(_cs)
    _vk["crit_met"] += sum(1 for c in _cs if norm(c.get("status")) == "met")
    _vsections.append(
        f'<section class="chapter ch-{_VLETTER.get(_b["biome"], "R")}"><header><h2>{E(_b["feature"])} · {E(_b["title"])}</h2>'
        f'<span class="chpct">{_pct}%</span></header>{"".join(_cards)}</section>')
_vparked = sum(1 for v_ in _vu.values() if v_ == "parked")
_vcodex = {t["id"]: t["status"] for b_ in vcat["biomes"] for t in b_["tasks"] if t["owner"] == "Codex"}
_vclaude = {t["id"]: t["status"] for b_ in vcat["biomes"] for t in b_["tasks"] if t["owner"] != "Codex"}
_vlegend = "".join(f'<span class="leg">{_vpill(k)} {sum(1 for v_ in _vu.values() if v_ == k)}</span>' for k in ("done", "open", "parked"))
visual_html = (
    '<div class="kpis">'
    f'<div class="kpi"><b>{_vdone} / {len(_vu)}</b><span>Catalog tasks done (each row once across biomes)</span></div>'
    f'<div class="kpi"><b>{sum(1 for v_ in _vcodex.values() if v_ == "done")} / {len(_vcodex)}</b><span>Scene, mesh, material, lighting and camera tasks done</span></div>'
    f'<div class="kpi"><b>{sum(1 for v_ in _vclaude.values() if v_ == "done")} / {len(_vclaude)}</b><span>UI and creature-pose tasks done</span></div>'
    f'<div class="kpi"><b>{_vk["crit_met"]} / {_vk["crit"]}</b><span>F38–F41 criteria met</span></div>'
    f'<div class="kpi"><b>{_vparked}</b><span>Tasks parked (need a fresh approach)</span></div>'
    '</div>'
    f'<div class="legend">{_vlegend}</div>'
    '<section class="panel"><h2>About this tab</h2><p class="note">Each biome pass is its own feature: its top-20 catalog rows, then every other row over impact 12, '
    'each fixed to the full bar with a before/after code-blind PASS on main, then a full matrix and defect scan. Codex owns scene, mesh, material, lighting and camera rows; '
    'UI rows go to Claude (F42) and creature-pose rows to Claude (F36#1). Planned last, after the main delivery plan; the plan is at the bottom of this tab. '
    f'Defects from ralph/reports/VISUAL/phase2/catalog.csv; status from the board (GPU-judged, owner 24 Oct), so this tab and Acceptance agree.</p></section>'
    + "".join(_vsections) + vplan_html)

# ---- visual catalogue tab (owner 27 Oct) -----------------------------------
# "Give me the full visual catalogue with their current score in a tab": every
# visual criterion (F36, F38-F41 and the visual rows of other features) with its
# status and the latest score recorded in its evidence. The score is read from the
# evidence text: the first GPU-judged figure when there is one, else the CPU figure;
# "a -> b" reads as b, "m / h" as Medium / High. Rows with no figure say so.
import re as _re
_NUM = r"(\d\.\d{1,2})(?![\d.]|\s*(?:m\b|%|s\b|x\b))"
_ARROW = _re.compile(_NUM + r"\s*(?:->|→|-&gt;)\s*\**" + _NUM + r"(?:\s*/\s*" + _NUM + r")?")
_PAIR = _re.compile(_NUM + r"\s*/\s*" + _NUM)
_ONE = _re.compile(_NUM)


def _score(ev):
    ev = str(ev or "")
    for src, seg in (("GPU", ev[ev.find("GPU"):] if "GPU" in ev else ""), ("CPU", ev)):
        if not seg:
            continue
        seg = seg[:420]
        m = _ARROW.search(seg)
        vals = [m.group(2), m.group(3)] if m else None
        if not vals:
            m = _PAIR.search(seg)
            vals = [m.group(1), m.group(2)] if m else None
        if not vals:
            m = _ONE.search(seg)
            vals = [m.group(1)] if m else None
        if vals:
            nums = [float(v) for v in vals if v and 3.0 <= float(v) <= 9.9]
            if nums:
                return nums, src
    return None, ""


# Categories for the executive summary (owner 27 Oct: "buckets by biome or category
# then score buckets so I can quickly tell where everything is at").
_VCATS = [("models", "Creature models", "F36 (0)"), ("poses", "Creature poses", "F36 (1)"),
          ("F38", "Meadows", "F38"), ("F39", "Tidewake", "F39"), ("F40", "Cloudreach", "F40"),
          ("F41", "Stormwood", "F41"), ("other", "Earlier features", "F04-F26")]
_BUCKETS = [("met", "Met", "closed"), ("b75", "At bar", "7.5+, open"), ("b70", "Close", "7.0–7.49"),
            ("b60", "Mid", "6.0–6.99"), ("b50", "Low", "5.0–5.99"), ("b00", "Far", "< 5.0"),
            ("none", "Unscored", "no own score")]


def _vcat(fid, x):
    if fid == "F36":
        return "poses" if str(x.get("text", "")).startswith("F36 (1)") else "models"
    return fid if fid in ("F38", "F39", "F40", "F41") else "other"


def _bucket(st, sc):
    if st == "met":
        return "met"
    if not sc:
        return "none"
    v = min(sc)
    return "b75" if v >= 7.5 else "b70" if v >= 7.0 else "b60" if v >= 6.0 else "b50" if v >= 5.0 else "b00"


def _short(sel, x):
    t = str(x.get("text", ""))
    m = _re.match(r"F36 \(1\) ([\w ]+?):", t)
    if m:
        return m.group(1).replace("_", " ").title() + " poses"
    m = _re.match(r"F36 \(0\) priority asset #\d+: (.+?) (?:regenerated|confirmed)", t)
    if m:
        return _re.sub(r"\s*\(.*?\)", "", m.group(1)) + " model"
    m = _re.match(r"F\d+ \(\d\) [^:]*?item (P2-\d+) ([^:]+):", t)
    if m:
        return f"{m.group(1)} {m.group(2).strip()}"
    t = _re.sub(r"^F\d+(#\d+)? · ", "", t)
    return (t[:80] + "…") if len(t) > 80 else t


_vitems = []
for _fid in ("F36", "F38", "F39", "F40", "F41"):
    for _n, x in enumerate(rows.get(_fid, {}).get("criteria", [])):
        _vitems.append((f"{_fid}#{_n}", _fid, x))
for _sel in VISUAL_OTHER:
    _f, _, _i = _sel.partition("#")
    _c = rows.get(_f, {}).get("criteria", [])
    if _i.isdigit() and int(_i) < len(_c):
        _vitems.append((_sel, _f, _c[int(_i)]))
_vrows = []
for _sel, _fid, x in _vitems:
    st = norm(x.get("status"))
    sc, src = _score(x.get("evidence"))
    _isc = x.get("item_scores") or {}
    if _isc:
        # Per-item GPU scores (tb/item-scores job): the row closes only when every biome it
        # touches passes, so it buckets on its lowest biome score.
        sc = [min(v["mapped"] for v in _isc.values())]
        src = "GPU item: " + ", ".join(f'{b.title()} {v["mapped"]:.2f}{"*" if v.get("low_confidence") else ""}'
                                       for b, v in _isc.items())
    _vrows.append({"sel": _sel, "cat": _vcat(_fid, x), "name": _short(_sel, x), "st": st, "sc": sc,
                   "src": src, "bk": _bucket(st, sc), "text": str(x.get("text", ""))})
_bk_order = [k for k, _l, _r in _BUCKETS]


def _cnt(rs, k):
    return sum(1 for r_ in rs if r_["bk"] == k)


def _sc_txt(r_):
    return " / ".join(f"{v:.2f}" for v in r_["sc"]) if r_["sc"] else "—"


# 1. Matrix: category rows x score-bucket columns, a part-to-whole bar per row.
_mx_head = "".join(f'<th class="num mxh"><span class="bk bk-{k}"></span>{E(l)}<span class="mxr">{E(r_)}</span></th>' for k, l, r_ in _BUCKETS)
_mx_rows = []
for _ck, _cl, _cid in _VCATS + [("all", "All visual", "")]:
    rs = _vrows if _ck == "all" else [r_ for r_ in _vrows if r_["cat"] == _ck]
    if not rs:
        continue
    n = len(rs)
    segs = "".join(f'<span class="vseg bk-{k}" style="flex:{_cnt(rs, k)}" title="{E(l)}: {_cnt(rs, k)} of {n}"></span>'
                   for k, l, _r in _BUCKETS if _cnt(rs, k))
    cells = "".join(f'<td class="num{" zero" if not _cnt(rs, k) else ""}" title="{E(_cl)} · {E(l)}: {_cnt(rs, k)}">{_cnt(rs, k) or "·"}</td>' for k, l, _r in _BUCKETS)
    _mx_rows.append(f'<tr class="{"mx-total" if _ck == "all" else ""}"><th scope="row">{E(_cl)}<span class="meta"> {E(_cid)}</span></th>'
                    f'<td class="num">{n}</td>{cells}<td class="mxbar"><span class="vbar">{segs}</span></td></tr>')
_matrix = ('<section class="panel"><h2>Where everything is</h2>'
           '<p class="note">Every visual criterion, by area and by its latest score (the lower of Medium / High; GPU where judged, else CPU). '
           '"At bar": scored 7.5 or above but its row is not closed yet. "Unscored": no score of its own yet. "GPU item": the per-item GPU job, one-sided, lowest biome counts; * marks a low-confidence batch.</p>'
           '<div class="tbl"><table class="mx"><thead><tr><th>Area</th><th class="num">Items</th>' + _mx_head + '<th>Spread</th></tr></thead>'
           f'<tbody>{"".join(_mx_rows)}</tbody></table></div></section>')

# 2. Closest to the bar: open items with a score, highest first.
_close = sorted([r_ for r_ in _vrows if r_["st"] != "met" and r_["sc"]], key=lambda r_: -min(r_["sc"]))[:15]
_catname = {k: l for k, l, _c in _VCATS}
_close_html = ('<section class="panel"><h2>Closest to the bar</h2><p class="note">The 15 open items with the highest scores: the next close-outs. "At bar" items already score 7.5 or above on what was judged; their row stays open until its remaining parts (a water form, a travel pose, the other preset) are judged.</p>'
               '<div class="tbl"><table><thead><tr><th>Item</th><th>Area</th><th class="num">Score</th><th class="num">To 7.5</th><th>Judge</th></tr></thead><tbody>'
               + "".join(f'<tr><td>{E(r_["name"])}</td><td>{E(_catname[r_["cat"]])}</td><td class="num">{E(_sc_txt(r_))}</td>'
                         f'<td class="num">{"at bar" if min(r_["sc"]) >= 7.5 else f"{7.5 - min(r_["sc"]):.2f}"}</td><td>{E(r_["src"])}</td></tr>' for r_ in _close)
               + '</tbody></table></div></section>')

# 3. Detail per area, collapsed, sorted by score.
_vtabs = []
for _ck, _cl, _cid in _VCATS:
    rs = sorted([r_ for r_ in _vrows if r_["cat"] == _ck],
                key=lambda r_: (r_["st"] != "met", -(min(r_["sc"]) if r_["sc"] else -1), r_["name"]))
    if not rs:
        continue
    m = sum(1 for r_ in rs if r_["st"] == "met")
    p_ = round(100 * m / len(rs))
    trs = "".join(
        f'<tr><td><span class="bk bk-{r_["bk"]}"></span>{E(r_["name"])}<div class="meta" title="{E(r_["text"])}"><code>{E(r_["sel"])}</code></div></td>'
        f'<td class="num">{E(_sc_txt(r_))}</td><td>{E(r_["src"])}</td><td>{pill(r_["st"])}</td></tr>' for r_ in rs)
    _vtabs.append(
        f'<details class="frow"><summary><span class="fid">{E(_cid.split(" ")[0])}</span><span class="ftitle">{E(_cl)}</span>'
        f'<span class="fnum">{m}/{len(rs)} met</span>{bar(p_)}<span class="fpct">{p_}%</span>'
        f'<span class="stack" aria-hidden="true">{"".join(f"<span class=\'vseg bk-{k}\' style=\'flex:{_cnt(rs, k)}\'></span>" for k in _bk_order if _cnt(rs, k))}</span></summary>'
        '<div class="tbl vtbl"><table><thead><tr><th>Item</th><th class="num">Score</th><th>Judge</th><th>Status</th></tr></thead>'
        f'<tbody>{trs}</tbody></table></div></details>')
_STANDS = [
    ("F38 Meadows", "Relay yard, band3 river lock 0", "5.93 / 5.93", "GPU MH4 (+1.43), landed #769"),
    ("F38 Meadows", "Ridgeline Watch", "6.40 / 6.40", "GPU MH7 (+1.64), landed #763"),
    ("F38 Meadows", "Stronghold approach and courtyard (mean)", "5.33 / 5.96", "GPU MH9 (+0.53 / +0.71), landed #771"),
    ("F39 Tidewake", "Sluice Isle pumps (shore)", "6.68 / 6.68", "GPU TW1 (+1.33), landed #766"),
    ("F39 Tidewake", "Shellwatch rescue jetty", "6.56 / 6.56", "GPU TW1 (+1.15), landed #766"),
    ("F41 Stormwood", "Ashfoot shelter, inside", "6.76 / 6.76", "GPU SW20b one-batch re-judge, landed #770"),
    ("F41 Stormwood", "Crown Overlook", "5.85 / 5.85", "GPU SW18 (+0.86), landed #764"),
    ("F41 Stormwood", "All 12 outdoor stands (mean)", "5.74 / 5.73", "GPU SW19 control"),
]
_stand_html = ('<section class="panel"><h2>Latest GPU stand scores</h2><p class="note">The GPU judges whole scenes (a stand: one place, several views and phases), '
    'not single catalogue items, so many items above have no score of their own yet. These are the latest stand scores, Medium / High.</p>'
    '<div class="tbl"><table><thead><tr><th>Biome</th><th>Stand</th><th>Score</th><th>Source</th></tr></thead><tbody>'
    + "".join(f"<tr><td>{E(a)}</td><td>{E(b)}</td><td class=\"num\">{E(c_)}</td><td>{E(d)}</td></tr>" for a, b, c_, d in _STANDS)
    + '</tbody></table></div></section>')
_n_met = sum(1 for r_ in _vrows if r_["st"] == "met")
_n_close = sum(1 for r_ in _vrows if r_["bk"] == "b70")
_n_bar = sum(1 for r_ in _vrows if r_["bk"] == "b75")
_n_none = sum(1 for r_ in _vrows if r_["bk"] == "none")
visual_tab_html = (
    '<div class="kpis">'
    f'<div class="kpi"><b>{_n_met} / {len(_vrows)}</b><span>Visual items met (7.5 or above on the GPU)</span></div>'
    f'<div class="kpi"><b>{_n_bar + _n_close}</b><span>Near: open and scoring 7.0 or above</span></div>'
    f'<div class="kpi"><b>{len(_vrows) - _n_met - _n_bar - _n_close - _n_none}</b><span>Open and below 7.0</span></div>'
    f'<div class="kpi"><b>{_n_none}</b><span>No score of their own yet</span></div>'
    '</div>'
    + _matrix + _close_html + _stand_html
    + '<section class="chapter ch-V"><header><h2>Every item, by area</h2></header>' + "".join(_vtabs) + '</section>'
    + '<details class="frow"><summary><span class="fid">P2</span><span class="ftitle">Catalogue defect detail and owners</span></summary>'
      '<div class="vtbl">' + visual_html + '</div></details>')


# A complete document (owner report, 2026-09-30): the board is also served raw by
# hosts that add no wrapper, where a missing charset turns "·" into "Â·", a missing
# viewport shrinks the page on phones, and a missing doctype falls into quirks mode.
page = f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Tetherbound Acceptance Board</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,600;12..96,750&family=Figtree:wght@400;500;600&family=JetBrains+Mono:wght@400;600&display=swap">
<style>
:root{{
  --bg:#f3f5f1; --panel:#ffffff; --ink:#1c2420; --muted:#5d6a63; --line:#d9e0da;
  --meadows:#4f8a3c; --cloud:#3f7fb3; --storm:#6b55a8; --tide:#1f8a86; --redesign:#b0602a;
  --met:#2f8a4a; --partial:#b7861a; --prog:#3b74c4; --fail:#c2413b; --block:#9a4fa0; --none:#8a948e;
  --tint-met:#e3f2e6; --tint-partial:#f7eed8; --tint-prog:#e2ecf8; --tint-fail:#f8e2e0; --tint-block:#f1e3f2; --tint-none:#eceeec;
  --accent:#27594a;
}}
@media (prefers-color-scheme: dark){{ :root:not([data-theme="light"]){{
  color-scheme:dark; --bg:#121815; --panel:#1a221e; --ink:#e4ebe6; --muted:#9aa8a0; --line:#2d3833;
  --tint-met:#1d3325; --tint-partial:#352c16; --tint-prog:#1b2b40; --tint-fail:#3a1f1d; --tint-block:#321f35; --tint-none:#252c28;
  --met:#6cc787; --partial:#e2b44b; --prog:#79a8ea; --fail:#ef7c75; --block:#c98fd0; --none:#9aa49e; --accent:#8fd0b8;
}} }}
:root[data-theme="dark"]{{
  color-scheme:dark; --bg:#121815; --panel:#1a221e; --ink:#e4ebe6; --muted:#9aa8a0; --line:#2d3833;
  --tint-met:#1d3325; --tint-partial:#352c16; --tint-prog:#1b2b40; --tint-fail:#3a1f1d; --tint-block:#321f35; --tint-none:#252c28;
  --met:#6cc787; --partial:#e2b44b; --prog:#79a8ea; --fail:#ef7c75; --block:#c98fd0; --none:#9aa49e; --accent:#8fd0b8;
}}
body{{background:var(--bg);color:var(--ink);font:15px/1.5 Figtree,system-ui,sans-serif;padding-inline:16px;padding-block:24px 48px}}
.wrap{{max-width:1080px;margin:0 auto;display:grid;gap:28px}}
h1,h2,h3{{font-family:"Bricolage Grotesque",Figtree,system-ui,sans-serif;text-wrap:balance;margin:0}}
h1{{font-size:clamp(26px,4vw,36px);font-weight:750;letter-spacing:-.01em}}
h2{{font-size:20px;font-weight:700}} h3{{font-size:16px;font-weight:700}}
.eyebrow{{font:600 12px/1 "JetBrains Mono",monospace;letter-spacing:.08em;text-transform:uppercase;color:var(--muted)}}
.meta{{color:var(--muted);font-size:13px}} code{{font:12.5px "JetBrains Mono",monospace}}
.top{{display:grid;gap:10px}}
.kpis{{display:grid;grid-template-columns:repeat(auto-fit,minmax(170px,1fr));gap:12px}}
.kpi{{background:var(--panel);border:1px solid var(--line);border-radius:10px;padding:14px 16px;display:grid;gap:4px}}
.kpi b{{font:750 30px/1.1 "Bricolage Grotesque",sans-serif;font-variant-numeric:tabular-nums}}
.kpi span{{color:var(--muted);font-size:13px}}
.legend{{display:flex;flex-wrap:wrap;gap:10px 16px;font-variant-numeric:tabular-nums}}
.leg{{display:inline-flex;gap:6px;align-items:center;font-size:13px}}
.pill{{display:inline-block;font:600 11px/1 "JetBrains Mono",monospace;letter-spacing:.04em;text-transform:uppercase;padding:5px 7px;border-radius:5px;white-space:nowrap}}
.pill.s-met{{background:var(--tint-met);color:var(--met)}} .pill.s-partial{{background:var(--tint-partial);color:var(--partial)}}
.pill.s-in_progress{{background:var(--tint-prog);color:var(--prog)}} .pill.s-failing{{background:var(--tint-fail);color:var(--fail)}}
.pill.s-blocked{{background:var(--tint-block);color:var(--block)}} .pill.s-not_started{{background:var(--tint-none);color:var(--none)}}
.chapter{{display:grid;gap:8px}}
.chapter header{{display:flex;align-items:baseline;gap:12px;border-bottom:3px solid var(--chc);padding-bottom:6px}}
.chpct{{font:600 14px "JetBrains Mono",monospace;color:var(--chc)}}
.ch-M{{--chc:var(--meadows)}} .ch-C{{--chc:var(--cloud)}} .ch-S{{--chc:var(--storm)}} .ch-T{{--chc:var(--tide)}} .ch-R{{--chc:var(--redesign)}} .ch-V{{--chc:var(--storm)}} .ch-B{{--chc:var(--block)}}
.vtbl{{padding:0 14px 14px}} .vtbl td:first-child{{min-width:220px}} .vtbl .meta{{font-size:11.5px}}
.bk-met{{--bk:var(--met)}} .bk-b75{{--bk:color-mix(in srgb,var(--met) 80%,var(--panel))}} .bk-b70{{--bk:color-mix(in srgb,var(--met) 45%,var(--panel))}} .bk-b60{{--bk:var(--partial)}} .bk-b50{{--bk:color-mix(in srgb,var(--fail) 70%,var(--panel))}} .bk-b00{{--bk:var(--fail)}} .bk-none{{--bk:var(--tint-none)}}
span.bk{{display:inline-block;width:10px;height:10px;border-radius:3px;background:var(--bk);margin-right:6px;vertical-align:-1px;border:1px solid var(--line)}}
.vseg{{background:var(--bk);display:block}} .vbar{{display:flex;gap:2px;height:12px;border-radius:4px;overflow:hidden;min-width:160px}}
.mx th[scope=row]{{font:600 14px Figtree,sans-serif;color:var(--ink);text-transform:none;letter-spacing:0;white-space:nowrap}}
.mx td.num{{font:600 15px "JetBrains Mono",monospace}} .mx td.zero{{color:var(--line)}} .mx tr.mx-total td,.mx tr.mx-total th{{border-top:2px solid var(--ink)}} .mxbar{{width:26%}} th.mxh{{white-space:nowrap}} .mxr{{display:block;font-weight:400;text-transform:none;letter-spacing:0;font-size:10.5px;margin-top:2px}} .tabs{{flex-wrap:wrap}}
.frow{{background:var(--panel);border:1px solid var(--line);border-radius:10px}}
.frow summary{{list-style:none;cursor:pointer;display:grid;grid-template-columns:44px minmax(0,1fr) auto 120px 44px;grid-template-areas:"id title num meter pct" "id stack stack stack stack";gap:6px 12px;align-items:center;padding:12px 14px}}
.frow summary::-webkit-details-marker{{display:none}}
.frow summary:focus-visible{{outline:2px solid var(--accent);outline-offset:2px;border-radius:10px}}
.fid{{grid-area:id;font:600 14px "JetBrains Mono",monospace;color:var(--chc)}}
.ftitle{{grid-area:title;font-weight:600}} .fnum{{grid-area:num;color:var(--muted);font-size:13px;font-variant-numeric:tabular-nums;white-space:nowrap}}
.fpct{{grid-area:pct;text-align:right;font:600 14px "JetBrains Mono",monospace;font-variant-numeric:tabular-nums}}
.meter{{grid-area:meter;height:8px;border-radius:4px;background:var(--tint-none);overflow:hidden;display:block}}
.meter span{{display:block;height:100%;background:var(--chc)}}
.stack{{grid-area:stack;display:flex;height:4px;border-radius:2px;overflow:hidden;gap:2px}}
.seg.s-met{{background:var(--met)}} .seg.s-partial{{background:var(--partial)}} .seg.s-in_progress{{background:var(--prog)}}
.seg.s-failing{{background:var(--fail)}} .seg.s-blocked{{background:var(--block)}} .seg.s-not_started{{background:var(--none)}}
.crits{{margin:0;padding:0 14px 14px 58px;display:grid;gap:10px}}
.crit{{padding:10px 12px;border-radius:8px;border:1px solid var(--line)}}
.crit.sub{{padding:0;border:none}} .crit.sub .frow{{border-color:var(--line)}} .crit.sub .crits{{padding-left:14px}}
.crit-head{{display:flex;gap:10px;align-items:flex-start}} .crit-text{{font-weight:500}}
.crit dl{{margin:8px 0 0;display:grid;gap:4px;font-size:13.5px}}
.crit dl div{{display:grid;grid-template-columns:86px minmax(0,1fr);gap:8px}}
.crit dt{{color:var(--muted);font:600 11px/1.9 "JetBrains Mono",monospace;text-transform:uppercase;letter-spacing:.05em}}
.crit dd{{margin:0}}
.panel{{background:var(--panel);border:1px solid var(--line);border-radius:10px;padding:16px;display:grid;gap:10px}}
.tbl{{overflow-x:auto}} table{{border-collapse:collapse;width:100%;font-size:14px}}
th,td{{text-align:left;padding:8px 10px;border-bottom:1px solid var(--line);vertical-align:top}}
th{{font:600 11px "JetBrains Mono",monospace;text-transform:uppercase;letter-spacing:.05em;color:var(--muted)}}
.two{{display:grid;grid-template-columns:repeat(auto-fit,minmax(300px,1fr));gap:16px}}
ul.plain{{margin:0;padding-left:18px;display:grid;gap:6px}}
.note{{font-size:13px;color:var(--muted)}}
.tabs{{display:flex;gap:6px;border-bottom:1px solid var(--line)}}
.tabs label{{font:600 14px Figtree,sans-serif;padding:8px 14px;border-radius:8px 8px 0 0;cursor:pointer;color:var(--muted);border:1px solid transparent;border-bottom:none}}
.tabsel{{position:absolute;opacity:0;pointer-events:none}}
#tab-vis:checked ~ .tabs label[for=tab-vis], #tab-acc:checked ~ .tabs label[for=tab-acc], #tab-plan:checked ~ .tabs label[for=tab-plan], #tab-lanes:checked ~ .tabs label[for=tab-lanes]{{color:var(--ink);background:var(--panel);border-color:var(--line)}}
#tab-vis:focus-visible ~ .tabs label[for=tab-vis], #tab-acc:focus-visible ~ .tabs label[for=tab-acc], #tab-plan:focus-visible ~ .tabs label[for=tab-plan], #tab-lanes:focus-visible ~ .tabs label[for=tab-lanes]{{outline:2px solid var(--accent)}}
.pane{{display:none;gap:28px;grid-template-columns:minmax(0,1fr)}} .wrap,.panel{{grid-template-columns:minmax(0,1fr)}} #tab-vis:checked ~ .pane-vis, #tab-acc:checked ~ .pane-acc, #tab-plan:checked ~ .pane-plan, #tab-lanes:checked ~ .pane-lanes{{display:grid}}
.gscroll{{overflow-x:auto}} .gantt{{min-width:980px;display:grid;gap:6px}}
.glane{{display:grid;grid-template-columns:190px minmax(0,1fr);gap:10px;align-items:center}}
.gname{{font-weight:600;font-size:13px;display:grid}} .gname .meta{{font-weight:400;font-size:11.5px}}
.gtrack{{position:relative;height:30px;background:var(--tint-none);border-radius:6px}}
.gday{{position:absolute;top:0;bottom:0;border-left:1px solid var(--line)}}
.gcount{{font-weight:400;opacity:.8}}
.gsum{{display:flex;flex-wrap:wrap;gap:24px}} .gsum div{{display:grid;gap:2px}} .gsum b{{font-size:18px}}
.gnowlist{{margin:0;padding-left:18px;display:grid;gap:6px}}
.ghead .gtrack{{background:none;height:34px;margin-top:12px}}
.gs{{position:absolute;top:0;display:grid;font-size:11px;color:var(--muted);padding-left:4px;border-left:1px solid var(--line);white-space:nowrap}}
.gs b{{font:600 12px "JetBrains Mono",monospace;color:var(--ink)}}
.gnow{{position:absolute;top:0;bottom:-600px;border-left:2px solid var(--fail);z-index:3;pointer-events:none}}
.gnow span{{position:absolute;top:-14px;left:-12px;font:600 10px "JetBrains Mono",monospace;color:var(--fail);text-transform:uppercase}}
.gbar{{position:absolute;top:3px;height:24px;border-radius:5px;overflow:hidden;background:var(--tc-tint);border:1px solid var(--tc)}}
.gfill{{position:absolute;inset:0 auto 0 0;background:var(--tc);opacity:.45}}
.glabel{{position:relative;display:block;font:600 11.5px system-ui,sans-serif;padding:0 6px;line-height:22px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;color:var(--ink)}}
.t-done{{--tc:var(--met);--tc-tint:var(--tint-met)}} .t-on_track{{--tc:var(--prog);--tc-tint:var(--tint-prog)}}
.t-behind{{--tc:var(--partial);--tc-tint:var(--tint-partial)}} .t-late{{--tc:var(--fail);--tc-tint:var(--tint-fail)}}
.t-planned{{--tc:var(--none);--tc-tint:var(--tint-none)}} .t-early{{--tc:var(--block);--tc-tint:var(--tint-block)}}
.tpill{{display:inline-block;font:600 11px/1 "JetBrains Mono",monospace;text-transform:uppercase;letter-spacing:.04em;padding:5px 7px;border-radius:5px;background:var(--tc-tint);color:var(--tc);white-space:nowrap}}
.glegend{{display:flex;flex-wrap:wrap;gap:8px}} td.num{{font-variant-numeric:tabular-nums;text-align:right}}
@media (max-width:640px){{
  .frow summary{{grid-template-columns:40px minmax(0,1fr) 44px;grid-template-areas:"id title pct" "id meter meter" "id num num" "id stack stack"}}
  .crits{{padding-left:14px}} .crit dl div{{grid-template-columns:1fr}}
}}
@media (prefers-reduced-motion:no-preference){{ .meter span{{transition:width .4s ease}} }}
</style>
</head>
<body>
<main class="wrap">
  <input type="radio" name="tab" id="tab-acc" class="tabsel" checked>
  <input type="radio" name="tab" id="tab-plan" class="tabsel">
  <input type="radio" name="tab" id="tab-lanes" class="tabsel">
  <input type="radio" name="tab" id="tab-vis" class="tabsel">
  <div class="top">
    <span class="eyebrow">Project update · F01–{E(last_id)} acceptance</span>
    <h1>Tetherbound Acceptance Board</h1>
    <p class="meta">Updated {E(crit.get("generated_at") or status.get("updated", ""))} · main <code>{E(crit.get("main_sha", ""))}</code> · batch in flight <code>{E(crit.get("batch4_sha", ""))}</code> · rebuilt hourly by the coordinator</p>
  </div>
  <nav class="tabs" aria-label="Board views"><label for="tab-acc">Acceptance</label><label for="tab-vis">Visual catalogue</label><label for="tab-plan">Delivery plan</label><label for="tab-lanes">Active lanes</label></nav>
  <div class="pane pane-plan">{plan_html}</div>
  <div class="pane pane-lanes">{active_lanes_html}</div>
  <div class="pane pane-vis">{visual_tab_html}</div>
  <div class="pane pane-acc">
  <div class="kpis">
    <div class="kpi"><b>{accepted} / {len(crit["rows"])}</b><span>F rows accepted (every criterion met)</span></div>
    <div class="kpi"><b>{len(all_c) - counts["met"]}</b><span>Criteria not done: {_open_by["F36"]} creatures (F36), {_open_by["look"]} biome looks (F38–F41), {_open_by["other"]} everything else</span></div>
    <div class="kpi"><b>{counts["met"]} / {len(all_c)}</b><span>Criteria met on main</span></div>
    <div class="kpi"><b>{redesign_met} / {len(redesign_c)}</b><span>Redesign criteria met (F16 onward)</span></div>
    <div class="kpi"><b>{counts["failing"] + counts["blocked"]}</b><span>Criteria failing or blocked</span></div>
  </div>
  <div class="legend">{legend}</div>
  <section class="panel"><h2>This hour</h2><ul class="plain">{li(status.get("headline", []))}</ul></section>
  {''.join(chapter_html)}
  <section class="panel"><h2>Chapter exit cards</h2><p class="note">Integrated continuous-path gates; required even when every F row passes. Progress = 80% feeder criteria met (weighted) + 20% for the integrated continuous run with its evidence card.</p>
    <div class="tbl"><table><thead><tr><th>Card</th><th>Progress</th><th>Feeder criteria</th><th>Integrated run</th><th>Note</th></tr></thead><tbody>{cards_tbl}</tbody></table></div></section>
  <section class="panel"><h2>Release-wide requirements</h2>
    <div class="tbl"><table><thead><tr><th>Requirement</th><th>Status</th><th>Note</th></tr></thead><tbody>{cc}</tbody></table></div></section>
  <section class="panel"><h2>Shortcut debt</h2><p class="note">Criteria closed under the relaxed-proof rule, and what each proof skipped. The chapter-exit and release playthroughs must exercise every row; a failure there points at the row. High = a sub-part not proven anywhere else. A passing chapter-card run retires its feeders\u2019 route shortcuts; harness input needs a human play pass; the final four-chapter run retires chapter-boundary fixture starts. <b>{debt_summary}</b></p>
    <div class="tbl"><table><thead><tr><th>Risk</th><th>Criterion</th><th>Chapter exit</th><th>Criterion text</th><th>Debt kind</th><th>State</th><th>Disclosed shortcuts</th></tr></thead><tbody>{debt_tbl}</tbody></table></div></section>
  <section class="panel"><h2>Integration batches</h2>
    <div class="tbl"><table><thead><tr><th>Batch</th><th>SHA</th><th>State</th><th>Contents</th></tr></thead><tbody>{batches}</tbody></table></div></section>
  <section class="panel"><h2>Lanes</h2>
    <div class="tbl"><table><thead><tr><th>Lane</th><th>Working on</th><th>Next</th></tr></thead><tbody>{lanes}</tbody></table></div></section>
  {lane_activity_section}
  <div class="two">
    <section class="panel"><h3>Decisions made</h3><ul class="plain">{li(status.get("decisions", []))}</ul></section>
    <section class="panel"><h3>Needs the owner</h3><ul class="plain">{li(status.get("owner_needs", []))}</ul></section>
  </div>
  <p class="note">Status is strict: fixture-only proof counts as partial, visual criteria need a passing code-blind judge verdict, and co-op criteria need two-peer evidence. Percentages are the coordinator's evidence audit, not a measured play-through.</p>
  </div>
</main>
</body>
</html>
"""
(HERE / "tetherbound_dashboard.html").write_text(page, encoding="utf-8")
print("wrote", HERE / "tetherbound_dashboard.html", "overall", overall, "counts", counts)
