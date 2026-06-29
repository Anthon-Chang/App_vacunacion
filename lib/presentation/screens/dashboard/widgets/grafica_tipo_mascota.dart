import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class GraficaTipoMascota extends StatefulWidget {
  final int perros;
  final int gatos;

  const GraficaTipoMascota({
    super.key,
    required this.perros,
    required this.gatos,
  });

  @override
  State<GraficaTipoMascota> createState() => _GraficaTipoMascotaState();
}

class _GraficaTipoMascotaState extends State<GraficaTipoMascota> {
  int _tocado = -1;

  @override
  Widget build(BuildContext context) {
    final total = widget.perros + widget.gatos;
    if (total == 0) return _buildVacio();

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Distribución por tipo',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            response == null ||
                            response.touchedSection == null) {
                          _tocado = -1;
                          return;
                        }
                        _tocado = response
                            .touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  sections: [
                    PieChartSectionData(
                      value: widget.perros.toDouble(),
                      title: _tocado == 0
                          ? '${widget.perros}\nperros'
                          : '${((widget.perros / total) * 100).toStringAsFixed(1)}%',
                      color: const Color(0xFF6D4C41),
                      radius: _tocado == 0 ? 70 : 60,
                      titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                    PieChartSectionData(
                      value: widget.gatos.toDouble(),
                      title: _tocado == 1
                          ? '${widget.gatos}\ngatos'
                          : '${((widget.gatos / total) * 100).toStringAsFixed(1)}%',
                      color: const Color(0xFFEF6C00),
                      radius: _tocado == 1 ? 70 : 60,
                      titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                  centerSpaceRadius: 40,
                  sectionsSpace: 3,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Leyenda(color: Color(0xFF6D4C41), label: '🐶 Perros'),
                SizedBox(width: 24),
                _Leyenda(color: Color(0xFFEF6C00), label: '🐱 Gatos'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVacio() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text('Sin datos aún',
              style: TextStyle(color: Colors.grey)),
        ),
      ),
    );
  }
}

class _Leyenda extends StatelessWidget {
  final Color color;
  final String label;
  const _Leyenda({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 14, height: 14,
            decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}