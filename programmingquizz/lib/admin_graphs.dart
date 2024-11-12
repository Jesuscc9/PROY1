import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminGraphs extends StatefulWidget {
  const AdminGraphs({super.key});

  @override
  _AdminGraphsState createState() => _AdminGraphsState();
}

class _AdminGraphsState extends State<AdminGraphs> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<dynamic> topics = [];
  List<dynamic> performanceByTopic = [];

  @override
  void initState() {
    super.initState();
    _fetchTopics();
    _fetchPerformanceByTopic();
  }

  Future<void> _fetchTopics() async {
    final response = await supabase.from('topics').select('shortTitle');
    setState(() {
      topics = response as List<dynamic>;
    });
  }

  Future<void> _fetchPerformanceByTopic() async {
    final response = await supabase.functions
        .invoke('averageScoreByTopic', method: HttpMethod.get);

    print(response.data);

    setState(() {
      performanceByTopic = response.data as List<dynamic>;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildInfoBox('10', 'Usuarios registrados'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildInfoBox('25', 'Quizzes publicados'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            'Rendimiento promedio por tema',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF006633),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 200,
            child: topics.isNotEmpty && performanceByTopic.isNotEmpty
                ? BarChart(
                    BarChartData(
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: true),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 &&
                                  value.toInt() < topics.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    topics[value.toInt()]['shortTitle'] ?? '',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                );
                              } else {
                                return const SizedBox.shrink();
                              }
                            },
                          ),
                        ),
                      ),
                      barGroups: List.generate(
                        performanceByTopic.length,
                        (index) => BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: performanceByTopic[index]
                                          ['correctPercentage']
                                      .toDouble() ??
                                  0.0, // Usa el valor de rendimiento
                              color: index.isEven
                                  ? const Color(0xFF006633)
                                  : const Color(0xFF46BC6E), // Alterna color
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
          const SizedBox(height: 30),
          const Text(
            'Progreso de los últimos 5 días',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF006633),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      const FlSpot(0, 20),
                      const FlSpot(1, 30),
                      const FlSpot(2, 50),
                      const FlSpot(3, 40),
                      const FlSpot(4, 70),
                    ],
                    isCurved: true,
                    dotData: const FlDotData(show: false),
                    color: const Color(0xFF46BC6E),
                  ),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final days = getLastFiveDays();
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              days[value.toInt()],
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      },
                      interval: 1,
                    ),
                  ),
                ),
                minX: 0,
                maxX: 4,
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            'Distribución de temas completados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF006633),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    color: const Color(0xFF006633),
                    value: 50,
                    title: 'Asignaciones',
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: const Color(0xFF46BC6E),
                    value: 40,
                    title: 'Condiciones',
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  PieChartSectionData(
                    color: Colors.lightGreen,
                    value: 16,
                    title: 'Ciclos',
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: Colors.greenAccent,
                    value: 32,
                    title: 'Arreglos',
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(String value, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF006633),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF46BC6E),
            ),
          ),
        ],
      ),
    );
  }

  List<String> getLastFiveDays() {
    final DateFormat formatter = DateFormat('EEE dd');
    final DateTime today = DateTime.now();
    return List.generate(5, (index) {
      final DateTime date = today.subtract(Duration(days: index));
      return formatter.format(date);
    }).reversed.toList();
  }
}
