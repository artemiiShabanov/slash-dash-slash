# slash-dash-slash: рабочие заметки для Claude

Перед дизайном читай `docs/GDD.md`, перед планированием `docs/PLAN.md` (сгенерирован из `docs/plan.yaml`).
Решения, принятые в чате, в тот же день попадают в журнал `docs/DESIGN.md`. Общий процесс всех проектов:
gamedev-hub/WORKFLOW.md.

## Layout

- `slash-dash-slash/` проект Godot 4.4, GDScript, рендерер `mobile`:
  `scenes/` (главная `equipment_selection.tscn`; `scenes/demos/` тест-сцены вех, `scenes/ui/`, `scenes/interaction/`),
  `scripts/` (`scripts/resources/` классы тюнинг-ресурсов, `scripts/gems/`, `scripts/abilities/`, `scripts/debug/`),
  `resources/` (тюнинг-числа как `.tres`, ростеры в `equipment/`, `gems/`, `abilities/`), `assets/` (audio, fonts, shaders).
- `docs/` GDD, журнал решений `DESIGN.md`, план (`plan.yaml` источник, `PLAN.md` генерируется),
  `ROADMAP.md` (порядок спек по вехам), `specs/` (одна спека на систему, шаблон `_template.md`).
- `tools/sync_plan.py` зеркалит план в GitHub (метки, вехи, issues).
- `.claude/commands/` команды спек-цикла `/spec` `/build` `/sync`; `.claude/skills/` next-task, sync-plan, playtest.

## Verification loop

- Godot: `/Applications/Godot.app/Contents/MacOS/Godot`. Редактор: `--path slash-dash-slash -e`.
  После добавления ассетов: `--path slash-dash-slash --headless --import`.
- Система проверяется в своей демо-сцене: `Godot --path slash-dash-slash res://scenes/demos/m3_combat_demo.tscn`
  (сцены `m1_input_demo`, `m1_style_smoke`, `m2_dash_demo`, `m3_combat_demo`). Главная сцена: выбор снаряжения → бой.
- Автотеста (`-- --auto-test`, печатает `END ok`) пока нет; завести вместе с базовой сценой уровня в M1.
- Перед коммитом: нет ошибок в выводе Godot, демо-сцена играется, спека системы отражает код.

## Workflow (Spec-Driven)

Три слоя, у каждого свой ритм:

- **`docs/GDD.md`** — видение (пилларсы, core loop, тон, non-goals). Читать первым, когда контекст неясен.
- **`docs/specs/<system>.md`** — спека системы: *что и почему*. Читать нужную спеку до правок системы.
  Когда писать спеку, см. `docs/specs/README.md`.
- **`slash-dash-slash/resources/*.tres`** — все тюнинг-числа (величины, длительности, множители) живут здесь
  как Godot Resources. Никогда не хардкодить тюнинг в скриптах сцен.

Цикл ведут слэш-команды:

- **`/spec <name>`** — черновик через интервью в `docs/specs/<name>.md` (статус `Draft`). Кода не пишет.
- **`/build <spec>`** — реализует спеку целиком под `slash-dash-slash/`, отмечает чекбоксы задач, заканчивает статусом `Shipped`.
- **`/sync <spec>`** — сводит дрейф после ручного тюнинга и правок; меняет только спеку (после шипа код первичен).

Спеки описывают *что и почему*, код *как*, ресурсы хранят *числа*. Правка `.tres` не делает спеку устаревшей.
Статусы: `Draft` → `Building` → `Shipped` → `Synced YYYY-MM-DD`.

## Process

1. Взять issue (`/next-task` подсказывает из текущей вехи). Нужно дизайн-решение: бриф в issue
   (вопрос, 2-3 варианта, рекомендация), метка `status: needs decision`, ждать Артемия.
2. Если задача трогает систему со спекой или заводит новую: `/spec` для новой, `/build` для реализации,
   `/sync` после ручных правок. Мелочь без спеки идёт прямо из issue.
3. Реализация на `main`, небольшие коммиты, сообщение ссылается на issue (`#12`). Пуш в конце сессии.
4. Играбельно: метка `status: needs playtest`, комментарий что пробовать и в какой сцене. Артемий играет
   и закрывает; `/playtest` раскладывает его заметки по issues и DESIGN.md.
5. Definition of done: Godot без ошибок, скриншот или замер в issue, спека `Shipped`/`Synced`, журнал решений обновлён.
6. Правка плана: `docs/plan.yaml`, затем `python3 tools/sync_plan.py --github` (`/sync-plan`). Issues закрываются
   на GitHub, не в yaml. Переименовывать задачу только одновременно в yaml и на GitHub, иначе будет дубликат.

## Conventions

- GDScript со статической типизацией; `var x := f()` падает, если `f` возвращает Variant.
- `snake_case` функции и переменные, `PascalCase` классы и ноды, `@export` для полей, настраиваемых в редакторе,
  сигналы вверху скрипта.
- Тюнинг-числа только в `resources/*.tres` через Resource-класс с `class_name` в `scripts/resources/`, не в коде сцен.
- Тексты в игре на английском, документы, issues и журнал решений на русском.
- Трейлер коммита: `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
