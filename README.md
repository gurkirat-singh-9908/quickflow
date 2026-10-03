# QuickFlow ⚡ (Stage 1)

> **Ultra-Lightweight Floating Bubble for Android**  
> Pure Native Android (Kotlin). Minimalist, always-running floating bubble over all apps.

---

## 🎯 Stage 1 Goal
A minimal, lightweight floating bubble that:
- Stays on your screen over any app (WhatsApp, Instagram, Telegram, browser, games).
- Draggable smoothly across the screen, snapping to the left or right edges.
- Runs persistently via a Foreground Service without getting killed by the OS.
- Super compact: **~1.5 MB APK size** (zero bloat, pure native Android).

---

## 📲 How to Download & Install
1. Download **`QuickFlow.apk`** from [GitHub Releases](https://github.com/gurkirat-singh-9908/quickflow/releases/latest).
2. Install the APK on your Android phone (tap "Download anyway" / allow installation from unknown sources if prompted).
3. Open QuickFlow and tap **"Grant Overlay Permission"** to allow "Display over other apps".
4. Tap **"Start Floating Bubble"** — your floating ⚡ bubble will immediately appear and stay on your screen!

---

## 🛠️ Project Structure
```
├── app/
│   ├── src/main/
│   │   ├── AndroidManifest.xml                     # Overlay & Foreground Service permissions
│   │   ├── kotlin/com/snaphack/quickflow/
│   │   │   ├── MainActivity.kt                     # Single-screen toggle & permission handler
│   │   │   └── FloatingBubbleService.kt            # Always-running overlay & touch drag logic
│   │   └── res/
│   │       ├── layout/activity_main.xml            # Minimal dark UI
│   │       └── layout/floating_bubble_layout.xml   # 56dp circular floating bubble
│   └── build.gradle
├── build.gradle
├── settings.gradle
└── .github/workflows/build-apk.yml                 # Automated Gradle release builder
```
