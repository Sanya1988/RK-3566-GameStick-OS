# GameStick OS Build Release

Эта папка подготовлена как release-репозиторий для сборки текущей версии `GameStick OS`.

Что внутри:
- `buildroot/` - подключён как git submodule и зафиксирован на проверенном commit
- `br2-external/` - product layer с конфигами и пакетами GameStick OS
- `esde/` - snapshot исходников ES-DE с текущими локальными правками
- `scripts/` - bootstrap и упаковка release-архива
- `docs/` - инструкции по сборке и пользовательская документация

Что сознательно исключено из публичного release:
- BIOS-файлы
- изображения для пользовательской screensaver-папки

Быстрый старт:
1. Инициализировать submodule:
   `git submodule update --init --recursive`
2. Подготовить output:
   `./scripts/init-build.sh`
   Этот шаг обязателен: скрипт автоматически накладывает локальные compatibility patches на чистый `buildroot` submodule.
3. Собрать:
   `cd output && make`

Подробные инструкции:
- [Сборка и запись](docs/BUILD.md)
- [Руководство пользователя](docs/USER_MANUAL.md)

Атрибуция bundled background music:
- набор заменён на Batocera `es-background-musics`
- лицензии и условия использования сохранены в `br2-external/package/gamestick-esde/assets/music/`
