# Project 1 – Data Validation & Sync Engine

## Obiettivo

Questo workflow n8n simula un processo reale di **data intake per lead/clienti**.
Riceve i dati tramite webhook, valida l'input, controlla eventuali duplicati su database Supabase, salva il record se non esiste già e registra ogni esecuzione in una tabella di log.

---

## Stack

| Componente | Tecnologia |
|-----------|-----------|
| Automation engine | n8n |
| Database | Supabase (PostgreSQL) |
| Trigger | Webhook HTTP POST |
| API calls | HTTP Request node |
| Validation logic | Code node (JavaScript) |

---

## Flusso

```
POST /webhook/lead-intake
        │
        ▼
┌─────────────────────┐
│   Validate Input    │  ← normalizza email, valida campi obbligatori
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│  Check Duplicate    │  ← GET su Supabase per email
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│  Prepare Flag       │  ← isDuplicate: true/false
└────────┬────────────┘
         │
    ┌────┴────┐
  TRUE      FALSE
    │          │
    ▼          ▼
Insert     Insert
Dup Log    Customer
    │          │
    ▼          ▼
Respond    Insert
  409      Success Log
               │
               ▼
           Respond
             201
```

---

## Logica di deduplicazione

La prevenzione duplicati è a **due livelli**:

1. **Controllo applicativo** nel workflow: query Supabase per email → se esiste, blocca e risponde 409
2. **Vincolo lato DB**: colonna `email UNIQUE` in PostgreSQL → fallback sicuro anche in caso di race condition

---

## API Reference

### Endpoint

```
POST https://n8n.n8nself.uk/webhook/lead-intake
```

### Request Body

```json
{
  "email": "mario@example.com",
  "name": "Mario Rossi",
  "phone": "3331234567",
  "source": "landing-page"
}
```

| Campo | Tipo | Obbligatorio | Note |
|-------|------|-------------|------|
| email | string | ✅ | normalizzata in lowercase |
| name | string | ✅ | |
| phone | string | ❌ | |
| source | string | ❌ | default: `web` |

### Risposta — Nuovo cliente (201)

```json
{
  "success": true,
  "message": "Customer created successfully"
}
```

### Risposta — Duplicato (409)

```json
{
  "success": false,
  "message": "Duplicate customer",
  "email": "mario@example.com"
}
```

### Risposta — Errore validazione (500)

```json
{
  "error": "VALIDATION_ERROR: email is required"
}
```

---

## Database

Le tabelle sono definite in [`db/schema.sql`](db/schema.sql).

### `customers`

| Colonna | Tipo | Note |
|---------|------|------|
| id | bigint | auto-generated |
| email | text | UNIQUE |
| name | text | |
| phone | text | nullable |
| source | text | default 'web' |
| created_at | timestamptz | auto |

### `automation_logs`

| Colonna | Tipo | Note |
|---------|------|------|
| id | bigint | auto-generated |
| workflow_name | text | |
| event_type | text | `duplicate_check` / `customer_insert` |
| status | text | `duplicate` / `success` |
| message | text | |
| payload | jsonb | email + name del lead |
| created_at | timestamptz | auto |

---

## Setup Supabase

1. Crea un progetto su [supabase.com](https://supabase.com)
2. Apri **SQL Editor** e incolla il contenuto di `db/schema.sql`
3. In **Settings → API** copia:
   - `Project URL`
   - `service_role key` (o `anon key` per test)
4. Nel workflow n8n, sostituisci tutti i placeholder:
   - `YOUR_PROJECT.supabase.co` → il tuo Project URL
   - `YOUR_SUPABASE_KEY` → la tua chiave API

---

## Test

### Caso 1 — Nuovo record

```bash
curl -X POST https://n8n.n8nself.uk/webhook/lead-intake \
  -H "Content-Type: application/json" \
  -d '{"email":"mario@example.com","name":"Mario Rossi","phone":"3331234567","source":"landing-page"}'
```

Risposta attesa: `HTTP 201`

### Caso 2 — Duplicato

```bash
# Invia lo stesso payload una seconda volta
curl -X POST https://n8n.n8nself.uk/webhook/lead-intake \
  -H "Content-Type: application/json" \
  -d '{"email":"mario@example.com","name":"Mario Rossi","phone":"3331234567","source":"landing-page"}'
```

Risposta attesa: `HTTP 409`

---

## File inclusi

```
project-1-data-sync/
├── README.md
├── workflow/
│   └── main-workflow.json       ← workflow n8n esportato
├── db/
│   └── schema.sql               ← schema PostgreSQL
└── docs/
    ├── sample-request.json
    ├── sample-response-success.json
    ├── sample-response-duplicate.json
    └── screenshots/
        ├── workflow-overview.png
        ├── execution-success.png
        ├── execution-duplicate.png
        ├── customers-table.png
        └── logs-table.png
```

---

## Concetti dimostrati

- **Webhook automation** — trigger HTTP POST per acquisizione dati real-time
- **Input validation** — controllo campi obbligatori e formato email
- **Data normalization** — email in lowercase, trim whitespace
- **Duplicate prevention** — deduplicazione a livello applicativo + DB constraint
- **Audit trail** — ogni evento loggato su tabella dedicata
- **REST API integration** — comunicazione con Supabase via HTTP Request
- **Branching logic** — routing condizionale IF/TRUE/FALSE
- **HTTP status codes semantici** — 201 Created, 409 Conflict

---

## Miglioramenti futuri

- Retry automatico su errori temporanei (5xx Supabase)
- Notifiche Slack/Email su errori critici
- Autenticazione webhook con HMAC signature
- Dashboard KPI su Supabase Studio
- Rate limiting per prevenire abusi
- Webhook validation token

---

