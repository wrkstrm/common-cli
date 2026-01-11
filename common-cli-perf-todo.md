# TODO — Common-cli-perf Harness

### Multi-case Input + Aggregate Summary
<!-- id:ccperf-multicase owner:dev-tools priority:P1 labels:common-cli-perf,perf,status:planned epic:perf-harness estimate:3x7.5m -->
- Accept an array of cases; run sequentially; emit per‑case JSON and an aggregate summary.
- Include optional baseline gates per case; fail fast or collect all failures based on a flag.

### Named Cases + Tags
<!-- id:ccperf-tags owner:dev-tools priority:P2 labels:common-cli-perf,reporting,status:planned epic:perf-harness estimate:2x7.5m -->
- Add `name` and `tags: [String]` to inputs for stable reporting/triage.
