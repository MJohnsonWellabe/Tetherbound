import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {ROOT, sourceReport} from './economy_ledger.mjs';
import {TIME_BUDGET_LOW_HOURS} from './f27_route_ledger.mjs';

// F47#2 four-character contention census. Data-only: every count comes from the
// same configs scripts/world/renewable_site_catalog.gd and essence_node_catalog.gd read.
// Contention: renewable and essence sites are WORLD stock ("scope":"world"), so
// four characters share one claim per respawn; supply never multiplies by party
// size. Only claim_policy "character_once" rows are per-character (x4, once).
// Formula per site: harvests = 1 + floor(route_days / respawn_days), where
// route_days = band route hours (f27 TIME_BUDGET_LOW_HOURS, PROGRESSION §4 lower
// bound) * 60 / (art.json day_length_seconds / 60), the clock that advances
// Game.day; sleeping adds days and is ignored (conservative). This assumes every
// site is revisited on every respawn: an UPPER bound. first_pass_supply (one claim
// per site) is the lower bound. One-time pickups count once if marked
// (one_time:true / existing_world_pickup_policy); meadows non-policy harvest rows
// (berry bushes) count once per harvest.json _comment_renewable. Farm: world plots,
// sows <= min(seeds, plots * floor(route_days / grow_days)) per crop (each crop
// capped independently: optimistic); berry seeds = vendor stock, counted once in
// the first band; typed seeds = floor(essence harvests * seed_drop.chance) (expected
// value). Shed drops (shed_drops.json, chance-based wild victories) and encounter_cycle
// rows are not sites and are not counted. Demand: economy_ledger four_character_raw
// (contention(): personal x4 + shared once, forge-expanded to raw), max over the
// homogeneous type rows per material at each upgrade; the verdict uses gear.max_upgrade
// because the boss-assumed upgrade (F33#2) is unmeasured. Earlier bands' surplus
// carries forward (inputs may be reachable "in or before" their biome).
export function supplyCensus(root = ROOT, report = sourceReport(root), characters = 4) {
  const read = p => JSON.parse(fs.readFileSync(path.join(root, p)));
  const order = read('data/config/biome_order.json');
  const dayMinutes = read('data/config/art.json').day_length_seconds / 60;
  const gear = read('data/config/gear.json');
  const harvest = read('data/config/harvest.json'), water = read('data/config/water_pickups.json');
  const cloudPolicy = read('data/config/cloudreach_resources.json').renewable;
  const cloud = read('data/config/cloudreach_chapter.json');
  const storm = read('data/config/stormwood_harvests.json'), stormPickups = read('data/config/stormwood_pickups.json');
  const essence = read('data/config/essence_nodes.json'), farm = read('data/config/farm.json');
  const trade = read('data/config/trade.json');
  const realmOf = biome => order.runtime_aliases?.[biome] ?? biome;
  const sites = Object.fromEntries(order.live.map(b => [realmOf(b), []]));
  const put = (realm, id, outputs, respawn_days, kind, copies = 1) => sites[realm].push({id, outputs, respawn_days, kind, copies});
  const ordinary = (realm, policy, id, item, n) => policy.materials.includes(item) ?
    put(realm, id, {[item]: n}, policy.material_respawn_days, 'renewable') : null;
  const extras = (realm, config) => {
    const block = config.additional_material_node_candidates;
    if (block?.runtime_enabled) for (const r of block.nodes) if (r.terrain_and_player_path_proven === true &&
      config.renewable.materials.includes(r.item)) put(realm, r.id, {[r.item]: r.amount}, r.respawn_days, 'renewable');
  };
  for (const band of read('data/config/chapter_curve.json').regions.map(r => r.id))
    for (const r of read(`data/config/bands/${band}/harvest.json`).nodes)
      if (harvest.renewable.materials.includes(r.item)) ordinary('meadows', harvest.renewable, `order:${r.order}`, r.item, r.amount);
      else put('meadows', `order:${r.order}`, {[r.item]: r.amount}, null, 'world_once');
  extras('meadows', harvest);
  for (const r of water.harvest) {
    if (r.claim_policy === 'character_once') put('water', r.id, {[r.item_id]: r.yield}, null, 'character_once', characters);
    else if (r.claim_policy === 'existing_world_pickup_policy') put('water', r.id, {[r.item_id]: r.yield}, null, 'world_once');
    else ordinary('water', water.renewable, r.id, r.item_id, r.yield);
  }
  for (const p of water.pickups) if (p.claim_policy === 'existing_world_pickup_policy') put('water', p.id, {[p.item_id]: p.quantity}, null, 'world_once');
  extras('water', water);
  for (const r of cloud.resource_tier.nodes) if (r.respawn_policy === 'world_day_regrow') ordinary('cloudreach', cloudPolicy, r.id, r.resource_id, r.amount);
  for (const p of cloud.pickups) if (p.one_time === true) put('cloudreach', p.id, {[p.item_id]: p.count}, null, 'world_once');
  for (const r of storm.sites) ordinary('stormwood', storm.renewable, r.id, r.item, r.amount);
  for (const p of stormPickups.pickups) if (p.one_time === true) put('stormwood', p.id, {[p.item_id]: p.count}, null, 'world_once');
  if (essence.runtime_enabled) for (const n of essence.nodes) if (sites[n.realm])
    sites[n.realm].push({id: n.id, outputs: n.outputs, respawn_days: n.respawn_days ?? essence.respawn_days, kind: 'essence', copies: 1, seed: n.seed_drop});
  const seedVendorStock = Object.values(trade.vendors).reduce((s, v) => s + (v.goods?.[farm.seed_item]?.stock ?? 0), 0);
  const tally = (into, outputs, k) => { for (const [id, n] of Object.entries(outputs)) into[id] = (into[id] ?? 0) + n * k; };
  const bands = [], shortfalls = [], carries = Array.from({length: gear.max_upgrade + 1}, () => ({}));
  order.live.forEach((biome, index) => {
    const realm = realmOf(biome), hours = TIME_BUDGET_LOW_HOURS[biome];
    if (!Number.isFinite(hours) || !(dayMinutes > 0)) throw Error(`Missing route hours/day length for ${biome}`);
    const routeDays = hours * 60 / dayMinutes, supply = {}, firstPass = {}, seeds = {};
    for (const s of sites[realm]) {
      const claims = s.respawn_days ? 1 + Math.floor(routeDays / s.respawn_days) : 1;
      tally(supply, s.outputs, claims * s.copies); tally(firstPass, s.outputs, s.copies);
      if (s.seed) seeds[s.seed.item] = (seeds[s.seed.item] ?? 0) + s.seed.amount * claims * s.seed.chance;
    }
    if (farm.runtime_enabled) for (const crop of Object.values(farm.crops)) {
      const have = crop.seed_item === farm.seed_item ? (index === 0 ? seedVendorStock : 0) : Math.floor(seeds[crop.seed_item] ?? 0);
      tally(supply, crop.outputs, Math.min(have, farm.plots.length * Math.floor(routeDays / crop.grow_days)));
    }
    const verdicts = {};
    for (let upgrade = 0; upgrade <= gear.max_upgrade; upgrade++) {
      const demand = {};
      for (const row of report.materials.filter(m => m.biome === biome && m.upgrade === upgrade))
        for (const [id, n] of Object.entries(row.four_character_raw)) demand[id] = Math.max(demand[id] ?? 0, n);
      const last = upgrade === gear.max_upgrade, bal = carries[upgrade];
      const rows = Object.entries(demand).map(([material, need]) => {
        const available = (bal[material] ?? 0) + (supply[material] ?? 0);
        const row = {material, demand: need, supply_in_band: supply[material] ?? 0, carry_in: bal[material] ?? 0,
          available, first_pass_supply: firstPass[material] ?? 0, ratio: need ? +(available / need).toFixed(3) : null,
          solvent: available >= need, no_source_in_band: !supply[material]};
        bal[material] = Math.max(0, available - need);
        if (last && !row.solvent) shortfalls.push({band: biome, material, demand: need, supply: available, shortfall: need - available});
        return row;
      });
      for (const [id, n] of Object.entries(supply)) if (!(id in demand)) bal[id] = (bal[id] ?? 0) + n;
      verdicts[upgrade] = {solvent: rows.every(r => r.solvent), materials: rows};
    }
    bands.push({band: biome, realm, route_hours: hours, route_days: routeDays, sites: sites[realm].length,
      site_kinds: sites[realm].reduce((o, s) => ({...o, [s.kind]: (o[s.kind] ?? 0) + 1}), {}),
      supply, solvent: verdicts[gear.max_upgrade].solvent, verdict_upgrade: gear.max_upgrade,
      materials: verdicts[gear.max_upgrade].materials,
      solvent_by_upgrade: Object.fromEntries(Object.entries(verdicts).map(([u, v]) => [u, v.solvent]))});
  });
  return {schema_version: 1, characters, day_minutes: dayMinutes,
    scope: 'source-generated upper-bound supply vs four-character demand; not an earned route', bands, shortfalls,
    solvent: bands.every(b => b.solvent)};
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const args = process.argv.slice(2), i = args.indexOf('--out');
  const json = JSON.stringify(supplyCensus(), null, 2) + '\n';
  if (i >= 0) fs.writeFileSync(args[i + 1], json); else process.stdout.write(json);
}
