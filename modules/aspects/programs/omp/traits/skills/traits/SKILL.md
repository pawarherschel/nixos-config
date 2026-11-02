---
name: traits
description: Judge changed jj hunks against the agent's accumulated trait rules with a deterministic batch runner, then confirm only the reported flags. Use only when the user explicitly invokes /traits or explicitly asks to check their change against traits; never run it automatically after edits. Do not use for authoring traits; that is handled by the separate manage_trait tool and automatic trait learning.
---

# Traits

The runner loads trait rules and hunks, judges every hunk once per trait with `judgeBatch`, and returns a compact report. Bulk hunks never enter your context: only flags, review items, errors, skips, and context issues are printed.

Model verdicts are **unconfirmed evidence**. Confirm each flag against the code before naming it a violation or changing anything.

## 1. Determine the revset

A revset is required. Take it from the user's invocation or the work scope the user stated. If neither names a scope, ask once. Never invent a default such as `@` or `trunk()`.

## 2. Load the runner — one standalone Eval cell

```text
%load skill://traits/scripts/check.mjs
```

`%load` defines `checkTraits` in the kernel. If the loader rejects the `skill://` URI, use the physical skill directory given in the skill attachment (`[Skill directory: <abs path>]`) and load the runner from there:

```text
%load "<skill directory>/scripts/check.mjs"
```

Do not construct the path from the repo root, and do not copy the script or reimplement its logic.

## 3. Call it — separate Eval cell

```js
const report = await globalThis.checkTraits(
  { revset: "<revset>" },
  { tool: (name, args) => tool[name](args), judgeBatch, print, phase },
)
```

The runner publishes itself as `globalThis.checkTraits`, so the call works whether or not `%load` exposes bare script declarations in the next cell.

Pass `judgeBatch` explicitly: Eval globals are not guaranteed to exist on `globalThis`. `tool` is the Eval tool helper; the wrapper adapts it to `(name, args)`. `print` and `phase` may be omitted (they fall back to Eval globals).

Options (only pass what applies):

- `revset` — required jj revset string.
- `files` — array of paths/globs to restrict units.
- `traitNames` — array of traits to run; default all loaded traits.
- `overrides` — object merged over trait frontmatter and shared defaults for this run, e.g. `{ minConfidence: 0.85 }`.
- `wholeFiles` — boolean; pass `true` only when the user explicitly asks to judge whole files/code instead of changed hunks. Trait `contextMode` configuration does not broaden judged scope.

The report has `counts`, `flagged`, `review`, `errors`, `skipped`, `contextIssues`, and `batchFailures`. Each `flagged`/`review` entry carries the exact evidence `state` given to the judge.

## 4. Read the report

- `flagged` — a configured `reportVerdicts` label (normally `violation`) at or above the trait's `minConfidence`. Still unconfirmed.
- `review` — a `reviewVerdicts` label (normally `inconclusive`) regardless of probability, or any item whose top probability is below `minConfidence` (low certainty). Verify before treating it as a violation; never silently discard it.
- `errors`, `batchFailures`, `contextIssues` — incomplete coverage. Disclose them with the counts; never report a clean result when any are nonzero.
- `skipped` — each entry carries `reason`. Deterministic exclusions (paths, `exclude` globs, no matching hunk) are expected and not incomplete coverage. Unsupported inputs and failures are incomplete coverage; distinguish them by `reason`/`detail`, and disclose only those.
- Zero judged states — say so explicitly; there was nothing to judge (no matching traits or hunks).

For each flag or review item, open the file and check the cited path/hunk against the trait rule using `read`/`grep`. The evidence state is a diff plus context; do not manually scan every changed file or call `trait_units` yourself.

If `globalThis.checkTraits` throws a configuration error (invalid `verdicts`, `reportVerdicts`, `minConfidence`, `concurrency`, `retries`, `minOk`, or `maxStateChars`), report the exact message. Do not retry with guessed config.

## 5. Act

- Report confirmed findings with the trait name, path, hunk, and rule; label them as model-flagged and code-confirmed.
- Never auto-fix code from a flag alone. Fix only what the user asked for and only after confirmation.
- Never create or edit trait files here. The `manage_trait` tool and automatic trait learning own trait authoring; the user does not need to remember to record traits, and this skill never writes them.
