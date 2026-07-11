# Contributing to RapidYencSharp

Thank you for contributing. Keep changes focused and include regression tests
when changing encoding, decoding, CRC, interop, or native build behavior.

## Prerequisites

- The .NET SDK selected by `global.json`
- Git
- Docker or Podman for reproducible multi-RID package builds

Clone with `--recurse-submodules`, or initialize rapidyenc in an existing
clone:

```bash
git submodule update --init
```

Restore, format, and build the managed project:

```bash
dotnet restore --locked-mode
dotnet format RapidYencSharp.sln --verify-no-changes --no-restore
dotnet build RapidYencSharp.sln --configuration Release --no-restore
dotnet test RapidYencSharp.Tests/RapidYencSharp.Tests.csproj --configuration Release --no-build
```

Build and validate all release artifacts with Podman:

```bash
./build-artifacts.sh
python3 scripts/validate-package.py artifacts/packages
```

The container build compiles native libraries for `linux-x64`, `linux-arm64`,
and `win-x64`. To build native libraries directly, install CMake, Ninja, and
the cross-compilers listed in the `Dockerfile`, then run `./build-native.sh`.

Never commit credentials, access tokens, native build output, or captured
private data.

## Pull requests

1. Open an issue first for large API or architectural changes.
2. Preserve public API and package compatibility unless a breaking change is
   intentional and documented.
3. Update documentation when behavior or public APIs change.
4. Add or update tests when practical.
5. Complete the pull request template and ensure all required checks pass.

Use `RapidYencSharp.Benchmarks` to measure hot-path changes locally. Commit the
benchmark code, but do not treat timing results from shared CI runners as a
pass/fail gate.

Use scoped Conventional Commit subjects, such as `fix(interop):`,
`feat(yenc):`, `docs(readme):`, or `chore(ci):`. Release Please uses commit
history to prepare release notes and determine semantic versions.

## Releases

Release Please maintains a release pull request. Merging that pull request
updates `.release-please-manifest.json`, `CHANGELOG.md`, and the `<Version>` in
`RapidYencSharp/RapidYencSharp.csproj`, then creates an immutable `vX.Y.Z` tag
and GitHub release. The release workflow builds from that tag, validates the
managed and native package contents, attests the artifacts, and publishes to
NuGet.org. Maintainers should not manually move release tags.
