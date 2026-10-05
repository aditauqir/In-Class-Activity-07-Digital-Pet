# In-Class Activity 07: Digital Pet State Lab

Collaborative Flutter state-management simulation app built with `StatefulWidget`, `setState()`, lifecycle-aware timers, and accessible feedback.

## Team Workstreams & Roles
- **Pathway**: Undergraduate Pathway
- **Team 1 (Care Systems & Core State)**:
  - Owner: Care loop, bounded state meters, timer lifecycles, and game outcome logic.
  - Branch: `team-1/care-systems`
- **Team 2 (Pet Personality & Visual Polish)**:
  - Owner: Pet visual assets, mood tinting (`ColorFiltered`), expression animations, accessible motion.
  - Branch: `team-2/pet-personality`

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

---

## Setup & Running the App

```bash
# Get dependencies
flutter pub get

# Run static analysis
flutter analyze

# Run automated state boundary and widget tests
flutter test

# Run the app on connected device / emulator
flutter run
```

---

## Automated Test Suite
Team 1 provides automated test suites verifying state boundaries and timer behaviors:
1. `test/widget_test.dart`: Verifies rendering, feed action, play action, and reset.
2. `test/state_boundary_test.dart`:
   - Clamping meters at lower (0) and upper (100) bounds.
   - Energy exhaustion restrictions on play.
   - Win condition timer initiation strictly above 80 (and not at 80).
   - Reset behavior cancelling win timer and restoring defaults.
