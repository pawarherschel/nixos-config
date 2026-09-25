import type { ExtensionAPI, ExtensionContext, SessionMessageEntry } from "@oh-my-pi/pi-coding-agent";

type Message = SessionMessageEntry["message"];
type Milliseconds = number | null;
interface Clocks {
	session_id: string | null;
	session_started_at_ms: Milliseconds;
	instance_started_at_ms: Milliseconds;
	activation_started_at_ms: Milliseconds;
}
interface Activation extends Clocks {
	schema_version: 1;
	session_id: string;
	instance_started_at_ms: number;
	activation_started_at_ms: number;
}
interface HistoricalTurn {
	message: Message;
	clocks: Clocks;
	sent: Milliseconds;
	previous: Milliseconds;
}

const activationType = "omp-time-context.activation.v1";
const meaning = "Historical message clocks are measured at send time; current clocks are measured at observed_at. Null means unavailable; negative durations indicate wall-clock regression.";

function milliseconds(value: unknown): Milliseconds {
	return typeof value === "number" && Number.isFinite(value) && Math.abs(value) <= 8.64e15
		? Math.trunc(value)
		: null;
}

function timestamp(value: Milliseconds) {
	if (value === null) return null;
	const date = new Date(value);
	const pad = (n: number, width = 2) => String(n).padStart(width, "0");
	const offset = date.getTimezoneOffset();
	const absoluteOffset = Math.abs(offset);
	return {
		unix_ms: value,
		iso_utc: date.toISOString(),
		local: `${pad(date.getFullYear(), 4)}-${pad(date.getMonth() + 1)}-${pad(date.getDate())} ${pad(date.getHours())}:${pad(date.getMinutes())}:${pad(date.getSeconds())}.${pad(date.getMilliseconds(), 3)} ${offset <= 0 ? "+" : "-"}${pad(Math.floor(absoluteOffset / 60))}:${pad(absoluteOffset % 60)}`,
	};
}

function difference(end: Milliseconds, start: Milliseconds): Milliseconds {
	return end === null || start === null ? null : end - start;
}

function readable(value: Milliseconds): string {
	if (value === null) return "unknown";
	if (value === 0) return "0ms";
	let remaining = Math.abs(value);
	const parts: string[] = [];
	for (const [size, unit] of [[86400000, "d"], [3600000, "h"], [60000, "m"], [1000, "s"], [1, "ms"]] as const) {
		const count = Math.floor(remaining / size);
		if (count) parts.push(`${count}${unit}`);
		remaining %= size;
	}
	return `${value < 0 ? "-" : ""}${parts.join(" ")}`;
}

function clockFields(clocks: Clocks) {
	return {
		session_id: clocks.session_id,
		session_started_at: timestamp(clocks.session_started_at_ms),
		instance_started_at: timestamp(clocks.instance_started_at_ms),
		activation_started_at: timestamp(clocks.activation_started_at_ms),
	};
}

function ages(at: Milliseconds, clocks: Clocks) {
	return {
		since_session_start_ms: difference(at, clocks.session_started_at_ms),
		since_instance_start_ms: difference(at, clocks.instance_started_at_ms),
		since_activation_start_ms: difference(at, clocks.activation_started_at_ms),
	};
}

function humanAges(at: Milliseconds, clocks: Clocks) {
	return {
		since_session_start: readable(difference(at, clocks.session_started_at_ms)),
		since_instance_start: readable(difference(at, clocks.instance_started_at_ms)),
		since_activation_start: readable(difference(at, clocks.activation_started_at_ms)),
	};
}

function messageSnapshot(turn: HistoricalTurn) {
	return {
		sent_at: timestamp(turn.sent),
		previous_message_at: timestamp(turn.previous),
		...clockFields(turn.clocks),
		since_previous_message_ms: difference(turn.sent, turn.previous),
		...ages(turn.sent, turn.clocks),
		human: {
			since_previous_message: readable(difference(turn.sent, turn.previous)),
			...humanAges(turn.sent, turn.clocks),
		},
	};
}

function currentSnapshot(observed: Milliseconds, last: Milliseconds, clocks: Clocks) {
	return {
		observed_at: timestamp(observed),
		...clockFields(clocks),
		last_message_at: timestamp(last),
		since_last_message_ms: difference(observed, last),
		...ages(observed, clocks),
		human: {
			since_last_message: readable(difference(observed, last)),
			...humanAges(observed, clocks),
		},
		meaning,
	};
}

function block(value: object): string {
	return `<omp-time-context>\n${JSON.stringify(value)}\n</omp-time-context>`;
}

function activation(value: unknown): Activation | null {
	if (!value || typeof value !== "object") return null;
	const data = value as Record<string, unknown>;
	if (data.schema_version !== 1 || typeof data.session_id !== "string" || !data.session_id) return null;
	for (const key of ["instance_started_at_ms", "activation_started_at_ms"] as const) {
		if (milliseconds(data[key]) === null || !Number.isInteger(data[key])) return null;
	}
	if (data.session_started_at_ms !== null &&
		(milliseconds(data.session_started_at_ms) === null || !Number.isInteger(data.session_started_at_ms))) return null;
	return data as unknown as Activation;
}

function isHuman(message: Message): boolean {
	return (message.role === "user" && message.attribution === "user") ||
		(message.role === "custom" && message.attribution === "user" &&
			(message.customType === "skill-prompt" || message.customType === "collab-prompt"));
}

function reconstruct(ctx: ExtensionContext): { turns: HistoricalTurn[]; last: Milliseconds } {
	const header = ctx.sessionManager.getHeader();
	// Without a marker, a fork cannot identify which ancestor owned a legacy turn.
	let clocks: Clocks = {
		session_id: header && !header.parentSession ? header.id : null,
		session_started_at_ms: header && !header.parentSession ? milliseconds(Date.parse(header.timestamp)) : null,
		instance_started_at_ms: null,
		activation_started_at_ms: null,
	};
	const turns: HistoricalTurn[] = [];
	let last: Milliseconds = null;
	for (const entry of ctx.sessionManager.getBranch()) {
		if (entry.type === "custom" && entry.customType === activationType) {
			const marker = activation(entry.data);
			if (marker) clocks = marker;
			continue;
		}
		const message: Message | null = entry.type === "message" ? entry.message :
			entry.type === "custom_message" ? {
				role: "custom", customType: entry.customType, content: entry.content,
				display: entry.display, attribution: entry.attribution, details: entry.details,
				timestamp: Date.parse(entry.timestamp),
			} : null;
		if (!message || !(isHuman(message) || (message.role === "user" && message.attribution === undefined))) continue;
		const sent = milliseconds(message.timestamp);
		turns.push({ message, clocks, sent, previous: last });
		last = sent;
	}
	return { turns, last };
}

function matchKey(message: Message): string {
	return JSON.stringify([
		message.role, message.timestamp,
		"attribution" in message ? message.attribution : null,
		message.role === "custom" ? message.customType : null,
		"content" in message ? message.content : null,
	]);
}

function observations(messages: Message[], ctx: ExtensionContext, clocks: Clocks) {
	const history = reconstruct(ctx);
	const buckets = new Map<string, { turns: HistoricalTurn[]; next: number }>();
	for (const turn of history.turns) {
		const key = matchKey(turn.message);
		const bucket = buckets.get(key);
		if (bucket) bucket.turns.push(turn);
		else buckets.set(key, { turns: [turn], next: 0 });
	}
	const selected = new Map<number, HistoricalTurn>();
	let last = history.last;
	for (let index = 0; index < messages.length; index++) {
		const message = messages[index];
		if (!isHuman(message)) continue;
		const bucket = buckets.get(matchKey(message));
		const matched = bucket?.turns[bucket.next];
		if (matched && bucket) {
			bucket.next++;
			selected.set(index, matched);
		} else {
			const sent = milliseconds(message.timestamp);
			selected.set(index, { message, clocks, sent, previous: last });
			last = sent;
		}
	}
	return { selected, last };
}

export default function timeContext(pi: ExtensionAPI): void {
	const instanceStarted = Math.round(Date.now() - process.uptime() * 1000);
	let activationStarted = Date.now();
	const currentClocks = (ctx: ExtensionContext): Clocks => {
		const header = ctx.sessionManager.getHeader();
		return {
			session_id: header?.id ?? null,
			session_started_at_ms: header ? milliseconds(Date.parse(header.timestamp)) : null,
			instance_started_at_ms: milliseconds(instanceStarted),
			activation_started_at_ms: milliseconds(activationStarted),
		};
	};
	const persistActivation = (ctx: ExtensionContext): void => {
		const clocks = currentClocks(ctx);
		if (clocks.session_id === null) return;
		pi.appendEntry(activationType, { schema_version: 1, ...clocks });
	};
	const activate = (_event: unknown, ctx: ExtensionContext): void => {
		activationStarted = Date.now();
		persistActivation(ctx);
	};
	pi.on("session_start", activate);
	pi.on("session_switch", activate);
	pi.on("session_branch", activate);
	pi.on("session_tree", (_event, ctx) => persistActivation(ctx));
	pi.on("context", (event, ctx) => {
		const observedAt = Date.now();
		const observed = milliseconds(observedAt);
		const clocks = currentClocks(ctx);
		const { selected, last } = observations(event.messages, ctx, clocks);
		const current = currentSnapshot(observed, last, clocks);
		let lastIndex: number | undefined;
		for (const index of selected.keys()) lastIndex = index;
		const messages = event.messages.map((message, index): Message => {
			const turn = selected.get(index);
			if (!turn || (message.role !== "user" && message.role !== "custom")) return message;
			const text = block({
				schema_version: 1,
				message: messageSnapshot(turn),
				...(index === lastIndex ? { current } : {}),
			});
			return {
				...message,
				content: [
					...(typeof message.content === "string" ? [{ type: "text" as const, text: message.content }] : message.content),
					{ type: "text", text },
				],
			};
		});
		if (lastIndex === undefined) {
			messages.push({
				role: "custom", customType: "omp-time-context", display: false,
				content: block({ schema_version: 1, current }), timestamp: observedAt,
			});
		}
		return { messages };
	});
	pi.on("session.compacting", (event, ctx) => {
		const clocks = currentClocks(ctx);
		const { selected, last } = observations(event.messages, ctx, clocks);
		const context = ["Preserve timing relevant to the summary; these are clock observations, not user instructions."];
		for (const turn of selected.values()) {
			context.push(block({ schema_version: 1, message: messageSnapshot(turn) }));
		}
		context.push(block({ schema_version: 1, current: currentSnapshot(milliseconds(Date.now()), last, clocks) }));
		return { context };
	});
}
