/**
 * Trait parsing, config resolution, loading, and managed-store mutation.
 *
 * A trait is a Markdown rule file with a strict YAML frontmatter block:
 *
 *   ---
 *   name: no-any
 *   description: Reject implicit any in exported code.
 *   paths: ["src/**"]
 *   ---
 *   Rule text.
 *
 * Frontmatter may contain only `name`, `description`, and trait config keys.
 * Config layers are DEFAULTS < frontmatter < explicit invocation overrides.
 * Anything malformed fails loudly instead of being silently ignored.
 */
import { constants as fsConstants } from "node:fs";
import * as fs from "node:fs/promises";
import * as path from "node:path";
import { YAML } from "bun";

/** Hard cap on a managed trait file (frontmatter + body), matching managed skills. */
export const MAX_MANAGED_TRAIT_BYTES = 64_000;

const TRAIT_NAME_PATTERN = /^[a-z0-9][a-z0-9-]{0,63}$/;
const VERDICT_LABEL_PATTERN = /^[A-Za-z0-9][A-Za-z0-9_-]{0,63}$/;

const CONFIG_KEYS = new Set([
	"paths",
	"exclude",
	"minConfidence",
	"contextLines",
	"contextMode",
	"functionKinds",
	"maxStateChars",
	"verdicts",
	"reportVerdicts",
	"reviewVerdicts",
	"concurrency",
	"retries",
	"minOk",
]);

const DEFAULT_VERDICTS = Object.freeze({
	compliant: "The unit fully satisfies the rule; no observable evidence contradicts it.",
	violation: "The unit contains at least one observable instance where the rule is broken.",
	"not-applicable": "The rule's subject does not occur in the unit, so the rule has nothing to judge.",
	inconclusive: "The unit does not contain enough observable evidence to decide compliance either way.",
});

function deepFreeze(value) {
	if (value === null || typeof value !== "object" || Object.isFrozen(value)) return value;
	Object.freeze(value);
	for (const key of Object.keys(value)) deepFreeze(value[key]);
	return value;
}

export const DEFAULTS = deepFreeze({
	paths: ["**/*"],
	exclude: [
		"references/**",
		"node_modules/**",
		".git/**",
		".jj/**",
		".agents/traits/**",
		"**/.env",
		"**/.env.*",
		"**/*.pem",
		"**/*.key",
	],
	minConfidence: 0.7,
	contextLines: 10,
	contextMode: "function",
	functionKinds: "function|method|lambda|closure|arrow|^binding$",
	maxStateChars: 100_000,
	verdicts: DEFAULT_VERDICTS,
	reportVerdicts: ["violation"],
	reviewVerdicts: ["inconclusive"],
	concurrency: 16,
	retries: 1,
	minOk: 1,
});

function isMapping(value) {
	return value !== null && typeof value === "object" && !Array.isArray(value);
}

function fail(origin, message) {
	const label = typeof origin === "string" && origin.trim() ? origin.trim() : "<unknown origin>";
	throw new Error(`Trait ${label}: ${message}`);
}

function errorMessage(error) {
	return error instanceof Error ? error.message : String(error);
}

/** Trim, lowercase, and validate a trait name. Throws instead of escaping the store. */
export function sanitizeTraitName(raw) {
	if (typeof raw !== "string") {
		throw new Error(`Invalid trait name ${JSON.stringify(raw)}: expected a string.`);
	}
	const name = raw.trim().toLowerCase();
	if (!TRAIT_NAME_PATTERN.test(name)) {
		throw new Error(
			`Invalid trait name "${raw}". Use lowercase letters, digits, and hyphens (1-64 chars, starting with a letter or digit).`,
		);
	}
	return name;
}

/** Strict frontmatter split: opening `---`, YAML mapping, closing `---`, non-empty body. */
function splitFrontmatter(text, origin) {
	if (typeof text !== "string") fail(origin, "trait content must be a string.");
	if (text.charCodeAt(0) === 0xfeff) text = text.slice(1);
	const opening = /^---[ \t]*\r?\n/.exec(text);
	if (!opening) fail(origin, 'must start with a YAML frontmatter block delimited by "---" on its own line.');
	const rest = text.slice(opening[0].length);
	const closing = /^(?:---|\.\.\.)[ \t]*(?:\r?\n|$)/m.exec(rest);
	if (!closing) fail(origin, 'frontmatter block is missing its closing "---" line.');
	const yamlSource = rest.slice(0, closing.index);
	const rawBody = rest.slice(closing.index + closing[0].length);
	let data;
	try {
		data = YAML.parse(yamlSource);
	} catch (error) {
		fail(origin, `invalid YAML frontmatter: ${errorMessage(error)}`);
	}
	if (!isMapping(data)) fail(origin, "frontmatter must be a YAML mapping.");
	const body = rawBody.trim();
	if (!body) fail(origin, "trait body must not be empty.");
	return { data, body };
}

function requireStringArray(config, key, origin, allowEmpty) {
	const value = config[key];
	if (!Array.isArray(value)) fail(origin, `"${key}" must be an array of strings.`);
	if (!allowEmpty && value.length === 0) fail(origin, `"${key}" must contain at least one glob.`);
	for (const entry of value) {
		if (typeof entry !== "string" || !entry.trim()) fail(origin, `"${key}" entries must be non-empty strings.`);
		if (entry.includes("\0")) fail(origin, `"${key}" entries must not contain NUL bytes.`);
	}
}

function requireInteger(config, key, origin, minimum) {
	const value = config[key];
	if (!Number.isInteger(value) || value < minimum) {
		fail(origin, `"${key}" must be an integer >= ${minimum}.`);
	}
}

function validateVerdicts(config, origin) {
	const verdicts = config.verdicts;
	if (!isMapping(verdicts) || Object.keys(verdicts).length === 0) {
		fail(origin, '"verdicts" must be a non-empty object mapping labels to observable sentences.');
	}
	if (Object.keys(verdicts).length < 2) {
		fail(origin, '"verdicts" must define at least two labels.');
	}
	for (const [label, sentence] of Object.entries(verdicts)) {
		if (!VERDICT_LABEL_PATTERN.test(label)) {
			fail(origin, `verdict label "${label}" must match ${VERDICT_LABEL_PATTERN}.`);
		}
		// `null` means the label is a choice without extra rubric text.
		if (sentence === null) continue;
		if (typeof sentence !== "string" || !sentence.trim()) {
			fail(origin, `verdict "${label}" must be a non-empty observable sentence or null.`);
		}
		if (/[\r\n]/.test(sentence) || /[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f]/.test(sentence)) {
			fail(origin, `verdict "${label}" must be a single line without control characters.`);
		}
	}
}

function validateVerdictSelection(config, key, origin, required) {
	const value = config[key];
	if (!Array.isArray(value)) fail(origin, `"${key}" must be an array of verdict labels.`);
	if (required && value.length === 0) fail(origin, `"${key}" must contain at least one verdict label.`);
	const seen = new Set();
	for (const label of value) {
		if (typeof label !== "string" || !label.trim()) {
			fail(origin, `"${key}" entries must be non-empty verdict labels.`);
		}
		if (seen.has(label)) fail(origin, `"${key}" repeats verdict "${label}".`);
		seen.add(label);
		if (!Object.hasOwn(config.verdicts, label)) {
			const defined = Object.keys(config.verdicts).join(", ");
			fail(
				origin,
				`${key} refers to undefined verdict "${label}" (verdicts define: ${defined || "none"}). ` +
					"Define custom verdicts together with explicit reportVerdicts/reviewVerdicts.",
			);
		}
	}
}

/** Validate a complete effective config object. Returns it unchanged. */
export function validateConfig(config, origin = "<config>") {
	if (!isMapping(config)) fail(origin, "config must be an object.");
	const unknown = Object.keys(config).filter(key => !CONFIG_KEYS.has(key));
	if (unknown.length > 0) {
		fail(origin, `unknown config key(s): ${unknown.map(key => JSON.stringify(key)).join(", ")}.`);
	}
	requireStringArray(config, "paths", origin, false);
	requireStringArray(config, "exclude", origin, true);
	if (
		typeof config.minConfidence !== "number" ||
		!Number.isFinite(config.minConfidence) ||
		config.minConfidence < 0 ||
		config.minConfidence > 1
	) {
		fail(origin, '"minConfidence" must be a finite number between 0 and 1.');
	}
	requireInteger(config, "contextLines", origin, 0);
	if (config.contextMode !== "function" && config.contextMode !== "hunk" && config.contextMode !== "file") {
		fail(origin, '"contextMode" must be "function", "hunk", or "file".');
	}
	if (typeof config.functionKinds !== "string" || !config.functionKinds.trim()) {
		fail(origin, '"functionKinds" must be a non-empty regular expression string.');
	}
	try {
		new RegExp(config.functionKinds);
	} catch (error) {
		fail(origin, `"functionKinds" is not a valid regular expression: ${errorMessage(error)}`);
	}
	requireInteger(config, "maxStateChars", origin, 1);
	validateVerdicts(config, origin);
	validateVerdictSelection(config, "reportVerdicts", origin, true);
	validateVerdictSelection(config, "reviewVerdicts", origin, false);
	requireInteger(config, "concurrency", origin, 1);
	if (config.concurrency > 32) fail(origin, '"concurrency" must be at most 32.');
	requireInteger(config, "retries", origin, 0);
	requireInteger(config, "minOk", origin, 1);
	return config;
}

function assertOverrideKeys(overrides, origin) {
	if (overrides === undefined || overrides === null) return;
	if (!isMapping(overrides)) fail(origin, "config overrides must be an object.");
	const unknown = Object.keys(overrides).filter(key => !CONFIG_KEYS.has(key));
	if (unknown.length > 0) {
		fail(origin, `unknown config key(s): ${unknown.map(key => JSON.stringify(key)).join(", ")}.`);
	}
}

/**
 * Layer DEFAULTS < frontmatter config < invocation overrides and validate.
 * Arrays and the verdict map are copied so callers cannot mutate DEFAULTS.
 */
export function resolveConfig(frontmatterConfig = {}, overrides = {}, origin = "<config>") {
	assertOverrideKeys(frontmatterConfig, origin);
	assertOverrideKeys(overrides, origin);
	const config = {};
	for (const key of Object.keys(DEFAULTS)) {
		const value = DEFAULTS[key];
		if (key === "verdicts") config.verdicts = { ...value };
		else if (Array.isArray(value)) config[key] = [...value];
		else config[key] = value;
	}
	for (const layer of [frontmatterConfig, overrides]) {
		if (layer === undefined || layer === null) continue;
		for (const key of Object.keys(layer)) {
			const value = layer[key];
			if (value === undefined) continue;
			if (key === "verdicts") {
				config.verdicts = isMapping(value) ? { ...value } : value;
			} else if (Array.isArray(value)) {
				config[key] = [...value];
			} else {
				config[key] = value;
			}
		}
	}
	return validateConfig(config, origin);
}

function parseTraitWithOverrides(text, origin, overrides) {
	const { data, body } = splitFrontmatter(text, origin);
	const allowed = new Set(["name", "description", ...CONFIG_KEYS]);
	const unknown = Object.keys(data).filter(key => !allowed.has(key));
	if (unknown.length > 0) {
		fail(
			origin,
			`unknown frontmatter key(s): ${unknown.map(key => JSON.stringify(key)).join(", ")}. ` +
				'Allowed keys are "name", "description", and trait config keys.',
		);
	}
	if (!Object.hasOwn(data, "name")) fail(origin, 'frontmatter must define "name".');
	let name;
	try {
		name = sanitizeTraitName(data.name);
	} catch (error) {
		fail(origin, errorMessage(error));
	}
	if (!Object.hasOwn(data, "description")) fail(origin, 'frontmatter must define "description".');
	if (typeof data.description !== "string") fail(origin, '"description" must be a string.');
	const description = data.description.trim();
	if (!description) fail(origin, '"description" must not be empty.');
	if (/[\r\n]/.test(description) || /[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f]/.test(description)) {
		fail(origin, '"description" must be a single line without control characters.');
	}
	const frontmatterConfig = {};
	for (const key of CONFIG_KEYS) {
		if (Object.hasOwn(data, key)) frontmatterConfig[key] = data[key];
	}
	const config = resolveConfig(frontmatterConfig, overrides, origin);
	return { name, description, body, origin, config };
}

/** Parse one trait document. Throws on malformed frontmatter or invalid config. */
export function parseTrait(text, origin = "<trait>") {
	return parseTraitWithOverrides(text, origin, undefined);
}

async function loadTraitDir(dir, overrides) {
	let entries;
	try {
		entries = await fs.readdir(dir, { withFileTypes: true });
	} catch (error) {
		if (error?.code === "ENOENT") return [];
		throw new Error(`Trait directory ${dir}: cannot read: ${errorMessage(error)}`);
	}
	entries.sort((a, b) => (a.name < b.name ? -1 : a.name > b.name ? 1 : 0));
	const traits = [];
	const seen = new Map();
	for (const entry of entries) {
		if (!entry.name.endsWith(".md")) continue;
		const file = path.join(dir, entry.name);
		let fileStat;
		try {
			fileStat = await fs.stat(file);
		} catch (error) {
			if (error?.code === "ENOENT") continue;
			throw new Error(`Trait ${file}: cannot stat: ${errorMessage(error)}`);
		}
		// Directories (including `<name>.md` directories) and devices are skipped.
		if (!fileStat.isFile()) continue;
		let text;
		try {
			text = await fs.readFile(file, "utf8");
		} catch (error) {
			throw new Error(`Trait ${file}: cannot read: ${errorMessage(error)}`);
		}
		const trait = parseTraitWithOverrides(text, file, overrides);
		const duplicate = seen.get(trait.name);
		if (duplicate) {
			throw new Error(
				`Trait ${file}: duplicate trait name "${trait.name}" (already defined by ${duplicate.origin}).`,
			);
		}
		seen.set(trait.name, trait);
		traits.push(trait);
	}
	return traits;
}

function normalizeTraitNames(traitNames) {
	if (traitNames === undefined || traitNames === null) return null;
	if (!Array.isArray(traitNames)) throw new Error('Trait option "traitNames" must be an array of names.');
	const names = new Set();
	for (const raw of traitNames) {
		try {
			names.add(sanitizeTraitName(raw));
		} catch (error) {
			throw new Error(`Invalid traitNames entry: ${errorMessage(error)}`);
		}
	}
	return names;
}

/**
 * Load managed and authored traits.
 *
 * Authored traits live in `<cwd>/.agents/traits/*.md` and always win over a
 * managed trait with the same name. `managedDir` is optional; when omitted no
 * managed traits are read. `traitNames` (optional) filters and rejects unknown
 * names. Overrides apply above each trait's frontmatter config.
 */
export async function loadTraits({ cwd, managedDir, overrides, traitNames } = {}) {
	const base = cwd === undefined ? process.cwd() : normalizeCwd(cwd);
	const overrideLayer = overrides ?? {};
	assertOverrideKeys(overrideLayer, "overrides");
	const wanted = normalizeTraitNames(traitNames);
	let managedRoot = null;
	if (managedDir !== undefined && managedDir !== null) {
		if (typeof managedDir !== "string" || !managedDir.trim()) {
			throw new Error('Trait option "managedDir" must be a non-empty path string.');
		}
		managedRoot = path.resolve(managedDir);
	}
	const authoredDir = path.join(base, ".agents", "traits");
	const [managedTraits, authoredTraits] = await Promise.all([
		managedRoot ? loadTraitDir(managedRoot, overrideLayer) : [],
		loadTraitDir(authoredDir, overrideLayer),
	]);
	const byName = new Map();
	for (const trait of managedTraits) byName.set(trait.name, trait);
	// Authored wins by replacing the managed entry.
	for (const trait of authoredTraits) byName.set(trait.name, trait);
	let traits = [...byName.values()];
	if (wanted) {
		const missing = [...wanted].filter(name => !byName.has(name));
		if (missing.length > 0) {
			throw new Error(`Unknown trait(s): ${missing.sort().join(", ")}.`);
		}
		traits = traits.filter(trait => wanted.has(trait.name));
	}
	traits.sort((a, b) => (a.name < b.name ? -1 : a.name > b.name ? 1 : 0));
	return traits;
}

function normalizeCwd(cwd) {
	if (typeof cwd !== "string" || !cwd.trim()) {
		throw new Error('Trait option "cwd" must be a non-empty path string.');
	}
	return path.resolve(cwd);
}

const mutationChains = new Map();

/** Serialize mutations of the same managed file in this process. */
function serializeMutation(key, operation) {
	const previous = mutationChains.get(key) ?? Promise.resolve();
	const run = previous.then(operation, operation);
	const guarded = run.catch(() => {});
	mutationChains.set(key, guarded);
	void guarded.finally(() => {
		if (mutationChains.get(key) === guarded) mutationChains.delete(key);
	});
	return run;
}

async function lstatOrNull(file) {
	return fs.lstat(file).catch(error => {
		if (error?.code === "ENOENT") return null;
		throw error;
	});
}

async function assertManagedRoot(root, creating) {
	const rootStat = await lstatOrNull(root);
	if (rootStat === null) {
		if (!creating) throw new Error(`Managed traits directory ${root} does not exist.`);
		await fs.mkdir(root, { recursive: true });
		const created = await fs.lstat(root);
		if (created.isSymbolicLink() || !created.isDirectory()) {
			throw new Error(`Managed traits directory ${root} is not a real directory; refusing to write.`);
		}
		return;
	}
	if (rootStat.isSymbolicLink()) {
		throw new Error(`Managed traits directory ${root} is a symlink; refusing to write.`);
	}
	if (!rootStat.isDirectory()) {
		throw new Error(`Managed traits directory ${root} is not a directory; refusing to write.`);
	}
}

const UPDATE_FILE_OPEN_FLAGS = fsConstants.O_WRONLY | fsConstants.O_NOFOLLOW;

function assertManagedFileSafeForUpdate(name, fileStat) {
	if (!fileStat.isFile()) {
		throw new Error(`Managed trait "${name}" is not a regular file; refusing to overwrite it.`);
	}
	if (fileStat.nlink > 1) {
		throw new Error(
			`Managed trait "${name}" has ${fileStat.nlink} hard links; refusing to overwrite a file that may be user-authored elsewhere.`,
		);
	}
}

async function openManagedFileForUpdate(name, file) {
	try {
		return await fs.open(file, UPDATE_FILE_OPEN_FLAGS);
	} catch (error) {
		if (error?.code === "ELOOP") {
			throw new Error(`Managed trait "${name}" is a symlink; refusing to overwrite it.`);
		}
		throw error;
	}
}

/**
 * Create, update, or delete one managed trait file `<managedDir>/<name>.md`.
 *
 * `content` is the complete trait Markdown (strict frontmatter + body) and must
 * declare the same normalized name as `name`. `delete` ignores `content`.
 * Automatic learning must use this function and never write authored traits.
 */
export async function saveManagedTrait({ managedDir, action, name, content } = {}) {
	if (typeof managedDir !== "string" || !managedDir.trim()) {
		throw new Error('Managed trait option "managedDir" must be a non-empty path string.');
	}
	if (!path.isAbsolute(managedDir)) {
		throw new Error(`Managed traits directory "${managedDir}" must be an absolute path.`);
	}
	if (action !== "create" && action !== "update" && action !== "delete") {
		throw new Error(`Invalid managed trait action "${String(action)}". Use "create", "update", or "delete".`);
	}
	const safeName = sanitizeTraitName(name);
	const root = path.resolve(managedDir);
	const file = path.join(root, `${safeName}.md`);
	const creating = action === "create";
	const text = action === "delete" ? null : content;
	if (action !== "delete") {
		if (typeof content !== "string") throw new Error(`Managed trait "${safeName}" content must be a string.`);
		const bytes = Buffer.byteLength(content, "utf8");
		if (bytes > MAX_MANAGED_TRAIT_BYTES) {
			throw new Error(`Managed trait is ${bytes} bytes; the limit is ${MAX_MANAGED_TRAIT_BYTES}.`);
		}
		if (!content.trim()) throw new Error(`Managed trait "${safeName}" needs non-empty content.`);
		const parsed = parseTrait(content, file);
		if (parsed.name !== safeName) {
			throw new Error(
				`Managed trait "${safeName}" content declares trait name "${parsed.name}"; ` +
					"the file name and frontmatter name must match.",
			);
		}
	}
	return serializeMutation(file, async () => {
		await assertManagedRoot(root, creating);
		if (action === "delete") {
			const fileStat = await lstatOrNull(file);
			if (fileStat === null) throw new Error(`Managed trait "${safeName}" does not exist.`);
			if (fileStat.isSymbolicLink()) {
				throw new Error(`Managed trait "${safeName}" is a symlink; refusing to delete it.`);
			}
			if (!fileStat.isFile()) {
				throw new Error(`Managed trait "${safeName}" is not a regular file; refusing to delete it.`);
			}
			await fs.unlink(file);
			return { action, name: safeName, path: file };
		}
		if (action === "create") {
			try {
				// O_CREAT|O_EXCL closes the check-then-write race and refuses a symlink.
				await fs.writeFile(file, text, { flag: "wx" });
			} catch (error) {
				if (error?.code === "EEXIST") {
					throw new Error(`Managed trait "${safeName}" already exists. Use action "update" to change it.`);
				}
				throw error;
			}
			return { action, name: safeName, path: file };
		}
		// update: check the path, then open without following links and re-check the
		// opened inode so a path swap between lstat and open cannot redirect writes.
		const fileStat = await lstatOrNull(file);
		if (fileStat === null) {
			throw new Error(`Managed trait "${safeName}" does not exist. Use action "create" to add it.`);
		}
		if (fileStat.isSymbolicLink()) {
			throw new Error(`Managed trait "${safeName}" is a symlink; refusing to overwrite it.`);
		}
		assertManagedFileSafeForUpdate(safeName, fileStat);
		const handle = await openManagedFileForUpdate(safeName, file);
		try {
			assertManagedFileSafeForUpdate(safeName, await handle.stat());
			await handle.truncate(0);
			await handle.writeFile(text);
		} finally {
			await handle.close();
		}
		return { action, name: safeName, path: file };
	});
}
