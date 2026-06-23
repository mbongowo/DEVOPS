import { bump, parseVersion, formatVersion } from '../src/semver';

describe('parseVersion', () => {
  it('parses a plain version', () => {
    expect(parseVersion('1.4.2')).toEqual({ major: 1, minor: 4, patch: 2, prerelease: [] });
  });

  it('parses a prerelease version', () => {
    expect(parseVersion('2.0.0-rc.3')).toEqual({ major: 2, minor: 0, patch: 0, prerelease: ['rc', '3'] });
  });

  it('rejects malformed input', () => {
    expect(() => parseVersion('v1.2')).toThrow(/not a valid semantic version/);
    expect(() => parseVersion('1.2.x')).toThrow();
  });
});

describe('formatVersion', () => {
  it('round-trips through parse', () => {
    for (const v of ['0.0.1', '10.20.30', '1.2.3-beta.0']) {
      expect(formatVersion(parseVersion(v))).toBe(v);
    }
  });
});

describe('bump', () => {
  it('bumps major and resets minor/patch', () => {
    expect(bump('1.4.2', 'major')).toBe('2.0.0');
  });

  it('bumps minor and resets patch', () => {
    expect(bump('1.4.2', 'minor')).toBe('1.5.0');
  });

  it('bumps patch', () => {
    expect(bump('1.4.2', 'patch')).toBe('1.4.3');
  });

  it('drops the prerelease when promoting to a release', () => {
    expect(bump('1.5.0-rc.2', 'patch')).toBe('1.5.1');
    expect(bump('2.0.0-rc.1', 'minor')).toBe('2.1.0');
  });

  it('starts a prerelease on the next patch', () => {
    expect(bump('1.4.2', 'prerelease')).toBe('1.4.3-rc.0');
  });

  it('increments an existing prerelease counter', () => {
    expect(bump('1.4.3-rc.0', 'prerelease')).toBe('1.4.3-rc.1');
    expect(bump('1.4.3-rc.9', 'prerelease')).toBe('1.4.3-rc.10');
  });

  it('honours a custom preid and resets when it changes', () => {
    expect(bump('1.4.2', 'prerelease', 'beta')).toBe('1.4.3-beta.0');
    expect(bump('1.4.3-rc.5', 'prerelease', 'beta')).toBe('1.4.3-beta.0');
  });

  it('throws on an invalid version', () => {
    expect(() => bump('not-a-version', 'patch')).toThrow();
  });
});
