# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Что это

Hugo-сайт частной строительной бригады (`bagaew.ru`), деплой на GitHub Pages. Полностью русскоязычный (`languageCode = 'ru'`). Тема не используется — все шаблоны и стили в проекте.

## Команды

```bash
# Локальный сервер разработки (порт 1313)
make hugo_serve            # hugo server --cleanDestinationDir --ignoreCache --disableFastRender

# Продакшн-сборка в ./public
make pd                    # rm -rf public/* && hugo

# Создать новый раздел верхнего уровня (название кириллицей транслитерируется в slug)
make section "Название раздела"

# Создать новый пост на верхнем уровне
make newpost "Название поста"

# Быстрый коммит-пуш (commit message = аргумент после gp)
make gp "сообщение коммита"
```

CI: `.github/workflows/hugo.yml` собирает на Hugo extended **0.128.0** при push в `main` и публикует через `actions/deploy-pages`. Локальная версия Hugo должна совпадать, иначе возможны расхождения при сборке pipes/SCSS.

## Архитектура контента

Контент разбит на три типа верхнеуровневых страниц:

1. **Одиночные страницы услуг** (`content/proekt.md`, `smeta.md`, `planirovka.md`) — рендерятся через **специализированные layout'ы** в `layouts/page/{proekt,smeta,planirovka}.html`. У каждой свой кастомный шаблон, выбираемый через `layout:` во front matter или соглашение Hugo `_default/<type>`. При добавлении новой такой страницы нужен соответствующий файл в `layouts/page/`.

2. **Разделы работ** (`content/{fundament,steny,krovlya}/`) — список (`_index.md`) + дочерние страницы по типам (например `lentochnyy.md`, `gazobeton.md`). Рендерятся через общий `layouts/_default/list.html` и `single.html`, которые **ветвятся по `.Section`**:
   - В `list.html` для секций `fundament` / `steny` / `krovlya` / `gotovye-proekty` отдельные блоки HERO, заголовков и сеток.
   - Для `steny` страницы группируются по `Params.group` со значениями ровно `"Каркас"`, `"Деревянные"`, `"Каменные и монолит"` — front matter дочерних страниц должен содержать одно из этих значений, иначе страница не попадёт в сетку. Дополнительно ожидается `group_weight` для сортировки групп: `1` (Каркас), `2` (Деревянные), `3` (Каменные и монолит).

3. **Кейсы** (`content/gotovye-proekty/<slug>/index.md`) — готовые объекты (раздел «Готовые проекты», URL `/gotovye-proekty/`). Каждый кейс — **Hugo Leaf Bundle**: каталог со `index.md` и фотографиями рядом. Структура папки:
   ```
   <slug>/
   ├── index.md           ← фронтматтер
   ├── cover.jpg          ← обложка для карточек и hero страницы кейса
   ├── hod-rabot/         ← фото хода работ по этапам (опц.)
   │   ├── planirovka/
   │   ├── fundament/
   │   ├── steny/
   │   ├── krovlya/
   │   └── gotovo/
   └── galereya/          ← общая фотогалерея готового объекта (опц.)
   ```
   Шаблон `single.html` авто-собирает фото через `.Resources.Match "hod-rabot/<stage>/*"` — **имена файлов в фронтматтере не перечисляются**.
   Front matter:
   - `stages` — массив этапов (`name`, `url`, `detail`, `cost_display`, `done`) → блок «Стоимость по этапам».
   - `cover` — имя файла обложки (`'cover.jpg'`); шаблоны разрешают через `.Resources.GetMatch` в URL `/gotovye-proekty/<slug>/cover.jpg`.
   - `area`, `region`, `materials`, `cost_total` — карточка на главной, мета-полоса в hero страницы кейса.
   - Hero страницы кейса (`section-hero--with-cover` в `single.html`) при наличии cover'а подставляет его фоном, накладывает горизонтальный градиент-оверлей и показывает поверх: h1 + описание, мета-полоску `case-meta` («Площадь / Регион / Стоимость») на чёрной полупрозрачной плашке (`rgba(0,0,0,0.45)` + `backdrop-filter: blur(2px)`), строку `case-materials`. Если cover не разрешается — класс `--with-cover` не ставится, hero просто тёмный без фото, остальное (мета и материалы) рендерится как обычно.
   - Раздел «О проекте» (`.Content`, Markdown body после фронтматтера) — рендерится для кейсов с заголовком секции `О проекте → Описание`, для других страниц — просто `.prose` без заголовка. Стили `.prose` (line-height 1.7, max-width 740 px) — для читаемых длинных абзацев, заголовков `h2/h3`, списков, ссылок.
   - Поведение секций галереи в `single.html`:
     - «Фотоотчёт» (табы по этапам) показывается, **только** если хоть в одной подпапке `hod-rabot/<stage>/` есть файлы. Этапы без файлов в табы не попадают. `.Resources.Match` фильтруется по `ResourceType = "image"`, чтобы отсеять `.gitkeep`/`.DS_Store`.
     - «Фотогалерея» (общие виды) показывается, только если в `galereya/*` есть файлы.
     - Ориентация ячейки (`landscape`/`portrait`/`square`) определяется автоматически из `.Width`/`.Height` файла. Партиал — `layouts/partials/gallery-item.html`.
   - **Блок «Стоимость по этапам»** (`stages-list`) **временно закомментирован** в `single.html` (Hugo-комментарий `{{/* ... */}}`). Поля `stages` / `cost_display` / `cost_total` в фронтматтере остаются — `cost_total` используется в hero мета-полосе и карточках; `stages` сейчас не отрисовываются. Когда понадобится разбивка цен — раскомментировать блок (там же в шаблоне, ищите `TODO: вернуть, когда понадобится показывать разбивку`).
   Образец: `content/gotovye-proekty/karkasnyy-dom-biryuza-90m2/`.

Главная страница рендерится через `layouts/index.html` (не `list.html`). Hero на весь viewport (`100dvh - 64px`) с адаптивным `<picture>`: десктоп `/images/hero/main/main_2000.jpg`, мобилка (`max-width: 768px`) `/images/hero/main/main_1080.jpg`. Текст и кнопки поверх через локальный градиент-оверлей (`.hero__overlay`). Ниже — первые 3 кейса из секции `gotovye-proekty` через `where .Site.RegularPages "Section" "gotovye-proekty" | first 3`.

## Глобальные параметры

`hugo.toml` `[params]`:
- Контакты: `phone`, `telegram` (URL), `telegram_handle` (`@DBliveproject`), `email`. **WhatsApp удалён** — в шаблонах его больше нет, не возвращать.
- Прочее: `region`, `experience` (лет), `guarantee` (лет), `description`.
- Реквизиты ИП: `ip_name`, `inn`, `ogrnip`, `okpo`, `okato`, `oktmo`, `okopf`, `okogu`, `okfs` — все попадают в футер.

Все шаблоны читают параметры через `.Site.Params.*`. Меню верхнего уровня жёстко прописано в `hugo.toml` (`[[menus.main]]`) — добавление новой страницы требует записи там же.

CSS — единственный файл `assets/css/main.css`, подключается через Hugo Pipes (`resources.Get | minify | fingerprint`) в `baseof.html`. Никаких npm/SCSS пайплайнов нет; в проекте нет `package.json`, поэтому `npm ci` в `.github/workflows/hugo.yml` фактически не выполняется (стоит `|| true`).

## Палитра (CSS-переменные в `:root`)

Дизайн «Эспрессо + латунь» (Вариант A). Все цвета — переменные в `assets/css/main.css`:

| Переменная | Hex | Назначение |
|---|---|---|
| `--primary` | `#1F1813` | эспрессо — тёмный фон (header, hero, секции `--dark`) |
| `--accent` | `#A8794A` | латунь — основной акцент (CTA-кнопки, ссылки, цена «Итого по объекту») |
| `--accent-hover` | `#8C6238` | латунь при ховере |
| `--accent-red` | `#DC604A` | терракотовый красный — **только** для стоимости в мета-полосе hero страницы кейса (`.case-meta__item--accent`) |
| `--bg` / `--surface` | `#F7F3EC` / `#EAE3D6` | нейтральные тёплые фоны (body, secondary секции) |
| `--text` / `--text-muted` | `#1A1410` / `#6E6055` | текст |
| `--border` | `#D8CFC1` | разделители |

Если потребуется новый акцент (например, для ярлыка «новинка» или тревожный статус) — добавлять переменную в `:root`, а не хардкодить hex по месту.

## Соглашения

- **Slug'и кириллических названий — транслит через `Makefile` (`section`/`newpost`).** Не изобретать кастомный слаг руками — использовать `make section`/`make newpost`, чтобы соблюсти существующую схему (`лентой → lentochnyy`, `газобетон → gazobeton` и т.д.).
- **Картинки кейсов лежат в bundle** рядом с `index.md` (`content/gotovye-proekty/<slug>/cover.jpg` и пр.) — Hugo сам копирует их в `public/<page-url>/`. Картинки не-кейсов (hero главной, иконки и т.п.) — в `static/images/`.
- **Cover-обложки и галереи разрешаются через Hugo Resources** (`.Resources.GetMatch` для одиночного файла, `.Resources.Match` для glob'а). Если ресурс не найден — шаблон рисует пунктирный плейсхолдер «Фото ожидается» без `<img>` и без 404-запросов в network. Это позволяет публиковать кейс до получения фото от заказчика. **Не возвращать `onerror`-плейсхолдеры на `<img>` и не использовать абсолютные URL для bundle-ресурсов** — оба паттерна порождают 404.
- При добавлении новой страницы кейса (`content/gotovye-proekty/<slug>/index.md`) — front matter `cover: 'cover.jpg'` оставлять, даже если файла ещё нет (плейсхолдер сработает); файлы фото класть в `hod-rabot/<stage>/` и `galereya/`, имена и количество свободные.
- `goldmark.renderer.unsafe = true` включён — в md-контенте можно вставлять HTML.
