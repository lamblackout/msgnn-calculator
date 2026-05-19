# Архитектурный план: MSG Закупки v2 (доработка 2026.05)

**Дата плана**: 2026-05-18
**Версия**: 2.0 (после внутреннего ревью и ответов от заказчика)
**Источник требований**: `ТЗ_доработка_v2.md`
**Заказчик**: Катя (МеталлСтройГрупп)
**Разработчик**: 1 человек (Миша), ~5 ч/день
**Тип проекта**: **доработка**, не «переписать с нуля». Парсер чермета, calculator.browser.js (формулы расчёта), Resend, IMAP-механизм через request_id, n8n workflows — сохраняются. Меняется UI-слой, auth, расширяется БД, переезжает инфра.

## Решения зафиксированы

| Развилка | Решение |
|---|---|
| Стек фронта | **SvelteKit 5 (runes)** |
| Стратегия миграции | **Параллельная (2 URL)**: старый сайт остаётся на GitHub Pages под hardcoded auth, новый — на app.msg.example.ru |
| Hotfix этап 0 | Параллельно в обе системы (фиксы пишутся 1 раз → коммит в старый index.html → переезжают в новый calculator/) |
| CI/CD | **GitHub Actions** + SSH auto-deploy на Beget VPS |
| Удаление поставщиков | **Только admin** |
| Создание `supplier_groups` | **Любой менеджер** (можно ужесточить позже) |
| Исторические заявки `user_id=NULL` | **Игнорируем**. Новая система = новая история |
| Email первого admin'а | `blackoutlamb@gmail.com` |
| С245/С345 | Русские С, ГОСТ 27772, плотность 7.85. **TODO**: уточнить с Катей точные значения характеристик |
| Yandex `mailbox_uid` | **TODO в этапе 1**: получить через Playwright (зайти в `zakup@msgnn.ru` в Яндекс.Почте). Не блокер на старт |
| Парсинг «ножей» | Удалено из плана (нет конкретного примера) |
| Старый сайт в параллельный период | **Не трогаем**. Продолжает работать на `msg/Zakupki2024!#`. После переключения DNS на новый — отключаем |

---

## 🚦 Status трекинг этапов

**Правило для Claude:** в конце каждого чата, когда этап (или часть этапа) завершён и закоммичен в main — обновить этот блок. Поставить ✅, дату завершения (формат `YYYY-MM-DD`), краткий итог (1 строка). Это единственный источник правды о прогрессе.

**Текущий этап**: 0c (в работе — ~40% выполнено, осталось T0.11-T0.13 hardening + T0.16-T0.20 deploy)

| Этап | Статус | Дата завершения | Итог / комментарий |
|---|---|---|---|
| 0a — Hotfix старой системы (швеллер гнутый, С245/С345, синонимы труб) | ⏭️ Postponed (2026-05-18) | — | **Отложено**. Hotfix-ы не критичны для запуска новой системы. Пользователь скинет Кате скриншот с 23met по проблемной марке стали — после её ответа задачи разнесём по отдельным фиксам. Подробности — §17 «Отложенные hotfix-ы». |
| 0b — Ramp-up SvelteKit | ⏭️ Skipped (2026-05-18) | — | Пользователь не проходит туториал, полагается на Claude (vibe-coding режим) |
| 0c — VPS setup + миграция n8n с Railway | 🟡 In progress (~40%, 2026-05-19) | — | **T0.10, T0.14, T0.15 выполнены**: куплен Beget VPS msg-prod (2/4/40 NVMe, IP 95.214.63.15, Docker preinstalled, 1500₽ пополнено), куплен домен msgzakupki.ru (199₽), DNS apex+app+n8n→VPS, инфра-файлы (docker-compose+Caddyfile+backup-n8n+README) написаны и закоммичены после code-review. **Осталось**: T0.11-T0.13 hardening VPS, T0.16-T0.20 deploy + миграция n8n с Railway + бэкапы + мониторинг. Аккаунт на ООО МСГ (юрлицо). Подробности в [infra/README.md](../../infra/README.md) и [memory/infra_beget_vps.md]. |
| 0d — SvelteKit scaffold + перенос calculator.browser.js | ⬜ Not started | — | — |
| 0e — Foundation документация (ADRs, runbook) | ⬜ Not started | — | — |
| 1 — Supabase Auth + личный кабинет (T1.1-T1.10) | ⬜ Not started | — | — |
| 1 — Auth продолжение (T1.11-T1.18) | ⬜ Not started | — | — |
| 2 — База поставщиков (T2.1-T2.5) | ⬜ Not started | — | — |
| 2 — Поставщики продолжение (T2.6-T2.9) | ⬜ Not started | — | — |
| 3 — Чермет: layout + парсинг + таблица (T3.1-T3.7) | ⬜ Not started | — | — |
| 3 — Чермет: рассылка + Realtime (T3.8-T3.12) | ⬜ Not started | — | — |
| 3 — Чермет: ссылки, проблема, звёздочки (T3.13-T3.16) | ⬜ Not started | — | — |
| 3 — Чермет: открытая заявка, Excel, сверка (T3.17-T3.20) | ⬜ Not started | — | — |
| 4 — Уторговывание: send-request переделка + Discount (T4.1-T4.6) | ⬜ Not started | — | — |
| 4 — Уведомления + IMAP обновления (T4.7-T4.12) | ⬜ Not started | — | — |
| 5 — Нержа: n8n workflows + layout (T5.1-T5.4) | ⬜ Not started | — | — |
| 5 — Нержа: парсинг + Excel + рассылка (T5.5-T5.10) | ⬜ Not started | — | — |
| 6 — Финализация миграции + sign-off | ⬜ Not started | — | — |
| 7 — (опц.) Парсер цен МС.ру/23мет | ⬜ Not started | — | Решение к концу этапа 3 |
| 8 — (опц.) Тёмная тема | ⬜ Not started | — | — |

**Условные обозначения:**
- ⬜ Not started — не начато
- 🟡 In progress — в работе (Claude обновляет на 🟡 в начале чата)
- ✅ Completed — завершено и закоммичено в main
- ⏭️ Skipped — пропущено по решению пользователя
- 🔴 Blocked — заблокировано (с указанием причины в комментарии)

**Алгоритм работы с этим блоком:**
1. В начале чата Claude смотрит этот блок и определяет следующий этап (первый ⬜ или 🟡)
2. Объявляет пользователю: «следующий этап — X, задачи T_X.A-T_X.B». Меняет статус на 🟡
3. По ходу работы — обычный workflow (TodoWrite, /feature-dev и т.д.)
4. Перед финальным push в main — Claude САМ запускает локальный code review через subagent `feature-dev:code-reviewer` (см. правило в CLAUDE.md). Раньше было правило про `/ultrareview`, но плагин недоступен в среде — заменили на локальный аналог 2026-05-19.
5. После успешного коммита и push в main — обновить статус на ✅, дату, короткий итог (1 строка)
6. Если по ходу появились ⚠️ важные открытия — записать в memory через memory system

---

## 1. Контекст

Production b2b-калькулятор металлопроката для МеталлСтройГрупп. Текущая система: 3979 строк vanilla JS + 2174 строки calculator.browser.js, hardcoded auth, 7 n8n workflows на Railway, Supabase Cloud. Полгода назад сдана и оплачена за 423 тыс. ₽.

Заказчик хочет вторую итерацию: многопользовательскую систему с ролями admin/manager, общей базой поставщиков (CRUD), историей запросов per-user, уторговыванием («Запрос на скидку»), напоминаниями, разделом нержи/цветмета без калькулятора, редизайном UI и переездом на свой VPS под NDA.

**Что сохраняем без переделки:**
- Парсер чермета (`Web Calculator API v4`) с GPT-4.1-mini
- `calculator.browser.js` ядро расчёта 2174 строки — переносим как `$lib/calculator/*.ts`, **формулы не переписываем**
- Механизм request_id `ЗП-YYYYMMDD-XXXXXXXXX-CAT` в темах писем
- Resend интеграция
- IMAP-приём писем через Яндекс 360
- 4 из 7 n8n workflows (Generate Excel, Get Summary, Telegram Metal Validation, СБИС → AMO CRM)

**Что меняем в корне:**
- Авторизация: hardcoded → Supabase Auth + RLS + роли
- UI: монолит → SvelteKit 5 с компонентами
- Категории поставщиков: hardcoded → таблица `suppliers` + `supplier_groups` с CRUD
- localStorage activeRequests с polling 30s → Supabase Realtime
- Хостинг: GitHub Pages + Railway → Beget VPS с Docker

---

## 2. Технологический стек

| Слой | Выбор | Версия (май 2026) |
|---|---|---|
| Frontend framework | **SvelteKit** (runes) | Svelte 5.x, SvelteKit 2.x |
| Bundler | **Vite** | 8.0 |
| Runtime | **Node** | 22 LTS |
| CSS | **Tailwind CSS** + `data-theme` | 4.x |
| Icons | **Lucide Svelte** (`lucide-svelte`) | latest |
| UI components | **bits-ui** (headless) | 1.x |
| Auth | **Supabase Auth** + `@supabase/ssr` | ssr 0.6+ |
| DB | **Supabase Postgres** (Cloud) | PG 16 |
| Realtime | **Supabase Realtime** (postgres_changes) | — |
| Email | **Resend** через Supabase SMTP | — |
| Storage | **Supabase Storage** | — |
| n8n | **n8n self-hosted** Docker + Postgres контейнер | 2.20.x |
| Reverse proxy | **Caddy** auto-SSL | 2.x |
| VPS OS | **Ubuntu** | 22.04 LTS |
| CI/CD | **GitHub Actions** + SSH deploy | — |
| State (frontend) | Svelte 5 runes в `*.svelte.ts` | — |
| Dark mode | `data-theme` attribute + CSS variables | — |
| Tests | **Vitest** (unit на calculator) + **Playwright** (e2e happy path) | latest |
| IDB для черновика | `idb-keyval` | latest |
| Package manager | **pnpm** | 9.x |

**Изменение vs v1 плана:** заменил `@tabler/icons-svelte` (5900 иконок) на `lucide-svelte` (1600). Lucide достаточно для b2b admin tool с 30-40 иконками, весит меньше, активнее поддерживается. Tabler — overkill.

---

## 3. Структура файлов нового проекта

В существующем репозитории `msgnn-calculator` (после NDA — приватный) добавляются:

```
msgnn-calculator/
├── index.html                          # СТАРОЕ — остаётся работать в параллельный период
├── calculator.browser.js               # СТАРОЕ — этап 0 hotfix применяется и сюда
├── n8n-workflows/                      # СТАРОЕ + обновляется экспорт после изменений
├── supabase/
│   ├── migrations/                     # 5 SQL файлов (см. §5)
│   └── config.toml
├── app-v2/                             # НОВЫЙ SvelteKit проект
│   ├── .env.example
│   ├── package.json
│   ├── svelte.config.js                # adapter-node
│   ├── vite.config.ts
│   ├── tailwind.config.ts
│   ├── tsconfig.json
│   ├── vitest.config.ts
│   ├── playwright.config.ts
│   ├── Dockerfile                      # multi-stage build (node-22-alpine)
│   ├── static/
│   │   ├── favicon.svg
│   │   ├── logo-msg.svg
│   │   ├── metals.json                 # build-time vendoring
│   │   └── sounds/new-response.mp3
│   ├── src/
│   │   ├── app.html
│   │   ├── app.d.ts
│   │   ├── app.css                     # Tailwind 4 + темы через CSS vars
│   │   ├── hooks.server.ts             # @supabase/ssr + auth guard
│   │   ├── hooks.client.ts
│   │   ├── lib/
│   │   │   ├── supabase/
│   │   │   │   ├── client.ts
│   │   │   │   ├── server.ts
│   │   │   │   └── types.ts            # генерим из supabase gen types
│   │   │   ├── calculator/             # перенос calculator.browser.js
│   │   │   │   ├── index.ts
│   │   │   │   ├── formulas.ts
│   │   │   │   ├── calculate-metal.ts
│   │   │   │   ├── helpers.ts
│   │   │   │   ├── constants.ts
│   │   │   │   └── __tests__/
│   │   │   │       └── formulas.test.ts
│   │   │   ├── api/
│   │   │   │   ├── n8n.ts
│   │   │   │   ├── parse.ts
│   │   │   │   ├── send-request.ts
│   │   │   │   └── excel.ts
│   │   │   ├── stores/                 # *.svelte.ts с runes
│   │   │   │   ├── theme.svelte.ts
│   │   │   │   ├── draft.svelte.ts
│   │   │   │   ├── notifications.svelte.ts
│   │   │   │   └── sidebar.svelte.ts
│   │   │   ├── realtime/
│   │   │   │   ├── responses.ts
│   │   │   │   ├── notifications.ts
│   │   │   │   └── requests-history.ts
│   │   │   ├── components/
│   │   │   │   ├── layout/ (Header, Sidebar, HistoryList, SupplierFolders, ThemeSwitcher, NotificationBell, CategoryTabs)
│   │   │   │   ├── chermet/ (OrderEditor, ParseInput, PositionsTable, PositionRow, MetalCell, SteelCell, SupplierSelector, ResponsesPanel)
│   │   │   │   ├── nerzh/ (NerzhOrderEditor, NerzhTable)
│   │   │   │   ├── suppliers/ (SupplierCard, SupplierTable, SupplierFormDialog, GroupBadge)
│   │   │   │   ├── modals/ (Dialog, ConfirmDialog, DiscountRequestDialog, ReminderDialog, AddSupplierDialog, ProblemReportDialog)
│   │   │   │   └── ui/ (Button, Input, Select, Checkbox, Spinner, Toast, Icon)
│   │   │   ├── utils/ (format, request-id, yandex-link, classnames)
│   │   │   └── server/ (auth-guard, role)
│   │   └── routes/
│   │       ├── +layout.svelte
│   │       ├── +layout.server.ts
│   │       ├── +error.svelte
│   │       ├── (public)/
│   │       │   ├── +layout.svelte
│   │       │   ├── login/+page.svelte + +page.server.ts
│   │       │   ├── reset-password/+page.svelte + +page.server.ts
│   │       │   └── reset-password/[token]/+page.svelte
│   │       ├── (app)/
│   │       │   ├── +layout.svelte
│   │       │   ├── +layout.server.ts        # auth guard, history, groups, suppliers
│   │       │   ├── chermet/+page.svelte + +page.server.ts
│   │       │   ├── chermet/[requestId]/+page.svelte + +page.server.ts
│   │       │   ├── nerzh/+page.svelte
│   │       │   ├── nerzh/[requestId]/+page.svelte
│   │       │   ├── suppliers/+page.svelte + +page.server.ts
│   │       │   ├── profile/+page.svelte + +page.server.ts
│   │       │   └── admin/users/+page.svelte + +page.server.ts (role guard)
│   │       └── api/
│   │           ├── auth/callback/+server.ts
│   │           └── healthcheck/+server.ts
│   └── e2e/
│       ├── login.spec.ts
│       ├── order-flow.spec.ts
│       └── draft-restore.spec.ts
├── infra/
│   ├── docker-compose.yml
│   ├── Caddyfile
│   ├── .env.example
│   ├── backup-n8n.sh
│   └── README.md                       # инструкция настройки VPS с нуля
├── docs/
│   ├── architecture.md                 # копия этого плана для команды
│   ├── adr/                            # Architecture Decision Records
│   │   ├── 001-svelte-vs-react.md
│   │   ├── 002-supabase-auth-rls.md
│   │   ├── 003-realtime-channels.md
│   │   └── 004-vps-vs-vercel.md
│   ├── runbook.md                      # инструкция для admin/Кати (как сменить пароль пользователю, как пересмотреть RLS, как откатиться)
│   ├── deployment.md                   # как деплоить вручную, если CI упал
│   └── troubleshooting.md              # типичные проблемы и их решения
├── CLAUDE.md                           # обновляется под новую архитектуру
├── README.md                           # обновляется
└── .github/
    └── workflows/
        ├── ci.yml
        └── deploy.yml
```

---

## 4. Frontend архитектура (SvelteKit 5)

### 4.1. State management — runes-stores

| Состояние | Где живёт | Тип | Жизненный цикл |
|---|---|---|---|
| `session`/`user`/`role` | `+layout.server.ts` data | server load | per-request |
| Активная категория | URL segment (`/chermet` vs `/nerzh`) | route | URL-driven |
| Текущий заказ (items, name, suppliers selection) | `OrderEditor.svelte` `$state` | runes local | mount |
| Черновики при переключении | `$lib/stores/draft.svelte.ts` (IndexedDB) | runes singleton | cross-route, TTL 24ч |
| История 20 запросов | `+layout.server.ts` data + Realtime invalidation | hybrid | per-session |
| Уведомления | `$lib/stores/notifications.svelte.ts` + Realtime | runes | per-session |
| Тема | `$lib/stores/theme.svelte.ts` + cookie | runes | per-user |
| Sidebar развёрнутые папки | `$lib/stores/sidebar.svelte.ts` + localStorage | runes | per-user |
| Toast-стек | `$lib/components/ui/toaster.svelte.ts` | runes singleton | app-lifetime |

### 4.2. Auth flow

`hooks.server.ts` создаёт `createServerClient` из `@supabase/ssr`, выставляет `event.locals.supabase` и `event.locals.safeGetSession()`. Последний делает `getSession()` + `getUser()` (для валидации JWT) — это каноничный паттерн SSR-доков Supabase.

`(app)/+layout.server.ts` — guard на сессию + загрузка history (20 запросов), groups, suppliers. `(app)/admin/+layout.server.ts` — дополнительный guard на роль admin.

### 4.3. Realtime подписки — 3 канала на пользователя

- `notifications:<user_id>` — глобальный в `(app)/+layout.svelte`, живёт всю сессию
- `responses:<request_id>` — локальный в `ResponsesPanel.svelte`, монтируется при открытии заявки
- `suppliers-changes` — глобальный, `invalidate('suppliers')` при изменениях

Используем `onMount`/`onDestroy` для подписок, не `$effect` (детерминированность).

### 4.4. Черновики IndexedDB через `idb-keyval`

Структура `OrderDraft = { name, category, items, selectedSupplierIds, savedAt, schemaVersion }`. Debounce 500ms на изменения. `beforeNavigate` синхронный flush. TTL 24ч.

### 4.5. Модалки — `bits-ui@1+`

Headless Dialog/Combobox/Popover, стилизуем под пастельную палитру. Не нативный `<dialog>` (z-index конфликты).

### 4.6. Тёмная тема — Tailwind 4

`data-theme` attribute + CSS variables. `@custom-variant dark` в CSS. Inline noflash script в `<head>` предотвращает FOUC.

### 4.7. Перенос `calculator.browser.js`

Из IIFE `(function(window){...})(window)` → ES modules с `export function calculateMetal()`. Файл разбивается на `formulas.ts`, `calculate-metal.ts`, `helpers.ts`, `constants.ts`. Типизация TypeScript. Перед переносом — Vitest тесты на 11 формул + 10 типовых заявок (эталон nn.23met.ru).

---

## 5. База данных

### 5.1. Миграции (4 файла, объединено для удобства rollback)

`supabase/migrations/`:

#### `20260601000001_init_auth_roles_schema.sql` (объединено: auth + extensions + helper functions)

```sql
-- Extensions
create extension if not exists "pgcrypto";
create extension if not exists "moddatetime";
create extension if not exists "citext";

-- App schema for internal helpers (not exposed to PostgREST)
create schema if not exists app;
revoke all on schema app from anon, authenticated;
grant usage on schema app to postgres, service_role;

-- JWT role reader (STABLE => Postgres кэширует на запрос)
create or replace function app.jwt_role()
returns text
language sql
stable
set search_path = ''
as $$
  select coalesce(
    current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'role',
    'manager'
  );
$$;

create or replace function app.is_admin()
returns boolean
language sql
stable
set search_path = ''
as $$
  select app.jwt_role() = 'admin';
$$;

-- Custom Access Token Hook: реальная роль из auth.users в JWT при логине
create or replace function app.custom_access_token_hook(event jsonb)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  claims jsonb;
  user_role text;
begin
  select coalesce(u.raw_app_meta_data ->> 'role', 'manager')
    into user_role
  from auth.users u
  where u.id = (event ->> 'user_id')::uuid;

  claims := event -> 'claims';
  if claims ? 'app_metadata' then
    claims := jsonb_set(claims, '{app_metadata,role}', to_jsonb(user_role));
  else
    claims := jsonb_set(claims, '{app_metadata}', jsonb_build_object('role', user_role));
  end if;
  return jsonb_set(event, '{claims}', claims);
end;
$$;

grant execute on function app.custom_access_token_hook(jsonb) to supabase_auth_admin;
revoke execute on function app.custom_access_token_hook(jsonb) from authenticated, anon, public;

-- После применения: зарегистрировать hook в Supabase Dashboard
-- Auth → Hooks → Custom Access Token → выбрать app.custom_access_token_hook
```

#### `20260601000002_schema_tables.sql` (объединено: extend + new tables)

```sql
-- 1. Расширение supplier_requests
alter table public.supplier_requests
  add column if not exists user_id uuid references auth.users(id) on delete set null,
  add column if not exists name text,
  add column if not exists category_kind text check (category_kind in ('chermet','nerzh')),
  add column if not exists is_starred boolean not null default false,
  add column if not exists is_archived boolean not null default false,
  add column if not exists updated_at timestamptz not null default now();

update public.supplier_requests set category_kind = 'chermet' where category_kind is null;
alter table public.supplier_requests alter column category_kind set not null;

create index if not exists idx_supplier_requests_user_active
  on public.supplier_requests(user_id, is_archived, created_at desc)
  where is_archived = false;
create index if not exists idx_supplier_requests_starred
  on public.supplier_requests(user_id) where is_starred = true;

drop trigger if exists trg_supplier_requests_moddatetime on public.supplier_requests;
create trigger trg_supplier_requests_moddatetime
  before update on public.supplier_requests
  for each row execute function moddatetime(updated_at);

-- 2. Расширение supplier_responses
alter table public.supplier_responses
  add column if not exists email_link text,
  add column if not exists yandex_uid text,
  add column if not exists yandex_message_uid text;

create index if not exists idx_supplier_responses_request on public.supplier_responses(request_id);

-- 3. supplier_groups
create table if not exists public.supplier_groups (
  id uuid primary key default gen_random_uuid(),
  category_kind text not null check (category_kind in ('chermet','nerzh')),
  code text not null,
  name text not null,
  emoji text,
  color text check (color ~ '^#[0-9A-Fa-f]{6}$'),
  sort_order int not null default 0,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (category_kind, code)
);
create index if not exists idx_supplier_groups_sort
  on public.supplier_groups(category_kind, sort_order, name);

drop trigger if exists trg_supplier_groups_moddatetime on public.supplier_groups;
create trigger trg_supplier_groups_moddatetime
  before update on public.supplier_groups
  for each row execute function moddatetime(updated_at);

-- 4. suppliers
create table if not exists public.suppliers (
  id uuid primary key default gen_random_uuid(),
  category_kind text not null check (category_kind in ('chermet','nerzh')),
  group_id uuid not null references public.supplier_groups(id) on delete restrict,
  company text not null,
  contact_name text,
  email citext not null,
  phone text not null,
  notes text,
  is_active boolean not null default true,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index if not exists uniq_suppliers_email_per_category
  on public.suppliers(category_kind, lower(email));
create index if not exists idx_suppliers_group on public.suppliers(group_id);
create index if not exists idx_suppliers_category
  on public.suppliers(category_kind) where is_active;

drop trigger if exists trg_suppliers_moddatetime on public.suppliers;
create trigger trg_suppliers_moddatetime
  before update on public.suppliers
  for each row execute function moddatetime(updated_at);

-- 5. sent_emails
create table if not exists public.sent_emails (
  id uuid primary key default gen_random_uuid(),
  request_id text not null references public.supplier_requests(request_id) on delete cascade,
  supplier_id uuid references public.suppliers(id) on delete set null,
  supplier_email text not null,
  email_type text not null check (email_type in ('initial','reminder','discount_request')),
  subject text,
  body text,
  attachment_url text check (attachment_url is null or attachment_url ~ '^https?://'),
  resend_message_id text,
  sent_at timestamptz not null default now(),
  sent_by uuid references auth.users(id) on delete set null
);
create index if not exists idx_sent_emails_request on public.sent_emails(request_id, sent_at desc);
create index if not exists idx_sent_emails_supplier on public.sent_emails(supplier_id);

-- 6. request_attachments
create table if not exists public.request_attachments (
  id uuid primary key default gen_random_uuid(),
  request_id text not null references public.supplier_requests(request_id) on delete cascade,
  storage_path text not null,
  original_name text,
  mime_type text,
  size_bytes bigint,
  uploaded_by uuid references auth.users(id) on delete set null,
  uploaded_at timestamptz not null default now()
);
create index if not exists idx_request_attachments_request on public.request_attachments(request_id);

-- 7. notifications
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  type text not null check (type in (
    'new_response','no_response_24h','partial_response_48h',
    'order_stale_7d','discount_response'
  )),
  title text not null,
  body text,
  request_id text references public.supplier_requests(request_id) on delete cascade,
  payload jsonb not null default '{}'::jsonb,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists idx_notifications_user_unread
  on public.notifications(user_id, created_at desc) where is_read = false;

-- 8. orphan_responses
create table if not exists public.orphan_responses (
  id uuid primary key default gen_random_uuid(),
  email_message_id text unique,
  from_email citext not null,
  subject text,
  received_at timestamptz not null default now(),
  raw_meta jsonb not null default '{}'::jsonb,
  reason text not null check (reason in (
    'no_request_id','request_not_found','unknown_supplier_email'
  )),
  resolved_at timestamptz,
  resolved_by uuid references auth.users(id),
  linked_response_id uuid references public.supplier_responses(id) on delete set null
);
create index if not exists idx_orphan_unresolved
  on public.orphan_responses(received_at desc) where resolved_at is null;

-- Seed дефолтных групп
insert into public.supplier_groups (category_kind, code, name, emoji, color, sort_order)
values
  ('chermet','nn','Нижний Новгород','🌆','#A8C8E6',1),
  ('chermet','moscow','Москва','🏛','#D4A8E6',2),
  ('chermet','factories','Заводы','🏭','#FFD3A5',3),
  ('nerzh','default','Нержа/Цветмет','🧪','#FFD3A5',1)
on conflict (category_kind, code) do nothing;
```

#### `20260601000003_triggers.sql`

```sql
-- Триггер 1: новый ответ → уведомление владельцу
create or replace function app.fn_notify_new_response()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare v_request_owner uuid;
begin
  select user_id into v_request_owner
  from public.supplier_requests where request_id = new.request_id;
  if v_request_owner is null then return new; end if;

  insert into public.notifications (user_id, type, title, body, request_id, payload)
  values (
    v_request_owner,
    'new_response',
    'Новый ответ от ' || coalesce(new.supplier_name, new.supplier_email, 'поставщика'),
    'Заказ ' || new.request_id,
    new.request_id,
    jsonb_build_object('supplier_email', new.supplier_email)
  );
  return new;
end;
$$;

drop trigger if exists trg_notify_new_response on public.supplier_responses;
create trigger trg_notify_new_response
  after insert on public.supplier_responses
  for each row execute function app.fn_notify_new_response();

-- Триггер 2: soft-archive самой старой не-избранной при >20 активных
-- Используется SELECT ... FOR UPDATE для защиты от race condition при параллельных INSERT
create or replace function app.fn_archive_old_requests()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare v_active_count int;
        v_victim_id uuid;
begin
  if new.user_id is null then return new; end if;

  -- Считаем активные заявки этого пользователя с блокировкой для serialization
  select count(*) into v_active_count
  from public.supplier_requests
  where user_id = new.user_id and is_archived = false;

  if v_active_count > 20 then
    -- Находим жертву с lock'ом
    select id into v_victim_id
    from public.supplier_requests
    where user_id = new.user_id
      and is_archived = false
      and is_starred = false
      and id <> new.id
    order by created_at asc
    limit 1
    for update skip locked;

    if v_victim_id is not null then
      update public.supplier_requests
      set is_archived = true
      where id = v_victim_id;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_archive_old_requests on public.supplier_requests;
create trigger trg_archive_old_requests
  after insert on public.supplier_requests
  for each row execute function app.fn_archive_old_requests();
```

**Изменение vs v1 плана:** добавил `FOR UPDATE SKIP LOCKED` в триггер архивации — защита от race condition при одновременных INSERT. `set search_path = ''` во всех `security definer` функциях — защита от search_path injection.

#### `20260601000004_rls_and_storage.sql`

См. §5.2 RLS политики + Storage buckets и политики.

### 5.2. RLS политики

```sql
-- supplier_requests
alter table public.supplier_requests enable row level security;
alter table public.supplier_requests force row level security;

create policy sr_select on public.supplier_requests for select to authenticated
  using (user_id = auth.uid() or app.is_admin());
create policy sr_insert on public.supplier_requests for insert to authenticated
  with check (user_id = auth.uid() or app.is_admin());
create policy sr_update on public.supplier_requests for update to authenticated
  using (user_id = auth.uid() or app.is_admin())
  with check (user_id = auth.uid() or app.is_admin());
create policy sr_delete on public.supplier_requests for delete to authenticated
  using (app.is_admin());

-- supplier_responses: SELECT для владельца заявки и admin. INSERT — service_role (n8n IMAP).
alter table public.supplier_responses enable row level security;
alter table public.supplier_responses force row level security;
create policy resp_select on public.supplier_responses for select to authenticated
  using (app.is_admin() or exists (
    select 1 from public.supplier_requests r
    where r.request_id = supplier_responses.request_id
      and (r.user_id = auth.uid() or app.is_admin())));

-- suppliers: SELECT/INSERT — все аутентифицированные. UPDATE — created_by или admin. DELETE — только admin (требование).
alter table public.suppliers enable row level security;
alter table public.suppliers force row level security;
create policy sup_select on public.suppliers for select to authenticated using (true);
create policy sup_insert on public.suppliers for insert to authenticated
  with check (auth.uid() is not null);
create policy sup_update on public.suppliers for update to authenticated
  using (created_by = auth.uid() or app.is_admin())
  with check (created_by = auth.uid() or app.is_admin());
create policy sup_delete on public.suppliers for delete to authenticated
  using (app.is_admin());

-- supplier_groups: SELECT — все. INSERT — любой авторизованный (требование). UPDATE/DELETE — admin.
alter table public.supplier_groups enable row level security;
alter table public.supplier_groups force row level security;
create policy grp_select on public.supplier_groups for select to authenticated using (true);
create policy grp_insert on public.supplier_groups for insert to authenticated
  with check (auth.uid() is not null);
create policy grp_update on public.supplier_groups for update to authenticated
  using (app.is_admin()) with check (app.is_admin());
create policy grp_delete on public.supplier_groups for delete to authenticated
  using (app.is_admin());

-- sent_emails
alter table public.sent_emails enable row level security;
alter table public.sent_emails force row level security;
create policy se_select on public.sent_emails for select to authenticated using (true);
create policy se_update_admin on public.sent_emails for update to authenticated
  using (app.is_admin()) with check (app.is_admin());
create policy se_delete_admin on public.sent_emails for delete to authenticated
  using (app.is_admin());

-- request_attachments
alter table public.request_attachments enable row level security;
alter table public.request_attachments force row level security;
create policy ra_select on public.request_attachments for select to authenticated
  using (exists (select 1 from public.supplier_requests r
                 where r.request_id = request_attachments.request_id
                   and (r.user_id = auth.uid() or app.is_admin())));
create policy ra_insert on public.request_attachments for insert to authenticated
  with check (uploaded_by = auth.uid() and exists (
    select 1 from public.supplier_requests r
    where r.request_id = request_attachments.request_id
      and (r.user_id = auth.uid() or app.is_admin())));
create policy ra_delete on public.request_attachments for delete to authenticated
  using (uploaded_by = auth.uid() or app.is_admin());

-- notifications
alter table public.notifications enable row level security;
alter table public.notifications force row level security;
create policy n_select on public.notifications for select to authenticated
  using (user_id = auth.uid());
create policy n_update on public.notifications for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy n_delete on public.notifications for delete to authenticated
  using (user_id = auth.uid());

-- orphan_responses: только admin
alter table public.orphan_responses enable row level security;
alter table public.orphan_responses force row level security;
create policy or_admin_all on public.orphan_responses for all to authenticated
  using (app.is_admin()) with check (app.is_admin());

-- metal_types
alter table public.metal_types enable row level security;
create policy mt_select on public.metal_types for select to authenticated using (true);
create policy mt_admin_all on public.metal_types for all to authenticated
  using (app.is_admin()) with check (app.is_admin());
```

### 5.3. Storage buckets и политики

```sql
-- Bucket request-attachments: для «Запрос на скидку», прикреплений
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'request-attachments', 'request-attachments', false, 20 * 1024 * 1024,
  array['application/pdf','image/jpeg','image/png','image/webp',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'application/vnd.ms-excel']
) on conflict (id) do nothing;

-- Bucket parser-uploads: временное хранилище для загруженных на парсинг файлов (TTL 7 дней через n8n cron)
insert into storage.buckets (id, name, public, file_size_limit)
values ('parser-uploads', 'parser-uploads', false, 20 * 1024 * 1024)
on conflict (id) do nothing;

-- Storage policies (path convention: {user_id}/{request_id_or_uuid}/{filename})
create policy "req-att read own" on storage.objects for select to authenticated
using (bucket_id = 'request-attachments'
       and (split_part(name,'/',1)::uuid = auth.uid() or app.is_admin()));

create policy "req-att upload own" on storage.objects for insert to authenticated
with check (bucket_id = 'request-attachments'
            and split_part(name,'/',1)::uuid = auth.uid());

create policy "req-att delete own" on storage.objects for delete to authenticated
using (bucket_id = 'request-attachments'
       and (split_part(name,'/',1)::uuid = auth.uid() or app.is_admin()));

-- Аналогичные политики для parser-uploads (зеркальные).
```

### 5.4. metals.json — build-time vendoring

В `.github/workflows/deploy.yml` шаг:
```yaml
- name: Fetch metals.json
  run: curl -sf https://raw.githubusercontent.com/lamblackout/metal-calculator/main/docs/database/metals.json
       -o app-v2/static/metals.json
```

Фронт `fetch('/metals.json')` — тот же origin, Caddy кэширует с `Cache-Control: public, max-age=3600`. Версия metals.json коммитится в репо при каждом deploy. Не зависим от GitHub raw rate limits в рантайме.

**Важно для заказчика:** изменения в metals.json (репозиторий `metal-calculator`) применяются после нового merge в main и deploy — не автоматически. Это сознательное решение для воспроизводимости.

### 5.5. Лимит 20 заявок per user

Soft-archive через триггер `app.fn_archive_old_requests()` с `FOR UPDATE SKIP LOCKED`. При >20 — старейшая не-избранная архивируется. Если все 20 избранные — лимит не работает, 21+ остаются (звёздочка > лимит).

UX: `select ... where is_archived=false order by is_starred desc, created_at desc limit 20`. Архив — вкладка `/profile`.

---

## 6. n8n workflows

### 6.1. Существующие — что меняем

| # | Workflow | Изменения |
|---|---|---|
| 1 | **Web Calculator API v4** | Расширить промпт GPT-4.1-mini: С245/С345 + синонимы труб. Без структурных изменений нод. |
| 2 | **Supplier Request - Generate Excel** | Без изменений. |
| 3 | **Send Supplier Request - Email v2** | Главные изменения. См. §6.2. |
| 4 | **Get Supplier Summary v2** | Оставляем как admin-инструмент, из UI не вызываем. |
| 5 | **IMAP Trigger - Save Incoming Emails** | Email_link, orphan_responses. См. §6.3. |
| 6 | **n8n Metal Validation** (Telegram-бот) | Без изменений. Переиспользуем токен для алертов мониторинга. |
| 7 | **СБИС → AMO CRM** | Без изменений. |

### 6.2. Send Supplier Request - Email v2 (расширение)

Новый payload:
```json
{
  "request_id": "ЗП-...",
  "category_kind": "chermet|nerzh",
  "supplier_ids": ["uuid","uuid"],
  "email_type": "initial|reminder|discount_request",
  "subject": "произвольная тема от менеджера",
  "body_html": "произвольный текст",
  "attachment_url": "https://...storage.../...",
  "excel_base64": "...",
  "user_id": "uuid"
}
```

Изменения нод:
- «Code: Get Suppliers by Category» → «Supabase: Fetch Suppliers by IDs»
- «Code: Prepare Email Body» принимает `subject` и `body_html` из payload
- Добавить «HTTP Request: Download Attachment» если есть `attachment_url`
- «Supabase: Insert sent_emails» — N строк (по одной на supplier_id) с `email_type`, `resend_message_id`, `sent_by`

### 6.3. IMAP Trigger — расширение

- В «Code: Check Request ID» извлекать `message_uid` из header `Message-ID` или `X-Yandex-Message-ID`
- Новая «Build Yandex Link»: `$json.email_link = \`https://mail.yandex.ru/?uid=${$env.YANDEX_MAILBOX_UID}#message/${$json.message_uid}\``
- Новая ветка «IF: Has Supplier Match?» — если from-email нет в `suppliers` → «Supabase: Insert Orphan» с `reason='unknown_supplier_email'`
- Ветка «No Request ID» теперь записывает в `orphan_responses` с `reason='no_request_id'`
- Добавить колонки `email_link`, `yandex_uid`, `yandex_message_uid` в Supabase: Save Response
- Триггер `trg_notify_new_response` создаст уведомление автоматически

### 6.4. Новые workflows

**A. `Calc - Parse Nerzh`** (`POST /calc-parse-nerzh`) — 10 нод, GPT-4.1-mini с новым промптом без сопоставления с базой металлов. Поля: name, size, qty, weight, steel_grade, comment. Все могут быть пустыми.

**B. `Calc - Generate Nerzh Excel`** (`POST /calc-generate-nerzh-excel`) — 7 нод, без формул и ГОСТ.

**C. `Notifications - Stale Order Check`** (cron `0 * * * *`) — 8 нод, проверяет `no_response_24h`, `order_stale_7d`, `partial_response_48h`, дедуп через проверку существующих notifications.

**D. `Parser Uploads - TTL Cleanup`** (cron `0 3 * * *`) — 5 нод, удаляет объекты в `parser-uploads` старше 7 дней.

**E. Шаблоны Supabase Auth** — НЕ workflow. Настраиваются в Supabase Dashboard → Auth → Email Templates с Go templates. Resend SMTP подключается в Auth Settings.

---

## 7. Инфраструктура

### 7.1. VPS

Beget Cloud VPS 4 CPU / 6 GB RAM / 80 GB NVMe, Ubuntu 22.04 LTS. Включить swap 4GB, firewall (22 SSH, 80, 443 наружу), SSH key only, fail2ban, unattended-upgrades.

### 7.2. Docker Compose

4 сервиса: Caddy (auto-SSL), app (SvelteKit node), n8n, pg-n8n (Postgres). Secrets через файлы (`_FILE` env vars). Healthchecks, restart unless-stopped, memory limits (app 1.5G, n8n 3G, pg 1G, caddy 100M). Volumes: caddy_data, n8n_data, pg_n8n_data.

### 7.3. Caddy

Два сайта: `app.msg.example.ru` (reverse_proxy на app:3000) и `n8n.msg.example.ru` (reverse_proxy на n8n:5678 с CORS). Headers: HSTS, X-Frame-Options DENY, CSP с конкретными origins.

### 7.4. CI/CD — GitHub Actions

`ci.yml` на каждый PR: pnpm install → vitest → build → playwright.
`deploy.yml` на push в main: build Docker image → push в ghcr.io → SSH на VPS → docker compose pull && up -d. Notification в Telegram через n8n.

**Безопасность deploy:**
- Dedicated user `deploy` на VPS (не root), в группе `docker`, без shell login
- SSH key в GitHub Secret `VPS_SSH_KEY`, привязан к `deploy` пользователю
- `deploy` имеет sudoers rule только для `docker compose` команд в `/srv/msg-zakupki/`
- GHCR_TOKEN для push в registry — fine-grained PAT, scope только `write:packages` на конкретный репо

### 7.5. Бэкапы

**Решение (2026-05-18)**: бэкапы в **Yandex Disk** через `rclone` (у пользователя уже есть Yandex Disk, не заводим новые сервисы).

Cron `0 3 * * *`: pg_dump n8n + tar n8n data volume → gzip → upload в Yandex Disk через rclone. 30-дневный retention.

```bash
# /srv/msg-zakupki/infra/backup-n8n.sh
#!/usr/bin/env bash
set -euo pipefail
DATE=$(date +%F)
DEST=/srv/backups
mkdir -p $DEST

# 1. Postgres dump (workflows + credentials)
docker exec pg-n8n pg_dump -U n8n n8n | gzip > $DEST/n8n-pg-$DATE.sql.gz

# 2. n8n data volume (binary files, custom nodes)
tar czf $DEST/n8n-data-$DATE.tar.gz \
  -C /var/lib/docker/volumes/msg-zakupki_n8n_data/_data .

# 3. Upload в Yandex Disk через rclone (remote настроен на этапе 0c)
rclone copy $DEST/n8n-pg-$DATE.sql.gz yandex-disk:/msg-backups/
rclone copy $DEST/n8n-data-$DATE.tar.gz yandex-disk:/msg-backups/

# 4. Удалить локальные бэкапы старше 7 дней
find $DEST -mtime +7 -delete

# 5. Удалить в Yandex Disk бэкапы старше 30 дней
rclone delete --min-age 30d yandex-disk:/msg-backups/
```

**Дополнительная страховка**: Beget предоставляет встроенные snapshot'ы VPS (бесплатно) — это второй слой защиты на инфре Beget.

**Итого 3 слоя защиты:**
1. Production данные на Beget VPS (live)
2. Beget VPS snapshots (на инфре Beget, встроено бесплатно)
3. pg_dump + n8n data → Yandex Disk (off-site, в другой компании)

**N8N_ENCRYPTION_KEY** хранится отдельно:
- Копия в password manager Кати (1Password/Bitwarden)
- Копия у Миши в зашифрованном файле (GPG)
- В git ключ НЕ коммитится
- Без него зашифрованные credentials в бэкапе мертвы — это критическая зависимость

**Supabase Cloud** делает свои бэкапы автоматически (заявки, ответы поставщиков, поставщики, пользователи). Дополнительно дублировать в Yandex Disk не нужно — это off-site уже сам по себе.

### 7.6. Мониторинг и алерты

**Решение (2026-05-18)**: Telegram-алерты через **существующий бот `n8n Metal Validation`** (токен уже есть в credentials, переиспользуем — не заводим новый).

**Что мониторим:**
- `https://app.msg.example.ru/api/healthcheck` — фронт жив
- `https://n8n.msg.example.ru/healthz` — n8n жив
- Бэкап выполнился ночью (cron status)
- SSL сертификат истекает через 7 дней
- Диск VPS >85% (через Beget или custom скрипт)

**Сервис мониторинга**: UptimeRobot (бесплатный план: 50 monitors, 5-минутный интервал). Пинг → если 2 проверки подряд fail → алерт в Telegram через webhook.

**Что приходит в Telegram:**
- 🚨 «n8n.msg.example.ru DOWN с 03:42» (alert)
- ✅ «n8n.msg.example.ru UP, downtime 8 мин» (recovery)
- ⚠️ «SSL app.msg.example.ru истекает через 7 дней» (но Caddy сам обновит)
- ❌ «Бэкап n8n не выполнился сегодня» (cron не отписался)

**Настройка** (делается в этапе 0c):
1. Получить chat_id своего Telegram (через `@userinfobot`) — куда слать алерты
2. В UptimeRobot создать Alert Contact типа Webhook с URL `https://api.telegram.org/bot<TOKEN>/sendMessage?chat_id=<CHAT_ID>&text=...`
3. Альтернатива: создать в n8n маленький workflow `Alert Receiver` который принимает HTTP webhook и форвардит в Telegram — даёт больше контроля (фильтры, дедупликация)

### 7.7. Безопасность инфраструктуры

- Все secrets через Docker secrets (`_FILE` env vars), не в `.env`
- CSP в Caddyfile: `default-src 'self' https://*.supabase.co https://n8n.msg.example.ru; img-src 'self' data: https:; style-src 'self' 'unsafe-inline'; font-src 'self' data:;`
- Supabase `service_role` ключ — только в n8n credentials (зашифрованы через `N8N_ENCRYPTION_KEY`), нигде больше
- VPS hardening: fail2ban, unattended-upgrades, SSH disable password auth, firewall ufw deny incoming default
- Регулярные обновления Docker images через Watchtower? Нет — ручной control через GitHub Actions deploy. Безопаснее.

---

## 8. План реализации по этапам

**Изменение vs v1 плана:** перестроен порядок этапов. Инфраструктура и базовый каркас выносятся в этап 0, чтобы все остальные этапы работали на реальной инфре с самого начала.

### Этап 0 — Foundation (3-4 недели, 60-90ч)

**Задачи (последовательно с параллелизацией где можно):**

**0a. Hotfix старой системы** (10-15ч, можно параллельно с 0b-0e):
- T0.1 — Швеллер гнутый: убрать из `TYPES_WITHOUT_STEEL`, в `metals.json` обновить коэффициенты, проверить с эталоном nn.23met.ru. Версия v4.62.
- T0.2 — Добавить С245/С345 в `STEEL_GRADES` и парсер. По данным Кати: русская С, ГОСТ 27772, плотность 7.85. Если уточнятся характеристики — патч.
- T0.3 — Расширить промпт GPT-4.1-mini в `Web Calculator API v4` (синонимы труб).
- T0.4 — Commit, push, deploy на GitHub Pages.

**0b. Обучение SvelteKit 5 + ramp-up** (15-25ч):
- T0.5 — Прохождение Svelte 5 tutorial (svelte.dev/tutorial)
- T0.6 — Изучить runes API ($state, $derived, $effect, $props, $bindable), отличия от старого Svelte
- T0.7 — Изучить SvelteKit 2 (file-based routing, +page/+layout/+server, load functions, form actions, hooks)
- T0.8 — Прочитать @supabase/ssr guide для SvelteKit
- T0.9 — Прочитать bits-ui документацию

**0c. VPS + инфраструктура с нуля** (20-30ч):
- T0.10 — Закупка Beget VPS 4/6/80, Ubuntu 22.04
- T0.11 — VPS hardening: SSH key, firewall, fail2ban, unattended-upgrades, swap 4GB
- T0.12 — Установка Docker, Docker Compose
- T0.13 — Создание dedicated `deploy` user с docker group, sudoers только на compose
- T0.14 — Регистрация поддоменов `app.msg.example.ru`, `n8n.msg.example.ru` (DNS A-records)
- T0.15 — `infra/docker-compose.yml`, `Caddyfile`, secrets (`pg_pw`, `n8n_enc_key`)
- T0.16 — Запустить Caddy + Postgres-n8n + n8n. Проверить SSL автополучение.
- T0.17 — **Экспорт workflows и credentials из Railway n8n** (получить текущий `N8N_ENCRYPTION_KEY` с Railway — критично!)
- T0.18 — Импорт workflows и credentials в новый n8n. Smoke-тест: парсер, рассылка, IMAP работают на новой инфре
- T0.19 — Cron backup-n8n.sh + Yandex Object Storage
- T0.20 — UptimeRobot мониторинг + алерты в Telegram

**0d. SvelteKit scaffold + перенос калькулятора** (15-20ч):
- T0.21 — Скаффолд `app-v2/`: `pnpm create svelte@latest`, TypeScript, Tailwind 4
- T0.22 — Добавить зависимости: `lucide-svelte`, `bits-ui`, `@supabase/supabase-js`, `@supabase/ssr`, `idb-keyval`, `vitest`, `@playwright/test`
- T0.23 — Базовый каркас layout, app.html, app.css с пастельной палитрой через CSS vars
- T0.24 — Tailwind 4 миграция стилей: `@import "tailwindcss"`, `@theme` блок, `@custom-variant dark`
- T0.25 — Base UI компоненты: `Button`, `Input`, `Spinner`, `Icon`
- T0.26 — Скопировать `calculator.browser.js` в `$lib/calculator/`, разбить на подмодули, типизировать TypeScript
- T0.27 — Vitest тесты на 11 формул + 10 типовых заявок (эталон nn.23met.ru). Должны зелёные.
- T0.28 — Hello-world SvelteKit deploy через GitHub Actions на staging URL — проверка end-to-end CI/CD

**0e. Документация foundation** (5-10ч):
- T0.29 — `docs/architecture.md` (копия этого плана)
- T0.30 — `docs/adr/001-svelte-vs-react.md`, `002-supabase-auth-rls.md`
- T0.31 — `infra/README.md` — инструкция настройки VPS с нуля (для disaster recovery)
- T0.32 — Обновить `CLAUDE.md` с новой архитектурой

**Приёмка этапа 0:**
- Hotfix-ы видны в проде (старая система v4.62)
- Новая инфра живёт: `app.msg.example.ru` отдаёт hello-world через HTTPS, `n8n.msg.example.ru` работает с импортированными workflows
- CI/CD работает: push в main → auto-deploy
- Все Vitest тесты на формулы зелёные
- Бэкапы pg_dump в S3 ежедневно
- UptimeRobot пингает, алерт в Telegram

### Этап 1 — Supabase Auth + личный кабинет (3-4 недели, 65-90ч)

- T1.1-T1.4 — Применить миграции `20260601000001-002` на staging Supabase. Создать первого admin (`blackoutlamb@gmail.com`) с `raw_app_meta_data: {role: "admin"}`. Зарегистрировать Custom Access Token Hook. Настроить Resend SMTP в Auth.
- T1.5 — Кастомизировать email templates на русском (Confirm Signup, Reset Password, Invite User)
- T1.6 — `hooks.server.ts` с `createServerClient`, `safeGetSession`
- T1.7 — `(public)/login` — UI + form action signIn
- T1.8 — `(public)/reset-password` — двухшаговая флоу
- T1.9 — `(app)/+layout.server.ts` — guard на сессию + загрузка history/groups/suppliers
- T1.10 — `(app)/+layout.svelte` — хедер (лого, табы Чермет/Нержа, имя, Logout), базовый сайдбар
- T1.11 — `(app)/profile/+page.svelte` — имя, смена пароля, переключатель темы
- T1.12 — `(app)/admin/users/+page.svelte` — role guard, list пользователей, форма создания через service_role в action
- T1.13 — История запросов 20 шт: `HistoryList.svelte` со звёздочками, поиском, контекст меню
- T1.14 — Триггеры `fn_notify_new_response` + `fn_archive_old_requests` (миграция `20260601000003_triggers.sql`)
- T1.15 — **Получить Yandex `mailbox_uid` через Playwright** (зайти в zakup@msgnn.ru, открыть письмо, прочитать uid из URL). Прописать в `.env` n8n
- T1.16 — Применить миграции на prod, RLS, Storage buckets (`20260601000004_rls_and_storage.sql`)
- T1.17 — Demo Кате: login, smena пароля, увидеть пустую историю
- T1.18 — Документация: `docs/adr/003-jwt-roles.md`, `docs/runbook.md` (как админ управляет пользователями)

### Этап 2 — База поставщиков (2-2.5 недели, 35-50ч)

- T2.1 — Миграции уже применены (часть `20260601000002`). Импорт существующих hardcoded поставщиков из n8n workflow в `suppliers` (one-time скрипт).
- T2.2 — `(app)/suppliers/+page.svelte` — таблица с фильтрами категория/группа, поиск, сортировка, импорт из Excel (опционально)
- T2.3 — `SupplierFormDialog.svelte` — модалка добавления/редактирования, маска телефона, валидация email
- T2.4 — Sidebar папки (`SupplierFolders.svelte`) с bits-ui Accordion, цветовая полоска, эмодзи. Состояние в `sidebar.svelte.ts` + localStorage
- T2.5 — Фильтрация по `category_kind` текущей route (chermet vs nerzh)
- T2.6 — Карточка контакта с `tel:`, `mailto:` (Lucide phone, mail)
- T2.7 — Realtime подписка `suppliers-changes` → `invalidate('suppliers')`
- T2.8 — Тест RLS: User B не может удалить поставщика User A (только admin)
- T2.9 — Demo Кате: создать новую группу «Екатеринбург», добавить туда поставщика

### Этап 3 — Редизайн чермета (4-5 недель, 80-110ч)

- T3.1-T3.4 — `(app)/chermet/+page.svelte` с двухстолбцовым layout (60/40), `OrderEditor`, `ParseInput` (drag&drop + textarea), вызов `parseFile`/`parseText` через n8n API
- T3.5-T3.7 — `PositionsTable` + `PositionRow` сжатые (ширины из ТЗ §2.9.4), `MetalCell`/`SteelCell` компактные дропдауны с tooltip
- T3.8 — Подключить `calculateMetal` из `$lib/calculator`, реактивный пересчёт через `$effect` с debounce
- T3.9 — `SupplierSelector.svelte` — bits-ui Accordion по группам, чекбоксы, «выбрать всех», счётчики
- T3.10 — Тема и текст письма (input + textarea, без шаблонов)
- T3.11 — Кнопка «Разослать (N поставщикам)» → `sendInitial` API → n8n
- T3.12 — `ResponsesPanel.svelte` с Realtime подпиской
- T3.13 — Ссылка «Открыть письмо в Яндекс.Почте» (используем `mailbox_uid` из T1.15)
- T3.14 — «Сообщить о проблеме» в подвале: модалка → email админу через n8n
- T3.15 — Звёздочки/избранное в HistoryList: toggle `is_starred`
- T3.16 — Контекстное меню в карточке истории: переименовать (inline edit), удалить (admin only), дублировать
- T3.17 — `(app)/chermet/[requestId]/+page.svelte` — открытие из истории, исторические ответы + Realtime
- T3.18 — Скачать Excel расчёта (старый `/supplier-request` webhook)
- T3.19 — Sub-task: **сверка расчётов с старой системой** на 10 типовых заявках, ±0.001 т (10ч)
- T3.20 — Demo Кате: полный flow чермета на новом сайте

### Этап 4 — Уторговывание и напоминания (2.5-3 недели, 50-70ч)

- T4.1 — `Send Supplier Request - Email v2` переделка: поддержка `email_type`, `attachment_url`, `supplier_ids`. Реалистично 8-12ч на одну переделку workflow.
- T4.2 — `DiscountRequestDialog.svelte` — выезжающая правая панель, чекбоксы независимые
- T4.3 — Upload в Storage `request-attachments/{user_id}/{request_id}/...`
- T4.4 — Кнопка «📧 Отправить» → `sendDiscount` API → n8n с `email_type='discount_request'`
- T4.5 — `ReminderDialog.svelte` — дефолтно отмечены не-ответившие (SQL query `select supplier_id from suppliers where id not in (select supplier_id from supplier_responses where request_id=...)`
- T4.6 — `NotificationBell.svelte` в хедере с бейджем непрочитанных
- T4.7 — `notifications.svelte.ts` store + Realtime
- T4.8 — Выпадающий список уведомлений, клик → редирект на заявку
- T4.9 — Новый n8n workflow `Notifications - Stale Order Check` (cron)
- T4.10 — IMAP обновления: orphan + email_link + триггер БД
- T4.11 — `/profile` — настройки уведомлений (включить/выключить, время триггера)
- T4.12 — Demo Кате: запрос скидки с прикреплённым файлом, форсированный stale check

### Этап 5 — Нержа/Цветмет (3-3.5 недели, 60-80ч)

- T5.1 — Новый n8n workflow `Calc - Parse Nerzh` (новый промпт без сопоставления с базой)
- T5.2 — Новый n8n workflow `Calc - Generate Nerzh Excel`
- T5.3 — `(app)/nerzh/+page.svelte` — два столбца, оранжевый акцент
- T5.4 — `NerzhOrderEditor.svelte` + `NerzhTable.svelte` — упрощённая таблица, только текстовые поля
- T5.5 — Парсинг через `parseNerzh` API, без автопересчёта веса
- T5.6 — Кнопка «📥 Сформировать Excel» → `generateNerzhExcel` API
- T5.7 — Правый столбец рассылки, фильтр поставщиков `category_kind='nerzh'`
- T5.8 — Сохранение черновика при переключении категорий через `draft.svelte.ts` (IDB)
- T5.9 — Категорийная маркировка в истории (бейдж 🟧 для нержи)
- T5.10 — Demo Кате: парсинг → редактирование → Excel → рассылка нержи

### Этап 6 — Финализация миграции и сдача (1-1.5 недели, 20-30ч)

- T6.1 — **DNS-переключение**: `lamblackout.github.io/msgnn-calculator` → редирект на `app.msg.example.ru` через GitHub Pages редирект-страницу
- T6.2 — Финальная сверка: все фичи работают, тесты зелёные, бэкапы валидируются
- T6.3 — Disable Railway проект (после 2 недель параллельной работы и подтверждения от Кати)
- T6.4 — Сделать GitHub репозиторий приватным (NDA)
- T6.5 — Документация финализирована: `docs/runbook.md` для Кати, `docs/troubleshooting.md` для Миши
- T6.6 — Финальный smoke-тест в проде
- T6.7 — Sign-off Кати

### Этап 7 (опционально) — Парсер цен МС.ру/23мет (1.5-2 недели, 40-55ч)

Если включаем: Firecrawl или Playwright scraping, кэширование в `market_prices`, UI-кнопка «Подтянуть цены».

### Этап 8 (опционально) — Тёмная тема (3-5 дней, 10-15ч)

Доработка пастельной палитры под тёмную, переключатель в `/profile`.

---

## 9. Тестирование

### 9.1. Vitest unit (приоритет 1)

`app-v2/src/lib/calculator/__tests__/formulas.test.ts` — 11 формул, по 3-5 эталонных значений с nn.23met.ru.
`calculator.test.ts` — 10 типовых заявок end-to-end.

### 9.2. Playwright e2e

3 happy-path сценария: login, order-flow (parse → calc → send → realtime), draft-restore.

### 9.3. RLS regression тесты

В Vitest unit-тестах через `@supabase/supabase-js` под двумя пользователями (A, B):
- User A видит только свои `supplier_requests`
- User B пытается обновить заявку User A → 0 строк затронуто
- Manager пытается удалить supplier → 0 строк затронуто
- Admin может всё

### 9.4. CI

На каждый PR — Vitest + build. На merge в main — Vitest + Playwright + build + deploy.

### 9.5. Smoke test после деплоя

Чеклист в `infra/smoke-test.md`. 10 шагов от login до удаления заявки.

---

## 10. Open questions заказчику

### Закрыто на старте

| # | Вопрос | Ответ |
|---|---|---|
| 1 | С245/С345 | Русские С, ГОСТ 27772. Точные характеристики Катя уточнит, можно стартовать с плотностью 7.85 |
| 2 | Парсинг «ножей» | Удалено из плана |
| 3 | Email admin'а | `blackoutlamb@gmail.com` |
| 4 | Yandex `mailbox_uid` | Получить через Playwright в этапе 1 |
| 5 | Исторические заявки | Игнорируем |
| 6 | Удаление поставщиков | Только admin |
| 7 | Создание групп | Любой авторизованный |
| 8 | Параллельный auth | Старый сайт не трогаем, новый с Supabase Auth, через 4-5 мес отключение старого |

### Уточнить по ходу (не блокирует)

- Список конкретных металлов для нержи (для промпта `Calc - Parse Nerzh`) — нужно к этапу 5
- Парсер цен МС.ру/23мет: этап 7 или вообще нет? Решение к концу этапа 3
- `Get Supplier Summary v2`: оставлять или удалить? Решение к концу этапа 4
- Email-дублирование критичных уведомлений на личный email менеджера — после этапа 4 фидбек
- Точные характеристики С245/С345 — Катя пришлёт TODO

---

## 11. Параллельный режим миграции

**Этап 0** — старый сайт работает как обычно. Новая инфра поднимается параллельно. Hotfix-ы заливаются в старый.

**Этапы 1-5** — новая система постепенно появляется на `app.msg.example.ru`. У менеджеров два паролей в этот период: старый `msg/Zakupki2024!#` на `lamblackout.github.io/msgnn-calculator`, новый индивидуальный email+пароль на `app.msg.example.ru`. **Это терпимо**, потому что переходный период чёткий, Катя предупреждена.

**Этап 6** — DNS-переключение, отключение Railway, репо приватный.

**Откат**: в любой момент возвращаем DNS старого сайта обратно на GitHub Pages, продолжаем работу там.

---

## 12. Безопасность

### 12.1. Auth и RLS

- Supabase Auth с email/password + Custom Access Token Hook
- Роли в `app_metadata` (защита от self-elevation через `user_metadata`)
- RLS на всех таблицах с `force row level security`
- Storage с path-based RLS (`{user_id}/...`)

### 12.2. Secrets

- `N8N_ENCRYPTION_KEY` хранится отдельно от бэкапов (1Password Кати + GPG-encrypted у Миши)
- Supabase `service_role` ключ — только в n8n credentials (зашифрованы через `N8N_ENCRYPTION_KEY`)
- Все Docker secrets через `_FILE` env vars, не в plain `.env`
- AWS credentials для Yandex Object Storage — в `/root/.aws/credentials` с правами 0600
- GitHub Secrets: `VPS_HOST`, `VPS_SSH_KEY`, `GHCR_TOKEN` (fine-grained PAT)

### 12.3. Network

- VPS firewall: только 22, 80, 443 inbound
- SSH: key only, password auth disabled, fail2ban
- Caddy CSP: `default-src 'self' https://*.supabase.co https://n8n.msg.example.ru`
- HSTS включён
- X-Frame-Options DENY

### 12.4. CI/CD

- Dedicated `deploy` user на VPS, без shell, sudoers только на docker compose
- Docker images подписываются (опционально, через cosign — на втором этапе)
- На каждый PR — Vitest + Playwright должны быть зелёные перед merge

### 12.5. RLS-тесты

Регрессионные тесты на access control (см. §9.3) запускаются в CI. Если кто-то случайно ослабит политику — CI красный.

---

## 13. Риски и митигации

| Риск | Вероятность | Митигация |
|---|---|---|
| **Парсер OpenAI деградирует/меняется** | Средняя | Vitest тесты на 10 эталонных заявок. При regression — bisect промпта. |
| **Beget VPS падает** | Низкая | UptimeRobot алерт. Бэкапы pg_dump в Yandex Object Storage. Disaster recovery план в `infra/README.md`. |
| **`N8N_ENCRYPTION_KEY` потерян** | Низкая | Две копии (1Password + GPG-encrypted). Никогда в git. |
| **RLS-баг открывает чужие заявки** | Низкая | Регрессионные тесты в CI на access control. |
| **Тяжёлые заявки 100+ позиций тормозят** | Средняя | Виртуализация таблицы через `@tanstack/svelte-virtual` — если станет проблемой. Сейчас не предупреждаем. |
| **Гнутый швеллер фикс ломает другие расчёты** | Средняя | Vitest regression suite перед merge. Сверка с эталоном на 10 типовых заявок. |
| **Supabase Realtime free tier превышен** | Низкая | На 5-10 пользователей лимит 200 не достижим. При росте — Pro $25. |
| **Yandex `mailbox_uid` нельзя получить через Playwright** | Низкая | Fallback: ссылка без uid тоже работает у залогиненного, просто менее надёжно. |
| **Параллельный режим путает менеджеров** | Средняя | Чёткая коммуникация от Кати. На старом сайте можно повесить плашку «Переходите на app.msg.example.ru». |
| **n8n 2.x breaking changes от Railway 1.x** | Средняя | Проверить changelog при миграции. Workflows должны импортироваться 1:1, но env переменные могли поменяться. |
| **Один разработчик уходит/недоступен** | Средняя | Документация в `docs/` (architecture.md, ADRs, runbook.md, troubleshooting.md). Catanyone может прочитать и разобраться за 2-3 дня. |
| **Vendor lock-in (Supabase, Resend, Beget)** | Низкая | Supabase — open source, можно self-host. Resend — есть альтернативы (Postmark, Mailgun). Beget — есть Timeweb как замена за день. |
| **Tailwind 4 миграция стилей займёт больше** | Средняя | Заложено отдельной задачей T0.24, ~8-12ч |
| **Ramp-up SvelteKit для vanilla JS разработчика** | Высокая | Заложено отдельной задачей T0.5-T0.9, ~15-25ч обучения до продуктивности |
| **n8n credentials миграция с Railway не пройдёт** | Средняя | Заложен fallback: пересоздать credentials вручную (Resend, Supabase, IMAP, OpenAI, Telegram) — это ещё 4-6ч сверху, если что |

---

## 14. Финальная смета

### Часы и сроки

| Этап | Часы | Дней (5ч/день) | Календарь |
|---|---|---|---|
| 0. Foundation (hotfix + ramp-up + VPS + scaffold + docs) | 60-90 | 12-18 | 3-4 недели |
| 1. Auth + кабинет + миграции БД | 65-90 | 13-18 | 3-4 недели |
| 2. База поставщиков | 35-50 | 7-10 | 2-2.5 недели |
| 3. Редизайн чермета | 80-110 | 16-22 | 4-5 недель |
| 4. Уторговывание + напоминания | 50-70 | 10-14 | 2.5-3 недели |
| 5. Нержа/Цветмет | 60-80 | 12-16 | 3-3.5 недели |
| 6. Финализация миграции | 20-30 | 4-6 | 1-1.5 недели |
| **Итого основные этапы** | **370-520ч** | **74-104** | **18.5-22.5 недель ≈ 4.5-5.5 мес** |
| 7. (опц.) Парсер цен МС.ру/23мет | +40-55 | +8-11 | +2 недели |
| 8. (опц.) Тёмная тема | +10-15 | +2-3 | +3-5 дней |

**Изменение vs v1 плана (255-360ч):** +115-160ч (45% увеличение). Заложено:
- Ramp-up на SvelteKit (15-25ч) — не было
- Tailwind 4 миграция стилей (8-12ч) — не было
- VPS setup с нуля + миграция n8n credentials (расширено) — было 30-45ч стало 40-50ч
- Документация ADRs/runbook/troubleshooting (15-25ч) — не было
- Сверка расчётов с эталоном (10ч) — не было
- Митинги с Катей и demo по этапам (~15-25ч) — не было

### Cost для понимания инвестиции

При средней ставке для подобных b2b проектов в РФ 1500-1900 ₽/час (full-stack senior с DevOps):

- **Полный объём без опциональных (370-520ч)**: 555-988 тыс. ₽
- **С парсером цен и тёмной темой**: 615-1093 тыс. ₽

**Для понимания инвестиции** (не как оплата): если Миша работает «бесплатно» на своём проекте — вклад труда эквивалентен **~700-900 тыс. ₽ рыночной стоимости** для основной части, **~800-1000 тыс. ₽** с опциональными.

---

## 15. Верификация конечного результата

### Production smoke test

```bash
curl https://app.msg.example.ru/api/healthcheck     # expect: 200 {"ok":true}
curl https://n8n.msg.example.ru/healthz             # expect: 200
ls -la /srv/backups/ | grep "n8n-pg-$(date +%F)"    # сегодняшний дамп есть
gh run list --workflow=ci.yml --limit 1             # success
supabase db diff                                    # clean
```

### Ручной чеклист после каждого этапа

См. `infra/smoke-test.md` (создаётся в этапе 0).

---

## 16. Critical files для реализации

**Будут созданы:**
- `supabase/migrations/20260601000001_init_auth_roles_schema.sql`
- `supabase/migrations/20260601000002_schema_tables.sql`
- `supabase/migrations/20260601000003_triggers.sql`
- `supabase/migrations/20260601000004_rls_and_storage.sql`
- `app-v2/` (новый SvelteKit проект, дерево см. §3)
- `infra/docker-compose.yml`, `infra/Caddyfile`, `infra/backup-n8n.sh`, `infra/README.md`
- `.github/workflows/ci.yml`, `.github/workflows/deploy.yml`
- `docs/architecture.md`, `docs/adr/`, `docs/runbook.md`, `docs/troubleshooting.md`, `docs/deployment.md`

**Будут изменены:**
- `n8n-workflows/Send Supplier Request - Email v2.json` (email_type, supplier_ids, attachment_url)
- `n8n-workflows/IMAP Trigger - Save Incoming Emails.json` (email_link, orphan_responses)
- `n8n-workflows/Web Calculator API v4.json` (промпт: С245/С345, синонимы)
- `index.html` (этап 0a hotfix — гнутый швеллер, С245/С345)
- `calculator.browser.js` (этап 0a hotfix — TYPES_WITHOUT_STEEL без гнутого швеллера)
- `CLAUDE.md` (обновление под новую архитектуру)

**Будут добавлены в n8n:**
- `Calc - Parse Nerzh` (новый workflow)
- `Calc - Generate Nerzh Excel`
- `Notifications - Stale Order Check` (cron)
- `Parser Uploads - TTL Cleanup` (cron)

---

## 17. Отложенные hotfix-ы

**Статус**: ⏭️ Postponed (с 2026-05-18). Возвращаемся после завершения основной работы (этапов 0c-6), либо когда пользователь скажет.

**Почему отложено**: hotfix-ы относятся к старой системе на GitHub Pages, которая в параллельный период работает как есть. Эти баги Катя видит, но они не блокируют использование системы. Основная задача — построить новую систему. Когда новая запустится, эти задачи либо мигрируют в новую структуру (новый calculator + новая metals.json), либо вообще отпадут.

### 17.1. Швеллер гнутый — выбор стали

**Описание**: гнутый швеллер сейчас в `TYPES_WITHOUT_STEEL` в [calculator.browser.js](../calculator.browser.js) — нельзя выбрать марку стали, потому что коэффициенты в metals.json уже содержат плотность 7.85. Это баг (явное «это ошибка?» — «конечно»).

**Что сделать когда вернёмся**:
1. Решение архитектуры (выбирается перед фиксом):
   - **Вариант A** (рекомендация): применять корректирующий коэффициент `selected_steel.density / 7.85` в расчёте. Коэффициенты в metals.json остаются как есть. Менее инвазивно.
   - **Вариант B**: разделить коэффициенты на 7.85 в metals.json (станут «чистыми линейными»), при расчёте умножать на плотность стали. Чище архитектурно, но требует пересчёта всех коэффициентов для гнутого швеллера.
2. Убрать `shveller_gnyt`, `shveller_gnyt_ocink` из `TYPES_WITHOUT_STEEL`
3. Показать дропдаун стали в UI для гнутого швеллера
4. Vitest тесты на эталонных значениях с https://nn.23met.ru/calculator
5. Версия v4.62

**Срочность**: НЕ срочно. Заказчик использует, но обходные варианты есть (вручную править вес).

### 17.2. Марки стали С245 / С345 (по ГОСТ 27772)

**Описание**: Катя сказала «не хватает 245 и 345». Это С245/С345 русские (конструкционные по ГОСТ 27772, плотность 7.85). Нужно добавить в `metals.json` репозитория `metal-calculator` и в промпт парсера в `Web Calculator API v4`.

**Блокер**: на nn.23met.ru у некоторых позиций НЕТ марок стали в дропдауне — поэтому не получается сверить эталонными значениями. Скриншот Катя обещала прислать, после её ответа точные характеристики будут понятнее (может оказаться что речь о других марках, например 09Г2С с пределом текучести 345).

**Что сделать когда вернёмся**:
1. Получить от Кати конкретный скриншот / описание позиции где не хватает марки
2. Если это С245/С345 → добавить в metals.json:
   ```json
   "С245": { "density": 7.85, "yield_strength_mpa": 245, "gost": "27772" },
   "С345": { "density": 7.85, "yield_strength_mpa": 345, "gost": "27772" }
   ```
3. Расширить парсер промпта GPT-4.1-mini в `n8n-workflows/Web Calculator API v4.json`
4. Если это другие марки — действовать по контексту скриншота

**Срочность**: НЕ срочно. Менеджеры используют существующие близкие марки.

### 17.3. Синонимы труб в парсере

**Описание**: расширить словарь синонимов в промпте GPT-4.1-mini:
- круглая / круг / кругляк / круглая труба
- квадрат / кв. труба / квадратка / профильная квадрат
- прямоугольная / прямоугольник / профильная прям.
- профильная / профтруба / проф труба
- ВГП / в.г.п. / газовая / водогазопроводная
- электросварная / ЭСВ / эл.св.

**Блокер**: нужен список из 10-15 проблемных заявок от Кати — какие конкретные строки она присылала. Без примеров заявок словарь делается «вслепую» и может не покрыть реальные случаи.

**Что сделать когда вернёмся**:
1. Получить от Кати 10-15 реальных строк заявок где парсер ошибается
2. Расширить промпт парсера на основе примеров
3. Сохранить набор тестовых примеров для регрессии

**Срочность**: НЕ срочно. Парсер работает в большинстве случаев, конкретные ошибки менеджеры правят руками в таблице.

### 17.4. Парсинг «ножей»

**Статус**: УДАЛЕНО из плана (Катя не прислала пример, нечего фиксить).

---

## 18. История изменений плана

- **v2.0** (2026-05-18) — внутренний ревью + ответы заказчика, перестроены этапы, инфра в начале, ramp-up SvelteKit, Tailwind 4 миграция, документация выделены отдельно, БД миграции объединены в 4 файла, race condition в триггере исправлен, dedicated SSH user, секция Status трекинг этапов, универсальный промпт
- **v2.1** (2026-05-18) — этап 0a hotfix отложен по решению пользователя (не критично для основной задачи), задачи перенесены в §17 «Отложенные hotfix-ы», следующий этап — 0c VPS setup

---

**Конец плана v2.1**
