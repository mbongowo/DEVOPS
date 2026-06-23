/**
 * Pure semantic-version bump logic — no GitHub Actions dependencies, so it is
 * trivially unit-testable in isolation.
 */
export type ReleaseType = 'major' | 'minor' | 'patch' | 'prerelease';

export const RELEASE_TYPES: ReleaseType[] = ['major', 'minor', 'patch', 'prerelease'];

export interface ParsedVersion {
  major: number;
  minor: number;
  patch: number;
  /** Dot-separated prerelease identifiers, e.g. ["rc", 1]. Empty for releases. */
  prerelease: Array<string | number>;
}

const SEMVER_RE = /^(\d+)\.(\d+)\.(\d+)(?:-([0-9A-Za-z.-]+))?$/;

/** Parse a `MAJOR.MINOR.PATCH[-prerelease]` string, throwing on malformed input. */
export function parseVersion(input: string): ParsedVersion {
  const match = SEMVER_RE.exec(input.trim());
  if (!match) {
    throw new Error(`"${input}" is not a valid semantic version (expected MAJOR.MINOR.PATCH)`);
  }
  return {
    major: Number(match[1]),
    minor: Number(match[2]),
    patch: Number(match[3]),
    prerelease: match[4] ? match[4].split('.') : [],
  };
}

/** Render a parsed version back to its canonical string form. */
export function formatVersion(version: ParsedVersion): string {
  const core = `${version.major}.${version.minor}.${version.patch}`;
  return version.prerelease.length > 0 ? `${core}-${version.prerelease.join('.')}` : core;
}

function bumpPrerelease(version: ParsedVersion, preid: string): ParsedVersion {
  // No active prerelease: start one on the next patch (1.2.3 -> 1.2.4-rc.0).
  if (version.prerelease.length === 0) {
    return { major: version.major, minor: version.minor, patch: version.patch + 1, prerelease: [preid, 0] };
  }
  // Same preid: increment the trailing numeric counter, or append one.
  if (version.prerelease[0] === preid) {
    const next = [...version.prerelease];
    const last = next[next.length - 1];
    if (typeof last === 'number' || /^\d+$/.test(String(last))) {
      next[next.length - 1] = Number(last) + 1;
    } else {
      next.push(0);
    }
    return { ...version, prerelease: next };
  }
  // Different preid: reset the prerelease series (1.2.4-rc.3 -> 1.2.4-beta.0).
  return { ...version, prerelease: [preid, 0] };
}

/**
 * Compute the next version given a release type.
 * @param version current version string
 * @param releaseType one of {@link RELEASE_TYPES}
 * @param preid prerelease identifier used for `prerelease` bumps (default "rc")
 */
export function bump(version: string, releaseType: ReleaseType, preid = 'rc'): string {
  const current = parseVersion(version);
  switch (releaseType) {
    case 'major':
      return formatVersion({ major: current.major + 1, minor: 0, patch: 0, prerelease: [] });
    case 'minor':
      return formatVersion({ major: current.major, minor: current.minor + 1, patch: 0, prerelease: [] });
    case 'patch':
      return formatVersion({ major: current.major, minor: current.minor, patch: current.patch + 1, prerelease: [] });
    case 'prerelease':
      return formatVersion(bumpPrerelease(current, preid));
    default:
      throw new Error(`Unknown release type "${releaseType as string}"`);
  }
}
