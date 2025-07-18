import 'package:flutter/material.dart';
import 'package:pomodoro_timer/database_helper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class SessionHistoryScreen extends StatefulWidget {
  const SessionHistoryScreen({super.key});

  @override
  State<SessionHistoryScreen> createState() => _SessionHistoryScreenState();
}

class _SessionHistoryScreenState extends State<SessionHistoryScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _sessions = [];
  Map<String, List<Map<String, dynamic>>> _groupedSessions = {};
  Map<String, double> _dailyFocusTime = {};

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final sessions = await _dbHelper.getPomodoroSessions();
    setState(() {
      _sessions = sessions;
      _groupedSessions = _groupSessionsByDate(sessions);
      _dailyFocusTime = _getDailyFocusTime(sessions);
    });
  }

  Map<String, double> _getDailyFocusTime(List<Map<String, dynamic>> sessions) {
    Map<String, double> dailyData = {};
    for (var session in sessions) {
      if (session['status'] == 'Completed') {
        final DateTime startTime = DateTime.fromMillisecondsSinceEpoch(session['startTime']);
        final String dateKey = DateFormat('yyyy-MM-dd').format(startTime);
        dailyData.update(dateKey, (value) => value + (session['durationSeconds'] / 60), // in minutes
            ifAbsent: () => (session['durationSeconds'] / 60));
      }
    }
    return dailyData;
  }

  Map<String, List<Map<String, dynamic>>> _groupSessionsByDate(List<Map<String, dynamic>> sessions) {
    Map<String, List<Map<String, dynamic>>> groupedData = {};
    for (var session in sessions) {
      final DateTime startTime = DateTime.fromMillisecondsSinceEpoch(session['startTime']);
      final String dateKey = DateFormat('yyyy-MM-dd').format(startTime);
      if (!groupedData.containsKey(dateKey)) {
        groupedData[dateKey] = [];
      }
      groupedData[dateKey]!.add(session);
    }
    return groupedData;
  }

  String _formatDuration(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}m ${remainingSeconds.toString().padLeft(2, '0')}s';
  }

  String _formatDateTime(int millisecondsSinceEpoch) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
    return DateFormat('HH:mm').format(dateTime);
  }

  String _formatDate(String dateKey) {
    final DateTime date = DateTime.parse(dateKey);
    return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date);
  }

  Future<void> _deleteSession(int id) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: const Text('Apakah Anda yakin ingin menghapus sesi ini?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirm) {
      await _dbHelper.deletePomodoroSession(id);
      _loadSessions(); // Refresh the UI
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi telah dihapus.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Sesi', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueGrey[900],
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.white),
            onPressed: _clearAllSessions,
            tooltip: 'Hapus Semua Riwayat',
          ),
        ],
      ),
      body: Container(
        color: Colors.blueGrey[900],
        child: _sessions.isEmpty
            ? const Center(
                child: Text('Belum ada sesi yang tersimpan.', style: TextStyle(color: Colors.white70)),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_dailyFocusTime.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: AspectRatio(
                          aspectRatio: 1.7,
                          child: BarChart(
                            BarChartData(
                              minY: 0,
                              maxY: _dailyFocusTime.values.isNotEmpty ? (_dailyFocusTime.values.reduce((a, b) => a > b ? a : b) * 1.2).ceilToDouble() : 60,
                              barGroups: _dailyFocusTime.entries.map((entry) {
                                return BarChartGroupData(
                                  x: DateTime.parse(entry.key).day,
                                  barRods: [BarChartRodData(toY: entry.value, color: Colors.cyanAccent, width: 16)],
                                );
                              }).toList(),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      return Text(value.toInt().toString(),
                                          style: TextStyle(color: Colors.white70, fontSize: 12));
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 10,
                                    getTitlesWidget: (value, meta) {
                                      return Text('${value.toInt()}m',
                                          style: TextStyle(color: Colors.white70, fontSize: 12));
                                    },
                                  ),
                                ),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              gridData: const FlGridData(show: false),
                            ),
                          ),
                        ),
                      ),
                    ..._groupedSessions.keys.map((dateKey) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Text(
                              _formatDate(dateKey),
                              style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _groupedSessions[dateKey]!.length,
                            itemBuilder: (context, index) {
                              final session = _groupedSessions[dateKey]![index];
                              return Card(
                                color: Colors.blueGrey[800],
                                elevation: 4,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row( // Added Row for delete button
                                    children: [
                                      Expanded( // Wrap existing Column with Expanded
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Jenis Pekerjaan: ${session['taskType']}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Area Fokus: ${session['focusArea']}',
                                              style: const TextStyle(fontSize: 14, color: Colors.white70),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Durasi: ${_formatDuration(session['durationSeconds'])}',
                                              style: const TextStyle(fontSize: 14, color: Colors.white70),
                                            ),
                                            Text(
                                              'Mulai: ${_formatDateTime(session['startTime'])}',
                                              style: const TextStyle(fontSize: 14, color: Colors.white70),
                                            ),
                                            Text(
                                              'Selesai: ${_formatDateTime(session['endTime'])}',
                                              style: const TextStyle(fontSize: 14, color: Colors.white70),
                                            ),
                                            Text(
                                              'Status: ${session['status']}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: session['status'] == 'Completed' ? Colors.greenAccent : Colors.redAccent,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton( // Delete button
                                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                                        onPressed: () => _deleteSession(session['id']),
                                        tooltip: 'Hapus Sesi Ini',
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _clearAllSessions() async {
    final bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: const Text('Apakah Anda yakin ingin menghapus semua riwayat sesi?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirm) {
      await _dbHelper.deleteAllPomodoroSessions();
      _loadSessions(); // Refresh the UI
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua riwayat sesi telah dihapus.')),
      );
    }
  }
}