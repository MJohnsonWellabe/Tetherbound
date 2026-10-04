// Read the production codec without changing the source bytes. Large signed
// integers stay BigInt; converting them to Number would lose saved identity.
const FLOAT = '$tb_float64', INTEGER = '$tb_int64', DICTIONARY = '$tb_dictionary';
const tags = [FLOAT, INTEGER, DICTIONARY];
const own = (value, key) => Object.hasOwn(value, key);
const dictionary = value => value !== null && typeof value === 'object' && !Array.isArray(value);
const invalid = () => { throw new Error('Invalid production save codec'); };

export function parseSaveDocument(text) {
  const outer = JSON.parse(text);
  if (!dictionary(outer)) invalid();
  if (outer.format !== 'tetherbound-save') return outer;
  if (Object.keys(outer).length !== 3 || !own(outer, 'payload') || outer.codec_version !== 1) invalid();
  const result = decode(outer.payload, 0);
  if (!dictionary(result)) invalid();
  return result;
}

function decode(value, depth) {
  if (depth > 128) invalid();
  if (value === null || typeof value === 'boolean' || typeof value === 'string') return value;
  if (typeof value === 'number') {
    if (!Number.isSafeInteger(value)) invalid();
    return value;
  }
  if (Array.isArray(value)) return value.map(item => decode(item, depth + 1));
  if (!dictionary(value)) invalid();
  const keys = Object.keys(value);
  if (own(value, FLOAT)) {
    if (keys.length !== 1 || typeof value[FLOAT] !== 'string' || !/^[0-9a-f]{16}$/.test(value[FLOAT])) invalid();
    const number = Buffer.from(value[FLOAT], 'hex').readDoubleLE();
    if (!Number.isFinite(number)) invalid();
    return number;
  }
  if (own(value, INTEGER)) {
    const text = value[INTEGER];
    if (keys.length !== 1 || typeof text !== 'string' || !/^-?(?:0|[1-9][0-9]*)$/.test(text)) invalid();
    const number = BigInt(text);
    if (String(number) !== text || number < -(2n ** 63n) || number >= 2n ** 63n ||
        (number >= -9007199254740991n && number <= 9007199254740991n)) invalid();
    return number;
  }
  if (own(value, DICTIONARY)) {
    if (keys.length !== 1 || !Array.isArray(value[DICTIONARY])) invalid();
    const pairs = [], seen = new Set();
    for (const pair of value[DICTIONARY]) {
      if (!Array.isArray(pair) || pair.length !== 2 || typeof pair[0] !== 'string' || seen.has(pair[0])) invalid();
      seen.add(pair[0]);
      pairs.push([pair[0], decode(pair[1], depth + 1)]);
    }
    if (!tags.some(tag => seen.has(tag))) invalid();
    return Object.fromEntries(pairs);
  }
  return Object.fromEntries(keys.map(key => [key, decode(value[key], depth + 1)]));
}
