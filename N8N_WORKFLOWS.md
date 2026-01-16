# N8N Workflows - MSG Закупки

Детальная документация backend архитектуры на n8n workflows.

## Обзор системы

Backend система построена на 5 n8n workflows, развёрнутых на Railway. Workflows обрабатывают API запросы от frontend, взаимодействуют с Supabase для хранения данных и отправляют email через Resend API.

### Схема взаимодействия

```
Frontend (index.html)
    ↓
Railway Webhooks
    ↓
┌─────────────────────────────────────────────────┐
│  1. Web Calculator API v4                       │ → Парсинг файлов (PDF/Excel/Image)
│  2. Supplier Request - Generate Excel           │ → Генерация Excel с позициями
│  3. Send Supplier Request - Email v2            │ → Отправка запросов поставщикам
│  4. IMAP Trigger - Save Incoming Emails         │ → Обработка ответов поставщиков
│  5. Get Supplier Summary v2                     │ → Формирование сводки цен
└─────────────────────────────────────────────────┘
    ↓
Supabase Database
    ↓
Resend API (Email)
```

---

## 1. Web Calculator API v4

**Webhook**: `/webhook/calc-parse`
**Метод**: POST
**Файл**: `Web Calculator API v4.json`

### Назначение
Основной API workflow для парсинга загруженных файлов (Excel, PDF, изображения) и извлечения позиций металла.

### Узлы workflow

1. **Webhook: calc-parse**
   - Принимает файл от frontend
   - Определяет тип файла (Excel/PDF/Image)

2. **Spreadsheet File / Extract from File / AI Vision**
   - Excel: читает строки и колонки
   - PDF: извлекает текст через n8n Extract
   - Image: распознаёт через AI Vision (Claude/GPT)

3. **Code: Parse Positions**
   - Парсит данные и извлекает позиции металла
   - Определяет тип, размер, марку стали, количество
   - Возвращает массив позиций в формате:
     ```json
     {
       "metal_name": "Лист г/к",
       "size": "10",
       "steel": "Ст3сп",
       "pieces": 10,
       "weight": 4.71
     }
     ```

4. **Respond to Webhook**
   - Возвращает распознанные позиции frontend

### Дополнительные endpoints

- `/webhook/calc-parse-file` - альтернативный endpoint для парсинга
- `/webhook/calc-calculate` - расчёт веса для одной позиции
- `/webhook/calc-refs` - получение справочных данных (типы металла из Supabase)

---

## 2. Supplier Request - Generate Excel

**Webhook**: `/webhook/supplier-request`
**Метод**: POST
**Файл**: `Supplier Request - Generate Excel.json`

### Назначение
Генерация Excel файла с позициями заявки для отправки поставщикам.

### Узлы workflow

1. **Webhook: Supplier Request**
   - Принимает данные заявки:
     ```json
     {
       "request_id": "ЗП-20260116-123456789-NN",
       "items": [...],
       "totals": { "weight": 10.5, "positions": 15 }
     }
     ```

2. **Code: Prepare Excel Data**
   - Формирует строки для Excel таблицы
   - Колонки: № | Наименование | Размер | Марка стали | Вес,т | Кол-во,шт | Дл.шт,м | Ширина,м | Дл.листа,м | Цена | Примечания
   - Добавляет итоговую строку с общим весом

3. **Create Excel File** (Spreadsheet File)
   - Конвертирует данные в `.xlsx`
   - Имя файла: `Запрос_ДД.ММ.ГГ_<request_id>.xlsx`
   - Имя листа: "Заявка"

4. **Code: Prepare Response**
   - Извлекает Excel в base64
   - Формирует ответ:
     ```json
     {
       "success": true,
       "request_id": "...",
       "excel_base64": "...",
       "excel_filename": "Запрос_16.01.26_ЗП-20260116-123456789-NN.xlsx",
       "total_weight": "10.500",
       "items_count": 15
     }
     ```

5. **Respond to Webhook**
   - Возвращает JSON с Excel в base64

---

## 3. Send Supplier Request - Email v2

**Webhook**: `/webhook/send-supplier-request`
**Метод**: POST
**Файл**: `Send Supplier Request - Email v2.json`

### Назначение
Отправка запросов поставщикам по email с прикреплённым Excel файлом.

### Узлы workflow

1. **Webhook: Send Request**
   - Принимает данные:
     ```json
     {
       "request_id": "ЗП-20260116-123456789-NN",
       "category": "nn|moscow|factories",
       "items": [...],
       "totals": {...}
     }
     ```

2. **Code: Get Suppliers by Category**
   - Определяет список email поставщиков по категории:
     - `nn` - Нижний Новгород
     - `moscow` - Москва и регионы
     - `factories` - Заводы
   - Возвращает массив email адресов

3. **HTTP Request: Resend API**
   - URL: `https://api.resend.com/emails`
   - Метод: POST
   - Headers: Authorization с API ключом
   - Body:
     ```json
     {
       "from": "МеталлСтройГрупп <zakup@msgnn.ru>",
       "to": ["supplier1@example.com", "supplier2@example.com"],
       "subject": "Заказ ЗП-20260116-123456789-NN | МеталлСтройГрупп",
       "html": "<email_template>",
       "attachments": [{
         "filename": "Запрос_16.01.26_ЗП-20260116-123456789-NN.xlsx",
         "content": "<base64_excel>"
       }]
     }
     ```

4. **Supabase: Insert Request**
   - Сохраняет заявку в таблицу `supplier_requests`:
     ```json
     {
       "request_id": "...",
       "category": "nn",
       "status": "sent",
       "sent_at": "2026-01-16T12:00:00Z",
       "collect_at": "2026-01-17T12:00:00Z",
       "total_weight": 10.5,
       "items_count": 15
     }
     ```

5. **Code: Prepare Response**
   - Возвращает статус отправки

### Email Template

**Тема**: `Заказ ЗП-<timestamp>-<category> | МеталлСтройГрупп`

**HTML шаблон**:
```html
<h2>Запрос на металлопрокат</h2>
<p>Добрый день!</p>
<p>Просим Вас предоставить расценки по прикреплённому файлу Excel.</p>
<p><strong>Номер заявки:</strong> ЗП-20260116-123456789-NN</p>
<p><strong>Общий вес:</strong> 10.500 т</p>
<p><strong>Количество позиций:</strong> 15</p>
<p>Пожалуйста, заполните колонку "Цена" в Excel и отправьте файл обратно, ответив на это письмо.</p>
<p>--<br>С уважением,<br>МеталлСтройГрупп</p>
```

---

## 4. IMAP Trigger - Save Incoming Emails

**Тип**: IMAP Trigger (автоматический)
**Файл**: `IMAP Trigger - Save Incoming Emails.json`

### Назначение
Автоматическая обработка входящих email от поставщиков с ценами.

### Узлы workflow

1. **IMAP: New Email**
   - Триггер: новое письмо на `zakup@msgnn.ru`
   - Скачивает вложения (Excel файлы)

2. **Code: Check Request ID**
   - Ищет `request_id` в теме или теле письма
   - Формат: `ЗП-YYYYMMDD-XXXXXXXXX-CAT`
   - Проверяет наличие Excel вложения
   - Извлекает email отправителя (поставщика)

3. **IF: Has Request ID?**
   - Если нет `request_id` → письмо игнорируется
   - Если есть → обрабатывается дальше

4. **IF: Has Excel?**
   - Если есть Excel → парсим цены
   - Если нет → сохраняем без цен

5. **Spreadsheet: Read Excel**
   - Читает Excel файл от поставщика
   - Извлекает строки с ценами

6. **Code: Parse Prices**
   - Парсит колонку "Цена" из Excel
   - Парсит колонку "Примечания"
   - Формат:
     ```json
     {
       "prices": {
         "1": 45000,
         "2": 52000,
         "3": 38000
       },
       "notes": {
         "1": "В наличии на складе",
         "2": "Под заказ 5 дней"
       }
     }
     ```

7. **Supabase: Insert Response**
   - Сохраняет ответ поставщика в таблицу `supplier_responses`:
     ```json
     {
       "request_id": "ЗП-20260116-123456789-NN",
       "supplier_email": "supplier@example.com",
       "supplier_name": "ООО Металл",
       "received_at": "2026-01-16T14:30:00Z",
       "prices": {...},
       "notes": {...},
       "prices_count": 3,
       "has_all_positions": true
     }
     ```

---

## 5. Get Supplier Summary v2

**Webhook**: `/webhook/get-supplier-summary?request_id=...`
**Метод**: GET
**Файл**: `Get Supplier Summary v2.json`

### Назначение
Формирование сводки лучших предложений по заявке.

### Узлы workflow

1. **Webhook: Get Summary**
   - Принимает query параметр: `request_id`

2. **Supabase: Get Request**
   - Ищет заявку в таблице `supplier_requests` по `request_id`
   - Проверяет статус и время сбора (`collect_at`)

3. **Code: Check Request**
   - Проверяет существует ли заявка
   - Проверяет прошло ли время сбора (24 часа)
   - Если не готово → возвращает время ожидания

4. **IF: Request Exists?**
   - Если нет → возвращает ошибку
   - Если есть → продолжаем

5. **IF: Is Ready?**
   - Если не готово → возвращает статус "waiting"
   - Если готово → формируем сводку

6. **Supabase: Get Responses**
   - Загружает все ответы поставщиков из `supplier_responses`
   - Фильтр: `request_id = ...`

7. **Code: Calculate Best Offers**
   - Для каждой позиции ищет минимальную цену
   - Формирует сравнительную таблицу:
     ```
     № | Наименование | Размер | Лучшая цена | Поставщик | Примечание
     ```

8. **Spreadsheet File: Generate Summary**
   - Создаёт Excel со сводкой
   - Несколько листов:
     - "Лучшие предложения" - сводка минимальных цен
     - "Все предложения" - полная таблица от всех поставщиков
     - "Статистика" - средняя/мин/макс цены по позициям

9. **Respond to Webhook**
   - Возвращает Excel файл со сводкой

---

## Структура базы данных Supabase

### Таблица: `supplier_requests`

Хранит заявки на металлопрокат.

| Поле | Тип | Описание |
|------|-----|----------|
| `id` | uuid | PK, auto-generated |
| `request_id` | text | Уникальный ID заявки (ЗП-YYYYMMDD-XXXXXXXXX-CAT) |
| `category` | text | Категория поставщиков (nn, moscow, factories) |
| `status` | text | Статус (sent, collecting, completed) |
| `sent_at` | timestamp | Время отправки запроса |
| `collect_at` | timestamp | Время когда можно собирать сводку (sent_at + 24h) |
| `total_weight` | numeric | Общий вес заявки (тонны) |
| `items_count` | integer | Количество позиций |
| `created_at` | timestamp | Время создания записи |

**Индексы**:
- Primary: `id`
- Unique: `request_id`

---

### Таблица: `supplier_responses`

Хранит ответы поставщиков с ценами.

| Поле | Тип | Описание |
|------|-----|----------|
| `id` | uuid | PK, auto-generated |
| `request_id` | text | FK → supplier_requests.request_id |
| `supplier_email` | text | Email поставщика |
| `supplier_name` | text | Название компании поставщика |
| `email_subject` | text | Тема письма |
| `email_message_id` | text | ID письма (для дедупликации) |
| `received_at` | timestamp | Время получения ответа |
| `prices` | jsonb | Объект с ценами: {"1": 45000, "2": 52000} |
| `notes` | jsonb | Объект с примечаниями: {"1": "В наличии"} |
| `prices_count` | integer | Количество указанных цен |
| `has_all_positions` | boolean | Все ли позиции оценены |
| `created_at` | timestamp | Время создания записи |

**Индексы**:
- Primary: `id`
- Index: `request_id`
- Index: `supplier_email`
- Unique: `email_message_id` (предотвращает дубликаты)

---

### Таблица: `metal_types`

Справочник типов металла (используется в Web Calculator API).

| Поле | Тип | Описание |
|------|-----|----------|
| `id` | uuid | PK |
| `key` | text | Ключ типа (sheet_hot, pipe_round, etc) |
| `name` | text | Название (Лист г/к, Труба круглая) |
| `category` | text | Категория (листы, трубы, профиль) |

---

## Переменные окружения и credentials

### Supabase
- **URL**: Supabase project URL
- **API Key**: Service role key (для доступа к таблицам)

### Resend API
- **API Key**: Ключ для отправки email
- **From Email**: `zakup@msgnn.ru` (МеталлСтройГрупп)

### IMAP (для получения email)
- **Server**: imap.example.com
- **Port**: 993 (SSL)
- **Email**: zakup@msgnn.ru
- **Password**: [stored in n8n credentials]

### Railway
- **Base URL**: `https://primary-production-4e88.up.railway.app/webhook`

---

## Последовательность работы системы

### 1. Создание и отправка заявки

```
Frontend → /supplier-request → Generate Excel
    ↓
Frontend получает Excel в base64
    ↓
Пользователь скачивает Excel для проверки
    ↓
Frontend → /send-supplier-request → Send Email
    ↓
Resend API отправляет email поставщикам с Excel
    ↓
Запись в supplier_requests (status: sent, collect_at: +24h)
```

### 2. Получение ответов от поставщиков

```
Поставщик отвечает на email с заполненным Excel
    ↓
IMAP Trigger получает новое письмо
    ↓
Извлекает request_id из темы/тела
    ↓
Парсит Excel, извлекает цены
    ↓
Запись в supplier_responses
```

### 3. Формирование сводки

```
Frontend → /get-supplier-summary?request_id=...
    ↓
Проверка: прошло ли 24 часа с отправки?
    ↓
Если да:
  - Загрузить все responses для request_id
  - Сравнить цены по позициям
  - Найти лучшие предложения
  - Сгенерировать Excel со сводкой
    ↓
Вернуть Excel файл frontend
```

---

## Обработка ошибок

### Generate Excel Workflow
- Если items пустой → возвращает ошибку "Нет позиций"
- Если нет request_id → генерирует timestamp-based ID

### Send Email Workflow
- Если категория неизвестна → возвращает ошибку "Unknown category"
- Если Resend API недоступен → логирует ошибку, возвращает статус failed

### IMAP Workflow
- Письмо без request_id → игнорируется (No-Op)
- Excel без цен → сохраняет с prices_count: 0
- Дубликат письма → игнорируется (unique constraint на email_message_id)

### Get Summary Workflow
- Заявка не найдена → возвращает {"exists": false, "error": "request_not_found"}
- Время сбора не пришло → возвращает {"is_ready": false, "remaining_minutes": X}
- Нет ответов → возвращает пустую сводку

---

## Формат request_id

### Структура
```
ЗП-YYYYMMDD-XXXXXXXXX-CAT
```

### Компоненты
- `ЗП` - префикс (Заявка Поставщикам)
- `YYYYMMDD` - дата (20260116)
- `XXXXXXXXX` - timestamp в миллисекундах (9 цифр)
- `CAT` - суффикс категории (опционально):
  - `NN` - Нижний Новгород
  - `MSC` - Москва
  - `FAC` - Factories (Заводы)

### Примеры
```
ЗП-20260116-123456789-NN
ЗП-20260116-987654321-MSC
ЗП-20260116-555555555-FAC
```

---

## Связанные файлы

- [CLAUDE.md](CLAUDE.md) - общая документация проекта
- [README.md](README.md) - описание для пользователей
- [index.html](index.html) - frontend код
- [n8n-workflows/](n8n-workflows/) - JSON файлы workflows
