# Infra — MSG Закупки v2.0

Инфраструктура продакшен-стенда на Beget VPS. Caddy + Postgres + n8n + (позже) SvelteKit-app, развёрнутые через Docker Compose.

> **Дата создания**: 2026-05-19
> **VPS**: `msg-prod` (IP `95.214.63.15`), Beget Cloud, Санкт-Петербург
> **Домены**: `app.msgzakupki.ru`, `n8n.msgzakupki.ru` (apex → app)
> **Этап плана**: 0c (см. [`.claude/plans/functional-crunching-galaxy.md`](../.claude/plans/functional-crunching-galaxy.md))

---

## Содержание

1. [Что уже готово](#1-что-уже-готово)
2. [Что осталось сделать (T0.11-T0.20)](#2-что-осталось-сделать)
3. [Первый вход на VPS + hardening (T0.11)](#3-t011--hardening-vps)
4. [Docker + deploy user (T0.12-T0.13)](#4-t012-t013--docker--deploy-user)
5. [Подготовка secrets (T0.16a)](#5-t016a--подготовка-secrets)
6. [Деплой docker-compose (T0.16b)](#6-t016b--деплой-docker-compose)
7. [Миграция n8n с Railway (T0.17-T0.18)](#7-t017-t018--миграция-n8n-с-railway)
8. [Бэкапы в Yandex Disk (T0.19)](#8-t019--бэкапы-в-yandex-disk)
9. [Мониторинг + алерты (T0.20)](#9-t020--мониторинг--алерты)
10. [Troubleshooting](#10-troubleshooting)
11. [Disaster recovery](#11-disaster-recovery)

---

## 1. Что уже готово

- ✅ Beget аккаунт `zakupm59` на ООО МСГ (ИНН 5263101167)
- ✅ VPS `msg-prod`: 2 CPU / 4 GB RAM / 40 GB NVMe, Docker preinstalled
- ✅ IP `95.214.63.15`
- ✅ Домен `msgzakupki.ru` (199 ₽ зарегистрирован, автопродление включено)
- ✅ DNS A-записи: apex, app., n8n. — все на `95.214.63.15`
- ✅ Баланс Beget: ~1 301 ₽ (после оплаты домена)
- ✅ Локальные файлы инфры: `docker-compose.yml`, `Caddyfile`, `backup-n8n.sh`, `.env.example`

Подробные реквизиты доступа — в файле `Доступы_к_системам_MSG_2026-05-19.md` в корне проекта (gitignored).

---

## 2. Что осталось сделать

| Задача | Что делает | Время |
|---|---|---|
| T0.11 | Первый вход на VPS + hardening (SSH-key, firewall, fail2ban, swap, отключение парольного входа) | 2-3 ч |
| T0.12 | Проверка установленных Docker и Docker Compose (preinstalled) | 10 мин |
| T0.13 | Создание dedicated user `deploy` с docker group | 30 мин |
| T0.16a | Подготовка secrets (`pg_password`, `n8n_encryption_key`) | 30 мин |
| T0.16b | Загрузка инфра-файлов на VPS, запуск `docker compose up -d`, проверка SSL | 1 ч |
| T0.17 | Экспорт workflows и credentials с Railway | 1 ч |
| T0.18 | Импорт в новый n8n + smoke-тест (парсер, рассылка, IMAP) | 2-3 ч |
| T0.19 | Cron `backup-n8n.sh` + rclone в Yandex Disk | 1 ч |
| T0.20 | UptimeRobot + Telegram-алерты | 1 ч |

**Итого: ~10-13 часов** работы по SSH на VPS. Делается в следующем чате.

---

## 3. T0.11 — Hardening VPS

### 3.1. Первый вход

В письме от Beget на `zakup@msgnn.ru` пришёл **root-пароль**. Заходим:

```bash
ssh root@95.214.63.15
# Ввести пароль из письма Beget
```

⚠️ Если входим в первый раз — Beget может предложить сменить пароль сразу при логине. Введи **новый сильный пароль** (32 символа, использовать `openssl rand -base64 24`).

### 3.2. Обновить систему

```bash
apt update && apt upgrade -y
apt autoremove -y
```

### 3.3. Swap 4 GB

VPS имеет 4 GB RAM, но при пиках (build SvelteKit, OpenAI парсинг параллельно) может не хватить. Swap-файл = страховка.

```bash
# Создаём 4GB swap-файл
fallocate -l 4G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

# Делаем постоянным (после reboot)
echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab

# Проверка
free -h
swapon --show
```

### 3.4. SSH-ключ (вместо пароля)

На локальной машине Миши (если ключа ещё нет):

```bash
# На локальной машине Миши
ssh-keygen -t ed25519 -C "msg-prod-deploy" -f ~/.ssh/msg_prod_key

# Скопировать публичный ключ на сервер
ssh-copy-id -i ~/.ssh/msg_prod_key.pub root@95.214.63.15
```

Проверить вход без пароля:

```bash
ssh -i ~/.ssh/msg_prod_key root@95.214.63.15
# Должен войти без запроса пароля
```

### 3.5. Отключить парольный SSH

На сервере:

```bash
# Резервная копия конфига
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Изменения:
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
sed -i 's/^#*ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config

# Применить
systemctl reload sshd

# Проверка: открыть НОВЫЙ ssh-сеанс (не закрывая старый!) — должен войти только по ключу
```

⚠️ **Не закрывай первую сессию**, пока не убедился что новая сессия открывается по ключу!

### 3.6. Firewall ufw

```bash
# Установка
apt install -y ufw

# Дефолтные правила
ufw default deny incoming
ufw default allow outgoing

# Разрешённые порты
ufw allow 22/tcp     # SSH
ufw allow 80/tcp     # HTTP (Caddy)
ufw allow 443/tcp    # HTTPS (Caddy)
ufw allow 443/udp    # HTTP/3 (Caddy)

# Запуск
ufw --force enable

# Проверка
ufw status verbose
```

### 3.7. fail2ban

Защита от перебора паролей SSH (хотя пароль уже отключён, fail2ban всё равно полезен для логирования и блокировки сканеров):

```bash
apt install -y fail2ban
systemctl enable --now fail2ban
fail2ban-client status sshd
```

### 3.8. Unattended-upgrades

Автоматическое применение security-обновлений Ubuntu:

```bash
apt install -y unattended-upgrades apt-listchanges
dpkg-reconfigure -plow unattended-upgrades
# Ответить "Yes"
```

---

## 4. T0.12-T0.13 — Docker + deploy user

### 4.1. Проверка Docker (preinstalled через шаблон Beget)

```bash
docker --version
docker compose version
```

Если что-то не так — переустановить через официальный скрипт:

```bash
curl -fsSL https://get.docker.com | sh
```

### 4.2. Создание deploy user

```bash
# Создать пользователя без shell, в группе docker
useradd -m -s /bin/bash deploy
usermod -aG docker deploy

# SSH-ключ deploy (тот же что у root, для удобства Миши)
mkdir -p /home/deploy/.ssh
cp ~/.ssh/authorized_keys /home/deploy/.ssh/
chown -R deploy:deploy /home/deploy/.ssh
chmod 700 /home/deploy/.ssh
chmod 600 /home/deploy/.ssh/authorized_keys

# Sudoers только на docker compose
cat > /etc/sudoers.d/deploy <<'EOF'
deploy ALL=(root) NOPASSWD: /usr/bin/docker compose *, /usr/bin/systemctl reload caddy
EOF
chmod 0440 /etc/sudoers.d/deploy

# Проверка
su - deploy
docker ps
exit
```

---

## 5. T0.16a — Подготовка secrets

### 5.1. Создать структуру каталогов

```bash
mkdir -p /srv/msg-zakupki/infra/secrets
chown -R deploy:deploy /srv/msg-zakupki
```

### 5.2. Сгенерировать pg_password

```bash
openssl rand -base64 32 | tr -d '\n' > /srv/msg-zakupki/infra/secrets/pg_password.txt
chmod 0600 /srv/msg-zakupki/infra/secrets/pg_password.txt
```

### 5.3. Положить N8N_ENCRYPTION_KEY

**Сначала получи ключ с Railway** (см. §7.1 ниже — экспорт с Railway), потом:

```bash
echo "ВСТАВЬ_СЮДА_КЛЮЧ_С_RAILWAY" > /srv/msg-zakupki/infra/secrets/n8n_encryption_key.txt
chmod 0600 /srv/msg-zakupki/infra/secrets/n8n_encryption_key.txt
```

⚠️ Если положишь **другой** ключ — n8n при импорте workflows не сможет расшифровать credentials (Resend API, Supabase, IMAP, OpenAI). Все credentials придётся пересоздавать вручную (это ещё 2-4 часа работы).

---

## 6. T0.16b — Деплой docker-compose

### 6.1. Загрузить файлы infra/ на VPS

С локальной машины Миши (из корня проекта `msgnn-calculator`):

```bash
# Через rsync
rsync -avz --exclude='secrets/' infra/ deploy@95.214.63.15:/srv/msg-zakupki/infra/

# Или через scp
scp -r infra/docker-compose.yml infra/Caddyfile infra/backup-n8n.sh infra/.env.example deploy@95.214.63.15:/srv/msg-zakupki/infra/
```

### 6.2. Создать .env с COMPOSE_PROJECT_NAME

```bash
ssh deploy@95.214.63.15
cd /srv/msg-zakupki/infra

# Создать .env из примера
cp .env.example .env

# Проверить что COMPOSE_PROJECT_NAME=msg-zakupki установлен
grep COMPOSE_PROJECT_NAME .env
```

⚠️ Это критично: без `COMPOSE_PROJECT_NAME=msg-zakupki` Docker назовёт volumes `infra_pg_n8n_data` и `infra_n8n_data`, а скрипт `backup-n8n.sh` ищет `msg-zakupki_n8n_data` — бэкап n8n volume не сработает.

### 6.3. Запустить compose

```bash
# Pull последние образы
docker compose pull

# Запуск
docker compose up -d

# Проверить что все 3 контейнера в статусе healthy (через ~1-2 мин)
docker compose ps
```

Должно быть:
```
NAME          STATUS                   PORTS
msg-caddy     Up (healthy)             0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp
msg-n8n       Up (healthy)             5678/tcp
msg-pg-n8n    Up (healthy)             5432/tcp
```

### 6.4. Проверить логи Caddy на получение SSL

```bash
docker compose logs caddy --tail 50
```

Должно появиться: `certificate obtained successfully` для каждого домена (msgzakupki.ru, app.msgzakupki.ru, n8n.msgzakupki.ru, www.msgzakupki.ru).

### 6.5. Smoke-тест

С локальной машины:

```bash
curl -I https://n8n.msgzakupki.ru/healthz
# Ожидаем: HTTP/2 200, заголовок Strict-Transport-Security

curl -I https://app.msgzakupki.ru
# Ожидаем: HTTP/2 503 (placeholder пока app не запущен)

curl -I https://msgzakupki.ru
# Ожидаем: HTTP/2 301, redirect на https://app.msgzakupki.ru
```

В браузере: https://n8n.msgzakupki.ru — должна показать UI n8n с предложением создать первого пользователя.

---

## 7. T0.17-T0.18 — Миграция n8n с Railway

### 7.1. Экспорт с Railway

В Railway dashboard (https://railway.app):

1. Открыть проект n8n
2. **Settings → Variables** — скопировать значение `N8N_ENCRYPTION_KEY` (это критично, см. §5.3 выше)
3. Открыть текущий UI n8n (Railway public URL)
4. **Settings → Workflows → Download** — скачать JSON всех workflows
5. **Credentials → Export** (через CLI или вручную каждую)

### 7.2. Импорт в новый n8n

В новом n8n (https://n8n.msgzakupki.ru):

1. Создать первого пользователя (email `zakup@msgnn.ru`)
2. **Settings → Import** — загрузить JSON workflows
3. Credentials должны автоматически расшифроваться (если `N8N_ENCRYPTION_KEY` совпадает с Railway)
4. Если credentials не расшифровались — пересоздать вручную (Resend API, Supabase, IMAP, OpenAI, Telegram)

### 7.3. Smoke-тест

- Парсер чермета: запустить `Web Calculator API v4` с тестовой строкой → должен вернуть распознанные позиции
- Рассылка: `Send Supplier Request - Email v2` → отправить тест-email
- IMAP: `IMAP Trigger - Save Incoming Emails` → проверить что слушает Yandex 360
- Excel: `Supplier Request - Generate Excel` → сгенерить тест-файл
- Telegram бот: `n8n Metal Validation` → отправить тестовое сообщение

### 7.4. Обновить webhook URLs в коде

В старом `index.html` (если будем держать параллельно) и новом app — заменить:

```diff
- https://primary-production-4e88.up.railway.app/webhook
+ https://n8n.msgzakupki.ru/webhook
```

### 7.5. Disable Railway проект

После 1-2 недель параллельной работы (этап 6) и подтверждения от Кати — отключить Railway.

---

## 8. T0.19 — Бэкапы в Yandex Disk

### 8.1. Установка rclone

```bash
ssh deploy@95.214.63.15
sudo curl https://rclone.org/install.sh | sudo bash
```

### 8.2. Настройка remote `yandex-disk`

```bash
rclone config
# n) New remote
# name> yandex-disk
# Storage> yandex (выбрать из списка)
# client_id> (оставить пустым)
# client_secret> (оставить пустым)
# Use auto config? > Y
# (откроется браузер для авторизации в Я.Диск)
# y/e/d> y (Yes this is OK)
# q (Quit config)
```

Проверить:

```bash
rclone lsd yandex-disk:
# Должны увидеть список папок Yandex Disk
```

### 8.3. Создать папку для бэкапов

```bash
rclone mkdir yandex-disk:/msg-backups
```

### 8.4. Cron на ежедневный бэкап в 03:00 МСК

```bash
crontab -e
# Добавить строку:
0 3 * * * /srv/msg-zakupki/infra/backup-n8n.sh >> /var/log/msg-backup.log 2>&1
```

### 8.5. Тестовый прогон вручную

```bash
bash /srv/msg-zakupki/infra/backup-n8n.sh
# Проверить лог
tail -50 /var/log/msg-backup.log
# Проверить что файлы в Yandex Disk появились
rclone ls yandex-disk:/msg-backups
```

---

## 9. T0.20 — Мониторинг + алерты

### 9.1. Получить Chat ID для Telegram

В Telegram отправить `/start` боту `@userinfobot` → получить свой `chat_id` (число типа `123456789`).

### 9.2. UptimeRobot

Создать аккаунт https://uptimerobot.com (бесплатный план: 50 monitors, 5-мин интервал).

Добавить мониторы:

| URL | Тип | Что проверяем |
|---|---|---|
| `https://n8n.msgzakupki.ru/healthz` | HTTPS | n8n жив |
| `https://app.msgzakupki.ru` | Keyword | (когда app будет — ищем "MSG" в HTML) |
| `https://95.214.63.15:443` | Port | TLS на 443 открыт |

### 9.3. Alert Contact → Telegram webhook

В UptimeRobot:

1. **My Settings → Alert Contacts → Add Alert Contact**
2. Type: **Web-Hook**
3. URL: `https://api.telegram.org/bot<TOKEN>/sendMessage?chat_id=<CHAT_ID>&text=*alertTypeFriendlyName*+*monitorFriendlyName*+%28*monitorURL*%29`
4. Где `<TOKEN>` — токен бота `n8n Metal Validation` (взять из n8n credentials), `<CHAT_ID>` — твой chat_id

### 9.4. Альтернатива через n8n workflow

Создать в n8n workflow `Alert Receiver`:

- Trigger: HTTP webhook `/webhook/uptime-alert`
- Action: отправить в Telegram через credentials бота

URL для UptimeRobot: `https://n8n.msgzakupki.ru/webhook/uptime-alert`

Это даёт больше контроля (фильтры, дедупликация, форматирование).

---

## 10. Troubleshooting

### Caddy не получает SSL

- Проверить DNS A-записи: `dig +short n8n.msgzakupki.ru` → должен вернуть `95.214.63.15`
- Проверить что 80/443 порты открыты в ufw: `ufw status`
- Проверить логи Caddy: `docker compose logs caddy --tail 100`
- Если Let's Encrypt rate-limit — переключиться на staging ACME (см. Caddyfile §глобальные настройки)

### n8n не запускается

- Проверить логи: `docker compose logs n8n --tail 100`
- Если ошибка `bad encryption key` — значит `N8N_ENCRYPTION_KEY` не совпадает с тем, что использовался при создании БД. Решение: либо положить правильный ключ, либо удалить volume `pg_n8n_data` и стартануть с нуля (потеряем workflows из БД)

### Postgres не стартует

- Проверить permissions volume: `docker volume inspect msg-zakupki_pg_n8n_data`
- Логи: `docker compose logs pg-n8n --tail 50`
- При первом запуске PG генерирует пароль из secrets/pg_password.txt — проверь что файл существует и не пустой

### High memory usage

- 4GB RAM — может быть впритык если все 3 сервиса грузятся одновременно. Включить swap (см. §3.3).
- `docker stats` — посмотреть кто кушает.
- Если n8n кушает >1.5GB — снизить `EXECUTIONS_DATA_MAX_AGE` (сейчас 720 часов = 30 дней).

### Beget shut down VPS за неуплату

- Зайти в https://cp.beget.com/pay, пополнить баланс (СБП), VPS включится автоматически в течение 5-10 минут.

---

## 11. Disaster recovery

### Сценарий: VPS пропал (отказ Beget или удалили по ошибке)

1. Заказать новый VPS в Beget (или другом хостере: Timeweb, Selectel)
2. Повторить §3-§6 с этим README на новой машине
3. Восстановить данные:
   ```bash
   # Скачать последний бэкап с Yandex Disk
   rclone copy yandex-disk:/msg-backups/n8n-pg-LATEST.sql.gz /tmp/
   rclone copy yandex-disk:/msg-backups/n8n-data-LATEST.tar.gz /tmp/

   # Восстановить Postgres
   gunzip -c /tmp/n8n-pg-LATEST.sql.gz | docker exec -i msg-pg-n8n psql -U n8n -d n8n

   # Восстановить n8n data volume
   docker compose down n8n
   docker volume rm msg-zakupki_n8n_data
   docker volume create msg-zakupki_n8n_data
   tar xzf /tmp/n8n-data-LATEST.tar.gz -C /var/lib/docker/volumes/msg-zakupki_n8n_data/_data
   docker compose up -d n8n
   ```
4. Обновить DNS A-записи на новый IP в Beget (https://cp.beget.com/dns/14265533)
5. Сертификаты Caddy выпустит заново автоматически

**Ключевая зависимость**: `N8N_ENCRYPTION_KEY` должен сохраниться (1Password Кати + GPG Миши). Без него зашифрованные credentials в бэкапе мертвы.

### Сценарий: Yandex Disk недоступен

- Beget предоставляет встроенные VPS snapshots (бесплатно) — второй слой защиты. Восстановление через cp.beget.com/cloud/servers/msg-prod
- Локальные бэкапы хранятся 7 дней в `/srv/backups/` на VPS (если VPS жив)

### Сценарий: n8n workflows повреждены

- Откатить через `git log` n8n-workflows/*.json в репозитории msgnn-calculator (там хранится экспорт workflows)
- Импортировать предыдущую версию в n8n UI

---

## Связанные файлы

- [`docker-compose.yml`](docker-compose.yml) — определение 3 сервисов
- [`Caddyfile`](Caddyfile) — reverse proxy конфиг
- [`backup-n8n.sh`](backup-n8n.sh) — скрипт ежедневного бэкапа
- [`.env.example`](.env.example) — пример переменных окружения
- [`Доступы_к_системам_MSG_2026-05-19.md`](../Доступы_к_системам_MSG_2026-05-19.md) — реквизиты доступа (gitignored)
- [`.claude/plans/functional-crunching-galaxy.md`](../.claude/plans/functional-crunching-galaxy.md) — общий план проекта v2.0

---

**Контакт**: при проблемах — Миша `blackoutlamb@gmail.com` или Beget support `support@beget.com` / `+7 (812) 385-41-36`.
