# Be Present — School Attendance App

A **local-first** school attendance management app for Android, built with Flutter and Drift (SQLite). Teachers mark daily attendance (Present / Absent / Late) and send SMS notices to parents — no backend required. Version 2 adds a **student portal**, **homework assignments & submissions**, **Google Sheets sync**, PIN lock, backup/restore, and CSV exports.

## Features
- **Admin role**: manage classes, divisions, students (with parent/guardian info), teachers, and teacher–class assignments; attendance overviews, per-student reports, and a school-wide stats dashboard with a 7-day chart.
- **Teacher role**: take daily attendance with Mark-All-Present, view history, per-student reports, send SMS to parents, and create homework assignments with due dates, class/division targeting, and submission review.
- **Student role**: instant login with **roll number + date of birth** (no account needed); view your own attendance report with charts, pending/submitted homework, and submit answers **with optional file attachments**.
- **Homework tracking**: teacher sees who submitted (pending / submitted / late / missing), gives feedback, and can download or share the saved attachment.
- **Cloud sync (optional)**: push attendance and homework-submission rows to a **Google Sheet you own** via a free Google Apps Script web app URL configured in Profile → Cloud Sync. No student data touches any third party — you control the sheet.
- **App lock**: optional 4-digit PIN shown at launch (Profile → App Lock).
- **Backup & restore**: export a full SQLite snapshot via the share sheet and restore it later (Profile → Backup & Restore).
- **Export**: attendance, student, and homework reports as CSV, shared to Drive/email/messaging (Profile → Export Reports).
- **Offline-first**: everything is stored in local SQLite via Drift and works with no internet.

## Demo accounts (seeded on first launch)
| Role    | Username      | Password / Credentials             |
|---------|---------------|------------------------------------|
| Admin   | `admin`       | `admin123`                         |
| Teacher | `sharma`      | `teacher123`                       |
| Student | Roll `101`    | DOB `12-05-2012` (Class 8A)        |

## Tech stack
- Flutter + Dart, Material 3
- Drift (SQLite) with generated DAOs / companions
- Riverpod (state + streams), GoRouter (navigation)
- fl_chart for charts, `http` for Apps Script sync, `share_plus` for shares, `file_picker` for attachments, crypto for password/PIN hashing

## Build & run
```bash
cd be_present
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # regenerates Drift code
flutter run                                               # debug on device/emulator
flutter build apk --release                               # release APK
```

The release APK is produced at `build/app/outputs/flutter-apk/app-release.apk`
(application id `com.bepresent`).

## Google Sheets sync setup
1. Open [script.google.com](https://script.google.com) → New Project.
2. Paste the Apps Script snippet shown in **Profile → Cloud Sync → Show Setup Guide & Script** into `Code.gs`.
3. Deploy → New deployment → **Web app**: *Execute as* "Me", *Who has access* "Anyone".
4. Copy the `/exec` URL into the Cloud Sync screen, enable sync, and tap *Sync Now*.

## Notes / limitations
- Local data is **not encrypted** at rest. PIN lock is a convenience lock, not a security boundary.
- INTERNET permission (declared in the manifest) is used only when Google Sheets sync is enabled.
- The app launches the device's SMS composer; it has no capability to auto-send messages.