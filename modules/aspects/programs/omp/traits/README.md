# OMP traits

Manual hunk reviews using OMP's builtin Eval `judgeBatch`; automatic agent-managed trait learning. The cached OMP package is unchanged. The plugin's Nix module declares its only external executable, `jj`; Bun and tree-sitter APIs are supplied by OMP's embedded runtime.

Invoke `/traits <revset>` or ask the agent to use the traits skill with a revision selection. The skill loads `scripts/check.mjs` in Eval and invokes its deterministic runner. Review does not automatically fix code. Agents inspect only flagged hunks after judging; model verdicts are not proof.

Each zero-context diff hunk is a separate judgment unit. Its enclosing functions plus ten surrounding lines are evidence, not additional review scope. Context comes from the target snapshot (the source snapshot for a pure deletion); the diff retains both changed sides. Overlapping function context never merges units. Whole-file review requires an explicit `wholeFiles: true` invocation; `contextMode: file` only widens evidence.

## Traits

Authored traits live in the project's `.agents/traits/*.md`. Automatically learned traits live in the active OMP profile's `managed-traits/*.md`, alongside managed skills. Authored traits take precedence for the same name. `manage_trait` lists, creates, updates, and deletes managed traits without changing authored files. Automatic learning captures reusable preferences and corrections, not speculative requirements or a model finding alone.

```markdown
---
name: preserve-omitted-fields
description: Preserve existing values when partial updates omit a field.
paths: ["src/**"]
---
An omitted field in a partial update leaves its existing value unchanged.
An explicitly supplied empty value may clear it.
```

Rule prose, exceptions, rationale, and examples go in the Markdown body. Metadata and configuration go in YAML frontmatter. Unknown keys and invalid configuration are errors.

## Configuration

Precedence: explicit invocation overrides → trait frontmatter → shared defaults in `core.mjs`. Arrays and verdict maps replace lower-layer values; omission inherits. Every option below is overridable in frontmatter or invocation overrides.

| Option | Shared default | Meaning |
| --- | --- | --- |
| `paths` | `["**/*"]` | Applicable repository paths |
| `exclude` | See `core.mjs` | Dependency/reference/rule directories and likely secret files |
| `minConfidence` | `0.7` | Probability required to report a configured finding verdict |
| `contextLines` | `10` | Lines before/after the selected context |
| `contextMode` | `function` | `function`, `hunk`, or `file` evidence |
| `functionKinds` | `function\|method\|lambda\|closure\|arrow\|^binding$` | Regex over tree-sitter node kinds |
| `maxStateChars` | `100000` | Oversized states are reported, never silently truncated |
| `verdicts` | compliant, violation, not-applicable, inconclusive | Label → observable rubric; custom labels supported |
| `reportVerdicts` | `["violation"]` | Verdicts treated as potential findings |
| `reviewVerdicts` | `["inconclusive"]` | Verdicts requiring inspection regardless of threshold |
| `concurrency` | `16` | Batch concurrency, bounded by OMP's limit of 32 |
| `retries` | `1` | Per-item batch retry count |
| `minOk` | `1` | Minimum successful batch answers |

Custom `verdicts` must have at least two labels and compatible `reportVerdicts`/`reviewVerdicts`. Low-certainty decisions, unavailable syntax context, oversized inputs, and provider errors are visible separately; they do not establish compliance. Deterministic path exclusions are counted separately from unsupported inputs.

## Boundaries

- jj defines combined-revset diff semantics and rejects unsupported selections such as gapped revision sets.
- Syntax extraction uses OMP's bundled `nodeChainAt`. Unsupported syntax or code outside a function is reported rather than presented as complete function context.
- Source and trait text are sent through OMP's configured judge backend. Exclusion patterns are not a secret scanner; select inputs accordingly.
- The main agent performs the mechanical Eval invocation; all collection, configuration, question construction, batching, and filtering are code-owned.
