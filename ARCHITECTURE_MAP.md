# 🏛️ Synapse Complete Architecture & Blueprint

এই বিস্তারিত আর্টিকেলে Synapse (No To Distraction) প্রোজেক্টের সমস্ত ফাইলের কাজ, ডেটা ফ্লো এবং কানেকশন খুব সুন্দরভাবে ম্যাপ ও ফ্লোচার্ট আকারে উপস্থাপন করা হলো। প্রোজেক্টটি মূলত তিনটি অংশে বিভক্ত: **১. Android Native**, **২. Flutter Frontend**, এবং **৩. Python Backend**। 

---

## 🗺️ ১. হাই-লেভেল সিস্টেম ম্যাপ (পুরো প্রোজেক্ট কিভাবে কানেক্টেড)

পুরো সিস্টেমের মূল ভিউ নিচের টেক্সট ম্যাপটিতে দেখানো হলো:

```text
================================================================
                    SYNAPSE PROJECT SYSTEM
================================================================

+-------------------------------------------------------------+
| 🤖 ANDROID NATIVE LAYER (Kotlin/Background Service)         |
|                                                             |
|   [ShortVideoAccessibilityService] <--> [ScannerEngine]     |
|             |                                |              |
|             v                                v              |
|     [OverlayManager]            [MethodChannels Bridge]     |
+-------------------------------------------------------------+
                              ||
                              || Platform Data & Events
                              ||
+-------------------------------------------------------------+
| 🦋 FLUTTER FRONTEND LAYER (Dart/UI)                         |
|                                                             |
|   [Screens & Widgets] <------> [State Providers]            |
|             |                        |                      |
|             v                        v                      |
|      [Local Storage]         [API Services & Listeners]     |
+-------------------------------------------------------------+
                              ||
                              || HTTP REST API Requests
                              ||
+-------------------------------------------------------------+
| ⚙️ BACKEND LAYER (FastAPI/Python)                           |
|                                                             |
|   [API Routers] <-----------> [Auth & Utils]                |
|         |                                                   |
|         v                                                   |
|   [(Database - SQLite)]                                     |
+-------------------------------------------------------------+
```

---

## 🤖 ২. Android Native Layer (Kotlin Files)

অ্যান্ড্রয়েড নেটিভ লেয়ার মূলত ইউজার কি দেখছে তা স্ক্যান করে এবং রিলস বা শর্টস পেলে তা ব্লক করে।

```text
+---------------------+
| Android Native Flow |
+---------------------+
 
 [MainActivity] 
       | 
       +----> (Sets up Flutter Bridge) ----> [ReelDetectionChannelBridge]
                                                          ^
 [AccessibilityService]                                   |
       |                                                  |
       +----> (Scans UI Tree for nodes)                   |
                     |                                    |
                     v                                    |
             [ScannerEngine] -----------------------------+ (Sends Event)
                     |
                     +-- (If Reel found) --> [OverlayManager] (Blocks View)
                     |
                     +-- (Reads config) -> [StorageManager]

```

**📂 ফাইল সমূহের কাজ:**
*   **`MainActivity.kt`**: অ্যাপের এন্ট্রি পয়েন্ট। এখান থেকে MethodChannels কনফিগার করা হয় যাতে Flutter এবং Kotlin কথা বলতে পারে।
*   **`ShortVideoAccessibilityService.kt`**: এটি ব্যাকগ্রাউন্ডে সবসময় চলতে থাকে। প্রতিটি স্ক্রিন পরিবর্তন হলে তা রিসিভ করে।
*   **`ScannerEngine.kt`**: কোর ইঞ্জিন। এটি ইউজার স্ক্রিনের লেখা/টেক্সট স্ক্যান করে সোশ্যাল মিডিয়া, রিলস, শর্টস আইডেন্টিফাই করে।
*   **`OverlayManager.kt`**: যখনই `ScannerEngine` রিলস ডিটেক্ট করে, তখন এই ফাইলটি স্ক্রিনের উপর "Not today!" টাইপের ওয়েলকাম ব্লক করে দেয়।
*   **`StorageManager.kt` & `QuickBlockStorage.kt`**: ইউজারের সেটিং (ব্লকিং অন কিনা) Android এর স্টোরেজে সেভ করে।
*   **`ReelDetectionChannelBridge.kt`**: রিল ব্লক হলে কতবার ব্লক হয়েছে সেই সংখ্যাটি Flutter এর কাছে পাঠায়।
*   **`Constants.kt`**: বিভিন্ন সোশ্যাল মিডিয়ার প্যাকেজ নাম এখানে রাখা আছে।
*   **`AccessibilityUtils.kt`**: স্ক্রিনের নোড ট্র্রি খোঁজার জন্য সাহায্যকারী ফাংশন।

---

## 🦋 ৩. Flutter Frontend Layer (Dart Files)

এটি ইউজার ইন্টারফেস। এখান থেকেই ইউজার লগইন করে, ড্যাশবোর্ড ও লিডারবোর্ড দেখে এবং সেটিং চেঞ্জ করে।

```text
+-----------------------+
| Flutter Frontend Flow |
+-----------------------+

 [main.dart]
       |
       v
 [app_routes.dart] ---> [Screens/UI] (Home, Auth, Stats)
                              |
                              v
                        [Providers (State)] (Auth, Stats)
                              |
                              |
       +----------------------+----------------------+
       |                      |                      |
       v                      v                      v
  [Api Services]      [Listener Services]     [Secure Storage]
  (auth, stats API)   (reel_detection.. )     (Saves Token)
```

**📂 ফাইল সমূহের কাজ:**
*   **`main.dart`**: অ্যাপ স্টার্ট হয়, থিম এবং প্রোভাইডার ইনিশিয়ালাইজ করে।
*   **`screens/` ফোল্ডার**: সব ইউজার ইন্টারফেস পেজ। (Dashboard, Login, Leaderboard)
*   **`widgets/` ফোল্ডার**: ছোট ছোট UI ব্লক (যেমন Button, QuickActionsCard)।
*   **`providers/` ফোল্ডার (State Management)**: 
    *   `auth_provider.dart`: ইউজারের লগইন প্রসেস এবং স্টেট মনিটর করে।
    *   `stats_provider.dart`: ইউজারের ডেইলি স্ট্যাটস ফেচ করে মেমোরিতে ধরে রাখে।
*   **`services/` ফোল্ডার**:
    *   `auth_api.dart`, `stats_api.dart`: এগুলো Backend সার্ভারে HTTP রিকোয়েস্ট পাঠায়।
    *   `reel_detection_listener_service.dart`: Native লেয়ার থেকে MethodChannel এর মাধ্যমে ডাটা রিসিভ করে।
    *   `secure_storage_service.dart`: ইউজারের টোকেন মোবাইলে নিরাপদে সেভ রাখে।
*   **`models/` ফোল্ডার**: ডাটাকে JSON থেকে ডার্ট অবজেক্টে রূপান্তর করে।

---

## ⚙️ ৪. Backend Layer (Python / FastAPI)

এখানে সব ডেটাবেস এবং ইউজারের একাউন্ট ইনফো সেভ থাকে।

```text
+---------------------+
| Backend Server Flow |
+---------------------+

 [Flutter App]
       |
       v
   [main.py] ---> [Routers]
                      |
        +-------------+-------------+
        |             |             |
        v             v             v
     auth.py      stats.py     leaderboard.py
        |             |             |
        v             v             v
  [auth_utils.py]     [dependencies.py] <-- Token validation
        |             |             |
        +-------------+-------------+
                      |
                      v
          [database.py / models.py]
          (Reads/Writes Data in DB)
```

**📂 ফাইল সমূহের কাজ:**
*   **`main.py`**: ব্যাকএন্ডের প্রধান হাব এবং এন্টি পয়েন্ট।
*   **`routers/` ফোল্ডার**:
    *   `auth.py`: লগইন, সাইনআপ রিকোয়েস্ট হ্যান্ডেল করে।
    *   `stats.py`: ইউজারের প্রতিদিনের ডিস্ট্রাকশন ব্লক করার কাউন্ট রিসিভ করে।
    *   `leaderboard.py`: টপ ইউজারদের তালিকা পাঠায়।
*   **`models.py`**: ডেটাবেসের টেবিল স্ট্রাকচার (যেমন Users, Stats টেবিল)।
*   **`schemas.py`**: রিকোয়েস্টগুলোর ফরম্যাট কেমন হবে (Pydantic validation) তা ডিফাইন করে।
*   **`utils/` ফোল্ডার**: পাসওয়ার্ড হ্যাশ করা এবং JWT টোকেন তৈরি করার কাজ করে।
*   **`dependencies.py`**: ইউজারের টোকেন চেক করে এটা ভেরিফাই করে।

---

## 🔁 ৫. ডেটা সার্কুলেশন ম্যাপ (Data Flow Sequence)

কিভাবে সবগুলো লেয়ার একসাথে কাজ করে তার একটি বাস্তব উদাহরণ - **"রিল ব্লক করার সময় ডেটা কিভাবে ফ্লো হয়:"**

```text
=============================================================
  HOW A REEL GETS BLOCKED AND DATA IS SAVED TO DATABASE
=============================================================

 (1) [📱 User Action] User opens Facebook Reels
         |
         v
 (2) [🤖 Native] ScannerEngine detects bad video node
         |
         +--> [🤖 Native] Shows OverlayManager ("Not today") -> (User sees view blocked!)
         |
         v
 (3) [🤖 Native] MethodChannel sends (+1 block count) to Flutter
         |
         v
 (4) [🦋 Flutter] Listener Service catches the event
         |
         v
 (5) [🦋 Flutter] Provider updates UI count & makes HTTP POST request
         |
         v
 (6) [⚙️ Backend] Validates user's token using dependencies.py
         |
         v
 (7) [⚙️ Backend] Saves new count to SQLite Database
         |
         v
 (8) [🦋 Flutter] Receives Success code (200 OK)
=============================================================
```

### 📍 সংক্ষেপে ফ্লো:
১. **Native App** রিল শনাক্ত করে তা ব্লক করে।  
২. **MethodChannel** এর মাধ্যমে ইভেন্টটি Flutter কে পাঠায়।  
৩. Flutter এর **Listener** ইভেন্ট ধরে **Provider** এর ডেটা আপডেট করে (UI সাথে সাথে আপডেট হয়)।  
৪. **Provider** নতুন ডেটা HTTP API দিয়ে **Backend** এ পাঠায়।  
৫. **Backend** তা চেক করে **Database** এ সেভ করে রাখে।

এই আর্কিটেকচারটি অত্যন্ত চমৎকারভাবে মডুলার করা, যেন এক অংশের কাজ অন্য অংশকে লুপে না ফেলে স্মুথ কাজ করতে পারে।
