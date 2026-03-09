Project 1 – Data Validation & Sync Engine
Obiettivo
Questo workflow n8n simula un processo reale di data intake per lead/clienti.
Riceve i dati tramite webhook, valida l'input, controlla eventuali duplicati su database Supabase, salva il record se non esiste già e registra ogni esecuzione in una tabella di log.

Stack
ComponenteTecnologiaAutomation enginen8nDatabaseSupabase (PostgreSQL)TriggerWebhook HTTP POSTAPI callsHTTP Request nodeValidation logicCode node (JavaScript)

Flusso
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

Logica di deduplicazione
La prevenzione duplicati è a due livelli:

Controllo applicativo nel workflow: query Supabase per email → se esiste, blocca e risponde 409
Vincolo lato DB: colonna email UNIQUE in PostgreSQL → fallback sicuro anche in caso di race condition

API Reference
Endpoint
POST https://n8n.n8nself.uk/webhook/lead-intake
Request Body
json{
  "email": "mario@example.com",
  "name": "Mario Rossi",
  "phone": "3331234567",
  "source": "landing-page"
}
CampoTipoObbligatorioNoteemailstring✅normalizzata in lowercasenamestring✅phonestring❌sourcestring❌default: web
Risposta — Nuovo cliente (201)
json{
  "success": true,
  "message": "Customer created successfully"
}
Risposta — Duplicato (409)
json{
  "success": false,
  "message": "Duplicate customer",
  "email": "mario@example.com"
}
Risposta — Errore validazione (500)
json{
  "error": "VALIDATION_ERROR: email is required"
}

Database
Le tabelle sono definite in db/schema.sql.
customers
ColonnaTipoNoteidbigintauto-generatedemailtextUNIQUEnametextphonetextnullablesourcetextdefault 'web'created_attimestamptzauto

Test
Caso 1 — Nuovo record
bashcurl -X POST https://n8n.n8nself.uk/webhook/lead-intake \
  -H "Content-Type: application/json" \
  -d '{"email":"mario@example.com","name":"Mario Rossi","phone":"3331234567","source":"landing-page"}'
Risposta attesa: HTTP 201
Caso 2 — Duplicato
bash# Invia lo stesso payload una seconda volta
curl -X POST https://n8n.n8nself.uk/webhook/lead-intake \
  -H "Content-Type: application/json" \
  -d '{"email":"mario@example.com","name":"Mario Rossi","phone":"3331234567","source":"landing-page"}'
Risposta attesa: HTTP 409


Concetti dimostrati

Webhook automation — trigger HTTP POST per acquisizione dati real-time
Input validation — controllo campi obbligatori e formato email
Data normalization — email in lowercase, trim whitespace
Duplicate prevention — deduplicazione a livello applicativo + DB constraint
Audit trail — ogni evento loggato su tabella dedicata
REST API integration — comunicazione con Supabase via HTTP Request
Branching logic — routing condizionale IF/TRUE/FALSE
HTTP status codes semantici — 201 Created, 409 Conflict


Miglioramenti futuri

Retry automatico su errori temporanei (5xx Supabase)
Notifiche Slack/Email su errori critici
Autenticazione webhook con HMAC signature
Dashboard KPI su Supabase Studio
Rate limiting per prevenire abusi
Webhook validation token



