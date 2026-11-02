// Trait check runner, loaded by Eval `%load`.
//
// %load evaluates a script (it may reject `export`), so this file has no module
// exports: it declares `checkTraits` and publishes it on globalThis. The next
// Eval cell can call `await checkTraits(options, deps)`. `await import(path)`
// also works; it installs the same global.

// `var` (not const) so a repeated `%load` in the same kernel does not throw a
// redeclaration error.
var TRAIT_CHECK_TOOL = "trait_units";
var TRAIT_CHECK_DRAIN_SLICE_SECONDS = 30;

function traitCheckFail(message) {
	throw new Error(`checkTraits: ${message}`);
}

function traitCheckUnwrapResult(raw) {
	if (!raw || typeof raw !== "object") traitCheckFail("trait_units returned no object result");
	// OMP tools return {content, details}; the parent puts the bulk payload in details.
	const details = raw.details;
	if (
		details &&
		typeof details === "object" &&
		(Array.isArray(details.traits) || (details.unitsByTrait && typeof details.unitsByTrait === "object"))
	) {
		return details;
	}
	return raw;
}

function traitCheckResolveDeps(deps) {
	const d = deps ?? {};
	const toolDep = d.tool ?? globalThis.tool;
	let callTool;
	if (typeof toolDep === "function") {
		callTool = (name, args) => toolDep(name, args);
	} else if (toolDep && typeof toolDep === "object" && typeof toolDep[TRAIT_CHECK_TOOL] === "function") {
		callTool = (name, args) => toolDep[name](args);
	} else {
		traitCheckFail(
			"no tool dependency; pass {tool} (`(name, args) => tool[name](args)`) or define globalThis.tool",
		);
	}
	return {
		callTool,
		judgeBatch: d.judgeBatch ?? globalThis.judgeBatch,
		print:
			typeof d.print === "function"
				? d.print
				: typeof globalThis.print === "function"
					? globalThis.print
					: (...args) => console.log(...args),
		phase:
			typeof d.phase === "function"
				? d.phase
				: typeof globalThis.phase === "function"
					? globalThis.phase
					: null,
	};
}

function traitCheckValidateOptions(options) {
	const opts = options ?? {};
	const revset = opts.revset;
	if (typeof revset !== "string" || revset.trim() === "") {
		traitCheckFail("revset is required (a jj revset string); refusing to guess one");
	}
	if (opts.files !== undefined) {
		if (!Array.isArray(opts.files) || opts.files.some((f) => typeof f !== "string" || f === "")) {
			traitCheckFail("files must be an array of nonempty strings");
		}
	}
	if (opts.traitNames !== undefined) {
		if (
			!Array.isArray(opts.traitNames) ||
			opts.traitNames.some((n) => typeof n !== "string" || n === "")
		) {
			traitCheckFail("traitNames must be an array of nonempty strings");
		}
	}
	if (opts.overrides !== undefined && (!opts.overrides || typeof opts.overrides !== "object" || Array.isArray(opts.overrides))) {
		traitCheckFail("overrides must be a plain object");
	}
	if (opts.wholeFiles !== undefined && typeof opts.wholeFiles !== "boolean") {
		traitCheckFail("wholeFiles must be a boolean");
	}
	return opts;
}

function traitCheckValidateConfig(trait) {
	if (!trait || typeof trait !== "object") traitCheckFail("trait entry is not an object");
	const name = trait.name;
	if (typeof name !== "string" || name === "") traitCheckFail("trait entry has no name");
	if (typeof trait.body !== "string") traitCheckFail(`trait ${name}: body must be a markdown string`);
	const config = trait.config;
	if (!config || typeof config !== "object") traitCheckFail(`trait ${name}: missing config`);

	const verdicts = config.verdicts;
	if (!verdicts || typeof verdicts !== "object" || Array.isArray(verdicts)) {
		traitCheckFail(`trait ${name}: config.verdicts must be an object of label -> rubric`);
	}
	const labels = Object.keys(verdicts);
	if (labels.length < 2) traitCheckFail(`trait ${name}: config.verdicts needs at least two labels`);
	for (const label of labels) {
		if (label === "") traitCheckFail(`trait ${name}: config.verdicts has an empty label`);
		const rubric = verdicts[label];
		if (typeof rubric !== "string" && rubric !== null) {
			traitCheckFail(`trait ${name}: config.verdicts.${label} must be a rubric string or null`);
		}
	}

	const checkLabelList = (key, required) => {
		const value = config[key];
		if (!Array.isArray(value) || value.length === 0) {
			if (required) traitCheckFail(`trait ${name}: config.${key} must be a nonempty array of verdict labels`);
			return [];
		}
		const seen = new Set();
		for (const label of value) {
			if (typeof label !== "string" || !Object.hasOwn(verdicts, label)) {
				traitCheckFail(`trait ${name}: config.${key} contains unknown verdict ${JSON.stringify(label)}`);
			}
			if (seen.has(label)) traitCheckFail(`trait ${name}: config.${key} repeats verdict ${label}`);
			seen.add(label);
		}
		return value;
	};
	const reportVerdicts = checkLabelList("reportVerdicts", true);
	const reviewVerdicts = checkLabelList("reviewVerdicts", false);

	const minConfidence = config.minConfidence;
	if (typeof minConfidence !== "number" || !Number.isFinite(minConfidence) || minConfidence < 0 || minConfidence > 1) {
		traitCheckFail(`trait ${name}: config.minConfidence must be a number in [0, 1]`);
	}
	const concurrency = config.concurrency;
	if (!Number.isInteger(concurrency) || concurrency < 1 || concurrency > 32) {
		traitCheckFail(`trait ${name}: config.concurrency must be an integer in [1, 32]`);
	}
	const retries = config.retries;
	if (!Number.isInteger(retries) || retries < 0) {
		traitCheckFail(`trait ${name}: config.retries must be a nonnegative integer`);
	}
	const minOk = config.minOk;
	if (!Number.isInteger(minOk) || minOk < 1) {
		traitCheckFail(`trait ${name}: config.minOk must be a positive integer`);
	}
	const maxStateChars = config.maxStateChars;
	if (!Number.isInteger(maxStateChars) || maxStateChars < 1) {
		traitCheckFail(`trait ${name}: config.maxStateChars must be a positive integer`);
	}

	return {
		name,
		verdicts,
		labels,
		reportVerdicts,
		reviewVerdicts,
		minConfidence,
		concurrency,
		retries,
		minOk,
		maxStateChars,
	};
}

function traitCheckHunkHeader(unit) {
	const h = unit.hunk;
	if (!h || typeof h !== "object") return "hunk";
	if (typeof h.oldStart !== "number" || typeof h.newStart !== "number") {
		return typeof h.header === "string" && h.header !== "" ? h.header : "hunk";
	}
	const oldCount = typeof h.oldCount === "number" ? h.oldCount : 0;
	const newCount = typeof h.newCount === "number" ? h.newCount : 0;
	return `@@ -${h.oldStart},${oldCount} +${h.newStart},${newCount} @@`;
}

function traitCheckContextBlock(label, items) {
	const lines = [];
	const list = Array.isArray(items) ? items : [];
	for (const item of list) {
		if (!item || typeof item !== "object") continue;
		const start = item.startLine;
		const end = item.endLine;
		let range = "L?";
		if (typeof start === "number") {
			range = typeof end === "number" && end !== start ? `L${start}-${end}` : `L${start}`;
		}
		lines.push(`[${range}]`, String(item.text ?? ""));
	}
	if (lines.length === 0) return [];
	return ["", `${label}:`, ...lines];
}

// One deterministic state per hunk (or per explicitly selected whole file).
// Never truncated: an oversized state is reported as an issue and the unit is
// skipped by the caller.
function traitCheckBuildState(unit, wholeFile) {
	const parts = [`Path: ${unit.path}`];
	if (typeof unit.oldPath === "string" && unit.oldPath !== "" && unit.oldPath !== unit.path) {
		parts.push(`Old path: ${unit.oldPath}`);
	}
	if (wholeFile) parts.push("Scope: whole file (explicitly selected; changed-only constraints do not apply)");
	parts.push(`Hunk: ${traitCheckHunkHeader(unit)}`);
	parts.push(
		"",
		wholeFile ? "Content (whole file):" : "Diff (unified; only + and - lines are changed):",
		String(unit.hunk?.diff ?? ""),
	);
	const context = unit.context && typeof unit.context === "object" ? unit.context : {};
	parts.push(...traitCheckContextBlock("Context before", context.before));
	parts.push(...traitCheckContextBlock("Context after", context.after));
	return parts.join("\n");
}

function traitCheckInstruction(trait, config, wholeFile) {
	const scope = wholeFile
		? "Judge the entire file shown. The user explicitly selected whole-file judgment, so do not limit the verdict to changed lines; unchanged code is in scope."
		: "Judge only lines changed in this hunk: `+` and `-` lines in the diff. Context lines and lines outside the hunk are background, not newly introduced changes.";
	return [
		`Trait: ${config.name}`,
		typeof trait.description === "string" && trait.description !== "" ? `Description: ${trait.description}` : null,
		"",
		"Rule (markdown):",
		trait.body,
		"",
		`${scope} Do not infer intent, files, or fixes beyond the supplied state. Choose exactly one criteria label and return its probability.`,
	]
		.filter((line) => line !== null)
		.join("\n");
}

function traitCheckQuestion(trait, config, wholeFile) {
	return {
		type: "choice",
		instructions: traitCheckInstruction(trait, config, wholeFile),
		criteria: { ...config.verdicts },
	};
}

function traitCheckTopProbability(probabilities, fallback) {
	let top = Number.isFinite(fallback) ? fallback : 0;
	if (probabilities && typeof probabilities === "object") {
		for (const value of Object.values(probabilities)) {
			if (typeof value === "number" && Number.isFinite(value) && value > top) top = value;
		}
	}
	return top;
}

// Drain in bounded slices. The JS API takes `{ timeout }`, and `status().done`
// is the settled count, not a completion boolean. Keep draining while the run
// is active and stop only once it is no longer running and a drain returned no
// items, so an item that settled between the drain and status cannot be lost.
// `drain()` raises only on a wholesale run failure; per-item failures stay on
// item.ok/item.error and are recorded faithfully.
async function traitCheckDrainBatch(batch, onItem) {
	for (;;) {
		if (!batch || typeof batch.drain !== "function") traitCheckFail("judgeBatch returned no drain()");
		const settled = await batch.drain({ timeout: TRAIT_CHECK_DRAIN_SLICE_SECONDS });
		if (Array.isArray(settled)) {
			for (const pair of settled) {
				if (!Array.isArray(pair) || pair.length < 2) continue;
				onItem(String(pair[0]), pair[1]);
			}
		}
		const status = typeof batch.status === "function" ? await batch.status() : null;
		if (!status || typeof status !== "object") {
			if (!Array.isArray(settled) || settled.length === 0) return null;
			continue;
		}
		if (status.running) continue;
		if (Array.isArray(settled) && settled.length > 0) continue;
		return status;
	}
}

function traitCheckPrintReport(report, print) {
	const lines = [];
	lines.push(
		`checkTraits revset=${JSON.stringify(report.revset)} traits=${report.traits.length} states=${report.counts.states} judged=${report.counts.judged} flagged=${report.counts.flagged} review=${report.counts.review} errors=${report.counts.errors} skipped=${report.counts.skipped} contextIssues=${report.counts.contextIssues} batchFailures=${report.counts.batchFailures}`,
	);
	const verdictLine = Object.entries(report.counts.verdicts)
		.map(([label, count]) => `${label}=${count}`)
		.join(" ");
	lines.push(verdictLine === "" ? "Verdicts: (none)" : `Verdicts: ${verdictLine}`);

	if (report.flagged.length > 0) {
		lines.push("", `FLAGS (unconfirmed model verdicts; ${report.flagged.length}):`);
		for (const entry of report.flagged) {
			lines.push(
				`FLAG trait=${entry.trait} path=${entry.path} hunk=${entry.hunk} unit=${entry.unitId ?? "?"} verdict=${entry.verdict} probability=${entry.probability} top=${entry.topProbability}`,
				entry.state,
			);
		}
	}

	if (report.review.length > 0) {
		lines.push("", `REVIEW (unconfirmed; ${report.review.length}):`);
		for (const entry of report.review) {
			lines.push(
				`REVIEW trait=${entry.trait} path=${entry.path} hunk=${entry.hunk} unit=${entry.unitId ?? "?"} verdict=${entry.verdict} probability=${entry.probability} top=${entry.topProbability} reason=${entry.reviewReasons.join(",")}`,
				entry.state,
			);
		}
	}

	if (report.errors.length > 0) {
		lines.push("", `ERRORS (${report.errors.length}):`);
		for (const entry of report.errors) {
			lines.push(
				`ERROR trait=${entry.trait} path=${entry.path ?? "?"} unit=${entry.unitId ?? "?"}: ${entry.error}`,
			);
		}
	}

	if (report.batchFailures.length > 0) {
		lines.push("", `BATCH FAILURES (${report.batchFailures.length}):`);
		for (const entry of report.batchFailures) {
			lines.push(`BATCH trait=${entry.trait}: ${entry.error}`);
		}
	}

	if (report.skipped.length > 0) {
		lines.push("", `SKIPPED (${report.skipped.length}):`);
		for (const entry of report.skipped) {
			lines.push(
				`SKIPPED trait=${entry.trait ?? "?"} path=${entry.path ?? "?"} reason=${entry.reason}${entry.chars !== undefined ? ` chars=${entry.chars} max=${entry.maxStateChars}` : ""}`,
			);
		}
	}

	if (report.contextIssues.length > 0) {
		lines.push("", `CONTEXT ISSUES (${report.contextIssues.length} units):`);
		for (const entry of report.contextIssues) {
			lines.push(
				`ISSUE trait=${entry.trait} path=${entry.path ?? "?"} unit=${entry.unitId ?? "?"}: ${JSON.stringify(entry.issues)}`,
			);
		}
	}

	if (report.counts.judged === 0) {
		lines.push("", "No hunks were judged (0 states); nothing to report.");
	} else if (report.flagged.length === 0 && report.review.length === 0) {
		lines.push("", "No flags or review items.");
	}
	lines.push("", "Model verdicts are unconfirmed; verify each flag against the code before acting.");
	print(lines.join("\n"));
}

async function checkTraits(options, deps) {
	const opts = traitCheckValidateOptions(options);
	const resolved = traitCheckResolveDeps(deps);

	const params = { revset: opts.revset };
	if (opts.files !== undefined) params.files = opts.files;
	if (opts.traitNames !== undefined) params.traitNames = opts.traitNames;
	if (opts.overrides !== undefined) params.overrides = opts.overrides;
	if (opts.wholeFiles !== undefined) params.wholeFiles = opts.wholeFiles;

	if (resolved.phase) resolved.phase(`Traits check ${opts.revset}`);

	const raw = await resolved.callTool(TRAIT_CHECK_TOOL, params);
	const payload = traitCheckUnwrapResult(raw);

	const traits = payload.traits;
	if (!Array.isArray(traits)) traitCheckFail("trait_units result is missing the traits array");
	const unitsByTrait = payload.unitsByTrait;
	if (unitsByTrait !== undefined && (unitsByTrait === null || typeof unitsByTrait !== "object" || Array.isArray(unitsByTrait))) {
		traitCheckFail("trait_units result unitsByTrait must be an object");
	}

	const report = {
		revset: opts.revset,
		traits: [],
		counts: {
			states: 0,
			judged: 0,
			flagged: 0,
			review: 0,
			errors: 0,
			skipped: 0,
			contextIssues: 0,
			batchFailures: 0,
			verdicts: {},
		},
		flagged: [],
		review: [],
		errors: [],
		skipped: [],
		contextIssues: [],
		batchFailures: [],
	};

	const toolSkipped = Array.isArray(payload.skipped) ? payload.skipped : [];
	for (const entry of toolSkipped) {
		report.counts.skipped += 1;
		// trait_units wraps each collected skip as {trait, detail}; collection
		// owners define detail.reason (deterministic exclusion vs unsupported/error).
		const detail = entry?.detail && typeof entry.detail === "object" ? entry.detail : entry;
		report.skipped.push({
			trait: entry?.trait ?? detail?.trait ?? detail?.traitName ?? "?",
			path: detail?.path ?? "?",
			reason: detail?.reason ?? detail?.message ?? "skipped",
			detail,
		});
	}

	// Whole-file judgment is a run-level user choice; it is never inferred from
	// a trait's contextMode or a unit's shape.
	const wholeFile = opts.wholeFiles === true;

	if (traits.length === 0) {
		resolved.print(
			`checkTraits revset=${JSON.stringify(opts.revset)}: no traits loaded; nothing to judge.\nFix trait configuration or pass traitNames, then retry.`,
		);
		return report;
	}

	// One batch per trait: each trait carries its own rule, verdict rubric, and
	// judge options, so its questions/options differ. Batch grouping for
	// identical schemas is intentionally not attempted.
	for (const trait of traits) {
		const config = traitCheckValidateConfig(trait);
		report.traits.push(config.name);
		for (const label of config.labels) {
			if (!Object.hasOwn(report.counts.verdicts, label)) report.counts.verdicts[label] = 0;
		}

		const units = Array.isArray(unitsByTrait?.[config.name]) ? unitsByTrait[config.name] : [];
		// unit id -> { unit, state } for this trait only.
		const prepared = [];
		for (const unit of units) {
			report.counts.states += 1;
			const path = unit && typeof unit.path === "string" ? unit.path : null;
			const unitId = unit && unit.id !== undefined && unit.id !== null ? String(unit.id) : null;
			if (!unit || typeof unit !== "object" || path === null) {
				report.errors.push({
					trait: config.name,
					path,
					unitId,
					error: "invalid unit: missing path",
				});
				report.counts.errors += 1;
				continue;
			}
			if (!unit.hunk || typeof unit.hunk.diff !== "string" || unit.hunk.diff === "") {
				report.errors.push({
					trait: config.name,
					path,
					unitId,
					error: "invalid unit: missing hunk.diff",
				});
				report.counts.errors += 1;
				continue;
			}
			if (Array.isArray(unit.issues) && unit.issues.length > 0) {
				report.contextIssues.push({ trait: config.name, path, unitId, issues: unit.issues });
				report.counts.contextIssues += unit.issues.length;
			}
			const state = traitCheckBuildState(unit, wholeFile);
			if (state.length > config.maxStateChars) {
				report.skipped.push({
					trait: config.name,
					path,
					reason: "oversized-state",
					chars: state.length,
					maxStateChars: config.maxStateChars,
				});
				report.counts.skipped += 1;
				report.contextIssues.push({
					trait: config.name,
					path,
					unitId,
					issues: [
						{
							type: "oversized-state",
							chars: state.length,
							maxStateChars: config.maxStateChars,
						},
					],
				});
				report.counts.contextIssues += 1;
				continue;
			}
			prepared.push({ key: `u${prepared.length}`, unit, unitId, path, state });
		}

		if (prepared.length === 0) continue;

		if (typeof resolved.judgeBatch !== "function") {
			traitCheckFail(
				"no judgeBatch dependency; pass {judgeBatch} explicitly (Eval globals are not on globalThis)",
			);
		}

		const states = {};
		for (const entry of prepared) states[entry.key] = entry.state;
		const questions = { [config.name]: traitCheckQuestion(trait, config, wholeFile) };
		const judgeOptions = {
			intent: `Traits: ${config.name} (${prepared.length} hunk${prepared.length === 1 ? "" : "s"})`,
			concurrency: config.concurrency,
			retries: config.retries,
			minOk: config.minOk,
		};

		let batch;
		const results = new Map();
		try {
			batch = await resolved.judgeBatch(states, questions, judgeOptions);
		} catch (error) {
			const message = error instanceof Error ? error.message : String(error);
			report.batchFailures.push({ trait: config.name, error: `judgeBatch failed: ${message}` });
			report.counts.batchFailures += 1;
			for (const entry of prepared) {
				report.errors.push({
					trait: config.name,
					path: entry.path,
					unitId: entry.unitId,
					error: `judgeBatch failed: ${message}`,
				});
				report.counts.errors += 1;
			}
			continue;
		}

		let wholesaleError = null;
		try {
			await traitCheckDrainBatch(batch, (key, item) => {
				if (results.has(key)) {
					results.set(key, { ok: false, error: `duplicate judgment for ${key}` });
					return;
				}
				results.set(key, item);
			});
		} catch (error) {
			wholesaleError = error instanceof Error ? error.message : String(error);
			report.batchFailures.push({ trait: config.name, error: `judgeBatch run failed: ${wholesaleError}` });
			report.counts.batchFailures += 1;
		} finally {
			if (batch && typeof batch.close === "function") {
				try {
					await batch.close();
				} catch (error) {
					report.batchFailures.push({
						trait: config.name,
						error: `judgeBatch close failed: ${error instanceof Error ? error.message : String(error)}`,
					});
					report.counts.batchFailures += 1;
				}
			}
		}

		for (const entry of prepared) {
			const item = results.get(entry.key);
			if (!item) {
				report.errors.push({
					trait: config.name,
					path: entry.path,
					unitId: entry.unitId,
					error: wholesaleError ? `batch failed: ${wholesaleError}` : "no judgment returned",
				});
				report.counts.errors += 1;
				continue;
			}
			if (item.ok !== true) {
				report.errors.push({
					trait: config.name,
					path: entry.path,
					unitId: entry.unitId,
					error: item.error === undefined || item.error === null ? "judge item failed without error" : String(item.error),
				});
				report.counts.errors += 1;
				continue;
			}

			const answers = item.answers;
			const answer = answers && typeof answers === "object" ? answers[config.name] : undefined;
			if (!answer || typeof answer !== "object") {
				report.errors.push({
					trait: config.name,
					path: entry.path,
					unitId: entry.unitId,
					error: "judge item has no answer for the trait question",
				});
				report.counts.errors += 1;
				continue;
			}
			const choice = answer.choice;
			if (typeof choice !== "string" || !Object.hasOwn(config.verdicts, choice)) {
				report.errors.push({
					trait: config.name,
					path: entry.path,
					unitId: entry.unitId,
					error: `judge returned unknown verdict ${JSON.stringify(choice)}`,
				});
				report.counts.errors += 1;
				continue;
			}
			const probability =
				answer.probabilities && typeof answer.probabilities === "object" ? answer.probabilities[choice] : undefined;
			if (typeof probability !== "number" || !Number.isFinite(probability)) {
				report.errors.push({
					trait: config.name,
					path: entry.path,
					unitId: entry.unitId,
					error: `judge returned no probability for verdict ${choice}`,
				});
				report.counts.errors += 1;
				continue;
			}

			report.counts.judged += 1;
			report.counts.verdicts[choice] += 1;
			const topProbability = traitCheckTopProbability(answer.probabilities, probability);
			const flagged = config.reportVerdicts.includes(choice) && probability >= config.minConfidence;
			const reviewReasons = [];
			if (!flagged) {
				if (config.reviewVerdicts.includes(choice)) reviewReasons.push("review-verdict");
				if (topProbability < config.minConfidence) reviewReasons.push("low-certainty");
			}
			const record = {
				trait: config.name,
				unitId: entry.unitId,
				path: entry.path,
				hunk: traitCheckHunkHeader(entry.unit),
				verdict: choice,
				probability,
				topProbability,
				confidence: typeof answer.confidence === "number" ? answer.confidence : null,
				confirmed: false,
				state: entry.state,
			};
			if (flagged) {
				report.flagged.push(record);
				report.counts.flagged += 1;
			} else if (reviewReasons.length > 0) {
				record.reviewReasons = reviewReasons;
				report.review.push(record);
				report.counts.review += 1;
			}
		}
	}

	traitCheckPrintReport(report, resolved.print);
	return report;
}

globalThis.checkTraits = checkTraits;
