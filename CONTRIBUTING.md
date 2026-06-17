# Contributing to Capy Copy

## Commit messages

This project uses [Conventional Commits](https://www.conventionalcommits.org/) and
[release-please](https://github.com/googleapis/release-please) to automate
versioning and changelog generation.

Use one of these prefixes in your commit messages and PR titles:

| Prefix      | Description                                      | Version bump |
|-------------|--------------------------------------------------|--------------|
| `feat:`     | New feature                                      | Minor        |
| `fix:`      | Bug fix                                          | Patch        |
| `docs:`     | Documentation only changes                       | Patch        |
| `chore:`    | Maintenance tasks (build, deps, config)          | Patch        |
| `refactor:` | Code change that neither fixes a bug nor adds a feature | Patch |
| `test:`     | Adding or correcting tests                       | Patch        |
| `BREAKING CHANGE:` | Incompatible API/behavior change          | Major        |

Examples:

```
feat: add search by source device in history
fix: paste not working in sandboxed builds
docs: update release instructions
chore: bump swift-tools-version
```

For breaking changes, add `BREAKING CHANGE:` in the commit body or use the
`!` indicator:

```
feat!: remove legacy keyboard shortcut format
```

## Release flow

1. Open PRs against `main`. They must pass CI (`swift test`) and be reviewed.
2. When PRs are merged, `release-please` opens a release PR updating
   `CHANGELOG.md` and `version.txt`.
3. Review and merge the release PR.
4. `release-please` creates a GitHub Release and tag (e.g. `v0.1.0`).
5. The `Build and Release` workflow triggers automatically, builds and notarizes
   the DMG, and uploads it to the release assets.
