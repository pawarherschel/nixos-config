import { afterEach, describe, expect, test } from "bun:test";
import * as fs from "node:fs/promises";
import * as os from "node:os";
import * as path from "node:path";
import { DEFAULTS, loadTraits, parseTrait, resolveConfig, saveManagedTrait } from "./core.mjs";

const tempDirs = [];

async function tempWorkspace() {
	const root = await fs.mkdtemp(path.join(os.tmpdir(), "omp-traits-core-"));
	tempDirs.push(root);
	return root;
}

function traitText({ name = "example", description = "Example trait.", body = "Rule body.", config = {} } = {}) {
	const lines = ["---", `name: ${name}`, `description: ${description}`];
	for (const [key, value] of Object.entries(config)) lines.push(`${key}: ${JSON.stringify(value)}`);
	lines.push("---", "", body, "");
	return lines.join("\n");
}

afterEach(async () => {
	await Promise.all(tempDirs.splice(0).map(dir => fs.rm(dir, { recursive: true, force: true })));
});

describe("config layering", () => {
	test("explicit overrides beat frontmatter, including falsy values and empty arrays", () => {
		const config = resolveConfig(
			{ exclude: ["src/**"], contextLines: 4, retries: 2, minConfidence: 0.2, contextMode: "hunk" },
			{ exclude: [], contextLines: 0, retries: 0, minConfidence: 0.9, contextMode: "file" },
		);
		expect(config.exclude).toEqual([]);
		expect(config.contextLines).toBe(0);
		expect(config.retries).toBe(0);
		expect(config.minConfidence).toBe(0.9);
		expect(config.contextMode).toBe("file");
	});

	test("shared defaults fill every unset key without sharing mutable state", () => {
		const config = resolveConfig({ contextLines: 2 });
		expect(config.paths).toEqual(DEFAULTS.paths);
		expect(config.minConfidence).toBe(DEFAULTS.minConfidence);
		expect(config.contextLines).toBe(2);
		expect(config.verdicts).toEqual(DEFAULTS.verdicts);
		expect(config.verdicts).not.toBe(DEFAULTS.verdicts);
		expect(config.paths).not.toBe(DEFAULTS.paths);
	});

	test("custom verdicts need explicit report and review selections", () => {
		expect(() => resolveConfig({ verdicts: { pass: null, fail: "Broken rule." } })).toThrow(/reportVerdicts/);
		const config = resolveConfig({
			verdicts: { pass: null, fail: "Broken rule." },
			reportVerdicts: ["fail"],
			reviewVerdicts: [],
		});
		expect(config.verdicts).toEqual({ pass: null, fail: "Broken rule." });
		expect(config.reportVerdicts).toEqual(["fail"]);
		expect(config.reviewVerdicts).toEqual([]);
	});

	test("custom verdicts parse from frontmatter", () => {
		const trait = parseTrait(
			traitText({
				config: {
					verdicts: { pass: null, fail: "Broken rule." },
					reportVerdicts: ["fail"],
					reviewVerdicts: [],
				},
			}),
		);
		expect(trait.config.verdicts).toEqual({ pass: null, fail: "Broken rule." });
		expect(trait.config.reportVerdicts).toEqual(["fail"]);
	});
});

describe("strict parsing", () => {
	test("malformed frontmatter fails visibly", () => {
		expect(() => parseTrait("name: no-frontmatter\n", "bad.md")).toThrow(/frontmatter/);
		expect(() => parseTrait("---\nname: example\ndescription: d\n---\n", "empty.md")).toThrow(/body/);
	});

	test("unknown frontmatter and override keys fail instead of being ignored", () => {
		expect(() =>
			parseTrait("---\nname: example\ndescription: d\nmodle: x\n---\nbody\n", "unknown.md"),
		).toThrow(/unknown frontmatter key/);
		expect(() => resolveConfig({}, { notAKey: true })).toThrow(/unknown config key/);
	});

	test("invalid names and config values fail", () => {
		expect(() => parseTrait("---\nname: Bad Name\ndescription: d\n---\nbody\n", "name.md")).toThrow(
			/Invalid trait name/,
		);
		expect(() => resolveConfig({ contextMode: "lines" })).toThrow(/contextMode/);
		expect(() => resolveConfig({ functionKinds: "(" })).toThrow(/functionKinds/);
	});
});

describe("trait loading", () => {
	test("authored trait wins over a managed trait with the same name", async () => {
		const root = await tempWorkspace();
		const cwd = path.join(root, "project");
		const managedDir = path.join(root, "managed");
		const authoredFile = path.join(cwd, ".agents", "traits", "same.md");
		await fs.mkdir(path.dirname(authoredFile), { recursive: true });
		await fs.mkdir(managedDir, { recursive: true });
		await fs.writeFile(path.join(managedDir, "same.md"), traitText({ name: "same", body: "managed body" }));
		await fs.writeFile(
			authoredFile,
			traitText({ name: "same", body: "authored body", config: { contextLines: 3 } }),
		);

		const traits = await loadTraits({ cwd, managedDir });
		expect(traits).toHaveLength(1);
		expect(traits[0].body).toBe("authored body");
		expect(traits[0].config.contextLines).toBe(3);
		expect(traits[0].origin).toBe(authoredFile);
	});
});

describe("managed store safety", () => {
	test("update refuses a symlinked managed trait file", async () => {
		const root = await tempWorkspace();
		const managedDir = path.join(root, "managed");
		const outside = path.join(root, "outside.md");
		await fs.mkdir(managedDir, { recursive: true });
		await fs.writeFile(outside, traitText({ name: "linked", body: "outside body" }));
		await fs.symlink(outside, path.join(managedDir, "linked.md"));

		await expect(
			saveManagedTrait({
				managedDir,
				action: "update",
				name: "linked",
				content: traitText({ name: "linked", body: "new body" }),
			}),
		).rejects.toThrow(/symlink/);
		expect(await fs.readFile(outside, "utf8")).toContain("outside body");
	});

	test("create refuses a symlinked managed root", async () => {
		const root = await tempWorkspace();
		const target = path.join(root, "real");
		const link = path.join(root, "link");
		await fs.mkdir(target);
		await fs.symlink(target, link);

		await expect(
			saveManagedTrait({
				managedDir: link,
				action: "create",
				name: "example",
				content: traitText({ name: "example" }),
			}),
		).rejects.toThrow(/symlink/);
		expect(await fs.readdir(target)).toEqual([]);
	});

	test("managed update never changes an authored trait of the same name", async () => {
		const root = await tempWorkspace();
		const cwd = path.join(root, "project");
		const managedDir = path.join(root, "managed");
		const authoredFile = path.join(cwd, ".agents", "traits", "same.md");
		await fs.mkdir(path.dirname(authoredFile), { recursive: true });
		await fs.mkdir(managedDir, { recursive: true });
		const authored = traitText({ name: "same", body: "authored stays" });
		await fs.writeFile(authoredFile, authored);
		await fs.writeFile(path.join(managedDir, "same.md"), traitText({ name: "same", body: "old managed" }));

		await saveManagedTrait({
			managedDir,
			action: "update",
			name: "same",
			content: traitText({ name: "same", body: "new managed" }),
		});

		expect(await fs.readFile(authoredFile, "utf8")).toBe(authored);
		expect(await fs.readFile(path.join(managedDir, "same.md"), "utf8")).toContain("new managed");
	});
});
