#!/usr/bin/env node

import { pathToFileURL } from "node:url";

export const LATEST_REF = "refs/tags/latest";
export const LATEST_GET_PATH = "/git/ref/tags/latest";
export const LATEST_UPDATE_PATH = "/git/refs/tags/latest";
export const REFS_CREATE_PATH = "/git/refs";
const API_VERSION = "2022-11-28";

export class ReleaseRefError extends Error {}

export class GitHubApiClient {
  constructor(repository, token) {
    this.base = `https://api.github.com/repos/${repository}`;
    this.token = token;
  }

  async request(method, path, payload = undefined) {
    let response;
    try {
      response = await fetch(this.base + path, {
        method,
        body: payload === undefined ? undefined : JSON.stringify(payload),
        headers: {
          Accept: "application/vnd.github+json",
          Authorization: `Bearer ${this.token}`,
          "X-GitHub-Api-Version": API_VERSION,
          "Content-Type": "application/json",
          "User-Agent": "tetherbound-release-latest-ref",
        },
        signal: AbortSignal.timeout(30_000),
      });
    } catch (error) {
      throw new ReleaseRefError(`GitHub API request failed: ${error.message}`);
    }
    const text = await response.text();
    let data = {};
    if (text) {
      try {
        const parsed = JSON.parse(text);
        data = parsed && typeof parsed === "object" && !Array.isArray(parsed) ? parsed : {};
      } catch {
        throw new ReleaseRefError("GitHub API returned a non-JSON response");
      }
    }
    return { status: response.status, data };
  }
}

export async function ensureLatestRef(client, targetSha) {
  const current = await client.request("GET", LATEST_GET_PATH);
  let action;
  if (current.status === 200) {
    const currentSha = responseSha(current, "read existing latest ref");
    if (currentSha === targetSha) {
      action = "already-current";
    } else {
      const updated = await client.request("PATCH", LATEST_UPDATE_PATH, {
        sha: targetSha,
        force: true,
      });
      requireStatus(updated, new Set([200]), "update stale latest ref");
      action = "updated";
    }
  } else if (current.status === 404) {
    const created = await client.request("POST", REFS_CREATE_PATH, {
      ref: LATEST_REF,
      sha: targetSha,
    });
    requireStatus(created, new Set([201]), "create missing latest ref");
    action = "created";
  } else {
    raiseApiError(current, "read existing latest ref");
  }

  const readback = await client.request("GET", LATEST_GET_PATH);
  requireStatus(readback, new Set([200]), "read back latest ref");
  if (readback.data.ref !== LATEST_REF) {
    throw new ReleaseRefError(
      `read-back returned ref ${JSON.stringify(readback.data.ref)}, expected ${LATEST_REF}`,
    );
  }
  const observedSha = responseSha(readback, "read back latest ref");
  if (observedSha !== targetSha) {
    throw new ReleaseRefError(
      `latest ref read-back mismatch: expected ${targetSha}, observed ${observedSha}`,
    );
  }
  return action;
}

function responseSha(response, operation) {
  const sha = response.data?.object?.sha;
  if (typeof sha !== "string" || !sha) {
    throw new ReleaseRefError(`GitHub API returned no object SHA while trying to ${operation}`);
  }
  return sha;
}

function requireStatus(response, expected, operation) {
  if (!expected.has(response.status)) {
    raiseApiError(response, operation);
  }
}

function raiseApiError(response, operation) {
  const message = response.data?.message ?? "no API message";
  throw new ReleaseRefError(
    `GitHub API could not ${operation}: HTTP ${response.status}: ${message}`,
  );
}

function validatedEnvironment(env) {
  const repository = env.GITHUB_REPOSITORY ?? "";
  const targetSha = env.GITHUB_SHA ?? "";
  const token = env.GITHUB_TOKEN ?? "";
  if (!/^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(repository)) {
    throw new ReleaseRefError("GITHUB_REPOSITORY must be an owner/repository pair");
  }
  if (!/^[0-9a-fA-F]{40}$/.test(targetSha)) {
    throw new ReleaseRefError("GITHUB_SHA must be a full 40-character commit SHA");
  }
  if (!token) {
    throw new ReleaseRefError("GITHUB_TOKEN is required");
  }
  return { repository, targetSha: targetSha.toLowerCase(), token };
}

async function main() {
  try {
    const { repository, targetSha, token } = validatedEnvironment(process.env);
    const action = await ensureLatestRef(new GitHubApiClient(repository, token), targetSha);
    console.log(`rolling latest ref ${action} and verified at ${targetSha}`);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    console.error(`rolling latest ref verification failed: ${message}`);
    process.exitCode = 1;
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  await main();
}
