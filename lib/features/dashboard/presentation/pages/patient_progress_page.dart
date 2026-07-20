import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/theme.dart';
import '../providers/dashboard_provider.dart';
import '../../../../core/session/session_manager.dart';
import 'dashboard_state.dart';

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
  int? _parsedPatientId;

  @override
  void initState() {
    super.initState();
    final pIdStr = widget.patientId;
    if (pIdStr != null) {
      _parsedPatientId = int.tryParse(pIdStr.replaceAll('#SP-', '').trim());
    } else {
      _parsedPatientId = context.read<SessionManager>().patientId;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final patientId = _parsedPatientId;
      if (patientId == null) return;
      final session = context.read<SessionManager>();
      context.read<DashboardProvider>().loadPatientDetails(patientId, doctorId: session.doctorId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();

    switch (dashboardProvider.detailsStatus) {
      case DashboardDetailsStatus.initial:
      case DashboardDetailsStatus.loading:
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Progreso: ${widget.patientName}',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.primary,
            iconTheme: IconThemeData(color: Colors.white),
          ),
          body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
        );
      case DashboardDetailsStatus.error:
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Progreso: ${widget.patientName}',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.primary,
            iconTheme: IconThemeData(color: Colors.white),
          ),
          body: Center(child: Text(dashboardProvider.errorMessage ?? 'Error al cargar detalles')),
        );
      case DashboardDetailsStatus.success:
        break;
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
        symptomsWidgets.add(SizedBox(height: 8));
      }
    }

    // Nota: NO se inyectan datos de ejemplo. En un contexto clínico mostrar
    // presiones/pesos falsos sería engañoso, así que si no hay lecturas reales
    // se muestra un estado vacío honesto en cada gráfica.
    final hasPressure = pressureSpotsSystolic.isNotEmpty;
    final hasWeight = weightSpots.isNotEmpty;
    // Etiquetas del eje horizontal: la FECHA de cada consulta (dd/mm), en el
    // orden en que ocurrieron. El eje X es el número de consulta (1,2,3...) y
    // cada punto se ubica en la fecha en que se registró.
    final xLabels = consultations
        .map((c) => '${c.createdAt.day}/${c.createdAt.month}')
        .toList();
    if (symptomsWidgets.isEmpty) {
      symptomsWidgets.add(Text('Sin síntomas reportados recientemente.', style: TextStyle(color: AppColors.textMuted)));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Progreso: ${widget.patientName}',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Datos Biométricos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            SizedBox(height: 16),
            _buildChartCard(
              title: 'Presión Arterial (Sistólica/Diastólica)',
              legend: hasPressure
                  ? Row(
                      children: [
                        _legendDot(Colors.redAccent, 'Sistólica'),
                        SizedBox(width: 16),
                        _legendDot(Colors.blueAccent, 'Diastólica'),
                      ],
                    )
                  : null,
              chart: hasPressure
                  ? _buildPressureChart(pressureSpotsSystolic, pressureSpotsDiastolic, xLabels)
                  : _buildEmptyChart('Aún no hay lecturas de presión registradas en las consultas.'),
            ),
            SizedBox(height: 16),
            _buildChartCard(
              title: 'Evolución de Peso (kg)',
              chart: hasWeight
                  ? _buildWeightChart(weightSpots, xLabels)
                  : _buildEmptyChart('Aún no hay registros de peso en las consultas.'),
            ),
            SizedBox(height: 24),
            Text(
              'Síntomas Recientes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: symptomsWidgets,
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard({required String title, required Widget chart, Widget? legend}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
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
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          if (legend != null) ...[
            SizedBox(height: 8),
            legend,
          ],
          SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: chart,
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ],
    );
  }

  Widget _buildEmptyChart(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 36, color: AppColors.textMuted),
          SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  /// Eje horizontal etiquetado con la FECHA (dd/mm) de cada consulta, más el
  /// rótulo "Fecha de consulta". Cada valor entero del eje X (1,2,3...) es una
  /// consulta y se traduce a su fecha vía [xLabels].
  FlTitlesData _dateTitlesData(List<String> xLabels) {
    return FlTitlesData(
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: true, reservedSize: 36),
      ),
      bottomTitles: AxisTitles(
        axisNameWidget: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Fecha de consulta',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600),
          ),
        ),
        axisNameSize: 20,
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 26,
          interval: 1,
          getTitlesWidget: (value, meta) {
            // Solo etiquetamos valores enteros (cada consulta), no los
            // intermedios que fl_chart consulta para la cuadrícula.
            if (value != value.roundToDouble()) return const SizedBox.shrink();
            final idx = value.round() - 1;
            if (idx < 0 || idx >= xLabels.length) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                xLabels[idx],
                style: TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPressureChart(List<FlSpot> systolic, List<FlSpot> diastolic, List<String> xLabels) {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: _dateTitlesData(xLabels),
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

  Widget _buildWeightChart(List<FlSpot> spots, List<String> xLabels) {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: _dateTitlesData(xLabels),
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
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
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
              style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.textDark),
            ),
          ),
          Text(time, style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
