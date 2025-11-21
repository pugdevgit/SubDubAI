# UI Описание приложения Speech2Subs

## Обзор интерфейса

**Speech2Subs** - нативное macOS приложение с современным SwiftUI интерфейсом для конвертации видео в субтитры. Приложение следует принципам macOS Human Interface Guidelines и использует NavigationSplitView для создания классического трехпанельного интерфейса.

---

## Архитектура интерфейса

### Основная структура

```
┌─────────────────────────────────────────────────────────┐
│  MainView (NavigationSplitView)                         │
├───────────────┬─────────────────────────────────────────┤
│   Sidebar     │           Detail View                   │
│   (200-250px) │                                         │
│               │                                         │
│   Navigation  │      Content Area                       │
│   List        │      (динамический контент)             │
│               │                                         │
└───────────────┴─────────────────────────────────────────┘
```

---

## 1. Главное окно (MainView)

### Структура
- **Тип:** NavigationSplitView
- **Размер:** Адаптивный, заполняет все окно
- **Заголовок:** "Speech2Subs"

### Компоненты
1. **Sidebar** - левая боковая панель навигации
2. **Detail View** - основная область контента (справа)
3. **Toolbar** - кнопки действий (шестеренка, мастер настройки)

### Toolbar кнопки
- **Setup Wizard** (`wand.and.stars`) - запуск мастера первоначальной настройки
- **Settings** (`gear`) - открытие окна настроек

---

## 2. Sidebar (боковая панель)

### Секции навигации

#### Home Section
- **Home** (`house`) - главная страница приветствия

#### Tasks Section
- **All Tasks** (`film`) - все задачи с счетчиком
- **Queue** (`clock`) - задачи в очереди с счетчиком
- **Active** (`play.circle`) - активные задачи (синий счетчик)
- **Completed** (`checkmark.circle`) - завершенные задачи (зеленый счетчик)
- **Errors** (`exclamationmark.triangle`) - ошибки (красный счетчик)

#### Logs Section
- **Logs** (`doc.text`) - просмотр логов приложения

### Визуальные особенности
- Счетчики справа от каждого пункта
- Цветовое кодирование: синий (активные), зеленый (завершенные), красный (ошибки)
- Стиль: `.sidebar`

---

## 3. Detail View (область контента)

Динамически меняется в зависимости от выбранного пункта в Sidebar.

### 3.1 Home View (главная страница)

#### Элементы
- **Заголовок:** "Speech2Subs" (largeTitle, bold)
- **Подзаголовок:** "Convert videos to subtitles" (title3, secondary)
- **Иконка:** `film.stack` (80pt, синяя)
- **Текст:** "Add video files to get started" (headline)

#### Кнопки действий
1. **Add Files** (`plus.circle`)
   - Стиль: `.borderedProminent`
   - Действие: выбор видеофайлов
   
2. **Add Folder** (`folder.badge.plus`)
   - Стиль: `.bordered`
   - Действие: выбор папки с видео

#### Состояния
- Индикатор загрузки при добавлении файлов
- Блокировка кнопок во время операции

---

### 3.2 Task List View (список задач)

#### Фильтры
- All - все задачи
- Queued - в очереди
- Active - в процессе
- Completed - завершенные
- Failed - с ошибками

#### Компоненты списка
- **TaskRowView** - строка задачи
- **Empty state** - пустое состояние с иконкой и текстом

#### Toolbar
- **Clear Completed** (`trash`) - для завершенных задач

#### Пустое состояние
- Иконка соответствует типу фильтра
- Текст: "No {filter_type}"

---

### 3.3 Task Row (строка задачи)

#### Верхний ряд
- **Иконка статуса** - цветная, динамическая
- **Имя файла** (headline, ограничение в 1 строку)
- **Статус** (caption, secondary) - справа

#### Progress Bar (для активных задач)
- Линейный индикатор прогресса
- Процент выполнения (caption2, secondary)

#### Информация о файле
- **Размер файла** (`doc`)
- **Время выполнения** (`clock`)

#### Кнопки действий (справа)
- **Play** (`play.circle`) - для pending задач
- **Stop** (`stop.circle`) - для активных задач
- **Delete** (`trash`) - всегда доступна (destructive)

---

### 3.4 Task Detail View (детальный вид задачи)

#### Структура (ScrollView)

##### 1. Task Header
- **Иконка:** `film` (title, blue)
- **Имя файла** (title2, bold)
- **Размер файла** (subheadline, secondary)
- **Путь к файлу** (caption, truncated)
- **Дата создания** (shortDateTime)

##### 2. Task Status
- **Заголовок:** "Status" (headline)
- **Иконка статуса** (title2, цветная)
- **Название статуса** (title3, semibold)
- **Текущий этап** (caption) - для активных
- **Время выполнения** (headline)

###### Progress (для активных)
- Линейный прогресс-бар
- Процент завершения
- ETA (расчетное время)
- Детали (опционально)

###### Error (для ошибок)
- Красный блок с сообщением об ошибке
- Иконка `exclamationmark.triangle.fill`

##### 3. Task Configuration
- **Заголовок:** "Configuration" (headline)
- **Grid layout:**
  - Recognition Language
  - Whisper Model
  - Subtitle Format
  - Target Languages (если есть)
  - Output Directory (caption, truncated)

##### 4. Task Output
- **Заголовок:** "Output Files" (headline)

###### Для завершенных задач:
- **Original subtitle** - оригинальные субтитры
- **Translated files** - переведенные версии (если есть)

###### Output File Row:
- Иконка `doc.text`
- Название (язык)
- Имя файла (caption, secondary)
- Кнопка **Show in Finder** (`arrow.right.circle`)

###### Пустое состояние:
- "No output files yet"

##### 5. Task Actions
- **Заголовок:** "Actions" (headline)

###### Кнопки:
- **Start Processing** (`play.fill`) - для pending
- **Cancel** (`stop.fill`) - для активных
- **Retry** (`arrow.clockwise`) - для failed
- **Delete** (`trash`) - всегда (destructive)

---

### 3.5 Log View (просмотр логов)

#### Структура

##### Log Toolbar
- **Level Filter** - выбор уровня логирования
  - All (все)
  - Debug, Info, Warning, Error, Critical
  - Width: 150px
  
- **Search Field** - поиск по логам
  - Placeholder: "Search logs..."
  - Иконка: `magnifyingglass`
  - Кнопка очистки: `xmark.circle.fill`
  
- **Actions:**
  - **Clear** (`trash`) - очистка логов
  - **Export** (`square.and.arrow.up`) - экспорт в файл

##### Log List
- **List style:** `.plain`
- **Разделители:** видимые

##### Log Entry Row
- **Level icon** - эмодзи (title3)
- **Timestamp** (caption, 80px)
- **Component** (caption, 120px, truncated)
- **Message** (callout, expandable)
- **Expand button** (`chevron.up`/`chevron.down`) - если есть детали

###### Expanded Details:
- **Metadata** - ключ-значение (caption)
- **Error** - сообщение об ошибке (красный текст)

###### Background Colors (уровни):
- Debug: transparent
- Info: blue opacity 0.05
- Warning: orange opacity 0.1
- Error: red opacity 0.1
- Critical: purple opacity 0.1

##### Empty State
- Иконка: `doc.text.magnifyingglass` (60pt)
- Текст: "No logs found"
- Подсказка: "Logs will appear here as the app runs"

##### Export
- File exporter с именем: `speech2subs-logs-{timestamp}.txt`
- Формат: plain text

---

## 4. Settings View (настройки)

### Структура
- **Тип:** TabView
- **Размер:** 600x500px
- **Tabs:** 4 вкладки

### Toolbar
- **Cancel** - отмена изменений
- **Save** - сохранение (disabled при сохранении)

### Success Overlay
- Зеленое сообщение внизу: "Settings saved successfully"

---

### 4.1 General Tab (Общие)

#### Sections

##### Output
- **Default Format** - Picker
  - WebVTT (.vtt)
  - SubRip (.srt)
  
- **Recognition Language** - Picker
  - Список всех языков распознавания

##### Cleanup
- **Auto-cleanup temporary files** - Toggle
- **Keep temporary audio files** - Toggle (disabled если auto-cleanup)
- **Auto-delete completed** - Stepper (0-90 дней)
  - Подсказка: "Set to 0 to never auto-delete"

##### Interface
- **Show detailed progress** - Toggle

---

### 4.2 Processing Tab (Обработка)

#### Sections

##### Performance
- **Parallel tasks** - Stepper (1-8)
  - Подсказка: "Number of files to process simultaneously (1-8)"

##### Speech Recognition
- **Default Whisper Model** - Picker
  - tiny, base, small, medium, large
  - Описание модели (размер, скорость)

##### Translation
- **Default Target Languages** - Multiple toggles
  - Список всех языков перевода
  - Multiple selection

##### Error Handling
- **Max retry attempts** - Stepper (1-10)

---

### 4.3 Paths Tab (Пути)

#### Sections

##### Executables

###### FFmpeg Path
- **Label:** "FFmpeg Path"
- **TextField** - путь
- **Browse button**
- **Status indicator:**
  - ✓ Found (green) - если файл существует
  - ✗ Not found (red) - если отсутствует

###### Whisper Path
- Аналогично FFmpeg

##### Directories

###### Whisper Models Directory
- **Label:** "Whisper Models Directory"
- **TextField** - путь
- **Browse button**

###### Default Output Directory
- **Label:** "Default Output Directory"
- **TextField** - путь
- **Browse button**

##### Actions
- **Reset to Defaults** - сброс к значениям по умолчанию

---

### 4.4 Docker Tab

#### Sections

##### LibreTranslate Service
- **Service URL** - TextField
  - Placeholder: "http://localhost:5000"
  - Подсказка: "Default: http://localhost:5000"
  
- **Auto-start Docker on app launch** - Toggle
  - Подсказка: "Automatically start LibreTranslate container when the app launches"

##### Information
- Информационные сообщения:
  - "LibreTranslate is required for subtitle translation."
  - "Make sure Docker Desktop is installed and running."
  - "Start the service with:"
  - Команда (monospaced): `docker-compose -f Docker/docker-compose.yml up -d`

---

## 5. Setup Wizard (мастер настройки)

### Структура
- **Тип:** Modal sheet
- **Размер:** 700x550px
- **Шаги:** 4

### Навигация
- **Progress bar** - линейный индикатор
- **Step indicator** - "Step X of 4"
- **Back button** - доступна с шага 2
- **Next button** - переход к следующему шагу
- **Finish button** - на последнем шаге

---

### 5.1 Step 1: Welcome

#### Элементы
- **Иконка:** `wand.and.stars` (60pt, blue)
- **Заголовок:** "Welcome to Speech2Subs" (largeTitle, bold)
- **Подзаголовок:** "Let's set up your application" (title3, secondary)

#### Features List
1. **Video to Subtitles** (`video`)
   - Description: "Extract audio and generate subtitles"

2. **Speech Recognition** (`waveform`)
   - Description: "Powered by Whisper AI"

3. **Translation** (`globe`)
   - Description: "Translate to multiple languages"

4. **Multiple Formats** (`doc.text`)
   - Description: "SRT, VTT, and more"

---

### 5.2 Step 2: Paths Configuration

#### Заголовок
- **Title:** "Configure Paths" (title, bold)
- **Subtitle:** "Set up the paths to required tools and directories" (subheadline, secondary)

#### Form Fields

##### Path Field Components
- **Icon** - синяя иконка (20pt)
- **Label** (headline)
- **TextField** - путь
- **Browse button**

##### Fields:
1. **FFmpeg** (`film`)
2. **Whisper** (`waveform`)
3. **Models Directory** (`folder`)
4. **Output Directory** (`folder.badge.plus`)

---

### 5.3 Step 3: Validation

#### Заголовок
- **Title:** "Validation" (title, bold)

#### States

##### Validating
- ProgressView: "Validating configuration..."

##### Validation Complete

###### Summary Card
- **Icon:** ✓ (green) или ✗ (red)
- **Title:** "Configuration Valid" / "Configuration Issues Found"
- **Error count** (красный)
- **Warning count** (оранжевый)
- **Background:** зеленый/красный с opacity 0.1

###### Validation Results
- Список результатов для каждого компонента
- **ValidationResultRow:**
  - Icon (цветная)
  - Component name (headline)
  - Message (subheadline, secondary)
  - Suggestion (опционально, blue, с `lightbulb`)
  - Background color по severity

##### Action
- **Validate Again** - повторная валидация

---

### 5.4 Step 4: Completion

#### Элементы
- **Иконка:** `checkmark.circle.fill` (60pt, green)
- **Заголовок:** "Setup Complete!" (largeTitle, bold)
- **Подзаголовок:** "Your application is ready to use" (title3, secondary)

#### Next Steps (numbered list)
1. "Add video files using the + button"
2. "Configure processing options"
3. "Start processing and generate subtitles"

##### Next Step Row
- **Number badge** - синий круг с номером
- **Text** - описание шага

---

## 6. Цветовая схема и иконография

### Статусы задач

| Статус | Иконка | Цвет |
|--------|--------|------|
| Pending | `clock` | secondary (серый) |
| Extracting Audio | `waveform` | blue |
| Transcribing | `text.bubble` | blue |
| Formatting | `doc.text` | blue |
| Translating | `globe` | blue |
| Completed | `checkmark.circle.fill` | green |
| Failed | `xmark.circle.fill` | red |
| Cancelled | `stop.circle` | orange |

### Уровни логов

| Level | Icon | Color |
|-------|------|-------|
| Debug | (emoji) | - |
| Info | (emoji) | blue |
| Warning | (emoji) | orange |
| Error | (emoji) | red |
| Critical | (emoji) | purple |

### Основные действия

| Действие | Иконка | Стиль кнопки |
|----------|--------|--------------|
| Add Files | `plus.circle` | `.borderedProminent` |
| Add Folder | `folder.badge.plus` | `.bordered` |
| Start | `play.circle` / `play.fill` | `.borderedProminent` |
| Stop | `stop.circle` / `stop.fill` | `.bordered` |
| Delete | `trash` | `.borderless` (destructive) |
| Settings | `gear` | - |
| Setup Wizard | `wand.and.stars` | - |

---

## 7. Типографика

### Размеры текста
- **largeTitle** - главные заголовки
- **title** - заголовки страниц
- **title2** - заголовки карточек
- **title3** - подзаголовки
- **headline** - метки и важный текст
- **subheadline** - вторичная информация
- **body** - основной текст
- **callout** - элементы списков
- **caption** - мелкая информация
- **caption2** - очень мелкая информация

### Веса шрифта
- **bold** - главные заголовки
- **semibold** - важные элементы
- **regular** - обычный текст

### Цвета текста
- **primary** - основной текст (по умолчанию)
- **secondary** - вторичный текст (.foregroundStyle(.secondary))
- **colored** - цветной текст (blue, green, red, orange)

---

## 8. Компоненты взаимодействия

### Кнопки
- **borderedProminent** - главные действия (синие)
- **bordered** - вторичные действия
- **borderless** - иконочные кнопки в списках
- **plain** - минимальные кнопки

### Формы
- **Form** - контейнер для настроек
- **Section** - группировка элементов
- **LabeledContent** - метка + контрол
- **Grid** - табличная разметка

### Пикеры
- **menu** - выпадающее меню
- **labelsHidden** - скрытие системных меток

### Индикаторы
- **ProgressView** - прогресс
  - `.linear` - линейный стиль
- **Toggle** - переключатель
- **Stepper** - числовой ввод

---

## 9. Состояния интерфейса

### Loading States
- **isAddingFiles** - добавление файлов
- **isSaving** - сохранение настроек
- **isValidating** - валидация конфигурации

### Empty States
- Home (начальное состояние)
- Task List (пустой список)
- Logs (нет логов)

### Error States
- Task errors (красный блок)
- Validation errors (красная иконка и текст)
- Alert dialogs

### Success States
- Settings saved (зеленое сообщение)
- Setup complete (зеленая галочка)
- Validation passed (зеленая иконка)

---

## 10. Адаптивность и accessibility

### Размеры
- Sidebar: min 200px, ideal 250px
- Settings window: 600x500px
- Setup wizard: 700x550px
- Main window: адаптивный

### Keyboard shortcuts
- **⌘R** - запуск в Xcode
- **⌘U** - тесты
- **.defaultAction** - Enter (Next/Finish)
- **.cancelAction** - Esc (Back/Cancel)

### Help tooltips
- Setup Wizard button: "Setup Wizard"
- Settings button: "Settings"
- Clear logs: "Clear all logs"
- Export logs: "Export logs to file"
- Show in Finder: "Show in Finder"

---

## 11. Анимации

### Transitions
- Переходы между шагами мастера: `.easeInOut`
- Раскрытие деталей логов: `withAnimation`

### Visual Feedback
- Hover states на кнопках
- Selection highlighting
- Progress animations

---

## Итого

Интерфейс **Speech2Subs** представляет собой классическое macOS приложение с:
- ✅ NavigationSplitView архитектурой
- ✅ Современным SwiftUI дизайном
- ✅ Следованием HIG guidelines
- ✅ Интуитивной навигацией
- ✅ Детальным отображением информации
- ✅ Удобным мастером настройки
- ✅ Гибкими настройками
- ✅ Системой логирования

Все элементы интерфейса соответствуют современным стандартам macOS и обеспечивают удобный пользовательский опыт.
