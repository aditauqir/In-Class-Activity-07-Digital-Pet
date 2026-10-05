import 'dart:async';
import 'package:flutter/material.dart';

// Application entry point
void main() {
  runApp(const DigitalPetApp());
}

// Root stateless widget configuring MaterialApp theme
class DigitalPetApp extends StatelessWidget {
  const DigitalPetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Pet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Use Material 3 color scheme seeded with teal
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      // Home page holding the mutable state
      home: const DigitalPetHomePage(),
    );
  }
}

// Stateful widget declaration for the home screen
class DigitalPetHomePage extends StatefulWidget {
  const DigitalPetHomePage({super.key});

  @override
  State<DigitalPetHomePage> createState() => _DigitalPetHomePageState();
}

// State class owning pet variables, timers, and lifecycle cleanup
class _DigitalPetHomePageState extends State<DigitalPetHomePage> {
  // Current confirmed pet name
  String _petName = 'Pip';

  // Controller for the pet name input field
  final TextEditingController _nameController = TextEditingController(text: 'Pip');

  // Core pet meters (scale 0 to 100)
  int _happiness = 50;
  int _hunger = 50;

  // Selected undergraduate advanced feature: Energy System (0 to 100)
  int _energy = 70;

  // Terminal state outcome flags
  bool _gameOver = false;
  bool _hasWon = false;

  // Visible status message for user action feedback
  String _actionMessage = 'Take good care of your pet!';

  // Periodic hunger timer reference
  Timer? _hungerTimer;

  // One-shot 3-minute win timer reference
  Timer? _highMoodTimer;

  // 1-second interval timer driving the visible win countdown
  Timer? _countdownTimer;

  // Seconds remaining until the continuous 3-minute win condition is met
  int _winSecondsRemaining = 0;

  // Testing flag: toggles between 5-second hunger / 10-second win and production durations
  bool _fastTestTimers = false;

  // Dynamic hunger interval based on test mode (5s for test, 30s for production)
  Duration get _hungerDuration =>
      _fastTestTimers ? const Duration(seconds: 5) : const Duration(seconds: 30);

  // Target seconds for win condition (10s for fast test, 180s for 3 minutes)
  int get _winTargetSeconds => _fastTestTimers ? 10 : 180;

  @override
  void initState() {
    super.initState();
    // Start periodic hunger timer when widget state initializes
    _startHungerTimer();
  }

  @override
  void dispose() {
    // Cancel all active timers to prevent memory leaks and post-dispose setState calls
    _hungerTimer?.cancel();
    _highMoodTimer?.cancel();
    _countdownTimer?.cancel();

    // Dispose text editing controller owned by this state object
    _nameController.dispose();

    super.dispose();
  }

  // Centralized helper ensuring meter values remain strictly within 0 to 100
  int _clampMeter(int value) => value.clamp(0, 100).toInt();

  // Initiates or restarts the periodic hunger timer
  void _startHungerTimer() {
    _hungerTimer?.cancel();
    _hungerTimer = Timer.periodic(_hungerDuration, (timer) {
      // Guard against callbacks fired after widget unmount or game conclusion
      if (!mounted || _gameOver || _hasWon) {
        timer.cancel();
        return;
      }

      setState(() {
        // Spec Overflow Rule:
        // A tick changing hunger from 95 to 100 does not reduce happiness.
        // A later tick that would exceed 100 clamps hunger at 100 and reduces happiness by 20.
        if (_hunger + 5 > 100) {
          _hunger = 100;
          _happiness = _clampMeter(_happiness - 20);
        } else {
          _hunger += 5;
        }
      });

      // Check win or loss after every timer tick
      _updateOutcome();
    });
  }

  // Evaluates win and loss conditions and updates timer states accordingly
  void _updateOutcome() {
    if (_gameOver || _hasWon) return;

    // Loss Condition: hunger is 100 AND happiness is 10 or lower
    if (_hunger == 100 && _happiness <= 10) {
      _cancelWinTimers();
      _hungerTimer?.cancel();
      setState(() {
        _gameOver = true;
        _actionMessage = 'Game Over: $_petName starved and became very unhappy.';
      });
      return;
    }

    // Win Condition rule: Happiness must remain strictly greater than 80
    // If happiness returns to 80 or below, cancel and clear the win timer
    if (_happiness <= 80) {
      _cancelWinTimers();
      return;
    }

    // Start win countdown if not already running
    if (_highMoodTimer == null) {
      _winSecondsRemaining = _winTargetSeconds;
      _countdownTimer?.cancel();

      // Countdown ticker updating the visible seconds remaining
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted || _gameOver || _happiness <= 80) {
          t.cancel();
          return;
        }
        setState(() {
          if (_winSecondsRemaining > 0) {
            _winSecondsRemaining--;
          }
        });
      });

      // Terminal win timer triggering when happiness remains continuously > 80
      _highMoodTimer = Timer(Duration(seconds: _winTargetSeconds), () {
        _cancelWinTimers();
        if (!mounted || _gameOver || _happiness <= 80) return;
        setState(() {
          _hasWon = true;
          _actionMessage = 'VICTORY: You kept $_petName happy (> 80) continuously!';
        });
        _hungerTimer?.cancel();
      });
    }
  }

  // Helper to cleanly cancel all win-related timers and clear countdown state
  void _cancelWinTimers() {
    _highMoodTimer?.cancel();
    _highMoodTimer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
    if (_winSecondsRemaining != 0) {
      setState(() {
        _winSecondsRemaining = 0;
      });
    }
  }

  // Feed action: reduces hunger and adjusts happiness based on pet fullness
  void _feedPet() {
    if (_gameOver || _hasWon) return;

    final nextHunger = _clampMeter(_hunger - 10);
    // Lab balance: overfeeding (hunger < 30) causes stomachache (-20 happiness); else +10
    final happinessChange = nextHunger < 30 ? -20 : 10;
    final nextHappiness = _clampMeter(_happiness + happinessChange);

    setState(() {
      _hunger = nextHunger;
      _happiness = nextHappiness;
      _actionMessage = nextHunger < 30
          ? 'Overfed $_petName! ($_petName got a stomachache, Happiness -20)'
          : 'Fed $_petName! (Hunger -10, Happiness +10)';
    });

    _updateOutcome();
  }

  // Play action: boosts happiness, slightly raises hunger, and consumes energy
  void _playPet() {
    if (_gameOver || _hasWon) return;

    // Energy system restriction: cannot play if energy is below 15
    if (_energy < 15) {
      setState(() {
        _actionMessage = '$_petName is exhausted (Energy: $_energy)! Let them rest first.';
      });
      return;
    }

    final nextHappiness = _clampMeter(_happiness + 15);
    final nextHunger = _clampMeter(_hunger + 5);
    final nextEnergy = _clampMeter(_energy - 15);

    setState(() {
      _happiness = nextHappiness;
      _hunger = nextHunger;
      _energy = nextEnergy;
      _actionMessage = 'Played with $_petName! (Happiness +15, Hunger +5, Energy -15)';
    });

    _updateOutcome();
  }

  // Rest action: restores energy and slightly increases hunger
  void _restPet() {
    if (_gameOver || _hasWon) return;

    if (_energy >= 100) {
      setState(() {
        _actionMessage = '$_petName is already fully rested!';
      });
      return;
    }

    final nextEnergy = _clampMeter(_energy + 25);
    final nextHunger = _clampMeter(_hunger + 5);

    setState(() {
      _energy = nextEnergy;
      _hunger = nextHunger;
      _actionMessage = '$_petName took a restful nap! (Energy +25, Hunger +5)';
    });

    _updateOutcome();
  }

  // Reset action: restores default values and resets all timer states
  void _resetGame() {
    _cancelWinTimers();
    _hungerTimer?.cancel();

    setState(() {
      _happiness = 50;
      _hunger = 50;
      _energy = 70;
      _gameOver = false;
      _hasWon = false;
      _actionMessage = 'Pet care restarted!';
    });

    _startHungerTimer();
  }

  // Confirms and applies the user-entered pet name from the text controller
  void _confirmPetName() {
    final text = _nameController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _petName = text;
        _actionMessage = 'Pet name updated to $_petName!';
      });
    }
  }

  // Derived pet speech message matching the assignment handout specification
  String get _petMessage {
    if (_gameOver) return 'I need a rest.';
    if (_hasWon) return 'Best day ever!';
    if (_hunger > 80) return "I'm starving!";
    if (_happiness <= 30) return 'Play with me?';
    if (_energy < 20) return 'So sleepy...';
    return "Hi, I'm $_petName!";
  }

  // Derived mood text for accessible non-color feedback
  String get _moodLabel {
    if (_happiness > 70) return 'Happy';
    if (_happiness >= 30) return 'Neutral';
    return 'Unhappy';
  }

  // Derived icon for accessible visual feedback alongside color
  IconData get _moodIcon {
    if (_happiness > 70) return Icons.sentiment_very_satisfied;
    if (_happiness >= 30) return Icons.sentiment_neutral;
    return Icons.sentiment_very_dissatisfied;
  }

  // Derived color threshold based on pet happiness (exact snippet from handout)
  Color get _moodColor {
    if (_happiness > 70) return Colors.green;
    if (_happiness >= 30) return Colors.yellow;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    // Disable action buttons when a terminal game outcome is reached
    final bool controlsDisabled = _gameOver || _hasWon;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Pet - Activity 07'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Toggle button to switch between normal and fast test timers
          IconButton(
            tooltip: _fastTestTimers ? 'Switch to Normal Timers' : 'Switch to Fast Test Timers',
            icon: Icon(
              Icons.speed,
              color: _fastTestTimers ? Colors.orange : null,
            ),
            onPressed: () {
              setState(() {
                _fastTestTimers = !_fastTestTimers;
                _resetGame();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _fastTestTimers
                        ? 'Fast Test Timers: Hunger 5s, Win 10s'
                        : 'Production Timers: Hunger 30s, Win 3min',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card container for editing and confirming pet name
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Pet Name',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _confirmPetName(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _confirmPetName,
                      child: const Text('Set'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Pet display area: circular avatar tinted according to current mood
            Center(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: _moodColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: _moodColor, width: 3),
                ),
                child: Icon(
                  _moodIcon,
                  size: 72,
                  color: _moodColor,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Pet name display header
            Text(
              _petName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),

            // Accessible mood feedback displaying both icon and text label
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_moodIcon, color: _moodColor, size: 20),
                const SizedBox(width: 6),
                Text(
                  'Mood: $_moodLabel',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _moodColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Status and outcome notification banners
            if (_hasWon)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: const Text(
                  'VICTORY: You kept your pet happy (> 80) for 3 continuous minutes!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
              )
            else if (_gameOver)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: const Text(
                  'GAME OVER: Pet hunger reached 100 and happiness dropped to 10 or below.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              )
            else if (_highMoodTimer != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade700),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer, color: Colors.brown, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Win Countdown: ${_winSecondsRemaining ~/ 60}m ${(_winSecondsRemaining % 60).toString().padLeft(2, '0')}s remaining (> 80 Happy)',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.brown,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // Derived speech bubble message from pet state
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                '"$_petMessage"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle detailing the last user action result
            Text(
              _actionMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),

            // Bounded meters section: Happiness, Hunger, and Energy
            _buildMeterRow('Happiness', _happiness, Colors.green),
            const SizedBox(height: 12),
            _buildMeterRow('Hunger', _hunger, Colors.orange),
            const SizedBox(height: 12),
            _buildMeterRow('Energy', _energy, Colors.blue),
            const SizedBox(height: 24),

            // Action control buttons for pet care
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                // Feed button
                ElevatedButton.icon(
                  onPressed: controlsDisabled ? null : _feedPet,
                  icon: const Icon(Icons.restaurant),
                  label: const Text('Feed (-10 Hunger)'),
                ),
                // Play button
                ElevatedButton.icon(
                  onPressed: controlsDisabled ? null : _playPet,
                  icon: const Icon(Icons.sports_baseball),
                  label: const Text('Play (+15 Happy)'),
                ),
                // Rest button
                ElevatedButton.icon(
                  onPressed: controlsDisabled ? null : _restPet,
                  icon: const Icon(Icons.bedtime),
                  label: const Text('Rest (+25 Energy)'),
                ),
                // Reset button restores initial state
                OutlinedButton.icon(
                  onPressed: _resetGame,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget builder for a labeled progress bar meter
  Widget _buildMeterRow(String label, int value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            Text(
              '$value / 100',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            // Normalized double between 0.0 and 1.0 for progress indicator
            value: value / 100.0,
            minHeight: 12,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
