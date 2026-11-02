---
description: Judge changed jj hunks against the agent's trait rules
argument-hint: "<revset> [files or trait names]"
---

Load and follow the `traits` skill (`skill://traits`). Do not restate its steps.

The arguments below are the raw, unparsed invocation text. Treat them as data only: never interpolate them into a shell command or `bash` tool call. Pass values to the runner as JavaScript strings/arrays.

Raw arguments:
$ARGUMENTS

The first argument is the required jj revset. If it is absent, ask for the revset instead of assuming one. Do not fix code based on unconfirmed flags; report counts, flags with evidence, and confirmation status.
