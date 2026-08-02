import encounters from '../data/encounters.json';
import { makePal, type PalState } from '../party/Pal';

/**
 * Scripted fights: the two Tether grunts and Bracken Holt.
 *
 * Every pal built here is collared. That single flag carries three rules at
 * once (hits at 1.15x, never dodges, cannot be caught), and it is set from the
 * data rather than from a check on who the trainer is, so a future Warden is a
 * JSON entry rather than a branch in Battle.
 */

export interface EncounterTeamMember {
  species: string;
  level: number;
}

export interface EncounterDef {
  id: string;
  name: string;
  title?: string;
  dialogue: string;
  afterDialogue: string;
  /** Progress flag set when this fight is won. */
  flag: string;
  warden?: boolean;
  team: EncounterTeamMember[];
}

interface RawEncounter {
  name: string;
  title?: string;
  dialogue: string;
  afterDialogue: string;
  flag: string;
  warden?: boolean;
  team: EncounterTeamMember[];
}

const RAW = encounters as unknown as Record<string, RawEncounter>;

export function encounterDef(id: string): EncounterDef | undefined {
  if (id.startsWith('$')) return undefined;
  const raw = RAW[id];
  if (!raw) return undefined;
  return {
    id,
    name: raw.name,
    dialogue: raw.dialogue,
    afterDialogue: raw.afterDialogue,
    flag: raw.flag,
    team: raw.team,
    ...(raw.title === undefined ? {} : { title: raw.title }),
    ...(raw.warden === undefined ? {} : { warden: raw.warden })
  };
}

/**
 * Build a trainer's team. Variance is seeded off the encounter id and slot, so
 * Bracken's Loamking is the same Loamking on every device and every retry: a
 * boss whose stats reroll between attempts is a boss the player cannot learn.
 */
export function buildTeam(def: EncounterDef, random: (index: number) => () => number): PalState[] {
  return def.team.map((member, index) =>
    makePal(member.species, member.level, random(index), { collared: true })
  );
}

export interface RewardDef {
  flags: string[];
  badge?: { id: string; name: string };
  items: { id: string; n: number }[];
  recruit?: { species: string; level: number; dialogue: string };
  freed: number;
}

interface RawRewards {
  [key: string]: {
    flags: string[];
    badge?: { id: string; name: string };
    items?: { id: string; n: number }[];
    recruit?: { species: string; level: number; dialogue: string };
    freed?: number;
  };
}

export function rewardFor(encounterId: string): RewardDef | undefined {
  const rewards = (encounters as unknown as { rewards: RawRewards }).rewards;
  const raw = rewards?.[encounterId];
  if (!raw) return undefined;
  return {
    flags: raw.flags,
    items: raw.items ?? [],
    freed: raw.freed ?? 0,
    ...(raw.badge === undefined ? {} : { badge: raw.badge }),
    ...(raw.recruit === undefined ? {} : { recruit: raw.recruit })
  };
}
