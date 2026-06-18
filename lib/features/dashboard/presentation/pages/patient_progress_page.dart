import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/theme.dart';
import '../providers/dashboard_provider.dart';
import '../../../login/presentation/providers/login_provider.dart';

class PatientProgressPage extends StatefulWidget {
  final String patientName;
  final String? patientId;

  const PatientProgressPage({
    super.key,
    required this.patientName,
    this.patientId,
  });

  @override
  State<PatientProgressPage> createState() => _PatientProgressPageState();
}

class _PatientProgressPageState extends State<PatientProgressPage> {
  int _parsedPatientId = 1;

  @override
  void initState() {
    super.initState();
    final pIdStr = widget.patientId;
    if (pIdStr != null) {
      _parsedPatientId = int.tryParse(pIdStr.replaceAll('#SP-', '').trim()) ?? 1;
    } else {
      _parsedPatientId = context.read<LoginProvider>().patientId ?? 1;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadPatientDetails(_parsedPatientId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();

    if (dashboardProvider.isDetailsLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Progreso: ${widget.patientName}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.primary,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final consultations = dashboardProvider.activeConsultations;

    final pressureSpotsSystolic = <FlSpot>[];
    final pressureSpotsDiastolic = <FlSpot>[];
    final weightSpots = <FlSpot>[];
    final symptomsWidgets = <Widget>[];

    for (var i = 0; i < consultations.length; i++) {
      final c = consultations[i];
      final xVal = (i + 1).toDouble();

      final pressureRegex = RegExp(r'(\d{2,3})/(\d{2,3})');
      final pressureMatch = pressureRegex.firstMatch(c.objective);
      if (pressureMatch != null) {
        final sys = double.tryParse(pressureMatch.group(1)!) ?? 120.0;
        final dia = double.tryParse(pressureMatch.group(2)!) ?? 80.0;
        pressureSpotsSystolic.add(FlSpot(xVal, sys));
        pressureSpotsDiastolic.add(FlSpot(xVal, dia));
      }

      final weightRegex = RegExp(r'Peso\s*(\d{2,3}(?:\.\d)?)');
      final weightMatch = weightRegex.firstMatch(c.objective);
      if (weightMatch != null) {
        final w = double.tryParse(weightMatch.group(1)!) ?? 60.0;
        weightSpots.add(FlSpot(xVal, w));
      } else {
        final doubleRegex = RegExp(r'(\d{2,3}\.\d)\s*kg');
        final doubleMatch = doubleRegex.firstMatch(c.objective);
        if (doubleMatch != null) {
          final w = double.tryParse(doubleMatch.group(1)!) ?? 60.0;
          weightSpots.add(FlSpot(xVal, w));
        }
      }

      if (c.reportedFacts.isNotEmpty && c.reportedFacts != 'None' && c.reportedFacts != 'Ninguno') {
        final formattedDate = '${c.createdAt.day}/${c.createdAt.month}';
        symptomsWidgets.add(
          _buildSymptomItem(
            c.reportedFacts,
            'Consulta #${c.consultationId} - $formattedDate',
            c.reportedFacts.toLowerCase().contains('dolor') ? Colors.redAccent : Colors.orange,
          ),
        );
        symptomsWidgets.add(const SizedBox(height: 8));
      }
    }

    if (pressureSpotsSystolic.isEmpty) {
      pressureSpotsSystolic.addAll([const FlSpot(1, 120), const FlSpot(2, 122), const FlSpot(3, 118)]);
      pressureSpotsDiastolic.addAll([const FlSpot(1, 80), const FlSpot(2, 82), const FlSpot(3, 78)]);
    }
    if (weightSpots.isEmpty) {
      weightSpots.addAll([const FlSpot(1, 60.0), const FlSpot(2, 60.5), const FlSpot(3, 61.2)]);
    }
    if (symptomsWidgets.isEmpty) {
      symptomsWidgets.add(const Text('Sin síntomas reportados recientemente.', style: TextStyle(color: AppColors.textMuted)));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: Text(
          'Progreso: ${widget.patientName}',
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
              chart: _buildPressureChart(pressureSpotsSystolic, pressureSpotsDiastolic),
            ),
            const SizedBox(height: 16),
            _buildChartCard(
              title: 'Evolución de Peso (kg)',
              chart: _buildWeightChart(weightSpots),
            ),
            const SizedBox(height: 24),
            const Text(
              'Síntomas Recientes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: symptomsWidgets,
            ),
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

  Widget _buildPressureChart(List<FlSpot> systolic, List<FlSpot> diastolic) {
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
            spots: systolic,
            isCurved: true,
            color: Colors.redAccent,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
          LineChartBarData(
            spots: diastolic,
            isCurved: true,
            color: Colors.blueAccent,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightChart(List<FlSpot> spots) {
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
            spots: spots,
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
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
          Expanded(
            child: Text(
              symptom,
              style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textDark),
            ),
          ),
          Text(time, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
