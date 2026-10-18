# CampusFind – Campus Lost and Found Portal

CampusFind is a clean, responsive Flutter web application designed to help university students, faculty, and staff report, locate, and recover misplaced personal belongings across campus.

---

## 📌 Problem Statement
On a busy college campus, students frequently misplace essential personal items such as student ID cards, scientific calculators, laptop chargers, notebooks, keys, and water bottles. 

Traditional recovery methods—such as physical notice boards, crowded WhatsApp groups, or visiting multiple department security desks—are unorganized, slow, and often result in items remaining unclaimed. 

**CampusFind** solves this issue by offering a centralized, easy-to-use digital portal where lost and found items can be categorized, searched, tracked, and safely recovered by their rightful owners.

---

## ✨ Key Features

- **Report Lost & Found Items**: Simple modal reporting form with input validation for item title, category, campus location, description, and contact details.
- **Instant Search**: Real-time keyword search across item names, descriptions, and campus locations.
- **Filter by Type & Category**:
  - Filter by report type: **All**, **Lost Items**, or **Found Items**.
  - Filter by category chips: *Electronics*, *ID Cards*, *Wallets & Bags*, *Books & Notes*, *Bottles & Tiffin*, *Keys*, and *Other*.
- **Detailed Item View**: Clicking any card opens a dialog showing full item details, campus location, date, contact details, and campus exchange safety reminders.
- **My Reports Dashboard**: Dedicated tab for students to view items they personally posted, toggle items as **Resolved / Returned**, or remove reports.
- **Live Campus Statistics**: Real-time summary counters tracking *Total Active*, *Lost Items*, *Found Items*, and *Recovered Items*.
- **Responsive Layout**: Designed with a navy blue, white, and teal theme that automatically adapts to laptop/desktop screens (sticky sidebar) and mobile viewports (top app bar + bottom navigation bar).

---

## 🛠️ Technologies Used

- **Flutter** (Web SDK) – Modern UI toolkit for building responsive web applications.
- **Dart** – Client-optimized programming language with null safety.
- **Material 3** – Modern design system for cards, badges, chips, and dialogs.
- **shared_preferences** – Local storage library to serialize and persist records in the browser.

---

## 💾 Storage & Limitations

> [!NOTE]
> **Client-Side Storage**: In this version of the project, all user-submitted reports and status updates are saved locally in the browser's persistent storage (`window.localStorage` via `shared_preferences`).
>
> **Limitation**: Reports persist across browser refreshes and application restarts on your local computer, but they are **not shared between different users or external devices**. Connecting a cloud database (such as Firebase Firestore or Supabase) with student authentication is the intended next step for campus-wide multi-user synchronization.

---

## 💻 How to Run the Project Locally

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed (version 3.10+ recommended)
- Google Chrome browser

### Steps

1. **Clone or navigate to the project directory**:
   ```powershell
   cd campuslost
   ```

2. **Fetch dependencies**:
   ```powershell
   flutter pub get
   ```

3. **Run on Flutter Web with Chrome**:
   ```powershell
   flutter run -d chrome
   ```
   *(To lock to a specific local port, run: `flutter run -d chrome --web-port=5000`)*

4. Open Chrome and navigate to the displayed URL (e.g., `http://localhost:5000`).

---

## 🎓 Academic Submission Details
- **Project Title**: CampusFind – Lost and Found Portal
- **Student Name**: Tejaswini N
- **Department**: Computer Science & Engineering
- **Technology Stack**: Flutter Web & Dart
