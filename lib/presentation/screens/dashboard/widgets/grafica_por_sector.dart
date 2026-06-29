import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../domain/entities/sector.dart';

class GraficaPorSector extends StatelessWidget {
  final Map<String, int> porSector;
  final List<Sector> sectores;

  const GraficaPorSector({
    super.key,
    required this.porSector,
    required this.sectores,
  });

  @override
  Widget build(BuildContext context) {
    if (porSector.isEmpty) return const SizedBox.shrink();

    // Ordenar por cantidad descendente, máx 6
    final entradas = porSector.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entradas.take(6).toList();
    final maxVal = top.first.value.toDouble();

    String nombreSector(String id) {
      final s = sectores.firstWhere(
        (s) => s.id == id,
        orElse: () => Sector(id: id, nombre: 'Sector', ciudad: ''),
      );
      // Abreviar nombre largo
      final n = s.nombre;
      return n.length > 10 ? '${n.substring(0, 10)}…' : n;
    }

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vacunaciones por sector',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxVal * 1.3,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final id = top[groupIndex].key;
                        final nombre = nombreSector(id);
                        return BarTooltipItem(
                          '$nombre\n${rod.toY.toInt()} vacunas',
                          const TextStyle(color: Colors.white, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= top.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              nombreSector(top[idx].key),
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                        reservedSize: 36,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          if (value % 1 != 0) return const SizedBox.shrink();
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            );
                        }
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(top.length, (i) {
                    final colores = [
                      const Color(0xFF1565C0),
                      const Color(0xFF2E7D32),
                      const Color(0xFFE65100),
                      const Color(0xFF6A1B9A),
                      const Color(0xFF00838F),
                      const Color(0xFFC62828),
                    ];
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: top[i].value.toDouble(),
                          color: colores[i % colores.length],
                          width: 28,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6)),
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