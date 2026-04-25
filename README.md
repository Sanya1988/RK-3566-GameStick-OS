# GameStick OS Build Release

![gamestick](https://cs12d7a.4pda.ws/32280949/M%26%23225%3By-Ch%26%23417%3Bi-Game-Stick-4K-V%26%23224%3Bng-M16-M%26%237899%3Bi-2023-64GB-20000-Tr%26%23242%3B-Ch%26%23417%3Bi-M%26%237899%3Bi-PS1-PSP-N64-M%26%23225%3By-Ch%26%23417%3Bi-Game-C%26%237847%3Bm-Tay-Kh%26%23244%3Bng-D%26%23226%3By-TV-2023-ok.jpg?s=00ae705f5a9cfc9569ecf3d9000000001ebbffc69d7ccdfd50ff0e53b6b51b8a)

Данная сборка представляет собой версию`GameStick OS`для Game Stick M16 4K Ultra HD (Gold Stick) и является полностью собранной с нуля ОС на базе buildroot. В качестве фронтэнда используется связка EmulationStation Desktop Edition (ES-DE) и RetroArch.

Из существенных доработок можно отметить проигрывание музыки в главном меню и полное меню Retroarch в отличии от стоковой пошивки. Все сетевые функции убраны. Добавлена поддержка сторонних геймпадов. Так же реализована автоматическая разметка раздела с ROMs (как в Batocera). 
Более подробная инструкция по использованию прилагается.

Что внутри:
- `buildroot/` - подключён как git submodule и зафиксирован на проверенном commit
- `br2-external/` - product layer с конфигами и пакетами GameStick OS
- `esde/` - snapshot исходников ES-DE с текущими локальными правками
- `scripts/` - bootstrap и упаковка release-архива
- `docs/` - инструкции по сборке и пользовательская документация

Что сознательно исключено из публичного release:
- BIOS-файлы

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
