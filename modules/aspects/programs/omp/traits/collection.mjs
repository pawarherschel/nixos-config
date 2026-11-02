/**
 * Deterministic jj-revset hunk collection for OMP traits.
 *
 * Both diffs are read at one frozen jj operation: exact zero-context hunks for
 * the judged units, and a full-context diff used to rebuild the old/new file
 * contents. A snapshot of the parse is reusable across collector configs so
 * multiple trait contexts see byte-identical diffs.
 */

/** Context value large enough to cover every realistic file in one hunk. */
const FULL_CONTEXT = 2147483647;

/**
 * JSONL path manifest. jj's git diff does not C-quote paths, so embedded
 * newlines/tabs make `diff --git` headers ambiguous. This template runs over
 * the same TreeDiff in the same order and yields escaped paths plus file types.
 */
const MANIFEST_TEMPLATE =
  'json({"path" => path, "source" => source.path(), "status" => status, "sourceType" => source.file_type(), "targetType" => target.file_type()}) ++ "\\n"';

const HUNK_RE = /^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@(.*)$/;
const INDEX_RE = /^index [0-9a-fA-F]+\.\.[0-9a-fA-F]+(?: ([0-7]{6}))?$/;

const DEFAULT_PATHS = ['**/*'];
const DEFAULT_EXCLUDE = [
  'references/**',
  'node_modules/**',
  '.git/**',
  '.jj/**',
  '.agents/traits/**',
  '**/.env',
  '**/.env.*',
  '**/*.pem',
  '**/*.key',
];
const DEFAULT_FUNCTION_KINDS = 'function|method|lambda|closure|arrow|^binding$';
const DEFAULT_CONTEXT_MODE = 'function';
const DEFAULT_CONTEXT_LINES = 10;
const REGULAR_MODES = new Set(['100644', '100755']);

/**
 * Collect and parse a jj diff snapshot. The returned object is opaque to
 * callers other than passing it back to {@link collectUnits}.
 */
export async function collectDiff({ cwd, revset, files, exec } = {}) {
  if (typeof cwd !== 'string' || cwd.length === 0) {
    throw new TypeError('collectDiff: cwd must be a non-empty string');
  }
  if (typeof revset !== 'string' || revset.trim().length === 0) {
    throw new TypeError('collectDiff: revset must be a non-empty string');
  }
  if (typeof exec !== 'function') {
    throw new TypeError('collectDiff: exec(argv, cwd) must be a function');
  }

  const normalizedFiles = normalizeFiles(files);

  // Freeze one operation, then read both diffs at it. `--at-operation` implies
  // --ignore-working-copy, so neither diff call can advance the snapshot.
  const opOutput = await exec(
    ['jj', 'op', 'log', '-n', '1', '--no-graph', '-T', 'id'],
    cwd,
  );
  const operation = String(opOutput ?? '').trim().split(/\s+/)[0];
  if (!operation) {
    throw new Error('collectDiff: jj op log did not return an operation id');
  }

  const base = ['jj', '--color=never', '--at-operation', operation, 'diff', '-r', revset, '--git'];
  const fileArgs = normalizedFiles.length > 0 ? ['--', ...normalizedFiles] : [];
  const manifestArgs = [
    'jj',
    '--color=never',
    '--at-operation',
    operation,
    'diff',
    '-r',
    revset,
    '-T',
    MANIFEST_TEMPLATE,
    ...fileArgs,
  ];

  const manifestPromise = exec(manifestArgs, cwd).then(
    (output) => ({ output }),
    (error) => ({ error }),
  );
  const [exactText, fullText, manifestResult] = await Promise.all([
    exec([...base, '--context', '0', ...fileArgs], cwd),
    exec([...base, '--context', String(FULL_CONTEXT), ...fileArgs], cwd),
    manifestPromise,
  ]);

  const exact = parseGitDiff(exactText);
  const full = parseGitDiff(fullText);

  const warnings = [];
  let manifest = null;
  if (manifestResult.error) {
    warnings.push(
      `path manifest unavailable (${manifestResult.error?.message ?? manifestResult.error}); falling back to diff-header paths`,
    );
  } else {
    try {
      manifest = parseManifest(manifestResult.output);
    } catch (error) {
      warnings.push(
        `path manifest could not be parsed (${error.message}); falling back to diff-header paths`,
      );
    }
  }

  if (manifest != null) {
    if (exact.length !== manifest.length || full.length !== manifest.length) {
      warnings.push(
        `path manifest has ${manifest.length} entries but diffs have ${exact.length}/${full.length}; falling back to diff-header paths`,
      );
      manifest = null;
    } else {
      applyManifest(exact, manifest);
      applyManifest(full, manifest);
    }
  }

  const fullByKey = new Map();
  for (const file of full) {
    fullByKey.set(fileKey(file), file);
  }

  return {
    version: 1,
    cwd,
    revset,
    files: normalizedFiles,
    operation,
    exact,
    fullByKey,
    warnings,
  };
}

/**
 * Build review units per zero-context hunk. When a snapshot is supplied from
 * {@link collectDiff}, no jj command runs and all configs share the snapshot.
 *
 * @returns {Promise<{units: object[], skipped: object[], snapshot: object}>}
 */
export async function collectUnits({
  cwd,
  revset,
  files,
  config,
  nodeChainAt,
  exec,
  snapshot,
  wholeFiles = false,
} = {}) {
  if (typeof nodeChainAt !== 'function') {
    throw new TypeError('collectUnits: nodeChainAt must be a function');
  }

  const cfg = normalizeConfig(config);
  let snap = snapshot;
  if (snap != null) {
    if (snap.version !== 1 || !Array.isArray(snap.exact) || !(snap.fullByKey instanceof Map)) {
      throw new TypeError('collectUnits: invalid snapshot');
    }
    if (cwd !== undefined && cwd !== snap.cwd) {
      throw new Error(`collectUnits: snapshot cwd ${snap.cwd} does not match ${cwd}`);
    }
    if (revset !== undefined && revset !== snap.revset) {
      throw new Error(`collectUnits: snapshot revset ${snap.revset} does not match ${revset}`);
    }
    if (files !== undefined && !sameStringSet(normalizeFiles(files), snap.files)) {
      throw new Error('collectUnits: snapshot files do not match the requested files');
    }
  } else {
    snap = await collectDiff({ cwd, revset, files, exec });
  }

  const units = [];
  const skipped = [];
  const snapshotWarnings = Array.isArray(snap.warnings) ? snap.warnings : [];

  for (const exactFile of snap.exact) {
    const path = exactFile.newPath ?? exactFile.oldPath ?? null;
    const oldPath = exactFile.oldPath ?? null;

    if (path == null) {
      skipped.push({
        path: null,
        oldPath,
        reason: 'path could not be parsed from diff headers',
      });
      continue;
    }

    if (exactFile.binary) {
      skipped.push({ path, oldPath, reason: 'binary file' });
      continue;
    }

    const exactType = nonRegularFileType(exactFile);
    const exactMode = nonRegularMode(exactFile);
    if (exactType || exactMode) {
      skipped.push({
        path,
        oldPath,
        reason: exactType
          ? `non-regular file (${exactType})`
          : `non-regular file (mode ${exactMode})`,
      });
      continue;
    }

    if (!matchesScope(path, cfg)) {
      skipped.push({
        path,
        oldPath,
        reason: scopeReason(path, cfg),
      });
      continue;
    }

    const fullFile = snap.fullByKey.get(fileKey(exactFile));
    if (!fullFile) {
      skipped.push({
        path,
        oldPath,
        reason: 'file missing from the full-context diff at the frozen operation',
      });
      continue;
    }
    if (fullFile.binary) {
      skipped.push({ path, oldPath, reason: 'binary file (full-context diff)' });
      continue;
    }
    const fullType = nonRegularFileType(fullFile);
    const fullMode = nonRegularMode(fullFile);
    if (fullType || fullMode) {
      skipped.push({
        path,
        oldPath,
        reason: fullType
          ? `non-regular file (${fullType})`
          : `non-regular file (mode ${fullMode})`,
      });
      continue;
    }

    if (fullFile.hunks.length === 0) {
      skipped.push({
        path,
        oldPath,
        reason: wholeFiles
          ? 'no full-file content: diff has no content hunks (unchanged rename or mode-only change)'
          : 'no content changes',
      });
      continue;
    }

    const recon = reconstructFull(fullFile);
    if (recon.error) {
      skipped.push({
        path,
        oldPath,
        reason: `full file reconstruction failed: ${recon.error}`,
      });
      continue;
    }

    if (wholeFiles) {
      const unit = buildWholeFileUnit({ exactFile, recon, path, oldPath });
      if (snapshotWarnings.length > 0) {
        unit.issues.unshift(
          ...snapshotWarnings.map((warning) => `path-manifest: ${warning}`),
        );
      }
      units.push(unit);
      continue;
    }

    for (let index = 0; index < exactFile.hunks.length; index += 1) {
      const unit = buildUnit({
        exactFile,
        hunk: exactFile.hunks[index],
        index,
        recon,
        cfg,
        nodeChainAt,
        path,
        oldPath,
      });
      if (snapshotWarnings.length > 0) {
        unit.issues.unshift(
          ...snapshotWarnings.map((warning) => `path-manifest: ${warning}`),
        );
      }
      units.push(unit);
    }
  }

  return { units, skipped, snapshot: snap };
}

/* ------------------------------------------------------------------ config */

function normalizeConfig(raw) {
  const config = raw != null && typeof raw === 'object' ? raw : {};
  const paths = stringArray(config.paths, DEFAULT_PATHS, 'paths');
  const exclude = stringArray(config.exclude, DEFAULT_EXCLUDE, 'exclude');
  const contextLines = nonNegativeInteger(
    config.contextLines ?? DEFAULT_CONTEXT_LINES,
    'contextLines',
  );
  const contextMode = config.contextMode ?? DEFAULT_CONTEXT_MODE;
  if (contextMode !== 'function' && contextMode !== 'hunk' && contextMode !== 'file') {
    throw new Error(
      `collectUnits: config.contextMode must be "function", "hunk", or "file" (got ${JSON.stringify(contextMode)})`,
    );
  }

  const rawKinds = config.functionKinds ?? DEFAULT_FUNCTION_KINDS;
  let functionKinds;
  let functionKindsSource;
  if (rawKinds instanceof RegExp) {
    // Never keep g/y state: a stateful .test() would silently skip hunks.
    functionKinds = new RegExp(rawKinds.source, rawKinds.flags.replace(/[gy]/g, ''));
    functionKindsSource = rawKinds.source;
  } else if (typeof rawKinds === 'string' && rawKinds.length > 0) {
    try {
      functionKinds = new RegExp(rawKinds);
    } catch (error) {
      throw new Error(`collectUnits: invalid config.functionKinds regex: ${error.message}`);
    }
    functionKindsSource = rawKinds;
  } else {
    throw new Error('collectUnits: config.functionKinds must be a regex string');
  }

  return {
    paths,
    exclude,
    pathMatchers: paths.map(compileGlob),
    excludeMatchers: exclude.map(compileGlob),
    contextLines,
    contextMode,
    functionKinds,
    functionKindsSource,
  };
}

function stringArray(value, fallback, name) {
  if (value === undefined) return [...fallback];
  if (!Array.isArray(value) || value.some((item) => typeof item !== 'string')) {
    throw new Error(`collectUnits: config.${name} must be an array of strings`);
  }
  return [...value];
}

function nonNegativeInteger(value, name) {
  if (typeof value !== 'number' || !Number.isInteger(value) || value < 0) {
    throw new Error(`collectUnits: config.${name} must be a non-negative integer`);
  }
  return value;
}

function normalizeFiles(files) {
  if (files === undefined || files === null) return [];
  const list = typeof files === 'string' ? [files] : files;
  if (!Array.isArray(list) || list.some((item) => typeof item !== 'string')) {
    throw new TypeError('collectUnits: files must be a string or an array of strings');
  }
  return list.filter((item) => item.length > 0);
}

function sameStringSet(a, b) {
  if (a.length !== b.length) return false;
  const left = [...a].sort();
  const right = [...b].sort();
  return left.every((value, index) => value === right[index]);
}

/* ------------------------------------------------------------------- scope */

function matchesScope(path, cfg) {
  const included = cfg.pathMatchers.length === 0
    ? true
    : cfg.pathMatchers.some((matcher) => matcher.test(path));
  if (!included) return false;
  return !cfg.excludeMatchers.some((matcher) => matcher.test(path));
}

function scopeReason(path, cfg) {
  const included = cfg.pathMatchers.length === 0
    ? true
    : cfg.pathMatchers.some((matcher) => matcher.test(path));
  return included ? 'excluded by config.exclude' : 'not included by config.paths';
}

function compileGlob(pattern) {
  if (typeof pattern !== 'string') {
    throw new Error('collectUnits: glob patterns must be strings');
  }
  return new RegExp(globSource(pattern));
}

function globSource(pattern) {
  let source = '^';
  let index = 0;
  while (index < pattern.length) {
    const char = pattern[index];
    if (char === '*') {
      if (pattern[index + 1] === '*') {
        index += 2;
        if (pattern[index] === '/') {
          source += '(?:[^/]+/)*';
          index += 1;
        } else {
          source += '.*';
        }
      } else {
        source += '[^/]*';
        index += 1;
      }
      continue;
    }
    if (char === '?') {
      source += '[^/]';
      index += 1;
      continue;
    }
    if (char === '[') {
      let cursor = index + 1;
      let negated = false;
      if (pattern[cursor] === '!' || pattern[cursor] === '^') {
        negated = true;
        cursor += 1;
      }
      let body = '';
      if (pattern[cursor] === ']') {
        body += '\\]';
        cursor += 1;
      }
      while (cursor < pattern.length && pattern[cursor] !== ']') {
        body += pattern[cursor] === '\\' ? '\\\\' : pattern[cursor];
        cursor += 1;
      }
      if (cursor >= pattern.length) {
        source += '\\[';
        index += 1;
        continue;
      }
      source += `[${negated ? '^' : ''}${body}]`;
      index = cursor + 1;
      continue;
    }
    source += /[\\^$.*+?()[\]{}|]/.test(char) ? `\\${char}` : char;
    index += 1;
  }
  return `${source}$`;
}

/* ------------------------------------------------------------- diff parser */

/**
 * Parse `jj diff --git` output into file entries. Paths are resolved from
 * `---`/`+++`, then rename/copy metadata, then the `diff --git` header.
 */
function parseGitDiff(text) {
  const files = [];
  let file = null;
  let hunk = null;

  const lines = String(text ?? '').split('\n');
  if (lines.length > 0 && lines[lines.length - 1] === '') lines.pop();

  for (const line of lines) {
    if (line.startsWith('diff --git ')) {
      const headerPaths = parseDiffGitHeader(line);
      file = {
        diffHeader: line,
        oldPath: headerPaths.oldPath,
        newPath: headerPaths.newPath,
        oldDevNull: false,
        newDevNull: false,
        renameFrom: null,
        renameTo: null,
        oldMode: null,
        newMode: null,
        indexMode: null,
        status: null,
        sourceType: null,
        targetType: null,
        binary: false,
        hunks: [],
        parseIssues: [],
      };
      files.push(file);
      hunk = null;
      continue;
    }

    if (file == null) continue;

    if (line.startsWith('@@ ')) {
      const match = HUNK_RE.exec(line);
      if (!match) {
        file.parseIssues.push(`malformed hunk header: ${line}`);
        hunk = null;
        continue;
      }
      hunk = {
        header: line,
        oldStart: Number(match[1]),
        oldCount: match[2] === undefined ? 1 : Number(match[2]),
        newStart: Number(match[3]),
        newCount: match[4] === undefined ? 1 : Number(match[4]),
        section: match[5] ?? '',
        body: [],
        oldSeen: 0,
        newSeen: 0,
        lastSign: null,
        oldNoNewline: false,
        newNoNewline: false,
      };
      file.hunks.push(hunk);
      continue;
    }

    if (hunk != null) {
      const sign = line[0];
      if (sign === ' ') {
        hunk.oldSeen += 1;
        hunk.newSeen += 1;
        hunk.lastSign = ' ';
      } else if (sign === '+') {
        hunk.newSeen += 1;
        hunk.lastSign = '+';
      } else if (sign === '-') {
        hunk.oldSeen += 1;
        hunk.lastSign = '-';
      } else if (sign === '\\') {
        if (hunk.lastSign === '-') {
          hunk.oldNoNewline = true;
        } else if (hunk.lastSign === '+') {
          hunk.newNoNewline = true;
        } else if (hunk.lastSign === ' ') {
          hunk.oldNoNewline = true;
          hunk.newNoNewline = true;
        } else {
          file.parseIssues.push(`newline marker without a preceding line: ${line}`);
        }
      } else if (line !== '') {
        file.parseIssues.push(`unexpected diff body line: ${JSON.stringify(line)}`);
      }
      hunk.body.push(line);
      continue;
    }

    if (line.startsWith('--- ')) {
      const parsed = parsePathLine(line.slice(4), 'a/');
      file.oldPath = parsed.path;
      file.oldDevNull = parsed.devNull;
      continue;
    }
    if (line.startsWith('+++ ')) {
      const parsed = parsePathLine(line.slice(4), 'b/');
      file.newPath = parsed.path;
      file.newDevNull = parsed.devNull;
      continue;
    }

    const indexMatch = INDEX_RE.exec(line);
    if (indexMatch) {
      if (indexMatch[1]) file.indexMode = indexMatch[1];
      continue;
    }

    let match = /^new file mode ([0-7]{6})$/.exec(line);
    if (match) {
      file.newMode = match[1];
      continue;
    }
    match = /^deleted file mode ([0-7]{6})$/.exec(line);
    if (match) {
      file.oldMode = match[1];
      continue;
    }
    match = /^old mode ([0-7]{6})$/.exec(line);
    if (match) {
      file.oldMode = match[1];
      continue;
    }
    match = /^new mode ([0-7]{6})$/.exec(line);
    if (match) {
      file.newMode = match[1];
      continue;
    }

    if (line.startsWith('rename from ')) {
      file.renameFrom = decodePathToken(line.slice('rename from '.length));
      continue;
    }
    if (line.startsWith('rename to ')) {
      file.renameTo = decodePathToken(line.slice('rename to '.length));
      continue;
    }
    if (line.startsWith('copy from ')) {
      file.renameFrom = decodePathToken(line.slice('copy from '.length));
      continue;
    }
    if (line.startsWith('copy to ')) {
      file.renameTo = decodePathToken(line.slice('copy to '.length));
      continue;
    }

    if (line.startsWith('Binary files ') || line === 'GIT binary patch') {
      file.binary = true;
      continue;
    }
    // Similarity/index metadata and unknown header lines are not needed for
    // unit construction. Content lines can only appear inside a hunk.
  }

  for (const entry of files) {
    if (entry.renameFrom != null && entry.oldPath == null) {
      entry.oldPath = entry.renameFrom;
    }
    if (entry.renameTo != null && entry.newPath == null) {
      entry.newPath = entry.renameTo;
    }
    if (entry.oldDevNull) entry.oldPath = null;
    if (entry.newDevNull) entry.newPath = null;
  }

  return files;
}

function parseDiffGitHeader(line) {
  const rest = line.slice('diff --git '.length);
  if (rest.startsWith('"')) {
    const match = /^("(?:[^"\\]|\\.)*")\s+("(?:[^"\\]|\\.)*")$/.exec(rest);
    if (match) {
      return {
        oldPath: normalizeRepoPath(stripPathPrefix(unquoteGitPath(match[1]), 'a/')),
        newPath: normalizeRepoPath(stripPathPrefix(unquoteGitPath(match[2]), 'b/')),
      };
    }
  }

  const splitAt = rest.lastIndexOf(' b/');
  if (splitAt >= 0) {
    const oldToken = rest.slice(0, splitAt);
    const newToken = rest.slice(splitAt + 1);
    return {
      oldPath: normalizeRepoPath(stripPathPrefix(decodePathToken(oldToken), 'a/')),
      newPath: normalizeRepoPath(stripPathPrefix(decodePathToken(newToken), 'b/')),
    };
  }

  const halves = rest.split(' ');
  if (halves.length === 2) {
    return {
      oldPath: normalizeRepoPath(stripPathPrefix(decodePathToken(halves[0]), 'a/')),
      newPath: normalizeRepoPath(stripPathPrefix(decodePathToken(halves[1]), 'b/')),
    };
  }

  return { oldPath: null, newPath: null };
}

function parsePathLine(raw, prefix) {
  const token = raw.endsWith('\t') ? raw.slice(0, -1) : raw;
  if (token === '/dev/null') return { path: null, devNull: true };
  const decoded = token.startsWith('"') ? unquoteGitPath(token) : token;
  return {
    path: normalizeRepoPath(stripPathPrefix(decoded, prefix)),
    devNull: false,
  };
}

function stripPathPrefix(path, prefix) {
  return path.startsWith(prefix) ? path.slice(prefix.length) : path;
}

function decodePathToken(token) {
  const trimmed = token.endsWith('\t') ? token.slice(0, -1) : token;
  return normalizeRepoPath(trimmed.startsWith('"') ? unquoteGitPath(trimmed) : trimmed);
}

function normalizeRepoPath(path) {
  return path.startsWith('./') ? path.slice(2) : path;
}

/**
 * Decode a git C-quoted path. Octal/hex escapes are bytes (decoded as UTF-8),
 * \u/\U escapes are Unicode code points.
 */
function unquoteGitPath(quoted) {
  const body = quoted.endsWith('"') ? quoted.slice(1, -1) : quoted.slice(1);
  let output = '';
  const bytes = [];
  const flush = () => {
    if (bytes.length === 0) return;
    output += new TextDecoder().decode(Uint8Array.from(bytes));
    bytes.length = 0;
  };

  for (let index = 0; index < body.length; index += 1) {
    const char = body[index];
    if (char !== '\\') {
      flush();
      output += char;
      continue;
    }

    const next = body[index + 1];
    if (next === undefined) {
      flush();
      output += '\\';
      break;
    }
    index += 1;

    if (next >= '0' && next <= '7') {
      let digits = next;
      for (let extra = 0; extra < 2; extra += 1) {
        const candidate = body[index + 1];
        if (candidate >= '0' && candidate <= '7') {
          digits += candidate;
          index += 1;
        } else {
          break;
        }
      }
      bytes.push(Number.parseInt(digits, 8) & 0xff);
      continue;
    }

    if (next === 'x') {
      const hex = body.slice(index + 1, index + 3);
      if (/^[0-9a-fA-F]{2}$/.test(hex)) {
        index += 2;
        bytes.push(Number.parseInt(hex, 16));
      } else {
        flush();
        output += 'x';
      }
      continue;
    }

    if (next === 'u' || next === 'U') {
      const width = next === 'u' ? 4 : 8;
      const hex = body.slice(index + 1, index + 1 + width);
      if (hex.length === width && /^[0-9a-fA-F]+$/.test(hex)) {
        const codePoint = Number.parseInt(hex, 16);
        if (codePoint <= 0x10ffff) {
          flush();
          output += String.fromCodePoint(codePoint);
          index += width;
          continue;
        }
      }
      flush();
      output += next;
      continue;
    }

    flush();
    if (next === 'n') output += '\n';
    else if (next === 't') output += '\t';
    else if (next === 'r') output += '\r';
    else if (next === 'b') output += '\b';
    else if (next === 'f') output += '\f';
    else if (next === 'v') output += '\v';
    else if (next === 'a') output += '\x07';
    else output += next;
  }

  flush();
  return output;
}

function nonRegularMode(file) {
  const modes = [file.oldMode, file.newMode, file.indexMode].filter(Boolean);
  return modes.find((mode) => !REGULAR_MODES.has(mode)) ?? null;
}

const NON_REGULAR_TYPES = new Set(['symlink', 'tree', 'git-submodule', 'conflict']);

function nonRegularFileType(file) {
  if (file.sourceType && NON_REGULAR_TYPES.has(file.sourceType)) {
    return `${file.sourceType} (before)`;
  }
  if (file.targetType && NON_REGULAR_TYPES.has(file.targetType)) {
    return `${file.targetType} (after)`;
  }
  return null;
}

function fileKey(file) {
  return file.newPath ?? file.oldPath ?? file.diffHeader;
}

function parseManifest(text) {
  const entries = [];
  for (const line of String(text ?? '').split('\n')) {
    if (line.trim().length === 0) continue;
    let parsed;
    try {
      parsed = JSON.parse(line);
    } catch (error) {
      throw new Error(`invalid JSON line ${JSON.stringify(line)}: ${error.message}`);
    }
    if (parsed == null || typeof parsed !== 'object') {
      throw new Error(`manifest entry is not an object: ${line}`);
    }
    entries.push({
      path: typeof parsed.path === 'string' ? normalizeRepoPath(parsed.path) : null,
      source:
        typeof parsed.source === 'string' && parsed.source.length > 0
          ? normalizeRepoPath(parsed.source)
          : null,
      status: typeof parsed.status === 'string' ? parsed.status : null,
      sourceType: typeof parsed.sourceType === 'string' ? parsed.sourceType : null,
      targetType: typeof parsed.targetType === 'string' ? parsed.targetType : null,
    });
  }
  return entries;
}

/**
 * Overlay authoritative paths/status/types from the JSONL manifest. The
 * manifest and git diff render the same TreeDiff.files() order.
 */
function applyManifest(files, manifest) {
  for (let index = 0; index < files.length; index += 1) {
    const file = files[index];
    const entry = manifest[index];
    const target = entry.path;
    const source = entry.source;

    file.status = entry.status;
    file.sourceType = entry.sourceType;
    file.targetType = entry.targetType;

    if (entry.status === 'added') {
      file.oldPath = null;
      file.newPath = target;
    } else if (entry.status === 'removed') {
      file.oldPath = source ?? target;
      file.newPath = null;
    } else if (entry.status === 'renamed' || entry.status === 'copied') {
      file.oldPath = source;
      file.newPath = target;
    } else {
      file.newPath = target;
      file.oldPath = source ?? target;
    }
  }
}

/* --------------------------------------------------------- reconstruction */

/**
 * Rebuild complete old/new line arrays from the full-context diff. A single
 * hunk starting at line 1 (line 0 for an empty side) is required; anything
 * else is rejected rather than silently treated as a whole file.
 */
function reconstructFull(file) {
  if (file.parseIssues.length > 0) {
    return { error: file.parseIssues.join('; ') };
  }
  if (file.hunks.length !== 1) {
    return {
      error: `expected 1 full-context hunk, found ${file.hunks.length}; file content would be incomplete`,
    };
  }

  const hunk = file.hunks[0];
  if (hunk.oldSeen !== hunk.oldCount || hunk.newSeen !== hunk.newCount) {
    return {
      error: `hunk line counts disagree with header (header -${hunk.oldCount} +${hunk.newCount}, body -${hunk.oldSeen} +${hunk.newSeen})`,
    };
  }
  if (hunk.oldCount === 0 ? hunk.oldStart !== 0 : hunk.oldStart !== 1) {
    return {
      error: `full-context old side starts at ${hunk.oldStart}, expected ${hunk.oldCount === 0 ? 0 : 1}`,
    };
  }
  if (hunk.newCount === 0 ? hunk.newStart !== 0 : hunk.newStart !== 1) {
    return {
      error: `full-context new side starts at ${hunk.newStart}, expected ${hunk.newCount === 0 ? 0 : 1}`,
    };
  }

  const oldLines = [];
  const newLines = [];
  for (const raw of hunk.body) {
    const sign = raw[0];
    if (sign === ' ') {
      oldLines.push(raw.slice(1));
      newLines.push(raw.slice(1));
    } else if (sign === '-') {
      oldLines.push(raw.slice(1));
    } else if (sign === '+') {
      newLines.push(raw.slice(1));
    } else if (sign !== '\\') {
      return { error: `unexpected full-context line ${JSON.stringify(raw)}` };
    }
  }

  if (oldLines.length !== hunk.oldCount) {
    return { error: `reconstructed ${oldLines.length} old lines, header says ${hunk.oldCount}` };
  }
  if (newLines.length !== hunk.newCount) {
    return { error: `reconstructed ${newLines.length} new lines, header says ${hunk.newCount}` };
  }

  return {
    oldLines,
    newLines,
    oldNoNewline: hunk.oldNoNewline,
    newNoNewline: hunk.newNoNewline,
  };
}

function validateHunk(hunk, recon, path) {
  const issues = [];
  if (hunk.oldSeen !== hunk.oldCount || hunk.newSeen !== hunk.newCount) {
    issues.push(
      `${path}: malformed hunk ${hunk.header}: body sees -${hunk.oldSeen} +${hunk.newSeen}, header says -${hunk.oldCount} +${hunk.newCount}`,
    );
  }

  checkSide(hunk, recon.oldLines, 'old', path, issues);
  checkSide(hunk, recon.newLines, 'new', path, issues);
  return issues;
}

function checkSide(hunk, lines, side, path, issues) {
  const isOld = side === 'old';
  const start = isOld ? hunk.oldStart : hunk.newStart;
  const count = isOld ? hunk.oldCount : hunk.newCount;
  const actual = [];
  for (const raw of hunk.body) {
    const sign = raw[0];
    if (
      sign === ' ' ||
      (isOld && sign === '-') ||
      (!isOld && sign === '+')
    ) {
      actual.push(raw.slice(1));
    }
  }

  if (actual.length !== count) {
    issues.push(
      `${path}: hunk ${hunk.header} ${side} body has ${actual.length} lines but header says ${count}`,
    );
  }

  if (count === 0) {
    if (start < 0 || start > lines.length) {
      issues.push(
        `${path}: hunk ${hunk.header} ${side} insertion point ${start} is outside 0..${lines.length}`,
      );
    }
    return;
  }

  if (start < 1 || start + count - 1 > lines.length) {
    issues.push(
      `${path}: hunk ${hunk.header} ${side} range ${start},${count} exceeds reconstructed file (${lines.length} lines)`,
    );
    return;
  }

  const expected = lines.slice(start - 1, start - 1 + count);
  const limit = Math.min(expected.length, actual.length);
  for (let index = 0; index < limit; index += 1) {
    if (expected[index] !== actual[index]) {
      issues.push(
        `${path}: hunk ${hunk.header} ${side} content mismatch at line ${start + index}: full diff ${JSON.stringify(expected[index])}, zero-context diff ${JSON.stringify(actual[index])}`,
      );
      break;
    }
  }
}

/* ------------------------------------------------------------------- units */

/**
 * Explicit whole-file mode: one unit per changed file. `hunk.diff` is the
 * complete target file text (old text for a deletion), not a changed-only
 * hunk. Scope is distinct from contextMode; the runner labels it at run level.
 */
function buildWholeFileUnit({ exactFile, recon, path, oldPath }) {
  const issues = [];
  for (const issue of exactFile.parseIssues) {
    issues.push(`${path}: ${issue}`);
  }
  for (const hunk of exactFile.hunks) {
    issues.push(...validateHunk(hunk, recon, path));
  }

  // Target existence, not line count: a file can be modified to empty content.
  const useNew = exactFile.newPath != null;
  const lines = useNew ? recon.newLines : recon.oldLines;
  const noNewline = useNew ? recon.newNoNewline : recon.oldNoNewline;
  const content = lines.length === 0
    ? ''
    : `${lines.join('\n')}${noNewline ? '' : '\n'}`;

  const oldCount = recon.oldLines.length;
  const newCount = recon.newLines.length;

  return {
    id: `${path}@whole`,
    path,
    oldPath: oldPath != null && oldPath !== path ? oldPath : null,
    hunk: {
      oldStart: oldCount > 0 ? 1 : 0,
      oldCount,
      newStart: newCount > 0 ? 1 : 0,
      newCount,
      diff: content,
    },
    context: { before: [], after: [] },
    issues,
  };
}

function buildUnit({
  exactFile,
  hunk,
  index,
  recon,
  cfg,
  nodeChainAt,
  path,
  oldPath,
}) {
  const issues = [];
  for (const issue of exactFile.parseIssues) {
    issues.push(`${path}: ${issue}`);
  }
  issues.push(...validateHunk(hunk, recon, path));

  const usesNew = hunk.newCount > 0 || hunk.oldCount === 0;
  const primaryLines = usesNew ? recon.newLines : recon.oldLines;
  const primaryPath = usesNew
    ? exactFile.newPath ?? path
    : exactFile.oldPath ?? path;

  const rawStart = usesNew ? hunk.newStart : hunk.oldStart;
  const rawEnd = rawStart + (usesNew ? hunk.newCount : hunk.oldCount) - 1;
  let changedStart = Math.max(1, Math.min(primaryLines.length || 1, rawStart));
  let changedEnd = Math.max(0, Math.min(primaryLines.length, rawEnd));
  if (changedEnd < changedStart) {
    // Keep a stable position for malformed/empty primary sides.
    changedStart = Math.max(1, Math.min(primaryLines.length || 1, rawStart));
    changedEnd = changedStart - 1;
  }

  const rawRegion = regionAround(primaryLines, changedStart, changedEnd, cfg.contextLines);
  let regions = [];

  if (cfg.contextMode === 'file') {
    if (primaryLines.length > 0) regions = [[1, primaryLines.length]];
  } else if (cfg.contextMode === 'hunk') {
    if (rawRegion) regions = [rawRegion];
  } else {
    const ast = collectFunctionSpans({
      lines: primaryLines,
      path: primaryPath,
      start: changedStart,
      end: changedEnd,
      functionKinds: cfg.functionKinds,
      nodeChainAt,
    });

    for (const unsupported of ast.unsupported) {
      issues.push(
        `${path}: unsupported-context: changed lines ${unsupported[0]}-${unsupported[1]} have no enclosing AST node matching functionKinds ${JSON.stringify(cfg.functionKindsSource)} (hunk ${hunk.header}); raw hunk +/- ${cfg.contextLines} lines shown, not a whole-function claim`,
      );
    }
    issues.push(...ast.issues);

    regions = ast.spans.map((span) => [
      Math.max(1, span.startLine - cfg.contextLines),
      Math.min(primaryLines.length, span.endLine + cfg.contextLines),
    ]);
    if (ast.spans.length === 0 && rawRegion) {
      regions = [rawRegion];
    } else if (ast.unsupported.length > 0 && rawRegion) {
      regions.push(rawRegion);
    }
    regions = mergeRegions(regions, primaryLines.length);
  }

  const context = splitContext(primaryLines, regions, changedStart, changedEnd);

  return {
    id: `${path}@-${hunk.oldStart},${hunk.oldCount}+${hunk.newStart},${hunk.newCount}#${index}`,
    path,
    oldPath: oldPath != null && oldPath !== path ? oldPath : null,
    hunk: {
      oldStart: hunk.oldStart,
      oldCount: hunk.oldCount,
      newStart: hunk.newStart,
      newCount: hunk.newCount,
      diff: [hunk.header, ...hunk.body].join('\n'),
    },
    context,
    issues,
  };
}

function regionAround(lines, start, end, contextLines) {
  if (lines.length === 0) return null;
  const from = Math.max(1, start - contextLines);
  const to = Math.min(lines.length, Math.max(end, start) + contextLines);
  if (to < from) return null;
  return [from, to];
}

function mergeRegions(regions, lineCount) {
  const cleaned = regions
    .map(([start, end]) => [
      Math.max(1, start),
      Math.min(lineCount, end),
    ])
    .filter(([start, end]) => start <= end)
    .sort((a, b) => a[0] - b[0] || a[1] - b[1]);

  const merged = [];
  for (const region of cleaned) {
    const last = merged[merged.length - 1];
    if (last != null && region[0] <= last[1] + 1) {
      last[1] = Math.max(last[1], region[1]);
    } else {
      merged.push([region[0], region[1]]);
    }
  }
  return merged;
}

function splitContext(lines, regions, changedStart, changedEnd) {
  const before = [];
  const after = [];

  for (const [start, end] of regions) {
    if (start < changedStart) {
      pushExcerpt(before, lines, start, Math.min(end, changedStart - 1));
    }
    if (end > changedEnd) {
      pushExcerpt(after, lines, Math.max(start, changedEnd + 1), end);
    }
  }

  return { before, after };
}

function pushExcerpt(target, lines, start, end) {
  if (start > end || start < 1 || end > lines.length) return;
  target.push({
    startLine: start,
    endLine: end,
    text: lines.slice(start - 1, end).join('\n'),
  });
}

/* ------------------------------------------------------ function contexts */

/**
 * Walk one side's changed range and collect every matching function-like span
 * that touches it. Ranges outside supported constructs are reported rather
 * than widened into an enclosing-function claim.
 */
function collectFunctionSpans({
  lines,
  path,
  start,
  end,
  functionKinds,
  nodeChainAt,
}) {
  const spans = [];
  const unsupported = [];
  const issues = [];

  const markUnsupported = (from, to) => {
    let left = Math.max(1, from);
    let right = Math.min(lines.length, to);
    if (left > right) return;
    if (!/\S/.test(lines.slice(left - 1, right).join('\n'))) return;
    const last = unsupported[unsupported.length - 1];
    if (last != null && left <= last[1] + 1) {
      last[1] = Math.max(last[1], right);
    } else {
      unsupported.push([left, right]);
    }
  };

  const code = lines.join('\n');

  try {
    let line = start;
    while (line <= end) {
      const probe = findProbeLine(lines, line, end);
      if (probe == null) {
        markUnsupported(line, end);
        break;
      }

      const chain = nodeChainAt({ code, path, line: probe });
      if (chain == null) {
        markUnsupported(line, end);
        break;
      }

      const matching = Array.isArray(chain)
        ? chain.filter(
            (node) =>
              node != null &&
              typeof node.startLine === 'number' &&
              typeof node.endLine === 'number' &&
              functionKinds.test(node.kind),
          )
        : [];

      const probeInRange = probe >= line && probe <= end;
      if (!probeInRange) {
        const covering = matching
          .filter((node) => node.startLine <= line && node.endLine >= end)
          .sort(bySpanSize)[0];
        if (covering) {
          spans.push({ startLine: covering.startLine, endLine: covering.endLine });
        }
        break;
      }

      if (matching.length === 0) {
        markUnsupported(line, probe);
        line = probe + 1;
        continue;
      }

      const covering = matching
        .filter((node) => node.startLine <= line && node.endLine >= end)
        .sort(bySpanSize)[0];
      if (covering) {
        spans.push({ startLine: covering.startLine, endLine: covering.endLine });
        break;
      }

      // The range crosses a supported boundary. Take the outermost matching
      // node at this probe, report any prefix it does not cover, then continue
      // at the next line so a following function in the same hunk is included.
      const node = matching[matching.length - 1];
      if (node.startLine > line) {
        markUnsupported(line, node.startLine - 1);
      }
      spans.push({ startLine: node.startLine, endLine: node.endLine });
      if (node.endLine >= end) break;
      line = Math.max(node.endLine + 1, probe + 1);
    }
  } catch (error) {
    issues.push(
      `${path}: ast-error: nodeChainAt failed for lines ${start}-${end}: ${error?.message ?? error}; raw hunk +/- context shown`,
    );
    markUnsupported(start, end);
  }

  return {
    spans: mergeSpans(spans),
    unsupported,
    issues,
  };
}

function bySpanSize(a, b) {
  return (a.endLine - a.startLine) - (b.endLine - b.startLine);
}

function findProbeLine(lines, start, end) {
  for (let line = start; line <= end; line += 1) {
    if (line >= 1 && line <= lines.length && /\S/.test(lines[line - 1])) {
      return line;
    }
  }
  for (let line = Math.min(start - 1, lines.length); line >= 1; line -= 1) {
    if (/\S/.test(lines[line - 1])) return line;
  }
  for (let line = Math.max(end + 1, 1); line <= lines.length; line += 1) {
    if (/\S/.test(lines[line - 1])) return line;
  }
  return null;
}

function mergeSpans(spans) {
  const sorted = spans
    .map((span) => ({ startLine: span.startLine, endLine: span.endLine }))
    .sort((a, b) => a.startLine - b.startLine || a.endLine - b.endLine);

  const merged = [];
  for (const span of sorted) {
    const last = merged[merged.length - 1];
    if (last != null && span.startLine <= last.endLine + 1) {
      last.endLine = Math.max(last.endLine, span.endLine);
    } else {
      merged.push(span);
    }
  }
  return merged;
}
