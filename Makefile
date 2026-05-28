gp:
	git add .
	git commit -m "$(filter-out $@,$(MAKECMDGOALS))"
	git push

pd:
	rm -rf public/*
	hugo

# Команда для создания нового раздела с транслитерацией названия
section:
	@NAME="$(filter-out $@,$(MAKECMDGOALS))"; \
	if [ -z "$$NAME" ]; then \
		echo "Ошибка: Не указано название раздела"; \
		exit 1; \
	fi; \
	TRANSLITERATED=$$(echo "$$NAME" | \
		sed 's/А/A/g' | sed 's/Б/B/g' | sed 's/В/V/g' | sed 's/Г/G/g' | \
		sed 's/Д/D/g' | sed 's/Е/E/g' | sed 's/Ё/E/g' | sed 's/Ж/ZH/g' | \
		sed 's/З/Z/g' | sed 's/И/I/g' | sed 's/Й/Y/g' | sed 's/К/K/g' | \
		sed 's/Л/L/g' | sed 's/М/M/g' | sed 's/Н/N/g' | sed 's/О/O/g' | \
		sed 's/П/P/g' | sed 's/Р/R/g' | sed 's/С/S/g' | sed 's/Т/T/g' | \
		sed 's/У/U/g' | sed 's/Ф/F/g' | sed 's/Х/H/g' | sed 's/Ц/TS/g' | \
		sed 's/Ч/CH/g' | sed 's/Ш/SH/g' | sed 's/Щ/SHCH/g' | sed 's/Ъ//g' | \
		sed 's/Ы/Y/g' | sed 's/Ь//g' | sed 's/Э/E/g' | sed 's/Ю/YU/g' | \
		sed 's/Я/YA/g' | sed 's/а/a/g' | sed 's/б/b/g' | sed 's/в/v/g' | \
		sed 's/г/g/g' | sed 's/д/d/g' | sed 's/е/e/g' | sed 's/ё/e/g' | \
		sed 's/ж/zh/g' | sed 's/з/z/g' | sed 's/и/i/g' | sed 's/й/y/g' | \
		sed 's/к/k/g' | sed 's/л/l/g' | sed 's/м/m/g' | sed 's/н/n/g' | \
		sed 's/о/o/g' | sed 's/п/p/g' | sed 's/р/r/g' | sed 's/с/s/g' | \
		sed 's/т/t/g' | sed 's/у/u/g' | sed 's/ф/f/g' | sed 's/х/h/g' | \
		sed 's/ц/ts/g' | sed 's/ч/ch/g' | sed 's/ш/sh/g' | sed 's/щ/shch/g' | \
		sed 's/ъ//g' | sed 's/ы/y/g' | sed 's/ь//g' | sed 's/э/e/g' | \
		sed 's/ю/yu/g' | sed 's/я/ya/g' | \
		sed 's/ /_/g' | tr '[:upper:]' '[:lower:]'); \
	if [ -z "$$TRANSLITERATED" ]; then \
		echo "Ошибка: Не удалось транслитерировать название"; \
		exit 1; \
	fi; \
	echo "Создание нового раздела: $$NAME -> $$TRANSLITERATED"; \
	hugo new content/"$$TRANSLITERATED"/_index.md --kind section; \
	sed -i '' "s/title = '[^']*'/title = '$$NAME'/" content/"$$TRANSLITERATED"/_index.md

# Команда для создания нового поста с транслитерацией названия
newpost:
	@NAME="$(filter-out $@,$(MAKECMDGOALS))"; \
	if [ -z "$$NAME" ]; then \
		echo "Ошибка: Не указано название поста"; \
		exit 1; \
	fi; \
	TRANSLITERATED=$$(echo "$$NAME" | \
		sed 's/А/A/g' | sed 's/Б/B/g' | sed 's/В/V/g' | sed 's/Г/G/g' | \
		sed 's/Д/D/g' | sed 's/Е/E/g' | sed 's/Ё/E/g' | sed 's/Ж/ZH/g' | \
		sed 's/З/Z/g' | sed 's/И/I/g' | sed 's/Й/Y/g' | sed 's/К/K/g' | \
		sed 's/Л/L/g' | sed 's/М/M/g' | sed 's/Н/N/g' | sed 's/О/O/g' | \
		sed 's/П/P/g' | sed 's/Р/R/g' | sed 's/С/S/g' | sed 's/Т/T/g' | \
		sed 's/У/U/g' | sed 's/Ф/F/g' | sed 's/Х/H/g' | sed 's/Ц/TS/g' | \
		sed 's/Ч/CH/g' | sed 's/Ш/SH/g' | sed 's/Щ/SHCH/g' | sed 's/Ъ//g' | \
		sed 's/Ы/Y/g' | sed 's/Ь//g' | sed 's/Э/E/g' | sed 's/Ю/YU/g' | \
		sed 's/Я/YA/g' | sed 's/а/a/g' | sed 's/б/b/g' | sed 's/в/v/g' | \
		sed 's/г/g/g' | sed 's/д/d/g' | sed 's/е/e/g' | sed 's/ё/e/g' | \
		sed 's/ж/zh/g' | sed 's/з/z/g' | sed 's/и/i/g' | sed 's/й/y/g' | \
		sed 's/к/k/g' | sed 's/л/l/g' | sed 's/м/m/g' | sed 's/н/n/g' | \
		sed 's/о/o/g' | sed 's/п/p/g' | sed 's/р/r/g' | sed 's/с/s/g' | \
		sed 's/т/t/g' | sed 's/у/u/g' | sed 's/ф/f/g' | sed 's/х/h/g' | \
		sed 's/ц/ts/g' | sed 's/ч/ch/g' | sed 's/ш/sh/g' | sed 's/щ/shch/g' | \
		sed 's/ъ//g' | sed 's/ы/y/g' | sed 's/ь//g' | sed 's/э/e/g' | \
		sed 's/ю/yu/g' | sed 's/я/ya/g' | \
		sed 's/ /_/g' | tr '[:upper:]' '[:lower:]'); \
	if [ -z "$$TRANSLITERATED" ]; then \
		echo "Ошибка: Не удалось транслитерировать название"; \
		exit 1; \
	fi; \
	echo "Создание нового поста: $$NAME -> $$TRANSLITERATED.md"; \
	hugo new content/"$$TRANSLITERATED.md" --kind post

# Очистить кэш Hugo Image Processing и выходной каталог
clean:
	rm -rf resources/_gen public
	@echo "✓ Очищено: resources/_gen/ + public/"

# Быстрый запуск dev-сервера — использует существующий кэш ресурсов
hugo_serve:
	hugo server --disableFastRender --port 1313

# Полный запуск со сбросом кэша — пересоздаёт все image variants заново (долго при первом старте)
hugo_serve_clean: clean hugo_serve

# Catch and ignore additional arguments
%:
	@: