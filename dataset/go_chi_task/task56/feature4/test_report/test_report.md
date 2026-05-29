# Go Project Test Results

- **Status**: PASSED
- **Repository**: go-chi/chi
- **Base Commit**: `7f280968675bcc9f310008fc6b8abff0b923734c`
- **Test Date**: Thu Apr 24 21:09:05 PDT 2025

## Test Details

```
ok  	github.com/go-chi/chi/v5	0.264s [no tests to run]
ok  	github.com/go-chi/chi/v5/middleware	0.152s
```

## Patch Status

Patch was applied before running tests.

### Changes Applied

```diff
 CHANGELOG.md                  | 6 +++---
 _examples/graceful/main.go    | 2 +-
 _examples/rest/main.go        | 2 +-
 middleware/compress.go        | 4 ++--
 middleware/middleware_test.go | 2 +-
 middleware/throttle_test.go   | 2 +-
 mux.go                        | 2 +-
 7 files changed, 10 insertions(+), 10 deletions(-)
```

## Environment

- **Go Version**: go version go1.23.2 darwin/arm64
- **GOOS**: darwin
- **GOARCH**: arm64
- **Go Module**: on
