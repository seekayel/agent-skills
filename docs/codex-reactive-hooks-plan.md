# Codex Reactive Hooks — Findings and Plan

Goal: make a Codex session react to incoming Parle messages the way the Claude
Code plugin does — including while the thread is idle — using
[`parlehq/parle-adapters`](https://github.com/parlehq/parle-adapters).

Date: 2026-08-22. Evidence baseline: parle-adapters `main` (codex-plugin
0.6.57), Codex CLI ~0.146.x hook surface.

## TL;DR

Reactive delivery *during a turn* already works in the Codex plugin today.
The only missing piece is **idle wake**: a message that arrives while the
Codex thread is fully idle stays queued until the next user prompt or
lifecycle event. That gap is a Codex host limitation, not a Parle one —
Codex has no supported way for a plugin or background process to start a
turn in an idle thread (tracked upstream as parle-adapters
[#57](https://github.com/parlehq/parle-adapters/issues/57) and openai/codex
[#32188](https://github.com/openai/codex/issues/32188)).

Recommended path: two cheap spikes, then ship a **bounded Stop-boundary
hold** (a plugin-owned reactive window after each turn) while pushing the
upstream **wake-on-background-exec-completion** proposal that makes true
idle wake possible.

## How the machinery works today

The Codex plugin (`packages/codex-plugin`) bundles the shared stdio MCP
server plus trusted lifecycle hooks:

1. The MCP child opens the Parle wake SSE (`/v/agent/wake`). Wake hints
   trigger a zero-wait drain; messages land in a bounded in-memory queue
   inside the **hook delivery bridge**
   (`packages/mcp-server/src/hook-delivery-bridge.ts`), which listens on an
   owner-only Unix socket under
   `~/.local/state/parle/hook-bridge/<hash of "codex-plugin">/`.
2. Codex fires command hooks (`packages/codex-plugin/hooks/hooks.json`) at
   `SessionStart`, `UserPromptSubmit`, `PreToolUse`, `PostToolUse`, and
   `Stop`. Each runs the fail-open launcher `run-parle-hook.sh`, which finds
   the bridge's published Node runtime and runs `parle-hook.mjs`.
3. The hook takes a lease from the bridge, writes the messages as
   `additionalContext` (or, at `Stop`, `{"decision":"block","reason":…}`,
   which *continues the turn* so the model can react before settling), then
   commits the lease; only then does the bridge acknowledge to Parle
   (at-least-once delivery).

So while the model is doing anything — prompting, tool calls, stopping —
queued Parle messages are injected within one lifecycle boundary. "Reactive
hooks" already exist for the active-turn case.

### Prerequisites checklist (why hooks often look broken)

- Install via `codex plugin marketplace add parlehq/parle-adapters` +
  `codex plugin add parle-codex-plugin@parlehq`, then **start a new
  session**.
- **Trust the hooks with `/hooks`** after install *and after any update that
  changes the hook command string*. Until trusted, Parle queues but Codex
  never injects — this is the most common "it doesn't work" cause.
- Unix only. Windows hooks are an explicit no-op (bridge needs Unix
  sockets; parle-adapters [#152](https://github.com/parlehq/parle-adapters/issues/152)
  tracks non-Unix transport).
- A profile must resolve (`~/.parle/profiles` `[default]`, or launch Codex
  with `PARLE_PROFILE=<name>`).
- Verify with `codex plugin list`, `codex mcp get parle`, and `parle_status`
  (canonical watcher/bridge state; Codex has no plugin footer).
- Runtime discovery is bridge-published (`<pid>.node` handle) with fixed
  absolute fallbacks — ambient PATH/mise/nvm weirdness is already designed
  around (`docs/design/codex-hook-runtime.md`).

## The gap: idle wake

When the thread goes idle, nothing fires hooks, so queued messages wait.
The adapter docs treat this as a hard host boundary and explicitly refuse
polling, cron, transcript edits, terminal automation, or a second Codex
process (`docs/design/codex-adapter.md`, "Responsive delivery").

### How Claude Code solves it (the template)

The Claude plugin's `Stop` hook passes
`--idle-wake-launcher …/parle-watch.sh` (`packages/claude-plugin/hooks/hooks.json`).
When the turn ends with delivery bound but no waiter attached, the hook
injects an instruction telling the model to run `parle-watch.sh
<agent_session_id>` **once via Claude's tracked background Bash task**. The
waiter (`parle-mcp.js --parle-watch`) connects to the bridge socket with
`{action:"wait"}` and blocks until responsive delivery is queued, then
exits. Claude's background-task completion wakes the host; the next
lifecycle boundary injects the messages. (Phase A; the durable version is
blocked on a Claude host capability, parle-adapters
[#99](https://github.com/parlehq/parle-adapters/issues/99).)

### Why that doesn't port to Codex yet

Everything except the last link exists for Codex — the bridge and its
`wait` action are host-neutral, and the waiter binary ships inside the
plugin's bundled artifact. The missing link is the host wake:

- Codex background exec sessions (`unified_exec`) **do not wake the model
  on completion** — openai/codex
  [#15723](https://github.com/openai/codex/issues/15723),
  [#32188](https://github.com/openai/codex/issues/32188) (open proposal for
  an opt-in `on_exit: "wake"` continuation turn),
  [#29865](https://github.com/openai/codex/issues/29865) (`wake_on_output`,
  closed as not planned, but with a working reference branch).
- `notify` is outbound-only (alerts a human; cannot start a turn).
- The app-server is documented as an experimental debug interface, and a
  second Codex process resuming the live thread is rejected on approval and
  trust-ownership grounds (parle-adapters #57 documents all of this).

### Verified against Codex source (openai/codex @ 2026-08-24, `3397517`)

Read directly from the Rust codebase rather than docs or third-party
writeups; file references are relative to `codex-rs/`.

- **Hook event set** (`hooks/src/events/`, `hooks/src/registry.rs`):
  `SessionStart`, `UserPromptSubmit`, `PreToolUse`, `PermissionRequest`,
  `PostToolUse`, `PreCompact`, `PostCompact`, `Stop`, `SessionEnd`. The
  plugin uses five of these; `PermissionRequest` and the compact pair are
  additional injection boundaries if ever useful.
- **Stop continuation confirmed** (`core/src/session/turn.rs:509`): a Stop
  hook returning `decision:block` with a non-empty reason re-enters the
  turn loop with the reason recorded as a prompt message and
  `stop_hook_active` set — exactly the mechanism the plugin's Stop
  delivery relies on.
- **Hooks are responders, not initiators.** No hook outcome can start a
  turn. The core injection helper is explicit: `inject_no_new_turn`
  "records them without starting a turn"
  (`core/src/session/inject.rs:117`).
- **Codex has an internal idle-wake — but it's closed to plugins.**
  `maybe_start_turn_for_pending_work` (`core/src/tasks/mod.rs:435`) starts
  a turn on an *idle* session when mailbox mail flagged `trigger_turn`
  arrives, or when any mail arrives while a "durable sleep" is attached to
  the thread. That mailbox is fed only by `Op::InterAgentCommunication`,
  submitted by the in-process multi-agent thread manager
  (`core/src/agent/control.rs`, `pub(crate)`). Nothing in the app-server
  protocol, MCP surface, plugin crate (manifest loading only), or hooks
  reaches it. So the capability parle needs literally exists in core —
  Codex's own agents wake each other with it — it just has no external
  door. This sharpens the upstream ask: expose a scoped version of the
  existing mailbox wake, rather than invent a new mechanism.
- **Durable sleep has no setter.** `SleepItem` in `thread_extension_data`
  is read (`core/src/tasks/mod.rs:428`) but never written anywhere in the
  shipped tree — it's plumbing for embedded Rust extensions, not
  marketplace plugins.
- **`clock.sleep` tool exists** (`core/src/tools/handlers/sleep.rs`): the
  model can pause in-turn up to 12 h at zero inference cost; the sleep ends
  early on new input for the active turn, and its completion is a
  `PostToolUse` boundary — i.e., a *supported* low-cost keepalive loop
  (sleep → PostToolUse hook drains Parle queue → repeat) if we ever want a
  model-cooperative variant. Latency equals the sleep interval, and each
  cycle costs one model round-trip, so it's a fallback, not the plan.
- **Background exec wake still unimplemented.** The only "wake" channels in
  `unified_exec`/`exec-server` unblock an in-flight `read` long-poll inside
  a running tool call (`exec-server/src/client.rs:1433`); process exit
  produces no turn. Confirms #32188 is still open at HEAD.
- **Hook timeouts are generous.** `timeout_sec` defaults to **600 seconds**
  with only a lower clamp (`hooks/src/engine/discovery.rs:606`,
  `unwrap_or(600).max(1)`). The current hooks.json's `timeout: 5` is a
  plugin choice, not a host limit — the Stop-hold option has far more
  headroom than assumed.
- **The app-server daemon is explicitly experimental** — its own README
  says the lifecycle contract may change (`app-server-daemon/README.md`),
  matching parle #57's characterization.
- Codex's own multi-agent system ships a **mailbox-wait tool** ("Wait for a
  mailbox update from any live agent… ends early when new user input is
  steered into the active turn",
  `core/src/tools/handlers/multi_agents_spec.rs`) — the waiter pattern is
  already native to Codex internally, which is good precedent for the
  upstream proposal.

## Options

### A. Bounded Stop-boundary hold (recommended first ship)

Plugin-owned change, no upstream dependency. At `Stop`, instead of
returning `{}` immediately when the queue is empty, the hook holds a
bridge `wait` for up to N seconds (N = hook `timeout` minus a commit
margin; today the hooks set `timeout: 5`, but Codex's hook engine defaults
to 600 s with no upper clamp — verified in source — so multi-minute holds
are in-contract). If a message arrives during the
hold, it returns `decision:"block"` with the delivered context — the turn
continues and the model reacts. If not, it fails open with `{}` as today.

- Effect: an N-second reactive window after every turn, and since each
  delivered message ends in another `Stop`, the window renews while a
  conversation is flowing. A message 10 minutes into idle still waits for
  the next prompt — this narrows the gap, it doesn't close it.
- Event-driven inside the hook (socket wait, not Parle polling), so it
  stays within the adapter doctrine; opt-in via env
  (e.g. `PARLE_CODEX_STOP_HOLD_SECONDS`), default unchanged.
- Open questions for the spike (timeout headroom is now settled from
  source — 600 s default, lower clamp only): whether a running `Stop` hook
  blocks or queues user input; whether Esc cancels it cleanly; how the
  status message renders during the hold.

### B. Keepalive waiter as a long tool call (not recommended)

Port the Claude idle-wake instruction: at `Stop`, tell the model to run the
waiter as a long-running exec; `PostToolUse` injects when it exits. Works
without upstream changes but keeps a turn (and inference session) alive
indefinitely, depends on model compliance every cycle, queues user input
behind the tool call, and is exactly the "babysitter" shape both parle and
openai/codex#32188 want to eliminate. Fallback only if A is blocked.

### C. Upstream wake-on-completion, then port Claude Phase A (durable fix)

Land openai/codex [#32188](https://github.com/openai/codex/issues/32188)
(`exec_command` `on_exit: "wake"`: turn ends, process is awaited without
inference, exit enqueues one bounded continuation turn). parle-adapters
[#57](https://github.com/parlehq/parle-adapters/issues/57) already
specifies what the proposal must cover (atomicity, idempotency, approval
ownership, cross-platform transport). Once available:

1. `Stop` hook adds `--idle-wake-launcher` pointing at a Codex
   `parle-watch` wrapper (the waiter already ships in `dist/parle-mcp.js`).
2. The injected instruction has the model launch the waiter as a background
   exec with wake-on-exit; the thread then goes truly idle.
3. Waiter exits when the bridge queues delivery → continuation turn →
   existing hooks inject and commit.

Adapter-side work is small and mirrors `packages/claude-plugin`: waiter
scope selection for the flat `codex-plugin` scope (today
`runWatcher` defaults to cwd-hash scope, `packages/mcp-server/src/index.ts:305`),
`bound` status on the non-`--direct-parent` path in `parle-hook.mjs`, and
hook-command stability rules from `docs/design/codex-hook-runtime.md`
(any command change forces re-trust — batch it once).

### D. Outside the plugin: supervisor for headless agents

If the real goal is unattended agents (ralph-style loops) rather than an
interactive TUI, skip the idle-wake problem entirely: a wrapper process
waits on Parle (direct HTTP/SSE) and starts `codex exec resume <thread>`
turns as messages arrive. Fully supported CLI surface, works today, but it
owns approvals/sandboxing itself and is explicitly out of scope for the
plugin. Keep as a separate harness, not a parle-adapters change.

## Plan

1. **Spike S1 — prove the baseline (half a day).** Disposable `CODEX_HOME`,
   install the plugin, trust hooks, bind a profile, send Parle messages
   during an active turn and at each boundary. Deliverable: a written
   checklist of what injected where, plus any failures (this also settles
   whether "hooks aren't working" is just the trust/runtime checklist).
2. **Spike S2 — measure the Stop boundary (half a day).** Raise the Stop
   hook `timeout` in a locally staged plugin, hold inside a stub hook, and
   record: max honored timeout, user-input behavior during the hold, Esc
   behavior, and multi-session interaction. This is the go/no-go for A.
3. **Ship Option A** as a small opt-in PR to parle-adapters (env-gated hold
   in the Codex `Stop` hook path, fail-open, tests per the launcher/handler
   validation matrix). One command-string change → one re-trust event.
4. **Advance Option C in parallel.** Add the parle #57 requirements as a
   comment on openai/codex#32188 (or a PR — #29865's reference branch shows
   the touch points in codex-core). The source read sharpens the ask:
   Codex core already starts turns on idle sessions for internal mailbox
   mail (`maybe_start_turn_for_pending_work`) — the proposal should ask to
   route background-exec completion (or a scoped external door) into that
   existing mailbox wake, not to build a new mechanism. When it lands,
   implement the Phase-A port and shrink the Option-A hold to a small
   default.
5. **Skip B; document D** for headless setups.

Sequencing rationale: S1/S2 are cheap information purchases; A is the
smallest batch that delivers real reactivity now; C is the durable fix with
external latency, so it runs concurrently rather than gating A.
