# QuickFlow (SnapHack) ⚡

> **Floating Text Palette & Instant Text Injection Assistant for Android**  
> Inspired by the speed and fluidity of Wispr Flow, tailored for chatting, messaging, and dating apps.

---

## 📱 What is QuickFlow?

QuickFlow is a persistent floating bubble app designed for power-chatters who find themselves repeating common questions, openers, and replies across WhatsApp, Instagram, Telegram, Tinder, or SMS.

Instead of typing everything from scratch or copying and pasting manually:
1. **The Floating Bubble** stays smoothly docked on the edge of your screen over any app.
2. **Tap the bubble** anytime you are chatting to expand the **Quick Text Palette**.
3. **Tap any phrase** (e.g., *"How are you doing today?"*, *"Where are you from originally?"*) to **instantly inject and type it** directly into the active chat field!
4. **Smart Conversation Memory**: When you use an opener or small talk phrase in a specific conversation, QuickFlow remembers and tags or filters it out for that chat session so you never repeat yourself.

---

## 🛠️ Architecture

QuickFlow combines a modern Flutter companion app with an Android system-level `AccessibilityService`:

```
┌────────────────────────────────────────────────────────┐
│  WhatsApp / Instagram / Telegram / Any Chat App       │
│                                                        │
│  [ Chat Messages ... ]                                 │
│                                                        │
│  ┌───────────────────────┐    (⚡) Floating Bubble     │
│  │ Type a message...     │     ▲ (Draggable, snaps     │
│  └───────────────────────┘     │  to screen edge)      │
│               ▲                │                       │
│               │ Injects Text   │ Tapped                │
│               │                ▼                       │
│        ┌─────────────────────────────┐                 │
│        │  💬 QuickFlow Palette       │                 │
│        │  [Openers] [Small Talk] [+] │                 │
│        │  • "How are you doing?"     │                 │
│        │  • "Where are you from?"    │                 │
│        │  • "Sounds great! 🙌"       │                 │
│        └─────────────────────────────┘                 │
└────────────────────────────────────────────────────────┘
```

### Core Components:

1. **`QuickFlowAccessibilityService`** (`android/.../QuickFlowAccessibilityService.kt`):
   - Background system accessibility service with window content retrieval.
   - Detects the currently active app package and focused `EditText`.
   - Injects text via `AccessibilityNodeInfo.ACTION_SET_TEXT` or `ACTION_PASTE`.
   - Completely bypasses clipboard friction.

2. **`FloatingPaletteManager`** (`android/.../FloatingPaletteManager.kt`):
   - Manages the floating `WindowManager` views (`TYPE_APPLICATION_OVERLAY` / `TYPE_ACCESSIBILITY_OVERLAY`).
   - Smooth gesture recognition (drag to move, snap to left/right screen edges, tap to expand).
   - Card layout with categories, search bar, phrase list, and quick custom inject box.

3. **`SmartChatMemory`** (`android/.../SmartChatMemory.kt`):
   - Tracks which categories and phrases have been used per conversation/app package.
   - Automatically dims or hides used categories (e.g. Openers) so you don't send the same question twice.

4. **Flutter Companion UI** (`lib/`):
   - `HomeScreen`: Status indicators, toggle floating bubble switch, category tabs, and sandbox test input.
   - `AddEditPhraseScreen`: Add new phrases with tags, categories, and custom keywords.
   - `CategoriesScreen`: Manage custom categories, icons, colors, and toggle smart deduplication.
   - `SettingsScreen`: Adjust bubble size, opacity slider (40% - 100%), and permission shortcuts.

---

## 🚀 How to Run & Build

### Prerequisites:
- Android SDK (API 24+ / Android 7.0 to Android 14)
- Flutter SDK (3.0.0+) or Android Studio

### Running the App:
```bash
# 1. Fetch Flutter dependencies
flutter pub get

# 2. Run on connected Android device or emulator
flutter run
```

### Granting Required Permissions on Android:
1. **Display Over Other Apps**:
   - `Settings > Apps > QuickFlow > Display over other apps > Allow`
2. **Accessibility Service**:
   - `Settings > Accessibility > QuickFlow > Turn On`
