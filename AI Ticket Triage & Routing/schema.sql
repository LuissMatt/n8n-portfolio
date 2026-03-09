-- ============================================================
-- AI Ticket Triage & Routing — Supabase Schema
-- Run this in your Supabase project → SQL Editor
-- ============================================================

-- ─────────────────────────────────────────
-- TABLE: tickets
-- Stores every incoming support ticket with
-- its AI classification results.
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS tickets (
  id           BIGSERIAL PRIMARY KEY,
  ticket_id    TEXT UNIQUE NOT NULL,        -- e.g. TKT-1741514400000-K3X7M
  email        TEXT NOT NULL,               -- submitter email
  subject      TEXT NOT NULL,               -- ticket subject line
  description  TEXT NOT NULL,               -- full ticket body
  team         TEXT NOT NULL                -- AI-assigned team
                 CHECK (team IN ('tech_support', 'billing', 'sales', 'rma')),
  priority     TEXT NOT NULL                -- AI-assigned priority
                 CHECK (priority IN ('low', 'medium', 'high')),
  category     TEXT,                        -- snake_case category label
  summary      TEXT,                        -- AI-generated 1-2 sentence summary
  confidence   FLOAT                        -- AI confidence score 0.0–1.0
                 CHECK (confidence >= 0 AND confidence <= 1),
  status       TEXT NOT NULL DEFAULT 'open' -- ticket lifecycle status
                 CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')),
  received_at  TIMESTAMPTZ,                 -- when webhook was called
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for team-based queries (e.g. "all tech_support tickets")
CREATE INDEX IF NOT EXISTS idx_tickets_team     ON tickets(team);
CREATE INDEX IF NOT EXISTS idx_tickets_priority ON tickets(priority);
CREATE INDEX IF NOT EXISTS idx_tickets_status   ON tickets(status);
CREATE INDEX IF NOT EXISTS idx_tickets_email    ON tickets(email);

-- ─────────────────────────────────────────
-- TABLE: notifications
-- Internal notification log generated for
-- each successfully classified ticket.
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notifications (
  id          BIGSERIAL PRIMARY KEY,
  type        TEXT NOT NULL DEFAULT 'new_ticket',
  ticket_id   TEXT NOT NULL REFERENCES tickets(ticket_id) ON DELETE CASCADE,
  team        TEXT NOT NULL,
  priority    TEXT NOT NULL,
  message     TEXT NOT NULL,               -- formatted notification string
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_ticket_id ON notifications(ticket_id);
CREATE INDEX IF NOT EXISTS idx_notifications_team      ON notifications(team);

-- ─────────────────────────────────────────
-- OPTIONAL: Enable Row Level Security (RLS)
-- Uncomment and configure for production use
-- ─────────────────────────────────────────

-- ALTER TABLE tickets       ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Allow service role full access (used by n8n)
-- CREATE POLICY "service_role_tickets" ON tickets
--   FOR ALL USING (auth.role() = 'service_role');

-- CREATE POLICY "service_role_notifications" ON notifications
--   FOR ALL USING (auth.role() = 'service_role');

-- ─────────────────────────────────────────
-- SAMPLE QUERIES for validation
-- ─────────────────────────────────────────

-- View all open high-priority tickets
-- SELECT ticket_id, email, subject, team, category, confidence, received_at
-- FROM tickets
-- WHERE status = 'open' AND priority = 'high'
-- ORDER BY received_at DESC;

-- Team summary
-- SELECT team, priority, COUNT(*) as count
-- FROM tickets
-- GROUP BY team, priority
-- ORDER BY team, priority;
