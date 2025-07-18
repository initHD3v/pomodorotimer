
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  final Function(ThemeMode) setThemeMode;

  const SettingsScreen({super.key, required this.setThemeMode});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late SharedPreferences _prefs;
  late TextEditingController _pomodoroController;
  late TextEditingController _shortBreakController;
  late TextEditingController _longBreakController;
  ThemeMode _selectedThemeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _pomodoroController = TextEditingController();
    _shortBreakController = TextEditingController();
    _longBreakController = TextEditingController();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _pomodoroController.text = (_prefs.getInt('pomodoroDuration') ?? 25).toString();
      _shortBreakController.text = (_prefs.getInt('shortBreakDuration') ?? 5).toString();
      _longBreakController.text = (_prefs.getInt('longBreakDuration') ?? 15).toString();
      _selectedThemeMode = ThemeMode.values[_prefs.getInt('themeMode') ?? 0];
    });
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      await _prefs.setInt('pomodoroDuration', int.parse(_pomodoroController.text));
      await _prefs.setInt('shortBreakDuration', int.parse(_shortBreakController.text));
      await _prefs.setInt('longBreakDuration', int.parse(_longBreakController.text));
      await _prefs.setInt('themeMode', _selectedThemeMode.index);
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
