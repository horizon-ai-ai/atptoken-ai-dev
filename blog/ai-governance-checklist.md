# AI governance checklist: 12 verifiable checks for model API usage (2026)

> Source: https://atptoken.ai/blog/ai-governance-checklist/
> Published: 2026-07-14 · By: hung-chien (AI Growth & Brand Manager)

AI governance checklist for model API usage: 12 checks with an owner, a done criterion and audit evidence for each, mapped to the NIST AI RMF framework.

## TL;DR

- This checklist covers how a company uses model APIs: keys, model access, data boundaries, spend and incident response. Bias, transparency and model validation belong to a full framework such as the NIST AI RMF.
- Each of the 12 checks has a done criterion, a named owner and the evidence an auditor would ask for, so it can be ticked off or failed on the day of the review.
- The four groups map to the NIST AI RMF functions Govern, Map, Measure and Manage. Data classification and vendor retention terms stay with security and legal whatever tooling you use.

An AI governance checklist is a list of controls you can verify, each with an owner and evidence, that shows your company knows which teams call which AI models, with which data, and at what cost. This one has 12 checks in four groups for model API usage. Each check states what "done" looks like, who owns it and what an auditor would ask to see, and the groups map to the four functions of the NIST AI Risk Management Framework.

## What this checklist covers

It is an operational checklist for model API usage: API keys, model access, data boundaries, spend and incident response. It does not cover bias and fairness testing, transparency and explainability, model validation or the impact of AI decisions on people. For those, use the [NIST AI Risk Management Framework](https://www.nist.gov/itl/ai-risk-management-framework) (AI RMF 1.0, released January 26, 2023) and its Generative AI Profile, NIST-AI-600-1, released July 26, 2024.

## The 12 checks at a glance

| # | Check | Owner | Evidence |
|---|---|---|---|
| 1 | Every key belongs to one project with a named owner | Platform team | Key inventory with project and owner per key |
| 2 | Offboarding revokes AI access the same day | IT + platform team | Offboarding ticket with revocation timestamp |
| 3 | Sandbox is separate from production and has a fixed budget | Engineering managers | Project list with budgets per environment |
| 4 | Each project has a model allowlist with a recorded reason | Project tech lead | Allowlist export and change tickets |
| 5 | Data classes are mapped to permitted vendors and models | Security / privacy | Signed data classification table |
| 6 | Each vendor's data terms are recorded | Legal / procurement | Vendor register with review dates |
| 7 | Every project has a hard spending limit | Budget owner | Limit configuration per project |
| 8 | Each request can be traced, and retention matches your audit period | Platform team | One request traced end to end by ID |
| 9 | Spend is reconciled monthly by project | Finance + platform | Last three reconciliations |
| 10 | New AI services enter through one intake path | Platform / procurement | Intake tickets for this quarter |
| 11 | A leaked-key runbook exists and was rehearsed | Security on-call | Rehearsal record with timings |
| 12 | Access is reviewed every quarter | Platform team | Signed review with list of changes |

## How the checklist maps to the NIST AI RMF

The NIST AI RMF organizes AI risk management into four functions. The mapping below is approximate: each NIST function is broader than the three checks placed under it.

| Checklist group | NIST AI RMF function | What the function asks for |
|---|---|---|
| 1. Keys and identity (checks 1–3) | Govern | Accountability, roles and policies across the AI lifecycle |
| 2. Models and data boundaries (checks 4–6) | Map | Context of use and the risks that follow from it |
| 3. Spend and attribution (checks 7–9) | Measure | Tracking and assessing what is happening |
| 4. Intake, incidents and review (checks 10–12) | Manage | Prioritizing risks and acting on them |

If your organization already reports against the NIST AI RMF as its AI governance framework, these 12 checks can sit under those four headings as the API-usage controls.

## Group 1: Keys and identity (Govern)

### 1. Every key belongs to one project with a named owner

A key shared across five services can't be revoked without breaking all five. Scope keys to one project each, as in [one project, one key](https://atptoken.ai/blog/one-project-one-key).

- Done when: the key inventory lists a project and a named owner for every active key, and no key is used by more than one service.
- Owner: platform team.
- Evidence: the key inventory export, plus a sample of five services showing five different keys.

### 2. Offboarding revokes AI access the same day

The offboarded contractor's key is the most common gap. Add AI keys and console roles to the offboarding checklist next to email and SSO.

- Done when: the offboarding checklist has a line for AI keys and roles, and the last three leavers were processed within one business day.
- Owner: IT, with the platform team revoking keys.
- Evidence: the offboarding tickets for the last three leavers with revocation timestamps.

### 3. Sandbox is separate from production and has a fixed budget

Experiments run in their own project with their own key and a budget small enough that a runaway loop can't become a month-end surprise, for example USD 50 per team per month.

- Done when: no sandbox key can reach production budget, and every sandbox project has a fixed allocation.
- Owner: engineering managers.
- Evidence: the project list showing environment and budget for each project.

## Group 2: Models and data boundaries (Map)

### 4. Each project has a model allowlist with a recorded reason

A support-summary project may only need [Claude Haiku 4.5](https://atptoken.ai/models/claude-haiku-4-5/). Adding a more expensive model should be a ticket with a reason, and a call to a model outside the list should fail.

- Done when: every project has an explicit allowlist, and a test call to a model outside it returns an error.
- Owner: the project's tech lead, approved by the platform team.
- Evidence: allowlist export per project, change tickets, and the failed test call.

### 5. Data classes are mapped to permitted vendors and models

Engineers should not decide case by case whether customer records can go to an external model. A one-page table answers it: data class, permitted vendors or models, required preprocessing such as redaction.

- Done when: the table is approved, versioned, and each project is tagged with the highest data class it sends.
- Owner: security or privacy.
- Evidence: the signed table with its version date, and the project-to-data-class list.

### 6. Each vendor's data terms are recorded

Retention period, use of data for training and processing region differ between providers and between plans of the same provider. Record them per vendor and plan, with a link to the terms version you reviewed.

- Done when: every AI vendor and plan in use has a row in the register, reviewed in the last 12 months.
- Owner: legal or procurement.
- Evidence: the vendor register with links and review dates.

## Group 3: Spend and attribution (Measure)

### 7. Every project has a hard spending limit

The first sign of an overrun should come from the limit, before the invoice arrives. Name the person who decides what happens when a project reaches it: top up, wait, or switch to a smaller model.

- Done when: every production and sandbox project has a configured limit and a named budget owner.
- Owner: the budget owner for each project.
- Evidence: the limit configuration, and a record of what happened the last time a project hit its limit.

### 8. Each request can be traced, and retention matches your audit period

For any call you should be able to name the project, key, model, status and token counts. Check how long your tooling keeps those records; if it is shorter than the period your auditors sample, export them on a schedule.

- Done when: a request ID from an application log can be traced to its record, and the retention or export period is written down.
- Owner: platform team.
- Evidence: one request traced end to end, and the documented retention or export job.

### 9. Spend is reconciled monthly by project

Convert usage from every provider into one unit and reconcile the invoice total against the sum of project usage. [How to read your AI bill](https://atptoken.ai/blog/how-to-read-your-ai-bill) covers the line items.

- Done when: the monthly report ties the invoice to project totals, and any variance above an agreed threshold has a written explanation.
- Owner: finance, with data from the platform team.
- Evidence: the last three monthly reconciliations.

## Group 4: Intake, incidents and review (Manage)

### 10. New AI services enter through one intake path

Checks 4 to 7 happen before the first key is issued: allowlist, data class, vendor terms, budget. Expense reports are the cross-check, since an AI charge without an intake ticket is [shadow AI](https://atptoken.ai/blog/shadow-ai-governed-control-plane).

- Done when: every AI service added this quarter has an intake ticket, and the expense report review found no AI charges without one.
- Owner: platform team with procurement.
- Evidence: intake tickets and the expense review result.

### 11. A leaked-key runbook exists and was rehearsed

The runbook lists revoke, trace and reissue steps, plus who notifies whom. Rehearse it and time it.

- Done when: the runbook is published and was rehearsed in the last 12 months with time-to-revoke recorded.
- Owner: security on-call.
- Evidence: the runbook and the rehearsal record with timestamps.

### 12. Access is reviewed every quarter

Revoke keys with no traffic in 30 days, close projects without an owner and confirm the admin list.

- Done when: the review is signed off within two weeks of quarter end.
- Owner: platform team.
- Evidence: the signed review with the list of revoked keys and role changes.

## Where to start by company size

| Size | Start with | How ownership works | Evidence format |
|---|---|---|---|
| Under 20 engineers | Checks 1, 3, 7, 11 in the first month | One person owns all four | A single shared sheet |
| 20 to 200 engineers | Add 4, 8, 9, 12 | Platform team plus one finance contact | Exports from your tooling, monthly |
| 200+ or regulated | All 12, with 5 and 6 before widening model access | Named owner per check, internal audit samples quarterly | Retained exports covering the audit period |

## Running this checklist on ATP Token

ATP Token covers the checks that live in the API path. Data classification (check 5) and vendor terms (check 6) remain your policy documents, and the intake, runbook and review processes (checks 10 to 12) remain your process. ATP supplies the records those processes use.

| Check | What ATP provides | Docs |
|---|---|---|
| 1 | Organization → workspace → project → key hierarchy; each key belongs to exactly one project, and the API keys page lists every key across workspaces and projects | [Set up your organization](https://atptoken.ai/docs/console-setup), [Managing API keys](https://atptoken.ai/docs/console-keys) |
| 2 | Revoked keys stop working immediately and stay in the roster; Owner / Admin / Member roles at workspace or project level | [Managing API keys](https://atptoken.ai/docs/console-keys), [Team & roles](https://atptoken.ai/docs/team) |
| 3, 7 | Credits are allocated organization → workspace → project, and a project can only spend what it was allocated; the Usage page shows Allocated vs Consumed per level | [Set up a team with budget caps](https://atptoken.ai/docs/cb-budget-caps) |
| 4 | Allowed models are set per project (at least one); a call to any other model returns `403` before reaching a provider | [Workspaces & projects](https://atptoken.ai/docs/resources), [How it works](https://atptoken.ai/docs/how-it-works) |
| 8 | Request logs per call with time, scope, model, status, request ID and input / output tokens; every response carries `x-request-id`; retention is 7 days, so export for longer audit periods | [Usage & logs](https://atptoken.ai/docs/monitoring), [Request logs API](https://atptoken.ai/docs/console-api-logs) |
| 9 | One unit across 70+ models from 11 vendors: 1 credit = USD 0.01; Usage page by model and by key | [How credits work](https://atptoken.ai/docs/credits), [Tracking spend](https://atptoken.ai/docs/spend) |
| 11, 12 | Activity log of sign-ins, invites, quota changes and resource updates; per-key token totals on the Usage page to find idle keys | [Usage & logs](https://atptoken.ai/docs/monitoring) |

For check 8, the 7-day request log is a debugging view. If your audit period is longer, call the Console API's request logs endpoint on a schedule and keep the results in your own storage.

[Set up a team with budget caps](https://atptoken.ai/docs/cb-budget-caps)

## Related reading

- [One project, one key](https://atptoken.ai/blog/one-project-one-key)
- [AI spending caps that work](https://atptoken.ai/blog/ai-spending-caps-that-work)
- [What is shadow AI?](https://atptoken.ai/blog/shadow-ai-governed-control-plane)

## FAQ

### What is an AI governance checklist?

An AI governance checklist is a list of controls a company can verify, each with an owner and evidence, showing that AI use is approved, attributable and reviewable. An operational checklist like this one focuses on model API usage: keys, model access, data boundaries, spend and incident response.

### What should an AI governance checklist include?

At minimum: key ownership and revocation, separation of sandbox and production, a model allowlist per project, a data classification table, a vendor terms register, spending limits, per-request records, monthly reconciliation, an intake path for new services, a leaked-key runbook and a quarterly access review.

### What is the difference between an AI governance checklist and an AI governance framework?

A framework such as the NIST AI Risk Management Framework describes the full set of outcomes an organization should manage, including fairness, transparency and impact on people. A checklist turns a slice of that into specific checks with owners and evidence. This checklist covers the operational slice for model API usage.

### Who owns AI governance in a company?

Ownership is usually split: the platform team owns keys, model access and logs; security and legal own data classification and vendor terms; finance and each budget owner own spending limits and reconciliation. Each check should name one accountable owner.

### How often should AI governance controls be reviewed?

Review access and keys quarterly, reconcile spend monthly, and rehearse the leaked-key runbook at least once a year. Re-run the vendor terms review whenever a provider changes its terms or you add a new plan.

---

Tags: AI governance, AI governance checklist, ATP
