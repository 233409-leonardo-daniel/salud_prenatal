import 'package:flutter/material.dart';
import '../theme/theme.dart';

class LatestDiaryRecordCard extends StatelessWidget {
  final int systolic;
  final int diastolic;
  final double weightKg;

  const LatestDiaryRecordCard({
    super.key,
    required this.systolic,
    required this.diastolic,
    required this.weightKg,
  });

  Map<String, dynamic> _evaluatePressureRisk(int systolic, int diastolic) {
    if (systolic >= 140 || diastolic >= 90) {
      return {
        'label': 'Riesgo Alto',
        'color': AppColors.riskHighText,
        'bgColor': AppColors.riskHighBg,
        'icon': Icons.warning_amber_rounded,
        'message': 'Presión arterial alta. Reposa y contacta a tu médico.'
      };
    } else if (systolic >= 130 || diastolic >= 85) {
      return {
        'label': 'Riesgo Medio',
        'color': AppColors.riskMediumText,
        'bgColor': AppColors.riskMediumBg,
        'icon': Icons.info_outline,
        'message': 'Presión arterial ligeramente elevada. Mantente en monitoreo.'
      };
    } else {
      return {
        'label': 'Normal',
        'color': AppColors.riskLowText,
        'bgColor': AppColors.riskLowBg,
        'icon': Icons.check_circle_outline,
        'message': 'Tu presión arterial está dentro de los rangos normales.'
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final riskEval = _evaluatePressureRisk(systolic, diastolic);

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withRed(220)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ÚLTIMO REGISTRO',
            style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.favorite, color: Colors.white70, size: 16),
                      SizedBox(width: 4),
                      Text('Presión Arterial', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    '$systolic/$diastolic',
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  Text('mmHg', style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.monitor_weight, color: Colors.white70, size: 16),
                      SizedBox(width: 4),
                      Text('Peso Actual', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    '$weightKg',
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  Text('kg', style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(riskEval['icon'] as IconData, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    riskEval['message'] as String,
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
