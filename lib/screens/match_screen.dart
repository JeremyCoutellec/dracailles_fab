import 'dart:async';

import 'package:fab_dracailles/theme/colors.dart';
import 'package:flutter/material.dart';

import '../models/game_player_model.dart';
import '../widgets/life_tracker_widget.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  _MatchScreenState createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final GlobalKey<LifeTrackerWidgetState> _player1Key = GlobalKey();
  final GlobalKey<LifeTrackerWidgetState> _player2Key = GlobalKey();

  late List<GamePlayer> _players;
  late List<String> _history;

  String _matchType = "Standard";
  final int _dieSides = 6;
  int _rolledNumber = 1;
  bool _rolling = false;
  int _timerDuration = 55 * 60; // 50 minutes in seconds
  int _timeLeft = 55 * 60; // Timer duration in seconds
  Timer? _timer;
  bool _timerStarted = false; // Track if the timer has started
  final List<Color> _colorsToSelect = ThemeColors.colorsPlayerGame;

  void initGame() {
    _players = [
      GamePlayer(
        name: 'Joueur 1',
        color: _colorsToSelect[0],
      ),
      GamePlayer(
        name: 'Joueur 2',
        color: _colorsToSelect[1],
      ),
    ];
    _history = [];
  }

  @override
  void initState() {
    super.initState();
    initGame();
  }

  @override
  dispose() {
    super.dispose();
    _timer?.cancel();
  }

  void _resetGame() {
    _players[0].life = 40;
    _players[1].life = 40;
    setState(() {
      _history = [];
      _timeLeft = _timerDuration; // Reset the timer
      _timerStarted = false; // Allow the timer to be started again
    });
    _timer?.cancel();
  }

  void _reversePlayers() {
    setState(() {
      _players = List.from(_players.reversed);
      _player1Key.currentState?.resetLife();
      _player2Key.currentState?.resetLife();
    });
  }

  Future<void> _rollDie() async {
    setState(() {
      _rolling = true;
    });

    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      setState(() {
        _rolledNumber =
            (1 + (DateTime.now().millisecondsSinceEpoch % _dieSides));
      });
    }

    setState(() {
      _rolling = false;
      _history.add("Rolled: $_rolledNumber");
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Die Roll ($_dieSides sides)"),
        content: Text("You rolled a $_rolledNumber"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void changePlayersColor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Changer la couleur des joueurs"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _players.asMap().entries.map((entry) {
            int index = entry.key;
            GamePlayer player = entry.value;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      color: player.color,
                      alignment: Alignment.center,
                      child: Text(
                        player.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      selectPlayerColor(index);
                    },
                    child: const Text("Changer la couleur"),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Fermer"),
          ),
        ],
      ),
    );
  }

  void selectPlayerColor(int playerIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Changer la couleur de ${_players[playerIndex].name}"),
        content: Wrap(
          spacing: 10,
          children: _colorsToSelect.map((color) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _players[playerIndex].color = color;
                });
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                changePlayersColor();
              },
              child: CircleAvatar(backgroundColor: color),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Annuler"),
          ),
        ],
      ),
    );
  }

  void showHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Life Changes History"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _history.map((entry) => Text(entry)).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Settings"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Match Type"),
                DropdownButton<String>(
                  value: _matchType,
                  dropdownColor: Colors.white,
                  focusColor: Colors.white,
                  items: const [
                    DropdownMenuItem(
                      value: "Classic Constructed",
                      child: Text("Classic Constructed"),
                    ),
                    DropdownMenuItem(
                      value: "Blitz",
                      child: Text("Blitz"),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _matchType = value;
                        _timerDuration = value == "Classic Constructed"
                            ? 55 * 60
                            : 35 * 60; // 50 minutes or 1 hour
                        _timeLeft = _timerDuration; // Reset timer duration
                      });
                    }
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void startTimer() {
    _timeLeft = _timerDuration; // Reset timer to match duration
    setState(() {
      _timeLeft--; // Reset timer to match duration
      _timerStarted = true; // Disable logo click
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_timerStarted) return;

      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _timer!.cancel(); // Stop timer when it reaches zero
        }
      });
    });
  }

  void toggleTimer() {
    setState(() {
      _timerStarted = !_timerStarted;
    });
  }

  void addToHistory(String entry) {
    setState(() {
      _history.add(entry);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Stack(
        children: [
          // Players and their life trackers
          Column(
            children: [
              LifeTrackerWidget(
                gamePlayer: _players[0],
                invertMode: true,
                onLifeChanged: (amount) {
                  addToHistory(
                      "${_players[0].name} ${amount > 0 ? "gained" : "lost"} ${amount.abs()} life");
                },
              ),
              LifeTrackerWidget(
                gamePlayer: _players[1],
                onLifeChanged: (amount) {
                  addToHistory(
                      "${_players[1].name} ${amount > 0 ? "gained" : "lost"} ${amount.abs()} life");
                },
              ),
            ],
          ),

          // Centered logo and action bar in a stacked layout
          Align(
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Action bar background (full width)
                Container(
                  color: Colors.white,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left-side buttons
                      Row(
                        children: [
                          IconButton(
                            onPressed: showSettings,
                            icon: const Icon(Icons.settings, size: 30),
                            tooltip: "Settings",
                          ),
                          IconButton(
                            onPressed: showHistory,
                            icon: const Icon(Icons.history, size: 30),
                            tooltip: "View History",
                          ),
                          IconButton(
                            onPressed: _rollDie,
                            icon: const Icon(Icons.casino, size: 30),
                            tooltip: "Roll Die",
                          ),
                        ],
                      ),

                      // Right-side buttons
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => changePlayersColor(),
                            icon: const Icon(Icons.color_lens, size: 30),
                            tooltip: "Changer Couleur Joueur",
                          ),
                          IconButton(
                            onPressed: _reversePlayers,
                            icon: const Icon(Icons.swap_horiz, size: 30),
                            tooltip: "Swap Players",
                          ),
                          IconButton(
                            onPressed: _resetGame,
                            icon: const Icon(Icons.refresh, size: 30),
                            tooltip: "Reset Life",
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Logo placed on top of the action bar
                Positioned(
                  top: -37, // Adjust to ensure overlap
                  child: GestureDetector(
                    onTap: _timerDuration == _timeLeft
                        ? startTimer
                        : toggleTimer, // Disable logo tap after start
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Image.asset(
                                'assets/images/logo_dracailles_min.png',
                                height: 100,
                              ),
                              if (!_timerStarted && _timerDuration != _timeLeft)
                                Center(
                                  child: Icon(
                                    Icons.pause_circle_filled,
                                    size: 100,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                            ],
                          ),
                          if (_timerDuration != _timeLeft)
                            Text(
                              '${_timeLeft ~/ 60}:${(_timeLeft % 60).toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
