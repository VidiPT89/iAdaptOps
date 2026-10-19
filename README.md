# 🤸 iAdaptOps

> Gentle, caring exercise for people living with chronic conditions. A short health questionnaire shapes a personal 28-session plan: four days a week, 10 to 17 minutes, at home, with a chair and, if it suits you, a mat.

[![Report Bug](https://img.shields.io/badge/Report-Bug-red)](https://github.com/VidiPT89/iAdaptOps/issues)
[![Request Feature](https://img.shields.io/badge/Request-Feature-blue)](https://github.com/VidiPT89/iAdaptOps/issues)
[![CI](https://github.com/VidiPT89/iAdaptOps/actions/workflows/ios.yml/badge.svg)](https://github.com/VidiPT89/iAdaptOps/actions/workflows/ios.yml)

<p align="center">
  <img src="assets/logo.jpg" alt="iAdaptOps logo" width="420">
</p>

<p align="center">
  <img src="assets/sign-in.jpg" alt="iAdaptOps sign-in screen with email and Apple accounts (shown in Portuguese, the app is bilingual)" width="280">
</p>

## ✨ Features

- ✅ Personal accounts: sign up with email and password or continue with Apple; Google and Microsoft appear once they are enabled in the Firebase console
- ✅ One admin account with a private panel: every account's progress and check-ins, program assignment and profiles prepared ahead of time by email
- ✅ Progress synced to your account with Cloud Firestore, so it follows you to any iPhone or iPad, and keeps working offline
- ✅ A health questionnaire at sign-up (conditions, limitations, energy, age, weight) that generates a personal 28-session care plan on the device
- ✅ Plans that respect every answer: seated alternatives, no floor work when getting down is hard, no joint loads that hurt, supported balance only
- ✅ Fixed plans the admin can assign instead, such as Ana's 28-day challenge, kept exactly as written
- ✅ 33 exercises, including seated, chair-supported and wall-based care exercises, each with its own animated demonstration
- ✅ Stick-figure animations drawn live with `Canvas` and `TimelineView`: every movement is generated from code, no video and no image assets
- ✅ Guided session player with a date-anchored timer that never drifts, even if the screen locks mid-set
- ✅ Spoken countdown, interval sounds and haptics, with a "switch sides" cue halfway through every unilateral exercise; your music keeps playing and only dips while the voice speaks
- ✅ Low-energy mode: shorter work intervals, longer rests, one round fewer, no added load and slower demonstrations, decided per day
- ✅ Seated version on low-energy days: the warm-up and every exercise swap to chair-based moves with the same focus
- ✅ Home-screen and lock-screen widget with today's workout, rest days and your progress ring
- ✅ Optional Apple Health integration: each finished session is saved as a workout (write-only, nothing is ever read)
- ✅ Progress tracking with a session history, weekly progress, total minutes and five unlockable achievements
- ✅ Local workout reminders at the time and on the weekdays you choose (Monday to Thursday by default)
- ✅ Exercise library with step-by-step instructions, breathing cues, common mistakes and an easier version of every movement
- ✅ Animated splash screen with developer credits, then straight into the app
- ✅ Runtime language switch: Português (PT-PT) and English, independent of the system locale
- ✅ Dark mode, Light mode and System mode
- ✅ Colour identity taken from [ividi.dev](https://ividi.dev/): burnt orange, amber and near-black
- ✅ Accessibility: VoiceOver labels, Dynamic Type and full Reduce Motion support
- ✅ Private by design: each account can only reach its own data, no analytics, no ads, and in-app account deletion

## 🛠️ Tech Stack

| Category | Technology |
|----------|------------|
| Language | Swift 5.9 |
| UI | SwiftUI |
| Graphics | Canvas + TimelineView |
| Architecture | MVVM with `@Observable` |
| Persistence | SwiftData (per-account store on device) |
| Accounts & sync | Firebase Authentication + Cloud Firestore |
| Sign-in | Email/password, Sign in with Apple, Google Sign-In, Microsoft (OAuth) |
| Audio | AVSpeechSynthesizer + system sounds (no audio files) |
| Notifications | UserNotifications |
| Widget | WidgetKit (App Group shared with the app) |
| Health | HealthKit (workouts, write-only) |
| Project | XcodeGen |
| Min. iOS | 17.0 |

## 🚀 Quick Start

### Prerequisites

- macOS with Xcode 15+
- iOS 17+ Simulator or device
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

### Installation

```bash
git clone https://github.com/VidiPT89/iAdaptOps.git
cd iAdaptOps
xcodegen generate
open iAdaptOps.xcodeproj
```

Build and run (`⌘R`) on the simulator or a connected device.

### Firebase

The app talks to the Firebase project `iadaptops-vidi`. Its iOS config lives in `iAdaptOps/Config/GoogleService-Info.plist`; after enabling a new sign-in provider in the console, refresh it with:

```bash
sh scripts/fetch-firebase-config.sh
```

Firestore security rules (`firebase/firestore.rules`) keep every account to its own data; only the admin, identified by a verified email, can read other accounts, assign programmes and prepare profiles. A build phase reads that file and registers the URL schemes Google and Microsoft sign-in return on. Deploy the rules with `firebase deploy --only firestore`.

> The Xcode project is generated from `project.yml` and is not committed. If you add or move Swift files, regenerate it with `xcodegen generate`.

## 📖 Usage

1. Create an account, or continue with Apple, Google or Microsoft
2. Run through the short onboarding and confirm you have medical clearance to exercise
3. Open **Today** and start the session the programme has queued for you
4. Follow the animated figure: it loops at the pace you should be moving at
5. Rest screens preview the next exercise, so you always know what is coming
6. Feeling flat? Turn on **Low-energy day** before starting, or switch to it mid-session, and the whole workout adapts

Days unlock in order and missing a day costs you nothing, the programme simply waits. Friday to Sunday are rest days by design.

Language, appearance, sounds, voice, haptics, reminders and your account (sign out, delete) are all in Settings.

## 🗓️ The Programme

iAdaptOps is made for people living with chronic conditions: gentle, caring movement that adapts to the body and the energy of each person.

### Personalized care plans

New accounts answer a short questionnaire during onboarding: age, weight and height, chronic conditions (fibromyalgia, ME/CFS, long COVID, POTS, arthritis, lupus, Behçet's, MS, Parkinson's, heart and lung conditions, osteoporosis, postpartum and more), physical limitations, typical energy and recent activity. Everything is optional and can be updated from Settings.

From those answers, `CarePlanGenerator` builds 28 sessions on the device, with fixed, tested rules:

| Answer | Effect on the plan |
|--------|--------------------|
| Activity, energy, age | Pace tier: very gentle (20 s work / 40 s rest), gentle or moderate, never more than 3 rounds or 45 s |
| ME/CFS, long COVID, POTS | Always the gentlest tier; seated or lying down only |
| Can't get down to the floor, Parkinson's, BMI ≥ 40 | No floor or kneeling exercises |
| Knee, wrist or shoulder pain | Nothing that loads that joint |
| Heart condition, asthma or COPD | No held efforts such as the wall sit |
| Osteoporosis | No bending, twisting or end-of-range movement |
| Dizziness, MS, age 75+ | Balance work only with both hands on the chair |

Each week has four themes (mobility and breathing, gentle strength, core and breathing, balance and full body), with a gentle warm-up and a stretching and breathing close chosen to suit the person. Sessions last 10 to 17 minutes.

### Fixed plans

The admin can assign a fixed plan instead. **Ana's 28-day challenge** follows her written plan exactly: 28 workouts over seven weeks at 40/20 to 50/10 seconds, water bottles on the days where the plan uses them, and the stretches as written (two one-minute stretches per day in week 1, then 30 s per side).

## 🧪 Testing

```bash
xcodebuild -project iAdaptOps.xcodeproj -scheme iAdaptOps \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

107 tests cover the care plan generator and every questionnaire rule, the programme data and Ana's plan, the session builder, the animation poses, the translations, the view models, the sign-in form, the admin role and the cloud sync merge rules.

The Firestore security rules have their own tests against the local emulator (needs Java):

```bash
cd firebase/tests && npm install && npm test
```

## 🔒 Privacy

Your account stores only your sign-in details, your programme settings and your workouts, in Firebase in the EU. Security rules keep every account to its own data, there are no analytics or ads, and the account can be deleted from Settings at any time. See [PRIVACY.md](PRIVACY.md) for the full policy.

> This app is a general fitness guide and not a medical device. Always consult a healthcare professional before starting.

## 📄 License

Distributed under the MIT License. See [LICENSE](LICENSE) for details.

## 👨‍💻 Author

**David Arsénio Martins**

- 🌐 Website: [ividi.dev](https://ividi.dev/)
- 🐙 GitHub: [@VidiPT89](https://github.com/VidiPT89/)

## 🤝 Contributing

Contributions, issues and feature requests are welcome. Feel free to check the [issues page](https://github.com/VidiPT89/iAdaptOps/issues).

---

<p align="center">Developed by <a href="https://ividi.dev">David Arsénio Martins</a></p>
<p align="center">⭐ If you like this project, give it a star!</p>
