import type { ExtensionAPI } from '@oh-my-pi/pi-coding-agent';
import { getAgentDir } from '@oh-my-pi/pi-coding-agent';
import { nodeChainAt } from '@oh-my-pi/pi-natives';
import { readFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { loadTraits, saveManagedTrait } from './core.mjs';
import { collectUnits } from './collection.mjs';

const pluginDir = dirname(fileURLToPath(import.meta.url));
const managedDir = join(getAgentDir(), 'managed-traits');

export default function(pi: ExtensionAPI) {
  const z = pi.zod;
  pi.on('before_agent_start', async event => ({
    systemPrompt: [...event.systemPrompt, await readFile(join(pluginDir, 'guidance.md'), 'utf8')],
  }));

  pi.registerTool({
    name: 'trait_units',
    label: 'Collect trait review units',
    description: 'Deterministically load traits and collect independent jj diff hunks with syntax context. Call from the traits Eval runner, not to hand-review bulk code. Results are in details. Read skill://traits for the runner.',
    approval: 'read',
    parameters: z.object({
      revset: z.string().min(1),
      files: z.array(z.string()).optional(),
      traitNames: z.array(z.string()).optional(),
      overrides: z.unknown().optional(),
      wholeFiles: z.boolean().optional(),
    }),
    async execute(_id, params, signal, _onUpdate, ctx) {
      const traits = await loadTraits({cwd: ctx.cwd, managedDir, overrides: params.overrides, traitNames: params.traitNames});
      const unitsByTrait: Record<string, unknown[]> = {};
      const skipped: unknown[] = [];
      const collections = new Map();
      let snapshot;
      const exec = async (argv: string[], cwd: string) => {
        const result = await pi.exec(argv[0], argv.slice(1), {cwd, signal});
        if (result.code !== 0) throw new Error(`${argv[0]} failed (${result.code}): ${result.stderr}`);
        return result.stdout;
      };
      for (const trait of traits) {
        const config = trait.config;
        const key = JSON.stringify({paths: config.paths, exclude: config.exclude, contextLines: config.contextLines, contextMode: config.contextMode, functionKinds: config.functionKinds, maxStateChars: config.maxStateChars});
        let collection = collections.get(key);
        if (!collection) {
          collection = await collectUnits({cwd: ctx.cwd, revset: params.revset, files: params.files, wholeFiles: params.wholeFiles, config, nodeChainAt, exec, snapshot});
          snapshot = collection.snapshot;
          collections.set(key, collection);
        }
        unitsByTrait[trait.name] = collection.units;
        skipped.push(...collection.skipped.map((item: unknown) => ({trait: trait.name, detail: item})));
      }
      return {
        content: [{type: 'text', text: `${traits.length} traits; ${Object.values(unitsByTrait).reduce((n, units) => n + units.length, 0)} hunk–trait assessments prepared; ${skipped.length} exclusions or unsupported inputs. Run the Eval judge before reading source units.`}],
        details: {traits, unitsByTrait, skipped},
      };
    },
  });

  pi.registerTool({
    name: 'manage_trait',
    label: 'Manage learned traits',
    description: 'List traits or automatically create/update/delete a managed coding trait after learning a reusable preference. No separate remember request is needed. Markdown body is the rule; frontmatter carries name, description and optional configuration. Never rewrites authored project traits.',
    approval: 'write',
    loadMode: 'essential',
    parameters: z.object({
      action: z.enum(['list', 'create', 'update', 'delete']),
      name: z.string().optional(),
      content: z.string().optional(),
    }),
    async execute(_id, params, _signal, _onUpdate, ctx) {
      if (params.action === 'list') {
        const traits = await loadTraits({cwd: ctx.cwd, managedDir});
        return {content: [{type: 'text', text: JSON.stringify(traits, null, 2)}], details: {traits}};
      }
      const result = await saveManagedTrait({managedDir, ...params});
      return {content: [{type: 'text', text: JSON.stringify(result)}], details: result};
    },
  });
}
