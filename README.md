# In-Class Activity 07: Digital Pet State Lab

Collaborative Flutter state-management simulation app built with `StatefulWidget`, `setState()`, lifecycle-aware timers, and accessible feedback.

## Team Workstreams & Collaborators
- **Pathway**: Undergraduate Pathway
- **Team 1 (Care Systems & Core State)**:
  - **Member**: Adi Tauqir ([@aditauqir](https://github.com/aditauqir))
  - **Responsibilities**: Care loop, bounded state meters (0-100), timer lifecycles (30-second hunger, 3-minute continuous win), energy system, outcome rules, state boundary tests.
  - **Pull Request**: [#1: Care Systems & Logic](https://github.com/aditauqir/In-Class-Activity-07-Digital-Pet/pull/1)
- **Team 2 (Pet Personality & Visual Polish)**:
  - **Member**: [Wilder Edwards](https://github.com/WilderEdwards) ([@WilderEdwards](https://github.com/WilderEdwards))
  - **Responsibilities**: Transparent pet PNG asset, `ColorFiltered` mood tinting, visual polish bundle (`AnimatedScale` bounce, `AnimatedSwitcher`, `TweenAnimationBuilder` living meters, action reactions), reduced-motion support.
  - **Pull Request**: [#2: Pet Personality & UI](https://github.com/aditauqir/In-Class-Activity-07-Digital-Pet/pull/2)

---

## App Screenshots

| Neutral Mood (Initial State) | Happy Mood (> 80 with Win Timer) | Unhappy Mood (< 30 Overfed State) |
| :---: | :---: | :---: |
| ![Neutral](screenshots/app_neutral.png) | ![Happy](screenshots/app_happy.png) | ![Unhappy](screenshots/app_unhappy.png) |

---

## Implemented Features (Undergraduate Scope)

### Core Care Systems (Team 1)
- **Pet Name**: Configurable pet name with an input field and confirmed display; `TextEditingController` cleanly released in `dispose()`.
- **Bounded State Meters (0-100)**:
  - **Happiness** (starts at 50, clamped strictly between 0 and 100).
  - **Hunger** (starts at 50, clamped strictly between 0 and 100).
- **Core Actions**:
  - **Feed**: Decreases hunger by 10. If resulting hunger is $< 30$ (overfeeding), happiness decreases by 20; otherwise happiness increases by 10.
  - **Play**: Increases happiness by 15, increases hunger by 5, and drains 15 energy.
  - **Reset**: Restores meters to default (50/50/70), cancels active win timers, resets game outcomes, and starts a fresh hunger timer.
- **Timer Lifecycle Management**:
  - **30-Second Periodic Hunger Timer**: Started in `initState()` and canceled in `dispose()` and on game over/win.
  - **Overflow Penalty Rule**: A tick reaching 100 does not penalize happiness; subsequent ticks while at 100 reduce happiness by 20.
  - **3-Minute Win Timer**: Continuous happiness $> 80$ starts a 3-minute win timer. If happiness drops to $\le 80$, the win timer is canceled and cleared.
  - **Loss Condition**: Triggered when Hunger reaches 100 AND Happiness drops to $\le 10$. All care controls are disabled until Reset.
- **Fast Test Timer Toggle**:
  - App bar action toggle allows switching between **Production Timers** (30s hunger, 3-minute win) and **Fast Test Timers** (5s hunger, 10s win) for rapid evaluation and grading.

### Advanced Feature 1: Energy System (Team 1)
- **Energy Meter (0-100)**: Starts at 70.
- **Costs**: Playing costs 15 energy. If energy drops below 15, pet is exhausted and cannot play until rested.
- **Recovery**: Rest / Nap action restores +25 energy (and slightly increases hunger by +5).

### Advanced Feature 2: Visual Polish & Accessible Motion (Team 2)
- **Transparent Asset Tinting**: Uses `ColorFiltered` with `BlendMode.modulate` on `assets/pet.png`:
  - Green when happiness $> 70$.
  - Yellow when happiness is between 30 and 70.
  - Red when happiness $< 30$.
- **Accessible Presentation**: Accompanied by text labels and mood icons so color is never the sole indicator.
- **Action Bounce & Scale**: Wraps the pet in `AnimatedScale` with responsive scaling on actions and mood bands.
- **Living Meters**: Employs `TweenAnimationBuilder<double>` for smooth meter transitions.
- **Speech Bubble & Expression Crossfade**: Uses `AnimatedSwitcher` to crossfade derived pet messages.
- **Reduced Motion Support**: Honors `MediaQuery.of(context).disableAnimations` to disable non-essential motion.

---

## Setup & Running the App

```bash
# Get dependencies
flutter pub get

# Run static analysis
flutter analyze

# Run automated tests
flutter test

# Run app on connected device or emulator
flutter run

# Build release APK
flutter build apk --release
```

---

## Automated Test Evidence

Both test suites pass with zero warnings:
1. `test/widget_test.dart`: Verifies initial rendering, feed action, play action, and reset.
2. `test/state_boundary_test.dart`:
   - Clamping meters at lower (0) and upper (100) bounds.
   - Energy exhaustion restrictions on play.
   - Win condition timer initiation strictly above 80 (and not at 80).
   - Reset behavior cancelling win timer and restoring defaults.
