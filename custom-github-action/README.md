# Semantic Version Bump — Custom GitHub Action

A custom **JavaScript GitHub Action** (TypeScript source, bundled with `ncc`)
that computes the next [semantic version](https://semver.org) from a base
version and a release type. Pure, dependency-light logic with unit tests and a
CI job that runs the action **on itself**.

## Usage

```yaml
- uses: mbongowo/DEVOPS/custom-github-action@main
  id: bump
  with:
    version: "1.4.2"
    release-type: minor      # major | minor | patch | prerelease
    # preid: rc              # identifier for prerelease bumps (default: rc)

- run: echo "Next version is ${{ steps.bump.outputs.next-version }}"
```

### Inputs

| Input          | Required | Default | Description                                  |
|----------------|----------|---------|----------------------------------------------|
| `version`      | yes      | —       | Current version, e.g. `1.4.2`                |
| `release-type` | yes      | —       | `major`, `minor`, `patch`, or `prerelease`   |
| `preid`        | no       | `rc`    | Prerelease identifier (e.g. `rc`, `beta`)    |

### Outputs

| Output             | Example        |
|--------------------|----------------|
| `previous-version` | `1.4.2`        |
| `next-version`     | `1.5.0`        |
| `next-tag`         | `v1.5.0`       |

### Bump semantics

| From            | Type         | preid  | Result          |
|-----------------|--------------|--------|-----------------|
| `1.4.2`         | `major`      | —      | `2.0.0`         |
| `1.4.2`         | `minor`      | —      | `1.5.0`         |
| `1.4.2`         | `patch`      | —      | `1.4.3`         |
| `1.4.2`         | `prerelease` | `rc`   | `1.4.3-rc.0`    |
| `1.4.3-rc.0`    | `prerelease` | `rc`   | `1.4.3-rc.1`    |
| `1.4.3-rc.5`    | `prerelease` | `beta` | `1.4.3-beta.0`  |
| `1.5.0-rc.2`    | `patch`      | —      | `1.5.1`         |

## Development

```bash
npm install
npm run typecheck     # tsc --noEmit
npm test              # jest unit tests
npm run build         # ncc bundle -> dist/index.js (committed)
```

The compiled `dist/index.js` is committed because GitHub runs the action
directly from the repository. CI (`.github/workflows/custom-action.yml`)
type-checks, tests, rebuilds the bundle and fails if `dist/` is stale, then a
second job invokes the action with `uses: ./` and asserts its outputs.
