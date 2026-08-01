/**
 * Environment resolver. ONE place decides whether this page load talks to the
 * production Firebase project or to nothing at all.
 *
 * Keyed on HOSTNAME rather than a build-time flag, because:
 *
 * - The Firebase web apiKey is a PUBLIC project identifier, not a secret. It
 *   names a project and authorises nothing; security lives entirely in
 *   firestore.rules and the Authorized-domains allowlist. Vite inlines
 *   `import.meta.env` at build time anyway, so a key "protected" as a CI
 *   secret still ships as a plaintext literal in the bundle.
 * - CLAUDE.md requires `npm run dev --host` so a phone on the same wifi can
 *   load the game. That host is a LAN IP that changes with DHCP and is not
 *   knowable at build time. A hostname allowlist handles it for free.
 * - Anyone cloning the repo can run the whole game with no setup.
 *
 * Anything that is not a production hostname resolves to `dev`, which is
 * LOCAL-ONLY: an empty apiKey makes `cloudEnabled` false, and the Firebase SDK
 * is then never imported at all.
 */

export type EnvName = 'prod' | 'dev';

export interface FirebaseConfig {
  apiKey: string;
  authDomain: string;
  projectId: string;
  appId: string;
}

export interface EnvConfig {
  name: EnvName;
  isProd: boolean;
  firebase: FirebaseConfig;
  /** False when unconfigured, or forced off with ?cloud=off. */
  cloudEnabled: boolean;
}

/** The GitHub Pages host that serves the live game. */
export const PROD_HOSTNAMES: readonly string[] = ['mjohnsonwellabe.github.io'];

/**
 * The production Firebase project.
 *
 * These are public identifiers and committing them is correct and standard
 * practice. `apiKey` in particular is not a credential: it names a project and
 * authorises nothing. Security is entirely firestore.rules plus the
 * Authorized-domains allowlist.
 *
 * `storageBucket` and `messagingSenderId` come with the console's snippet but
 * are omitted here. We use neither Storage nor Cloud Messaging, and config a
 * reader has to check against reality is worse than config that is obviously
 * complete.
 */
const PROD_FIREBASE: FirebaseConfig = {
  apiKey: 'AIzaSyBlTN98zHJUfZC8uUFiUGn1EMnGq4PUyr0',
  authDomain: 'tetherbound-5fdd8.firebaseapp.com',
  projectId: 'tetherbound-5fdd8',
  appId: '1:772258546214:web:dc1c7afcda1318e4bf1ce7'
};

const EMPTY: FirebaseConfig = { apiKey: '', authDomain: '', projectId: '', appId: '' };

export type MetaEnvLike = Record<string, string | undefined>;

export function resolveEnvName(hostname: string, search: string): EnvName {
  const forced = new URLSearchParams(search).get('env');
  if (forced === 'dev' || forced === 'prod') return forced;
  return PROD_HOSTNAMES.includes(hostname) ? 'prod' : 'dev';
}

/**
 * A PARTIAL dev config is a misconfiguration and throws loudly. All-empty is
 * the intentional local-only fallback and is silent.
 */
function devFirebase(meta: MetaEnvLike): FirebaseConfig {
  const apiKey = meta.VITE_DEV_FIREBASE_API_KEY ?? '';
  if (!apiKey) return EMPTY;
  const fb: FirebaseConfig = {
    apiKey,
    authDomain: meta.VITE_DEV_FIREBASE_AUTH_DOMAIN ?? '',
    projectId: meta.VITE_DEV_FIREBASE_PROJECT_ID ?? '',
    appId: meta.VITE_DEV_FIREBASE_APP_ID ?? ''
  };
  const missing = (['authDomain', 'projectId', 'appId'] as const).filter((k) => !fb[k]);
  if (missing.length > 0) {
    throw new Error(
      `[env] Dev Firebase config is incomplete, missing ${missing.join(', ')}. ` +
        'Set every VITE_DEV_FIREBASE_* variable, or clear them all to run local-only.'
    );
  }
  return fb;
}

export function resolveEnv(hostname: string, search: string, meta: MetaEnvLike): EnvConfig {
  const name = resolveEnvName(hostname, search);
  const forcedOff = new URLSearchParams(search).get('cloud') === 'off';
  const firebase = name === 'prod' ? PROD_FIREBASE : devFirebase(meta);
  return {
    name,
    isProd: name === 'prod',
    firebase,
    cloudEnabled:
      !forcedOff && Boolean(firebase.apiKey && firebase.appId && firebase.projectId)
  };
}

const host = typeof location === 'undefined' ? '' : location.hostname;
const search = typeof location === 'undefined' ? '' : location.search;
const meta = ((import.meta as unknown as { env?: MetaEnvLike }).env ?? {}) as MetaEnvLike;

export const ENV: EnvConfig = resolveEnv(host, search, meta);
