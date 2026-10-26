# Outbound floor dashboard (B2C · NewCairo)

Live outbound dashboard for the NewCairo fulfillment hub, B2C orders only. Source table: `bosta_fulfillment.omniful_orders` (Metabase database 11, Redshift).

## Contents

- `page/index.html` – the Claude dashboard page (tabs: Today live, Yesterday / any day, Trends per day · week · month).
- `sql/` – the live queries behind the Claude dashboard. `{{day}}` is the selected day, NULL means today (Cairo time).
- `metabase/` – the SQL behind the Metabase dashboards:
  - Live: https://metabase.bosta.co/dashboard/95
  - Yesterday: https://metabase.bosta.co/dashboard/96
  - Trends: https://metabase.bosta.co/dashboard/97 (per-day, per-week and per-month versions of `sql/totals.sql`)

## Business rules

- **COT (cut-off):** orders created before 17:00 must ship the same day; after 17:00 they are due the next day. Cancelled orders are excluded.
- **Breach:** due and shipped after the deadline, or not shipped once the deadline has passed.
- **IPP:** units ÷ user-hours (each person counted once per hour they scanned). Targets: pick 70, pack 90 units per hour; 8-hour shift.
- **Weeks:** Saturday to Friday.

## Datasets

| File | What it is |
|---|---|
| `sql/aging_live.sql` | Open-order aging (live) |
| `sql/cycle.sql` | Step times on the day |
| `sql/flow.sql` | Order flow and cut-off |
| `sql/hourly.sql` | Picked, packed, shipped by hour |
| `sql/people.sql` | Scans by user and hour |
| `sql/sellers.sql` | Pending orders per seller |
| `sql/totals.sql` | Totals per day, week, month |
