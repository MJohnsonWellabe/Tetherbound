#!/usr/bin/env node

import assert from "node:assert/strict";
import test from "node:test";

import {
  LATEST_GET_PATH,
  LATEST_REF,
  LATEST_UPDATE_PATH,
  REFS_CREATE_PATH,
  ReleaseRefError,
  ensureLatestRef,
} from "../tools/release_latest_tag.mjs";

const OLD_SHA = "a".repeat(40);
const TARGET_SHA = "b".repeat(40);
const WRONG_SHA = "c".repeat(40);

function refResponse(status, sha = "") {
  if (status === 404) return { status, data: { message: "Not Found" } };
  return { status, data: { ref: LATEST_REF, object: { sha } } };
}

class FakeApi {
  constructor(responses) {
    this.responses = [...responses];
    this.calls = [];
  }

  async request(method, path, payload = undefined) {
    this.calls.push([method, path, payload]);
    assert.ok(this.responses.length > 0, "unexpected API call");
    return this.responses.shift();
  }
}

test("existing stale tag is force-updated and read back", async () => {
  const api = new FakeApi([
    refResponse(200, OLD_SHA),
    refResponse(200, TARGET_SHA),
    refResponse(200, TARGET_SHA),
  ]);

  assert.equal(await ensureLatestRef(api, TARGET_SHA), "updated");
  assert.deepEqual(api.calls, [
    ["GET", LATEST_GET_PATH, undefined],
    ["PATCH", LATEST_UPDATE_PATH, { sha: TARGET_SHA, force: true }],
    ["GET", LATEST_GET_PATH, undefined],
  ]);
});

test("missing tag is created and read back", async () => {
  const api = new FakeApi([
    refResponse(404),
    refResponse(201, TARGET_SHA),
    refResponse(200, TARGET_SHA),
  ]);

  assert.equal(await ensureLatestRef(api, TARGET_SHA), "created");
  assert.deepEqual(api.calls, [
    ["GET", LATEST_GET_PATH, undefined],
    ["POST", REFS_CREATE_PATH, { ref: LATEST_REF, sha: TARGET_SHA }],
    ["GET", LATEST_GET_PATH, undefined],
  ]);
});

test("unexpected API error fails without mutation", async () => {
  const api = new FakeApi([{ status: 503, data: { message: "Service unavailable" } }]);

  await assert.rejects(() => ensureLatestRef(api, TARGET_SHA), ReleaseRefError);
  assert.deepEqual(api.calls, [["GET", LATEST_GET_PATH, undefined]]);
});

test("read-back mismatch fails", async () => {
  const api = new FakeApi([
    refResponse(200, OLD_SHA),
    refResponse(200, TARGET_SHA),
    refResponse(200, WRONG_SHA),
  ]);

  await assert.rejects(
    () => ensureLatestRef(api, TARGET_SHA),
    /read-back mismatch/,
  );
  assert.deepEqual(api.calls.at(-1), ["GET", LATEST_GET_PATH, undefined]);
});
