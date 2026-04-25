# Сборка и запись

## Сборка из git-репозитория

```bash
git clone --recursive https://github.com/Sanya1988/RK-3566-GameStick-OS.git br2
cd br2
./scripts/init-build.sh
cd output
make
```

Если репозиторий уже клонирован без submodule:

```bash
git submodule update --init --recursive
```

## Что делает init-build.sh

Скрипт создаёт `output/` и запускает:

```bash
make -C buildroot O=$PWD/output BR2_EXTERNAL=$PWD/br2-external gamestick_rk3566_m16_defconfig
```

Перед этим он автоматически накладывает локальные compatibility patches на чистый `buildroot` submodule. Поэтому для `git clone --recursive`, нужно использовать именно `./scripts/init-build.sh`, а не вызывать `make ... defconfig` вручную.

После этого обычная сборка идёт из `output/`:

```bash
cd output
make
```

## Запись образа на карту
Используйте программы типа Balena Etcher или через терминал linux:

Подставьте свой диск вместо `/dev/sdX`.

```bash
cd /path/to/br2
export DISK=/dev/sdX

sudo umount ${DISK}1 2>/dev/null || true
sudo umount ${DISK}2 2>/dev/null || true
sudo dd if="$PWD/output/images/sdcard.img" of="$DISK" bs=4M conv=fsync status=progress
sync
```

`prepare-userdata.sh` после записи запускать не нужно.

## Первый запуск

На свежей карте используется двухэтапная инициализация раздела `USERDATA`:
- первый запуск: первый этап и выключение
- затем нужно включить стик ещё раз
- второй запуск: второй этап и далее обычная загрузка системы

## BIOS

В публичный release BIOS не включены.

Система соберётся и без них, но соответствующие эмуляторы без BIOS работать не будут.
Если нужно собрать образ уже с BIOS внутри, положи свои файлы в:

```bash
br2-external/package/gamestick-bios/seed/
```

## Screensaver images

Из release также удалён набор пользовательских screensaver-изображений.

Если хочешь включить их в свой приватный билд, положи изображения в:

```bash
br2-external/package/gamestick-games-storage/assets/screensaver/
```

Требования:
- формат: `jpg` или `png`
- рекомендуемое разрешение: `1920x1080`
