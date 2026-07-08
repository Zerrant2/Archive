# AR Street MVP Workspace

Рабочая папка MVP исторического AR-приложения.

Основной Flutter-проект:

```text
Ar/flutter_application_1
```

Подробная документация проекта:

```text
Ar/flutter_application_1/README.md
```

Журнал состояния и восстановления контекста:

```text
History.mb
```

## Быстрый Запуск

```powershell
cd E:\ar\Ar\flutter_application_1
F:\Flutter\flutter\bin\flutter.bat pub get
F:\Flutter\flutter\bin\flutter.bat run -d web-server --web-port 5176
```

Админка:

```text
http://127.0.0.1:5176/#/admin
```

Пользовательский web-интерфейс:

```text
http://127.0.0.1:5176/#/studio
```

## Что Внутри

- Flutter-приложение с картой, QR-сканером, панорамами и 3D/AR-просмотром.
- MVP карты с историческими маршрутами и режимом “Места рядом”.
- Встроенный MVP `AR-камера` для размещения серверной `.glb` модели перед камерой, Scene Viewer оставлен fallback.
- Web-админка для объектов, эпох, панорам, QR и 3D/AR-моделей.
- Supabase-схема MVP в `Ar/flutter_application_1/supabase/admin_mvp_schema.sql`.
- Серверное хранение `.glb/.usdz` моделей через Supabase Storage.
- `History.mb` с подробным журналом проделанной работы.

## Перед Заливкой На GitHub

Проверить:

```powershell
cd E:\ar\Ar\flutter_application_1
F:\Flutter\flutter\bin\flutter.bat analyze
F:\Flutter\flutter\bin\flutter.bat test
F:\Flutter\flutter\bin\flutter.bat build web
F:\Flutter\flutter\bin\flutter.bat build apk --debug
```

Не добавлять в репозиторий тяжелые локальные исходники и временные файлы: `.zip`, `.mp4`, `.glb`, `.usdz`, `.pptx`, `.docx`, логи и build-кэши. Для этого добавлен корневой `.gitignore`.

Локальный Supabase-конфиг `Ar/flutter_application_1/assets/.env` тоже не коммитится. Для GitHub оставлен шаблон:

```text
Ar/flutter_application_1/assets/.env.example
```

## Recent MVP Additions

- `Карта мест` получила режим “Места рядом”: nearby-маркеры, фильтры категорий и нижнюю панель с местами из Overpass API/fallback.
- Добавлен MVP маршрутов: кнопка маршрутов в шапке карты, список маршрутов, линия на карте, пронумерованные точки и панель прогресса.
- Кнопка `AR` в 3D-режиме теперь открывает встроенный экран `AR-камера`, а не сразу внешний Scene Viewer.
- Свежий debug APK после проверок лежит в `Ar/flutter_application_1/build/app/outputs/flutter-apk/app-debug.apk`.
