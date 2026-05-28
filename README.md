# ZoNotes 📝✨

Современные iOS-заметки с встроенным ИИ от **Fireworks AI** и защитой **Face ID** для приватных записей.

- **iOS 16.0+**
- **Swift 5.9 · SwiftUI · CoreData**
- **Fireworks AI** (Llama 3.3 70B по умолчанию, любой OpenAI-совместимый API)
- **Face ID / Touch ID** для приватных заметок
- Поиск, теги, папки, закрепление, Markdown-предпросмотр, ShareLink

## ИИ-возможности

В нижней панели редактора:

- **Спросить ИИ** — свободный вопрос с контекстом заметки
- Кратко изложить · Улучшить стиль · Сократить / Развернуть
- Продолжить мысль · В список · Исправить ошибки
- Перевод RU↔EN · Извлечь задачи · Подсказать заголовок

## Защита заметок 🔒

- В редакторе: меню `⋯` → **«Защитить Face ID»**
- В списке: свайп влево → **«Защитить»**
- При тапе по защищённой заметке система запросит Face ID / Touch ID
- При уходе приложения в фон все разблокировки сбрасываются

## Настройка ИИ

1. Получите ключ на [fireworks.ai](https://fireworks.ai) → **API Keys**
2. В приложении: **Настройки** → вставьте ключ → **«Сохранить»**
3. По умолчанию используется `accounts/fireworks/models/llama-v3p3-70b-instruct`
4. Кнопкой можно переключиться на OpenAI или вручную задать любой OpenAI-совместимый Base URL

Ключ хранится только на устройстве в Keychain — он не уходит ни на какие сервера, кроме выбранного провайдера.

## Запуск

```bash
brew install xcodegen
git clone https://github.com/vantazer561-a11y/zo-ios-tima-notion.git
cd zo-ios-tima-notion
xcodegen generate
open ZoNotes.xcodeproj
```

В Xcode выбрать команду в Signing & Capabilities и запустить.

## Архитектура

```
ZoNotes/
├── App/                 ZoNotesApp · RootView · AppSettings
├── Models/              CoreData-модель Note + Folder, расширения
├── Persistence/         PersistenceController (боевой + preview)
├── Services/            AIService · KeychainStore · BiometricAuth
├── Views/
│   ├── NotesListView    список + поиск + папки
│   ├── NoteEditorView   редактор + AI-тулбар + меню
│   ├── AskAISheet       свободный диалог с моделью
│   ├── AIToolbar        быстрые AI-действия
│   ├── MarkdownView     рендер превью
│   ├── FolderManagerView · SettingsView · Components/
└── Resources/           Assets.xcassets · Info.plist
```

## Лицензия

MIT.
