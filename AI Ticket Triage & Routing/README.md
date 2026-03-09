## 📌 What This Project Does

An incoming support ticket is received via webhook, validated, classified by an AI agent, stored in a database, and routed to the right internal team — all automatically, in under 2 seconds.

```
POST /webhook/ticket-triage
        │
        ▼
  [Input Validation]
        │
   valid? ──── NO ──▶  400 { success: false, error, missing }
        │
       YES
        ▼
  [AI Classification]  ◄── GPT-4o-mini + Structured Output Parser
        │
        ▼
  [Merge Ticket Data]
        │
        ▼
  [Save → Supabase: tickets table]
        │
        ▼
  [Prepare Notification]
        │
        ▼
  [Save → Supabase: notifications table]
        │
        ▼
  200 { success: true, ticket_id, team, priority, category, summary }
```

---

## 🧰 Tech Stack

| Component | Technology |
|-----------|-----------|
| Automation engine | [n8n](https://n8n.io) (self-hosted) |
| AI classification | OpenAI GPT-4o-mini via LangChain Agent |
| Structured output | n8n `outputParserStructured` |
| Database | [Supabase](https://supabase.com) (PostgreSQL via REST API) |


## 🚀 Quick Start

### Prerequisites
- n8n instance (self-hosted or cloud)
- Supabase account (free tier works fine)
- OpenAI API key

### 1. Set up Supabase

In your Supabase project → **SQL Editor**, run the contents of `supabase/schema.sql`.

### 2. Configure n8n Variables

Go to **Settings → Variables** in your n8n instance and create:

| Variable | Value |
|----------|-------|
| `SUPABASE_URL` | `https://<your-project-id>.supabase.co` |
| `SUPABASE_ANON_KEY` | Your Supabase anon or service key |

### 3. Import the Workflow

In n8n: **Workflows → Import from file** → upload `workflow/ai_ticket_triage.json`

### 4. Add OpenAI Credential

Go to **Credentials → New → OpenAI API**, add your key. Then open the workflow and connect the credential to the **OpenAI GPT-4o Mini** node.

### 5. Activate & Test

Activate the workflow, then send a test request:

```bash
curl -X POST https://<your-n8n-url>/webhook/ticket-triage \
  -H 'Content-Type: application/json' \
  -d '{
    "email": "mario.rossi@workshop.it",
    "subject": "Flex device error E07 after firmware update",
    "description": "After updating to firmware 3.2.1, the Flex tool shows error E07 and cannot connect to ECU. The device was working fine before the update."
  }'
```

**Expected response:**
```json
{
  "success": true,
  "ticket_id": "TKT-1741514400000-K3X7M",
  "team": "tech_support",
  "priority": "high",
  "category": "firmware_error",
  "summary": "Customer reports Flex device E07 error preventing ECU connection after firmware update.",
  "status": "open",
  "message": "Classified and routed to tech_support",
  "timestamp": "2026-03-09T09:30:00.000Z"
}
```

---

## 🤖 AI Classification Logic

The AI agent classifies each ticket into:

### Teams

| Team | When assigned |
|------|--------------|
| `tech_support` | Device errors, firmware issues, software bugs, ECU connection failures |
| `billing` | Payments, invoices, refunds, subscriptions |
| `sales` | Pre-sale questions, licensing, pricing, product comparisons |
| `rma` | Defective hardware, return requests, warranty claims, repair tickets |
| Trigger | n8n Webhook (HTTP POST) |
| Response | n8n Respond to Webhook |
