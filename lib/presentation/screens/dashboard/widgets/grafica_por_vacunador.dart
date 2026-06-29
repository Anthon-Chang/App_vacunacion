import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../domain/entities/usuario.dart';

class GraficaPorVacunador extends StatelessWidget {
  final Map<String, int> porVacunador;
  final List<Usuario> vacunadores;

  const GraficaPorVacunador({
    super.key,
    required this.porVacunador,
    required this.vacunadores,
  });

  @override
  Widget build(BuildContext context) {
    if (porVacunador.isEmpty) return const SizedBox.shrink();

    final entradas = porVacunador.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entradas.take(5).toList();
    final maxVal = top.first.value.toDouble();

    String nombreVacunador(String uid) {
      try {
        final u = vacunadores.firstWhere((u) => u.uid == uid);
        return u.nombres;
      } catch (_) {
        return 'N/A';
      }
    }

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vacunaciones por vacunador',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: top.length * 52.0 + 20,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.center,
                  maxY: maxVal * 1.3,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, _, rod, __) {
                        final nombre = nombreVacunador(top[group.x].key);
                        return BarTooltipItem(
                          '$nombre\n${rod.toY.toInt()} vacunas',
                          const TextStyle(color: Colors.white, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 80,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (value != idx.toDouble()) {
                            return const SizedBox.shrink();
                          }
                          if (idx < 0 || idx >= top.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              nombreVacunador(top[idx].key),
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (value != value.toInt().toDouble()) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: false,
                    getDrawingVerticalLine: (_) => FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(top.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barsSpace: 8,
                      barRods: [
                        BarChartRodData(
                          toY: top[i].value.toDouble(),
                          color: const Color(0xFF1565C0),
                          width: 22,
                          borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(6)),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxVal * 1.3,
                            color: Colors.grey.shade100,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}