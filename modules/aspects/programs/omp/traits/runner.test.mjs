import { afterAll, describe, expect, test } from "bun:test";
import "./skills/traits/scripts/check.mjs";

const checkTraits = globalThis.checkTraits;

afterAll(() => {
	delete globalThis.checkTraits;
});

const BASE_CONFIG = {
	paths: ["**/*"],
	exclude: [],
	minConfidence: 0.7,
	contextLines: 10,
	contextMode: "function",
	functionKinds: "function|method|lambda|closure|arrow|^binding$",
	maxStateChars: 100_000,
	verdicts: {
		ok: "The change follows the rule.",
		bad: "The change breaks the rule.",
		unsure: "The evidence is insufficient.",
	},
	reportVerdicts: ["bad"],
	reviewVerdicts: ["unsure"],
	concurrency: 4,
	retries: 1,
	minOk: 1,
};

function makeTrait(config = {}) {
	return {
		name: "demo",
		description: "Demo rule.",
		body: "Never call foo.",
		origin: "test",
		config: { ...BASE_CONFIG, ...config, verdicts: config.verdicts ?? { ...BASE_CONFIG.verdicts } },
	};
}

function makeUnit(id, marker) {
	return {
		id,
		path: `src/${marker}.ts`,
		oldPath: `src/${marker}.ts`,
		hunk: {
			oldStart: 1,
			oldCount: 1,
			newStart: 1,
			newCount: 1,
			diff: `@@ -1,1 +1,1 @@\n-const before = ${marker}\n+const after = ${marker}`,
		},
		context: { before: [], after: [] },
		issues: [],
	};
}

function makeTool(trait, units, skipped = []) {
	return async (name, params) => {
		if (name !== "trait_units") throw new Error(`unexpected tool ${name}`);
		if (typeof params?.revset !== "string" || params.revset === "") {
			throw new Error("runner must pass a revset");
		}
		return {
			content: [{ type: "text", text: "summary" }],
			details: { traits: [trait], unitsByTrait: { [trait.name]: units }, skipped },
		};
	};
}

function answer(choice, probability, rest = {}) {
	return { choice, probabilities: { ...rest, [choice]: probability }, confidence: probability };
}

function makeJudge({ answers = {}, errors = {}, missing = new Set(), perDrain = 1, drainError = null } = {}) {
	const calls = [];
	const closed = [];
	let drainCalls = 0;
	// Async on purpose: judgeBatch is a Promise-returning factory. A missing
	// `await` in the runner would yield a Promise with no drain() and fail here.
	const judgeBatch = async (states, questions, options) => {
		calls.push({ states, questions, options });
		const keys = Object.keys(states);
		const questionId = Object.keys(questions)[0];
		let cursor = 0;
		let settled = 0;
		let didClose = false;
		return {
			async drain(opts) {
				drainCalls += 1;
				if (!opts || typeof opts !== "object" || typeof opts.timeout !== "number") {
					throw new Error(`drain() requires { timeout } (received ${JSON.stringify(opts)})`);
				}
				if (drainError) throw new Error(drainError);
				const out = [];
				for (let i = 0; i < perDrain && cursor < keys.length; i++) {
					const key = keys[cursor++];
					settled += 1;
					if (missing.has(key)) continue;
					if (errors[key] !== undefined) out.push([key, { ok: false, error: errors[key] }]);
					else out.push([key, { ok: true, answers: { [questionId]: answers[key] } }]);
				}
				return out;
			},
			async status() {
				return { done: settled, total: keys.length, running: cursor < keys.length, failed: 0 };
			},
			async close() {
				if (!didClose) {
					didClose = true;
					closed.push(questionId);
				}
			},
		};
	};
	judgeBatch.calls = calls;
	judgeBatch.closed = closed;
	judgeBatch.drainCalls = () => drainCalls;
	return judgeBatch;
}

function makePrint() {
	const chunks = [];
	const print = (...args) => chunks.push(args.map(String).join(" "));
	print.text = () => chunks.join("\n");
	return print;
}

describe("checkTraits", () => {
	test("classifies custom verdicts at the confidence boundary and keeps review items separate", async () => {
		const trait = makeTrait();
		const units = ["u0", "u1", "u2", "u3"].map((id) => makeUnit(id, `${id}-marker`));
		const judgeBatch = makeJudge({
			answers: {
				u0: answer("bad", 0.7, { ok: 0.2, unsure: 0.1 }),
				u1: answer("bad", 0.69, { ok: 0.2, unsure: 0.11 }),
				u2: answer("ok", 0.9, { bad: 0.05, unsure: 0.05 }),
				u3: answer("unsure", 0.95, { ok: 0.03, bad: 0.02 }),
			},
		});
		const print = makePrint();
		const report = await checkTraits(
			{ revset: "trunk()..@" },
			{ tool: makeTool(trait, units), judgeBatch, print },
		);

		expect(report.counts.judged).toBe(4);
		expect(report.counts.verdicts).toEqual({ ok: 1, bad: 2, unsure: 1 });
		expect(report.counts.errors).toBe(0);
		expect(report.counts.flagged).toBe(1);
		expect(report.counts.review).toBe(2);

		expect(report.flagged).toHaveLength(1);
		expect(report.flagged[0].unitId).toBe("u0");
		expect(report.flagged[0].probability).toBe(0.7);
		expect(report.flagged[0].confirmed).toBe(false);
		expect(report.flagged[0].state).toContain("u0-marker");

		const lowCertainty = report.review.find((entry) => entry.unitId === "u1");
		expect(lowCertainty?.reviewReasons).toEqual(["low-certainty"]);
		const reviewVerdict = report.review.find((entry) => entry.unitId === "u3");
		expect(reviewVerdict?.reviewReasons).toEqual(["review-verdict"]);

		const call = judgeBatch.calls[0];
		expect(call.questions.demo.criteria).toEqual(BASE_CONFIG.verdicts);
		expect(call.questions.demo.instructions).toContain("only lines changed");
		expect(call.options.concurrency).toBe(4);
		expect(call.options.retries).toBe(1);
		expect(call.options.minOk).toBe(1);
		expect(call.options.intent).toContain("demo");

		const text = print.text();
		expect(text).toContain("FLAG trait=demo");
		expect(text).toContain("u0-marker");
		expect(text).not.toContain("u2-marker");
		expect(text).toContain("Model verdicts are unconfirmed");
		expect(judgeBatch.closed).toEqual(["demo"]);
	});

	test("does not stop at a numeric status.done and judges every drained hunk", async () => {
		const trait = makeTrait();
		const units = ["u0", "u1"].map((id) => makeUnit(id, `${id}-marker`));
		const judgeBatch = makeJudge({
			perDrain: 1,
			answers: {
				u0: answer("bad", 0.9, { ok: 0.1 }),
				u1: answer("bad", 0.8, { ok: 0.2 }),
			},
		});
		const report = await checkTraits(
			{ revset: "trunk()..@" },
			{ tool: makeTool(trait, units), judgeBatch, print: makePrint() },
		);

		expect(report.counts.judged).toBe(2);
		expect(report.counts.flagged).toBe(2);
		expect(report.counts.errors).toBe(0);
		expect(judgeBatch.drainCalls()).toBeGreaterThan(2);
	});

	test("records per-item errors and missing judgments without inventing verdicts", async () => {
		const trait = makeTrait();
		const units = ["u0", "u1", "u2"].map((id) => makeUnit(id, `${id}-marker`));
		const judgeBatch = makeJudge({
			errors: { u0: "model exploded" },
			missing: new Set(["u1"]),
			answers: { u2: answer("ok", 0.9, { bad: 0.1 }) },
		});
		const report = await checkTraits(
			{ revset: "trunk()..@" },
			{ tool: makeTool(trait, units), judgeBatch, print: makePrint() },
		);

		expect(report.counts.judged).toBe(1);
		expect(report.counts.verdicts).toEqual({ ok: 1, bad: 0, unsure: 0 });
		expect(report.counts.errors).toBe(2);
		expect(report.counts.batchFailures).toBe(0);
		expect(report.errors.map((entry) => entry.unitId).sort()).toEqual(["u0", "u1"]);
		expect(report.errors.find((entry) => entry.unitId === "u0")?.error).toBe("model exploded");
		expect(report.errors.find((entry) => entry.unitId === "u1")?.error).toBe("no judgment returned");
		expect(judgeBatch.closed).toEqual(["demo"]);
	});

	test("keeps partial results after a wholesale drain failure and closes the batch", async () => {
		const trait = makeTrait();
		const units = ["u0", "u1"].map((id) => makeUnit(id, `${id}-marker`));
		const judgeBatch = makeJudge({ drainError: "no judge available" });
		const report = await checkTraits(
			{ revset: "trunk()..@" },
			{ tool: makeTool(trait, units), judgeBatch, print: makePrint() },
		);

		expect(report.counts.judged).toBe(0);
		expect(report.counts.batchFailures).toBe(1);
		expect(report.counts.errors).toBe(2);
		expect(report.batchFailures[0].error).toContain("no judge available");
		expect(report.errors.every((entry) => entry.error.includes("no judge available"))).toBe(true);
		expect(judgeBatch.closed).toEqual(["demo"]);
	});

	test("marks explicitly selected whole files in state and instructions", async () => {
		const trait = makeTrait();
		const units = [makeUnit("u0", "whole-marker")];
		const judgeBatch = makeJudge({ answers: { u0: answer("ok", 0.95, { bad: 0.05 }) } });

		await checkTraits(
			{ revset: "trunk()..@", wholeFiles: true },
			{ tool: makeTool(trait, units), judgeBatch, print: makePrint() },
		);
		const wholeCall = judgeBatch.calls[0];
		expect(wholeCall.questions.demo.instructions).toContain("entire file");
		expect(wholeCall.questions.demo.instructions).not.toContain("only lines changed");
		expect(wholeCall.states.u0).toContain("Scope: whole file");
		expect(wholeCall.states.u0).toContain("Content (whole file):");

		await checkTraits(
			{ revset: "trunk()..@" },
			{ tool: makeTool(trait, units), judgeBatch, print: makePrint() },
		);
		const hunkCall = judgeBatch.calls[1];
		expect(hunkCall.questions.demo.instructions).toContain("only lines changed");
		expect(hunkCall.states.u0).not.toContain("Scope: whole file");
	});

	test("skips oversized states with an issue instead of truncating, and reports zero judged", async () => {
		const trait = makeTrait({ maxStateChars: 120 });
		const unit = makeUnit("u0", "x".repeat(400));
		const judgeBatch = makeJudge({});
		const print = makePrint();
		const report = await checkTraits(
			{ revset: "trunk()..@" },
			{ tool: makeTool(trait, [unit]), judgeBatch, print },
		);

		expect(judgeBatch.calls).toHaveLength(0);
		expect(report.counts.states).toBe(1);
		expect(report.counts.judged).toBe(0);
		expect(report.counts.skipped).toBe(1);
		expect(report.skipped[0].reason).toBe("oversized-state");
		expect(report.contextIssues.some((entry) => entry.issues[0]?.type === "oversized-state")).toBe(true);
		expect(print.text()).toContain("oversized-state");
		expect(print.text()).toContain("No hunks were judged");
	});

	test("handles zero units explicitly without calling judgeBatch", async () => {
		const trait = makeTrait();
		const judgeBatch = makeJudge({});
		const print = makePrint();
		const report = await checkTraits(
			{ revset: "trunk()..@" },
			{ tool: makeTool(trait, []), judgeBatch, print },
		);

		expect(judgeBatch.calls).toHaveLength(0);
		expect(report.counts.states).toBe(0);
		expect(report.counts.judged).toBe(0);
		expect(print.text()).toContain("No hunks were judged");
	});
});
