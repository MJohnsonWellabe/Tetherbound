import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {ROOT, sourceReport} from './economy_ledger.mjs';
import {TIME_BUDGET_LOW_HOURS, TEAM_SIZE, ORDINARY_WILD_SITE_FRACTION, loadSources, buildRoute, engagedSites} from './f27_route_ledger.mjs';

// F47#2 four-character contention census. Data-only; no number here is authored.
// SUPPLY per band (labelled per source in `sources`):
// - renewable_site / essence_node / ripplet_node: WORLD stock ("scope":"world"), one
//   claim per respawn shared by all four: claims = 1 + floor(route_days / respawn_days),
//   route_days = f27 TIME_BUDGET_LOW_HOURS (PROGRESSION §4 lower bound) * 60 / (art.json
//   day_length_seconds / 60). Assumes every revisit (upper bound); sleep days ignored.
// - one_time: pickups/caches marked one_time / existing_world_pickup_policy, meadows
//   non-policy harvest rows (harvest.json _comment_renewable: berry bushes once per world),
//   Burrow Warrens clear reward + wall deposits (paid once against warrens_cleared),
//   Cloudreach trainer reward_tiers by rank, water_local_chains grants. Counted ONCE
//   (conservative: per-participant trainer payouts are not assumed).
// - character_once harvest rows and master_chest (masters.json preparation_supplies +
//   attuned_per_creature x TEAM_SIZE for the party's own types, breakthrough.gd
//   _master_supplies, "once-per-character Master chest receipt"): x characters.
// - vendor: trade.json stocked goods, once, in the first band (restock unverified).
// - bounty_expected: personal boards (board_count per host morning per character):
//   floor(route_days) * board_count * characters * mean reward of the band's templates,
//   with material_delivery slots credited ZERO (optional; a player declines a delivery
//   that would spend a needed input, so neither its reward nor its cost is counted).
// conversions: recipes whose output is a demanded raw material are listed; their
//   outputs (wood/fiber/stone) are never short, so they are not propagated.
// - farm: sows <= min(seeds, plots * floor(route_days / grow_days)) per crop
//   (independent caps, optimistic); berry seeds = vendor stock in band 1 only; typed
//   seeds = floor(essence claims * seed_drop.chance).
// - shed_expected: floor(wild_win_chance * wild_amount * bodies of that species in
//   f27 engagedSites(main-path sites, ORDINARY_WILD_SITE_FRACTION)) for shed_drops
//   species whose wild_realms include the band. Expected value, one drop per victory.
// DEMAND (required): economy_ledger four_character_raw (personal x4 + shared once,
// forge-expanded) at upgrade 0: gear.json declares no boss-required upgrade
// (boss_proof is UNRUN); +1 is reported because masters.json _preparation_supplies is
// sized for +1. Feasts are one per creature per Master of the band. attuned_* is
// POOLED: each feast needs its creature's type and the Master chest pays the party's
// own types, so the pooled total is mix-independent; per-type (mono-team) is reported
// with chest attuned assignable to that type. "max" = old worst case at gear.max_upgrade.
// Earlier bands' surplus carries forward (balance floored at 0 per band).
const POOL = 'attuned_*', pool = id => id.startsWith('attuned_') ? POOL : id;
export function supplyCensus(root = ROOT, report = sourceReport(root), characters = 4) {
  const read = p => JSON.parse(fs.readFileSync(path.join(root, p)));
  const order = read('data/config/biome_order.json'), gear = read('data/config/gear.json');
  const dayMinutes = read('data/config/art.json').day_length_seconds / 60;
  const harvest = read('data/config/harvest.json'), water = read('data/config/water_pickups.json');
  const cloudPolicy = read('data/config/cloudreach_resources.json').renewable, cloud = read('data/config/cloudreach_chapter.json');
  const storm = read('data/config/stormwood_harvests.json'), stormPickups = read('data/config/stormwood_pickups.json');
  const essence = read('data/config/essence_nodes.json'), farm = read('data/config/farm.json'), trade = read('data/config/trade.json');
  const masters = read('data/config/masters.json').masters, warrens = read('data/config/burrow_warrens.json');
  const cloudRewards = read('data/config/cloudreach_encounters.json').reward_tiers, shed = read('data/config/shed_drops.json');
  const realmOf = b => order.runtime_aliases?.[b] ?? b, biomeOf = r => order.live.find(b => realmOf(b) === r);
  const sites = Object.fromEntries(order.live.map(b => [realmOf(b), []])), fixed = Object.fromEntries(order.live.map(b => [b, []]));
  const put = (realm, id, outputs, respawn_days, kind, copies = 1) => sites[realm].push({id, outputs, respawn_days, kind, copies});
  const give = (biome, kind, outputs, copies = 1) => fixed[biome].push({kind, outputs, copies});
  const items = list => Object.fromEntries(list.map(i => [i.id, i.count ?? i.n]));
  const ordinary = (realm, policy, id, item, n) => policy.materials.includes(item) && put(realm, id, {[item]: n}, policy.material_respawn_days, 'renewable_site');
  const extras = (realm, config) => { const block = config.additional_material_node_candidates;
    if (block?.runtime_enabled) for (const r of block.nodes) if (r.terrain_and_player_path_proven === true &&
      config.renewable.materials.includes(r.item)) put(realm, r.id, {[r.item]: r.amount}, r.respawn_days, 'renewable_site'); };
  for (const band of read('data/config/chapter_curve.json').regions.map(r => r.id))
    for (const r of read(`data/config/bands/${band}/harvest.json`).nodes)
      if (harvest.renewable.materials.includes(r.item)) ordinary('meadows', harvest.renewable, `order:${r.order}`, r.item, r.amount);
      else put('meadows', `order:${r.order}`, {[r.item]: r.amount}, null, 'one_time');
  extras('meadows', harvest);
  for (const r of water.harvest) {
    if (r.claim_policy === 'character_once') put('water', r.id, {[r.item_id]: r.yield}, null, 'character_once', characters);
    else if (r.claim_policy === 'existing_world_pickup_policy') put('water', r.id, {[r.item_id]: r.yield}, null, 'one_time');
    else ordinary('water', water.renewable, r.id, r.item_id, r.yield);
  }
  for (const p of water.pickups) if (p.claim_policy === 'existing_world_pickup_policy') put('water', p.id, {[p.item_id]: p.quantity}, null, 'one_time');
  extras('water', water);
  for (const s of read('data/config/ripplet_traversal.json').sites)
    put('water', s.id, s.outputs ?? {[s.item]: s.count}, s.kind === 'node' ? s.respawn_days : null, s.kind === 'node' ? 'ripplet_node' : 'one_time');
  for (const r of cloud.resource_tier.nodes) if (r.respawn_policy === 'world_day_regrow') ordinary('cloudreach', cloudPolicy, r.id, r.resource_id, r.amount);
  for (const p of cloud.pickups) if (p.one_time === true) put('cloudreach', p.id, {[p.item_id]: p.count}, null, 'one_time');
  for (const r of storm.sites) ordinary('stormwood', storm.renewable, r.id, r.item, r.amount);
  for (const p of stormPickups.pickups) if (p.one_time === true) put('stormwood', p.id, {[p.item_id]: p.count}, null, 'one_time');
  if (essence.runtime_enabled) for (const n of essence.nodes) if (sites[n.realm])
    sites[n.realm].push({id: n.id, outputs: n.outputs, respawn_days: n.respawn_days ?? essence.respawn_days, kind: 'essence_node', copies: 1, seed: n.seed_drop});
  for (const m of masters) give(m.biome, 'master_chest', {...m.preparation_supplies, [POOL]: m.attuned_per_creature * TEAM_SIZE}, characters);
  give(biomeOf('meadows'), 'one_time', items(warrens.clear.reward.items));
  for (const d of warrens.deposits) give(biomeOf('meadows'), 'one_time', {[d.item]: d.amount});
  for (const t of cloud.trainer_ladder) give(biomeOf('cloudreach'), 'one_time', items(cloudRewards[t.rank]?.items ?? []));
  for (const s of read('data/config/water_local_chains.json').steps) if (s.grant) give(biomeOf('water'), 'one_time', s.grant);
  for (const v of Object.values(trade.vendors)) for (const [id, g] of Object.entries(v.goods ?? {}))
    if (g.stock > 0 && g.buy > 0 && id !== farm.seed_item) give(order.live[0], 'vendor', {[id]: g.stock});
  if (shed.runtime_enabled) { const f27 = loadSources(root);
    for (const r of buildRoute(f27)) for (const site of engagedSites(r.sites, ORDINARY_WILD_SITE_FRACTION)) for (const b of site.bodies ?? []) {
      const row = shed.species[b.species];
      if (row?.wild_realms.includes(realmOf(r.biome))) give(r.biome, 'shed_expected', {[row.item]: shed.wild_win_chance * row.wild_amount});
    } }
  const bounties = read('data/config/bounties.json'), bountyNet = {};
  if (bounties.runtime_enabled) for (const biome of order.live) { const t = bounties.templates.filter(x => x.biome === biome), net = bountyNet[biome] = {};
    for (const x of t) if (x.kind !== 'material_delivery') for (const r of x.rewards) net[r.id] = (net[r.id] ?? 0) + r.n / t.length; }
  const recipeBooks = [...fs.readdirSync(path.join(root, 'data/recipes')).filter(f => f.endsWith('.json')).map(f => read(`data/recipes/${f}`).recipes), gear.recipes,
    read('data/config/water_crafting.json').recipes, read('data/config/stormwood_items_recipes.json').recipes];
  const raw = new Set(report.materials.flatMap(m => Object.keys(m.four_character_raw)));
  const conversions = recipeBooks.flatMap(b => Object.entries(b ?? {})).filter(([, r]) => raw.has(r?.output?.id)).map(([id, r]) => ({recipe: id, output: r.output.id}));
  const seedStock = Object.values(trade.vendors).reduce((s, v) => s + (v.goods?.[farm.seed_item]?.stock ?? 0), 0);
  const demandAt = (biome, upgrade, worst) => { const out = {};
    for (const row of report.materials.filter(m => m.biome === biome && m.upgrade === upgrade && (worst || m.type === report.materials[0].type)))
      for (const [id, n] of Object.entries(row.four_character_raw)) out[pool(id)] = Math.max(out[pool(id)] ?? 0, n);
    return out; };
  const scenarios = {required: 0, upgrade_1: 1, max: gear.max_upgrade}, carry = {required: {}, upgrade_1: {}, max: {}};
  const bands = [], shortfalls = [], max_shortfalls = [];
  order.live.forEach((biome, index) => {
    const realm = realmOf(biome), hours = TIME_BUDGET_LOW_HOURS[biome];
    if (!Number.isFinite(hours) || !(dayMinutes > 0)) throw Error(`Missing route hours/day length for ${biome}`);
    const routeDays = hours * 60 / dayMinutes, supply = {}, typed = {}, sources = {}, seeds = {};
    const tally = (outputs, k, kind) => { for (const [id, n] of Object.entries(outputs)) { const p = pool(id);
      supply[p] = (supply[p] ?? 0) + n * k; (sources[p] ??= {})[kind] = (sources[p][kind] ?? 0) + n * k;
      if (p === POOL && id !== POOL) typed[id] = (typed[id] ?? 0) + n * k; } };
    for (const s of sites[realm]) {
      const claims = s.respawn_days ? 1 + Math.floor(routeDays / s.respawn_days) : 1;
      tally(s.outputs, claims * s.copies, s.kind);
      if (s.seed) seeds[s.seed.item] = (seeds[s.seed.item] ?? 0) + s.seed.amount * claims * s.seed.chance;
    }
    for (const f of fixed[biome]) tally(f.outputs, f.copies, f.kind);
    tally(bountyNet[biome] ?? {}, Math.floor(routeDays) * bounties.board_count * characters, 'bounty_expected');
    for (const id of Object.keys(sources)) for (const kind of ['shed_expected', 'bounty_expected']) if (sources[id][kind]) {
      const whole = Math.floor(sources[id][kind]); supply[id] -= sources[id][kind] - whole; sources[id][kind] = whole; }
    if (farm.runtime_enabled) for (const crop of Object.values(farm.crops)) {
      const have = crop.seed_item === farm.seed_item ? (index === 0 ? seedStock : 0) : Math.floor(seeds[crop.seed_item] ?? 0);
      tally(crop.outputs, Math.min(have, farm.plots.length * Math.floor(routeDays / crop.grow_days)), 'farm');
    }
    const out = {band: biome, realm, route_hours: hours, route_days: routeDays, sites: sites[realm].length,
      site_kinds: sites[realm].reduce((o, s) => ({...o, [s.kind]: (o[s.kind] ?? 0) + 1}), {}), supply, sources};
    for (const [name, upgrade] of Object.entries(scenarios)) {
      const demand = demandAt(biome, upgrade, name === 'max'), bal = carry[name];
      const materials = Object.entries(demand).map(([material, need]) => {
        const available = (bal[material] ?? 0) + (supply[material] ?? 0), solvent = available >= need;
        const row = {material, demand: need, supply_in_band: supply[material] ?? 0, carry_in: bal[material] ?? 0, available,
          shortfall: Math.max(0, need - available), ratio: +(available / need).toFixed(3), solvent, sources: sources[material] ?? {}};
        bal[material] = Math.max(0, available - need);
        if (!solvent && name !== 'upgrade_1') (name === 'max' ? max_shortfalls : shortfalls).push({band: biome, material, demand: need, supply: available, shortfall: need - available});
        return row; });
      for (const [id, n] of Object.entries(supply)) if (!(id in demand)) bal[id] = (bal[id] ?? 0) + n;
      out[name] = {upgrade, solvent: materials.every(m => m.solvent), materials};
    }
    const chest = sources[POOL]?.master_chest ?? 0, mono = out.required.materials.find(m => m.material === POOL)?.demand ?? 0;
    out.attuned_by_type = Object.fromEntries(Object.entries(typed).map(([id, n]) => [id, {mono_team_demand: mono, supply: n + chest, solvent: n + chest >= mono}]));
    out.solvent = out.required.solvent;
    bands.push(out);
  });
  return {schema_version: 2, characters, day_minutes: dayMinutes, scope: 'source-generated supply vs four-character required demand; not an earned route',
    conversions, uncounted: ['shed_drops den_grooming: once per owned uid per host day, depends on owning galecrest/sparkit/staticub',
      'rematches repeat_materials: gated on each biome climax_flag (post-boss)', 'cloudreach encounter_cycle skyplume nodes: encounter producer, not a site'],
    bands, shortfalls, max_shortfalls, solvent: bands.every(b => b.solvent)};
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const args = process.argv.slice(2), i = args.indexOf('--out');
  const json = JSON.stringify(supplyCensus(), null, 2) + '\n';
  if (i >= 0) fs.writeFileSync(args[i + 1], json); else process.stdout.write(json);
}
