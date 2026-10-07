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
chapter_html = []
for name, letter, ids in CHAPTERS:
    cards = []
    for fid in ids:
        r = rows.get(fid)
        if not r:
            continue
        p = pct(r)
        cs = r.get("criteria", [])
        met = sum(1 for x in cs if norm(x.get("status")) == "met")
        items = "".join(
            f'<li class="crit s-{norm(x.get("status"))}"><div class="crit-head">{pill(x.get("status"))}'
            f'<span class="crit-text">{E(x.get("text", ""))}</span></div>'
            f'<dl><div><dt>Evidence</dt><dd>{E(x.get("evidence") or "None recorded")}</dd></div>'
            f'<div><dt>Remaining</dt><dd>{E(x.get("gap") or "Nothing")}</dd></div></dl></li>'
            for x in cs)
        cards.append(
            f'<details class="frow" id="{fid}"><summary>'
            f'<span class="fid">{fid}</span><span class="ftitle">{E(r.get("title", ""))}</span>'
            f'<span class="fnum">{met}/{len(cs)} met</span>{bar(p)}<span class="fpct">{p}%</span>{stack(cs)}'
            f'</summary><ol class="crits">{items}</ol></details>')
    ch_rows = [rows[i] for i in ids if i in rows]
    ch_pct = round(sum(pct(r) for r in ch_rows) / max(1, len(ch_rows)))
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
# Owner request 2026-10-04: a frozen baseline of five lanes x 8-hour sprints,
# tracked live. plan.json holds the bars; progress is read from criteria.json.
import datetime as _dt
_plan_path = HERE / "plan.json"
plan_html = ""
if _plan_path.exists():
    plan = json.loads(_plan_path.read_text(encoding="utf-8"))
    p_start = _dt.datetime.fromisoformat(plan["start"].replace("Z", "+00:00"))
    p_hours = float(plan.get("sprint_hours", 8))
    n_sprints = int(plan["sprints"])
    now = _dt.datetime.now(_dt.timezone.utc)
    now_pos = (now - p_start).total_seconds() / 3600.0 / p_hours
    W = {"met": 1.0}  # owner 2026-10-06: fill is met criteria only

    def _items(f):
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
        done = sum(1 for x in cs if norm(x.get("status")) in ("met", "blocked"))
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
        return t.astimezone(_CT).strftime("%a %d %b %-I:%M %p")

    TRACK = {"done": "Done", "on_track": "On track", "behind": "Behind", "late": "Late",
             "planned": "Planned", "early": "Started early"}
    track_rows, lane_html, counts_t = [], [], {}
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
            left, width = 100 * s0 / n_sprints, 100 * (e0 - s0) / n_sprints
            tip = (f'{b["label"]}: {fmt(at(s0))} to {fmt(at(e0))} {at(s0).tzname()}. '
                   f'{done}/{n} criteria done or owner-blocked, {actual:.0f}% met (expected now {expected:.0f}%). {TRACK[st]}.')
            bars.append(
                f'<div class="gbar t-{st}" style="left:{left:.3f}%;width:{width:.3f}%" title="{E(tip)}">'
                f'<span class="gfill" style="width:{actual:.0f}%"></span>'
                f'<span class="glabel">{E(b["label"].split(" ")[0])}</span></div>')
            track_rows.append(
                f'<tr class="t-{st}"><td>{E(lane["id"])}</td><td>{E(b["label"])}</td>'
                f'<td>S{int(s0) + 1}{"½" if s0 % 1 else ""} → S{int(e0 - 0.001) + 1}{"½" if e0 % 1 else ""}'
                f'<br><span class="meta">{fmt(at(s0))} → {fmt(at(e0))}</span></td>'
                f'<td class="num">{done}/{n}</td><td class="num">{base:.0f}%</td><td class="num">{expected:.0f}%</td>'
                f'<td class="num">{actual:.0f}%</td><td><span class="tpill t-{st}">{TRACK[st]}</span></td>'
                f'<td>{E(", ".join(b.get("depends", [])))}{(" · " + E(b["note"])) if b.get("note") else ""}</td></tr>')
        lane_html.append(
            f'<div class="glane"><div class="gname">{E(lane["name"])}<span class="meta">{E(lane.get("session", ""))}</span></div>'
            f'<div class="gtrack">{"".join(bars)}</div></div>')
    heads = "".join(
        f'<div class="gs" style="left:{100 * i / n_sprints:.3f}%;width:{100 / n_sprints:.3f}%">'
        f'<b>S{i + 1}</b><span>{at(i).strftime("%a %-I %p")}</span></div>' for i in range(n_sprints))
    now_html = (f'<div class="gnow" style="left:{100 * now_pos / n_sprints:.3f}%"><span>now</span></div>'
                if 0 <= now_pos <= n_sprints else "")
    cur = int(now_pos) + 1 if now_pos >= 0 else 0
    # Finish = end of the last lane bar (owner-only items follow it; owner 2026-10-07).
    finish = at(max(float(b["end"]) for l in plan["lanes"] if l.get("id") != "owner" for b in l["bars"]))
    tsum = " · ".join(f'{TRACK[k]} {v}' for k, v in counts_t.items())
    plan_html = f"""
  <section class="panel gantt-panel" aria-labelledby="plan-h"><h2 id="plan-h">Delivery plan</h2>
    <p class="meta">Baseline set {E(plan.get("baseline_set", ""))} · sprint = {p_hours:.0f} h, back to back from {fmt(p_start)} {at(0).tzname()} ·
      now in <b>sprint {cur} of {n_sprints}</b> · planned finish {fmt(finish)} {finish.tzname()} · {E(tsum)}</p>
    <p class="note">Each bar is a feature a lane takes to done (every criterion met or blocked on the owner). The darker fill is the share of that bar's
      criteria met now (partial, in-progress and blocked add nothing). Status compares it with a straight-line expectation from the bar's frozen starting progress: within 15 points is on track.
      Past its end and not done is late.</p>
    <div class="gscroll"><div class="gantt">
      <div class="glane ghead"><div class="gname"></div><div class="gtrack">{heads}{now_html}</div></div>
      {"".join(lane_html)}
    </div></div>
    <div class="glegend">{"".join(f'<span class="tpill t-{k}">{v}</span>' for k, v in TRACK.items())}</div>
    <div class="tbl"><table><thead><tr><th>Lane</th><th>Feature</th><th>Planned window</th><th>Criteria</th><th>At baseline</th><th>Expected now</th><th>Actual</th><th>Status</th><th>Depends on / notes</th></tr></thead>
    <tbody>{"".join(track_rows)}</tbody></table></div>
    <p class="note">Rebaselines: {E("; ".join(plan.get("rebaselines", [])) or "none")}.</p>
  </section>"""

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
.ch-M{{--chc:var(--meadows)}} .ch-C{{--chc:var(--cloud)}} .ch-S{{--chc:var(--storm)}} .ch-T{{--chc:var(--tide)}} .ch-R{{--chc:var(--redesign)}}
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
#tab-acc:checked ~ .tabs label[for=tab-acc], #tab-plan:checked ~ .tabs label[for=tab-plan]{{color:var(--ink);background:var(--panel);border-color:var(--line)}}
#tab-acc:focus-visible ~ .tabs label[for=tab-acc], #tab-plan:focus-visible ~ .tabs label[for=tab-plan]{{outline:2px solid var(--accent)}}
.pane{{display:none;gap:28px;grid-template-columns:minmax(0,1fr)}} .wrap,.panel{{grid-template-columns:minmax(0,1fr)}} #tab-acc:checked ~ .pane-acc, #tab-plan:checked ~ .pane-plan{{display:grid}}
.gscroll{{overflow-x:auto}} .gantt{{min-width:880px;display:grid;gap:6px}}
.glane{{display:grid;grid-template-columns:190px minmax(0,1fr);gap:10px;align-items:center}}
.gname{{font-weight:600;font-size:13px;display:grid}} .gname .meta{{font-weight:400;font-size:11.5px}}
.gtrack{{position:relative;height:30px;background:repeating-linear-gradient(90deg,var(--tint-none) 0 1px,transparent 1px calc(100%/13));border-radius:6px}}
.ghead .gtrack{{background:none;height:34px;margin-top:12px}}
.gs{{position:absolute;top:0;display:grid;font-size:11px;color:var(--muted);padding-left:4px;border-left:1px solid var(--line)}}
.gs b{{font:600 12px "JetBrains Mono",monospace;color:var(--ink)}}
.gnow{{position:absolute;top:0;bottom:-600px;border-left:2px solid var(--fail);z-index:3;pointer-events:none}}
.gnow span{{position:absolute;top:-14px;left:-12px;font:600 10px "JetBrains Mono",monospace;color:var(--fail);text-transform:uppercase}}
.gbar{{position:absolute;top:3px;height:24px;border-radius:5px;overflow:hidden;background:var(--tc-tint);border:1px solid var(--tc)}}
.gfill{{position:absolute;inset:0 auto 0 0;background:var(--tc);opacity:.45}}
.glabel{{position:relative;font:600 11px "JetBrains Mono",monospace;padding:0 5px;line-height:22px;white-space:nowrap;color:var(--ink)}}
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
  <div class="top">
    <span class="eyebrow">Project update · F01–{E(last_id)} acceptance</span>
    <h1>Tetherbound Acceptance Board</h1>
    <p class="meta">Updated {E(status.get("updated", crit.get("generated_at", "")))} · main <code>{E(crit.get("main_sha", ""))}</code> · batch in flight <code>{E(crit.get("batch4_sha", ""))}</code> · rebuilt hourly by the coordinator</p>
  </div>
  <nav class="tabs" aria-label="Board views"><label for="tab-acc">Acceptance</label><label for="tab-plan">Delivery plan</label></nav>
  <div class="pane pane-plan">{plan_html}</div>
  <div class="pane pane-acc">
  <div class="kpis">
    <div class="kpi"><b>{accepted} / {len(crit["rows"])}</b><span>F rows accepted (every criterion met)</span></div>
    <div class="kpi"><b>{overall}%</b><span>Criteria met, averaged across features (met criteria only)</span></div>
    <div class="kpi"><b>{counts["met"]} / {len(all_c)}</b><span>Criteria met: {counts["met"] - evidenced_only} on main, {evidenced_only} evidenced on lane branches</span></div>
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
