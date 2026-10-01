"""F30 owned content; no shared-file writes or engine invocation."""
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
ROWS = [
    ('bold','common','charged_power',.05,'Charged moves deal 5% more damage.'),
    ('calm','common','wind_regen',.05,'Wind regenerates 5% faster.'),
    ('sturdy','common','defence',.05,'Effective defence increases by 5%.'),
    ('swift','common','combat_speed',.05,'Move 5% faster in combat.'),
    ('gentle','common','healing',.05,'Receive 5% more healing.'),
    ('stubborn','common','poise',.05,'Poise threshold increases by 5%.'),
    ('curious','common','cooldown',-.05,'Move cooldowns are 5% shorter.'),
    ('watchful','common','burst_cost',-.05,'Burst costs 5% less Wind.'),
    ('hardy','common','max_hp',.05,'Maximum HP increases by 5%.'),
    ('keen','common','quick_power',.05,'Quick moves deal 5% more damage.'),
    ('surefoot','common','ride_speed',.05,'Ride 5% faster.'),
    ('paddler','common','swim_speed',.05,'Mounted swimming is 5% faster.'),
    ('fierce','rare','charged_power',.08,'Charged moves deal 8% more damage.'),
    ('composed','rare','wind_regen',.08,'Wind regenerates 8% faster.'),
    ('resolute','rare','defence',.08,'Effective defence increases by 8%.'),
    ('nimble','rare','combat_speed',.08,'Move 8% faster in combat.'),
    ('renewing','rare','healing',.08,'Receive 8% more healing.'),
    ('unshaken','rare','poise',.08,'Poise threshold increases by 8%.'),
    ('inventive','rare','cooldown',-.08,'Move cooldowns are 8% shorter.'),
    ('vigilant','rare','burst_cost',-.08,'Burst costs 8% less Wind.'),
    ('current_rider','rare','swim_speed',.08,'Mounted swimming is 8% faster.'),
    ('soaring','rare','fly_speed',.08,'Fly 8% faster.'),
    ('precise','epic','quick_power',.12,'Quick moves deal 12% more damage.'),
    ('ferocious','epic','charged_power',.12,'Charged moves deal 12% more damage.'),
    ('radiant','epic','ultimate_power',.12,'Ultimate moves deal 12% more damage.'),
    ('unyielding','epic','defence',.12,'Effective defence increases by 12%.'),
    ('tireless','epic','wind_regen',.12,'Wind regenerates 12% faster.'),
    ('fleet','epic','combat_speed',.12,'Move 12% faster in combat.'),
    ('tide_dancer','epic','swim_speed',.12,'Mounted swimming is 12% faster.'),
    ('sky_dancer','epic','fly_speed',.12,'Fly 12% faster.'),
]
config = {
    'version': 1, 'rarities': {'common': .05, 'rare': .08, 'epic': .12},
    'maximum_rolled': 3, 'aggregate_effect_limit': .30,
    'bond_reveal_nodes': 5, 'slot_breakthrough_tiers': [1,3,5],
    'essence_cost_per_slot': 10, 'maximum_transaction_receipts': 4096,
    'profiles': {
        'ordinary': {'count_weights': [45,38,14,3], 'rarity_weights': [82,16,2]},
        'unusual': {'count_weights': [20,38,30,12], 'rarity_weights': [64,29,7]},
        'alpha': {'count_weights': [5,20,43,32], 'rarity_weights': [45,40,15]},
        'alpha_unusual': {'count_weights': [2,12,40,46], 'rarity_weights': [35,44,21]},
    },
    'traits': {id: {'display_name': id.replace('_',' ').title(), 'rarity': rarity,
                    'effect': effect, 'magnitude': value, 'description': desc,
                    'seed_item': 'trait_seed_'+id}
               for id,rarity,effect,value,desc in ROWS},
}
ROOT.joinpath('data/config/traits.json').write_text(json.dumps(config,indent=2)+'\n', encoding='utf-8')
