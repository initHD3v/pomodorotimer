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
  int _quickBreakDuration = 1 * 60; // Default 1 minute for quick break

  late int _remainingSeconds;
  Timer? _timer;
  bool _isRunning = false;
  bool _isBreak = false;
  bool _isQuickBreak = false; // New variable to track quick break status
  int _pomodoroCount = 0;
  bool _hasStarted = false; // New variable to track if a session has ever started

  int _workSessionRemainingSeconds = 0; // To store remaining time before quick break
  int _workSessionTotalDuration = 0; // To store total duration before quick break

  bool get _isPaused => !_isRunning && !_isBreak && !_isQuickBreak && _hasStarted; // Added getter

  void _quickPause() { // Added method
    _startQuickBreak();
  }

  late AnimationController _animationController;
  int _currentTotalDuration = 0;

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TextEditingController _taskTypeController = TextEditingController();
  final NotificationService _notificationService = NotificationService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final SystemTrayManager _systemTrayManager = SystemTrayManager();

  final TextEditingController _numTasksController = TextEditingController(); // New controller for number of tasks
  bool _showTaskInputForm = true; // New state to control initial task input visibility

  List<TextEditingController> _taskTypeControllers = []; // Controllers for dynamic task type inputs
  List<TextEditingController> _taskDurationControllers = []; // Controllers for dynamic task duration inputs
  List<Map<String, dynamic>> _currentSessionTasks = []; // List to hold the tasks for the current session
  int _currentTaskIndex = 0; // Index of the currently active task

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
        _systemTrayManager.setToolTip(
            _isBreak ? 'Istirahat' : (_isQuickBreak ? 'Jeda Cepat' : 'Kerja') + ': ${_formatTime(_remainingSeconds)}');
      });
    });

    _animationController!.addStatusListener((status) async { // Added async
      if (status == AnimationStatus.completed) {
        _timer?.cancel(); // Cancel the periodic timer if it's still running
        _isRunning = false;
        _playSound(true); // Play sound for task completion

        // Update the completed task's actual duration and status
        if (_currentSessionTasks.isNotEmpty && _currentTaskIndex < _currentSessionTasks.length) {
          final currentTask = _currentSessionTasks[_currentTaskIndex];
          final taskDuration = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(currentTask['taskStartTime'])).inSeconds;
          currentTask['actualDurationSeconds'] = taskDuration;
          currentTask['taskEndTime'] = DateTime.now().millisecondsSinceEpoch;
          currentTask['taskStatus'] = 'Completed';
          await _dbHelper.updateSessionTask(currentTask); // Update task in DB
        }

        if (!_isBreak && !_isQuickBreak) { // If it was a work session (or task within a work session)
          _currentTaskIndex++; // Move to the next task

          if (_currentTaskIndex < _currentSessionTasks.length) {
            // More tasks in the current Pomodoro session
            final nextTask = _currentSessionTasks[_currentTaskIndex];
            _currentTotalDuration = nextTask['taskDurationSeconds'];
            _remainingSeconds = _currentTotalDuration;
            _animationController!.duration = Duration(seconds: _currentTotalDuration);
            _animationController!.reset();

            // Update task start time for the next task in DB
            nextTask['taskStartTime'] = DateTime.now().millisecondsSinceEpoch;
            await _dbHelper.updateSessionTask(nextTask);

            _notificationService.showNotification(
              'Tugas Berikutnya',
              'Mulai tugas: ${nextTask['taskType']}',
            );
            setState(() {
              _isRunning = true; // Mark as running for the next task
            });
            _animationController!.forward(); // Start timer for next task
          } else {
            // All tasks in the current Pomodoro session are completed
            // Update the main session's total work duration and status
            final totalWorkDuration = _currentSessionTasks.fold(0, (sum, task) => sum + (task['actualDurationSeconds'] as int));
            await _dbHelper.updatePomodoroSession({
              'id': _currentSessionId,
              'endTime': DateTime.now().millisecondsSinceEpoch,
              'totalWorkDurationSeconds': totalWorkDuration,
              'status': 'Completed',
            });

            // Proceed to break logic
            _isBreak = true; // Toggle to break
            _pomodoroCount++; // Increment pomodoro count only when a work session completes
            _currentTotalDuration = (_pomodoroCount % 4 == 0 ? _longBreakDuration : _shortBreakDuration);

            _animationController!.duration = Duration(seconds: _currentTotalDuration);
            _animationController!.reset();

            _notificationService.showNotification(
              'Waktu Istirahat',
              (_pomodoroCount % 4 == 0 ? 'Waktunya istirahat panjang!' : 'Waktunya istirahat pendek!'),
            );

            setState(() {
              _isRunning = true; // Mark as running for the break
            });
            _animationController!.forward(); // Start the break timer animation
          }
        } else if (_isQuickBreak) { // If it was a quick break
          _playSound(false); // Play break sound
          _notificationService.showNotification(
            'Jeda Cepat Selesai',
            'Jeda cepat telah berakhir. Lanjutkan pekerjaan Anda.',
          );
          setState(() {
            _isQuickBreak = false; // Reset quick break status
            _isRunning = true; // Continue the main timer
            _currentTotalDuration = _workSessionTotalDuration; // Restore total duration
            _remainingSeconds = _workSessionRemainingSeconds; // Restore remaining seconds
          });
          _animationController!.duration = Duration(seconds: _currentTotalDuration);
          _animationController!.value = 1.0 - (_remainingSeconds / _currentTotalDuration); // Set animation to correct point
          _animationController!.forward(); // Resume the main timer animation
        } else { // If it was a regular break, now stop and reset
          _playSound(false); // Break session completed
          _notificationService.showNotification(
            'Sesi Selesai',
            'Sesi Pomodoro telah berakhir. Silakan mulai sesi baru.',
          );
          _resetTimer(isCompletedReset: true); // Reset UI and stop, indicating it's a completed reset
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
      _quickBreakDuration = (prefs.getInt('quickBreakDuration') ?? 1) * 60; // Load quick break duration
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

        // Populate _currentSessionTasks from user input
        _currentSessionTasks = List.generate(_taskTypeControllers.length, (index) {
          return {
            'taskType': _taskTypeControllers[index].text.isEmpty ? 'N/A' : _taskTypeControllers[index].text,
            'taskDurationSeconds': (int.tryParse(_taskDurationControllers[index].text) ?? 25) * 60, // Default to 25 minutes if invalid
            'taskOrder': index,
            'taskStatus': 'Active',
          };
        });

        final newSession = {
          'startTime': _sessionStartTime!.millisecondsSinceEpoch,
          'endTime': 0, // Will be updated later
          'totalWorkDurationSeconds': 0, // Will be updated later
          'status': 'Active',
        };
        _currentSessionId = await _dbHelper.insertPomodoroSession(newSession);
        print('New session started with ID: $_currentSessionId'); // For debugging

        // Insert each task into the database
        for (int i = 0; i < _currentSessionTasks.length; i++) {
          _currentSessionTasks[i]['session_id'] = _currentSessionId;
          _currentSessionTasks[i]['taskStartTime'] = DateTime.now().millisecondsSinceEpoch; // Set start time for the task
          _currentSessionTasks[i]['actualDurationSeconds'] = 0;
          _currentSessionTasks[i]['id'] = await _dbHelper.insertSessionTask(_currentSessionTasks[i]);
        }

        // Set initial duration to the first task's duration
        _currentTotalDuration = _currentSessionTasks[_currentTaskIndex]['taskDurationSeconds'];
        _remainingSeconds = _currentTotalDuration;
        _animationController.duration = Duration(seconds: _currentTotalDuration);
        _animationController.reset();

      } else {
        // This is a resumed work session, update existing one
        // No need to update taskType/focusArea here as they are now managed per task
        print('Existing session $_currentSessionId resumed.'); // For debugging
      }
    }

    _animationController!.forward(from: _animationController!.value);
  }

  void _pauseTimer() async {
    _animationController.stop();
    setState(() {
      _isRunning = false;
    });

    // Update the actual duration of the currently active task when paused
    if (_currentSessionTasks.isNotEmpty && _currentTaskIndex < _currentSessionTasks.length) {
      final currentTask = _currentSessionTasks[_currentTaskIndex];
      final taskDuration = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(currentTask['taskStartTime'])).inSeconds;
      currentTask['actualDurationSeconds'] = taskDuration;
      await _dbHelper.updateSessionTask(currentTask); // Update task in DB
    }
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
      _isQuickBreak = false; // Reset quick break status
      _remainingSeconds = _pomodoroDuration;
      _pomodoroCount = 0;
      _numTasksController.clear(); // Clear the number of tasks input
      _taskTypeControllers.forEach((controller) => controller.dispose());
      _taskDurationControllers.forEach((controller) => controller.dispose());
      _taskTypeControllers.clear();
      _taskDurationControllers.clear();
      _currentSessionTasks.clear();
      _currentTaskIndex = 0;
      _sessionStartTime = null;
      _currentSessionId = null;
      _currentTotalDuration = _pomodoroDuration; // Reset total duration
      _animationController?.duration = Duration(seconds: _currentTotalDuration);
      _hasStarted = false; // Reset to false when timer is reset
      _showTaskInputForm = true; // Show initial task input form again
    });
  }

  void _stopBreak() {
    _animationController.reset();
    _animationController.stop();
    setState(() {
      _isRunning = false;
      _isBreak = false;
      _isQuickBreak = false; // Reset quick break status
      _remainingSeconds = _pomodoroDuration;
      _taskTypeControllers.forEach((controller) => controller.clear());
      _taskDurationControllers.forEach((controller) => controller.clear());
      _taskTypeControllers.clear();
      _taskDurationControllers.clear();
      _currentSessionTasks.clear();
      _currentTaskIndex = 0;
      _sessionStartTime = null;
      _currentSessionId = null;
      _currentTotalDuration = _pomodoroDuration;
      _animationController?.duration = Duration(seconds: _currentTotalDuration);
      _showTaskInputForm = true; // Show initial task input form again
    });
  }

  void _startQuickBreak() {
    _animationController.stop(); // Stop current animation if any
    setState(() {
      _workSessionRemainingSeconds = _remainingSeconds; // Save remaining time
      _workSessionTotalDuration = _currentTotalDuration; // Save total duration
      _isRunning = false; // Main timer is paused during quick break
      _isQuickBreak = true;
      _currentTotalDuration = _quickBreakDuration;
      _remainingSeconds = _currentTotalDuration;
    });
    _animationController.duration = Duration(seconds: _currentTotalDuration);
    _animationController.reset();
    _animationController.forward();

    _notificationService.showNotification(
      'Jeda Cepat',
      'Waktunya jeda singkat!',
    );
            _systemTrayManager.setToolTip(
            _isBreak ? 'Istirahat' : (_isQuickBreak ? 'Jeda Cepat' : 'Kerja') + ': ${_formatTime(_remainingSeconds)}'); // Update system tray tooltip
  }

  void _createTaskInputs() {
    final int? numTasks = int.tryParse(_numTasksController.text);
    if (numTasks == null || numTasks <= 0) {
      // Show an error or a SnackBar if input is invalid
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap masukkan jumlah pekerjaan yang valid (angka positif).')),
      );
      return;
    }

    setState(() {
      _taskTypeControllers = List.generate(numTasks, (index) => TextEditingController());
      _taskDurationControllers = List.generate(numTasks, (index) => TextEditingController(text: '25')); // Default 25 minutes
      _showTaskInputForm = false;
    });
  }

  Future<void> _updateSession(String status) async {
    if (_currentSessionId == null) return; // Don't update if no session ID

    final durationWorked = _sessionStartTime != null
        ? DateTime.now().difference(_sessionStartTime!).inSeconds
        : 0;

    final updatedSession = {
      'id': _currentSessionId,
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
    _numTasksController.dispose(); // Dispose the new controller
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
          child: _showTaskInputForm
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 50.0),
                      child: TextField(
                        controller: _numTasksController,
                        decoration: InputDecoration(
                          labelText: 'Berapa jumlah pekerjaan yang ingin Anda lakukan?',
                          labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color!.withOpacity(0.7)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                        ),
                        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _createTaskInputs,
                      child: const Text('Buat Daftar Pekerjaan'),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // Display current task or task input fields
                    if (_isRunning || _isBreak || _isQuickBreak) // If timer is running or on any break, show current task/break status
                      Column(
                        children: [
                          Text(
                            _isBreak ? 'Break Time!' : (_isQuickBreak ? 'Jeda Cepat!' : 'Work Time!'),
                            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                                  color: Theme.of(context).textTheme.headlineSmall!.color,
                                ),
                          ),
                          const SizedBox(height: 20),
                          if (!_isBreak && !_isQuickBreak) // Show current task type only if not on break or quick break
                            Text(
                              'Jenis Pekerjaan: ${_currentSessionTasks.isNotEmpty ? _currentSessionTasks[_currentTaskIndex]['taskType'] : 'N/A'}',
                              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    color: Theme.of(context).textTheme.bodyMedium!.color,
                                  ),
                            ),
                          const SizedBox(height: 20),
                        ],
                      )
                    else // Show task input fields when not running and not on break
                      Column(
                        children: [
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _taskTypeControllers.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 50.0, vertical: 8.0),
                                child: Column(
                                  children: [
                                    TextField(
                                      controller: _taskTypeControllers[index],
                                      decoration: InputDecoration(
                                        labelText: 'Jenis Pekerjaan ${index + 1}',
                                        labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color!.withOpacity(0.7)),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10.0),
                                          borderSide: BorderSide.none,
                                        ),
                                        filled: true,
                                        fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                                      ),
                                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color),
                                    ),
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: _taskDurationControllers[index],
                                      decoration: InputDecoration(
                                        labelText: 'Durasi (menit) ${index + 1}',
                                        labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color!.withOpacity(0.7)),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10.0),
                                          borderSide: BorderSide.none,
                                        ),
                                        filled: true,
                                        fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                                      ),
                                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _startTimer,
                            child: const Text('Mulai Sesi'),
                          ),
                        ],
                      ),
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
                      progressColor: _isBreak ? Colors.cyanAccent : (_isQuickBreak ? Colors.blueAccent : Colors.redAccent),
                      backgroundColor: Colors.blueGrey[700]!,
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        // Stop button (during any break)
                        if (_isBreak && !_isQuickBreak)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _stopBreak,
                              child: const Text('Stop'),
                            ),
                          ),
                        // Start button (if not running, and not on break)
                        if (!_isRunning && !_isBreak && !_isQuickBreak)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _startTimer,
                              child: const Text('Start'),
                            ),
                          ),
                        // Pause button (if running and not on break)
                        if (_isRunning && !_isBreak && !_isQuickBreak)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _pauseTimer,
                              child: const Text('Pause'),
                            ),
                          ),
                        // Jeda Cepat button (if paused and has started)
                        if (_isPaused) // This implies !_isRunning && !_isBreak && !_isQuickBreak && _hasStarted
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _quickPause,
                              child: const Text('Jeda Cepat'),
                            ),
                          ),
                        // Reset button (if has started and not on break)
                        if (_hasStarted && !_isBreak && !_isQuickBreak)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _resetTimer,
                              child: const Text('Reset'),
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
