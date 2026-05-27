# Заметки по HLE-457: Nikolay-Shirokov/cc-1c-skills

## Репо: https://github.com/Nikolay-Shirokov/cc-1c-skills
## Дата: 2026-05-26
## Фокус: промт-инжиниринг и абстракции «как объяснять LLM устройство 1С»

---

## Структура репо

```
.claude/skills/         # 68 скиллов для Claude Code (основная ветка = PowerShell)
docs/                   # спецификации XML + гайды (≈35 файлов)
scripts/switch.py       # переключение платформ (13 платформ)
LICENSE                 # MIT
README.md               # обзор
.claude-plugin/         # плагин-манифест (plugin.json)
.agents/plugins/        # marketplace.json
tests/                  # (папка есть, не изучалась)
```

---

## Состав скиллов (68 штук, 16 групп)

| Группа | Навыки | Назначение |
|---|---|---|
| EPF/ERF | epf-init, epf-build, epf-dump, epf-validate, epf-bsp-init, epf-bsp-add-command, erf-* | Внешние обработки и отчёты |
| Универсальные | template-add/remove, form-add/remove, help-add | Добавление/удаление к любым объектам |
| MXL | mxl-info, mxl-compile, mxl-decompile, mxl-validate | Табличные документы / печатные формы |
| Form | form-info, form-compile, form-edit, form-validate, form-patterns | Управляемые формы |
| Role | role-info, role-compile, role-validate | Роли и права |
| SKD | skd-info, skd-compile, skd-edit, skd-decompile, skd-validate | Схема компоновки данных |
| Meta | meta-info, meta-compile, meta-edit, meta-remove, meta-validate | 23 типа объектов метаданных |
| CF | cf-info, cf-init, cf-edit, cf-validate | Корневые файлы конфигурации |
| CFE | cfe-init, cfe-borrow, cfe-patch-method, cfe-diff, cfe-validate | Расширения (CFE) |
| Subsystem | subsystem-info/compile/edit/validate, interface-edit/validate | Подсистемы и CommandInterface |
| DB | db-list/create/dump-cf/load-cf/dump-xml/load-xml/update/run/load-git | Базы данных 1С |
| Web | web-publish/info/stop/unpublish/test | Публикация и тестирование |
| Утилиты | img-grid | Сетка на изображение |

---

## НАХОДКИ: структура одного скилла

Каждый скилл = папка с:
- `SKILL.md` — основной файл (frontmatter + инструкция для модели)
- `scripts/<name>.ps1` — PowerShell-скрипт (или `.py` в Python-версии)
- `reference/` (в некоторых: child-operations.md, properties-reference.md, json-dsl.md, types-*.md)

**Frontmatter SKILL.md:**
```yaml
---
name: meta-info
description: Анализ структуры объекта метаданных 1С из XML-выгрузки — реквизиты, 
             табличные части, формы, движения, типы. Используй для изучения структуры 
             объектов (вместо чтения XML-файлов напрямую) и как подготовительный шаг 
             при написании запросов и кода, работающего с объектами
argument-hint: <ObjectPath> [-Mode overview|brief|full] [-Name <элемент>]
allowed-tools:
  - Bash
  - Read
  - Glob
---
```

**Как агент подхватывает**: 
- Автоматически по `description` (платформа матчит задачу пользователя к description скилла)
- Явно через слэш-команды: `/meta-info`, `/epf-init` и т.д.
- Плагин-установка: `/plugin marketplace add`

---

## НАХОДКИ: промт-инжиниринг — ключевые приёмы

### 1. Ключевая анти-выдумка формулировка (meta-compile/SKILL.md):
> "Эта инструкция и reference-файлы — **полная документация для генерации. Не ищи примеры XML в выгрузках конфигураций.**"

Это прямой аналог нашего "отвечай только из источника". Модели явно запрещается брать XML-примеры из реальных файлов конфигурации — только из документации скилла.

### 2. Абстракция через "вместо":
В description скиллов:
- `form-info`: "**Заменяет чтение тысяч строк XML**"
- `meta-info`: "Используй **вместо чтения XML-файлов напрямую**"
- Общая позиция README: "дать модели готовые абстракции над XML-форматами... чтобы работать с **сутью задачи**, а не с деталями реализации"

### 3. Указание контекста использования в description:
- `form-info`: "Используй для понимания формы — **при написании модуля формы, анализе обработчиков и элементов**"
- `meta-info`: "Используй **как подготовительный шаг при написании запросов и кода**"
- `form-patterns`: "Вызывай **перед** проектированием формы через `/form-compile`, когда требования пользователя не детализируют расположение элементов"
- `cf-info`: "Используй для обзора конфигурации — **какие объекты есть, сколько их, какие настройки**"

### 4. Явный рабочий цикл (meta-guide.md):
> "Описание объекта (текст) → JSON DSL → /meta-compile → XML-исходники → /meta-validate"

Модели показывают не просто инструменты, а **порядок их использования**.

### 5. Управление детализацией (режимы overview/brief/full + drill-down):
- `meta-info`: overview (default), brief, full
- `-Name` — drill-down в конкретный элемент
- Пагинация: `-Limit 150 -Offset N`
- Это управление токенами: не грузить всё сразу, брать нужный уровень детали

### 6. Паттерны вместо правил (form-patterns):
Вместо абстрактных правил — конкретные архетипы с именованными компонентами:
```
Форма документа:
Шапка (horizontal, 2 колонки)
├─ Левая: НомерДата (H: Номер + Дата "от"), Контрагент, Договор
├─ Правая: Организация, Подразделение, ЦеныИВалюта
```

### 7. Конвенции именования в таблицах (form-patterns):
| Назначение | Имя | Тип |
|---|---|---|
| Шапка | `ГруппаШапка` | horizontal |
| Левая колонка | `ГруппаШапкаЛевая` | vertical |
| Обработчик OnChange | `<Поле>ПриИзменении` | — |

### 8. Shorthand синтаксис вместо JSON (meta-compile):
```
"ИмяРеквизита: Тип | req, index"
"Товары: Ном: CatalogRef.Ном, Кол: Число(15,3)"
```
Сначала shorthand, потом полный JSON для сложных случаев. Облегчает генерацию без ошибок.

### 9. Batch через `;;`:
```
-Value "Комментарий: Строка(200) ;; Сумма: Число(15,2)"
```
Несколько операций в одном вызове — сокращает количество шагов.

### 10. Русские синонимы ключей в DSL:
JSON поддерживает русские синонимы: `реквизиты`, `тч`, `измерения` — облегчает работу с кириллическими именами.

---

## НАХОДКИ: абстракции над XML конфигурации

### Сводный индекс 1c-specs-index.md — прямо переиспользуемый артефакт

**Полная таблица соответствий**: XML-элемент → каталог → русское название → ссылка на спецификацию

#### Категоризация (8 групп):
1. **Служебные и интерфейсные**: Language, Subsystem, StyleItem, Style, CommandGroup
2. **Общие объекты**: CommonPicture, SessionParameter, Role, CommonTemplate, FilterCriterion, CommonModule, CommonAttribute, CommonCommand, CommonForm
3. **Интеграция и сервисы**: ExchangePlan, XDTOPackage, WebService, HTTPService, WSReference, IntegrationService
4. **Поведение и параметризация**: EventSubscription, ScheduledJob, SettingsStorage, FunctionalOption, FunctionalOptionsParameter, DefinedType, Constant
5. **Прикладные объекты**: Catalog, Document, DocumentNumerator, Sequence, DocumentJournal, Enum, Report, DataProcessor
6. **Регистры**: InformationRegister, AccumulationRegister, AccountingRegister, CalculationRegister
7. **Планы**: ChartOfCharacteristicTypes, ChartOfAccounts, ChartOfCalculationTypes
8. **Бизнес-процессы**: BusinessProcess, Task

**Всего 44 типа в Configuration.xml ChildObjects** (из 1c-configuration-spec.md).

### 1c-config-objects-spec.md — детальная структура объекта

Таблица модулей по типам (кто имеет ObjectModule/ManagerModule/RecordSetModule):
| Тип | ObjectModule | ManagerModule | RecordSetModule |
|---|---|---|---|
| Справочник | + | + | - |
| Документ | + | + | - |
| Регистры | - | + | + |
| Перечисление | - | + | - |

Полный список каталогов верхнего уровня выгрузки (из 1c-config-objects-spec.md, строки 18-64):
Catalogs, Documents, InformationRegisters, AccumulationRegisters, AccountingRegisters, CalculationRegisters, ChartsOfAccounts, ChartsOfCharacteristicTypes, ChartsOfCalculationTypes, BusinessProcesses, Tasks, ExchangePlans, DocumentJournals, Enums, Reports, DataProcessors, Constants, CommonModules, CommonAttributes, CommonCommands, CommonForms, CommonPictures, CommonTemplates, CommandGroups, DefinedTypes, DocumentNumerators, EventSubscriptions, FilterCriteria, FunctionalOptions, FunctionalOptionsParameters, HTTPServices, Languages, Roles, ScheduledJobs, SessionParameters, SettingsStorages, StyleItems, Styles, Subsystems, WebServices, WSReferences, XDTOPackages

### Структура каталога объекта (meta-guide.md):
```
<MetaType>/<ObjectName>/
├── <ObjectName>.xml         # основное определение
├── Ext/
│   ├── ObjectModule.bsl
│   ├── ManagerModule.bsl
│   ├── Predefined.xml
│   └── Flowchart.xml (бизнес-процессы)
├── Forms/<ИмяФормы>/Ext/Form.xml
├── Templates/<ИмяМакета>/Ext/Template.xml
└── Commands/
```

### DSL-абстракции (ключевое):
- **Meta DSL** (meta-dsl-spec.md): JSON → 23 типа объектов метаданных. Система типов с DSL↔XML маппингом. Автогенерация синонимов из CamelCase.
- **Form DSL** (form-dsl-spec.md): JSON → Form.xml. Архетипы форм + конвенции.
- **SKD DSL** (skd-dsl-spec.md): JSON → DataCompositionSchema.xml
- **MXL DSL** (mxl-dsl-spec.md): JSON → SpreadsheetDocument.xml
- **Role DSL** (role-dsl-spec.md): JSON → Rights.xml

---

## НАХОДКИ: категоризация по типам

### 23 поддерживаемых типа в meta-* скиллах:
**Прикладные**: Catalog, Document, Enum, ChartOfCharacteristicTypes, ChartOfAccounts, ChartOfCalculationTypes
**Процессы**: BusinessProcess, Task
**Регистры**: InformationRegister, AccumulationRegister, AccountingRegister, CalculationRegister
**Отчёты/обработки**: Report, DataProcessor
**Интеграция**: ExchangePlan, HTTPService, WebService
**Журналы**: DocumentJournal, Sequence
**Прочие**: Constant, CommonModule, SessionParameter, FunctionalOption, DefinedType

Это НЕ полный список 44 типов Configuration.xml — сознательно ограниченный subset.

### В meta-info SKILL.md — более компактная классификация:
> **Ссылочные:** Справочник, Документ, Перечисление, Бизнес-процесс, Задача, План обмена, План счетов, ПВХ, ПВР
> **Регистры:** Регистр сведений, Регистр накопления, Регистр бухгалтерии, Регистр расчёта
> **Сервисные:** Отчёт, Обработка, HTTP-сервис, Веб-сервис, Общий модуль, Регламентное задание, Подписка на событие
> **Прочие:** Константа, Журнал документов, Определяемый тип

Интересно: в SKILL.md (на русском) используется слово "Ссылочные" вместо "Прикладные" — другая точка зрения на группировку.

---

## НАХОДКИ: что НЕ брать

1. **CLI-скрипты** (scripts/*.ps1, scripts/*.py) — заточены под разработку, работают с файловой системой
2. **Инфраструктурные скиллы**: db-*, web-* — для CI/CD и деплоя, нам не нужны
3. **Компиляторы XML** (meta-compile, form-compile, mxl-compile и т.д.) — создают XML-файлы, не применимо к MCP-консультанту
4. **web-test** — тестирование через браузер (Playwright), не наша область
5. **switch.py** — инструмент сборки, не промт-инжиниринг
6. **Формат `.claude/skills/`** — подключение в другую архитектуру, у нас MCP

---

## ДОПОЛНИТЕЛЬНЫЕ НАБЛЮДЕНИЯ

1. **Версии платформы в спецификациях**: явно указаны версии 2.17 (8.3.20-8.3.24) и 2.20 (8.3.27+). Источники: ERP 2, Бухгалтерия предприятия, платформы 8.3.20/8.3.24/8.3.27. Это ценно для Азимута — у нас может быть другая версия.

2. **Рабочий цикл meta**: Описание → JSON DSL → /meta-compile → XML → /meta-edit → /meta-validate → /meta-info. Линейный workflow с явными точками входа.

3. **form-patterns — справочник паттернов** — сильная идея. Это не инструкция "как делать", а готовые архетипы с именами компонентов. Можно адаптировать для нашего контракта.

4. **allowed-tools в frontmatter** — модели явно ограничивают набор инструментов на скилл. web-test разрешает всё, meta-info — только Bash/Read/Glob.

5. **Наличие SKD в спецификациях**: 1c-dcs-spec.md — "930 схем проанализировано" — это эмпирическая база, не догадки.

6. **Разграничение с HLE-317**: форматы XML в docs/ — это именно то, что нужно HLE-317 (завендорить спеки). Наша задача — как эти форматы объяснены модели (через DSL-абстракции, shorthand-синтаксис, meta-info команды).

7. **README.md миссия**: "Навыки дают модели готовые абстракции над XML-форматами и CLI конфигуратора — чтобы работать с сутью задачи, а не с деталями реализации." — ключевая формулировка проектной идеи.

8. **Автоактивация** по description — интересная архитектурная идея: не нужно знать имя скилла, достаточно описать задачу.
