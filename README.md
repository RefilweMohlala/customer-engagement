# Customer Success & Engagement Automation

AI-assisted customer retention system that scores churn risk, drafts personalized WhatsApp
check-ins with a local language model, and routes anything high-stakes to a human before it
goes out. Module 4 of a five-module AI automation portfolio.

**Stack:** Docker · PostgreSQL · n8n · Ollama (local LLM) · WhatsApp Business Cloud API
**Cost:** $0 — fully local except WhatsApp delivery, which stays free in Meta's developer
sandbox mode (see [Cost breakdown](#cost-breakdown))

---

## The problem

Most small businesses lose customers quietly. Nobody decides to leave in one dramatic
moment — they just stop replying, stop opening emails, and one day they're gone. A support
ticket gets resolved and nobody circles back. A customer's tone turns negative and nobody
notices until it's too late. Doing consistent, personalized follow-up across hundreds of
customers isn't something a small team can sustain by hand.

## The solution

A daily automated scan that:

1. **Scores engagement risk** per customer from three signals — recency of activity,
   sentiment trend across recent interactions, and time since last outreach.
2. **Drafts a personalized WhatsApp message** locally via Ollama, referencing the customer's
   actual situation rather than generic template language.
3. **Enforces consent and rate limits** before anything goes out — no message without opt-in,
   no more than one outreach per customer per week.
4. **Routes critical-risk customers to a human** for approval before sending. Low-stakes
   check-ins send automatically; anything close to a churn event waits for a person to read
   it first.
5. **Logs every decision** — score, drafted message, approval status, delivery status — to
   Postgres as an audit trail.

A second workflow listens for inbound WhatsApp replies, logs them as new interaction history,
and processes opt-outs (e.g. a customer replying "STOP") automatically.

## Architecture

```
Schedule Trigger (daily)
  → Pull customers + interaction history from Postgres
  → Score engagement risk (recency, sentiment trend, outreach gap)
  → Upsert scores, log history
  → Filter: skip healthy customers
  → Check consent + rate limit
  → Draft message via local Ollama model
  → Defensively parse AI output (fallback template if malformed)
  → Critical risk? → hold for human approval via email
                    → not critical → send automatically
  → Send via WhatsApp Business Cloud API
  → Log delivery outcome to Postgres

Webhook Trigger (WhatsApp inbound)
  → Log customer reply as new interaction
  → Detect opt-out keywords → update consent status
```


## Where automation stops and a human decides

Every message isn't treated the same. A friendly at-risk check-in is low-stakes — if the tone
is slightly off, the cost is small, and requiring human review for every one of these would
defeat the point of automating at scale. A critical-risk message goes to a customer already
close to leaving, often after a specific negative experience — an AI-drafted message that
misreads that situation has real cost, potentially accelerating the churn it's meant to
prevent. So the system auto-sends for `at_risk` customers and holds for human approval on
`critical` ones, via an email with one-click approve/reject links tied directly back into the
workflow.

## Cost breakdown

Docker, Postgres, n8n, and Ollama are all local and free indefinitely. WhatsApp delivery
stays free by using Meta's developer sandbox mode — up to 5 verified recipient numbers,
unlimited messages, no business verification required. Moving to real paying customers later
means completing Meta's business verification and budgeting a small per-message cost on
proactive outreach (typically a few cents, varies by country and category) — a known,
transparent scaling cost, not something incurred during development or demo use.

**A note on the WhatsApp integration specifically:** the send step was developed against a
mock matching Meta's Cloud API response contract while business verification was pending,
allowing the full pipeline — risk scoring, AI drafting, consent enforcement, human approval
gating — to be built and tested independently of a third-party account verification timeline.
It swaps to the live endpoint with zero changes to any other part of the workflow. This is a
standard pattern for decoupling a build from a dependency outside your control, not a gap in
the implementation.

## Compliance

Built with POPIA in mind: no message sends without explicit opt-in, opt-out is detected and
respected automatically from inbound replies, and every send/skip is logged with a reason,
so consent status is always auditable.

## Known follow-ups

- Swap the mock WhatsApp send node for the live Cloud API call once business verification
  completes (see build guide, Section 8.1 — a one-node change).
- Wire up WhatsApp delivery-status webhooks (`delivered` / `read`) into `message_log`.
- Add a weekly digest summarizing risk-tier movement across the customer base.

## Repo structure

```
customer-engagement/
├─ docker-compose.yml
├─ sql/
│  └─ schema.sql
├─ workflows/
│  ├─ Daily_Engagement_Scan.json
│  └─ Inbound_WhatsApp_Handler.json
└─ docs/
   └─ BUILD_GUIDE.md
```

## Author

Refilwe Mohlala — AI Automation Specialist, Johannesburg, South Africa
[refilwem.netlify.app](https://refilwem.netlify.app) · [GitHub](https://github.com/RefilweMohlala)
