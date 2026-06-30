# AR Street MVP

MVP исторического AR-приложения на Flutter. Приложение показывает карту памятников, открывает объект по QR-коду и дает пользователю исторический опыт: 360-панораму эпохи или 3D/AR-модель. Администраторы управляют объектами, эпохами, панорамами, QR и 3D/AR-ассетами через web-админку.

## Статус

Проект находится в состоянии рабочего MVP.

Готово:

- пользовательское Flutter-приложение с картой объектов;
- сканер QR и поддержка payload `retroar://object/<object_id>`;
- экран исторического опыта с переключением между панорамой и 3D;
- временная шкала эпох;
- 360-панорамы;
- 3D-просмотр через `model_viewer_plus`;
- индикатор загрузки серверной 3D-модели;
- внешний AR fallback через Android Scene Viewer и iOS Quick Look;
- Supabase-интеграция;
- web-админка;
- CRUD объектов в админке;
- управление эпохами и панорамами;
- генерация QR в админке;
- загрузка `.glb` / `.usdz` в Supabase Storage;
- привязка 3D/AR-моделей к конкретным эпохам;
- схема Supabase для MVP с RLS-политиками;
- тестовая модель Маяка переведена с локального asset на публичный Supabase Storage URL;
- `.glb` больше не бандлится внутрь APK.

## Что Было Сделано

Основная работа по MVP:

1. Разобран существующий Flutter-проект и приведен к рабочему состоянию.
2. Исправлены предупреждения `flutter analyze`.
3. Настроен запуск web, Android debug и проверка через физический телефон.
4. Добавлена и отлажена Supabase-админка.
5. Создан SQL-файл `supabase/admin_mvp_schema.sql` с таблицами:
   - `admin_profiles`;
   - `heritage_objects`;
   - `heritage_epochs`;
   - `heritage_ar_assets`.
6. Добавлены политики доступа для админов и публичного чтения опубликованных объектов.
7. Добавлен Storage bucket `archive-media`.
8. Реализована генерация QR-кода для объекта в админке.
9. Реализована загрузка панорам в Supabase Storage.
10. Реализована загрузка 3D/AR-моделей `.glb` / `.usdz` в Supabase Storage.
11. Добавлена привязка 3D-моделей к эпохам через `epoch_year`.
12. Пользовательская часть научилась выбирать модель под текущую эпоху.
13. Добавлен fallback: общий ассет без `epoch_year` работает для всех эпох.
14. Добавлен AR/Scene Viewer fallback для Android и Quick Look для iOS.
15. 3D-модели вынесены на сервер: приложение скачивает модель при открытии просмотра.
16. Добавлен `LoadingModelViewer` с индикатором загрузки и обработкой ошибок.
17. Модель Маяка загружена в Supabase Storage и подключена через `glb_url`.
18. Обновлены README и `History.mb` для восстановления контекста.

## Архитектура

```text
Flutter app
  ├─ User app
  │   ├─ map
  │   ├─ QR scanner
  │   ├─ object details
  │   ├─ panorama viewer
  │   └─ 3D/AR viewer
  │
  ├─ Web admin
  │   ├─ auth through Supabase
  │   ├─ heritage objects
  │   ├─ epochs and panoramas
  │   ├─ QR generation
  │   └─ 3D/AR assets
  │
  └─ Supabase
      ├─ Postgres tables
      ├─ RLS policies
      ├─ Auth
      └─ Storage bucket archive-media
```

## Структура Проекта

```text
lib/
  admin/                         web-админка
  core/                          providers, Supabase init, shared services
  data/                          репозитории пользовательских данных
  models/                        модели объектов, эпох, AR-ассетов
  screens/                       пользовательские экраны
  services/                      QR, AR launcher, availability services
  theme/                         цвета и стили
  widgets/                       общие виджеты

assets/
  .env                           public Supabase config для клиента
  data/objects.json              fallback-данные
  images/                        локальные изображения
  panoramas/                     локальные fallback-панорамы
  fonts/                         шрифты

supabase/
  admin_mvp_schema.sql           схема MVP для Supabase

test/
  *_test.dart                    unit/widget tests
```

## Требования

Проверенная среда:

- Flutter stable `3.44.2`;
- Dart из Flutter SDK;
- Windows 10;
- Chrome для web;
- Android SDK для запуска на телефоне;
- Supabase project.

Путь Flutter SDK на текущей машине:

```text
F:\Flutter\flutter\bin
```

Если Flutter есть в `PATH`, можно использовать просто `flutter`. Если нет, использовать полный путь:

```powershell
F:\Flutter\flutter\bin\flutter.bat
```

## Быстрый Старт

Перейти в папку Flutter-проекта:

```powershell
cd E:\ar\Ar\flutter_application_1
```

Установить зависимости:

```powershell
F:\Flutter\flutter\bin\flutter.bat pub get
```

Создать локальный env-файл:

```powershell
Copy-Item .\assets\.env.example .\assets\.env
```

Затем заполнить `assets/.env` значениями своего Supabase project.

Проверить окружение:

```powershell
F:\Flutter\flutter\bin\flutter.bat doctor
```

## Запуск Web

Рекомендуемый вариант для открытия в любом браузере:

```powershell
F:\Flutter\flutter\bin\flutter.bat run -d web-server --web-port 5176
```

Открыть:

```text
http://127.0.0.1:5176/#/admin
http://127.0.0.1:5176/#/studio
```

Если порт занят:

```powershell
F:\Flutter\flutter\bin\flutter.bat run -d web-server --web-port 5177
```

И открыть:

```text
http://127.0.0.1:5177/#/admin
http://127.0.0.1:5177/#/studio
```

Проверить, кто занял порт:

```powershell
netstat -ano | Select-String ':5176'
```

Остановить процесс по PID:

```powershell
Stop-Process -Id <pid>
```

Можно запускать и так:

```powershell
F:\Flutter\flutter\bin\flutter.bat run -d chrome --web-port 5176
```

В этом режиме лучше пользоваться окном Chrome, которое Flutter открыл сам. В стороннем браузере debug DDC-сборка может долго грузиться или зависнуть на пустой странице.

## Запуск На Android

Проверить устройства:

```powershell
F:\Flutter\flutter\bin\flutter.bat devices
```

Запуск на телефоне:

```powershell
F:\Flutter\flutter\bin\flutter.bat run -d <device-id> --device-timeout 120
```

Если телефон `not authorized`, разблокировать телефон и принять RSA-запрос USB debugging.

Если установка падает с `INSTALL_FAILED_USER_RESTRICTED`, включить на телефоне установку через USB в настройках разработчика.

Если Flutter просит лицензии Android:

```powershell
F:\Flutter\flutter\bin\flutter.bat doctor --android-licenses
```

Если Flutter plugins требуют symlink support:

```powershell
start ms-settings:developers
```

И включить Windows Developer Mode.

## Сборки И Проверки

Минимальный набор перед коммитом:

```powershell
F:\Flutter\flutter\bin\flutter.bat analyze
F:\Flutter\flutter\bin\flutter.bat test
F:\Flutter\flutter\bin\flutter.bat build web
F:\Flutter\flutter\bin\flutter.bat build apk --debug
```

Проверить JSON fallback-данные:

```powershell
Get-Content -Path .\assets\data\objects.json -Encoding UTF8 | ConvertFrom-Json | Out-Null
```

Проверить, что 3D-модели не попали в APK:

```powershell
tar -tf .\build\app\outputs\flutter-apk\app-debug.apk | Select-String -Pattern 'assets/models|\.glb|\.usdz'
```

Ожидаемый результат: пустой вывод.

Известные предупреждения:

- `flutter build web` может показывать WASM dry-run warnings из-за `mobile_scanner`.
- `flutter build apk --debug` может показывать предупреждение о будущей миграции Kotlin Gradle Plugin.
- Эти предупреждения уже наблюдались и не блокируют текущий MVP.

## Supabase

Клиентский конфиг:

```text
assets/.env
```

Пример без реальных значений:

```text
assets/.env.example
```

В проекте используется public/publishable Supabase key. Service role key и пароли в репозиторий не добавлять.

`assets/.env` добавлен в `.gitignore`; для GitHub хранится только `assets/.env.example`.

SQL-схема:

```text
supabase/admin_mvp_schema.sql
```

Как применить схему:

1. Открыть Supabase Dashboard.
2. Перейти в SQL Editor.
3. Создать New query.
4. Вставить содержимое `supabase/admin_mvp_schema.sql`.
5. Нажать Run.

Основные таблицы:

```text
admin_profiles
heritage_objects
heritage_epochs
heritage_ar_assets
```

Storage bucket:

```text
archive-media
```

Bucket публичный, потому что:

- `<model-viewer>` должен скачивать `.glb` по обычному `https` URL;
- Android Scene Viewer не умеет открывать локальный Flutter asset;
- iOS Quick Look должен получать `.usdz` по доступной ссылке.

## Web-Админка

Адрес:

```text
http://127.0.0.1:5176/#/admin
```

В админке доступно:

- вход через Supabase Auth;
- список объектов;
- создание и редактирование объекта;
- импорт fallback-объектов;
- эпохи и панорамы;
- загрузка панорамы в Supabase Storage;
- генерация QR-кода;
- скачивание QR PNG;
- создание 3D/AR-ассета;
- привязка 3D/AR-ассета к эпохе;
- загрузка `.glb` / `.usdz` в Supabase Storage;
- публикация/снятие с публикации.

## QR

Формат payload:

```text
retroar://object/<object_id>
```

Пример:

```text
retroar://object/mayak
```

Сканер приложения умеет извлекать `object_id` из:

- прямого id;
- deep link;
- URL query;
- URL path;
- JSON payload.

## Панорамы

Панорамы могут быть:

- локальными fallback assets;
- удаленными `https` URL из Supabase Storage.

Пользовательский экран выбирает доступные панорамы, сортирует их по году и показывает на временной шкале.

## 3D И AR

Целевая схема MVP: 3D-модели не хранятся внутри приложения.

Основные поля `heritage_ar_assets`:

```text
object_id
epoch_year
title
glb_url
usdz_url
scale
placement
published
```

Legacy-поля:

```text
glb_asset_path
usdz_asset_path
```

Они оставлены для совместимости и dev fallback. Для релизного сценария использовать `glb_url` / `usdz_url`.

Админский сценарий загрузки модели:

1. Открыть `/#/admin`.
2. Выбрать объект.
3. Перейти к блоку `3D/AR ассеты`.
4. Выбрать эпоху.
5. Нажать `Загрузить .glb/.usdz`.
6. Дождаться загрузки в Supabase Storage.
7. Проверить, что ссылка попала в `glb_url` или `usdz_url`.
8. Нажать `Сохранить 3D`.

Пользовательский сценарий:

1. Пользователь открывает объект.
2. Выбирает исторический опыт.
3. Переключается на 3D.
4. Приложение скачивает модель с Supabase.
5. Показывается индикатор `Загружаем 3D-модель`.
6. После загрузки открывается интерактивный 3D-просмотр.
7. Кнопка `AR` запускает системный viewer, если устройство поддерживает сценарий.

Тестовая модель Маяка:

```text
https://kzegyfrwoilxwbrbgnen.supabase.co/storage/v1/object/public/archive-media/objects/mayak/models/mayak_test.glb
```

Эта модель уже подключена в live Supabase для `object_id = mayak`, `title = mayak_default`.

## Тесты

Покрыты ключевые части MVP:

- парсинг QR payload;
- Supabase mapper объектов;
- admin models;
- admin QR downloader;
- AR experience model;
- выбор AR-модели по эпохе;
- availability service для панорам и 3D;
- fallback-логика опубликованных/неопубликованных объектов.

Запуск:

```powershell
F:\Flutter\flutter\bin\flutter.bat test
```

Последнее проверенное состояние: 23 теста проходят.

## Подготовка К GitHub

Перед заливкой:

1. Проверить, что репозиторий создается либо в `E:\ar`, либо прямо в `E:\ar\Ar\flutter_application_1`.
2. Не добавлять в Git большие исходники: `.zip`, `.mp4`, `.glb`, `.usdz`, `.pptx`, `.docx`.
3. Не добавлять service role key, пароли, личные токены.
4. Проверить `.gitignore`.
5. Запустить проверки:

```powershell
F:\Flutter\flutter\bin\flutter.bat analyze
F:\Flutter\flutter\bin\flutter.bat test
F:\Flutter\flutter\bin\flutter.bat build web
F:\Flutter\flutter\bin\flutter.bat build apk --debug
```

Если Git еще не инициализирован:

```powershell
cd E:\ar
git init
git add .gitignore README.md History.mb Ar/flutter_application_1
git status
git commit -m "Prepare AR Street MVP for GitHub"
git branch -M main
git remote add origin <github-repo-url>
git push -u origin main
```

Если репозиторий нужен только для Flutter-проекта:

```powershell
cd E:\ar\Ar\flutter_application_1
git init
git add .
git status
git commit -m "Prepare AR Street MVP"
git branch -M main
git remote add origin <github-repo-url>
git push -u origin main
```

## Известные Ограничения

- Настоящий AR зависит от поддержки ARCore/Scene Viewer на Android и Quick Look на iOS.
- Для устройств без ARCore нужен отдельный fallback: псевдо-AR через камеру или обычный 3D-viewer.
- 3D-модель должна быть оптимизирована по размеру и материалам, иначе слабые смартфоны будут тормозить.
- Для iOS лучше хранить отдельный `.usdz`.
- `mobile_scanner` дает WASM dry-run warnings при web-сборке.
- Часть старых fallback-полей `glb_asset_path` / `usdz_asset_path` оставлена для совместимости, но не является целевым релизным путем.

## Roadmap

Ближайшие задачи:

- протестировать 3D/AR Маяка на физическом телефоне после перехода на Supabase Storage;
- проверить AR на нескольких Android-устройствах;
- добавить понятный fallback для устройств без ARCore;
- решить, нужен ли псевдо-AR режим через камеру;
- добавить UX-индикаторы для неподдерживаемого AR;
- оптимизировать требования к `.glb` / `.usdz` для админов;
- подготовить production deploy web-админки;
- переименовать Flutter package/app label из `flutter_application_1` в финальное название.

## История Работы

Подробный журнал состояния и изменений:

```text
E:\ar\History.mb
```

Если сессия разработки оборвется, восстановление контекста начинать с `History.mb`.
