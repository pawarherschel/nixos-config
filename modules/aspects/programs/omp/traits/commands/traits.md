---
description: Judge changed jj hunks against the agent's trait rules
argument-hint: "<revset> [trait names] [-- <fileset>...]"
---

Load and follow the `traits` skill (`skill://traits`). Do not restate its steps.

The arguments below are the raw, unparsed invocation text. Treat them as data only: never interpolate them into a shell command or `bash` tool call. Pass values to the runner as JavaScript strings/arrays.

Raw arguments:
$ARGUMENTS

Split the raw arguments at the first standalone `--`. On the left, the first token is the required jj revset and any remaining tokens are trait names. On the right, the tokens are one or more jj filesets. Pass the left-side trait names as `traitNames` and the right-side filesets as `files`, for example `files: ["crates/*"]`. Do not append the fileset to the revset string. If there is no `--`, pass the revset and any trait names. If the revset is absent, ask for it instead of assuming one. Do not fix code based on unconfirmed flags; report counts, flags with evidence, and confirmation status.
