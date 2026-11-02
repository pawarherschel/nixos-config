import { test } from 'bun:test';
import assert from 'node:assert/strict';

import { collectUnits } from './collection.mjs';

function jsonl(entries) {
  return `${entries.map((entry) => JSON.stringify(entry)).join('\n')}\n`;
}

function makeExec({ exact, full, manifest }) {
  const calls = [];
  const exec = async (argv) => {
    calls.push([...argv]);
    if (argv[1] === 'op') return 'op-test-1\n';
    if (argv.includes('--context')) {
      const context = argv[argv.indexOf('--context') + 1];
      return context === '0' ? exact : full;
    }
    return jsonl(manifest);
  };
  return { exec, calls };
}

async function run({
  exact,
  full,
  manifest,
  config = {},
  nodeChainAt = () => null,
  wholeFiles = false,
}) {
  const { exec, calls } = makeExec({ exact, full, manifest });
  const result = await collectUnits({
    cwd: '/repo',
    revset: 'test-revset',
    config,
    nodeChainAt,
    exec,
    wholeFiles,
  });
  return { result, calls };
}

test('keeps A1 A2 B1 B2 hunks separate with exact zero-context ranges', async () => {
  const exact = `diff --git a/src/a.ts b/src/a.ts
index 1111111111..2222222222 100644
--- a/src/a.ts
+++ b/src/a.ts
@@ -2,1 +2,1 @@
-line2
+LINE2
@@ -4,1 +4,1 @@
-line4
+LINE4
@@ -7,1 +7,1 @@
-line7
+LINE7
@@ -10,1 +10,1 @@
-line10
+LINE10
`;
  const full = `diff --git a/src/a.ts b/src/a.ts
index 1111111111..2222222222 100644
--- a/src/a.ts
+++ b/src/a.ts
@@ -1,13 +1,13 @@
 line1
-line2
+LINE2
 line3
-line4
+LINE4
 line5
 line6
-line7
+LINE7
 line8
 line9
-line10
+LINE10
 line11
 line12
 line13
`;
  const manifest = [
    {
      path: 'src/a.ts',
      source: 'src/a.ts',
      status: 'modified',
      sourceType: 'file',
      targetType: 'file',
    },
  ];

  const chain = () => [{ startLine: 1, endLine: 13, kind: 'function_declaration' }];
  const { result } = await run({
    exact,
    full,
    manifest,
    config: { contextLines: 1 },
    nodeChainAt: chain,
  });

  assert.equal(result.units.length, 4);
  assert.deepEqual(
    result.units.map((unit) => [
      unit.hunk.oldStart,
      unit.hunk.oldCount,
      unit.hunk.newStart,
      unit.hunk.newCount,
    ]),
    [
      [2, 1, 2, 1],
      [4, 1, 4, 1],
      [7, 1, 7, 1],
      [10, 1, 10, 1],
    ],
  );
  assert.ok(result.units.every((unit) => unit.issues.length === 0));
  assert.equal(result.units[0].context.before[0].text, 'line1');
  assert.match(result.units[0].context.after[0].text, /^line3\n/);
});

test('deletion ranges cover both file boundaries without overrunning sides', async () => {
  const exact = `diff --git a/src/d.txt b/src/d.txt
index 1111111111..2222222222 100644
--- a/src/d.txt
+++ b/src/d.txt
@@ -1,1 +0,0 @@
-a
@@ -4,1 +2,0 @@
-d
`;
  const full = `diff --git a/src/d.txt b/src/d.txt
index 1111111111..2222222222 100644
--- a/src/d.txt
+++ b/src/d.txt
@@ -1,4 +1,2 @@
-a
 b
 c
-d
`;
  const manifest = [
    {
      path: 'src/d.txt',
      source: 'src/d.txt',
      status: 'modified',
      sourceType: 'file',
      targetType: 'file',
    },
  ];

  const { result } = await run({
    exact,
    full,
    manifest,
    config: { contextMode: 'hunk', contextLines: 1 },
  });

  assert.equal(result.units.length, 2);
  const [first, last] = result.units;
  assert.deepEqual(
    [first.hunk.oldStart, first.hunk.oldCount, first.hunk.newStart, first.hunk.newCount],
    [1, 1, 0, 0],
  );
  assert.equal(first.context.before.length, 0);
  assert.equal(first.context.after[0].text, 'b');

  assert.deepEqual(
    [last.hunk.oldStart, last.hunk.oldCount, last.hunk.newStart, last.hunk.newCount],
    [4, 1, 2, 0],
  );
  assert.equal(last.context.before[0].text, 'c');
  assert.equal(last.context.after.length, 0);
  assert.ok(result.units.every((unit) => unit.issues.length === 0));
});

test('selects the function span and falls back to raw hunk context outside it', async () => {
  const exact = `diff --git a/src/f.rs b/src/f.rs
index 1111111111..2222222222 100644
--- a/src/f.rs
+++ b/src/f.rs
@@ -2,1 +2,1 @@
-    a();
+    A();
@@ -6,1 +6,1 @@
-top();
+TOP();
`;
  const full = `diff --git a/src/f.rs b/src/f.rs
index 1111111111..2222222222 100644
--- a/src/f.rs
+++ b/src/f.rs
@@ -1,11 +1,11 @@
 fn one() {
-    a();
+    A();
     b();
 }
 // gap
-top();
+TOP();
 // gap
 fn two() {
     c();
     d();
 }
`;
  const manifest = [
    {
      path: 'src/f.rs',
      source: 'src/f.rs',
      status: 'modified',
      sourceType: 'file',
      targetType: 'file',
    },
  ];

  const nodeChainAt = ({ line }) => {
    if (line >= 1 && line <= 4) {
      return [{ startLine: 1, endLine: 4, kind: 'function_item' }];
    }
    if (line >= 8 && line <= 11) {
      return [{ startLine: 8, endLine: 11, kind: 'function_item' }];
    }
    return null;
  };

  const { result } = await run({
    exact,
    full,
    manifest,
    config: { contextLines: 1 },
    nodeChainAt,
  });

  assert.equal(result.units.length, 2);
  const [inside, outside] = result.units;

  assert.equal(inside.issues.length, 0);
  assert.equal(inside.context.before[0].text, 'fn one() {');
  assert.match(inside.context.after[0].text, /^    b\(\);\n}\n\/\/ gap$/);

  assert.ok(outside.issues.some((issue) => issue.includes('unsupported-context')));
  assert.deepEqual(
    outside.context.before.map((chunk) => [chunk.startLine, chunk.endLine]),
    [[5, 5]],
  );
  assert.deepEqual(
    outside.context.after.map((chunk) => [chunk.startLine, chunk.endLine]),
    [[7, 7]],
  );
});

test('rename resolves both paths and preserves no-newline markers', async () => {
  const exact = `diff --git a/old.txt b/new.txt
rename from old.txt
rename to new.txt
similarity index 50%
index 1111111111..2222222222 100644
--- a/old.txt
+++ b/new.txt
@@ -2,1 +2,1 @@
-beta
\\ No newline at end of file
+BETA
\\ No newline at end of file
`;
  const full = `diff --git a/old.txt b/new.txt
rename from old.txt
rename to new.txt
similarity index 50%
index 1111111111..2222222222 100644
--- a/old.txt
+++ b/new.txt
@@ -1,2 +1,2 @@
 alpha
-beta
\\ No newline at end of file
+BETA
\\ No newline at end of file
`;
  const manifest = [
    {
      path: 'new.txt',
      source: 'old.txt',
      status: 'renamed',
      sourceType: 'file',
      targetType: 'file',
    },
  ];

  const { result } = await run({
    exact,
    full,
    manifest,
    config: { contextMode: 'hunk', contextLines: 1 },
  });

  assert.equal(result.units.length, 1);
  const [unit] = result.units;
  assert.equal(unit.path, 'new.txt');
  assert.equal(unit.oldPath, 'old.txt');
  assert.equal(unit.hunk.diff.match(/\\ No newline at end of file/g)?.length, 2);
  assert.equal(unit.context.before[0].text, 'alpha');
  assert.equal(unit.context.after.length, 0);
  assert.ok(unit.issues.length === 0);
});

test('manifest paths win over newline-bearing diff headers', async () => {
  const exact = `diff --git a/new
line.txt b/new
line.txt
index 1111111111..2222222222 100644
--- a/new
line.txt
+++ b/new
line.txt
@@ -2,1 +2,1 @@
-b
+B
`;
  const full = `diff --git a/new
line.txt b/new
line.txt
index 1111111111..2222222222 100644
--- a/new
line.txt
+++ b/new
line.txt
@@ -1,2 +1,2 @@
 a
-b
+B
`;
  const manifest = [
    {
      path: 'new\nline.txt',
      source: 'new\nline.txt',
      status: 'modified',
      sourceType: 'file',
      targetType: 'file',
    },
  ];

  const { result } = await run({
    exact,
    full,
    manifest,
    config: { contextMode: 'hunk', contextLines: 0 },
  });

  assert.equal(result.units.length, 1);
  assert.equal(result.units[0].path, 'new\nline.txt');
  assert.equal(result.units[0].oldPath, null);
});

test('wholeFiles returns one unit per file with the complete target content', async () => {
  const exact = `diff --git a/w.txt b/w.txt
index 1111111111..2222222222 100644
--- a/w.txt
+++ b/w.txt
@@ -1,1 +1,1 @@
-a
+A
@@ -3,1 +3,1 @@
-c
+C
`;
  const full = `diff --git a/w.txt b/w.txt
index 1111111111..2222222222 100644
--- a/w.txt
+++ b/w.txt
@@ -1,3 +1,3 @@
-a
+A
 b
-c
+C
`;
  const manifest = [
    {
      path: 'w.txt',
      source: 'w.txt',
      status: 'modified',
      sourceType: 'file',
      targetType: 'file',
    },
  ];

  const { result } = await run({
    exact,
    full,
    manifest,
    config: { contextMode: 'hunk', contextLines: 0 },
    nodeChainAt: () => {
      throw new Error('whole-file mode must not query the AST');
    },
    wholeFiles: true,
  });

  assert.equal(result.units.length, 1);
  const [unit] = result.units;
  assert.equal(unit.id, 'w.txt@whole');
  assert.equal(unit.hunk.diff, 'A\nb\nC\n');
  assert.deepEqual(
    [unit.hunk.oldStart, unit.hunk.oldCount, unit.hunk.newStart, unit.hunk.newCount],
    [1, 3, 1, 3],
  );
  assert.deepEqual(unit.context, { before: [], after: [] });
  assert.ok(unit.issues.length === 0);
});

test('skips binary and non-regular files with reasons', async () => {
  const exact = `diff --git a/blob.bin b/blob.bin
new file mode 100644
index 0000000000..1111111111
Binary files /dev/null and b/blob.bin differ
diff --git a/link b/link
new file mode 120000
index 0000000000..2222222222
--- /dev/null
+++ b/link
@@ -0,0 +1,1 @@
+target
`;
  const full = exact;
  const manifest = [
    {
      path: 'blob.bin',
      source: 'blob.bin',
      status: 'added',
      sourceType: '',
      targetType: 'file',
    },
    {
      path: 'link',
      source: 'link',
      status: 'added',
      sourceType: '',
      targetType: 'symlink',
    },
  ];

  const { result } = await run({
    exact,
    full,
    manifest,
    config: { contextMode: 'hunk' },
  });

  assert.equal(result.units.length, 0);
  assert.equal(result.skipped.length, 2);
  const reasons = Object.fromEntries(result.skipped.map((entry) => [entry.path, entry.reason]));
  assert.match(reasons['blob.bin'], /binary/);
  assert.match(reasons.link, /non-regular.*symlink/);
});

test('reuses a snapshot without running jj again', async () => {
  const exact = `diff --git a/x.ts b/x.ts
index 1111111111..2222222222 100644
--- a/x.ts
+++ b/x.ts
@@ -1,1 +1,1 @@
-old
+new
`;
  const full = `diff --git a/x.ts b/x.ts
index 1111111111..2222222222 100644
--- a/x.ts
+++ b/x.ts
@@ -1,1 +1,1 @@
-old
+new
`;
  const manifest = [
    {
      path: 'x.ts',
      source: 'x.ts',
      status: 'modified',
      sourceType: 'file',
      targetType: 'file',
    },
  ];

  const first = await run({
    exact,
    full,
    manifest,
    config: { contextMode: 'hunk' },
  });
  const snapshot = first.result.snapshot;
  assert.ok(snapshot);

  const second = await collectUnits({
    snapshot,
    config: { contextMode: 'hunk', contextLines: 0 },
    nodeChainAt: () => null,
    exec: async () => {
      throw new Error('snapshot reuse must not execute jj');
    },
  });

  assert.equal(second.snapshot, snapshot);
  assert.equal(second.units.length, 1);
  assert.equal(second.units[0].path, 'x.ts');
});
