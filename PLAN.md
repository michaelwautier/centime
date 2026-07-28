# Centime — Income & Expense Tracker (Rails 8 + Hotwire Native + Kamal)

## Context

Greenfield build of a personal finance app: track categorized income/expenses on web and mobile (Hotwire Native iOS + Android), with automatic bank sync (GoCardless Bank Account Data, EU/PSD2 — 1 connection free, multiple = paid Pro plan via Stripe/Pay), an Avo admin dashboard, and a self-learning category suggester. Clean code, RSpec, GitHub Actions CI, Kamal 2 deploy to a single VPS.

**Locked decisions**: Rails 8.x / Ruby 4.0.5, PostgreSQL, Devise, RSpec, GoCardless (EU), Stripe via `pay` gem, Avo admin, single user per account, single VPS with Postgres as Kamal accessory, rules + naive Bayes categorizer (pure Ruby).

**Recommended defaults**: importmap (no Node build), tailwindcss-rails, integer `amount_cents` (signed; negative = expense) — no money-rails, Cuprite for system specs, rubocop-rails-omakase, Chartkick + Chart.js for charts, Solid Queue/Cache/Cable (no Redis).

The app is named **Centime**, living at `/Users/michael/projects/centime` (new repo). Mobile shells later as `centime-ios` / `centime-android`.

## Gem policy — latest versions, minimal set

**Latest versions**: no version pins in the Gemfile (except the `ruby "4.0.5"` line); every gem is added with `bundle add <gem>` at implementation time so Bundler resolves the newest release, and `bundle outdated` must be clean at each phase start. Enable Dependabot (`.github/dependabot.yml`, weekly, bundler + github-actions ecosystems) so we stay current after launch.

**Every gem earns its place** — the full list and why, everything else is deliberately excluded:

| Gem | Justification |
|---|---|
| rails, pg, puma, propshaft, importmap-rails, turbo-rails, stimulus-rails, tailwindcss-rails, solid_queue/cache/cable, kamal, thruster, bootsnap | Rails 8 defaults; the Solid stack removes any Redis dependency |
| devise | required by spec (auth) |
| pay + stripe | required by spec (billing); `stripe` is Pay's required adapter |
| avo | required by spec (admin) |
| hotwire-native-rails | path-configuration helpers + `hotwire_native_app?`; small and saves hand-rolling |
| chartkick | one-line charts over Chart.js (pinned via importmap, not a gem); the alternative is a custom Stimulus/Chart.js controller — revisit if we outgrow it |
| rspec-rails, factory_bot_rails, capybara, cuprite | test stack core |
| shoulda-matchers | keeps model specs one-liners; cheap, test-only |
| webmock | required to spec the GoCardless client without network |
| simplecov | coverage signal in CI; test-only |
| brakeman, rubocop-rails-omakase | ship with Rails 8; CI security + lint |

**Deliberately NOT used**: `faraday`/`httparty` (GoCardless client is ~6 endpoints — plain `Net::HTTP` wrapper, zero deps), `faker` (factory sequences + literals suffice), `money-rails` (signed integer cents + a formatting helper), `nordigen-ruby` (stale), `classifier-reborn` (naive Bayes is ~100 lines of pure Ruby we fully control), `redis`/`sidekiq` (Solid stack), `devise-jwt` or API auth gems (cookie sessions work in Hotwire Native webviews), `administrate` (Avo chosen), `kaminari`/`pagy` initially (simple `limit/offset` month-scoped lists; add `pagy` only if lists demand it).

## Domain model (target schema)

```
users                 Devise cols + name, currency(3) default EUR, time_zone, admin:boolean
categories            user_id (null = system default), name, kind enum(income|expense), color, archived_at
                      unique [user_id, name, kind]
bank_connections      user_id, institution_id/name/logo_url, requisition_id (uniq), reference (uniq UUID),
                      status enum(pending|linked|expiring|expired|revoked|paused|error),
                      consent_expires_at, last_synced_at, last_sync_error, last_manual_sync_on
bank_accounts         bank_connection_id, gocardless_account_id (uniq), name, iban_last4, currency,
                      balance_cents, balance_refreshed_at, status
transactions          user_id, bank_account_id (null = manual), category_id (nullable),
                      amount_cents (signed, not null), currency, booked_on:date, description, merchant_name,
                      external_id (GoCardless id), source enum(manual|bank_sync),
                      categorization_source enum(manual|rule|merchant|bayes|none), pending:boolean
                      unique [bank_account_id, external_id] where external_id IS NOT NULL; index [user_id, booked_on]
categorization_rules  user_id, category_id, matcher_type enum(contains|equals), pattern, position
merchant_category_mappings  user_id, merchant_key, category_id, hit_count — unique [user_id, merchant_key]
bayes_tokens          user_id, category_id, token, count — unique [user_id, category_id, token]
bayes_category_stats  user_id, category_id, document_count — unique [user_id, category_id]
pay_*                 from pay gem; solid_queue_*/cache_*/cable_* via Rails 8 multi-DB database.yml
```

## Phase 0 — Skeleton, tooling, CI

- `rails new centime --database=postgresql --css=tailwind` (Rails 8: importmap, Solid stack, Kamal + Thruster, Brakeman, rubocop-rails-omakase included).
- Ruby pinned to **4.0.5** everywhere it's declared: `.ruby-version`, `Gemfile`, Dockerfile base image (`ruby:4.0.5-slim`), and `ruby-version` in the CI workflow. Verify all gems (notably Devise, Avo, Pay) install cleanly on 4.0 before feature work starts.
- Replace Minitest with RSpec: `rspec-rails`, `factory_bot_rails`, `shoulda-matchers`, `simplecov`, `capybara`, `cuprite`, `webmock` — all via `bundle add` (latest). Configure Cuprite driver in `spec/support/capybara.rb`.
- `.github/dependabot.yml` (weekly, bundler + github-actions).
- `.github/workflows/ci.yml`: jobs `lint` (rubocop), `security` (brakeman, `bin/importmap audit`), `test` (Postgres service, `db:schema:load`, rspec with Chrome via `browser-actions/setup-chrome`).
- Seeds: system default categories (user_id nil) — Salary, Freelance, Interest (income); Groceries, Rent, Utilities, Transport, Dining, Health, Entertainment, Shopping, Fees, Other (expense).
- **Kick off external lead-time items now**: GoCardless account (approval can take days), Stripe test account, Apple Developer enrollment, Google Play account (new accounts need a 14-day closed test with 12+ testers), VPS + domain.

Specs: smoke system spec; CI green on first PR.

## Phase 1 — Devise auth + manual tracking MVP

- Devise `User` (database_authenticatable, registerable, recoverable, rememberable, validatable). Root → `dashboards#show` behind `authenticate_user!`.
- `Categories::ProvisionDefaults.call(user:)` copies system categories on signup (invoked from a Devise `RegistrationsController` subclass).
- Models: `Category` (kind enum, income/expense scopes), `Transaction` (validations, `in_month` scope, formatting helpers).
- `TransactionForm` (ActiveModel PORO): positive decimal amount + income/expense toggle → signed `amount_cents`. Thin `TransactionsController` CRUD.
- Routes: `resources :transactions`, `resources :categories`, `resource :dashboard, only: :show`.
- Dashboard v1: current-month income/expense/net, Chartkick pie (category breakdown) + 6-month column chart. Query object `Reports::MonthlySummary` (grouped SQL, PORO in `app/queries/`).
- Transactions index: month filter (Turbo Frame) + **inline category select PATCHing via Turbo** — this UI is the future learning feedback loop.
- **First Kamal deploy at end of this phase** (hello-world prod) so infra surprises surface early.

Specs: model + form unit specs, request specs for CRUD, system specs (sign up → add expense → see dashboard), `MonthlySummary` spec.

## Phase 2 — GoCardless bank sync

No new gems — hand-rolled client on plain `Net::HTTP` (the API is ~6 REST endpoints; the official `nordigen-ruby` gem is stale).

- `app/services/go_cardless/client.rb`: token lifecycle (access token cached in Solid Cache), `institutions(country:)`, `create_end_user_agreement`, `create_requisition`, `requisition(id)`, `account_details/balances/transactions`. Typed errors: `RateLimitedError`, `ConsentExpiredError`.
- Consent flow: `resources :bank_connections, only: [:index, :new, :create, :destroy]` + `get "bank_connections/callback"`.
  - `new`: institution picker (cached 24h).
  - `create`: `BankConnections::InitiateRequisition` — local pending record with UUID reference, EUA (90 days historical + validity), requisition with callback redirect, then redirect user to bank.
  - callback: `BankConnections::CompleteRequisition` — fetch requisition, create `BankAccount` rows, status linked, set `consent_expires_at`, enqueue first sync.
- Sync: `BankAccountSyncJob` → `BankAccounts::SyncTransactions.call(account)`:
  - fetch since `[last_synced_at - 5.days, 90.days.ago].max` (overlap catches pending→booked flips),
  - `GoCardless::TransactionMapper` (defensive — payloads vary per bank; decimal → cents at this boundary),
  - **insert-only dedup**: `insert_all(unique_by: [:bank_account_id, :external_id])` ignoring conflicts, second pass updates only `pending` — NEVER overwrite `category_id` on re-sync,
  - run new rows through the categorizer (no-op until Phase 4), update balances.
- `DailyBankSyncJob` via Solid Queue recurring task (`config/recurring.yml`, 06:15). **Rate limit: 4 calls/day/account** → one auto sync + max one manual "Sync now" per account per day (guard via `last_manual_sync_on`, disable button when spent). On 429: record `last_sync_error`, don't retry same day.
- Consent renewal: daily `ConsentExpiryCheckJob` flags connections expiring <7 days → banner + `ConsentMailer`. Renewal reruns the requisition flow and re-points existing `bank_accounts` by `gocardless_account_id` (history preserved).
- Dev/test against sandbox institution `SANDBOXFINANCE_SFIN0000`. Secrets: `GOCARDLESS_SECRET_ID/KEY`.

Specs: client specs with WebMock; `SyncTransactions` idempotency spec (run twice, no dupes, categories preserved); requisition flow request specs; system spec with stubbed client.

## Phase 3 — Billing (Pay + Stripe), free/paid gating

Add `pay`, `stripe`. One product: **Pro** monthly (`STRIPE_PRO_PRICE_ID`).

- `pay:install:migrations`; `User` → `pay_customer`.
- Routes: `resource :subscription` (show/new), `post subscription/checkout` (Stripe Checkout via Pay), success page, billing portal link. Pay mounts `/pay/webhooks/stripe` (dev: `stripe listen --forward-to`).
- Gating PORO `Entitlements`: `max_bank_connections` = 1 free / unlimited Pro (`payment_processor.subscribed?`). Enforced in `BankConnections::InitiateRequisition` (raises `LimitReached`) and in UI (upsell partial replaces "Add bank").
- Downgrade (`subscription.deleted` webhook → `Billing::HandleDowngrade`): surplus connections become `status: :paused` (skipped by daily sync), user picks the keeper. Never delete data.

Specs: `Entitlements` unit specs (free/pro/grace), request spec refusing 2nd connection for free users, downgrade handler spec, upsell system spec.

## Phase 4 — Categorization engine + learning loop

Pure Ruby in `app/services/categorization/` — no gems, no external ML.

- `Categorization::Engine.call(transaction)` → `Result(category, source, confidence)`, pipeline (first hit wins):
  1. `RuleMatcher` — user rules by position, contains/equals on merchant/description.
  2. `MerchantMatcher` — `MerchantKey.for(txn)` (downcase, strip digits/store numbers, squish) → `merchant_category_mappings` lookup.
  3. `BayesClassifier` — multinomial naive Bayes + Laplace smoothing over merchant+description tokens, counts from `bayes_tokens`/`bayes_category_stats`. Accept only if user has ≥10 trained docs AND log-prob margin over runner-up exceeds threshold; else fall through. Memoize corpus per sync run for batching.
  4. Nothing → `categorization_source: :none`.
- Runs inside `SyncTransactions` for new rows (batch, corpus loaded once). Manual entries skip suggestion but feed training.
- **Train on write, not on schedule**: any category set/change fires `CategorizationLearnJob` → `Categorization::LearnFromCorrection` — upserts merchant mapping (+decrements the old wrong one), increments/decrements bayes token + doc counts. The "model" is just count tables; no retraining pass.
- UI: auto-categorized rows show an "auto" badge + inline select (changing = correction). "Review" filter for uncategorized rows with one-click suggested chips (top Bayes guess labeled "Suggested"). "Always do this" checkbox in correction UI creates a `categorization_rule`. `resources :categorization_rules` CRUD.

Specs (heaviest unit coverage of the app): table-driven `MerchantKey` spec; `BayesClassifier` spec with hand-built corpus incl. threshold fall-through; `Engine` precedence spec (rule > merchant > bayes); `LearnFromCorrection` count-movement spec; integration spec: train, sync 10 stubbed transactions, assert categories.

## Phase 5 — Reports + Avo admin

- `resource :reports, only: :show` with `?month=`: 12-month income vs expense trend, category breakdown with Turbo Frame drill-down, CSV export. Query objects in `app/queries/`; aggregates cached in Solid Cache keyed on `transactions.maximum(:updated_at)`.
- Avo mounted at `/avo`, authorized by `current_user.admin?`. Resources: User (with subscription panel), Category, Transaction (read-mostly), BankConnection (status, last_synced_at, last_sync_error, consent_expires_at + error/expired filter = sync-health view), Pay::Subscription. Dashboard card: connections in error, syncs >48h stale. (Avo Community is free; custom cards may need Pro — check when we get there.)

Specs: `/avo` authorization request specs, report query specs, CSV spec.

## Phase 6 — Hotwire Native (iOS + Android)

Rails side first (`hotwire-native-rails` gem):
- Path-configuration JSON endpoints (`/configurations/ios`, `/configurations/android`): modals for `/transactions/new`, `/categories/new`; pull-to-refresh on dashboard/transactions; **external browser rules for GoCardless consent and Stripe Checkout** (must not run in webview) with universal/deep links back to `bank_connections/callback`.
- Native tab bar: Dashboard, Transactions, Reports, Settings — each rooted at its Rails URL.
- Auth: Devise cookie sessions work in the webview as-is; long `remember_for`, `SameSite=Lax`; hide web nav chrome when `hotwire_native_app?`.
- Bridge components where valuable: form bridge (native submit in nav bar for transaction form), button bridge for "Sync now".

Shell projects (separate repos, thin — target <500 lines each): `centime-ios` (Swift, HotwireNative SPM, TabBar + Navigator per tab), `centime-android` (Kotlin, hotwire-native-android, HotwireActivity + bottom nav).

Specs: path-config endpoint request specs; system spec for native-variant layout.

## Phase 7 — Kamal deploy + hardening (first deploy already done in Phase 1)

- `config/deploy.yml`: single server; `proxy: { ssl: true, host: ... }` (kamal-proxy + Let's Encrypt); Thruster in Dockerfile CMD; accessory `postgres:17` with volume, port bound to localhost. Secrets via `.kamal/secrets` (env or 1Password adapter): `RAILS_MASTER_KEY`, `POSTGRES_PASSWORD`, `GOCARDLESS_SECRET_ID/KEY`, `STRIPE_PRIVATE_KEY`, `STRIPE_SIGNING_SECRET`.
- Solid Queue in-process (`SOLID_QUEUE_IN_PUMA=true`) — split into a job role only if sync load demands it. Recurring tasks from `config/recurring.yml`.
- Hardening backlog: rack-attack on Devise endpoints, `force_ssl`, Sentry, uptime check on `/up`, nightly `pg_dump` cron on the VPS, 404/500 pages, empty states, onboarding checklist.
- Deploys manual (`kamal deploy`) initially; optional GH Action CD later.

## Key risks & ordering constraints

1. **External lead times start in Phase 0**: GoCardless approval (days), Google Play 14-day closed test, Apple Developer enrollment.
2. **Re-sync must never overwrite user categorization** (insert-only upsert) or it fights the learning loop.
3. **GoCardless 4 calls/day/account** shapes sync UX: daily auto + one manual sync; don't promise real-time freshness.
4. **90-day consent expiry is a product feature**: renewal banner + email must ship with bank sync, not after.
5. **Bank/Stripe redirects must leave the webview** in Hotwire Native — test on real devices early.
6. **Apple 4.2 (minimum functionality) risk** for wrapper apps — native tabs + bridge components are the mitigation; budget one rejection cycle.

## Verification

- Every phase: `bundle exec rspec` green, RuboCop clean, Brakeman clean; CI enforces all three on PRs.
- Phase 2: idempotency spec + manual run against GoCardless sandbox (`SANDBOXFINANCE_SFIN0000`) end-to-end: link → callback → transactions appear.
- Phase 3: `stripe listen` + test-mode Checkout: subscribe → 2nd bank allowed; cancel → downgrade pauses surplus connection.
- Phase 4: seed corrections, re-run sync, confirm suggestions with "auto" badge; correct one, confirm next similar transaction gets the corrected category.
- Phase 6: real-device test of bank consent + Stripe Checkout leaving/returning to the app.
- Phase 7: `kamal deploy`, check `/up`, SSL, recurring sync fires, `pg_dump` restore drill once.
