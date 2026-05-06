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
   Поведение секций галереи в `single.html`:
   - «Фотоотчёт» (табы по этапам) показывается, **только** если хоть в одной подпапке `hod-rabot/<stage>/` есть файлы. Этапы без файлов в табы не попадают.
   - «Фотогалерея» (общие виды) показывается, только если в `galereya/*` есть файлы.
   - Ориентация ячейки (`landscape`/`portrait`/`square`) определяется автоматически из `.Width`/`.Height` файла. Партиал — `layouts/partials/gallery-item.html`.
   Образец: `content/gotovye-proekty/karkasnaya-banya-18m2/`.

Главная страница рендерится через `layouts/index.html` (не `list.html`). Она показывает первые 3 кейса из секции `gotovye-proekty` через `where .Site.RegularPages "Section" "gotovye-proekty" | first 3`.

## Глобальные параметры

`hugo.toml` `[params]` — телефон, whatsapp, telegram, регион, опыт (лет), гарантия (лет), реквизиты ИП. Все шаблоны читают их через `.Site.Params.*`. Меню верхнего уровня тоже жёстко прописано в `hugo.toml` (`[[menus.main]]`) — добавление новой страницы требует и записи там.

CSS — единственный файл `assets/css/main.css`, подключается через Hugo Pipes (`resources.Get | minify | fingerprint`) в `baseof.html`. Никаких npm/SCSS пайплайнов нет, хотя CI вызывает `npm ci`, если появится `package-lock.json`.

## Соглашения

- **Slug'и кириллических названий — транслит через `Makefile` (`section`/`newpost`).** Не изобретать кастомный слаг руками — использовать `make section`/`make newpost`, чтобы соблюсти существующую схему (`лентой → lentochnyy`, `газобетон → gazobeton` и т.д.).
- **Картинки кейсов лежат в bundle** рядом с `index.md` (`content/gotovye-proekty/<slug>/cover.jpg` и пр.) — Hugo сам копирует их в `public/<page-url>/`. Картинки не-кейсов (hero, иконки и т.п.) — в `static/images/`. Шаблоны имеют `onerror`-плейсхолдеры — отсутствующие фото не ломают вёрстку, поэтому можно публиковать кейс до получения фото от заказчика.
- `goldmark.renderer.unsafe = true` включён — в md-контенте можно вставлять HTML.
