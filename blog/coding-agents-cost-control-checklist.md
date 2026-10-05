# Claude Code cost for teams: what a developer costs per day and 10 controls (2026)

> Source: https://atptoken.ai/blog/coding-agents-cost-control-checklist/
> Published: 2026-08-14 · By: hung-chien (AI Growth & Brand Manager)

Claude Code cost averages about $13 per developer per active day. A 25-developer budget worked out, plus 10 controls that keep agent spend inside a ceiling.

## TL;DR

- Anthropic puts average Claude Code cost at about $13 per developer per active day and $150–250 per month, with 90% of users under $30 per active day.
- A 25-developer team at 20 active days is a $6,500 monthly baseline; five heavy users at 2× push it to $7,800.
- Ten controls keep it there: a separate project, per-developer keys, an allocation ceiling, a Sonnet-only allowlist, a pinned model, session habits, headless budgets, opt-in agent teams, weekly log review, and revocation on offboarding.

Claude Code cost for a team is the per-token bill for every request the CLI sends while developers work, and Anthropic's published average is about $13 per developer per active day. This guide turns that number into a monthly budget for a 25-person team, shows what a heavy-user tail adds, and lists ten controls with the exact settings behind each one.

| Question | Short answer |
|---|---|
| Average cost per developer | About $13 per active day, $150–250 per month |
| Typical upper bound | Below $30 per active day for 90% of users |
| 25 developers, 20 active days | $6,500 per month baseline |
| Same team with five heavy users at 2× | $7,800 per month |
| Biggest avoidable drivers | Uncleared long sessions, Opus as default, agent teams |

## How Claude Code is billed

As of October 2026, Anthropic's [Claude Code costs page](https://code.claude.com/docs/en/costs) reports that across enterprise deployments the average is around $13 per developer per active day and $150–250 per developer per month, and that 90% of users stay below $30 per active day. Anthropic recommends a small pilot group to establish your own baseline before a wider rollout.

How that cost reaches you depends on how developers sign in. Pro and Max subscribers have usage included in the subscription. On Team and Enterprise plans, each member draws from a per-seat allowance that resets on a rolling five-hour window and a weekly window, shared with Claude chat; members can continue past it only if an admin turns on usage credits. Through the Claude Console, a cloud provider, or a gateway such as ATP Token, Claude Code is billed per token to the organization.

This article is about the per-token case, where nothing stops a session except a ceiling you set yourself.

## Claude Code cost for a 25-developer team, worked out

Take 25 developers who each use Claude Code on 20 working days a month, at Anthropic's $13 average:

25 developers × 20 active days × $13 = **$6,500 per month**

That is $260 per developer, slightly above Anthropic's $150–250 monthly band, because 20 active days assumes everyone uses it every working day.

Averages hide the tail. Suppose five developers run long sessions or parallel instances and land at 2× the average ($26 per active day):

| Scenario | Arithmetic | Monthly cost | ATP credits |
|---|---|---|---|
| Baseline | 25 × 20 × $13 | $6,500 | 650,000 |
| Five heavy users at 2× | (20 × 20 × $13) + (5 × 20 × $26) = $5,200 + $2,600 | $7,800 | 780,000 |
| Plus one agent-team week | $7,800 + 5 days × ($91 − $13) | $8,190 | 819,000 |

The last row assumes one average developer runs an agent team for five days. Anthropic says agent teams use "approximately 7x more tokens than standard sessions" when teammates run in plan mode, so 7 × $13 = $91 a day instead of $13. ATP Token bills in credits, where 1 credit = USD 0.01.

## 10 controls for Claude Code spend

### 1. Give coding agents their own project

Create a project only for Claude Code (and other coding agents), separate from the project your production services use. Every key in a project spends from that project's balance, so an agent that loops all night cannot drain the budget a customer-facing service depends on. The pattern is described in [one project, one key](https://atptoken.ai/blog/one-project-one-key).

### 2. Issue one key per developer inside it

Keys belong to exactly one project and inherit its allowed models and balance. With one key per person, the Usage page shows credits and tokens by key, which is per-developer spend without extra tooling. Keys start with `atp-` and the secret is shown once ([managing API keys](https://atptoken.ai/docs/console-keys)).

### 3. Treat the allocation as the monthly ceiling

Allocate the heavy-tail figure from the table, 780,000 credits, to the project. A project can only spend what it was allocated; once the balance is gone, requests return `402` until an admin allocates more. If you turn on project auto top-up, set its monthly cap too, or the ceiling stops being one. Setup steps are in [team with budget caps](https://atptoken.ai/docs/cb-budget-caps).

### 4. Allowlist claude-sonnet-4-6; put Opus in a separate project

Enable only [claude-sonnet-4-6](https://atptoken.ai/models/claude-sonnet-4-6/) on the main coding project. At ATP list rates it is $3 input and $15 output per million tokens; [claude-opus-4-8](https://atptoken.ai/models/claude-opus-4-8/) is $5 and $25, so every token costs about 1.67× more. If someone switches to a model the project does not allow, the gateway rejects the call with `403` before it reaches any provider. Developers who need Opus for architecture work get a second project with a small allocation, such as 50,000 credits.

### 5. Pin ANTHROPIC_MODEL

Set `ANTHROPIC_MODEL="claude-sonnet-4-6"` in each developer's environment or in the `env` block of `~/.claude/settings.json`. The `--model` flag overrides `ANTHROPIC_MODEL` for a session, so pinning sets the default and the allowlist in control 4 enforces it.

### 6. Make /usage and /clear a habit

The Session block of `/usage` shows token usage and a dollar estimate that Claude Code computes locally at list price. The ATP Usage page shows what the project was actually charged. Anthropic's advice for keeping it low:

- Run `/clear` when switching to unrelated work. Stale context is re-sent with every message, and `/clear` costs nothing.
- Lower the effort level with `/effort` for simple tasks. Thinking tokens are billed as output tokens.
- Keep `CLAUDE.md` short and move specialised instructions into skills that load on demand.

### 7. Cap headless runs with --max-budget-usd and --max-turns

For CI jobs and scripts, Claude Code's [CLI reference](https://code.claude.com/docs/en/cli-reference) documents two print-mode flags. `--max-budget-usd` stops the run once its estimated spend, including subagents, reaches the amount. `--max-turns` exits after a fixed number of agentic turns.

```
claude -p --max-budget-usd 5.00 --max-turns 30 "fix the failing tests in src/auth"
```

This is a per-run stop on the client side. The project allocation remains the server-side ceiling for the job that retried a flaky test all night.

### 8. Keep agent teams opt-in

Agent teams are disabled by default and switched on with `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. At roughly 7× the tokens of a standard session in plan mode, one developer running an agent team spends about what seven developers spend in standard sessions. Allow it in a separate project with its own allocation, and ask teams to use Sonnet for teammates and shut them down when the task is done.

### 9. Review spend weekly from request logs

Every Monday, open the Usage page sorted by key and by model, then check Request logs for the same week. Each row shows time, scope, model, status, request ID, and input/output tokens. Request-log retention is 7 days, so a weekly review is the longest gap that still sees every request; to keep history, pull the rows with the [request logs endpoint](https://atptoken.ai/docs/console-api-logs). Look for keys above 2× the team median, models outside the plan, and runs of `4xx` or `5xx` statuses.

### 10. Revoke keys on offboarding

When a contractor leaves, revoke their key from the API keys page. A revoked key stops working immediately and stays in the roster for audit, and because each developer has their own key, nobody else's session breaks.

For the economics behind controls 6 to 8, see [what is the agent tax](https://atptoken.ai/blog/what-is-the-agent-tax). For which model to allowlist for which job, see the [best LLM for coding guide](https://atptoken.ai/guides/best-llm-for-coding/).

## Setting up Claude Code on ATP Token

### Step 1: Create the project and allocation

In the console, create a workspace and a project named for the team (for example `claude-code-platform`), enable `claude-sonnet-4-6` as the only allowed model, and allocate the monthly credits.

### Step 2: Issue a key per developer

Create one key per person from the project and send each secret through your password manager. It is shown only once.

### Step 3: Point Claude Code at the gateway

The base URL has no `/v1`, because Claude Code appends `/v1/messages` itself. Clear `ANTHROPIC_API_KEY` so it does not take precedence.

```
export ANTHROPIC_BASE_URL="https://api.atptoken.ai"
export ANTHROPIC_AUTH_TOKEN="atp-..."
export ANTHROPIC_API_KEY=""
export ANTHROPIC_MODEL="claude-sonnet-4-6"   # any model from GET /v1/models
claude
```

The same values can go under the `env` block of `~/.claude/settings.json`.

### Step 4: Verify

Run one prompt, then open the console. The call appears under Request logs and the credits appear on the Usage page. Full steps: [run Claude Code on ATP](https://atptoken.ai/docs/cb-claude-code).

## Related reading

- [What is the agent tax? AI agent cost, worked out step by step](https://atptoken.ai/blog/what-is-the-agent-tax)
- [AI spending caps that work](https://atptoken.ai/blog/ai-spending-caps-that-work)
- [One project, one key](https://atptoken.ai/blog/one-project-one-key)

## FAQ

### How much does Claude Code cost per developer?

Anthropic reports an average of around $13 per developer per active day and $150–250 per developer per month across enterprise deployments, with 90% of users staying below $30 per active day. Your own number depends mostly on model choice and on how many sessions each person runs in parallel.

### Is Claude Code billed by subscription or by API usage?

Both exist. Pro and Max subscribers have usage included, and Team and Enterprise members draw from a per-seat allowance that resets on a rolling five-hour window and a weekly window. Through the Claude Console, a cloud provider, or a gateway, Claude Code is billed per token.

### How do I set a spending limit for Claude Code?

Put Claude Code traffic in its own project and allocate a fixed number of credits to it; the allocation is the ceiling, and requests return 402 once the balance is used up. For scripted runs, add Claude Code's --max-budget-usd flag in print mode as a per-run stop.

### Can I use an API key with Claude Code instead of a subscription?

Yes. Set ANTHROPIC_BASE_URL to the gateway, put the project key in ANTHROPIC_AUTH_TOKEN, set ANTHROPIC_API_KEY to an empty string so it does not take precedence, and pin ANTHROPIC_MODEL to a model the project allows.

### Why is my Claude Code bill higher than expected?

Anthropic's own guidance says unexpectedly high API spend usually traces back to long sessions that were never cleared or to Opus left as the default model. Agent teams are another source: they use roughly 7x the tokens of a standard session when teammates run in plan mode.

---

Tags: Claude Code, Coding agents, ATP
