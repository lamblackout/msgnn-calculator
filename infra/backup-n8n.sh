#!/usr/bin/env bash
# MSG Закупки — backup n8n
# Запускается через cron каждый день в 03:00 (см. infra/README.md §бэкапы)
#
# Делает:
#   1. pg_dump базы n8n (workflows + credentials, зашифрованы через N8N_ENCRYPTION_KEY)
#   2. tar n8n data volume (binary files, custom nodes, settings)
#   3. Загрузка в Yandex Disk через rclone (remote name: yandex-disk)
#   4. Удаление локальных бэкапов старше 7 дней
#   5. Удаление в Yandex Disk бэкапов старше 30 дней
#
# Что НЕ бэкапится этим скриптом:
#   - Supabase Cloud (он делает свои бэкапы автоматически)
#   - Caddy data (сертификаты Let's Encrypt автообновляются)
#
# Critical: N8N_ENCRYPTION_KEY должен храниться ОТДЕЛЬНО от этого бэкапа
# (1Password у Кати + GPG у Миши). Без него зашифрованные credentials в бэкапе
# мертвы — это сознательная критическая зависимость для дополнительной защиты.

set -euo pipefail

# ─── Конфигурация ─────────────────────────────────────────────────
DATE=$(date +%F)
DEST=/srv/backups
COMPOSE_DIR=/srv/msg-zakupki/infra
# Лог в /srv/backups/ (не /var/log/) — чтобы скрипт мог писать от пользователя deploy без sudo
LOG=$DEST/msg-backup.log
RCLONE_REMOTE=yandex-disk:/msg-backups
RETENTION_LOCAL_DAYS=7
RETENTION_REMOTE_DAYS=30

# ─── Подготовка ───────────────────────────────────────────────────
mkdir -p "$DEST"

# Логирование с меткой времени
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG"
}

log "═══════════════════════════════════════════════"
log "Старт бэкапа n8n — $DATE"

# ─── 1. Postgres dump (workflows + credentials) ───────────────────
log "→ pg_dump базы n8n..."

DUMP_FILE="$DEST/n8n-pg-$DATE.sql.gz"

# pipefail из set -euo pipefail заставит fail если pg_dump упадёт внутри пайпа
if ! docker exec msg-pg-n8n pg_dump -U n8n -d n8n --no-owner --no-acl 2>>"$LOG" | gzip > "$DUMP_FILE"; then
  log "  ✗ pg_dump завершился с ошибкой — удаляю частичный файл и выхожу"
  rm -f "$DUMP_FILE"
  exit 1
fi

# Защита от молчаливых ошибок: проверяем что файл не пустой и валидный gzip
if [[ ! -s "$DUMP_FILE" ]]; then
  log "  ✗ pg_dump создал пустой файл — что-то пошло не так"
  rm -f "$DUMP_FILE"
  exit 1
fi

if ! gzip -t "$DUMP_FILE" 2>>"$LOG"; then
  log "  ✗ pg_dump создал повреждённый gzip — удаляю"
  rm -f "$DUMP_FILE"
  exit 1
fi

DUMP_SIZE=$(du -h "$DUMP_FILE" | cut -f1)
log "  ✓ Дамп сохранён: $DUMP_FILE ($DUMP_SIZE)"

# ─── 2. n8n data volume (binary files, custom nodes) ──────────────
log "→ tar volume msg-zakupki_n8n_data..."

# Путь к docker volume (зависит от storage driver)
VOLUME_PATH=$(docker volume inspect msg-zakupki_n8n_data --format '{{ .Mountpoint }}')

if [[ -z "$VOLUME_PATH" ]] || [[ ! -d "$VOLUME_PATH" ]]; then
  log "  ✗ Volume msg-zakupki_n8n_data не найден — пропускаю tar"
else
  tar czf "$DEST/n8n-data-$DATE.tar.gz" -C "$VOLUME_PATH" . 2>&1 | tee -a "$LOG"
  TAR_SIZE=$(du -h "$DEST/n8n-data-$DATE.tar.gz" | cut -f1)
  log "  ✓ Volume архивирован: $DEST/n8n-data-$DATE.tar.gz ($TAR_SIZE)"
fi

# ─── 3. Загрузка в Yandex Disk через rclone ───────────────────────
log "→ Загрузка в Yandex Disk ($RCLONE_REMOTE)..."

if ! command -v rclone >/dev/null 2>&1; then
  log "  ✗ rclone не установлен — пропускаю off-site копирование"
  log "    Установка: curl https://rclone.org/install.sh | sudo bash"
  log "    Настройка: rclone config (создать remote с именем yandex-disk)"
else
  rclone copy "$DEST/n8n-pg-$DATE.sql.gz" "$RCLONE_REMOTE/" 2>&1 | tee -a "$LOG"
  if [[ -f "$DEST/n8n-data-$DATE.tar.gz" ]]; then
    rclone copy "$DEST/n8n-data-$DATE.tar.gz" "$RCLONE_REMOTE/" 2>&1 | tee -a "$LOG"
  fi
  log "  ✓ Загрузка в Yandex Disk завершена"
fi

# ─── 4. Удаление локальных бэкапов старше N дней ──────────────────
log "→ Очистка локальных бэкапов старше $RETENTION_LOCAL_DAYS дней..."
# КРИТИЧНО: скобки обязательны вокруг -name ... -o -name ..., иначе из-за приоритета операторов
# первая часть будет удалять ВСЕ .sql.gz независимо от возраста
DELETED_LOCAL=$(find "$DEST" \( -name "n8n-*-*.sql.gz" -o -name "n8n-*-*.tar.gz" \) \
  -type f -mtime "+$RETENTION_LOCAL_DAYS" -print -delete | wc -l)
log "  ✓ Удалено $DELETED_LOCAL локальных файлов"

# ─── 5. Удаление в Yandex Disk старше N дней ──────────────────────
if command -v rclone >/dev/null 2>&1; then
  log "→ Очистка Yandex Disk бэкапов старше $RETENTION_REMOTE_DAYS дней..."
  rclone delete --min-age "${RETENTION_REMOTE_DAYS}d" "$RCLONE_REMOTE/" 2>&1 | tee -a "$LOG"
  log "  ✓ Очистка Yandex Disk завершена"
fi

# ─── Финал ────────────────────────────────────────────────────────
log "Бэкап n8n завершён успешно — $DATE"
log "═══════════════════════════════════════════════"

# Telegram-алерт через n8n webhook (опционально, см. README.md §мониторинг)
# curl -fsS -X POST "https://n8n.msgzakupki.ru/webhook/backup-status" \
#   -H "Content-Type: application/json" \
#   -d "{\"status\":\"success\",\"date\":\"$DATE\",\"dump_size\":\"$DUMP_SIZE\"}" \
#   >/dev/null 2>&1 || true
