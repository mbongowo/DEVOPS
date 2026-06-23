import * as core from '@actions/core';
import { bump, RELEASE_TYPES, ReleaseType } from './semver';

export async function run(): Promise<void> {
  try {
    const version = core.getInput('version', { required: true });
    const releaseType = core.getInput('release-type', { required: true }) as ReleaseType;
    const preid = core.getInput('preid') || 'rc';

    if (!RELEASE_TYPES.includes(releaseType)) {
      throw new Error(`release-type must be one of: ${RELEASE_TYPES.join(', ')} (got "${releaseType}")`);
    }

    const next = bump(version, releaseType, preid);
    core.info(`Bumped ${version} (${releaseType}) -> ${next}`);

    core.setOutput('previous-version', version);
    core.setOutput('next-version', next);
    core.setOutput('next-tag', `v${next}`);
  } catch (error) {
    core.setFailed(error instanceof Error ? error.message : String(error));
  }
}

run();
