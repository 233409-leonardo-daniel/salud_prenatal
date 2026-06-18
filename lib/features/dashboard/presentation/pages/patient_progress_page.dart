import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/theme.dart';

class PatientProgressPage extends StatelessWidget {
  final String patientName;

  const PatientProgressPage({super.key, required this.patientName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: Text(
          'Progreso: $patientName',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Datos Biométricos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 16),
            _buildChartCard(
              title: 'Presión Arterial (Sistólica/Diastólica)',
              chart: _buildPressureChart(),
            ),
            const SizedBox(height: 16),
            _buildChartCard(
              title: 'Evolución de Peso (kg)',
              chart: _buildWeightChart(),
            ),
            const SizedBox(height: 24),
            const Text(
              'Síntomas Recientes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 12),
            _buildSymptomsList(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard({required String title, required Widget chart}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: chart,
          ),
        ],
      ),
    );
  }

  Widget _buildPressureChart() {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 22, interval: 1),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // Sistólica
          LineChartBarData(
            spots: const [
              FlSpot(1, 120),
              FlSpot(2, 122),
              FlSpot(3, 125),
              FlSpot(4, 130),
              FlSpot(5, 135),
            ],
            isCurved: true,
            color: Colors.redAccent,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
          // Diastólica
          LineChartBarData(
            spots: const [
              FlSpot(1, 80),
              FlSpot(2, 82),
              FlSpot(3, 85),
              FlSpot(4, 88),
              FlSpot(5, 90),
            ],
            isCurved: true,
            color: Colors.blueAccent,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightChart() {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 22, interval: 1),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: const [
              FlSpot(1, 60.5),
              FlSpot(2, 61.2),
              FlSpot(3, 62.0),
              FlSpot(4, 63.5),
              FlSpot(5, 64.1),
            ],
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomsList() {
    return Column(
      children: [
        _buildSymptomItem('Dolor de cabeza leve', 'Hace 2 días', Colors.orange),
        const SizedBox(height: 8),
        _buildSymptomItem('Náuseas matutinas', 'Hace 4 días', Colors.yellow.shade700),
        const SizedBox(height: 8),
        _buildSymptomItem('Hinchazón en los pies', 'Hace 1 semana', Colors.redAccent),
      ],
    );
  }

  Widget _buildSymptomItem(String symptom, String time, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(symptom, style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textDark)),
          Text(time, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
