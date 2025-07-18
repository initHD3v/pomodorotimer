import 'package:flutter/material.dart';
import 'dart:async';
import 'package:pomodoro_timer/database_helper.dart';
import 'package:pomodoro_timer/notification_service.dart';
import 'package:pomodoro_timer/session_history_screen.dart';
import 'package:pomodoro_timer/settings_screen.dart';
import 'package:pomodoro_timer/system_tray_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  final NotificationService notificationService = NotificationService();
  await notificationService.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('themeMode') ?? 0; // 0: system, 1: light, 2: dark
    setState(() {
      _themeMode = ThemeMode.values[themeIndex];
    });
  }

  void _setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pomodoro Timer',
      themeMode: _themeMode,
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        scaffoldBackgroundColor: Colors.blueGrey[50], // Lighter background for light theme
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 90.0, fontWeight: FontWeight.bold, color: Colors.black87),
          headlineSmall: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w600, color: Colors.black54),
          bodyMedium: TextStyle(fontSize: 18.0, color: Colors.black54),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.blueGrey[700]!,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            // Removed minimumSize to fix button layout
          ),
        ),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blueGrey,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.blueGrey[900], // Darker background for dark theme
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 90.0, fontWeight: FontWeight.bold, color: Colors.white),
          headlineSmall: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w600, color: Colors.white),
          bodyMedium: TextStyle(fontSize: 18.0, color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.blueGrey[700]!,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            // Removed minimumSize to fix button layout
          ),
        ),
      ),
      home: PomodoroTimer(setThemeMode: _setThemeMode),
    );
  }
}

class PomodoroTimer extends StatefulWidget {
  final Function(ThemeMode) setThemeMode;

  const PomodoroTimer({super.key, required this.setThemeMode});

  @override
  State<PomodoroTimer> createState() => _PomodoroTimerState();
}

class _PomodoroTimerState extends State<PomodoroTimer> with SingleTickerProviderStateMixin {
  int _pomodoroDuration = 25 * 60;
  int _shortBreakDuration = 5 * 60;
  int _longBreakDuration = 15 * 60;

  late int _remainingSeconds;
  Timer? _timer;
  bool _isRunning = false;
  bool _isBreak = false;
  int _pomodoroCount = 0;
  bool _hasStarted = false; // New variable to track if a session has ever started

  late AnimationController _animationController;
  int _currentTotalDuration = 0;

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TextEditingController _taskTypeController = TextEditingController();
  final TextEditingController _focusAreaController = TextEditingController();
  final NotificationService _notificationService = NotificationService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final SystemTrayManager _systemTrayManager = SystemTrayManager();

  List<String> _availableSounds = [];
  String _selectedWorkSound = 'alarm1.mp3'; // Default
  String _selectedBreakSound = 'bell.mp3'; // Default

  DateTime? _sessionStartTime;
  int? _currentSessionId; // To store the ID of the current session

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _pomodoroDuration;
    _currentTotalDuration = _pomodoroDuration;
    _availableSounds = ['alarm1.mp3', 'alarm2.mp3', 'bell.mp3', 'bell2.mp3', 'bell3.mp3', 'bell4.mp3', 'bright.mp3', 'bright2.mp3', 'bright3.mp3', 'ding.mp3', 'signall.mp3'];
    _loadSettings();
    _systemTrayManager.init(_startTimer, _pauseTimer, _resetTimer);

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _currentTotalDuration),
    );

    _animationController!.addListener(() {
      setState(() {
        _remainingSeconds = (_currentTotalDuration * (1 - _animationController!.value)).ceil();
        _systemTrayManager.setToolTip('${_isBreak ? 'Istirahat' : 'Kerja'}: ${_formatTime(_remainingSeconds)}');
      });
    });

    _animationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _timer?.cancel(); // Cancel the periodic timer if it's still running
        _isRunning = false;
        _updateSession('Completed'); // Update session on completion
        if (_isBreak) { // If it was a break, now stop and reset
          _playSound(false); // Break session completed
          _notificationService.showNotification(
            'Sesi Selesai',
            'Sesi Pomodoro telah berakhir. Silakan mulai sesi baru.',
          );
          _resetTimer(isCompletedReset: true); // Reset UI and stop, indicating it's a completed reset
        } else { // If it was a work session, transition to break
          _playSound(true); // Work session completed
          _isBreak = true; // Toggle to break
          _pomodoroCount++; // Increment pomodoro count only when a work session completes
          _currentTotalDuration = (_pomodoroCount % 4 == 0 ? _longBreakDuration : _shortBreakDuration);

          _animationController!.duration = Duration(seconds: _currentTotalDuration);
          _animationController!.reset();

          _notificationService.showNotification(
            'Waktu Istirahat',
            (_pomodoroCount % 4 == 0 ? 'Waktunya istirahat panjang!' : 'Waktunya istirahat pendek!'),
          );

          // Automatically start the next phase (the break) without creating a new session
          setState(() {
            _isRunning = true; // Mark as running for the break
          });
          _animationController!.forward(); // Start the break timer animation
        }
      }
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pomodoroDuration = (prefs.getInt('pomodoroDuration') ?? 25) * 60;
      _shortBreakDuration = (prefs.getInt('shortBreakDuration') ?? 5) * 60;
      _longBreakDuration = (prefs.getInt('longBreakDuration') ?? 15) * 60;
      _selectedWorkSound = prefs.getString('workSound') ?? _availableSounds.first;
      _selectedBreakSound = prefs.getString('breakSound') ?? _availableSounds.first;

      // Update _currentTotalDuration if settings change and timer is not running
      if (!_isRunning) {
        _currentTotalDuration = _isBreak
            ? (_pomodoroCount % 4 == 0 ? _longBreakDuration : _shortBreakDuration)
            : _pomodoroDuration;
        _remainingSeconds = _currentTotalDuration;
        _animationController.duration = Duration(seconds: _currentTotalDuration);
        _animationController.reset();
      }
    });
  }

  void _startTimer() async {
    if (_isRunning) return; // Prevent starting if already running

    setState(() {
      _isRunning = true;
      _sessionStartTime = DateTime.now(); // Record start time
      _hasStarted = true; // Set to true when timer starts
    });

    // Insert new session when timer starts, only if it's a work session
    if (!_isBreak) {
      if (_currentSessionId == null) {
        // This is a brand new work session
        _sessionStartTime = DateTime.now(); // Record start time for new session
        final newSession = {
          'taskType': _taskTypeController.text.isEmpty ? 'N/A' : _taskTypeController.text,
          'focusArea': _focusAreaController.text.isEmpty ? 'N/A' : _focusAreaController.text,
          'durationSeconds': 0, // Will be updated later
          'startTime': _sessionStartTime!.millisecondsSinceEpoch,
          'endTime': 0, // Will be updated later
          'status': 'Active',
        };
        _currentSessionId = await _dbHelper.insertPomodoroSession(newSession);
        print('New session started with ID: $_currentSessionId'); // For debugging
      } else {
        // This is a resumed work session, update existing one
        final updatedSessionData = {
          'id': _currentSessionId,
          'taskType': _taskTypeController.text.isEmpty ? 'N/A' : _taskTypeController.text,
          'focusArea': _focusAreaController.text.isEmpty ? 'N/A' : _focusAreaController.text,
        };
        await _dbHelper.updatePomodoroSession(updatedSessionData);
        print('Existing session $_currentSessionId updated with new task/focus.'); // For debugging
      }
    }

    _animationController!.forward(from: _animationController!.value);
  }

  void _pauseTimer() {
    _animationController.stop();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer({bool isCompletedReset = false}) {
    _animationController.reset();
    _animationController.stop(); // Ensure it's stopped
    if(_isRunning && !isCompletedReset) { // Only update to 'Reset' if not a completed reset
      _updateSession('Reset'); // Update session on reset
    }
    setState(() {
      _isRunning = false;
      _isBreak = false;
      _remainingSeconds = _pomodoroDuration;
      _pomodoroCount = 0;
      _taskTypeController.clear();
      _focusAreaController.clear();
      _sessionStartTime = null;
      _currentSessionId = null;
      _currentTotalDuration = _pomodoroDuration; // Reset total duration
      _animationController?.duration = Duration(seconds: _currentTotalDuration);
    });
  }

  void _stopBreak() {
    _animationController.reset();
    _animationController.stop();
    setState(() {
      _isRunning = false;
      _isBreak = false;
      _remainingSeconds = _pomodoroDuration;
      _taskTypeController.clear();
      _focusAreaController.clear();
      _sessionStartTime = null;
      _currentSessionId = null;
      _currentTotalDuration = _pomodoroDuration;
      _animationController?.duration = Duration(seconds: _currentTotalDuration);
    });
  }

  Future<void> _updateSession(String status) async {
    if (_currentSessionId == null) return; // Don't update if no session ID

    final durationWorked = _sessionStartTime != null
        ? DateTime.now().difference(_sessionStartTime!).inSeconds
        : 0;

    final updatedSession = {
      'id': _currentSessionId,
      'taskType': _taskTypeController.text.isEmpty ? 'N/A' : _taskTypeController.text,
      'focusArea': _focusAreaController.text.isEmpty ? 'N/A' : _focusAreaController.text,
      'durationSeconds': durationWorked,
      'startTime': _sessionStartTime!.millisecondsSinceEpoch,
      'endTime': DateTime.now().millisecondsSinceEpoch,
      'status': status,
    };
    await _dbHelper.updatePomodoroSession(updatedSession);
    print('Session updated: $updatedSession'); // For debugging
  }

  void _playSound(bool isWorkSessionCompleted) async {
    if (isWorkSessionCompleted) {
      await _audioPlayer.play(AssetSource('sounds/$_selectedWorkSound'));
    } else {
      await _audioPlayer.play(AssetSource('sounds/$_selectedBreakSound'));
    }
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _taskTypeController.dispose();
    _focusAreaController.dispose();
    _audioPlayer.dispose();
    _animationController.dispose(); // Dispose the animation controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double percent = _currentTotalDuration > 0 ? _animationController.value : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pomodoro Timer', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueGrey[800], // Added for visibility
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SessionHistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen(setThemeMode: widget.setThemeMode, availableSounds: _availableSounds)),
              ).then((_) => _loadSettings());
            },
          ),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.background, // Use theme background color
      body: Center( // No need for Container if only for background color
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                  _isBreak ? 'Break Time!' : 'Work Time!',
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    color: Theme.of(context).textTheme.headlineSmall!.color,
                  ),
                ),
              const SizedBox(height: 20),
              CircularPercentIndicator(
                radius: 140.0,
                lineWidth: 13.0,
                animation: false, // Changed to false for smooth, continuous progress
                percent: percent,
                center: Text(
                  _formatTime(_remainingSeconds),
                  style: TextStyle(fontSize: 70.0, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.displayLarge!.color),
                ),
                footer: Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Text(
                    _isBreak ? "Istirahat" : "Fokus",
                    style: const TextStyle(fontSize: 28.0, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
                circularStrokeCap: CircularStrokeCap.round,
                progressColor: _isBreak ? Colors.cyanAccent : Colors.redAccent,
                backgroundColor: Colors.blueGrey[700]!,
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50.0),
                child: _isBreak
                    ? const SizedBox.shrink() // Hide during break
                    : _isRunning
                        ? Text(
                            'Jenis Pekerjaan: ${_taskTypeController.text}',
                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  color: Theme.of(context).textTheme.bodyMedium!.color,
                                ),
                          )
                        : TextField(
                            controller: _taskTypeController,
                            decoration: InputDecoration(
                              labelText: 'Jenis Pekerjaan',
                              labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color!.withOpacity(0.7)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                            ),
                            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color),
                            enabled: !_isRunning, // Disable input when timer is running
                          ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50.0),
                child: _isBreak
                    ? const SizedBox.shrink() // Hide during break
                    : _isRunning
                        ? Text(
                            'Area Fokus: ${_focusAreaController.text}',
                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  color: Theme.of(context).textTheme.bodyMedium!.color,
                                ),
                          )
                        : TextField(
                            controller: _focusAreaController,
                            decoration: InputDecoration(
                              labelText: 'Area Fokus',
                              labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color!.withOpacity(0.7)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                            ),
                            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color),
                            enabled: !_isRunning, // Disable input when timer is running
                          ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  if (_isBreak) // Show Stop button during break
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _stopBreak,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent, // Transparent background
                          elevation: 0, // No shadow
                          padding: EdgeInsets.zero, // Remove padding
                        ),
                        child: Icon(Icons.stop, color: Theme.of(context).textTheme.bodyMedium!.color), // Stop icon
                      ),
                    )
                  else if (!_hasStarted || (_hasStarted && !_isRunning)) // Show Start if not started or paused
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isRunning ? null : _startTimer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent, // Transparent background
                          elevation: 0, // No shadow
                          padding: EdgeInsets.zero, // Remove padding
                        ),
                        child: Icon(Icons.play_arrow, color: Theme.of(context).textTheme.bodyMedium!.color), // Play icon
                      ),
                    ),
                  if (!_isBreak && _hasStarted && _isRunning) // Show Pause if started and running (not during break)
                    const SizedBox(width: 10),
                  if (!_isBreak && _hasStarted && _isRunning) // Show Pause if started and running (not during break)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isRunning ? _pauseTimer : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent, // Transparent background
                          elevation: 0, // No shadow
                          padding: EdgeInsets.zero, // Remove padding
                        ),
                        child: Icon(Icons.pause, color: Theme.of(context).textTheme.bodyMedium!.color), // Pause icon
                      ),
                    ),
                  if (!_isBreak && _hasStarted) // Show Reset if started (not during break)
                    const SizedBox(width: 10),
                  if (!_isBreak && _hasStarted) // Show Reset if started (not during break)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _resetTimer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent, // Transparent background
                          elevation: 0, // No shadow
                          padding: EdgeInsets.zero, // Remove padding
                        ),
                        child: Icon(Icons.refresh, color: Theme.of(context).textTheme.bodyMedium!.color), // Reset icon
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 40),
              Text(
                'Pomodoros Completed: $_pomodoroCount',
                style: TextStyle(fontSize: 18.0, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
