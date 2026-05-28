# ZoNotes 📝✨

Современные iOS-заметки с встроенным ИИ. Чистый SwiftUI, CoreData, OpenAI-совместимый API.

- **iOS 16.0+**
- **Swift 5.9 / SwiftUI / CoreData**
- **OpenAI-совместимый API** (ключ хранится в Keychain)
- Поиск, теги, папки, закрепление, Markdown-предпросмотр, ShareLink

## ИИ-возможности

Все действия — в нижней панели редактора:

- **Спросить ИИ** — свободный вопрос с контекстом заметки
- Кратко изложить · Улучшить стиль · Сократить / Развернуть
- Продолжить мысль · В список · Исправить ошибки
- Перевод RU ↔ EN · Извлечь задачи · Подобрать заголовок

## Запуск

```bash
# 1. Установите XcodeGen (один раз)
brew install xcodegen

# 2. Сгенерируйте Xcode-проект
cd zo-ios-tima-notion
xcodegen generate

# 3. Откройте
open ZoNotes.xcodeproj
```

В Xcode выберите команду подписания (Signing & Capabilities → Team) и запустите на симуляторе или устройстве с iOS 16+.

## Настройка ИИ

1. Запустите приложение → ⚙️ **Настройки**
2. Вставьте OpenAI-совместимый ключ (`sk-…`) → **Сохранить ключ**
3. По умолчанию используется `gpt-4o-mini`. Можно сменить модель и Base URL (поддерживаются OpenRouter, локальные прокси и т.д.).

> Ключ хранится **только** на устройстве в Keychain. Сервер не используется.

## Структура

```
ZoNotes/
├── App/                 # точка входа, AppSettings, RootView
├── Models/              # CoreData-модель и расширения
├── Persistence/         # PersistenceController
├── Services/            # AIService, KeychainStore
├── Views/               # SwiftUI-экраны
│   └── Components/
└── Resources/           # Info.plist, Assets.xcassets
```

## Лицензия

MIT.
