
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pomodoro_timer/database_helper.dart'; // Import DatabaseHelper

class SettingsScreen extends StatefulWidget {
  final Function(ThemeMode) setThemeMode;
  final List<String> availableSounds;

  const SettingsScreen({super.key, required this.setThemeMode, required this.availableSounds});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late SharedPreferences _prefs;
  late TextEditingController _pomodoroController;
  late TextEditingController _shortBreakController;
  late TextEditingController _longBreakController;
  late TextEditingController _quickBreakController; // New controller for quick break duration
  ThemeMode _selectedThemeMode = ThemeMode.system;
  late String _selectedWorkSound;
  late String _selectedBreakSound;

  @override
  void initState() {
    super.initState();
    _pomodoroController = TextEditingController();
    _shortBreakController = TextEditingController();
    _longBreakController = TextEditingController();
    _quickBreakController = TextEditingController(); // Initialize new controller

    // Initialize with a safe default, or the first available sound if the list is not empty
    _selectedWorkSound = widget.availableSounds.isNotEmpty ? widget.availableSounds.first : 'alarm1.mp3';
    _selectedBreakSound = widget.availableSounds.isNotEmpty ? widget.availableSounds.first : 'bell.mp3';

    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _pomodoroController.text = (_prefs.getInt('pomodoroDuration') ?? 25).toString();
      _shortBreakController.text = (_prefs.getInt('shortBreakDuration') ?? 5).toString();
      _longBreakController.text = (_prefs.getInt('longBreakDuration') ?? 15).toString();
      _quickBreakController.text = (_prefs.getInt('quickBreakDuration') ?? 1).toString(); // Load quick break duration
      _selectedThemeMode = ThemeMode.values[_prefs.getInt('themeMode') ?? 0];
      _selectedWorkSound = _prefs.getString('workSound') ?? widget.availableSounds.first;
      _selectedBreakSound = _prefs.getString('breakSound') ?? widget.availableSounds.first;
    });
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      await _prefs.setInt('pomodoroDuration', int.parse(_pomodoroController.text));
      await _prefs.setInt('shortBreakDuration', int.parse(_shortBreakController.text));
      await _prefs.setInt('longBreakDuration', int.parse(_longBreakController.text));
      await _prefs.setInt('quickBreakDuration', int.parse(_quickBreakController.text)); // Save quick break duration
      await _prefs.setInt('themeMode', _selectedThemeMode.index);
      await _prefs.setString('workSound', _selectedWorkSound);
      await _prefs.setString('breakSound', _selectedBreakSound);
      widget.setThemeMode(_selectedThemeMode);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaturan disimpan!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _pomodoroController.dispose();
    _shortBreakController.dispose();
    _longBreakController.dispose();
    _quickBreakController.dispose(); // Dispose new controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueGrey[900],
        elevation: 0,
      ),
      body: Container(
        color: Colors.blueGrey[900],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _pomodoroController,
                  decoration: InputDecoration(
                    labelText: 'Durasi Pomodoro (menit)',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                  ),
                  style: TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Harap masukkan durasi';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Harap masukkan angka yang valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _shortBreakController,
                  decoration: InputDecoration(
                    labelText: 'Istirahat Pendek (menit)',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                  ),
                  style: TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Harap masukkan durasi';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Harap masukkan angka yang valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _longBreakController,
                  decoration: InputDecoration(
                    labelText: 'Istirahat Panjang (menit)',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                  ),
                  style: TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Harap masukkan durasi';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Harap masukkan angka yang valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _quickBreakController,
                  decoration: InputDecoration(
                    labelText: 'Jeda Cepat (menit)',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                  ),
                  style: TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Harap masukkan durasi';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Harap masukkan angka yang valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Tema Aplikasi', style: TextStyle(color: Colors.white)),
                  trailing: DropdownButton<ThemeMode>(
                    value: _selectedThemeMode,
                    dropdownColor: Colors.blueGrey[800],
                    iconEnabledColor: Colors.white,
                    onChanged: (ThemeMode? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedThemeMode = newValue;
                        });
                      }
                    },
                    items: <DropdownMenuItem<ThemeMode>>[
                      DropdownMenuItem<ThemeMode>(
                        value: ThemeMode.system,
                        child: Text('Sistem', style: TextStyle(color: Colors.white)),
                      ),
                      DropdownMenuItem<ThemeMode>(
                        value: ThemeMode.light,
                        child: Text('Terang', style: TextStyle(color: Colors.white)),
                      ),
                      DropdownMenuItem<ThemeMode>(
                        value: ThemeMode.dark,
                        child: Text('Gelap', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Suara Sesi Kerja', style: TextStyle(color: Colors.white)),
                  trailing: DropdownButton<String>(
                    value: _selectedWorkSound,
                    dropdownColor: Colors.blueGrey[800],
                    iconEnabledColor: Colors.white,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedWorkSound = newValue;
                        });
                      }
                    },
                    items: widget.availableSounds.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value.replaceAll('.mp3', ''), style: TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Suara Sesi Istirahat', style: TextStyle(color: Colors.white)),
                  trailing: DropdownButton<String>(
                    value: _selectedBreakSound,
                    dropdownColor: Colors.blueGrey[800],
                    iconEnabledColor: Colors.white,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedBreakSound = newValue;
                        });
                      }
                    },
                    items: widget.availableSounds.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value.replaceAll('.mp3', ''), style: TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _saveSettings,
                  child: const Text('Simpan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
