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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Sesi', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.blueGrey[100],
        elevation: 0,
      ),
      body: _sessions.isEmpty
          ? const Center(
              child: Text('Belum ada sesi yang tersimpan.'),
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
                            barGroups: _dailyFocusTime.entries.map((entry) {
                              return BarChartGroupData(
                                x: DateTime.parse(entry.key).day,
                                barRods: [BarChartRodData(toY: entry.value, color: Colors.blueGrey)],
                              );
                            }).toList(),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    return Text(DateFormat('dd').format(DateTime(2024, 1, value.toInt())));
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    return Text('${value.toInt()}m');
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
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _groupedSessions[dateKey]!.length,
                          itemBuilder: (context, index) {
                            final session = _groupedSessions[dateKey]![index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Jenis Pekerjaan: ${session['taskType']}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Area Fokus: ${session['focusArea']}',
                                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Durasi: ${_formatDuration(session['durationSeconds'])}',
                                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                                    ),
                                    Text(
                                      'Mulai: ${_formatDateTime(session['startTime'])}',
                                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                                    ),
                                    Text(
                                      'Selesai: ${_formatDateTime(session['endTime'])}',
                                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                                    ),
                                    Text(
                                      'Status: ${session['status']}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: session['status'] == 'Completed' ? Colors.green[700] : Colors.red[700],
                                      ),
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
    );
  }
}