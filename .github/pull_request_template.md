## Summary

- What changed?
- Why is the change needed?

## Validation

- [ ] `dotnet restore --locked-mode`
- [ ] `dotnet format RapidYencSharp.sln --verify-no-changes --no-restore`
- [ ] `dotnet build RapidYencSharp.sln --configuration Release --no-restore`
- [ ] `./build-artifacts.sh`
- [ ] `python3 scripts/validate-package.py artifacts/packages`
- [ ] Documentation and regression tests are updated where needed.
- [ ] No credentials, tokens, generated native binaries, or private data are included.

## Compatibility

Describe any public API, package, native ABI, runtime, or performance impact.
