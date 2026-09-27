# Sarjan Jewels | Enterprise AI Automation + CRM + Order & Workflow SaaS Platform

A multi-tenant business automation platform optimized for luxury jewelry businesses, combining WhatsApp automation, AI intent classification, bespoke order tracking, simultaneous capacity balancing, and role-based operations.

---

## 🏛️ System Architecture

```text
                   +------------------------------------+
                   |     React + TypeScript Frontend    |
                   |   (Tailwind CSS + Framer Motion)   |
                   +-----------------+------------------+
                                     |
                                     v
                   +------------------------------------+
                   |           FastAPI Backend          |
                   |       (Python 3.13 + Pydantic)     |
                   +-----------------+------------------+
                                     |
                                     v
                   +------------------------------------+
                   |       Supabase Cloud / Postgres    |
                   |  - 28+ Normalized Tables           |
                   |  - Row Level Security (RLS)        |
                   |  - Auth & RBAC                     |
                   |  - Realtime & Storage              |
                   +------------------------------------+
```

---

## 📁 Repository Structure

```text
customber-system-/
├── backend/                        # FastAPI application
│   ├── app/
│   │   ├── api/v1/                 # Modular API routers
│   │   │   ├── auth.py             # Authentication & role simulator
│   │   │   ├── companies.py        # Multi-tenant company context
│   │   │   ├── customers.py        # CRM customer profiles & tiers
│   │   │   ├── orders.py           # Bespoke orders & workflow states
│   │   │   ├── approvals.py        # Simultaneous capacity approval engine
│   │   │   ├── capacity.py         # Bench capacity metrics
│   │   │   ├── tracking.py         # Public tracking token verification (/track)
│   │   │   ├── tasks.py            # Departmental workflow tasks
│   │   │   ├── audit.py            # Immutable compliance audit trail
│   │   │   └── health.py           # Live Supabase diagnostic endpoint
│   │   ├── core/
│   │   │   ├── config.py           # Pydantic v2 settings & env vars
│   │   │   ├── database.py         # Supabase client manager & pre-seeded store
│   │   │   ├── security.py         # JWT tokens & RBAC permissions
│   │   │   ├── errors.py           # Standardized JSON error handlers
│   │   │   └── logging.py          # Structured logging
│   │   ├── models/
│   │   │   └── schemas.py          # Pydantic validation models
│   │   └── main.py                 # FastAPI application & middleware
│   ├── tests/
│   │   └── test_api.py             # Integration test suite (pytest)
│   ├── requirements.txt            # Python dependencies
│   ├── .env.example
│   └── .env
│
├── frontend/                       # React 18 + TypeScript + Vite
│   ├── src/
│   │   ├── components/
│   │   │   ├── Sidebar.tsx         # Multi-tenant nav & RBAC simulator
│   │   │   └── Header.tsx          # Status indicators & global search
│   │   ├── pages/
│   │   │   ├── AdminDashboard.tsx  # Executive Hub & Simultaneous Approval Queue
│   │   │   ├── CustomerTracking.tsx# Public Customer Tracking Portal (/track)
│   │   │   ├── CustomersPage.tsx   # CRM directory with VIP tiers
│   │   │   └── SystemHealth.tsx    # Supabase architecture inspector
│   │   ├── lib/
│   │   │   ├── api.ts              # Typed API client
│   │   │   └── supabaseClient.ts   # Supabase browser SDK
│   │   ├── types/                  # TypeScript domain interfaces
│   │   ├── App.tsx                 # Main layout & router state
│   │   └── index.css               # Luxury theme & glassmorphic tokens
│   ├── package.json
│   ├── tailwind.config.js
│   └── vite.config.ts
│
└── supabase/
    └── migrations/
        ├── 20260928000001_initial_schema.sql # 28+ core tables, foreign keys, indexes
        ├── 20260928000002_rls_policies.sql   # Multi-tenant RLS & RBAC policies
        └── 20260928000003_seed_data.sql      # Sarjan Fine Jewels demo dataset
```

---

## 🚀 Quickstart Guide

### 1. Backend (FastAPI)
```bash
cd backend
python -m pip install -r requirements.txt
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
```
- API Docs: `http://localhost:8000/docs`
- Health check: `http://localhost:8000/api/v1/health`

### 2. Frontend (React + Vite)
```bash
cd frontend
npm install
npm run dev
```
- Web Application: `http://localhost:5173`

---

## 🧪 Automated Testing
Run integration tests covering health, customers, orders, capacity conflicts, and customer token verification:
```bash
cd backend
python -m pytest tests/test_api.py -v
```

---

## 💎 Phase 1 Verification Summary
- **Multi-Tenant Database**: 28+ tables, foreign keys, updated_at triggers, and indexes.
- **Row Level Security**: Isolated company tenant context (`company_id`) and customer tracking token validation.
- **Simultaneous Order Approval Queue (§24 & §25)**: Evaluates bench capacity constraints (e.g. Order A consumes 50 units; Order B requires 50 units with 0 remaining, triggering approval hold or split batching).
- **Public Customer Tracking Portal (/track)**: Token verification (`SARJAN-2026-8F42`) rendering a 9-stage luxury timeline.
- **RBAC Simulation**: Interactive role switcher (Admin, Manager, Team Member, Customer) for permission testing.
- **Zero Mock UI / Real API**: All actions trigger live FastAPI endpoints with compliance audit logging.
