# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Что это

Hugo-сайт частной строительной бригады (`bagaew.ru`), деплой на GitHub Pages. Полностью русскоязычный (`languageCode = 'ru'`). Тема не используется — все шаблоны и стили в проекте.

## Команды

```bash
# Быстрый запуск dev-сервера (порт 1313) — использует существующий кэш resources/_gen/
make hugo_serve            # hugo server --disableFastRender --port 1313

# Полный запуск со сбросом кэша — пересоздаёт все image variants заново (долго при первом старте)
make hugo_serve_clean      # clean + hugo_serve

# Просто очистить кэш Hugo Image Processing и public/, без запуска сервера
make clean                 # rm -rf resources/_gen public

# Продакшн-сборка в ./public
make pd                    # rm -rf public/* && hugo

# Создать новый раздел верхнего уровня (название кириллицей транслитерируется в slug)
make section "Название раздела"

# Создать новый пост на верхнем уровне
make newpost "Название поста"

# Быстрый коммит-пуш (commit message = аргумент после gp)
make gp "сообщение коммита"
```

**Когда использовать `hugo_serve_clean` vs `hugo_serve`:** обычная разработка — `hugo_serve` (после первого прогрева быстрый). Если поменяли исходник cover/hero и Hugo не подхватывает — `hugo_serve_clean` один раз. Первый запуск с пустым кэшем медленный (минуты): на каждом cover Hugo генерирует множество WebP/JPG-вариантов разных ширин + LQIP. Это нормально.

CI: `.github/workflows/hugo.yml` собирает на Hugo **extended 0.128.0** при push в `main` и публикует через `actions/deploy-pages`. **Extended обязателен** — нужен для генерации WebP через Image Processing. **AVIF не поддерживается** этой сборкой Homebrew/CI (нет libavif).

## Архитектура контента

Контент разбит на четыре типа верхнеуровневых разделов:

1. **Одиночные страницы услуг** (`content/proekt.md`, `smeta.md`, `planirovka.md`) — рендерятся через **специализированные layout'ы** в `layouts/page/{proekt,smeta,planirovka}.html`. У каждой свой кастомный шаблон, выбираемый через `layout:` во front matter или соглашение Hugo `_default/<type>`. При добавлении новой такой страницы нужен соответствующий файл в `layouts/page/`. Изображений в этих шаблонах нет — hero у них чисто текстовый.

2. **Разделы работ** (`content/{fundament,steny,krovlya}/`) — список (`_index.md`) + дочерние страницы по типам (`lentochnyy.md`, `gazobeton.md` и т.п.). Рендерятся через общий `layouts/_default/list.html` и `single.html`, которые **ветвятся по `.Type` (не `.Section`!)** — см. секцию «Hugo .Type vs .Section» ниже.
   - В `list.html` для секций `fundament` / `steny` / `krovlya` / `gotovye-proekty` / `gotovye-fundamenty` отдельные блоки HERO, заголовков и сеток.
   - Для `steny` страницы группируются по `Params.group` со значениями ровно `"Каркас"`, `"Деревянные"`, `"Каменные и монолит"` — front matter дочерних страниц должен содержать одно из этих значений, иначе страница не попадёт в сетку. Дополнительно ожидается `group_weight` для сортировки групп: `1` (Каркас), `2` (Деревянные), `3` (Каменные и монолит).
   - Для `fundament` сетка использует `range .RegularPages` (а не `.Pages`), чтобы подсекция `gotovye-fundamenty/` не попадала в сетку типов фундамента отдельной карточкой.
   - Hero раздела `/fundament/` особенный: полноэкранный `<section class="hero section--dark">` с **видео-фоном** `<video class="hero__bg" autoplay muted loop playsinline>` из `/videos/hero/fundament/main.mp4` — те же классы что у hero главной. Остальные разделы используют короткий `.section-hero`.
   - Внизу `/fundament/` отрисовывается блок-витрина «Готовые фундаменты» — первые 3 кейса из подсекции `gotovye-fundamenty/` (см. ниже).

3. **Кейсы готовых проектов** (`content/gotovye-proekty/<slug>/index.md`) — готовые объекты (раздел «Готовые проекты», URL `/gotovye-proekty/`). Каждый кейс — **Hugo Leaf Bundle** (см. структуру ниже).

4. **Кейсы готовых фундаментов** (`content/fundament/gotovye-fundamenty/<slug>/index.md`) — **подсекция внутри `fundament/`**, URL `/fundament/gotovye-fundamenty/<slug>/`. Структура такая же как у кейсов готовых проектов. Различается через `.Type` (см. ниже). Образец: `content/fundament/gotovye-fundamenty/plita-9x9/`.

### Структура bundle кейса (для обоих типов)

```
<slug>/
├── index.md           ← фронтматтер
├── cover.jpg          ← обложка для карточек и hero страницы кейса
├── hod-rabot/         ← фото и видео хода работ по этапам (опц.)
│   ├── planirovka/
│   ├── fundament/
│   ├── steny/
│   ├── krovlya/
│   └── gotovo/
└── galereya/          ← общая фотогалерея готового объекта (опц.)
```

Шаблон `single.html` авто-собирает медиа через `.Resources.Match "hod-rabot/<stage>/*"` — **имена файлов в фронтматтере не перечисляются**.

**Фильтр медиа:** в галереях пропускаются и фото, и видео: `where $matched "ResourceType" "in" (slice "image" "video")`. Это отсеивает `.gitkeep` / `.DS_Store` и пропускает `.mp4` / `.webm`.

Front matter кейса:
- `cover` — имя файла обложки (`'cover.jpg'`); разрешается через `.Resources.GetMatch`. Прогоняется через адаптивный `responsive-image.html` (см. ниже).
- `area`, `region`, `materials`, `cost_total` — карточка на главной и в витринах, мета-полоса в hero страницы кейса.
- `stages` — массив этапов (`name`, `url`, `detail`, `cost_display`, `done`) → блок «Стоимость по этапам».
- Для подсекции `gotovye-fundamenty/_index.md` обязательны `type: 'gotovye-fundamenty'` и `cascade.type: 'gotovye-fundamenty'` — иначе шаблоны не отличат страницы кейса от страниц-типов фундамента.

Hero страницы кейса (`section-hero--with-cover` в `single.html`):
- При наличии cover'а подставляет его фоном через `responsive-image.html` (WebP-srcset + JPEG fallback + LQIP), накладывает горизонтальный градиент-оверлей.
- Поверх — h1 + описание, мета-полоска `case-meta` («Площадь / Регион / Стоимость») на чёрной полупрозрачной плашке (`rgba(0,0,0,0.45)` + `backdrop-filter: blur(2px)`), строка `case-materials`.
- Если cover не разрешается — класс `--with-cover` не ставится, hero просто тёмный без фото.

Раздел «О проекте» (`.Content`) рендерится для кейсов с заголовком секции `О проекте → Описание`, для других страниц — просто `.prose` без заголовка.

Поведение секций медиа в `single.html`:
- **«Фотоотчёт»** (табы по этапам) показывается только если хоть в одной подпапке `hod-rabot/<stage>/` есть image/video файлы. Этапы без файлов в табы не попадают.
- **«Фотогалерея»** (общие виды) показывается, только если в `galereya/*` есть файлы.
- Ориентация ячейки image (`landscape`/`portrait`/`square`) определяется автоматически из `.Width`/`.Height` файла. Видео всегда `landscape` (4:3 через aspect-ratio).
- Партиал — `layouts/partials/gallery-item.html`.

**Блок «Стоимость по этапам»** (`stages-list`) **временно закомментирован** в `single.html` (Hugo-комментарий `{{/* ... */}}`). Поля `stages` / `cost_display` / `cost_total` в фронтматтере остаются — `cost_total` используется в hero мета-полосе и карточках; `stages` сейчас не отрисовываются. Когда понадобится разбивка цен — раскомментировать блок (там же в шаблоне, ищите `TODO: вернуть, когда понадобится показывать разбивку`).

Главная страница рендерится через `layouts/index.html` (не `list.html`). Hero на весь viewport (`100dvh - 64px`) с адаптивным `<picture>` из исходника `assets/images/hero/main.jpg` через `responsive-image.html`. Ниже — первые 3 кейса из секции `gotovye-proekty` через `where .Site.RegularPages "Section" "gotovye-proekty" | first 3`.

## Hugo `.Type` vs `.Section`

**Важно:** в шаблонах `list.html` и `single.html` ветвление сделано по `.Type`, не `.Section`. Причина — подсекция `content/fundament/gotovye-fundamenty/` внутри `fundament/`. Для всех её страниц Hugo возвращает `.Section == "fundament"` (root-секция), и проверки типа `eq .Section "gotovye-fundamenty"` молча отваливаются.

Решение: в `content/fundament/gotovye-fundamenty/_index.md` явно прописан `type: 'gotovye-fundamenty'` и `cascade.type: 'gotovye-fundamenty'`. Cascade автоматически проставляет `.Type` всем дочерним страницам — например `plita-9x9/`. В шаблонах используется `eq .Type "gotovye-fundamenty"` — работает корректно.

При добавлении новых подсекций по той же схеме: `_index.md` подсекции должен иметь `type:` + `cascade.type:` с одинаковым значением.

## Адаптивные изображения

Все hero и cover-обложки на сайте рендерятся через **общий partial** `layouts/partials/responsive-image.html` — он принимает Image Resource и генерирует `<picture>` с:

- **WebP-srcset** (quality 78) — основной формат, ~98% юзеров получают его.
- **Один JPEG-fallback** в `<img src>` (quality 80, без srcset) — для IE/Safari ≤13.
- **LQIP** (Low Quality Image Placeholder) — 20px blur-preview, инлайнится как `data:image/jpeg;base64,...` в CSS-variable `--lqip` на `<picture>` через `safeURL` фильтр (иначе Hugo экранирует data: URL в стиле). До загрузки реального изображения виден размытый цветной плейсхолдер.

**Стандартные точки break:**
- Hero / cover в hero: `widths=(slice 480 1080 1920 2560)` — default partial'a.
- Карточки кейсов в витринах: `widths=(slice 480 800 1200)` — мобильным не нужны 4K варианты.

**Параметры partial:**
- `src` (обязательно) — Image Resource из `.Resources.GetMatch` или `resources.Get`
- `alt` (обязательно для значимых) — `""` для декоративных hero
- `class` — CSS-класс для `<img>`
- `sizes` (default `"100vw"`) — для карточек `"(max-width: 768px) 100vw, 33vw"`
- `widths` (default 4 breakpoints) — можно переопределить
- `loading` (default `"lazy"`) — для hero ставить `"eager"`
- `fetchpriority` — `"high"` для hero выше fold

**Применяется во всех местах:**
- `single.html` — cover в hero страницы кейса (`loading=eager`, `fetchpriority=high`)
- `list.html` — cover в `projects-grid` карточках витрин кейсов
- `list.html` — cover в блоке-витрине «Готовые фундаменты» на `/fundament/`
- `index.html` — hero на главной (`loading=eager`, `fetchpriority=high`)
- `index.html` — cover в блоке «Последние работы»
- `gallery-item.html` — превью фото в галереях (inline, не через partial — нужны лайтбокс-href и custom orient)

**Не апскейлим:** если запрошенная ширина больше исходника, partial её пропускает. Для cover.jpg с iPhone (4032×3024) все 4 ширины применимы.

**Hugo не делает upscale при .Resize:** если исходник 1199px и запрошен 2560px, Hugo вернёт оригинал в WebP без re-encoding с указанным quality — файл получается жирным (1-2 МБ). Partial фильтрует widths по `$src.Width`, чтобы избежать.

**Hero на главной** — исходник в `assets/images/hero/main.jpg` (был PNG 9.7 МБ → конвертирован через `sips` в JPEG 2.4 МБ для ускорения декодирования). Через partial генерируются 480/1080/1920/2560-варианты WebP + один JPEG fallback.

**Cover'ы кейсов** — iPhone-фото 12 МП (3-4 МБ). При первом обращении к странице Hugo генерирует их в WebP-варианты разных ширин и кэширует в `resources/_gen/`. Это занимает несколько секунд на cover при cold start. Для регулярной работы используйте `make hugo_serve` (с кэшем); только при изменении исходника — `make hugo_serve_clean`.

**AVIF** — Hugo extended из Homebrew (и в CI workflow) собран без libavif. Указание `"...avif..."` в `.Resize` молча игнорируется и возвращает оригинальный формат. Если в будущем понадобится AVIF — нужна сборка Hugo с `-tags extended,libavif` или Docker `hugomods/hugo:exts`.

## Медиа-галерея и лайтбокс

Партиал `layouts/partials/gallery-item.html` рендерит один элемент сетки в галерее кейса. Поддерживает **изображения и видео** через `.ResourceType`:

- **Image:** `<a class="gallery-item gallery-item--{orient}">` → внутри `<picture>` с WebP-source (q78) + JPEG fallback (q80) + LQIP-background через CSS-variable `--lqip` на ссылке. Превью 800px, большая версия (1920 WebP) — в `href` и `data-lightbox-src` для лайтбокса.
- **Video:** `<a class="gallery-item gallery-item--video">` → тёмная плашка (`var(--primary)`) с нативным `<video src="...#t=0.5" preload="metadata" muted playsinline>` (`#t=0.5` — media fragment, заставляет браузер показать кадр на 0.5 сек). Поверх — латунный кружок ▶ (`.gallery-item__play`). При клике видео открывается в лайтбоксе с `<video controls autoplay>`.

Партиал `layouts/partials/lightbox.html` — **HTML5 `<dialog>` лайтбокс + inline JS** (~25 строк, нулевые зависимости):
- Подключается один раз в `single.html` перед CTA: `{{ partial "lightbox.html" . }}`.
- Реагирует на любой `[data-lightbox-src]` с `data-lightbox-type="image|video"`.
- Закрытие: кнопка ×, ESC, клик по бэкдропу.
- Фолбэк: если JS отключён, клик по `<a href="...">` открывает прямую ссылку на ресурс.

**Tab-навигация по этапам** в «Фотоотчёт» использует CSS-only через `:checked ~ #panel-X` (без JS). Селектор: `#tab-XXX:checked ~ #panel-XXX { display: block; }` — комбинатор general sibling. **Не использовать** `~ * #panel-XXX` — это будет искать панель как потомка sibling'а, не сработает (был баг до 2026-05-29).

## Глобальные параметры

`hugo.toml` `[params]`:
- Контакты: `phone`, `telegram` (URL), `telegram_handle` (`@DBliveproject`), `email`. **WhatsApp удалён** — в шаблонах его больше нет, не возвращать.
- Прочее: `region`, `experience` (лет), `guarantee` (лет), `description`.
- Реквизиты ИП: `ip_name`, `inn`, `ogrnip`, `okpo`, `okato`, `oktmo`, `okopf`, `okogu`, `okfs` — все попадают в футер.

Все шаблоны читают параметры через `.Site.Params.*`. Меню верхнего уровня жёстко прописано в `hugo.toml` (`[[menus.main]]`) — добавление новой страницы требует записи там же. Раздел `gotovye-fundamenty/` **не в меню** (доступен через прямую ссылку и блок-витрину на `/fundament/`).

CSS — единственный файл `assets/css/main.css`, подключается через Hugo Pipes (`resources.Get | minify | fingerprint`) в `baseof.html`. Никаких npm/SCSS пайплайнов нет; в проекте нет `package.json`, поэтому `npm ci` в `.github/workflows/hugo.yml` фактически не выполняется (стоит `|| true`).

## Палитра (CSS-переменные в `:root`)

Дизайн «Эспрессо + латунь» (Вариант A). Все цвета — переменные в `assets/css/main.css`:

| Переменная | Hex | Назначение |
|---|---|---|
| `--primary` | `#1F1813` | эспрессо — тёмный фон (header, hero, секции `--dark`, плашка видео в галерее) |
| `--accent` | `#A8794A` | латунь — основной акцент (CTA-кнопки, ссылки, цена «Итого по объекту», кружок ▶ на видео) |
| `--accent-hover` | `#8C6238` | латунь при ховере |
| `--accent-red` | `#DC604A` | терракотовый красный — **только** для стоимости в мета-полосе hero страницы кейса (`.case-meta__item--accent`) |
| `--bg` / `--surface` | `#F7F3EC` / `#EAE3D6` | нейтральные тёплые фоны (body, secondary секции, LQIP fallback фон до загрузки) |
| `--text` / `--text-muted` | `#1A1410` / `#6E6055` | текст |
| `--border` | `#D8CFC1` | разделители |

Если потребуется новый акцент (например, для ярлыка «новинка» или тревожный статус) — добавлять переменную в `:root`, а не хардкодить hex по месту.

## Соглашения

- **Slug'и кириллических названий — транслит через `Makefile` (`section`/`newpost`).** Не изобретать кастомный слаг руками — использовать `make section`/`make newpost`, чтобы соблюсти существующую схему (`лентой → lentochnyy`, `газобетон → gazobeton`).
- **Картинки кейсов лежат в bundle** рядом с `index.md` — Hugo сам копирует их в `public/<page-url>/`. Картинки не-кейсов: hero главной — `assets/images/hero/main.jpg` (через Hugo Pipes), иконки — в `static/images/`.
- **Видео hero для `/fundament/`** лежит в `static/videos/hero/fundament/main.mp4` (копия, не симлинк на bundle-ресурс — чтобы переименование кейса не сломало hero).
- **Cover-обложки и галереи разрешаются через Hugo Resources** (`.Resources.GetMatch` для одиночного файла, `.Resources.Match` для glob'а). Если ресурс не найден — шаблон рисует пунктирный плейсхолдер «Фото ожидается» без `<img>` и без 404-запросов в network. Это позволяет публиковать кейс до получения фото от заказчика. **Не возвращать `onerror`-плейсхолдеры на `<img>` и не использовать абсолютные URL для bundle-ресурсов** — оба паттерна порождают 404.
- При добавлении новой страницы кейса — front matter `cover: 'cover.jpg'` оставлять, даже если файла ещё нет (плейсхолдер сработает); файлы фото/видео класть в `hod-rabot/<stage>/` и `galereya/`, имена и количество свободные. Видео `.mp4` ставятся туда же, что и фото — `gallery-item.html` различает их по `.ResourceType`.
- При добавлении нового изображения с cover/hero на сайт — **всегда использовать `partial "responsive-image.html"`**, не голый `<img src="{{ $img.RelPermalink }}">`. См. секцию «Адаптивные изображения».
- `goldmark.renderer.unsafe = true` включён — в md-контенте можно вставлять HTML.
- **`.gitignore` имеет правило `.github`** — это не ошибка, но особенность: CI workflow `.github/workflows/hugo.yml` уже закоммичен, и новые правки в нём не подхватываются git без `-f`. Если когда-то понадобится обновить workflow — `git add -f .github/`.
- **Playwright MCP** подключён project-scope (`.mcp.json` в корне, попадает в git). Каталог `/.playwright-mcp/` (snapshots + screenshots) в `.gitignore`. Скриншоты сохранять с путём `.playwright-mcp/screenshots/<имя>.png`, не в корень репозитория.
