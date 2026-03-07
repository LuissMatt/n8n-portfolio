-- ============================================================
-- Project 1: Data Validation & Sync Engine
-- Schema for Supabase PostgreSQL
-- ============================================================

-- Tabella clienti/lead
create table if not exists customers (
  id bigint generated always as identity primary key,
  email text not null unique,
  name text not null,
  phone text,
  source text default 'web',
  created_at timestamptz default now()
);

-- Tabella log automazioni
create table if not exists automation_logs (
  id bigint generated always as identity primary key,
  workflow_name text not null,
  event_type text not null,
  status text not null,
  message text,
  payload jsonb,
  created_at timestamptz default now()
);

-- Indici per performance
create index if not exists idx_customers_email on customers(email);
create index if not exists idx_logs_status on automation_logs(status);
create index if not exists idx_logs_created_at on automation_logs(created_at desc);
