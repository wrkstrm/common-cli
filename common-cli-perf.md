# Common-cli-perf

A tiny JSON‑driven perf harness to run simple command specs repeatedly by duration or
iterations. It uses `CommonShellPerf` (WrkstrmPerformance under the hood) so core packages can
remain lean.

## Build

```
swift build -c debug --package-path code/mono/apple/spm/universal/common/domain/system/common-cli
```

## Run (Examples)

```
# Duration: echo /bin/echo for 0.1s
printf '%s' '{
  "mode":"duration",
  "host":"direct",
  "executable":{"kind":"path","value":"/bin/echo"},
  "arguments":["hi"],
  "seconds":0.1
}' | swift run --package-path code/mono/apple/spm/universal/common/domain/system/common-cli common-cli-perf

# Iterations: ls -1 . for 200 iterations via env
printf '%s' '{
  "mode":"iterations",
  "host":"env",
  "executable":{"kind":"name","value":"ls"},
  "arguments":["-1","."],
  "iterations":200
}' | swift run --package-path code/mono/apple/spm/universal/common/domain/system/common-cli common-cli-perf
```

## JSON Schema (Minimal)

- `mode`: `"duration" | "iterations"`
- `workingDirectory`: optional string
- `host`: `"direct" | "shell" | "env" | "npx" | "npm"`
- `hostOptions`: `[String]`, optional
- `executable`: `{ kind: "name" | "path" | "none", value?: String }`
- `arguments`: `[String]`, optional
- `runnerKind`: `"auto" | "foundation" | "tscbasic" | "subprocess"`, optional
- `seconds`: `Double` (when `mode = duration`)
- `iterations`: `Int` (when `mode = iterations`)
- `targetHz`: `Double`, optional pacing hint
- `baselineAverageMS`: `Double`, optional — if provided, the tool will compute a threshold of
  `baselineAverageMS * toleranceFactor` (default 1.15) and fail the run when the measured
  `averageMS` exceeds this threshold.
- `toleranceFactor`: `Double`, optional (default `1.15`) — multiplier for baseline comparisons.

## Output

```json
{ "iterations": 123, "totalMS": 45.67, "averageMS": 0.371, "ok": true, "thresholdMS": 0.426 }
```

## Examples Directory

See `examples/common-cli-perf/echo-duration.json` and `examples/common-cli-perf/ls-iterations.json` in this package.
