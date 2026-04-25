# GameStick OS Build Release

<img src="docs/Gamestick.jpg" width="500" alt="GameStick OS">

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

Подробные инструкции:
- [Сборка и запись](docs/BUILD.md)
- [Руководство пользователя](docs/USER_MANUAL.md)

Атрибуция bundled background music:
- набор заменён на Batocera `es-background-musics`
- лицензии и условия использования сохранены в `br2-external/package/gamestick-esde/assets/music/`
  
## License

The original GameStick OS project files are licensed under the Apache License 2.0.

Third-party components keep their original licenses. This includes Buildroot, ES-DE, RetroArch, libretro cores, Linux kernel, U-Boot, BusyBox and other bundled open-source packages.

BIOS files and commercial ROM files are not included in this repository or public releases.
