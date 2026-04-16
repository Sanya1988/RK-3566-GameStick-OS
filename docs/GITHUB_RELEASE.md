# Публикация на GitHub

## 1. Создай репозиторий на GitHub

Создай пустой репозиторий, например:

`gamestick-os-br2`

## 2. Запушь подготовленный release-репозиторий

Из папки `br2`:

```bash
git add .
git commit -m "Prepare public GameStick OS build release"
git branch -M main
git remote add origin <YOUR_GITHUB_REPO_URL>
git push -u origin main
```

## 3. Подготовь release-архив

GitHub автоматически показывает `Source code (zip/tar.gz)`, но эти архивы не подходят,
если в проекте есть submodule.

Поэтому для релиза нужен отдельный архив-asset, который уже содержит развёрнутый `buildroot`.

Собрать его можно так:

```bash
./scripts/create-release-archive.sh
```

Результат появится в:

```bash
dist/
```

Там будут:
- `gamestick-os-br2-<date>.tar.gz`
- `gamestick-os-br2-<date>.tar.gz.sha256`

## 4. Создай Release на GitHub

На странице репозитория:
1. `Releases`
2. `Draft a new release`
3. Создай tag, например `v1.0.0`
4. Заголовок, например `GameStick OS Build Release v1.0.0`
5. Загрузи в assets файл из `dist/`:
   - `gamestick-os-br2-<date>.tar.gz`
   - опционально `gamestick-os-br2-<date>.tar.gz.sha256`
6. Опубликуй release

## 5. Как потом скачивать и собирать

Есть два нормальных варианта:

### Через git

```bash
git clone --recursive <YOUR_GITHUB_REPO_URL> br2
cd br2
./scripts/init-build.sh
cd output
make
```

### Через Release asset

```bash
tar -xzf gamestick-os-br2-*.tar.gz
cd br2
./scripts/init-build.sh
cd output
make
```

Для обычных пользователей лучше второй вариант, потому что он уже содержит submodule contents.
