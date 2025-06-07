# 💧 Hydration Tracker

**Hydration Tracker** is a smart, cross-platform application (available as SwiftUI for iOS and HTML/CSS/JavaScript for web) that helps users monitor and improve their daily water intake through scheduled servings, progress visualizations, notifications, and personalized recommendations.

---

## 📱 Features

### 🌟 Universal Features
- 🎯 Personalized hydration goals based on **weight**
- 🛌 Sleep schedule integration for optimal reminder timing
- ⏰ Smart reminders with **in-app and push notifications**
- 📈 Daily stats, progress visualization, and motivational feedback
- 🔐 Data saved with `AppStorage` (iOS) or `localStorage` (Web)

### 🧑‍💻 SwiftUI (iOS/macOS)
- Modular and reusable UI components (`StatCard`, `ProgressCard`, `LabelTextField`)
- Dark/Light mode switcher
- Alerts and modals for confirmation and warnings
- History tracking with hydration logs and visual feedback
- Notification integration using `UserNotifications`
- MVVM-friendly architecture and preview support

### 🌐 Web App (HTML/CSS/JS)
- Fully responsive animated UI
- LocalStorage-based hydration and user data tracking
- Sleep summary, serving logs, and daily history view
- Beautiful animations, dark mode, and interactive time buttons
- No dependencies — fully built with vanilla HTML, CSS & JS

---

## 🛠 Tech Stack

| Platform | Language/Framework |
|----------|---------------------|
| iOS/macOS | SwiftUI, Combine, Swift 5 |
| Web | HTML5, CSS3, JavaScript ES6 |

---

## 📷 Screenshots

| Light Mode | Dark Mode |
|------------|-----------|
| ![Light Screenshot](https://placehold.co/300x600/light?text=Light+Mode) | ![Dark Screenshot](https://placehold.co/300x600/dark?text=Dark+Mode) |

---

## 🚀 How to Run

### iOS App (SwiftUI)
1. Open the `.xcodeproj` in **Xcode 14+**
2. Run on **iPhone Simulator** or your device
3. Allow notifications when prompted

### Web App
1. Open `Hydration tracker.html` in any browser
2. Allow notifications when prompted
3. Fill out your info → Click "Calculate Goal" → Track your day!

---

## 📦 File Structure (SwiftUI)
HydrationTracker.swift        # Main view containing UI logic and state
SettingsView.swift            # User settings view (name, DOB, height, weight, sleep)
Components/
│
├── StatCard.swift            # Card to display stats like daily goal and per serving
├── ProgressCard.swift        # Progress bar showing intake vs. goal
├── ServingRow.swift          # List row for each serving time
├── LabelTextField.swift      # Reusable text input field with label
├── LabelDatePicker.swift     # Reusable date picker with label
Models/
│
├── HydrationProgress.swift   # Model for tracking servings and times
└── HydrationLog.swift        # Model for storing daily hydration log with feedback
Helpers/
│
├── NotificationManager.swift # Schedules and manages reminders (if extracted)
├── FormatterUtils.swift      # Formatters for dates and numbers
Preview/
└── HydrationTracker_Previews.swift # Preview configurations for different devices


---

## ✍️ Author

**Zyan Shaikh**

---

## 📝 License

This project is licensed under the [MIT License](LICENSE).

---

## ❤️ Acknowledgments

- SwiftUI team for clean reactive UI architecture
- Apple for `UserNotifications` and `AppStorage`
- Pure CSS animation inspirations from Dribbble & CodePen
