import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';

class PatientRecordPage extends StatelessWidget {
  final String patientName;
  final String patientId;

  const PatientRecordPage({
    super.key,
    required this.patientName,
    required this.patientId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: Text(
          'Expediente: $patientName',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildResumenIA(),
            const SizedBox(height: 16),
            _buildExpansionSection(
              title: 'Detalles del paciente',
              icon: Icons.person_outline,
              content: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Edad: 28 años', style: TextStyle(color: AppColors.textDark)),
                    SizedBox(height: 8),
                    Text('Tipo de sangre: O+', style: TextStyle(color: AppColors.textDark)),
                    SizedBox(height: 8),
                    Text('Alergias: Penicilina', style: TextStyle(color: AppColors.textDark)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildExpansionSection(
              title: 'Banderas (Datos Biométricos)',
              icon: Icons.flag_outlined,
              content: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        const Text('Presión Arterial Elevada', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Último registro: 135/90 mmHg (Hace 2 días)'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildExpansionSection(
              title: 'Consultas Previas',
              icon: Icons.history,
              content: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('15 Mayo 2026 - Revisión de rutina. Todo en orden.'),
                    Divider(),
                    Text('02 Abril 2026 - Ecografía del primer trimestre. Feto estable.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildExpansionSection(
              title: 'Citas Pendientes',
              icon: Icons.calendar_today_outlined,
              content: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('18 Jun 2026 - Control prenatal (Semana 28)'),
                    Divider(),
                    Text('30 Jul 2026 - Ecografía 3D (Semana 34)'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildExpansionSection(
              title: 'Plan del Paciente',
              icon: Icons.next_plan_outlined,
              content: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('- Continuar con ácido fólico diario.'),
                    SizedBox(height: 4),
                    Text('- Monitorear presión arterial cada tercer día.'),
                    SizedBox(height: 4),
                    Text('- Reposo relativo, evitar esfuerzos pesados.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenIA() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.pink.shade50),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.psychology_outlined, color: AppColors.primary, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Resumen IA',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 15),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.pink.shade100),
                ),
                child: const Text(
                  'GENERADO POR IA',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '"La tendencia de presión arterial en las últimas 48h muestra una leve mejoría. Se recomienda priorizar la revisión de laboratorio agendada para la próxima cita."',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: AppColors.textDark,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpansionSection({
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Container(
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
      child: ExpansionTile(
        shape: const Border(),
        leading: Icon(icon, color: AppColors.primary),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
            ),
            child: content,
          ),
        ],
      ),
    );
  }
}
