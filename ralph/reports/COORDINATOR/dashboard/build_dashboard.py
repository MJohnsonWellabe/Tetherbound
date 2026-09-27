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
crit = json.loads((HERE / "criteria.json").read_text())
status = json.loads((HERE / "status.json").read_text())

E = html.escape
ORDER = ["met", "partial", "in_progress", "failing", "blocked", "not_started"]
LABEL = {"met": "Met", "partial": "Partial", "in_progress": "In progress",
         "failing": "Failing", "blocked": "Blocked", "not_started": "Not started"}
CHAPTERS = [("Meadows", "M", ["F01", "F02", "F03", "F04", "F05"]),
            ("Cloudreach", "C", ["F06", "F07", "F08"]),
            ("Stormwood", "S", ["F09", "F10", "F11"]),
            ("Tidewake", "T", ["F12", "F13", "F14", "F15"])]


def norm(s):
    s = (s or "not_started").strip().lower().replace(" ", "_").replace("-", "_")
    return s if s in LABEL else "partial"


def pct(row):
    c = row.get("criteria", [])
    if not c:
        return int(row.get("pct", 0))
    w = {"met": 1.0, "partial": 0.5, "in_progress": 0.25}
    return round(100 * sum(w.get(norm(x.get("status")), 0) for x in c) / len(c))


rows = {r["id"]: r for r in crit["rows"]}
all_c = [x for r in crit["rows"] for x in r.get("criteria", [])]
counts = {k: sum(1 for x in all_c if norm(x.get("status")) == k) for k in ORDER}
overall = round(sum(pct(r) for r in crit["rows"]) / max(1, len(crit["rows"])))
accepted = sum(1 for r in crit["rows"] if r.get("criteria") and all(norm(x.get("status")) == "met" for x in r["criteria"]))


def bar(p):
    return f'<span class="meter" role="img" aria-label="{p}% of criteria evidenced"><span style="width:{p}%"></span></span>'


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
cards_tbl = "".join(
    f'<tr><td>{E(x["id"])}</td><td>{pill(x.get("status"))}</td><td>{E(x.get("note", ""))}</td></tr>'
    for x in crit.get("chapter_cards", []))


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
debt_rows.sort(key=lambda t: (SEV_ORDER[t[0]], t[1], t[2]))
debt_tbl = "".join(
    f'<tr><td>{E(sev)}</td><td>{E(rid)}#{i}</td><td>{E(CHAPTER_OF.get(rid, ""))}</td><td>{E(text)}</td><td>{E(", ".join(kinds))}</td><td>{E(disc)}</td></tr>'
    for sev, rid, i, text, kinds, disc in debt_rows)
lanes = "".join(
    f'<tr><td>{E(l["lane"])}</td><td>{E(l.get("now", ""))}</td><td>{E(l.get("next", ""))}</td></tr>'
    for l in status.get("lanes", []))
legend = "".join(f'<span class="leg">{pill(k)} {counts[k]}</span>' for k in ORDER)

page = f"""<title>Tetherbound Acceptance Board</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,600;12..96,750&family=Figtree:wght@400;500;600&family=JetBrains+Mono:wght@400;600&display=swap">
<style>
:root{{
  --bg:#f3f5f1; --panel:#ffffff; --ink:#1c2420; --muted:#5d6a63; --line:#d9e0da;
  --meadows:#4f8a3c; --cloud:#3f7fb3; --storm:#6b55a8; --tide:#1f8a86;
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
.ch-M{{--chc:var(--meadows)}} .ch-C{{--chc:var(--cloud)}} .ch-S{{--chc:var(--storm)}} .ch-T{{--chc:var(--tide)}}
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
@media (max-width:640px){{
  .frow summary{{grid-template-columns:40px minmax(0,1fr) 44px;grid-template-areas:"id title pct" "id meter meter" "id num num" "id stack stack"}}
  .crits{{padding-left:14px}} .crit dl div{{grid-template-columns:1fr}}
}}
@media (prefers-reduced-motion:no-preference){{ .meter span{{transition:width .4s ease}} }}
</style>
<main class="wrap">
  <div class="top">
    <span class="eyebrow">Project update · F01–F15 acceptance</span>
    <h1>Tetherbound Acceptance Board</h1>
    <p class="meta">Updated {E(status.get("updated", crit.get("generated_at", "")))} · main <code>{E(crit.get("main_sha", ""))}</code> · batch in flight <code>{E(crit.get("batch4_sha", ""))}</code> · rebuilt hourly by the coordinator</p>
  </div>
  <div class="kpis">
    <div class="kpi"><b>{accepted} / 15</b><span>F rows accepted (every criterion met)</span></div>
    <div class="kpi"><b>{overall}%</b><span>Criteria evidenced, weighted (met 1, partial ½, in progress ¼)</span></div>
    <div class="kpi"><b>{counts["met"]} / {len(all_c)}</b><span>Atomic criteria fully met</span></div>
    <div class="kpi"><b>{counts["failing"] + counts["blocked"]}</b><span>Criteria failing or blocked</span></div>
  </div>
  <div class="legend">{legend}</div>
  <section class="panel"><h2>This hour</h2><ul class="plain">{li(status.get("headline", []))}</ul></section>
  {''.join(chapter_html)}
  <section class="panel"><h2>Chapter exit cards</h2><p class="note">Integrated continuous-path gates; required even when every F row passes.</p>
    <div class="tbl"><table><thead><tr><th>Card</th><th>Status</th><th>Note</th></tr></thead><tbody>{cards_tbl}</tbody></table></div></section>
  <section class="panel"><h2>Release-wide requirements</h2>
    <div class="tbl"><table><thead><tr><th>Requirement</th><th>Status</th><th>Note</th></tr></thead><tbody>{cc}</tbody></table></div></section>
  <section class="panel"><h2>Shortcut debt</h2><p class="note">Criteria closed under the relaxed-proof rule, and what each proof skipped. The chapter-exit and release playthroughs must exercise every row; a failure there points at the row. High = a sub-part not proven anywhere else.</p>
    <div class="tbl"><table><thead><tr><th>Risk</th><th>Criterion</th><th>Chapter exit</th><th>Criterion text</th><th>Debt kind</th><th>Disclosed shortcuts</th></tr></thead><tbody>{debt_tbl}</tbody></table></div></section>
  <section class="panel"><h2>Integration batches</h2>
    <div class="tbl"><table><thead><tr><th>Batch</th><th>SHA</th><th>State</th><th>Contents</th></tr></thead><tbody>{batches}</tbody></table></div></section>
  <section class="panel"><h2>Lanes</h2>
    <div class="tbl"><table><thead><tr><th>Lane</th><th>Working on</th><th>Next</th></tr></thead><tbody>{lanes}</tbody></table></div></section>
  <div class="two">
    <section class="panel"><h3>Decisions made</h3><ul class="plain">{li(status.get("decisions", []))}</ul></section>
    <section class="panel"><h3>Needs the owner</h3><ul class="plain">{li(status.get("owner_needs", []))}</ul></section>
  </div>
  <p class="note">Status is strict: fixture-only proof counts as partial, visual criteria need a passing code-blind judge verdict, and co-op criteria need two-peer evidence. Percentages are the coordinator's evidence audit, not a measured play-through.</p>
</main>
"""
(HERE / "tetherbound_dashboard.html").write_text(page)
print("wrote", HERE / "tetherbound_dashboard.html", "overall", overall, "counts", counts)
