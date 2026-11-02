export interface ContextChunk {
  startLine: number
  endLine: number
  text: string
}

export interface ReviewHunk {
  oldStart: number
  oldCount: number
  newStart: number
  newCount: number
  diff: string
}

export interface ReviewUnit {
  id: string
  path: string
  oldPath: string | null
  hunk: ReviewHunk
  context: {
    before: ContextChunk[]
    after: ContextChunk[]
  }
  issues: string[]
}

export interface SkippedFile {
  path: string | null
  oldPath: string | null
  reason: string
}

/**
 * Opaque parsed diff snapshot frozen at one jj operation. Reuse it across
 * collector configs so every trait context sees identical diffs.
 */
export interface CollectionSnapshot {
  version: 1
  cwd: string
  revset: string
  files: string[]
  operation: string
  exact: unknown[]
  fullByKey: Map<string, unknown>
  warnings?: string[]
}

export interface CollectionResult {
  units: ReviewUnit[]
  skipped: SkippedFile[]
  snapshot: CollectionSnapshot
}

export interface CollectionConfig {
  paths?: string[]
  exclude?: string[]
  contextLines?: number
  contextMode?: 'function' | 'hunk' | 'file'
  functionKinds?: string | RegExp
}

export interface NodeSpan {
  startLine: number
  endLine: number
  kind: string
}

export interface CollectDiffOptions {
  cwd: string
  revset: string
  files?: string | string[]
  exec: (argv: string[], cwd: string) => Promise<string>
}

export interface CollectUnitsOptions {
  cwd?: string
  revset?: string
  files?: string | string[]
  config?: CollectionConfig
  nodeChainAt: (options: { code: string; path?: string; line: number }) => NodeSpan[] | null
  exec?: (argv: string[], cwd: string) => Promise<string>
  snapshot?: CollectionSnapshot
  wholeFiles?: boolean
}

export function collectDiff(options: CollectDiffOptions): Promise<CollectionSnapshot>
export function collectUnits(options: CollectUnitsOptions): Promise<CollectionResult>
