# Centime

Personal income & expense tracker: web + mobile (Hotwire Native), automatic
bank sync via GoCardless Bank Account Data (EU/PSD2), self-learning
category suggestions, and a Pro plan (Stripe) for multiple bank connections.

Rails 8.1 · Ruby 4.0.5 · PostgreSQL · Hotwire · Solid Queue/Cache/Cable (no
Redis) · Devise · Pay/Stripe · Avo admin · Kamal 2 deploy.

## Development

```sh
bin/setup            # bundle, db:prepare, seeds (system categories)
bin/dev              # Puma + Tailwind watcher on http://localhost:3000
```

Environment (only needed for the features you're touching):

| Variable | Used for |
|---|---|
| `GOCARDLESS_SECRET_ID` / `GOCARDLESS_SECRET_KEY` | bank sync (use the sandbox institution `SANDBOXFINANCE_SFIN0000`) |
| `STRIPE_PUBLIC_KEY` / `STRIPE_PRIVATE_KEY` / `STRIPE_SIGNING_SECRET` | billing (test mode; `stripe listen --forward-to localhost:3000/pay/webhooks/stripe`) |
| `STRIPE_PRO_PRICE_ID` | the Pro monthly price |

## Tests & checks

```sh
bundle exec rspec    # full suite incl. real-browser system specs (Cuprite)
bin/rubocop          # rails-omakase style
bin/brakeman         # static security analysis
```

System specs need a Chromium binary — Chrome or Brave is picked up
automatically, or set `BROWSER_PATH`.

## Architecture notes

- Amounts are signed integer cents on `transactions.amount_cents`
  (negative = expense). No money gem.
- Bank sync is insert-only on `[bank_account_id, external_id]` — re-syncs
  never overwrite user categorization (see `BankAccounts::SyncTransactions`).
- Category suggestions: `Categorization::Engine` runs rules → learned
  merchant mappings → naive Bayes (pure Ruby, per-user counts, trained on
  every correction via `Categorization::LearnFromCorrection`).
- GoCardless free tier allows 4 API calls/day/account: one scheduled sync
  (`config/recurring.yml`) plus at most one manual sync per day.
- Admin at `/avo` (users with `admin: true` only).
- Mobile shells: see `docs/mobile-shells.md`.

## Deployment (Kamal 2)

Single VPS; Postgres runs as a Kamal accessory, Solid Queue inside Puma.

```sh
export CENTIME_SERVER_IP=1.2.3.4 CENTIME_HOST=app.example.com \
       KAMAL_REGISTRY_USER=you KAMAL_REGISTRY_PASSWORD=... \
       CENTIME_DATABASE_PASSWORD=... GOCARDLESS_SECRET_ID=... \
       GOCARDLESS_SECRET_KEY=... STRIPE_PRIVATE_KEY=... \
       STRIPE_SIGNING_SECRET=... STRIPE_PRO_PRICE_ID=...

kamal setup          # first time: provisions accessory + app + SSL
kamal deploy         # every release
kamal console        # rails console on the server
```

SSL is terminated by kamal-proxy (Let's Encrypt) — `force_ssl` is on.
Remember a nightly `pg_dump` cron on the VPS; the accessory volume is not a
backup.
